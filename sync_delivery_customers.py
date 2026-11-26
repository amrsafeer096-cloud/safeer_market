import pyodbc
pyodbc.pooling = False

import time
from datetime import datetime
from supabase import create_client, Client

# ==========================================
# 1. إعدادات سوبابيز (Supabase)
# ==========================================
SUPABASE_URL = "https://jugdxfhmjakmzjvfltjv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ==========================================
# 2. إعدادات سيستم المحل (فوجيتسو - SQL Server)
# ==========================================
SQL_SERVER = "40.40.40.2"
SQL_DATABASE = "retail"
SQL_USER = "sa"
SQL_PASSWORD = "retipr"

connection_string = (
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={SQL_SERVER};"
    f"DATABASE={SQL_DATABASE};"
    f"UID={SQL_USER};"
    f"PWD={SQL_PASSWORD};"
    f"TrustServerCertificate=yes;"
    f"Connection Timeout=15;"
)

# الفاصل الزمني لمزامنة العملاء المحذوفين/المعطلين (بالثواني) -> 5 دقائق
DELETED_SYNC_INTERVAL_SECONDS = 300

# قاموس المناطق الاحتياطي (مطابق لسيستم فوجيتسو)
FUJITSU_ZONES = {
    1: "حى السفارات",
    2: "الحى السابع",
    3: "مكرم عبيد",
    4: "عباس العقاد",
    5: "النادي الاهلي",
    6: "الحي السادس",
    7: "الحي الثامن",
    8: "الحي العاشر",
    9: "الطوب الرملي",
    10: "الحديقة الدولية",
    11: "السويسري",
    12: "حي الواحة",
    13: "جاردينيا",
    14: "رابعة العدوية",
    15: "الزهراء",
    16: "الطيران",
    17: "المنطقة التاسعة",
    18: "أحمد فخري",
    19: "طريق النصر",
    20: "جنينة مول",
    25: "نادي السكة",
    26: "استلام المحل",
}


def clean_phone(phone_val):
    """Normalize to Egyptian local digits (01… / landline); empty if none."""
    if not phone_val:
        return ""
    digits = "".join(ch for ch in str(phone_val) if ch.isdigit())
    if digits.startswith("0020"):
        digits = "0" + digits[4:]
    elif digits.startswith("20") and len(digits) >= 11:
        digits = "0" + digits[2:]
    if len(digits) == 10 and digits.startswith("1"):
        digits = "0" + digits
    return digits[:20]


def distinct_secondary(primary, *candidates):
    """Return unique secondaries that differ from primary and each other."""
    seen = {primary} if primary else set()
    out = []
    for raw in candidates:
        p = clean_phone(raw)
        if not p or p in seen:
            continue
        seen.add(p)
        out.append(p)
    return out


def get_zone_info(zone_id):
    try:
        z_id = int(zone_id) if zone_id is not None else 2
    except (ValueError, TypeError):
        z_id = 2

    try:
        res = (
            supabase.table("delivery_zones")
            .select("name, city, governorate")
            .eq("fujitsu_zone_id", z_id)
            .limit(1)
            .execute()
        )
        if res.data:
            row = res.data[0]
            return (
                z_id,
                row.get("name") or FUJITSU_ZONES.get(z_id, "الحى السابع"),
                row.get("city") or "مدينة نصر",
                row.get("governorate") or "القاهرة",
            )
    except Exception:
        pass

    return (z_id, FUJITSU_ZONES.get(z_id, "الحى السابع"), "مدينة نصر", "القاهرة")


