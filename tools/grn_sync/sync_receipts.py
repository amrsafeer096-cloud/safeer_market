"""Pull pending goods receipts from Supabase and insert Fujitsu GRNs.

Reads public.app_receipts (status = 'pending') and public.app_receipt_items,
then writes one unposted goods receipt:

    dbo.stk_order        company=1, branch=101, transtype=201, doctype=2010
    dbo.stk_order_items  same order number, one row per scanned barcode

Rows are written through Fujitsu's own procedures, the same ones the
handheld (PDA) calls: dbo.sp_stk_order for the header and
dbo.sp_stk_order_items for each line. sp_stk_order takes the order number
from dbo.sys_sequence. Numbering any other way (e.g. max(orderno) + 1)
leaves that counter behind, so the next handheld GRN is handed a number
the sync already used, and Fujitsu rejects it as a supplier mismatch.

A successful insert is committed before the receipt is marked 'synced'.
The Supabase id is stored in stk_order.Reserved1 so a retry after a failed
status update does not create a second GRN.

Runs continuously, polling every SYNC_INTERVAL_SECONDS (default 30).
--once runs a single pass; --dry-run runs a single pass without writing.

dbo.sys_supplier is also copied to public.app_suppliers, the list the app
searches: at start-up and then every SUPPLIER_REFRESH_SECONDS (default 600).
--suppliers copies it once and exits.
"""

from __future__ import annotations

import logging
import os
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from pathlib import Path
from typing import Any

import pyodbc
from dotenv import load_dotenv
from supabase import Client, create_client

# sp_stk_order derives company, sector and region from the branch; these are
# only used to look rows up.
COMPANY = 1
SECTOR = 1
REGION = 1
BRANCH = 101
SECTION = 0
TRANSTYPE = 201
DOCTYPE = 2010
SITES_SECTION = 0
DEFAULT_USER_ID = 24

# sp_stk_order_items stores barcode as char(20) and quantity as decimal(13,2).
BARCODE_MAX = 20
FREE_QTY = Decimal("0")

# Each attempt that hits a number already in stk_order burns that number,
# exactly as it does on the handheld.
MAX_NUMBER_ATTEMPTS = 20

DEFAULT_INTERVAL_SECONDS = 30
DEFAULT_SUPPLIER_REFRESH_SECONDS = 600

RECEIPT_TAG = "app:"

log = logging.getLogger("grn_sync")


class ReceiptDataError(Exception):
    """The receipt cannot be turned into a GRN until its data is fixed."""


@dataclass(frozen=True)
class Supplier:
    number: int
    arabic_name: str
    latin_name: str | None


@dataclass(frozen=True)
class ResolvedLine:
    barcode: str
    quantity: int
    itemean: str
    unit: int


def main() -> int:
    load_dotenv(Path(__file__).with_name(".env"))
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    _configure_stdio()
    dry_run = "--dry-run" in sys.argv
    once = dry_run or "--once" in sys.argv
    interval = int(_env("SYNC_INTERVAL_SECONDS", str(DEFAULT_INTERVAL_SECONDS)))

    supplier_refresh = int(
        _env("SUPPLIER_REFRESH_SECONDS", str(DEFAULT_SUPPLIER_REFRESH_SECONDS))
    )

    supabase = create_client(_env("SUPABASE_URL"), _env("SUPABASE_SERVICE_ROLE_KEY"))
    if "--suppliers" in sys.argv:
        return publish_suppliers(supabase)
    if once:
        return sync_pending(supabase, dry_run)

    log.info("Polling for pending receipts every %s seconds", interval)
    suppliers_published_at = 0.0
    while True:
        if time.monotonic() - suppliers_published_at >= supplier_refresh:
            try:
                publish_suppliers(supabase)
            except Exception:
                log.exception("Supplier refresh crashed")
            suppliers_published_at = time.monotonic()
        try:
            sync_pending(supabase, dry_run)
        except Exception:
            log.exception("Sync pass crashed")
        try:
            time.sleep(interval)
        except KeyboardInterrupt:
            log.info("Stopped")
            return 0


