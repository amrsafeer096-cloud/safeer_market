"""
Two-way delivery-order bridge: Supabase → Fujitsu POS (retail).

Picks up orders that already have preparer_name assigned, creates/matches the
customer in Fujitsu, allocates a real daily OrderId (YYMMDD######), inserts
hd_orders + hd_order_items, then writes the Fujitsu ids back to Supabase so
the Flutter prep-receipt QR can be scanned at the cashier.

Also reapplies approved item substitutions onto hd_order_items.

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
APP_VERSION = "1.0.0.56"
POLL_SECONDS = 5
DEFAULT_PICKER_ID = 10
DEFAULT_PICKER_NAME = "محضر"
STATUS_WAITING_PREP = 2
STATUS_WAITING_PREP_NAME = "فى إنتظار التجهيز"
STAFF_USER_ID = 7

# DocType codes in hd_sequence
DOC_CUSTOMER = 101
DOC_ADDRESS = 105
DOC_ORDER = 4


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


def next_hd_sequence(cursor, doc_type: int, *, daily: bool) -> int:
    """Atomically increment hd_sequence and return the new Sequence value."""
    today = date.today()
    if daily:
        # Ensure today's row exists, then increment in a separate statement so
        # pyodbc can reliably read OUTPUT INSERTED.Sequence.
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
    cursor.execute(
        """
        SELECT TOP 1 CustomerNo, DefaultAddressId
        FROM Customers
        WHERE REPLACE(REPLACE(REPLACE(ISNULL(Mobile,''),'+',''),' ',''),'-','') LIKE ?
           OR REPLACE(REPLACE(REPLACE(ISNULL(Phone1,''),'+',''),' ',''),'-','') LIKE ?
        ORDER BY CustomerNo DESC
        """,
        (f"%{phone}%", f"%{phone}%"),
    )
    row = cursor.fetchone()
    if not row:
        return None
    return int(row[0]), (int(row[1]) if row[1] is not None else None)


def insert_customer_address(
    cursor,
    *,
    address_id: int,
    customer_no: int,
    address: str,
) -> None:
    street = truncate(address, 2000, "بدون عنوان")
    full = truncate(address, 3000, street)
    cursor.execute(
        """
        INSERT INTO CustomerAddresses (
            AddressId, CustomerNo,
            CountryId, CountryName,
            GovId, GovName, TownId, TownName,
            CityId, CityName,
            Building, Floor, Apartment,
            StreetAddress, FullAddress,
            IsPrimary, BranchId, AddedFrom, IsDisabled,
            NeedsConfirmation, IsConfirmed,
            AppVersion, DateCreated, DateModified,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            last_modified_time
        ) VALUES (
            ?, ?,
            0, N'مصر',
            1, N'القاهرة', 1, N'مدينة نصر',
            2, N'الحى السابع',
            N'', N'', N'',
            ?, ?,
            0, ?, 0, 0,
            0, 0,
            ?, GETDATE(), GETDATE(),
            0, 0, 0, 0,
            GETDATE()
        )
        """,
        (address_id, customer_no, street, full, BRANCH_ID, APP_VERSION),
    )


def create_customer(
    cursor,
    *,
    name: str,
    phone: str,
    address: str,
) -> tuple[int, int]:
    seq_cust = next_hd_sequence(cursor, DOC_CUSTOMER, daily=False)
    customer_no = 2000000 + seq_cust
    seq_addr = next_hd_sequence(cursor, DOC_ADDRESS, daily=False)
    address_id = seq_addr

    display_name = truncate(name, 200, "عميل")
    mobile = truncate(phone, 20) or None

    cursor.execute(
        """
        INSERT INTO Customers (
            CustomerNo, ArabicName, EnglishName,
            CustomerType, CompanyId, BranchId,
            IsDisabled, RegistrationDate, CreatedFrom,
            Mobile, Phone1, DefaultAddressId, CustomerCategory,
            CreatedBy, ModifiedBy, AppVersion,
            DateCreated, DateModified,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            last_modified_time
        ) VALUES (
            ?, ?, ?,
            1, 0, 0,
            0, GETDATE(), 1,
            ?, ?, ?, 0,
            ?, ?, ?,
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
            mobile,
            address_id,
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
    )
    return customer_no, address_id


