"""
Two-way delivery-order bridge: Supabase → Fujitsu POS (retail).

Parity target: TrustyDelivery (hd_orders / hd_order_items / hd_order_log /
Customers / CustomerAddresses / hd_sequence) + PosPrintouts QR.

Picks up newly placed orders (no fujitsu_order_id yet), creates/matches the
customer in Fujitsu, allocates a real daily OrderId (YYMMDD######) using the
Trusty ServerWorkingDate (GETDATE minus hd_settings «order processing
shift hours»), inserts hd_orders + hd_order_items at StatusCode=2 with
empty PickerNo/PickerName, writes hd_order_log, then writes Fujitsu ids
back to Supabase. When a preparer starts the order (status→preparing),
updates StatusCode=3 with the real PickerNo/PickerName.

Also:
  - rebuilds hd_order_items after edits / substitutions (barcode merge)
  - syncs cancellations → StatusCode 200 + audit log
  - syncs lifecycle status transitions + audit log
  - 2-way staff sync: Fujitsu hd_pickers ↔ staff(preparer) and
    sal_cashier(jobtype=2) pilots ↔ staff(driver)
  - on out_for_delivery/delivered writes real PilotNo/PilotName (not «طيار»)

Reuse the same SQL Server + Supabase config as sync_direct.py.
Run next to sync_direct.py:  python sync_orders_to_fujitsu.py
"""

from __future__ import annotations

import re
import time
import traceback
from datetime import date, datetime, timezone
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
STAFF_SYNC_INTERVAL_SECONDS = 300
# Back-compat alias (older loops / docs referred to picker-only sync).
PICKER_SYNC_INTERVAL_SECONDS = STAFF_SYNC_INTERVAL_SECONDS
DEFAULT_PICKER_ID = 10
DEFAULT_PICKER_NAME = "محضر"
# Fujitsu pilots live in sal_cashier with jobtype=2 (PilotNo = cashier).
FUJITSU_PILOT_JOBTYPE = 2
# In sal_cashier, status=0 is the value used by currently delivering pilots.
FUJITSU_PILOT_STATUS_ACTIVE = 0
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


def line_qty_and_unit_price(item: dict[str, Any]) -> tuple[float, float]:
    """Return (Qty, charged unit price).

    Weight lines store price_at_time as the *line total* with quantity=1 and
    weight_in_grams set → Qty is kg fraction, unit is per-kg charged.
    Piece lines store unit price × quantity.
    """
    grams_raw = item.get("weight_in_grams")
    try:
        grams = int(grams_raw) if grams_raw is not None else 0
    except (TypeError, ValueError):
        grams = 0
    stored = float(item.get("price_at_time") or 0)
    if grams > 0:
        # Exact kg to 3 decimals (1 g = 0.001 kg) — never coerce to int/quarters.
        qty = round(grams / 1000.0, 3)
        if qty <= 0:
            qty = 0.001
        unit = stored / qty if qty else stored
        return qty, unit
    qty = float(item.get("quantity") or 1)
    if qty <= 0:
        qty = 1.0
    return qty, stored


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


def _as_date(value: Any) -> date:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return date.fromisoformat(str(value)[:10])


def utc_now_iso() -> str:
    """UTC timestamp for Supabase write-backs (avoids deprecated utcnow())."""
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def order_processing_shift_hours(cursor) -> int:
    """Trusty hd_settings: «order processing shift hours» (positive hours)."""
    cursor.execute(
        """
        SELECT TOP 1 TRY_CAST(setting_value AS int)
        FROM hd_settings
        WHERE setting_name = N'order processing shift hours'
        """
    )
    row = cursor.fetchone()
    try:
        hours = int(row[0]) if row and row[0] is not None else 0
    except (TypeError, ValueError):
        hours = 0
    return abs(hours)


def sql_server_working_date(cursor) -> date:
    """Trusty ``ServerWorkingDate`` used for OrderDate / OrderId / GetPrepOrders.

    Exact Trusty filter (report §5 RefreshProcessingOrders / GetPrepOrders):
      OrderDate = CONVERT(date, DATEADD(hh, {offset}, GETDATE()))

    ``offset`` is ``-hd_settings['order processing shift hours']`` (e.g. -5), so
    until that many hours after midnight the business day is still yesterday —
    e.g. 02:30 on Nov 26 with shift=5 → working date Nov 25.

    Never use Python ``date.today()`` / ``utcnow()`` / plain ``CAST(GETDATE() AS DATE)``.
    """
    shift = order_processing_shift_hours(cursor)
    cursor.execute(
        """
        SELECT CONVERT(date, DATEADD(hh, ?, GETDATE()))
        """,
        (-shift,),
    )
    row = cursor.fetchone()
    if not row or row[0] is None:
        raise RuntimeError("SQL Server ServerWorkingDate returned no date")
    return _as_date(row[0])