def sync_pending(supabase: Client, dry_run: bool) -> int:
    """One pass over the pending receipts. Returns 1 if any receipt failed."""
    try:
        receipts = fetch_pending_receipts(supabase)
    except Exception as error:
        log.error("Could not read pending receipts: %s", error)
        return 1
    if not receipts:
        return 0
    log.info("Pending receipts: %s", len(receipts))

    try:
        connection = connect_sql()
    except pyodbc.Error as error:
        log.error("Could not connect to SQL Server: %s", error)
        return 1

    user_id = int(_env("SYNC_USER_ID", str(DEFAULT_USER_ID)))
    try:
        cursor = connection.cursor()
        cursor.execute("SET LOCK_TIMEOUT 15000")
        connection.commit()
        suppliers = load_suppliers(cursor)
        failures = 0
        for receipt in receipts:
            try:
                sync_receipt(cursor, supabase, suppliers, receipt, user_id, dry_run)
            except ReceiptDataError as error:
                failures += 1
                _rollback(connection)
                log.error("Receipt %s rejected: %s", receipt.get("id"), error)
                if not dry_run:
                    try:
                        mark_status(supabase, str(receipt["id"]), "failed")
                    except Exception as update_error:
                        log.error(
                            "Could not mark receipt %s failed: %s",
                            receipt.get("id"),
                            update_error,
                        )
            except Exception as error:
                failures += 1
                _rollback(connection)
                log.error("Receipt %s left pending: %s", receipt.get("id"), error)
        log.info("Finished. failed=%s dry_run=%s", failures, dry_run)
        return 1 if failures else 0
    finally:
        connection.close()


def publish_suppliers(supabase: Client) -> int:
    """Upsert every sys_supplier row into app_suppliers. Returns 1 on failure."""
    try:
        connection = connect_sql()
    except pyodbc.Error as error:
        log.error("Could not connect to SQL Server: %s", error)
        return 1
    try:
        suppliers = load_suppliers(connection.cursor())
    finally:
        connection.close()

    now = datetime.now().astimezone().isoformat()
    rows = [
        {
            "supplier_no": supplier.number,
            "name": supplier.arabic_name.strip()
            or (supplier.latin_name or "").strip()
            or str(supplier.number),
            "updated_at": now,
        }
        for supplier in suppliers
    ]
    try:
        supabase.table("app_suppliers").upsert(rows, on_conflict="supplier_no").execute()
    except Exception as error:
        log.error("Could not publish suppliers: %s", error)
        return 1
    log.info("Published %s suppliers to app_suppliers", len(rows))
    return 0


def sync_receipt(
    cursor: pyodbc.Cursor,
    supabase: Client,
    suppliers: list[Supplier],
    receipt: dict[str, Any],
    user_id: int,
    dry_run: bool,
) -> None:
    receipt_id = str(receipt["id"])
    supplier_name = str(receipt.get("supplier_name") or "").strip()
    if not supplier_name:
        raise ReceiptDataError("supplier name is empty")

    items = receipt.get("app_receipt_items") or []
    if not items:
        raise ReceiptDataError("receipt has no lines")

    supplier_no = resolve_supplier(suppliers, supplier_name, receipt.get("supplier_no"))
    lines = [resolve_line(cursor, item) for item in _sorted_items(items)]
    connection_commit_reads(cursor)

    existing = find_existing_order(cursor, receipt_id)
    if existing is not None:
        log.info("Receipt %s already stored as orderno %s", receipt_id, existing)
        if not dry_run:
            mark_status(supabase, receipt_id, "synced")
        return

    if dry_run:
        # Runs the real procedures, then rolls back, which also restores sys_sequence.
        order_no = insert_grn(cursor, receipt_id, supplier_no, lines, user_id, commit=False)
        _rollback(cursor.connection)
        log.info(
            "Dry run %s -> orderno %s supplier %s (%s) lines %s",
            receipt_id,
            order_no,
            supplier_no,
            supplier_name,
            [(line.barcode, line.quantity, line.itemean, line.unit) for line in lines],
        )
        return

    order_no = insert_grn(cursor, receipt_id, supplier_no, lines, user_id)
    # Status is updated only after SQL Server commits. Reserved1 makes a
    # later run skip the insert if this update does not get through.
    mark_status(supabase, receipt_id, "synced")
    log.info("Synced receipt %s as orderno %s", receipt_id, order_no)


def fetch_pending_receipts(supabase: Client) -> list[dict[str, Any]]:
    response = (
        supabase.table("app_receipts")
        .select(
            "id, supplier_no, supplier_name, created_at, "
            "app_receipt_items(id, barcode, quantity, created_at)"
        )
        .eq("status", "pending")
        # Returns are not GRNs; they stay pending until return sync exists.
        .eq("transaction_type", "receive")
        .order("created_at")
        .execute()
    )
    return list(response.data or [])


