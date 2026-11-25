"""
Two-way delivery-order bridge: Supabase → Fujitsu POS (retail).

Parity target: TrustyDelivery (hd_orders / hd_order_items / hd_order_log /
Customers / CustomerAddresses / hd_sequence) + PosPrintouts QR.

Picks up orders that already have preparer_name assigned, creates/matches the
customer in Fujitsu, allocates a real daily OrderId (YYMMDD######), inserts
hd_orders + hd_order_items, writes hd_order_log, then writes Fujitsu ids back
to Supabase so the Flutter prep-receipt QR can be scanned at the cashier.

Also:
  - rebuilds hd_order_items after edits / substitutions (barcode merge)
  - syncs cancellations → StatusCode 200 + audit log
  - syncs lifecycle status transitions + audit log

Reuse the same SQL Server + Supabase config as sync_direct.py.
Run next to sync_direct.py:  python sync_orders_to_fujitsu.py
"""

from __future__ import annotations

import re
import time
import traceback
from datetime import datetime, date
from typing import Any, Optional

import pyodbc
from supabase import Client, create_client

# ==========================================
# 1. إعدادات سوبابيز (نفس sync_direct.py)
# ==========================================
SUPABASE_URL = "https://jugdxfhmjakmzjvfltjv.supabase.co"
SUPABASE_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6"
    "InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ."
    "mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE"
)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ==========================================
# 2. إعدادات سيستم المحل (فوجيتسو) — نفس sync_direct.py
# ==========================================
SQL_SERVER = "40.40.40.2"
SQL_DATABASE = "retail"
SQL_USER = "sa"
SQL_PASSWORD = "retipr"

connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};"
    f"UID={SQL_USER};PWD={SQL_PASSWORD};TrustServerCertificate=yes;"
)

BRANCH_ID = 101
# Live TrustyDelivery writes TerminalNo=0 / OrderVersion=0 despite config.txt
# TerminalNo=19 — match the production write path, not the unused config value.
TERMINAL_NO = 0
ORDER_VERSION = 0
APP_VERSION = "1.0.0.56"
POLL_SECONDS = 5
DEFAULT_PICKER_ID = 10
DEFAULT_PICKER_NAME = "محضر"
STAFF_USER_ID = 7
STAFF_USER_NAME = "سفير ماركت"

# DocType codes in hd_sequence
DOC_CUSTOMER = 101
DOC_ADDRESS = 105
DOC_ORDER = 4  # OrderTaking

# TrustyDelivery.OrderStatus
STATUS = {
    1: "جارى تلقى الطلب",
    2: "فى إنتظار التجهيز",
    3: "جارى تجهيز الطلب",
    4: "تم تجهيز الطلب",
    5: "جارى توصيل الطلب",
    6: "تم توصيل الطلب",
    7: "جارى إعادة تلقى الطلب",
    101: "تم رد الطلب للتلقى",
    102: "تم رد الطلب للتجهيز",
    200: "تم إلغاء الطلب",
    201: "تم طلب الإلغاء",
}
STATUS_WAITING_PREP = 2
STATUS_CANCELLED = 200

# Supabase orders.status → Fujitsu StatusCode
STATUS_MAP = {
    "pending": 2,  # we sync after preparer assigned → WaitingPicking
    "preparing": 3,
    "processing": 3,
    "ready_for_delivery": 4,
    "out_for_delivery": 5,
    "delivered": 6,
    "cancelled": 200,
    "canceled": 200,
}


def log(msg: str) -> None:
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}", flush=True)


def connect_sql():
    return pyodbc.connect(connection_string, autocommit=False)


def truncate(value: Optional[str], max_len: int, fallback: str = "") -> str:
    text = (value or "").strip() or fallback
    return text[:max_len]


def normalize_phone(raw: Optional[str]) -> str:
    if not raw:
        return ""
    digits = re.sub(r"\D+", "", str(raw))
    if digits.startswith("0020"):
        digits = "0" + digits[4:]
    elif digits.startswith("20") and len(digits) >= 11:
        digits = "0" + digits[2:]
    if len(digits) == 10 and digits.startswith("1"):
        digits = "0" + digits
    return digits[:20]


def payment_code(method: Optional[str]) -> int:
    m = (method or "").strip().lower()
    if m in ("card", "visa", "visa_on_delivery"):
        return 2
    if m in ("instapay",):
        return 3
    return 1  # نقدي / cash_on_delivery


def fujitsu_order_source(raw: Optional[str]) -> int:
    """Trusty OrderSource: 0=call center, 1=online."""
    v = (raw or "").strip().lower()
    if v in ("app", "online", "1"):
        return 1
    return 0


def item_count_of(qty: float) -> int:
    """Trusty: (Qty == (int)Qty) ? (int)Qty : 1"""
    try:
        if float(qty) == float(int(qty)):
            return int(qty)
    except (TypeError, ValueError):
        pass
    return 1


def unit_discount_value(
    retail: float, discount_value: float, discount_type: int
) -> float:
    """Trusty ItemDiscount.CalculateItemDiscount."""
    if discount_type in (102, 3):
        return float(discount_value or 0)
    if discount_type == 101:
        return float(retail or 0) * float(discount_value or 0) / 100.0
    return 0.0


def build_qr(
    *,
    order_id: str | int,
    order_source: int,
    commit_prices: int,
    customer_no: int | str,
    address_id: int | str,
    pilot_no: int,
    delivery_fees: float,
) -> str:
    """Exact TrustyDelivery Order.GetQrCodeString."""
    fee = f"{float(delivery_fees):.2f}"
    return (
        f"DlvOrd,001,01,{order_id},{order_source},{commit_prices},"
        f"{customer_no},{address_id},{pilot_no},{fee}"
    )


def _fetch_first_row(cursor):
    """Skip non-result batches (IF/INSERT) until OUTPUT row appears."""
    while True:
        try:
            row = cursor.fetchone()
            if row is not None:
                return row
        except pyodbc.ProgrammingError:
            pass
        if not cursor.nextset():
            return None


def _fetch_last_result(cursor):
    cols, rows = None, []
    while True:
        try:
            if cursor.description:
                cols = [d[0] for d in cursor.description]
                rows = cursor.fetchall()
        except Exception:
            pass
        if not cursor.nextset():
            break
    return cols, rows