def next_hd_sequence(cursor, doc_type: int, *, daily: bool) -> int:
    """Atomically increment hd_sequence and return the new Sequence value."""
    working = sql_server_working_date(cursor)
    if daily:
        cursor.execute(
            """
            IF NOT EXISTS (
                SELECT 1 FROM hd_sequence WITH (UPDLOCK, HOLDLOCK)
                WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
                  AND DocType = ? AND SequenceDate = ?
            )
            INSERT INTO hd_sequence
                (Branch, Param1, Param2, Param3, DocType, SequenceDate,
                 Sequence, ModifiedTime)
            VALUES (0, 0, 0, 0, ?, ?, 0, GETDATE());
            """,
            (doc_type, working, doc_type, working),
        )
        cursor.execute(
            """
            UPDATE hd_sequence
            SET Sequence = Sequence + 1,
                ModifiedTime = GETDATE()
            OUTPUT INSERTED.Sequence
            WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
              AND DocType = ? AND SequenceDate = ?;
            """,
            (doc_type, working),
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
            (doc_type, doc_type, working),
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


def allocate_daily_order_identity(cursor) -> tuple[int, int, date]:
    """Allocate a unique (OrderId, OrderNo, OrderDate) for DocType=4.

    Uses Trusty ServerWorkingDate (shift-hours business day). OrderNo =
    max(hd_sequence, MAX(OrderNo for that OrderDate))+1 and the resulting
    OrderId must not already exist in hd_orders.
    """
    working = sql_server_working_date(cursor)
    shift = order_processing_shift_hours(cursor)
    log(
        f"📅 ServerWorkingDate={working} "
        f"(GETDATE()-{shift}h order-processing shift)"
    )
    cursor.execute(
        """
        IF NOT EXISTS (
            SELECT 1 FROM hd_sequence WITH (UPDLOCK, HOLDLOCK)
            WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
              AND DocType = ? AND SequenceDate = ?
        )
        INSERT INTO hd_sequence
            (Branch, Param1, Param2, Param3, DocType, SequenceDate,
             Sequence, ModifiedTime)
        VALUES (0, 0, 0, 0, ?, ?, 0, GETDATE());
        """,
        (DOC_ORDER, working, DOC_ORDER, working),
    )

    cursor.execute(
        """
        SELECT ISNULL(MAX(OrderNo), 0)
        FROM hd_orders WITH (UPDLOCK, HOLDLOCK)
        WHERE CAST(OrderDate AS DATE) = ?
        """,
        (working,),
    )
    max_existing = int((cursor.fetchone() or [0])[0] or 0)

    cursor.execute(
        """
        SELECT Sequence
        FROM hd_sequence WITH (UPDLOCK, HOLDLOCK)
        WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
          AND DocType = ? AND SequenceDate = ?
        """,
        (DOC_ORDER, working),
    )
    seq_row = cursor.fetchone()
    seq_val = int(seq_row[0] or 0) if seq_row else 0

    order_no = max(seq_val, max_existing) + 1
    yymmdd = working.strftime("%y%m%d")

    for _ in range(50):
        order_id = int(f"{yymmdd}{str(order_no).zfill(6)}")
        cursor.execute(
            "SELECT 1 FROM hd_orders WHERE OrderId = ?",
            (order_id,),
        )
        if cursor.fetchone() is None:
            cursor.execute(
                """
                UPDATE hd_sequence
                SET Sequence = ?, ModifiedTime = GETDATE()
                WHERE Branch = 0 AND Param1 = 0 AND Param2 = 0 AND Param3 = 0
                  AND DocType = ? AND SequenceDate = ?
                """,
                (order_no, DOC_ORDER, working),
            )
            return order_id, order_no, working
        order_no += 1

    raise RuntimeError(
        f"Could not allocate unique OrderId for OrderDate={working}"
    )

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


def _distinct_phones(
    primary: Optional[str], *secondaries: Optional[str]
) -> tuple[Optional[str], Optional[str], Optional[str], Optional[str], list[str]]:
    """Mobile + up to 3 Fujitsu secondaries; also return all distinct phones.

    Fujitsu Customers has Mobile + Phone1..Phone3 (4 slots). Extra numbers
    (5th) are returned in ``all_phones`` for AddressPhones.
    """
    mobile = truncate(normalize_phone(primary) or (primary or ""), 20) or None
    seen = {mobile} if mobile else set()
    extras: list[str] = []
    all_phones: list[str] = ([mobile] if mobile else [])
    for raw in secondaries:
        normalized = normalize_phone(raw) or (str(raw).strip() if raw else "")
        p = truncate(normalized, 20) or None
        if not p or p in seen:
            continue
        seen.add(p)
        extras.append(p)
        all_phones.append(p)
    p1 = extras[0] if len(extras) > 0 else None
    p2 = extras[1] if len(extras) > 1 else None
    p3 = extras[2] if len(extras) > 2 else None
    return mobile, p1, p2, p3, all_phones


def update_customer_phones(
    cursor,
    *,
    customer_no: int,
    phone: str,
    phone2: Optional[str] = None,
    phone3: Optional[str] = None,
    phone4: Optional[str] = None,
    phone5: Optional[str] = None,
    name: Optional[str] = None,
    notes: Optional[str] = None,
) -> None:
    """Update Fujitsu customer phones without duplicating Mobile into Phone1."""
    mobile, p1, p2, p3, _ = _distinct_phones(
        phone, phone2, phone3, phone4, phone5
    )
    display = truncate(name or "", 200) or None
    comments = truncate(notes or "", 500) or None
    try:
        cursor.execute(
            """
            UPDATE Customers
            SET ArabicName = COALESCE(?, ArabicName),
                EnglishName = COALESCE(?, EnglishName),
                Mobile = COALESCE(?, Mobile),
                Phone1 = ?,
                Phone2 = ?,
                Phone3 = ?,
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
    phone4: Optional[str] = None,
    phone5: Optional[str] = None,
    notes: Optional[str] = None,
) -> tuple[int, int]:
    seq_cust = next_hd_sequence(cursor, DOC_CUSTOMER, daily=False)
    customer_no = 2000000 + seq_cust
    seq_addr = next_hd_sequence(cursor, DOC_ADDRESS, daily=False)
    address_id = seq_addr

    display_name = truncate(name, 200, "عميل")
    mobile, p1, p2, p3, all_phones = _distinct_phones(
        phone, phone2, phone3, phone4, phone5
    )
    phone_blob = " - ".join(all_phones)

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
            p1,  # distinct secondary only — never copy Mobile
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
) -> tuple[Optional[str], Optional[str], Optional[str], Optional[str], Optional[str]]:
    """phone2..phone5 / notes from Supabase pos_customers."""
    if not pos_customer_id:
        return None, None, None, None, None
    try:
        res = (
            supabase.table("pos_customers")
            .select("phone, phone2, phone3, phone4, phone5, notes")
            .eq("id", pos_customer_id)
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if not rows:
            return None, None, None, None, None
        row = rows[0]
        mobile = normalize_phone(row.get("phone")) or ""
        _, p2, p3, p4, all_phones = _distinct_phones(
            mobile,
            row.get("phone2"),
            row.get("phone3"),
            row.get("phone4"),
            row.get("phone5"),
        )
        p5 = all_phones[4] if len(all_phones) > 4 else None
        notes = (str(row.get("notes") or "").strip() or None)
        return p2, p3, p4, p5, notes
    except Exception as exc:
        log(f"⚠️ pos_customers extras lookup failed: {exc}")
        return None, None, None, None, None


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


def match_picker_optional(
    cursor, preparer_name: str
) -> Optional[tuple[int, str]]:
    name = (preparer_name or "").strip()
    if not name:
        return None
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
        return int(row[0]), truncate(str(row[1] or name).strip(), 150, name)
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
        return int(row[0]), truncate(str(row[1] or name).strip(), 150, name)
    return None


def match_picker(cursor, preparer_name: str) -> tuple[int, str]:
    found = match_picker_optional(cursor, preparer_name)
    if found:
        return found
    return DEFAULT_PICKER_ID, DEFAULT_PICKER_NAME


def _staff_picker_no(preparer_name: str) -> Optional[int]:
    """Exact PickerNo stored on Supabase staff after hd_pickers sync."""
    name = (preparer_name or "").strip()
    if not name:
        return None
    try:
        res = (
            supabase.table("staff")
            .select("fujitsu_picker_no, name")
            .eq("role", "preparer")
            .eq("name", name)
            .not_.is_("fujitsu_picker_no", "null")
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if not rows:
            # Trim / soft match on name (Fujitsu names often have trailing spaces).
            res = (
                supabase.table("staff")
                .select("fujitsu_picker_no, name")
                .eq("role", "preparer")
                .not_.is_("fujitsu_picker_no", "null")
                .limit(200)
                .execute()
            )
            needle = name.casefold()
            rows = [
                r
                for r in (res.data or [])
                if str(r.get("name") or "").strip().casefold() == needle
            ]
        if not rows:
            return None
        raw = rows[0].get("fujitsu_picker_no")
        return int(raw) if raw is not None else None
    except Exception as exc:
        log(f"⚠️ staff fujitsu_picker_no lookup failed: {exc}")
        return None


def resolve_picker(
    cursor, preparer_name: str, *, allow_default: bool = True
) -> tuple[int, str]:
    """Prefer synced staff.fujitsu_picker_no, else match hd_pickers by name.

    When [allow_default] is False (preparer start), never fall back to the
    generic «محضر» picker — keep the actual name with PickerNo=0 if unmatched.
    """
    name = (preparer_name or "").strip()
    if not name:
        return (
            (DEFAULT_PICKER_ID, DEFAULT_PICKER_NAME)
            if allow_default
            else (0, "")
        )

    picker_no = _staff_picker_no(name)
    if picker_no is not None:
        cursor.execute(
            """
            SELECT TOP 1 picker_id, picker_arabic_name
            FROM hd_pickers
            WHERE picker_id = ?
            """,
            (picker_no,),
        )
        row = cursor.fetchone()
        if row:
            return int(row[0]), truncate(str(row[1] or name).strip(), 150, name)
        return picker_no, truncate(name, 150)

    found = match_picker_optional(cursor, name)
    if found:
        return found
    if allow_default:
        return DEFAULT_PICKER_ID, DEFAULT_PICKER_NAME
    return 0, truncate(name, 150)


def _egypt_mobile(raw: Optional[str]) -> Optional[str]:
    phone_val = (raw or "").strip()
    if not re.fullmatch(r"01[0125]\d{8}", phone_val):
        return None
    return phone_val


def _norm_name(value: Optional[str]) -> str:
    return re.sub(r"\s+", " ", (value or "").strip()).casefold()


def _names_match(a: Optional[str], b: Optional[str]) -> bool:
    """Exact or containment match (e.g. «محمود» ↔ «محمود يحيي»)."""
    na, nb = _norm_name(a), _norm_name(b)
    if not na or not nb:
        return False
    return na == nb or na in nb or nb in na


def _is_junk_person_name(name: str) -> bool:
    """Skip masked / generic Fujitsu placeholders."""
    cleaned = (name or "").strip()
    if not cleaned:
        return True
    if set(cleaned) <= {"*", " "}:
        return True
    compact = re.sub(r"\s+", "", cleaned)
    if compact in {"طيار", "طيار1", "محضر"}:
        return True
    return False


def _find_staff_by_name(
    *,
    role: str,
    name: str,
    id_column: str,
) -> Optional[dict[str, Any]]:
    """Match a dashboard staff row missing its Fujitsu id (exact, then soft)."""
    needle = (name or "").strip()
    if not needle:
        return None
    try:
        exact = (
            supabase.table("staff")
            .select(f"id, name, {id_column}")
            .eq("role", role)
            .eq("name", needle)
            .is_(id_column, "null")
            .limit(1)
            .execute()
        )
        if exact.data:
            return exact.data[0]

        soft = (
            supabase.table("staff")
            .select(f"id, name, {id_column}")
            .eq("role", role)
            .is_(id_column, "null")
            .limit(200)
            .execute()
        )
        hits = [
            r
            for r in (soft.data or [])
            if _names_match(str(r.get("name") or ""), needle)
        ]
        if len(hits) == 1:
            return hits[0]
    except Exception as exc:
        log(f"⚠️ staff name lookup ({role}/{needle}) failed: {exc}")
    return None


def sync_fujitsu_pickers(cursor) -> int:
    """Upsert active/inactive hd_pickers into public.staff (role=preparer).

    Manual dashboard preparers (no fujitsu_picker_no) are kept. Matching names
    without a Fujitsu id get fujitsu_picker_no attached when possible.
    """
    cursor.execute(
        """
        SELECT
            picker_id,
            LTRIM(RTRIM(picker_arabic_name)) AS picker_name,
            LTRIM(RTRIM(ISNULL(Phone, N''))) AS phone,
            CAST(ISNULL(active, 0) AS INT) AS is_active
        FROM hd_pickers
        WHERE picker_arabic_name IS NOT NULL
          AND LTRIM(RTRIM(picker_arabic_name)) <> N''
        """
    )
    rows = cursor.fetchall() or []
    if not rows:
        return 0

    changed = 0
    for picker_id, picker_name, phone, is_active in rows:
        name = (picker_name or "").strip()
        if not name or _is_junk_person_name(name):
            continue
        pid = int(picker_id)
        active = int(is_active or 0) == 1
        phone_val = _egypt_mobile(phone)

        try:
            by_id = (
                supabase.table("staff")
                .select("id, name, phone, is_active")
                .eq("fujitsu_picker_no", pid)
                .limit(1)
                .execute()
            )
            existing = (by_id.data or [None])[0]
            if existing:
                patch: dict[str, Any] = {}
                if str(existing.get("name") or "").strip() != name:
                    patch["name"] = name
                if phone_val and str(existing.get("phone") or "").strip() != phone_val:
                    patch["phone"] = phone_val
                if bool(existing.get("is_active", True)) != active:
                    patch["is_active"] = active
                if patch:
                    supabase.table("staff").update(patch).eq(
                        "id", existing["id"]
                    ).execute()
                    changed += 1
                continue

            named = _find_staff_by_name(
                role="preparer", name=name, id_column="fujitsu_picker_no"
            )
            if named:
                patch = {"fujitsu_picker_no": pid, "is_active": active}
                if phone_val:
                    patch["phone"] = phone_val
                supabase.table("staff").update(patch).eq(
                    "id", named["id"]
                ).execute()
                changed += 1
                continue

            if not active:
                continue

            payload: dict[str, Any] = {
                "name": name,
                "role": "preparer",
                "fujitsu_picker_no": pid,
                "is_active": True,
            }
            if phone_val:
                payload["phone"] = phone_val
            supabase.table("staff").insert(payload).execute()
            changed += 1
        except Exception as exc:
            log(f"⚠️ picker upsert {pid}/{name} failed: {exc}")
    return changed


def sync_fujitsu_pilots(cursor) -> int:
    """Upsert sal_cashier pilots (jobtype=2) into public.staff (role=driver).

    PilotNo on hd_orders is sal_cashier.cashier. Phone is stored in l_name.
    status=0 means active for currently delivering pilots.
    """
    cursor.execute(
        """
        SELECT
            cashier,
            LTRIM(RTRIM(ISNULL(a_name, ''))) AS pilot_name,
            LTRIM(RTRIM(ISNULL(l_name, ''))) AS phone,
            CAST(ISNULL(status, 1) AS INT) AS status_code
        FROM sal_cashier
        WHERE jobtype = ?
          AND a_name IS NOT NULL
          AND LTRIM(RTRIM(a_name)) <> ''
        """,
        (FUJITSU_PILOT_JOBTYPE,),
    )
    rows = cursor.fetchall() or []
    if not rows:
        return 0

    changed = 0
    for cashier, pilot_name, phone, status_code in rows:
        name = (pilot_name or "").strip()
        if not name or _is_junk_person_name(name):
            continue
        pid = int(cashier)
        active = int(status_code) == FUJITSU_PILOT_STATUS_ACTIVE
        phone_val = _egypt_mobile(phone)

        try:
            by_id = (
                supabase.table("staff")
                .select("id, name, phone, is_active")
                .eq("fujitsu_pilot_no", pid)
                .limit(1)
                .execute()
            )
            existing = (by_id.data or [None])[0]
            if existing:
                patch: dict[str, Any] = {}
                if str(existing.get("name") or "").strip() != name:
                    patch["name"] = name
                if phone_val and str(existing.get("phone") or "").strip() != phone_val:
                    patch["phone"] = phone_val
                if bool(existing.get("is_active", True)) != active:
                    patch["is_active"] = active
                if patch:
                    supabase.table("staff").update(patch).eq(
                        "id", existing["id"]
                    ).execute()
                    changed += 1
                continue

            named = _find_staff_by_name(
                role="driver", name=name, id_column="fujitsu_pilot_no"
            )
            if named:
                patch = {"fujitsu_pilot_no": pid, "is_active": active}
                if phone_val:
                    patch["phone"] = phone_val
                # Keep the dashboard short name (e.g. محمود) when it already
                # soft-matches the Fujitsu full name.
                supabase.table("staff").update(patch).eq(
                    "id", named["id"]
                ).execute()
                changed += 1
                continue

            if not active:
                continue

            payload: dict[str, Any] = {
                "name": name,
                "role": "driver",
                "fujitsu_pilot_no": pid,
                "is_active": True,
            }
            if phone_val:
                payload["phone"] = phone_val
            supabase.table("staff").insert(payload).execute()
            changed += 1
        except Exception as exc:
            log(f"⚠️ pilot upsert {pid}/{name} failed: {exc}")
    return changed


def _next_picker_id(cursor) -> int:
    cursor.execute("SELECT ISNULL(MAX(picker_id), 0) + 1 FROM hd_pickers")
    return int((cursor.fetchone() or [1])[0] or 1)


def _next_pilot_cashier_no(cursor) -> int:
    """Allocate the next PilotNo in the modern 1xxx range (avoid 8xxxx legacy)."""
    cursor.execute(
        """
        SELECT ISNULL(MAX(cashier), 1000) + 1
        FROM sal_cashier
        WHERE cashier >= 1000 AND cashier < 80000
        """
    )
    candidate = int((cursor.fetchone() or [1001])[0] or 1001)
    while True:
        cursor.execute(
            "SELECT 1 FROM sal_cashier WHERE cashier = ?", (candidate,)
        )
        if not cursor.fetchone():
            return candidate
        candidate += 1


def push_new_staff_pickers(cursor) -> int:
    """Insert dashboard preparers missing fujitsu_picker_no into hd_pickers."""
    try:
        res = (
            supabase.table("staff")
            .select("id, name, phone, is_active")
            .eq("role", "preparer")
            .is_("fujitsu_picker_no", "null")
            .eq("is_active", True)
            .limit(100)
            .execute()
        )
    except Exception as exc:
        log(f"⚠️ push pickers query failed: {exc}")
        return 0

    pushed = 0
    for row in res.data or []:
        name = str(row.get("name") or "").strip()
        if not name or _is_junk_person_name(name):
            continue
        phone_val = _egypt_mobile(str(row.get("phone") or ""))
        try:
            # Re-use an existing Fujitsu picker with the same name when present.
            cursor.execute(
                """
                SELECT TOP 1 picker_id
                FROM hd_pickers
                WHERE LTRIM(RTRIM(picker_arabic_name)) = ?
                ORDER BY picker_id
                """,
                (name,),
            )
            existing = cursor.fetchone()
            if existing:
                pid = int(existing[0])
            else:
                pid = _next_picker_id(cursor)
                cursor.execute(
                    """
                    INSERT INTO hd_pickers (
                        picker_id, picker_arabic_name, picker_english_name,
                        active, branch_id, last_modified_time, Phone
                    ) VALUES (?, ?, N'', 1, ?, GETDATE(), ?)
                    """,
                    (pid, truncate(name, 50), BRANCH_ID, phone_val or ""),
                )
            supabase.table("staff").update(
                {"fujitsu_picker_no": pid}
            ).eq("id", row["id"]).execute()
            pushed += 1
            log(f"👷 pushed preparer «{name}» → hd_pickers #{pid}")
        except Exception as exc:
            log(f"⚠️ push preparer {name} failed: {exc}")
    return pushed


def push_new_staff_pilots(cursor) -> int:
    """Insert dashboard drivers missing fujitsu_pilot_no into sal_cashier."""
    try:
        res = (
            supabase.table("staff")
            .select("id, name, phone, is_active")
            .eq("role", "driver")
            .is_("fujitsu_pilot_no", "null")
            .eq("is_active", True)
            .limit(100)
            .execute()
        )
    except Exception as exc:
        log(f"⚠️ push pilots query failed: {exc}")
        return 0

    pushed = 0
    for row in res.data or []:
        name = str(row.get("name") or "").strip()
        if not name or _is_junk_person_name(name):
            continue
        phone_val = _egypt_mobile(str(row.get("phone") or "")) or ""
        try:
            cursor.execute(
                """
                SELECT TOP 1 cashier, a_name
                FROM sal_cashier
                WHERE jobtype = ?
                  AND LTRIM(RTRIM(a_name)) = ?
                ORDER BY cashier
                """,
                (FUJITSU_PILOT_JOBTYPE, name),
            )
            existing = cursor.fetchone()
            if existing:
                pid = int(existing[0])
            else:
                # Soft-match full Fujitsu names («محمود يحيي») to short dashboard names.
                cursor.execute(
                    """
                    SELECT cashier, LTRIM(RTRIM(a_name)) AS a_name
                    FROM sal_cashier
                    WHERE jobtype = ?
                      AND a_name IS NOT NULL
                    """,
                    (FUJITSU_PILOT_JOBTYPE,),
                )
                soft_hits = [
                    r
                    for r in (cursor.fetchall() or [])
                    if _names_match(str(r[1] or ""), name)
                    and not _is_junk_person_name(str(r[1] or ""))
                ]
                if len(soft_hits) == 1:
                    pid = int(soft_hits[0][0])
                else:
                    pid = _next_pilot_cashier_no(cursor)
                    cursor.execute(
                        """
                        INSERT INTO sal_cashier (
                            cashier, a_name, l_name, company, branch, job,
                            education, hire_date, commission, status, govern,
                            city, emp_privileges, user_id, password,
                            accesslevel, jobtype, ledger, subledger,
                            last_modified_time
                        ) VALUES (
                            ?, ?, ?, NULL, ?, NULL,
                            NULL, NULL, 0, ?, NULL,
                            NULL, NULL, NULL, NULL,
                            0, ?, NULL, NULL,
                            GETDATE()
                        )
                        """,
                        (
                            pid,
                            truncate(name, 50),
                            truncate(phone_val, 50) if phone_val else "",
                            BRANCH_ID,
                            FUJITSU_PILOT_STATUS_ACTIVE,
                            FUJITSU_PILOT_JOBTYPE,
                        ),
                    )
            supabase.table("staff").update(
                {"fujitsu_pilot_no": pid}
            ).eq("id", row["id"]).execute()
            pushed += 1
            log(f"🛵 pushed pilot «{name}» → sal_cashier #{pid}")
        except Exception as exc:
            log(f"⚠️ push pilot {name} failed: {exc}")
    return pushed


def sync_fujitsu_staff(cursor) -> tuple[int, int, int, int]:
    """Pull Fujitsu pickers/pilots then push any new dashboard-only staff."""
    pulled_pickers = sync_fujitsu_pickers(cursor)
    pulled_pilots = sync_fujitsu_pilots(cursor)
    pushed_pickers = push_new_staff_pickers(cursor)
    pushed_pilots = push_new_staff_pilots(cursor)
    return pulled_pickers, pulled_pilots, pushed_pickers, pushed_pilots


def _staff_pilot_no(driver_name: str) -> Optional[int]:
    """Exact / soft PilotNo from public.staff after sal_cashier sync."""
    name = (driver_name or "").strip()
    if not name:
        return None
    try:
        res = (
            supabase.table("staff")
            .select("fujitsu_pilot_no, name")
            .eq("role", "driver")
            .eq("name", name)
            .not_.is_("fujitsu_pilot_no", "null")
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if not rows:
            res = (
                supabase.table("staff")
                .select("fujitsu_pilot_no, name")
                .eq("role", "driver")
                .not_.is_("fujitsu_pilot_no", "null")
                .limit(200)
                .execute()
            )
            rows = [
                r
                for r in (res.data or [])
                if _names_match(str(r.get("name") or ""), name)
            ]
        if not rows:
            return None
        raw = rows[0].get("fujitsu_pilot_no")
        return int(raw) if raw is not None else None
    except Exception as exc:
        log(f"⚠️ staff fujitsu_pilot_no lookup failed: {exc}")
        return None


def resolve_pilot(cursor, driver_name: str) -> tuple[int, str]:
    """Prefer staff.fujitsu_pilot_no, else match sal_cashier pilots by name.

    Never falls back to a generic «طيار» placeholder — unmatched keeps the
    real name with PilotNo=0.
    """
    name = (driver_name or "").strip()
    if not name:
        return 0, ""

    pilot_no = _staff_pilot_no(name)
    if pilot_no is not None:
        cursor.execute(
            """
            SELECT TOP 1 cashier, LTRIM(RTRIM(a_name))
            FROM sal_cashier
            WHERE cashier = ? AND jobtype = ?
            """,
            (pilot_no, FUJITSU_PILOT_JOBTYPE),
        )
        row = cursor.fetchone()
        if row:
            return int(row[0]), truncate(str(row[1] or name).strip(), 150, name)
        return pilot_no, truncate(name, 150)

    cursor.execute(
        """
        SELECT TOP 1 cashier, LTRIM(RTRIM(a_name))
        FROM sal_cashier
        WHERE jobtype = ?
          AND LTRIM(RTRIM(a_name)) = ?
        ORDER BY cashier
        """,
        (FUJITSU_PILOT_JOBTYPE, name),
    )
    row = cursor.fetchone()
    if row:
        return int(row[0]), truncate(str(row[1] or name).strip(), 150, name)

    cursor.execute(
        """
        SELECT cashier, LTRIM(RTRIM(a_name))
        FROM sal_cashier
        WHERE jobtype = ?
          AND a_name IS NOT NULL
        """,
        (FUJITSU_PILOT_JOBTYPE,),
    )
    soft = [
        r
        for r in (cursor.fetchall() or [])
        if _names_match(str(r[1] or ""), name)
        and not _is_junk_person_name(str(r[1] or ""))
    ]
    if len(soft) == 1:
        return int(soft[0][0]), truncate(str(soft[0][1] or name).strip(), 150, name)

    return 0, truncate(name, 150)


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
    """Trusty: same barcode on one order → Qty += addedQty (kg for weight)."""
    merged: dict[str, dict[str, Any]] = {}
    passthrough: list[dict[str, Any]] = []
    for item in items:
        product = product_of(item)
        barcode = str(product.get("barcode") or "").strip()
        qty, _ = line_qty_and_unit_price(item)
        if qty <= 0:
            qty = 1.0
        if not barcode:
            passthrough.append(item)
            continue
        if barcode in merged:
            prev = merged[barcode]
            prev_qty, _ = line_qty_and_unit_price(prev)
            new_qty = round(prev_qty + qty, 3)
            prev_grams = int(prev.get("weight_in_grams") or 0)
            add_grams = int(item.get("weight_in_grams") or 0)
            if prev_grams > 0 or add_grams > 0:
                total_grams = prev_grams + add_grams
                prev["weight_in_grams"] = total_grams
                prev["quantity"] = 1
                # Line totals (price_at_time) sum for weight lines.
                prev["price_at_time"] = float(prev.get("price_at_time") or 0) + float(
                    item.get("price_at_time") or 0
                )
            else:
                prev["quantity"] = new_qty
            # Keep first charged unit when piece lines merge.
        else:
            copy = dict(item)
            if int(item.get("weight_in_grams") or 0) > 0:
                copy["quantity"] = 1
            else:
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
    """Orders ready for first Fujitsu insert (no fujitsu_order_id yet).

    Syncs immediately after «إتمام وتسجيل الطلب» into إنتظار التجهيز (2)
    with empty picker — does NOT wait for a preparer.
    """
    res = (
        supabase.table("orders")
        .select(
            "id, created_at, status, preparer_name, taker_name, "
            "customer_name, customer_phone, address_details, delivery_fee, "
            "total_amount, payment_method, order_source, pos_customer_id, "
            "fujitsu_order_id, fujitsu_address_id, fujitsu_synced_at"
        )
        .is_("fujitsu_order_id", "null")
        .neq("status", "cancelled")
        .neq("status", "canceled")
        .order("created_at")
        .limit(20)
        .execute()
    )
    return list(res.data or [])


def fetch_order_items(order_id: str) -> list[dict[str, Any]]:
    res = (
        supabase.table("order_items")
        .select(
            "id, quantity, price_at_time, weight_in_grams, notes, "
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
            int(picker_id or 0),
            # Empty string is intentional for إنتظار التجهيز (no preparer yet).
            truncate(picker_name, 150, ""),
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
    qty, charged_unit = line_qty_and_unit_price(item)
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
            CustomerNotes, Notes,
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
            int(picker_id or 0),
            truncate(picker_name, 150, ""),
            customer_no,
            class_id,
            class_name,
            section_id,
            section_name,
            group_id,
            group_name,
            department_id,
            department_name,
            truncate(str(item.get("notes") or "").strip() or None, 1000) or None,
            truncate(str(item.get("notes") or "").strip() or None, 1000) or None,
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

    phone2, phone3, phone4, phone5, notes = load_pos_customer_extras(
        pos_customer_id
    )
    _, phone2, phone3, phone4, all_phones = _distinct_phones(
        phone, phone2, phone3, phone4, phone5
    )
    phone_blob = " - ".join(all_phones)

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
                phone4=phone4,
                phone5=phone5,
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
                phone4=phone4,
                phone5=phone5,
                notes=notes,
            )

        # First insert always lands in إنتظار التجهيز with empty picker.
        # Preparer name/PickerNo are written later when status → 3.
        _ = preparer  # reserved for status-3 sync only
        picker_id, picker_name = 0, ""

        fujitsu_order_id, seq, working_date = allocate_daily_order_identity(cursor)
        fujitsu_order_id_str = str(fujitsu_order_id)
        # OrderDate must match Trusty ServerWorkingDate used in OrderId /
        # GetPrepOrders (shift-hours business day — not calendar midnight).
        order_date = datetime(
            working_date.year, working_date.month, working_date.day
        )

        # Hard guard: never overwrite an existing Fujitsu order header.
        cursor.execute(
            "SELECT 1 FROM hd_orders WHERE OrderId = ?",
            (fujitsu_order_id,),
        )
        if cursor.fetchone():
            raise RuntimeError(
                f"OrderId {fujitsu_order_id_str} already exists — refusing overwrite"
            )

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
            qty, charged = line_qty_and_unit_price(item)
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

        cursor.execute(
            """
            SELECT COUNT(*) FROM hd_order_items
            WHERE OrderId = ? AND OrderVersion = ?
            """,
            (fujitsu_order_id, ORDER_VERSION),
        )
        inserted = int((cursor.fetchone() or [0])[0] or 0)
        if inserted != len(line_payloads):
            raise RuntimeError(
                f"hd_order_items count mismatch for {fujitsu_order_id_str}: "
                f"expected {len(line_payloads)}, got {inserted}"
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
            "fujitsu_synced_at": utc_now_iso(),
            "fujitsu_sync_error": None,
            "pos_receipt_number": fujitsu_order_id_str,
            "fujitsu_status_code": STATUS_WAITING_PREP,
            "fujitsu_status_synced_at": utc_now_iso(),
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
        picker_id, picker_name = resolve_picker(cursor, preparer_name)

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

        cursor.execute(
            """
            SELECT COUNT(*) FROM hd_order_items
            WHERE OrderId = ? AND OrderVersion = ?
            """,
            (fujitsu_order_id, ORDER_VERSION),
        )
        inserted = int((cursor.fetchone() or [0])[0] or 0)
        if inserted != len(items):
            raise RuntimeError(
                f"rebuild item count mismatch for {fujitsu_order_id_str}: "
                f"expected {len(items)}, got {inserted}"
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
        now_iso = utc_now_iso()
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
    preparer_name: str = "",
    driver_name: str = "",
) -> None:
    if not fujitsu_order_id_str or fujitsu_order_id_str.upper() == "SKIPPED":
        return
    if old_status is not None and int(old_status) == int(new_status):
        return

    fujitsu_order_id = int(fujitsu_order_id_str)
    order_no = int(fujitsu_order_id_str[-6:])

    prev = int(old_status) if old_status is not None else STATUS_WAITING_PREP
    prev_name = STATUS.get(prev, "")
    new_name = STATUS.get(new_status, "")
    now = datetime.now()

    conn = connect_sql()
    cursor = conn.cursor()
    try:
        # Prefer the OrderDate already stored on the Fujitsu header (Cairo day).
        cursor.execute(
            "SELECT TOP 1 OrderDate FROM hd_orders WHERE OrderId = ?",
            (fujitsu_order_id,),
        )
        row = cursor.fetchone()
        if row and row[0] is not None:
            raw = row[0]
            order_date = raw if isinstance(raw, datetime) else datetime(
                raw.year, raw.month, raw.day
            )
        else:
            try:
                order_date = (
                    datetime.fromisoformat(str(created_at).replace("Z", "+00:00"))
                    .replace(tzinfo=None)
                    if created_at
                    else datetime.now()
                )
            except Exception:
                order_date = datetime.now()

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
            picker_id, picker_name = resolve_picker(
                cursor, preparer_name, allow_default=False
            )
            started_by_name = truncate(
                picker_name or preparer_name, 150, preparer_name or STAFF_USER_NAME
            )
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    PickerNo = ?,
                    PickerName = ?,
                    PickingStartedBy = ?,
                    PickingStartedByName = ?,
                    PickingStartTime = COALESCE(PickingStartTime, ?),
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (
                    new_status,
                    new_name,
                    int(picker_id or 0),
                    truncate(picker_name or preparer_name, 150, ""),
                    STAFF_USER_ID,
                    started_by_name,
                    now,
                    fujitsu_order_id,
                ),
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
            pilot_no, pilot_name = resolve_pilot(cursor, driver_name)
            started_by_name = truncate(
                pilot_name or driver_name, 150, driver_name or STAFF_USER_NAME
            )
            # Never write the generic «طيار» placeholder.
            if _is_junk_person_name(started_by_name):
                started_by_name = truncate(driver_name, 150, STAFF_USER_NAME)
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    PilotNo = ?,
                    PilotName = ?,
                    DeliveryStartedBy = ?, DeliveryStartedByName = ?,
                    DeliveryStartTime = COALESCE(DeliveryStartTime, ?),
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (
                    new_status,
                    new_name,
                    int(pilot_no or 0),
                    truncate(pilot_name or driver_name, 150, ""),
                    STAFF_USER_ID,
                    started_by_name,
                    now,
                    fujitsu_order_id,
                ),
            )
        elif new_status == 6:
            pilot_no, pilot_name = resolve_pilot(cursor, driver_name)
            closed_by_name = truncate(
                pilot_name or driver_name, 150, driver_name or STAFF_USER_NAME
            )
            if _is_junk_person_name(closed_by_name):
                closed_by_name = truncate(driver_name, 150, STAFF_USER_NAME)
            cursor.execute(
                """
                UPDATE hd_orders
                SET PreviousStatusCode = StatusCode,
                    PreviousStatusName = StatusName,
                    StatusCode = ?, StatusName = ?,
                    PilotNo = CASE
                        WHEN ? > 0 THEN ?
                        ELSE PilotNo
                    END,
                    PilotName = CASE
                        WHEN LTRIM(RTRIM(?)) <> N'' THEN ?
                        ELSE PilotName
                    END,
                    DeliveryStartedByName = CASE
                        WHEN LTRIM(RTRIM(?)) <> N''
                             AND (DeliveryStartedByName IS NULL
                                  OR LTRIM(RTRIM(DeliveryStartedByName)) IN (N'', N'طيار', N'طيار '))
                        THEN ?
                        ELSE DeliveryStartedByName
                    END,
                    DeliveryEndTime = ?, EndTime = ?,
                    ClosedBy = ?, ClosedByName = ?,
                    ModifiedTime = GETDATE(), DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (
                    new_status,
                    new_name,
                    int(pilot_no or 0),
                    int(pilot_no or 0),
                    truncate(pilot_name or driver_name, 150, ""),
                    truncate(pilot_name or driver_name, 150, ""),
                    closed_by_name,
                    closed_by_name,
                    now,
                    now,
                    STAFF_USER_ID,
                    closed_by_name,
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

        log_notes = cancel_reason or "safeer_market status sync"
        if new_status in (5, 6) and (driver_name or "").strip():
            log_notes = f"{log_notes} · pilot {(driver_name or '').strip()}"
        insert_hd_order_log(
            cursor,
            order_id=fujitsu_order_id,
            order_date=order_date,
            order_no=order_no,
            old_status=prev,
            new_status=new_status,
            notes=log_notes,
        )
        conn.commit()

        supabase.table("orders").update(
            {
                "fujitsu_status_code": new_status,
                "fujitsu_status_synced_at": utc_now_iso(),
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
                "id, status, created_at, preparer_name, driver_name, "
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
                        "fujitsu_status_synced_at": utc_now_iso(),
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
                preparer_name=str(order.get("preparer_name") or ""),
                driver_name=str(order.get("driver_name") or ""),
            )
        except Exception as exc:
            log(f"⚠️ status sync failed for {fujitsu_id}: {exc}")


def main() -> None:
    log(
        "🚀 sync_orders_to_fujitsu started (Trusty parity loop every "
        f"{POLL_SECONDS}s) → {SQL_SERVER}/{SQL_DATABASE}"
    )
    last_staff_sync = 0.0
    while True:
        try:
            now_ts = time.time()
            if now_ts - last_staff_sync >= STAFF_SYNC_INTERVAL_SECONDS:
                try:
                    conn = connect_sql()
                    try:
                        cur = conn.cursor()
                        pulled_p, pulled_d, pushed_p, pushed_d = sync_fujitsu_staff(
                            cur
                        )
                        conn.commit()
                        if pulled_p:
                            log(f"👷 synced/updated {pulled_p} Fujitsu preparer(s)")
                        if pulled_d:
                            log(f"🛵 synced/updated {pulled_d} Fujitsu pilot(s)")
                        if pushed_p:
                            log(f"👷 pushed {pushed_p} new preparer(s) → hd_pickers")
                        if pushed_d:
                            log(f"🛵 pushed {pushed_d} new pilot(s) → sal_cashier")
                    except Exception:
                        conn.rollback()
                        raise
                    finally:
                        conn.close()
                except Exception as exc:
                    log(f"⚠️ staff/picker/pilot sync failed: {exc}")
                last_staff_sync = now_ts

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