def connect_sql() -> pyodbc.Connection:
    driver = _env("MSSQL_DRIVER", "SQL Server")
    if not driver.startswith("{"):
        driver = "{" + driver + "}"
    server = _env("MSSQL_SERVER")
    port = os.environ.get("MSSQL_PORT", "").strip()
    if port:
        server = f"{server},{port}"

    connection_string = (
        f"DRIVER={driver};"
        f"SERVER={server};"
        f"DATABASE={_odbc(_env('MSSQL_DATABASE'))};"
        f"UID={_odbc(_env('MSSQL_USER'))};"
        f"PWD={_odbc(_env('MSSQL_PASSWORD'))};"
    )
    connection = pyodbc.connect(connection_string, timeout=15)
    # stk_order notes and supplier names are varchar under Arabic_CI_AS.
    connection.setdecoding(pyodbc.SQL_CHAR, encoding="cp1256")
    connection.setdecoding(pyodbc.SQL_WCHAR, encoding="utf-16le")
    connection.setencoding(encoding="cp1256")
    connection.autocommit = False
    return connection


def load_suppliers(cursor: pyodbc.Cursor) -> list[Supplier]:
    cursor.execute(
        """
        SELECT supplierno, a_name, l_name
        FROM dbo.sys_supplier
        """
    )
    suppliers = [
        Supplier(
            number=int(row.supplierno),
            arabic_name=str(row.a_name or ""),
            latin_name=None if row.l_name is None else str(row.l_name),
        )
        for row in cursor.fetchall()
    ]
    connection_commit_reads(cursor)
    log.info("Loaded %s suppliers", len(suppliers))
    return suppliers


def resolve_supplier(
    suppliers: list[Supplier], supplier_name: str, supplier_no: Any = None
) -> int:
    if supplier_no is not None:
        number = int(supplier_no)
        if any(supplier.number == number for supplier in suppliers):
            return number
        raise ReceiptDataError(f"supplier code {number} is not in sys_supplier")

    target = _norm(supplier_name)
    if target.isdigit():
        number = int(target)
        if any(supplier.number == number for supplier in suppliers):
            return number

    exact = [supplier for supplier in suppliers if _names_match(supplier, target)]
    if len(exact) == 1:
        return exact[0].number
    if len(exact) > 1:
        raise ReceiptDataError(f"supplier name matches more than one code: {supplier_name}")

    partial = [
        supplier
        for supplier in suppliers
        if _name_contains(supplier, target)
    ]
    if len(partial) == 1:
        return partial[0].number
    if len(partial) > 1:
        raise ReceiptDataError(f"supplier name is ambiguous: {supplier_name}")
    raise ReceiptDataError(f"no supplier matches {supplier_name!r}")


def resolve_line(cursor: pyodbc.Cursor, item: dict[str, Any]) -> ResolvedLine:
    barcode = str(item.get("barcode") or "").strip()
    if not barcode:
        raise ReceiptDataError("a line has an empty barcode")
    if len(barcode) > BARCODE_MAX:
        raise ReceiptDataError(f"barcode longer than {BARCODE_MAX} characters: {barcode}")

    try:
        quantity = int(item["quantity"])
    except (KeyError, TypeError, ValueError) as error:
        raise ReceiptDataError(f"invalid quantity for {barcode}") from error
    if quantity <= 0:
        raise ReceiptDataError(f"quantity for {barcode} must be positive")

    # sp_stk_order_items resolves the item the same way; an unknown barcode
    # would make it insert a NULL itemean and fail.
    cursor.execute(
        """
        SELECT TOP 1 RTRIM(itemean) AS itemean, unit
        FROM dbo.sys_item_units
        WHERE barcode = ?
        """,
        barcode,
    )
    row = cursor.fetchone()
    if row is None or not str(row.itemean or "").strip():
        raise ReceiptDataError(f"barcode {barcode} is not in sys_item_units")

    return ResolvedLine(
        barcode=barcode,
        quantity=quantity,
        itemean=str(row.itemean).strip(),
        unit=int(row.unit),
    )