def ensure_address(
    cursor,
    *,
    customer_no: int,
    address_id: Optional[int],
    address: str,
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

    seq_addr = next_hd_sequence(cursor, DOC_ADDRESS, daily=False)
    new_id = seq_addr
    insert_customer_address(
        cursor,
        address_id=new_id,
        customer_no=customer_no,
        address=address,
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
    code = (barcode or "").strip()
    if not code:
        return None
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
        "section_id": int(row.section_id or 0),
        "group_id": int(row.group_id or 0),
        "department_id": int(row.department_id or 0),
    }


def fetch_pending_orders() -> list[dict[str, Any]]:
    # Real orders columns (no preparer_id): preparer_name, taker_name,
    # customer_name/phone, address_details, delivery_fee, total_amount,
    # payment_method, pos_customer_id + fujitsu_* write-back fields.
    res = (
        supabase.table("orders")
        .select(
            "id, created_at, status, preparer_name, taker_name, "
            "customer_name, customer_phone, address_details, delivery_fee, "
            "total_amount, payment_method, pos_customer_id, fujitsu_order_id, "
            "fujitsu_synced_at"
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


def product_of(item: dict[str, Any]) -> dict[str, Any]:
    p = item.get("products")
    if isinstance(p, list) and p:
        p = p[0]
    return p if isinstance(p, dict) else {}


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
    total_value: float,
    line_count: int,
) -> None:
    now = datetime.now()
    order_day = datetime(order_date.year, order_date.month, order_date.day)
    cursor.execute(
        """
        INSERT INTO hd_orders (
            OrderId, OrderVersion, OrderDate, OrderNo, TerminalNo, OrderBranch,
            StatusCode, StatusName, SessionNo, StartTime, TotalMinutes,
            TakerNo, TakerName, TakingStartTime, TakingEndTime, TakingMinutes,
            PickingDocPrintCount, PickerNo, PickerName,
            DeliveryDocPrintCount, IsReturned,
            CustomerNo, CustomerName, CustomerPhone, ShippingAddress,
            OrderLineCount, DiscountValue, PaymentMethod,
            DeliveryFees, AdditionalFees, TotalValue,
            OrderSource, CreatedTime, ModifiedTime, AddressId,
            GovId, GovName, TownId, TownName, CityId, CityName,
            IsFirstOrder, NeedsConfirmation, IsConfirmed, IsReviewed, CommitPrices,
            AppVersion, SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            DateCreated, DateModified, Reserved1
        ) VALUES (
            ?, 0, ?, ?, 0, ?,
            ?, ?, 0, ?, 0,
            ?, ?, ?, ?, 0,
            0, ?, ?,
            0, 0,
            ?, ?, ?, ?,
            ?, 0, ?,
            ?, 0, ?,
            0, ?, ?, ?,
            1, N'القاهرة', 1, N'مدينة نصر', 2, N'الحى السابع',
            0, 0, 0, 0, 0,
            ?, 0, 0, 0, 0,
            GETDATE(), GETDATE(), ?
        )
        """,
        (
            order_id,
            order_day,
            order_no,
            BRANCH_ID,
            STATUS_WAITING_PREP,
            STATUS_WAITING_PREP_NAME,
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
            payment_method,
            delivery_fees,
            total_value,
            now,
            now,
            address_id,
            APP_VERSION,
            APP_VERSION,
        ),
    )


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
) -> None:
    product = product_of(item)
    barcode = truncate(str(product.get("barcode") or ""), 20)
    item_name = truncate(str(product.get("name") or "صنف"), 150, "صنف")
    qty = float(item.get("quantity") or 1)
    if qty <= 0:
        qty = 1.0
    unit_price = float(item.get("price_at_time") or 0)
    list_price = float(product.get("price") or unit_price)
    discount = max(0.0, (list_price - unit_price) * qty)
    line_total = unit_price * qty

    fj = lookup_item(cursor, barcode) if barcode else None
    itemean = truncate((fj or {}).get("itemean") or barcode or f"UNK{line_no}", 20, "0")
    barcode = truncate(barcode or itemean, 20, itemean)
    retail = float((fj or {}).get("retail_price") or list_price or unit_price)
    cost = float((fj or {}).get("cost_price") or 0)
    unit = int((fj or {}).get("unit") or 1001)
    pieces = int((fj or {}).get("pieces") or 1)
    if fj and fj.get("item_name"):
        item_name = truncate(fj["item_name"], 150, item_name)

    class_id = int((fj or {}).get("class_id") or 0)
    section_id = int((fj or {}).get("section_id") or 0)
    group_id = int((fj or {}).get("group_id") or 0)
    department_id = int((fj or {}).get("department_id") or 0)

    order_item_id = int(f"{order_id}{str(line_no).zfill(4)}")
    order_day = datetime(order_date.year, order_date.month, order_date.day)
    now = datetime.now()

    cursor.execute(
        """
        INSERT INTO hd_order_items (
            OrderItemId, OrderItemVersion, OrderId, OrderVersion,
            OrderDate, OrderNo, TerminalNo, SessionNo, OrderLineNo, DocType,
            ItemEan, Barcode, ItemName, IsOpenItem,
            Qty, ItemCount, RetailPrice, CostPrice,
            DiscountValue, TotalValue, TaxValue, TaxRate,
            Unit, Pieces, TakerNo, IsPicked, PickerNo, PickerName,
            IsReturned, CustomerNo,
            ItemClass, ItemClassName, ItemSection, ItemSectionName,
            ItemGroup, ItemGroupName, ItemDepartment, ItemDepartmentName,
            RegistrationWay, SelectedFrom,
            CreatedTime, ModifiedTime,
            SourceRowVersion, CreatedRowVersion, CreatedAt, ModifiedAt,
            DateCreated, DateModified
        ) VALUES (
            ?, 0, ?, 0,
            ?, ?, 0, 0, ?, 2080,
            ?, ?, ?, 0,
            ?, ?, ?, ?,
            ?, ?, 0, 0,
            ?, ?, 0, 0, ?, ?,
            0, ?,
            ?, N'', ?, N'',
            ?, N'', ?, N'',
            3, 0,
            ?, ?,
            0, 0, 0, 0,
            GETDATE(), GETDATE()
        )
        """,
        (
            order_item_id,
            order_id,
            order_day,
            order_no,
            line_no,
            itemean,
            barcode,
            item_name,
            qty,
            int(round(qty)) if qty >= 1 else 1,
            retail,
            cost,
            discount,
            line_total,
            unit,
            pieces,
            picker_id,
            truncate(picker_name, 150, DEFAULT_PICKER_NAME),
            customer_no,
            class_id,
            section_id,
            group_id,
            department_id,
            now,
            now,
        ),
    )


def sync_one_order(order: dict[str, Any]) -> None:
    order_id = str(order["id"])
    phone = normalize_phone(order.get("customer_phone"))
    name = (order.get("customer_name") or "عميل").strip()
    address = (order.get("address_details") or "").strip()
    preparer = (order.get("preparer_name") or "").strip()
    taker = (order.get("taker_name") or "").strip() or "التطبيق"
    delivery_fee = float(order.get("delivery_fee") or 0)
    total_value = float(order.get("total_amount") or 0)
    pay = payment_code(order.get("payment_method"))

    items = fetch_order_items(order_id)
    if not items:
        raise RuntimeError("order has no items")

    conn = connect_sql()
    cursor = conn.cursor()
    try:
        found = find_customer(cursor, phone)
        if found:
            customer_no, address_id = found
            address_id = ensure_address(
                cursor,
                customer_no=customer_no,
                address_id=address_id,
                address=address,
            )
        else:
            customer_no, address_id = create_customer(
                cursor, name=name, phone=phone, address=address
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

        insert_hd_order(
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
            total_value=total_value,
            line_count=len(items),
        )

        # Fujitsu samples use 0-based OrderLineNo / OrderItemId suffix.
        for line_no, item in enumerate(items):
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
            )

        conn.commit()

        supabase.table("orders").update(
            {
                "fujitsu_order_id": fujitsu_order_id_str,
                "fujitsu_customer_no": customer_no,
                "fujitsu_address_id": address_id,
                "fujitsu_synced_at": datetime.utcnow().isoformat() + "Z",
                "fujitsu_sync_error": None,
                "pos_receipt_number": fujitsu_order_id_str,
            }
        ).eq("id", order_id).execute()

        log(
            f"✅ synced order {order_id[:8]}… → Fujitsu {fujitsu_order_id_str} "
            f"(customer {customer_no}, address {address_id})"
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


def sync_substitutions() -> None:
    """Push approved alternatives onto already-synced Fujitsu order lines."""
    alts = (
        supabase.table("order_item_alternatives")
        .select(
            "id, order_id, status, created_at, "
            "orders!inner(fujitsu_order_id, fujitsu_customer_no, fujitsu_synced_at, "
            "preparer_name, created_at)"
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
        fujitsu_order_id_str = str(order_wrap.get("fujitsu_order_id") or "").strip()
        customer_no = order_wrap.get("fujitsu_customer_no")
        synced_at = order_wrap.get("fujitsu_synced_at")
        alt_created = alt.get("created_at")
        if not fujitsu_order_id_str:
            continue
        if synced_at and alt_created and str(alt_created) <= str(synced_at):
            continue
        seen_orders.add(order_id)

        items = fetch_order_items(order_id)
        conn = connect_sql()
        cursor = conn.cursor()
        try:
            fujitsu_order_id = int(fujitsu_order_id_str)
            order_no = int(fujitsu_order_id_str[-6:])
            created_at = order_wrap.get("created_at")
            try:
                order_date = (
                    datetime.fromisoformat(str(created_at).replace("Z", "+00:00"))
                    .replace(tzinfo=None)
                    if created_at
                    else datetime.now()
                )
            except Exception:
                order_date = datetime.now()
            picker_id, picker_name = match_picker(
                cursor, str(order_wrap.get("preparer_name") or "")
            )

            cursor.execute(
                "DELETE FROM hd_order_items WHERE OrderId = ?",
                (fujitsu_order_id,),
            )
            for line_no, item in enumerate(items):
                insert_hd_order_item(
                    cursor,
                    order_id=fujitsu_order_id,
                    order_no=order_no,
                    order_date=order_date,
                    line_no=line_no,
                    customer_no=int(customer_no or 0),
                    picker_id=picker_id,
                    picker_name=picker_name,
                    item=item,
                )
            cursor.execute(
                """
                UPDATE hd_orders
                SET OrderLineCount = ?, ModifiedTime = GETDATE(),
                    DateModified = GETDATE()
                WHERE OrderId = ?
                """,
                (len(items), fujitsu_order_id),
            )
            conn.commit()
            supabase.table("orders").update(
                {
                    "fujitsu_synced_at": datetime.utcnow().isoformat() + "Z",
                    "fujitsu_sync_error": None,
                }
            ).eq("id", order_id).execute()
            log(f"🔁 substitutions applied on Fujitsu order {fujitsu_order_id_str}")
        except Exception as exc:
            conn.rollback()
            log(f"⚠️ substitution sync failed for {fujitsu_order_id_str}: {exc}")
        finally:
            cursor.close()
            conn.close()


def main() -> None:
    log(
        "🚀 sync_orders_to_fujitsu started (loop every "
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
                sync_substitutions()
            except Exception:
                traceback.print_exc()
        except Exception as exc:
            log(f"loop error: {exc}")
            traceback.print_exc()
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