def next_hd_sequence(cursor, doc_type: int, *, daily: bool) -> int:
    """Atomically increment hd_sequence and return the new Sequence value."""
    today = date.today()
    if daily:
        cursor.execute(
            """
            IF NOT EXISTS (
                SELECT 1 FROM hd_sequence WITH (UPDLOCK, HOLDLOCK)
                WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
                  AND DocType = ? AND SequenceDate = CAST(GETDATE() AS DATE)
            )
            INSERT INTO hd_sequence
                (Branch, Param1, Param2, Param3, DocType, SequenceDate,
                 Sequence, ModifiedTime)
            VALUES (0, 0, 0, 0, ?, CAST(GETDATE() AS DATE), 0, GETDATE());
            """,
            (doc_type, doc_type),
        )
        cursor.execute(
            """
            UPDATE hd_sequence
            SET Sequence = Sequence + 1,
                ModifiedTime = GETDATE()
            OUTPUT INSERTED.Sequence
            WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
              AND DocType = ? AND SequenceDate = CAST(GETDATE() AS DATE);
            """,
            (doc_type,),
        )
    else:
        cursor.execute(
            """
            IF NOT EXISTS (
                SELECT 1 FROM hd_sequence WITH (UPDLOCK, HOLDLOCK)
                WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
                  AND DocType = ?
            )
            INSERT INTO hd_sequence
                (Branch, Param1, Param2, Param3, DocType, SequenceDate,
                 Sequence, ModifiedTime)
            VALUES (0, 0, 0, 0, ?, ?, 0, GETDATE());
            """,
            (doc_type, doc_type, today),
        )
        cursor.execute(
            """
            UPDATE hd_sequence
            SET Sequence = Sequence + 1,
                ModifiedTime = GETDATE()
            OUTPUT INSERTED.Sequence
            WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
              AND DocType = ?;
            """,
            (doc_type,),
        )

    row = _fetch_first_row(cursor)
    if row is None:
        raise RuntimeError(f"hd_sequence returned no value for DocType={doc_type}")
    return int(row[0])


def find_customer(cursor, phone: str) -> Optional[tuple[int, Optional[int]]]:
    if not phone:
        return None
    pattern = f"%{phone}%"
    cursor.execute(
        """
        SELECT TOP 1 CustomerNo, DefaultAddressId
        FROM Customers
        WHERE REPLACE(REPLACE(REPLACE(ISNULL(Mobile,''),'+',''),' ',''),'-','') LIKE ?
           OR REPLACE(REPLACE(REPLACE(ISNULL(Phone1,''),'+',''),' ',''),'-','') LIKE ?
           OR REPLACE(REPLACE(REPLACE(ISNULL(Phone2,''),'+',''),' ',''),'-','') LIKE ?
           OR REPLACE(REPLACE(REPLACE(ISNULL(Phone3,''),'+',''),' ',''),'-','') LIKE ?
        ORDER BY CustomerNo DESC
        """,
        (pattern, pattern, pattern, pattern),
    )
    row = cursor.fetchone()
    if not row:
        return None
    return int(row[0]), (int(row[1]) if row[1] is not None else None)


def update_customer_phones(
    cursor,
    *,
    customer_no: int,
    phone: str,
    phone2: Optional[str] = None,
    phone3: Optional[str] = None,
    name: Optional[str] = None,
    notes: Optional[str] = None,
) -> None:
    """Match Trusty Update Customers phone / name / notes mapping."""
    mobile = truncate(phone, 20) or None
    p1 = mobile  # Phone1 mirrors primary mobile when no separate landline
    p2 = truncate(phone2 or "", 20) or None
    p3 = truncate(phone3 or "", 20) or None
    display = truncate(name or "", 200) or None
    comments = truncate(notes or "", 500) or None
    try:
        cursor.execute(
            """
            UPDATE Customers
            SET ArabicName = COALESCE(?, ArabicName),
                EnglishName = COALESCE(?, EnglishName),
                Mobile = COALESCE(?, Mobile),
                Phone1 = COALESCE(?, Phone1),
                Phone2 = CASE WHEN ? IS NULL THEN Phone2 ELSE ? END,
                Phone3 = CASE WHEN ? IS NULL THEN Phone3 ELSE ? END,
                Notes = CASE WHEN ? IS NULL THEN Notes ELSE ? END,
                ModifiedBy = ?,
                DateModified = GETDATE(),
                last_modified_time = GETDATE()
            WHERE CustomerNo = ?
            """,
            (
                display,
                display,
                mobile,
                p1,
                p2,
                p2,
                p3,
                p3,
                comments,
                comments,
                STAFF_USER_ID,
                customer_no,
            ),
        )
    except Exception as exc:
        log(f"⚠️ could not update customer {customer_no}: {exc}")


def insert_customer_address(
    cursor,
    *,
    address_id: int,
    customer_no: int,
    address: str,
    phones: str = "",
    is_primary: int = 0,
    zone_id: int = 2,
    zone_name: str = "الحى السابع",
    town_name: str = "مدينة نصر",
    gov_name: str = "القاهرة",
    building: str = "",
    floor: str = "",
    apartment: str = "",
    landmark: str = "",
    title: str = "",
) -> None:
    street = truncate(address, 2000, "بدون عنوان")
    full = truncate(address, 3000, street)
    cursor.execute(
        """
        INSERT INTO CustomerAddresses (
            AddressId, CustomerNo, Title,
            CountryId, CountryName,
            GovId, GovName, TownId, TownName,
            CityId, CityName,
            Building, Floor, Apartment, Landmark,
            StreetAddress, FullAddress, AddressPhones,
            IsPrimary, BranchId, AddedFrom, IsDisabled,
            NeedsConfirmation, IsConfirmed,
            AppVersion, DateCreated, DateModified,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            last_modified_time
        ) VALUES (
            ?, ?, ?,
            0, N'مصر',
            1, ?, 1, ?,
            ?, ?,
            ?, ?, ?, ?,
            ?, ?, ?,
            ?, ?, 0, 0,
            0, 0,
            ?, GETDATE(), GETDATE(),
            0, 0, 0, 0,
            GETDATE()
        )
        """,
        (
            address_id,
            customer_no,
            truncate(title, 100) or None,
            gov_name,
            town_name,
            zone_id,
            zone_name,
            truncate(building, 50) or None,
            truncate(floor, 50) or None,
            truncate(apartment, 50) or None,
            truncate(landmark, 200) or None,
            street,
            full,
            truncate(phones, 100) or None,
            int(is_primary),
            BRANCH_ID,
            APP_VERSION,
        ),
    )


def create_customer(
    cursor,
    *,
    name: str,
    phone: str,
    address: str,
    phone2: Optional[str] = None,
    phone3: Optional[str] = None,
    notes: Optional[str] = None,
) -> tuple[int, int]:
    seq_cust = next_hd_sequence(cursor, DOC_CUSTOMER, daily=False)
    customer_no = 2000000 + seq_cust
    seq_addr = next_hd_sequence(cursor, DOC_ADDRESS, daily=False)
    address_id = seq_addr

    display_name = truncate(name, 200, "عميل")
    mobile = truncate(phone, 20) or None
    p2 = truncate(phone2 or "", 20) or None
    p3 = truncate(phone3 or "", 20) or None
    phone_blob = " - ".join(p for p in (mobile, p2, p3) if p)

    cursor.execute(
        """
        INSERT INTO Customers (
            CustomerNo, ArabicName, EnglishName,
            CustomerType, CompanyId, BranchId,
            IsDisabled, RegistrationDate, CreatedFrom,
            Mobile, Phone1, Phone2, Phone3, DefaultAddressId, CustomerCategory,
            Notes, CreatedBy, ModifiedBy, AppVersion,
            DateCreated, DateModified,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            last_modified_time
        ) VALUES (
            ?, ?, ?,
            1, 0, 0,
            0, GETDATE(), 1,
            ?, ?, ?, ?, ?, 0,
            ?, ?, ?, ?,
            GETDATE(), GETDATE(),
            0, 0, 0, 0,
            GETDATE()
        )
        """,
        (
            customer_no,
            display_name,
            display_name,
            mobile,
            mobile,  # Phone1
            p2,
            p3,
            address_id,
            truncate(notes or "", 500) or None,
            STAFF_USER_ID,
            STAFF_USER_ID,
            APP_VERSION,
        ),
    )
    insert_customer_address(
        cursor,
        address_id=address_id,
        customer_no=customer_no,
        address=address,
        phones=phone_blob,
        is_primary=1,
        title="افتراضي",
    )
    return customer_no, address_id