def find_existing_order(cursor: pyodbc.Cursor, receipt_id: str) -> int | None:
    cursor.execute(
        """
        SELECT TOP 1 orderno
        FROM dbo.stk_order
        WHERE company = ?
          AND sector = ?
          AND region = ?
          AND branch = ?
          AND section = ?
          AND transtype = ?
          AND doctype = ?
          AND Reserved1 = ?
        """,
        COMPANY,
        SECTOR,
        REGION,
        BRANCH,
        SECTION,
        TRANSTYPE,
        DOCTYPE,
        _receipt_tag(receipt_id),
    )
    row = cursor.fetchone()
    connection_commit_reads(cursor)
    if row is None:
        return None
    return int(row.orderno)


def insert_grn(
    cursor: pyodbc.Cursor,
    receipt_id: str,
    supplier_no: int,
    lines: list[ResolvedLine],
    user_id: int,
    *,
    commit: bool = True,
) -> int:
    """Create the draft GRN through Fujitsu's procedures. Commits unless commit is False."""
    order_date, order_no = create_header(cursor, supplier_no, user_id)
    for line in lines:
        add_line(cursor, order_date, order_no, supplier_no, line, user_id)

    # transdate is not set by sp_stk_order (its insert trigger is disabled).
    # Reserved1 lets a later pass recognise this receipt.
    cursor.execute(
        """
        SET NOCOUNT ON;
        UPDATE dbo.stk_order
        SET transdate = GETDATE(),
            Reserved1 = ?
        WHERE company = ? AND sector = ? AND region = ? AND branch = ?
          AND section = ? AND transtype = ? AND doctype = ?
          AND orderno = ? AND orderdate = ?;
        SELECT @@ROWCOUNT AS updated;
        """,
        _receipt_tag(receipt_id),
        COMPANY,
        SECTOR,
        REGION,
        BRANCH,
        SECTION,
        TRANSTYPE,
        DOCTYPE,
        order_no,
        order_date,
    )
    if _result_row(cursor, "updated").updated != 1:
        raise RuntimeError(f"header {order_no} was not found after insert")
    if commit:
        cursor.connection.commit()
    return order_no


def create_header(cursor: pyodbc.Cursor, supplier_no: int, user_id: int) -> tuple[datetime, int]:
    """Run sp_stk_order with orderno 0 so it takes the next number from sys_sequence."""
    for _attempt in range(MAX_NUMBER_ATTEMPTS):
        cursor.execute(
            """
            SET NOCOUNT ON;
            DECLARE @orderdate smalldatetime = CONVERT(date, GETDATE()),
                    @currentsite int, @status smallint, @closed smallint,
                    @insertstatus smallint, @message varchar(100), @orderno int;
            EXEC dbo.sp_stk_order
                @mybranch = ?, @mysection = ?, @mydoctype = ?,
                @Mysite = ?, @mysite_section = ?,
                @myorderdate = @orderdate, @myorderno = 0,
                @myreorderdate = NULL, @myreorderno = NULL,
                @myinvoicedate = NULL, @myinvoiceno = NULL,
                @MyDispatch_type = NULL, @myduedate = NULL,
                @Myfromdate = NULL, @Mytodate = NULL,
                @MyInventory_type = NULL, @MyInventory_location = NULL,
                @Mydiscount_type = NULL, @Mydiscount_value = NULL,
                @myuserid = ?,
                @mycurrentsite = @currentsite OUTPUT,
                @Mystatus = @status OUTPUT,
                @Myclosemonthstatus = @closed OUTPUT,
                @MYinsertstatus = @insertstatus OUTPUT,
                @Myerrormessage = @message OUTPUT,
                @mynewsequence = @orderno OUTPUT;
            SELECT @orderdate AS orderdate, @orderno AS orderno, @status AS status,
                   @closed AS closed, @insertstatus AS insertstatus,
                   @message AS message, @currentsite AS currentsite;
            """,
            BRANCH,
            SECTION,
            DOCTYPE,
            supplier_no,
            SITES_SECTION,
            user_id,
        )
        row = _result_row(cursor, "orderno")
        if row.closed:
            raise ReceiptDataError(f"Fujitsu refused the GRN: {row.message}")
        if row.orderno is None:
            raise RuntimeError(f"sp_stk_order did not allocate a number: {row.message}")
        if row.currentsite is not None:
            # sp_stk_order only reports a current supplier when the number is
            # already taken, and then inserts nothing, even if that supplier
            # matches ours. Keep the sequence bump and ask for the next number.
            log.warning(
                "GRN number %s already belongs to supplier %s, taking the next one",
                row.orderno,
                row.currentsite,
            )
            cursor.connection.commit()
            continue
        if row.status == 0 and row.insertstatus == 0:
            return row.orderdate, int(row.orderno)
        raise RuntimeError(f"sp_stk_order failed (status {row.status}): {row.message}")
    raise RuntimeError(f"no free GRN number after {MAX_NUMBER_ATTEMPTS} attempts")