def fetch_profile_address(user_id):
    for col in ["user_id", "customer_id", "profile_id"]:
        try:
            res = (
                supabase.table("addresses")
                .select("*")
                .eq(col, user_id)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if res.data:
                return res.data[0]
        except Exception:
            continue
    return {}


def get_next_fujitsu_ids(cursor):
    """
    حجز الرقم التالي من جدول hd_sequence الرسمي الخاص بفوجيتسو
    (DocType 101 للعملاء، و DocType 105 للعناوين) لمنع أي تعارض مع الكاشير
    """
    # 1) رقم العميل الجديد (DocType = 101)
    cursor.execute("""
        UPDATE hd_sequence
        SET Sequence = CASE
            WHEN Sequence < (SELECT ISNULL(MAX(CustomerNo), 2000000) - 2000000 FROM Customers WHERE CustomerNo >= 2000000)
            THEN (SELECT ISNULL(MAX(CustomerNo), 2000000) - 2000000 FROM Customers WHERE CustomerNo >= 2000000) + 1
            ELSE Sequence + 1
        END,
        ModifiedTime = GETDATE()
        OUTPUT INSERTED.Sequence
        WHERE DocType = 101 AND Branch = 0
    """)
    row_cust = cursor.fetchone()
    if row_cust:
        new_cust_no = 2000000 + int(row_cust[0])
    else:
        cursor.execute("SELECT ISNULL(MAX(CustomerNo), 2000000) + 1 FROM Customers")
        new_cust_no = int(cursor.fetchone()[0])

    # 2) رقم العنوان الجديد (DocType = 105)
    cursor.execute("""
        UPDATE hd_sequence
        SET Sequence = CASE
            WHEN Sequence < (SELECT ISNULL(MAX(AddressId), 19000) FROM CustomerAddresses)
            THEN (SELECT ISNULL(MAX(AddressId), 19000) FROM CustomerAddresses) + 1
            ELSE Sequence + 1
        END,
        ModifiedTime = GETDATE()
        OUTPUT INSERTED.Sequence
        WHERE DocType = 105 AND Branch = 0
    """)
    row_addr = cursor.fetchone()
    if row_addr:
        new_addr_id = int(row_addr[0])
    else:
        cursor.execute("SELECT ISNULL(MAX(AddressId), 19000) + 1 FROM CustomerAddresses")
        new_addr_id = int(cursor.fetchone()[0])

    return new_cust_no, new_addr_id


# ==========================================
# الاتجاه الأول: من سوبابيز (التطبيق والداشبورد) ---> إلى فوجيتسو
# ==========================================
def push_supabase_to_fujitsu(table_name):
    try:
        res = (
            supabase.table(table_name)
            .select("*")
            .eq("synced_to_fujitsu", False)
            .execute()
        )
        customers = res.data or []
    except Exception:
        return

    valid_customers = []
    for c in customers:
        p = clean_phone(c.get("phone") or c.get("mobile") or c.get("phone1"))
        if p:
            valid_customers.append(c)

    if not valid_customers:
        return

    print(
        f"\n[{datetime.now().strftime('%I:%M:%S %p')}] "
        f"⬆️ [{table_name}] تم العثور على ({len(valid_customers)}) عميل جديد جاري نقلهم لفوجيتسو..."
    )

    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    try:
        for cust in valid_customers:
            cust_id = cust.get("id")
            try:
                name = (
                    cust.get("full_name")
                    or cust.get("name")
                    or cust.get("arabic_name")
                    or "عميل دليفري"
                ).strip()

                phone1 = clean_phone(
                    cust.get("phone") or cust.get("mobile") or cust.get("phone1")
                )
                # Keep international storage form for AddressPhones blob.
                all_phones = []
                for key in ("phone", "phone2", "phone3", "phone4", "phone5"):
                    raw = cust.get(key) or ""
                    if key == "phone" and not raw:
                        raw = cust.get("mobile") or cust.get("phone1") or ""
                    p = clean_phone(raw) or str(raw).strip()
                    if p and p not in all_phones:
                        all_phones.append(p)
                extras = distinct_secondary(
                    phone1,
                    cust.get("phone2") or cust.get("secondary_phone") or "",
                    cust.get("phone3") or "",
                    cust.get("phone4") or "",
                    cust.get("phone5") or "",
                )
                phone2 = extras[0] if len(extras) > 0 else ""
                phone3 = extras[1] if len(extras) > 1 else ""
                phone4 = extras[2] if len(extras) > 2 else ""
                # phone5 lives only on AddressPhones (Fujitsu has 4 customer slots).

                cursor.execute(
                    "SELECT TOP 1 CustomerNo FROM Customers WHERE Mobile = ? OR Phone1 = ?",
                    (phone1, phone1),
                )
                existing = cursor.fetchone()

                if existing:
                    existing_no = existing[0]
                    supabase.table(table_name).update(
                        {
                            "synced_to_fujitsu": True,
                            "fujitsu_customer_id": str(existing_no),
                        }
                    ).eq("id", cust_id).execute()
                    print(
                        f"ℹ️ العميل ({name} - {phone1}) موجود مسبقاً في فوجيتسو برقم ({existing_no}) -> تم ربطه."
                    )
                    continue

                addr = fetch_profile_address(cust_id) if table_name == "profiles" else {}

                raw_zone_id = (
                    cust.get("fujitsu_zone_id")
                    or cust.get("zone_id")
                    or addr.get("fujitsu_zone_id")
                    or 2
                )
                zone_id, zone_name, town_name, gov_name = get_zone_info(raw_zone_id)

                building = str(cust.get("building") or addr.get("building") or "").strip()
                floor = str(cust.get("floor") or addr.get("floor") or "").strip()
                apartment = str(cust.get("apartment") or addr.get("apartment") or "").strip()
                street = str(
                    cust.get("street")
                    or cust.get("street_address")
                    or addr.get("street")
                    or cust.get("address")
                    or cust.get("full_address")
                    or "غير محدد"
                ).strip()
                landmark = cust.get("landmark") or addr.get("landmark") or None

                parts = []
                if building:
                    parts.append(building)
                if street:
                    parts.append(street)
                if floor:
                    parts.append(f"الدور {floor}")
                if apartment:
                    parts.append(f"شقة {apartment}")
                if zone_name:
                    parts.append(zone_name)
                full_addr = " - ".join(parts) if parts else street

                lat = cust.get("latitude") or cust.get("lat") or addr.get("lat")
                lon = cust.get("longitude") or cust.get("lng") or addr.get("lng")
                lat_str = str(lat) if lat is not None else None
                lon_str = str(lon) if lon is not None else None

                now = datetime.now()

                # حجز الأرقام من hd_sequence الرسمي لفوجيتسو
                new_cust_no, new_addr_id = get_next_fujitsu_ids(cursor)

                notes = str(cust.get("notes") or "").strip() or None
                # All up-to-5 phones on AddressPhones; Customers holds first 4.
                phone_blob = " - ".join(all_phones) if all_phones else " - ".join(
                    p for p in (phone1, phone2, phone3, phone4) if p
                )

                # Mobile + Phone1..Phone3 = first 4 distinct numbers.
                cursor.execute(
                    """
                    INSERT INTO Customers (
                        CustomerNo, ArabicName, EnglishName, CustomerType, CompanyId, BranchId,
                        IsDisabled, RegistrationDate, CreatedFrom, CreatedBy, ModifiedBy,
                        AppVersion, DateCreated, DateModified, SourceRowVersion,
                        CreatedRowVersion, CreatedAt, ModifiedAt, last_modified_time,
                        Mobile, Phone1, Phone2, Phone3, Notes, DefaultAddressId
                    ) VALUES (
                        ?, ?, ?, 1, 0, 0,
                        0, ?, 1, 8, 8,
                        '1.0.0.56', ?, ?, 0,
                        0, 0, 0, ?,
                        ?, ?, ?, ?, ?, ?
                    )
                    """,
                    (
                        new_cust_no,
                        name,
                        name,
                        now,
                        now,
                        now,
                        now,
                        phone1,
                        phone2 if phone2 else None,
                        phone3 if phone3 else None,
                        phone4 if phone4 else None,
                        notes,
                        new_addr_id,
                    ),
                )

                cursor.execute(
                    """
                    INSERT INTO CustomerAddresses (
                        AddressId, CustomerNo, Title, CountryId, CountryName,
                        GovId, GovName, TownId, TownName,
                        CityId, CityName, Building, Floor, Apartment,
                        Landmark, StreetAddress, FullAddress, AddressPhones, Lon, Lat,
                        IsPrimary, BranchId, AddedFrom, IsDisabled,
                        NeedsConfirmation, IsConfirmed, AppVersion,
                        DateCreated, DateModified, SourceRowVersion,
                        CreatedRowVersion, CreatedAt, ModifiedAt, last_modified_time
                    ) VALUES (
                        ?, ?, N'افتراضي', 0, N'مصر',
                        1, ?, 1, ?,
                        ?, ?, ?, ?, ?,
                        ?, ?, ?, ?, ?, ?,
                        1, 101, 0, 0,
                        0, 0, '1.0.0.56',
                        ?, ?, 0,
                        0, 0, 0, ?
                    )
                    """,
                    (
                        new_addr_id,
                        new_cust_no,
                        gov_name,
                        town_name,
                        zone_id,
                        zone_name,
                        building if building else None,
                        floor if floor else None,
                        apartment if apartment else None,
                        landmark,
                        street,
                        full_addr,
                        phone_blob if phone_blob else None,
                        lon_str,
                        lat_str,
                        now,
                        now,
                        now,
                    ),
                )
                conn.commit()

                supabase.table(table_name).update(
                    {
                        "synced_to_fujitsu": True,
                        "fujitsu_customer_id": str(new_cust_no),
                    }
                ).eq("id", cust_id).execute()

                print(
                    f"[{datetime.now().strftime('%I:%M:%S %p')}] "
                    f"✅ تم نقل العميل لفوجيتسو: {name} ({phone1}) | المنطقة: {zone_name} | رقم: {new_cust_no}"
                )

            except Exception as e:
                conn.rollback()
                print(f"❌ خطأ أثناء نقل العميل ({cust_id}) لفوجيتسو: {e}")
    finally:
        cursor.close()
        conn.close()


# ==========================================
# الاتجاه الثاني: من فوجيتسو ---> إلى سوبابيز (pos_customers)
# ==========================================
def get_last_synced_customer_rowversion():
    """Trusty SyncCustomerCache watermark: max IntRowVersion already pulled."""
    try:
        res = (
            supabase.table("pos_customers")
            .select("fujitsu_row_version")
            .not_.is_("fujitsu_row_version", "null")
            .order("fujitsu_row_version", desc=True)
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if rows and rows[0].get("fujitsu_row_version") is not None:
            return int(rows[0]["fujitsu_row_version"])
    except Exception:
        pass
    # Fallback for DBs that don't have the column yet: CustomerNo watermark.
    try:
        res = (
            supabase.table("pos_customers")
            .select("fujitsu_customer_id")
            .not_.is_("fujitsu_customer_id", "null")
            .order("id", desc=True)
            .limit(200)
            .execute()
        )
        max_no = 0
        for row in (res.data or []):
            val = row.get("fujitsu_customer_id")
            if val and str(val).isdigit():
                num = int(val)
                if num > max_no:
                    max_no = num
        return max_no
    except Exception:
        return 0


def pull_fujitsu_to_supabase(min_row_version):
    """
    Incremental pull from v_customers.

    Trusty SyncCustomerCache seeds with ``RowVersion >= minVersion`` once, then
    advances past the watermark. We use strict ``IntRowVersion > last`` so the
    last synced customer is not re-fetched every poll when nothing changed.
    """
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Prefer IntRowVersion incremental. Fall back to CustomerNo when version is 0.
    query = """
        SELECT TOP 500
            CustomerNo,
            ISNULL(NULLIF(LTRIM(RTRIM(ArabicName)), ''), EnglishName) AS Name,
            LTRIM(RTRIM(ISNULL(Mobile, ''))) AS Mobile,
            LTRIM(RTRIM(ISNULL(Phone1, ''))) AS Phone1,
            LTRIM(RTRIM(ISNULL(Phone2, ''))) AS Phone2,
            LTRIM(RTRIM(ISNULL(Phone3, ''))) AS Phone3,
            Notes,
            DefaultAddressId,
            AddressId,
            Title,
            GovName,
            TownName,
            CityId,
            CityName,
            Building,
            Floor,
            Apartment,
            Landmark,
            StreetAddress,
            FullAddress,
            AddressPhones,
            Lat,
            Lon,
            IsPrimary,
            BranchId,
            ISNULL(IntRowVersion, 0) AS IntRowVersion
        FROM dbo.v_customers
        WHERE IsDisabled = 0
          AND (
                IntRowVersion > ?
             OR (ISNULL(IntRowVersion, 0) = 0 AND CustomerNo > ?)
          )
        ORDER BY IntRowVersion ASC, CustomerNo ASC
    """

    try:
        cursor.execute(query, (min_row_version, min_row_version))
        rows = cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

    if not rows:
        return min_row_version

    first_no = getattr(rows[0], "CustomerNo", rows[0][0])
    print(
        f"[{datetime.now().strftime('%I:%M:%S %p')}] "
        f"⬇️ جاري سحب ({len(rows)}) عميل من v_customers "
        f"(RowVersion>{min_row_version}, أول رقم {first_no})..."
    )

    batch = []
    new_max_rv = min_row_version

    for r in rows:
        c_no = int(r.CustomerNo)
        rv = int(getattr(r, "IntRowVersion", 0) or 0)
        if rv > new_max_rv:
            new_max_rv = rv
        if c_no > new_max_rv and rv == 0:
            new_max_rv = c_no

        phone1 = clean_phone(r.Mobile) or clean_phone(r.Phone1)
        if not phone1:
            continue
        # Prefer real secondaries; only use Phone1 when Mobile is set and Phone1 differs.
        extras = distinct_secondary(
            phone1,
            r.Phone2,
            r.Phone1 if clean_phone(r.Mobile) else "",
            r.Phone3,
        )
        # Also scrape AddressPhones for a possible 5th number.
        addr_phones = [
            clean_phone(p)
            for p in str(getattr(r, "AddressPhones", "") or "").replace(",", "-").split("-")
        ]
        for ap in addr_phones:
            if ap and ap != phone1 and ap not in extras:
                extras.append(ap)
        phone2 = extras[0] if len(extras) > 0 else ""
        phone3 = extras[1] if len(extras) > 1 else ""
        phone4 = extras[2] if len(extras) > 2 else ""
        phone5 = extras[3] if len(extras) > 3 else ""

        full_name = (r.Name or "عميل").strip()
        full_addr = (r.FullAddress or r.StreetAddress or "").strip()
        zone_txt = (r.CityName or "").strip() or None

        def to_float(v):
            try:
                return float(v) if v is not None and str(v).strip() != "" else None
            except ValueError:
                return None

        lat_val = to_float(r.Lat)
        lon_val = to_float(r.Lon)

        row_payload = {
            "fujitsu_customer_id": str(c_no),
            "fujitsu_customer_no": c_no,
            "full_name": full_name,
            "phone": phone1,
            "phone2": phone2 if phone2 else None,
            "phone3": phone3 if phone3 else None,
            "phone4": phone4 if phone4 else None,
            "phone5": phone5 if phone5 else None,
            "notes": (str(r.Notes or "").strip() or None),
            "customer_type": "regular",
            "address": full_addr,
            "full_address": full_addr,
            "street": (r.StreetAddress or "").strip() or None,
            "street_address": (r.StreetAddress or "").strip() or None,
            "building": (r.Building or "").strip() or None,
            "floor": (r.Floor or "").strip() or None,
            "apartment": (r.Apartment or "").strip() or None,
            "governorate": (r.GovName or "القاهرة").strip(),
            "city": (r.TownName or "مدينة نصر").strip(),
            "zone": zone_txt,
            "zone_name": zone_txt,
            "fujitsu_zone_id": int(r.CityId) if r.CityId is not None else None,
            "lat": lat_val,
            "lng": lon_val,
            "latitude": lat_val,
            "longitude": lon_val,
            "source_system": "fujitsu",
            "synced_to_fujitsu": True,
            "fujitsu_row_version": rv if rv else None,
        }
        batch.append(row_payload)

    if batch:
        try:
            supabase.table("pos_customers").upsert(
                batch, on_conflict="fujitsu_customer_id"
            ).execute()
            print(
                f"[{datetime.now().strftime('%I:%M:%S %p')}] "
                f"✅ تم رفع ({len(batch)}) عميل إلى سوبابيز بنجاح "
                f"(آخر RowVersion: {new_max_rv})."
            )
        except Exception as e:
            # Column fujitsu_row_version may not exist until migration is applied.
            if "fujitsu_row_version" in str(e):
                for row in batch:
                    row.pop("fujitsu_row_version", None)
                    row.pop("fujitsu_customer_no", None)
                    row.pop("phone3", None)
                    row.pop("notes", None)
                try:
                    supabase.table("pos_customers").upsert(
                        batch, on_conflict="fujitsu_customer_id"
                    ).execute()
                    print(
                        f"[{datetime.now().strftime('%I:%M:%S %p')}] "
                        f"✅ تم رفع ({len(batch)}) عميل (بدون أعمدة RowVersion الجديدة)."
                    )
                except Exception as e2:
                    print(f"❌ خطأ أثناء رفع العملاء لسوبابيز: {e2}")
                    return min_row_version
            else:
                print(f"❌ خطأ أثناء رفع العملاء لسوبابيز: {e}")
                return min_row_version

    return new_max_rv

# ==========================================
# مزامنة المحذوفين/المعطلين من فوجيتسو (كل 5 دقائق)
# ==========================================
def sync_deleted_customers():
    """حذف أي عميل تم حذفه أو تعطيله في فوجيتسو من جدول pos_customers"""
    try:
        # 1) جلب كل أرقام العملاء النشطين في فوجيتسو (أرقام فقط - سريع جداً)
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        try:
            cursor.execute("SELECT CustomerNo FROM Customers WHERE IsDisabled = 0")
            active_fujitsu_ids = {str(row[0]) for row in cursor.fetchall()}
        finally:
            cursor.close()
            conn.close()

        # حماية ضد أي خلل يرجّع قائمة فاضية
        if not active_fujitsu_ids:
            return

        # 2) جلب كل fujitsu_customer_id الموجودة في Supabase على دفعات
        supa_ids = set()
        offset = 0
        page_size = 1000
        while True:
            res = (
                supabase.table("pos_customers")
                .select("fujitsu_customer_id")
                .not_.is_("fujitsu_customer_id", "null")
                .range(offset, offset + page_size - 1)
                .execute()
            )
            rows = res.data or []
            if not rows:
                break
            for r in rows:
                val = r.get("fujitsu_customer_id")
                if val is not None:
                    supa_ids.add(str(val))
            if len(rows) < page_size:
                break
            offset += page_size

        # 3) العملاء اللي موجودين في سوبابيز ومبقوش نشطين في فوجيتسو
        to_delete = list(supa_ids - active_fujitsu_ids)
        if not to_delete:
            return

        # مسحهم على دفعات (كل 100 رقم مع بعض)
        for i in range(0, len(to_delete), 100):
            chunk = to_delete[i : i + 100]
            supabase.table("pos_customers").delete().in_("fujitsu_customer_id", chunk).execute()

        print(
            f"[{datetime.now().strftime('%I:%M:%S %p')}] "
            f"🗑️ تم حذف ({len(to_delete)}) عميل محذوف/معطل في فوجيتسو من سوبابيز."
        )
    except Exception as e:
        print(f"⚠️ خطأ أثناء مزامنة المحذوفين: {e}")


if __name__ == "__main__":
    print("=" * 65)
    print("🚀 خدمة المزامنة الثنائية لعملاء سفير ماركت (التطبيق <-> فوجيتسو)")
    print("=" * 65)

    last_row_version = get_last_synced_customer_rowversion()
    print(f"📌 آخر Customer IntRowVersion متزامن في سوبابيز: {last_row_version}")
    print("⏳ جاري تشغيل المزامنة اللحظية في الاتجاهين (مع تنظيف المحذوفين كل 5 دقائق)...\n")

    last_deleted_sync = 0.0

    while True:
        try:
            # 1) نقل العملاء الجداد من التطبيق/الداشبورد إلى فوجيتسو
            push_supabase_to_fujitsu("pos_customers")
            push_supabase_to_fujitsu("profiles")

            # 2) سحب العملاء من v_customers (Trusty SyncCustomerCache / RowVersion)
            new_rv = pull_fujitsu_to_supabase(last_row_version)
            if new_rv > last_row_version:
                last_row_version = new_rv
                continue

            # 3) فحص ومسح العملاء المحذوفين/المعطلين كل 5 دقائق
            now_ts = time.time()
            if now_ts - last_deleted_sync >= DELETED_SYNC_INTERVAL_SECONDS:
                sync_deleted_customers()
                last_deleted_sync = now_ts

        except Exception as e:
            print(f"⚠️ خطأ في الاتصال (سيتم إعادة المحاولة): {e}")

        time.sleep(5)