def find_matching_address(
    cursor, *, customer_no: int, address: str
) -> Optional[int]:
    full = truncate(address, 3000, "").strip()
    if not full:
        return None
    cursor.execute(
        """
        SELECT AddressId, FullAddress, StreetAddress
        FROM CustomerAddresses
        WHERE CustomerNo = ? AND ISNULL(IsDisabled, 0) = 0
        ORDER BY AddressId DESC
        """,
        (customer_no,),
    )
    for row in cursor.fetchall() or []:
        existing = (str(row[1] or "").strip() or str(row[2] or "").strip())
        if existing == full:
            return int(row[0])
    return None


def ensure_address(
    cursor,
    *,
    customer_no: int,
    address_id: Optional[int],
    address: str,
    phones: str = "",
) -> int:
    full = truncate(address, 3000, "بدون عنوان")
    if address_id:
        cursor.execute(
            "SELECT FullAddress, StreetAddress FROM CustomerAddresses WHERE AddressId = ?",
            (address_id,),
        )
        row = cursor.fetchone()
        if row:
            existing = (str(row[0] or "").strip() or str(row[1] or "").strip())
            if existing == full.strip() or not (address or "").strip():
                return int(address_id)

    matched = find_matching_address(
        cursor, customer_no=customer_no, address=address
    )
    if matched is not None:
        return matched

    seq_addr = next_hd_sequence(cursor, DOC_ADDRESS, daily=False)
    new_id = seq_addr
    insert_customer_address(
        cursor,
        address_id=new_id,
        customer_no=customer_no,
        address=address,
        phones=phones,
        is_primary=0,
    )
    try:
        cursor.execute(
            """
            UPDATE Customers
            SET DefaultAddressId = ?, ModifiedBy = ?, DateModified = GETDATE(),
                last_modified_time = GETDATE()
            WHERE CustomerNo = ?
            """,
            (new_id, STAFF_USER_ID, customer_no),
        )
    except Exception:
        pass
    return new_id