def add_line(
    cursor: pyodbc.Cursor,
    order_date: datetime,
    order_no: int,
    supplier_no: int,
    line: ResolvedLine,
    user_id: int,
) -> None:
    cursor.execute(
        """
        SET NOCOUNT ON;
        DECLARE @currentsite int, @status smallint, @closed smallint,
                @insertstatus smallint, @message varchar(100);
        EXEC dbo.sp_stk_order_items
            @mybranch = ?, @mysection = ?, @mydoctype = ?,
            @Mysite = ?, @Mysite_section = ?,
            @myorderdate = ?, @myorderno = ?,
            @Myfromdate = NULL, @Mytodate = NULL, @Myduedate = NULL,
            @MyInventory_type = NULL, @Mydiscount_type = NULL, @Mydiscount_value = NULL,
            @Myactual_qty = ?, @Myfree_qty = ?,
            @Myuserid = ?, @Mybarcode = ?,
            @Mycurrentsite = @currentsite OUTPUT,
            @Mystatus = @status OUTPUT,
            @Myclosemonthstatus = @closed OUTPUT,
            @MYinsertstatus = @insertstatus OUTPUT,
            @Myerrormessage = @message OUTPUT;
        SELECT @status AS status, @closed AS closed,
               @insertstatus AS insertstatus, @message AS message;
        """,
        BRANCH,
        SECTION,
        DOCTYPE,
        supplier_no,
        SITES_SECTION,
        order_date,
        order_no,
        Decimal(line.quantity),
        FREE_QTY,
        user_id,
        line.barcode,
    )
    row = _result_row(cursor, "insertstatus")
    if row.closed:
        raise ReceiptDataError(f"Fujitsu refused line {line.barcode}: {row.message}")
    if row.status or row.insertstatus:
        raise RuntimeError(
            f"sp_stk_order_items failed for {line.barcode} "
            f"(status {row.status}/{row.insertstatus}): {row.message}"
        )


def mark_status(supabase: Client, receipt_id: str, status: str) -> None:
    supabase.table("app_receipts").update({"status": status}).eq("id", receipt_id).execute()


def connection_commit_reads(cursor: pyodbc.Cursor) -> None:
    cursor.connection.commit()


def _result_row(cursor: pyodbc.Cursor, column: str) -> pyodbc.Row:
    """Skip result sets a procedure may emit and return our final SELECT row."""
    while True:
        if cursor.description and any(d[0] == column for d in cursor.description):
            row = cursor.fetchone()
            if row is None:
                raise RuntimeError(f"no row returned for {column}")
            while cursor.nextset():
                pass
            return row
        if not cursor.nextset():
            raise RuntimeError(f"result column {column} not returned")


def _rollback(connection: pyodbc.Connection) -> None:
    try:
        connection.rollback()
    except pyodbc.Error:
        log.exception("SQL rollback failed")


def _sorted_items(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(items, key=lambda item: (str(item.get("created_at") or ""), str(item.get("id") or "")))


def _receipt_tag(receipt_id: str) -> str:
    return f"{RECEIPT_TAG}{receipt_id}"


def _names_match(supplier: Supplier, target: str) -> bool:
    names = [_norm(supplier.arabic_name)]
    if supplier.latin_name:
        names.append(_norm(supplier.latin_name))
    return target in names


def _name_contains(supplier: Supplier, target: str) -> bool:
    if len(target) < 3:
        return False
    names = [_norm(supplier.arabic_name)]
    if supplier.latin_name:
        names.append(_norm(supplier.latin_name))
    return any(target in name for name in names if name)


def _norm(value: str) -> str:
    return " ".join(value.split()).casefold()


def _env(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None or not str(value).strip():
        raise SystemExit(f"Missing environment variable {name}. Copy env.example to .env.")
    return str(value).strip()


def _odbc(value: str) -> str:
    return "{" + value.replace("}", "}}") + "}"


def _configure_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ReceiptDataError as error:
        log.error("%s", error)
        raise SystemExit(1) from error