def load_pos_customer_extras(
    pos_customer_id: Any,
) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """phone2 / phone3 / notes from Supabase pos_customers."""
    if not pos_customer_id:
        return None, None, None
    try:
        res = (
            supabase.table("pos_customers")
            .select("phone2, phone3, notes")
            .eq("id", pos_customer_id)
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if not rows:
            return None, None, None
        row = rows[0]
        p2 = normalize_phone(row.get("phone2")) or None
        p3 = normalize_phone(row.get("phone3")) or None
        notes = (str(row.get("notes") or "").strip() or None)
        return p2, p3, notes
    except Exception as exc:
        log(f"⚠️ pos_customers extras lookup failed: {exc}")
        return None, None, None


def write_back_customer_link(
    *,
    pos_customer_id: Any,
    customer_no: int,
    address_id: int,
    address: str,
) -> None:
    if not pos_customer_id:
        return
    try:
        supabase.table("pos_customers").update(
            {
                "fujitsu_customer_no": customer_no,
                "synced_to_fujitsu": True,
            }
        ).eq("id", pos_customer_id).execute()
    except Exception as exc:
        log(f"⚠️ pos_customers fujitsu_customer_no write-back failed: {exc}")
    try:
        res = (
            supabase.table("customer_addresses")
            .select("id, address")
            .eq("pos_customer_id", pos_customer_id)
            .execute()
        )
        for row in res.data or []:
            if (str(row.get("address") or "").strip() == (address or "").strip()):
                supabase.table("customer_addresses").update(
                    {"fujitsu_address_id": address_id}
                ).eq("id", row["id"]).execute()
                break
    except Exception as exc:
        log(f"⚠️ customer_addresses fujitsu_address_id write-back failed: {exc}")


def match_picker(cursor, preparer_name: str) -> tuple[int, str]:
    name = (preparer_name or "").strip()
    if name:
        cursor.execute(
            """
            SELECT TOP 1 picker_id, picker_arabic_name
            FROM hd_pickers
            WHERE LTRIM(RTRIM(picker_arabic_name)) = ?
            """,
            (name,),
        )
        row = cursor.fetchone()
        if row:
            return int(row[0]), truncate(str(row[1] or name), 150, DEFAULT_PICKER_NAME)
        cursor.execute(
            """
            SELECT TOP 1 picker_id, picker_arabic_name
            FROM hd_pickers
            WHERE picker_arabic_name LIKE ?
            """,
            (f"%{name}%",),
        )
        row = cursor.fetchone()
        if row:
            return int(row[0]), truncate(str(row[1] or name), 150, DEFAULT_PICKER_NAME)
    return DEFAULT_PICKER_ID, DEFAULT_PICKER_NAME


def lookup_item(cursor, barcode: str) -> Optional[dict[str, Any]]:
    """Prefer v_hd_items (Trusty item cache) then fall back to sys_item_units."""
    code = (barcode or "").strip()
    if not code:
        return None

    cursor.execute(
        """
        SELECT TOP 1
            LTRIM(RTRIM(CAST(ItemEan AS NVARCHAR(50)))) AS itemean,
            LTRIM(RTRIM(CAST(Barcode AS NVARCHAR(50)))) AS barcode,
            AName AS item_name,
            RetailPrice AS retail_price,
            Unit AS unit_code,
            ISNULL(Pieces, 1) AS pieces,
            CAST(ISNULL(ItemClass, 0) AS INT) AS class_id,
            ISNULL(ItemClassName, N'') AS class_name,
            CAST(ISNULL(ItemSection, 0) AS INT) AS section_id,
            ISNULL(ItemSectionName, N'') AS section_name,
            CAST(ISNULL(ItemGroup, 0) AS INT) AS group_id,
            ISNULL(ItemGroupName, N'') AS group_name,
            CAST(ISNULL(Department, 0) AS INT) AS department_id,
            ISNULL(DepartmentName, N'') AS department_name
        FROM dbo.v_hd_items
        WHERE LTRIM(RTRIM(CAST(Barcode AS NVARCHAR(50)))) = ?
        """,
        (code,),
    )
    row = cursor.fetchone()
    cost = 0.0
    if row:
        try:
            cursor.execute(
                """
                SELECT TOP 1 ISNULL(costprice, 0)
                FROM sys_item_units
                WHERE LTRIM(RTRIM(CAST(barcode AS NVARCHAR(50)))) = ?
                """,
                (code,),
            )
            crow = cursor.fetchone()
            if crow:
                cost = float(crow[0] or 0)
        except Exception:
            cost = 0.0
        return {
            "itemean": str(row.itemean or code).strip(),
            "barcode": str(row.barcode or code).strip(),
            "item_name": str(row.item_name or "").strip(),
            "retail_price": float(row.retail_price or 0),
            "cost_price": cost,
            "unit": int(row.unit_code or 1001),
            "pieces": int(row.pieces or 1),
            "class_id": int(row.class_id or 0),
            "class_name": str(row.class_name or "").strip(),
            "section_id": int(row.section_id or 0),
            "section_name": str(row.section_name or "").strip(),
            "group_id": int(row.group_id or 0),
            "group_name": str(row.group_name or "").strip(),
            "department_id": int(row.department_id or 0),
            "department_name": str(row.department_name or "").strip(),
        }

    cursor.execute(
        """
        SELECT TOP 1
            LTRIM(RTRIM(CAST(u.itemean AS NVARCHAR(50)))) AS itemean,
            LTRIM(RTRIM(CAST(u.barcode AS NVARCHAR(50)))) AS barcode,
            i.a_name AS item_name,
            u.retailprice AS retail_price,
            u.costprice AS cost_price,
            u.unit AS unit_code,
            ISNULL(u.peices, 1) AS pieces,
            CAST(ISNULL(i.itemclass, 0) AS INT) AS class_id,
            CAST(ISNULL(i.section, 0) AS INT) AS section_id,
            CAST(ISNULL(i.itemgroup, 0) AS INT) AS group_id,
            CAST(ISNULL(i.department, 0) AS INT) AS department_id
        FROM sys_item_units u
        JOIN sys_item i ON u.itemean = i.itemean
        WHERE LTRIM(RTRIM(CAST(u.barcode AS NVARCHAR(50)))) = ?
        """,
        (code,),
    )
    row = cursor.fetchone()
    if not row:
        return None
    return {
        "itemean": str(row.itemean or code).strip(),
        "barcode": str(row.barcode or code).strip(),
        "item_name": str(row.item_name or "").strip(),
        "retail_price": float(row.retail_price or 0),
        "cost_price": float(row.cost_price or 0),
        "unit": int(row.unit_code or 1001),
        "pieces": int(row.pieces or 1),
        "class_id": int(row.class_id or 0),
        "class_name": "",
        "section_id": int(row.section_id or 0),
        "section_name": "",
        "group_id": int(row.group_id or 0),
        "group_name": "",
        "department_id": int(row.department_id or 0),
        "department_name": "",
    }


def fetch_active_discounts(
    cursor, barcodes: list[str]
) -> dict[str, dict[str, Any]]:
    """
    Active item discounts (types 101=% / 102|3=fixed).

    Live retail: Func_ActiveItemDiscountsOf(101, …) returns 0 because many
    pos_promotion_items offers have no sys_discount_branchs row for branch 101.
    Use the function's @Branch<=0 body (same as Trusty yellow-star offers).
    """
    wanted = {(b or "").strip() for b in barcodes if (b or "").strip()}
    if not wanted:
        return {}
    try:
        cursor.execute(
            """
            SELECT
                LTRIM(RTRIM(CAST(barcode AS NVARCHAR(50)))) AS barcode,
                DiscountValue,
                DiscountNo,
                DiscountType
            FROM (
                SELECT
                    i.barcode,
                    i.discountvalue AS DiscountValue,
                    i.discountno AS DiscountNo,
                    d.discounttype AS DiscountType
                FROM sys_discount d WITH (NOLOCK)
                INNER JOIN sys_discount_items i WITH (NOLOCK)
                    ON d.discountno = i.discountno
                WHERE GETDATE() BETWEEN i.date_from AND i.date_to
                  AND d.discounttype IN (101, 102)
                  AND i.usage = 1

                UNION ALL

                SELECT
                    pi.barcode,
                    pi.sales_price - pi.prom_price,
                    pi.prom_id,
                    pi.prom_type
                FROM pos_promotion_items pi WITH (NOLOCK)
                WHERE pi.prom_type = 3
                  AND pi.postflag = 0
                  AND pi.sdate IS NOT NULL
                  AND pi.edate IS NOT NULL
                  AND GETDATE() BETWEEN pi.sdate AND pi.edate
            ) active_discounts
            """
        )
        out: dict[str, dict[str, Any]] = {}
        for row in cursor.fetchall() or []:
            bc = str(row[0] or "").strip()
            if not bc or bc not in wanted:
                continue
            out[bc] = {
                "discount_value": float(row[1] or 0),
                "discount_no": int(row[2] or 0),
                "discount_type": int(row[3] or 0),
            }
        return out
    except Exception as exc:
        log(f"⚠️ active-discount lookup failed: {exc}")
        return {}


def product_of(item: dict[str, Any]) -> dict[str, Any]:
    p = item.get("products")
    if isinstance(p, list) and p:
        p = p[0]
    return p if isinstance(p, dict) else {}


def merge_items_by_barcode(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Trusty: same barcode on one order → Qty += addedQty."""
    merged: dict[str, dict[str, Any]] = {}
    passthrough: list[dict[str, Any]] = []
    for item in items:
        product = product_of(item)
        barcode = str(product.get("barcode") or "").strip()
        qty = float(item.get("quantity") or 1)
        if qty <= 0:
            qty = 1.0
        if not barcode:
            passthrough.append(item)
            continue
        if barcode in merged:
            prev = merged[barcode]
            prev["quantity"] = float(prev.get("quantity") or 0) + qty
            # Keep first price_at_time (Trusty keeps original line price).
        else:
            copy = dict(item)
            copy["quantity"] = qty
            merged[barcode] = copy
    return list(merged.values()) + passthrough


def insert_hd_order_log(
    cursor,
    *,
    order_id: int,
    order_date: datetime,
    order_no: int,
    old_status: int,
    new_status: int,
    notes: str = "",
) -> None:
    """Trusty writes hd_order_log on every meaningful status change."""
    now = datetime.now()
    order_day = datetime(order_date.year, order_date.month, order_date.day)
    old_name = STATUS.get(old_status, "")
    new_name = STATUS.get(new_status, "")
    cursor.execute(
        """
        INSERT INTO hd_order_log (
            OrderId, OrderDate, OrderNo, SessionNo, TransTime,
            TransTerminalNo, TransBranch, TransUserCode, TransUserName,
            TransType, TransName,
            OldOrderBranch, NewOrderBranch, OldVersion, NewVersion,
            OldStatusCode, OldStatusName, NewStatusCode, NewStatusName,
            ReasonCode, ReasonName, Notes, TransData, ModifiedTime,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            DateCreated, DateModified
        ) VALUES (
            ?, ?, ?, 0, ?,
            ?, ?, ?, ?,
            0, N'',
            ?, ?, ?, ?,
            ?, ?, ?, ?,
            NULL, NULL, ?, NULL, ?,
            0, 0, 0, 0,
            GETDATE(), GETDATE()
        )
        """,
        (
            order_id,
            order_day,
            order_no,
            now,
            TERMINAL_NO,
            BRANCH_ID,
            STAFF_USER_ID,
            STAFF_USER_NAME,
            BRANCH_ID,
            BRANCH_ID,
            ORDER_VERSION,
            ORDER_VERSION,
            old_status,
            old_name,
            new_status,
            new_name,
            truncate(notes, 500) or None,
            now,
        ),
    )


def fetch_pending_orders() -> list[dict[str, Any]]:
    res = (
        supabase.table("orders")
        .select(
            "id, created_at, status, preparer_name, taker_name, "
            "customer_name, customer_phone, address_details, delivery_fee, "
            "total_amount, payment_method, order_source, pos_customer_id, "
            "fujitsu_order_id, fujitsu_address_id, fujitsu_synced_at"
        )
        .not_.is_("preparer_name", "null")
        .is_("fujitsu_order_id", "null")
        .neq("status", "cancelled")
        .order("created_at")
        .limit(20)
        .execute()
    )
    rows = res.data or []
    return [r for r in rows if str(r.get("preparer_name") or "").strip()]


def fetch_order_items(order_id: str) -> list[dict[str, Any]]:
    res = (
        supabase.table("order_items")
        .select(
            "id, quantity, price_at_time, weight_in_grams, "
            "products(name, barcode, price, discount_price)"
        )
        .eq("order_id", order_id)
        .execute()
    )
    return res.data or []


def insert_hd_order(
    cursor,
    *,
    order_id: int,
    order_date: datetime,
    order_no: int,
    picker_id: int,
    picker_name: str,
    taker_name: str,
    customer_no: int,
    customer_name: str,
    customer_phone: str,
    shipping_address: str,
    address_id: int,
    payment_method: int,
    delivery_fees: float,
    merchandise_total: float,
    order_discount: float,
    additional_fees: float,
    line_count: int,
    order_source: int,
    commit_prices: int = 0,
) -> float:
    """Insert header. Persisted TotalValue = NetTotalValue (Trusty)."""
    now = datetime.now()
    order_day = datetime(order_date.year, order_date.month, order_date.day)
    net_total = (
        float(merchandise_total)
        - float(order_discount)
        + float(delivery_fees)
        + float(additional_fees)
    )
    cursor.execute(
        """
        INSERT INTO hd_orders (
            OrderId, OrderVersion, OrderDate, OrderNo, TerminalNo, OrderBranch,
            StatusCode, StatusName, SessionNo, StartTime, TotalMinutes,
            TakerNo, TakerName, TakingStartTime, TakingEndTime, TakingMinutes,
            PickingDocPrintCount, PickerNo, PickerName,
            DeliveryDocPrintCount, IsReturned,
            CustomerNo, CustomerName, CustomerPhone, ShippingAddress,
            OrderLineCount, DiscountValue, DiscountNo, DiscountType, DiscountCoupon,
            PaymentMethod, DeliveryFees, AdditionalFees, TotalValue,
            OrderSource, CreatedTime, ModifiedTime, AddressId,
            GovId, GovName, TownId, TownName, CityId, CityName,
            IsFirstOrder, NeedsConfirmation, IsConfirmed, IsReviewed, CommitPrices,
            AppVersion, SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            DateCreated, DateModified, Reserved1
        ) VALUES (
            ?, ?, ?, ?, ?, ?,
            ?, ?, 0, ?, 0,
            ?, ?, ?, ?, 0,
            0, ?, ?,
            0, 0,
            ?, ?, ?, ?,
            ?, ?, 0, 0, NULL,
            ?, ?, ?, ?,
            ?, ?, ?, ?,
            1, N'القاهرة', 1, N'مدينة نصر', 2, N'الحى السابع',
            0, 0, 0, 0, ?,
            ?, 0, 0, 0, 0,
            GETDATE(), GETDATE(), ?
        )
        """,
        (
            order_id,
            ORDER_VERSION,
            order_day,
            order_no,
            TERMINAL_NO,
            BRANCH_ID,
            STATUS_WAITING_PREP,
            STATUS[STATUS_WAITING_PREP],
            now,
            STAFF_USER_ID,
            truncate(taker_name, 150, "التطبيق"),
            now,
            now,
            picker_id,
            truncate(picker_name, 150, DEFAULT_PICKER_NAME),
            customer_no,
            truncate(customer_name, 150, "عميل"),
            truncate(customer_phone, 200, "0"),
            truncate(shipping_address, 1000, "بدون عنوان"),
            line_count,
            float(order_discount),
            payment_method,
            delivery_fees,
            additional_fees,
            net_total,
            order_source,
            now,
            now,
            address_id,
            commit_prices,
            APP_VERSION,
            APP_VERSION,
        ),
    )
    return net_total


def insert_hd_order_item(
    cursor,
    *,
    order_id: int,
    order_no: int,
    order_date: datetime,
    line_no: int,
    customer_no: int,
    picker_id: int,
    picker_name: str,
    item: dict[str, Any],
    discount_info: Optional[dict[str, Any]] = None,
) -> float:
    """Insert one line. Returns line TotalValue (after discount)."""
    product = product_of(item)
    barcode = truncate(str(product.get("barcode") or ""), 20)
    item_name = truncate(str(product.get("name") or "صنف"), 150, "صنف")
    qty = float(item.get("quantity") or 1)
    if qty <= 0:
        qty = 1.0

    charged_unit = float(item.get("price_at_time") or 0)
    list_price = float(product.get("price") or charged_unit)

    fj = lookup_item(cursor, barcode) if barcode else None
    itemean = truncate((fj or {}).get("itemean") or barcode or f"UNK{line_no}", 20, "0")
    barcode = truncate(barcode or itemean, 20, itemean)
    retail = float((fj or {}).get("retail_price") or list_price or charged_unit)
    cost = float((fj or {}).get("cost_price") or 0)
    unit = int((fj or {}).get("unit") or 1001)
    pieces = int((fj or {}).get("pieces") or 1)
    if fj and fj.get("item_name"):
        item_name = truncate(fj["item_name"], 150, item_name)

    # Prefer active Fujitsu discount; else derive from charged vs retail.
    disc_no = 0
    disc_type = 0
    if discount_info:
        disc_no = int(discount_info.get("discount_no") or 0)
        disc_type = int(discount_info.get("discount_type") or 0)
        unit_disc = unit_discount_value(
            retail,
            float(discount_info.get("discount_value") or 0),
            disc_type,
        )
    else:
        unit_disc = max(0.0, retail - charged_unit) if charged_unit > 0 else 0.0

    discount_value = qty * unit_disc
    line_total = qty * retail - discount_value
    # If we only know charged price and no retail delta, keep charged math.
    if retail <= 0 and charged_unit > 0:
        line_total = charged_unit * qty
        discount_value = 0.0

    class_id = int((fj or {}).get("class_id") or 0)
    section_id = int((fj or {}).get("section_id") or 0)
    group_id = int((fj or {}).get("group_id") or 0)
    department_id = int((fj or {}).get("department_id") or 0)
    class_name = truncate((fj or {}).get("class_name") or "", 100)
    section_name = truncate((fj or {}).get("section_name") or "", 100)
    group_name = truncate((fj or {}).get("group_name") or "", 100)
    department_name = truncate((fj or {}).get("department_name") or "", 100)

    order_item_id = int(f"{order_id}{str(line_no).zfill(4)}")
    order_day = datetime(order_date.year, order_date.month, order_date.day)
    now = datetime.now()
    count = item_count_of(qty)

    cursor.execute(
        """
        INSERT INTO hd_order_items (
            OrderItemId, OrderItemVersion, OrderId, OrderVersion,
            OrderDate, OrderNo, TerminalNo, SessionNo, OrderLineNo, DocType,
            ItemEan, Barcode, ItemName, IsOpenItem,
            Qty, ItemCount, RetailPrice, CostPrice,
            DiscountValue, TotalValue, TaxValue, TaxRate,
            DiscountNo, DiscountType, DiscountCoupon,
            Unit, Pieces, TakerNo, IsPicked, PickerNo, PickerName,
            IsReturned, CustomerNo,
            ItemClass, ItemClassName, ItemSection, ItemSectionName,
            ItemGroup, ItemGroupName, ItemDepartment, ItemDepartmentName,
            RegistrationWay, SelectedFrom,
            CreatedTime, ModifiedTime,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            DateCreated, DateModified
        ) VALUES (
            ?, ?, ?, ?,
            ?, ?, ?, 0, ?, 2080,
            ?, ?, ?, 0,
            ?, ?, ?, ?,
            ?, ?, 0, 0,
            ?, ?, NULL,
            ?, ?, ?, 0, ?, ?,
            0, ?,
            ?, ?, ?, ?,
            ?, ?, ?, ?,
            3, 0,
            ?, ?,
            0, 0, 0, 0,
            GETDATE(), GETDATE()
        )
        """,
        (
            order_item_id,
            ORDER_VERSION,
            order_id,
            ORDER_VERSION,
            order_day,
            order_no,
            TERMINAL_NO,
            line_no,
            itemean,
            barcode,
            item_name,
            qty,
            count,
            retail,
            cost,
            discount_value,
            line_total,
            disc_no,
            disc_type,
            unit,
            pieces,
            STAFF_USER_ID,
            picker_id,
            truncate(picker_name, 150, DEFAULT_PICKER_NAME),
            customer_no,
            class_id,
            class_name,
            section_id,
            section_name,
            group_id,
            group_name,
            department_id,
            department_name,
            now,
            now,
        ),
    )
    return float(line_total)


def sync_one_order(order: dict[str, Any]) -> None:
    order_id = str(order["id"])
    phone = normalize_phone(order.get("customer_phone"))
    name = (order.get("customer_name") or "عميل").strip()
    address = (order.get("address_details") or "").strip()
    preparer = (order.get("preparer_name") or "").strip()
    taker = (order.get("taker_name") or "").strip() or "التطبيق"
    delivery_fee = float(order.get("delivery_fee") or 0)
    pay = payment_code(order.get("payment_method"))
    order_source = fujitsu_order_source(order.get("order_source"))
    pos_customer_id = order.get("pos_customer_id")
    preferred_address_id = order.get("fujitsu_address_id")
    try:
        preferred_address_id = (
            int(preferred_address_id) if preferred_address_id is not None else None
        )
    except (TypeError, ValueError):
        preferred_address_id = None

    phone2, phone3, notes = load_pos_customer_extras(pos_customer_id)
    phone_blob = " - ".join(p for p in (phone, phone2, phone3) if p)

    raw_items = fetch_order_items(order_id)
    if not raw_items:
        raise RuntimeError("order has no items")
    items = merge_items_by_barcode(raw_items)

    conn = connect_sql()
    cursor = conn.cursor()
    try:
        found = find_customer(cursor, phone)
        if found:
            customer_no, default_address_id = found
            update_customer_phones(
                cursor,
                customer_no=customer_no,
                phone=phone,
                phone2=phone2,
                phone3=phone3,
                name=name,
                notes=notes,
            )
            address_id = ensure_address(
                cursor,
                customer_no=customer_no,
                address_id=preferred_address_id or default_address_id,
                address=address,
                phones=phone_blob,
            )
        else:
            customer_no, address_id = create_customer(
                cursor,
                name=name,
                phone=phone,
                address=address,
                phone2=phone2,
                phone3=phone3,
                notes=notes,
            )

        seq = next_hd_sequence(cursor, DOC_ORDER, daily=True)
        order_day = datetime.now().strftime("%y%m%d")
        fujitsu_order_id_str = f"{order_day}{str(seq).zfill(6)}"
        fujitsu_order_id = int(fujitsu_order_id_str)

        picker_id, picker_name = match_picker(cursor, preparer)
        created_at = order.get("created_at")
        try:
            order_date = (
                datetime.fromisoformat(str(created_at).replace("Z", "+00:00"))
                .replace(tzinfo=None)
                if created_at
                else datetime.now()
            )
        except Exception:
            order_date = datetime.now()

        barcodes = [
            str(product_of(it).get("barcode") or "").strip() for it in items
        ]
        discounts = fetch_active_discounts(cursor, barcodes)

        # Insert lines first in memory totals, then header with NetTotalValue.
        # Actually Trusty saves header then items; we need merchandise sum first.
        # Compute using the same formulas without writing, then write header+items.
        # Simpler: write header with placeholder, update after lines — but
        # Trusty writes NetTotal in one shot. We pre-calc via a dry pass of math.
        merchandise = 0.0
        line_payloads: list[tuple[dict[str, Any], Optional[dict[str, Any]]]] = []
        for item in items:
            product = product_of(item)
            bc = str(product.get("barcode") or "").strip()
            disc = discounts.get(bc)
            # Approximate merchandise with the same insert math (lookup retail).
            fj = lookup_item(cursor, bc) if bc else None
            qty = float(item.get("quantity") or 1) or 1.0
            charged = float(item.get("price_at_time") or 0)
            list_price = float(product.get("price") or charged)
            retail = float((fj or {}).get("retail_price") or list_price or charged)
            if disc:
                unit_disc = unit_discount_value(
                    retail,
                    float(disc.get("discount_value") or 0),
                    int(disc.get("discount_type") or 0),
                )
            else:
                unit_disc = max(0.0, retail - charged) if charged > 0 else 0.0
            line_total = qty * retail - qty * unit_disc
            if retail <= 0 and charged > 0:
                line_total = charged * qty
            merchandise += line_total
            line_payloads.append((item, disc))

        net_total = insert_hd_order(
            cursor,
            order_id=fujitsu_order_id,
            order_date=order_date,
            order_no=seq,
            picker_id=picker_id,
            picker_name=picker_name,
            taker_name=taker,
            customer_no=customer_no,
            customer_name=name,
            customer_phone=phone or "0",
            shipping_address=address or "بدون عنوان",
            address_id=address_id,
            payment_method=pay,
            delivery_fees=delivery_fee,
            merchandise_total=merchandise,
            order_discount=0.0,
            additional_fees=0.0,
            line_count=len(line_payloads),
            order_source=order_source,
            commit_prices=0,
        )

        for line_no, (item, disc) in enumerate(line_payloads):
            insert_hd_order_item(
                cursor,
                order_id=fujitsu_order_id,
                order_no=seq,
                order_date=order_date,
                line_no=line_no,
                customer_no=customer_no,
                picker_id=picker_id,
                picker_name=picker_name,
                item=item,
                discount_info=disc,
            )

        # EndOrder → WaitingPicking (2). Log Taking(1) → WaitingPicking(2).
        insert_hd_order_log(
            cursor,
            order_id=fujitsu_order_id,
            order_date=order_date,
            order_no=seq,
            old_status=1,
            new_status=STATUS_WAITING_PREP,
            notes="safeer_market sync",
        )

        conn.commit()

        qr = build_qr(
            order_id=fujitsu_order_id_str,
            order_source=order_source,
            commit_prices=0,
            customer_no=customer_no,
            address_id=address_id,
            pilot_no=0,
            delivery_fees=delivery_fee,
        )

        write_back = {
            "fujitsu_order_id": fujitsu_order_id_str,
            "fujitsu_customer_no": customer_no,
            "fujitsu_address_id": address_id,
            "fujitsu_synced_at": datetime.utcnow().isoformat() + "Z",
            "fujitsu_sync_error": None,
            "pos_receipt_number": fujitsu_order_id_str,
            "fujitsu_status_code": STATUS_WAITING_PREP,
            "fujitsu_status_synced_at": datetime.utcnow().isoformat() + "Z",
        }
        try:
            supabase.table("orders").update(write_back).eq("id", order_id).execute()
        except Exception:
            write_back.pop("fujitsu_status_code", None)
            write_back.pop("fujitsu_status_synced_at", None)
            supabase.table("orders").update(write_back).eq("id", order_id).execute()

        write_back_customer_link(
            pos_customer_id=pos_customer_id,
            customer_no=customer_no,
            address_id=address_id,
            address=address,
        )

        log(
            f"✅ synced order {order_id[:8]}… → Fujitsu {fujitsu_order_id_str} "
            f"(customer {customer_no}, address {address_id}, net={net_total:.2f}, qr={qr})"
        )
    except Exception as exc:
        conn.rollback()
        err = str(exc)[:500]
        log(f"❌ sync failed for {order_id}: {err}")
        try:
            supabase.table("orders").update(
                {"fujitsu_sync_error": err}
            ).eq("id", order_id).execute()
        except Exception:
            pass
        raise
    finally:
        cursor.close()
        conn.close()


def _rebuild_fujitsu_items(
    *,
    order_id: str,
    fujitsu_order_id_str: str,
    customer_no: Any,
    preparer_name: str,
    created_at: Any,
    delivery_fee: float = 0.0,
    order_discount: float = 0.0,
    additional_fees: float = 0.0,
) -> None:
    """Replace hd_order_items and recalc header TotalValue = NetTotalValue."""
    if not fujitsu_order_id_str or fujitsu_order_id_str.upper() == "SKIPPED":
        return
    raw_items = fetch_order_items(order_id)
    items = merge_items_by_barcode(raw_items)
    conn = connect_sql()
    cursor = conn.cursor()
    try:
        fujitsu_order_id = int(fujitsu_order_id_str)
        order_no = int(fujitsu_order_id_str[-6:])
        try:
            order_date = (
                datetime.fromisoformat(str(created_at).replace("Z", "+00:00"))
                .replace(tzinfo=None)
                if created_at
                else datetime.now()
            )
        except Exception:
            order_date = datetime.now()
        picker_id, picker_name = match_picker(cursor, preparer_name)

        cursor.execute(
            "DELETE FROM hd_order_items WHERE OrderId = ?",
            (fujitsu_order_id,),
        )

        barcodes = [
            str(product_of(it).get("barcode") or "").strip() for it in items
        ]
        discounts = fetch_active_discounts(cursor, barcodes)

        merchandise = 0.0
        for line_no, item in enumerate(items):
            bc = str(product_of(item).get("barcode") or "").strip()
            merchandise += insert_hd_order_item(
                cursor,
                order_id=fujitsu_order_id,
                order_no=order_no,
                order_date=order_date,
                line_no=line_no,
                customer_no=int(customer_no or 0),
                picker_id=picker_id,
                picker_name=picker_name,
                item=item,
                discount_info=discounts.get(bc),
            )

        net_total = (
            merchandise
            - float(order_discount)
            + float(delivery_fee)
            + float(additional_fees)
        )
        cursor.execute(
            """
            UPDATE hd_orders
            SET OrderLineCount = ?,
                DeliveryFees = ?,
                DiscountValue = ?,
                AdditionalFees = ?,
                TotalValue = ?,
                ModifiedTime = GETDATE(),
                DateModified = GETDATE()
            WHERE OrderId = ?
            """,
            (
                len(items),
                float(delivery_fee),
                float(order_discount),
                float(additional_fees),
                net_total,
                fujitsu_order_id,
            ),
        )
        conn.commit()
        now_iso = datetime.utcnow().isoformat() + "Z"
        supabase.table("orders").update(
            {
                "fujitsu_synced_at": now_iso,
                "fujitsu_items_synced_at": now_iso,
                "fujitsu_sync_error": None,
            }
        ).eq("id", order_id).execute()
        log(f"🔁 Fujitsu items rebuilt for {fujitsu_order_id_str} net={net_total:.2f}")
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


def sync_edited_fujitsu_items() -> None:
    res = (
        supabase.table("orders")
        .select(
            "id, created_at, preparer_name, total_amount, delivery_fee, "
            "fujitsu_order_id, fujitsu_customer_no, "
            "items_updated_at, fujitsu_items_synced_at, is_being_edited"
        )
        .not_.is_("fujitsu_order_id", "null")
        .neq("fujitsu_order_id", "SKIPPED")
        .eq("is_being_edited", False)
        .not_.is_("items_updated_at", "null")
        .order("items_updated_at")
        .limit(20)
        .execute()
    )
    for order in res.data or []:
        fujitsu_order_id = str(order.get("fujitsu_order_id") or "").strip()
        items_updated = order.get("items_updated_at")
        items_synced = order.get("fujitsu_items_synced_at")
        if not fujitsu_order_id or not items_updated:
            continue
        if items_synced and str(items_updated) <= str(items_synced):
            continue
        try:
            _rebuild_fujitsu_items(
                order_id=str(order["id"]),
                fujitsu_order_id_str=fujitsu_order_id,
                customer_no=order.get("fujitsu_customer_no"),
                preparer_name=str(order.get("preparer_name") or ""),
                created_at=order.get("created_at"),
                delivery_fee=float(order.get("delivery_fee") or 0),
            )
        except Exception as exc:
            log(f"⚠️ edited-items sync failed for {fujitsu_order_id}: {exc}")


def sync_substitutions() -> None:
    alts = (
        supabase.table("order_item_alternatives")
        .select(
            "id, order_id, status, created_at, "
            "orders!inner(fujitsu_order_id, fujitsu_customer_no, fujitsu_synced_at, "
            "fujitsu_items_synced_at, preparer_name, created_at, total_amount, "
            "delivery_fee, is_being_edited)"
        )
        .in_("status", ["selected", "removed"])
        .not_.is_("orders.fujitsu_order_id", "null")
        .order("created_at", desc=True)
        .limit(50)
        .execute()
    )
    rows = alts.data or []
    if not rows:
        return

    seen_orders: set[str] = set()
    for alt in rows:
        order_id = str(alt.get("order_id") or "")
        if not order_id or order_id in seen_orders:
            continue
        order_wrap = alt.get("orders") or {}
        if isinstance(order_wrap, list):
            order_wrap = order_wrap[0] if order_wrap else {}
        if order_wrap.get("is_being_edited") is True:
            continue
        fujitsu_order_id_str = str(order_wrap.get("fujitsu_order_id") or "").strip()
        synced_at = (
            order_wrap.get("fujitsu_items_synced_at")
            or order_wrap.get("fujitsu_synced_at")
        )
        alt_created = alt.get("created_at")
        if not fujitsu_order_id_str or fujitsu_order_id_str.upper() == "SKIPPED":
            continue
        if synced_at and alt_created and str(alt_created) <= str(synced_at):
            continue
        seen_orders.add(order_id)
        try:
            _rebuild_fujitsu_items(
                order_id=order_id,
                fujitsu_order_id_str=fujitsu_order_id_str,
                customer_no=order_wrap.get("fujitsu_customer_no"),
                preparer_name=str(order_wrap.get("preparer_name") or ""),
                created_at=order_wrap.get("created_at"),
                delivery_fee=float(order_wrap.get("delivery_fee") or 0),
            )
        except Exception as exc:
            log(f"⚠️ substitution sync failed for {fujitsu_order_id_str}: {exc}")


def _apply_fujitsu_status(
    *,
    order_id: str,
    fujitsu_order_id_str: str,
    new_status: int,
    old_status: Optional[int],
    created_at: Any,
    cancel_reason: Optional[str] = None,
) -> None:
    if not fujitsu_order_id_str or fujitsu_order_id_str.upper() == "SKIPPED":
        return
    if old_status is not None and int(old_status) == int(new_status):
        return

    fujitsu_order_id = int(fujitsu_order_id_str)
    order_no = int(fujitsu_order_id_str[-6:])
    try:
        order_date = (
            datetime.fromisoformat(str(created_at).replace("Z", "+00:00"))
            .replace(tzinfo=None)
            if created_at
            else datetime.now()
        )
    except Exception:
        order_date = datetime.now()

    prev = int(old_status) if old_status is not None else STATUS_WAITING_PREP
    prev_name = STATUS.get(prev, "")
    new_name = STATUS.get(new_status, "")
    now = datetime.now()

    conn = connect_sql()
    cursor = conn.cursor()
    try:
        if new_status == STATUS_CANCELLED:
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?,
                    StatusName = ?,
                    CancelledBy = ?,
                    CancelledByName = ?,
                    CancelledAtStatusCode = StatusCode,
                    CancelReasonName = ?,
                    CancelTime = ?,
                    ModifiedTime = GETDATE(),
                    DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (
                    STATUS_CANCELLED,
                    STATUS[STATUS_CANCELLED],
                    STAFF_USER_ID,
                    STAFF_USER_NAME,
                    truncate(cancel_reason or "إلغاء من سفير ماركت", 200),
                    now,
                    fujitsu_order_id,
                ),
            )
        elif new_status == 3:
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    PickingStartedBy = ?, PickingStartedByName = ?,
                    PickingStartTime = COALESCE(PickingStartTime, ?),
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (new_status, new_name, STAFF_USER_ID, STAFF_USER_NAME, now, fujitsu_order_id),
            )
        elif new_status == 4:
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    PickingEndTime = ?,
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (new_status, new_name, now, fujitsu_order_id),
            )
        elif new_status == 5:
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    DeliveryStartedBy = ?, DeliveryStartedByName = ?,
                    DeliveryStartTime = COALESCE(DeliveryStartTime, ?),
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (new_status, new_name, STAFF_USER_ID, STAFF_USER_NAME, now, fujitsu_order_id),
            )
        elif new_status == 6:
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    DeliveryEndTime = ?, EndTime = ?,
                    ClosedBy = ?, ClosedByName = ?,
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (
                    new_status,
                    new_name,
                    now,
                    now,
                    STAFF_USER_ID,
                    STAFF_USER_NAME,
                    fujitsu_order_id,
                ),
            )
        else:
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (new_status, new_name, fujitsu_order_id),
            )

        insert_hd_order_log(
            cursor,
            order_id=fujitsu_order_id,
            order_date=order_date,
            order_no=order_no,
            old_status=prev,
            new_status=new_status,
            notes=cancel_reason or "safeer_market status sync",
        )
        conn.commit()

        supabase.table("orders").update(
            {
                "fujitsu_status_code": new_status,
                "fujitsu_status_synced_at": datetime.utcnow().isoformat() + "Z",
                "fujitsu_sync_error": None,
            }
        ).eq("id", order_id).execute()
        log(
            f"📦 status {fujitsu_order_id_str}: {prev}({prev_name}) → "
            f"{new_status}({new_name})"
        )
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


_STATUS_SYNC_DISABLED = False


def sync_status_and_cancellations() -> None:
    """Push Supabase status / cancel onto hd_orders + hd_order_log."""
    global _STATUS_SYNC_DISABLED
    if _STATUS_SYNC_DISABLED:
        return
    # Requires fujitsu_status_code watermark (migration 20261125230000).
    try:
        res = (
            supabase.table("orders")
            .select(
                "id, status, created_at, "
                "fujitsu_order_id, fujitsu_status_code"
            )
            .not_.is_("fujitsu_order_id", "null")
            .neq("fujitsu_order_id", "SKIPPED")
            .order("created_at", desc=True)
            .limit(40)
            .execute()
        )
    except Exception as exc:
        if "fujitsu_status_code" in str(exc):
            _STATUS_SYNC_DISABLED = True
            log(
                "⚠️ status sync disabled until migration "
                "20261125230000_trusty_qr_parity.sql is applied"
            )
            return
        log(f"⚠️ status sync query failed: {exc}")
        return
    for order in res.data or []:
        fujitsu_id = str(order.get("fujitsu_order_id") or "").strip()
        if not fujitsu_id:
            continue
        status_raw = str(order.get("status") or "").strip().lower()
        mapped = STATUS_MAP.get(status_raw)
        if mapped is None:
            continue
        prev = order.get("fujitsu_status_code")
        try:
            prev_i = int(prev) if prev is not None else None
        except (TypeError, ValueError):
            prev_i = None
        if prev_i is not None and prev_i == mapped:
            continue
        # Fresh sync leaves status at WaitingPicking(2); don't force pending→2 again.
        if prev_i is None and mapped == STATUS_WAITING_PREP:
            try:
                supabase.table("orders").update(
                    {
                        "fujitsu_status_code": STATUS_WAITING_PREP,
                        "fujitsu_status_synced_at": datetime.utcnow().isoformat() + "Z",
                    }
                ).eq("id", str(order["id"])).execute()
            except Exception:
                pass
            continue
        try:
            _apply_fujitsu_status(
                order_id=str(order["id"]),
                fujitsu_order_id_str=fujitsu_id,
                new_status=mapped,
                old_status=prev_i if prev_i is not None else STATUS_WAITING_PREP,
                created_at=order.get("created_at"),
                cancel_reason=None,
            )
        except Exception as exc:
            log(f"⚠️ status sync failed for {fujitsu_id}: {exc}")


def main() -> None:
    log(
        "🚀 sync_orders_to_fujitsu started (Trusty parity loop every "
        f"{POLL_SECONDS}s) → {SQL_SERVER}/{SQL_DATABASE}"
    )
    while True:
        try:
            pending = fetch_pending_orders()
            if pending:
                log(f"Found {len(pending)} order(s) awaiting Fujitsu sync")
            for order in pending:
                try:
                    sync_one_order(order)
                except Exception:
                    traceback.print_exc()
            try:
                sync_edited_fujitsu_items()
            except Exception:
                traceback.print_exc()
            try:
                sync_substitutions()
            except Exception:
                traceback.print_exc()
            try:
                sync_status_and_cancellations()
            except Exception:
                traceback.print_exc()
        except Exception as exc:
            log(f"loop error: {exc}")
            traceback.print_exc()
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
