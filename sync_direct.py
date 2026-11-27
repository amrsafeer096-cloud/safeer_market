import pyodbc
import time
from datetime import datetime
from supabase import create_client, Client

# ==========================================
# 1. إعدادات سوبابيز
# ==========================================
SUPABASE_URL = "https://jugdxfhmjakmzjvfltjv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ==========================================
# 2. إعدادات سيستم المحل (فوجيتسو)
# ==========================================
SQL_SERVER = "40.40.40.2"
SQL_DATABASE = "retail"
SQL_USER = "sa"
SQL_PASSWORD = "retipr"

connection_string = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};UID={SQL_USER};PWD={SQL_PASSWORD};TrustServerCertificate=yes;"

VALID_APP_SUBCATEGORIES = {
    'جبن تترباك و مثلثات و كوب', 'اجبان معبأ ولبنة و كريمة وسمنة', 'أجبان وزن',
    'جبن موزاريلا', 'زبادي وارز باللبن', 'البان طويلة الاجل', 'زبدة معبأ', 'بيض مغلف',
    'شيكولاتة', 'بسكويت', 'حلويات', 'مقرمشات و محمصات', 'تسالي و مكسرات وزن',
    'حلاوة وزبدة', 'ياميش رمضان', 'مياه ومشروبات و عصائر و ايس كريم', 'مشروبات',
    'عصائر', 'عصائر بودر', 'دواجن مجمدة ومصنعات دوراجن', 'لحوم مجمدة', 'مصنعات لحوم',
    'أسماك مجمدة', 'اسماك مدخنة', 'خضروات وفاكهه مجمدة', 'معجنات مجمدة',
    'مخبوزات', 'باتيه و وتش', 'كورن فليكس و موسلي وشوفان', 'مكرونه', 'ارز',
    'بقوليات وعطارة وبقسماط معبأة', 'شوربات ومرقات و خلطات', 'زيوت', 'سمن',
    'سكر ودقيق', 'معلبات', 'مشهيات', 'زيتون ومخللات', 'زيتون ومخلل معبأ',
    'عطارة وزن', 'علافة وزن', 'مستلزمات حلويات وبودر', 'سلاطات أنواع وزن',
    'مساحيق ومنعمات', 'صابون سائل ومزيلات بقع', 'كلور ومطهرات', 'ملمعات',
    'مبيدات ومعطرات', 'مناديل و ورق تواليت', 'سلك وليف', 'أسفنج و سلك',
    'مسلكات بلوعات', 'بخور', 'شامبو وبلسم', 'شاور جل وهاند ووش', 'صابون',
    'برفانات ومزيلات عرق', 'كريمات وسيرم', 'مستلزمات أسنان', 'مستلزمات حلاقة',
    'صبغات وحنة', 'مستلزمات عناية شخصية', 'حافضات و فوط صحية', 'اكل اطفال',
    'مستلزمات اطفال', 'ادوات منزلية', 'ادوات كهربية', 'مستلزمات كهربائية',
    'بلاستيكات وأكياس', 'فويل', 'خردوات', 'بطاريات وحجاره', 'كبريت و ولاعات',
    'مستلزمات حيوانات', 'مستلزمات رمضان',
}

UNLISTED_CATEGORIES = {
    'اصناف لا تتم بيعها', 'خدمة توصيل', 'خدمة فوري', 'كروت وكتب'
}

def normalize_ar(text):
    if not text: return ""
    t = " ".join(text.strip().split())
    return t.replace('أ', 'ا').replace('إ', 'ا').replace('آ', 'ا').replace('ة', 'ه')

NORMALIZED_APP_MAP = {normalize_ar(c): c for c in VALID_APP_SUBCATEGORIES}

def get_exact_app_category(subcat_raw, sec_raw):
    sub = subcat_raw.strip()
    sec = sec_raw.strip()

    if sub in VALID_APP_SUBCATEGORIES: return sub
    if sec in VALID_APP_SUBCATEGORIES: return sec

    norm_sub = normalize_ar(sub)
    if norm_sub in NORMALIZED_APP_MAP: return NORMALIZED_APP_MAP[norm_sub]
    norm_sec = normalize_ar(sec)
    if norm_sec in NORMALIZED_APP_MAP: return NORMALIZED_APP_MAP[norm_sec]

    combined = f"{sub} {sec}"
    if any(w in combined for w in ["تترباك", "تتبراك", "مثلثات"]): return 'جبن تترباك و مثلثات و كوب'
    if any(w in combined for w in ["موزاريلا", "موتزاريلا"]): return 'جبن موزاريلا'
    if any(w in combined for w in ["لبنة", "كريمة", "اجبان معبأ"]): return 'اجبان معبأ ولبنة و كريمة وسمنة'
    if any(w in combined for w in ["جبن", "أجبان", "اجبان"]): return 'أجبان وزن'
    if any(w in combined for w in ["زبادي", "ارز باللبن"]): return 'زبادي وارز باللبن'
    if any(w in combined for w in ["لبن", "حليب", "ألبان", "البان"]): return 'البان طويلة الاجل'
    if "زبدة" in combined and "حلاوة" not in combined: return 'زبدة معبأ'
    if "بيض" in combined: return 'بيض مغلف'

    if "شيكولات" in combined: return 'شيكولاتة'
    if any(w in combined for w in ["بسكويت", "ويفر", "كيك", "مولتو"]): return 'بسكويت'
    if any(w in combined for w in ["مقرمشات", "محمصات", "شيبسي"]): return 'مقرمشات و محمصات'
    if any(w in combined for w in ["تسالي", "مكسرات"]): return 'تسالي و مكسرات وزن'
    if "حلاوة" in combined: return 'حلاوة وزبدة'
    if "ياميش" in combined: return 'ياميش رمضان'
    if any(w in combined for w in ["حلو", "طوفي", "توفي", "لبان", "ملبس"]): return 'حلويات'

    if "بودر" in combined and "عصير" in combined: return 'عصائر بودر'
    if any(w in combined for w in ["ايس كريم", "أيس كريم", "مياه"]): return 'مياه ومشروبات و عصائر و ايس كريم'
    if any(w in combined for w in ["عصير", "عصائر"]): return 'عصائر'
    if any(w in combined for w in ["مشروب", "بيبسي", "كانز", "غازية", "شاي", "قهوة", "بن", "نسكافيه", "ينسون", "اعشاب"]): return 'مشروبات'

    if any(w in combined for w in ["دواجن", "دوراجن", "فراخ", "بانيه"]): return 'دواجن مجمدة ومصنعات دوراجن'
    if "مصنعات" in combined or "لانشون" in combined or "بسطرمة" in combined or "برجر" in combined or "سجق" in combined: return 'مصنعات لحوم'
    if "مدخن" in combined or "رنجة" in combined: return 'اسماك مدخنة'
    if any(w in combined for w in ["سمك", "أسماك", "اسماك", "جمبري"]): return 'أسماك مجمدة'
    if any(w in combined for w in ["خضروات", "خضار", "فاكه", "بامية", "بسلة", "بطاطس"]): return 'خضروات وفاكهه مجمدة'
    if "معجنات" in combined or "سمبوسك" in combined or "جلاش" in combined: return 'معجنات مجمدة'
    if "لحوم" in combined or "لحم" in combined or "كفتة" in combined: return 'لحوم مجمدة'

    if any(w in combined for w in ["باتيه", "وتش", "كرواسون"]): return 'باتيه و وتش'
    if any(w in combined for w in ["فليكس", "موسلي", "شوفان"]): return 'كورن فليكس و موسلي وشوفان'
    if any(w in combined for w in ["مخبوز", "عيش", "خبز", "توست", "بقسماط"]): return 'مخبوزات'

    if "مكرون" in combined or "شعرية" in combined: return 'مكرونه'
    if any(w in combined for w in ["أرز", "ارز"]): return 'ارز'
    if any(w in combined for w in ["شورب", "مرق", "خلط"]): return 'شوربات ومرقات و خلطات'
    if any(w in combined for w in ["بقوليات", "عدس", "فاصوليا", "لوبيا", "فول"]): return 'بقوليات وعطارة وبقسماط معبأة'

    if any(w in combined for w in ["شامبو", "بلسم"]): return 'شامبو وبلسم'
    if any(w in combined for w in ["شاور", "هاند ووش"]): return 'شاور جل وهاند ووش'
    if any(w in combined for w in ["برفان", "مزيل", "عرق", "سبراي"]): return 'برفانات ومزيلات عرق'
    if any(w in combined for w in ["كريم", "سيرم", "لوشن", "بشرة"]): return 'كريمات وسيرم'
    if any(w in combined for w in ["أسنان", "اسنان", "معجون", "فرشاة"]): return 'مستلزمات أسنان'
    if "حلاقة" in combined or "شفرات" in combined: return 'مستلزمات حلاقة'
    if any(w in combined for w in ["صبغ", "حنة"]): return 'صبغات وحنة'
    if "صابون سائل" in combined or "مزيلات بقع" in combined or "فيبا" in combined or "بريل" in combined: return 'صابون سائل ومزيلات بقع'
    if "صابون" in combined: return 'صابون'
    if any(w in combined for w in ["عناية شخصية", "تجميل", "شعر", "جل"]): return 'مستلزمات عناية شخصية'

    if any(w in combined for w in ["مساحيق", "مسحوق", "منعم", "اريال", "برسيل", "أوكسي", "اوكسي", "داوني"]): return 'مساحيق ومنعمات'
    if any(w in combined for w in ["كلور", "مطهر", "ديتول"]): return 'كلور ومطهرات'
    if "ملمع" in combined: return 'ملمعات'
    if any(w in combined for w in ["مبيد", "معطر", "ريد", "بيروسول"]): return 'مبيدات ومعطرات'
    if any(w in combined for w in ["مناديل", "تواليت", "ورق"]): return 'مناديل و ورق تواليت'
    if any(w in combined for w in ["سلك", "ليف", "إسفنج", "أسفنج"]): return 'سلك وليف'
    if "مسلك" in combined or "بلوعات" in combined: return 'مسلكات بلوعات'
    if "بخور" in combined: return 'بخور'

    if any(w in combined for w in ["حافضات", "حفاضات", "فوط", "بامبرز", "أولويز"]): return 'حافضات و فوط صحية'
    if "اكل اطفال" in combined or "سيريلاك" in combined: return 'اكل اطفال'
    if any(w in combined for w in ["اطفال", "أطفال", "طفل", "بيبي", "ببرونة"]): return 'مستلزمات اطفال'

    if any(w in combined for w in ["كهرب", "لمب", "مشترك"]): return 'ادوات كهربية'
    if any(w in combined for w in ["بلاستيك", "أكياس", "اكياس", "شنط"]): return 'بلاستيكات وأكياس'
    if "فويل" in combined or "استرتش" in combined: return 'فويل'
    if any(w in combined for w in ["بطاري", "حجار"]): return 'بطاريات وحجاره'
    if any(w in combined for w in ["كبريت", "ولاع", "فحم"]): return 'كبريت و ولاعات'
    if any(w in combined for w in ["حيوان", "قطط", "كلاب", "دراي فود"]): return 'مستلزمات حيوانات'
    if any(w in combined for w in ["منزل", "ادوات", "أدوات", "خردوات"]): return 'ادوات منزلية'

    if any(w in combined for w in ["زيت", "زيوت"]) and "زيتون" not in combined: return 'زيوت'
    if "سمن" in combined: return 'سمن'
    if any(w in combined for w in ["سكر", "دقيق"]): return 'سكر ودقيق'
    if any(w in combined for w in ["معلبات", "تونة", "صلصة", "فول مدمس", "ذرة", "مشروم"]): return 'معلبات'
    if any(w in combined for w in ["مشهيات", "كاتشب", "مايونيز", "مسطردة", "خل", "صوص", "طحينة"]): return 'مشهيات'
    if any(w in combined for w in ["زيتون", "مخلل"]): return 'زيتون ومخلل معبأ'
    if any(w in combined for w in ["عطارة", "توابل", "بهارات", "فلفل", "كمون"]): return 'عطارة وزن'
    if "مستلزمات حلويات" in combined or "فانيليا" in combined or "بيكنج" in combined or "جيلي" in combined or "كريم شانتيه" in combined: return 'مستلزمات حلويات وبودر'

    return 'معلبات'

BRANCH_ID = 101


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


def _unit_discount(retail, discount_value, discount_type):
    """Trusty ItemDiscount: 101=% , 102/3=fixed amount."""
    try:
        retail = float(retail or 0)
        discount_value = float(discount_value or 0)
        discount_type = int(discount_type or 0)
    except (TypeError, ValueError):
        return 0.0
    if discount_type in (102, 3):
        return discount_value
    if discount_type == 101:
        return retail * discount_value / 100.0
    return 0.0


def sync_active_with_categories():
    """Trusty SyncItemCache parity: v_hd_items + Func_ItemBalanceOf + Func_ActiveItemDiscountsOf."""
    print(f"\n[{datetime.now().strftime('%I:%M:%S %p')}] جاري سحب الأصناف من v_hd_items + الرصيد + الخصومات...")

    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()

        unit_map = {}
        try:
            cursor.execute("SELECT CAST(unit AS VARCHAR), a_name FROM sys_unit WHERE a_name IS NOT NULL")
            for row in cursor.fetchall():
                unit_map[str(row[0]).strip()] = str(row[1]).strip()
        except Exception:
            pass

        # Master from v_hd_items (Trusty SyncItemCache) + live stock calc (same math as
        # Func_ItemBalanceOf opening+movements). Overlay Func_ItemBalanceOf when it
        # returns a row; the TVF often omits items with no current-month MTD row.
        cursor.execute(
            f"""
            SET NOCOUNT ON;
            DECLARE @branchId INT = {BRANCH_ID};
            DECLARE @companyId INT = 1;
            DECLARE @sectionId INT = 0;
            DECLARE @expiryDate SMALLDATETIME = '1900-01-01';
            DECLARE @toDate DATETIME = GETDATE();
            DECLARE @transYear INT, @transMonth INT;
            EXEC sp_get_max_closing_mnoth_year @branchId, @toDate, @transYear OUT, @transMonth OUT;
            DECLARE @fromDate DATETIME = DATEFROMPARTS(@transYear, @transMonth, 1);

            SELECT
                LTRIM(RTRIM(CAST(v.Barcode AS NVARCHAR(50)))) AS barcode,
                LTRIM(RTRIM(CAST(v.ItemEan AS NVARCHAR(50)))) AS itemean,
                v.AName AS a_name,
                v.RetailPrice AS retail_price,
                v.Unit AS unit_code,
                ISNULL(v.Pieces, 1) AS pieces,
                ISNULL(v.ItemSectionName, N'') AS section_name,
                ISNULL(v.ItemGroupName, N'') AS group_name,
                (ISNULL(op.opening_qty, 0) + ISNULL(mv.net_qty, 0)) AS stock_quantity
            FROM dbo.v_hd_items v
            LEFT JOIN (
                SELECT itemean, SUM(item_qtyin) AS opening_qty
                FROM stk_mtod
                WHERE doctype = 0
                  AND transyear = @transYear AND transmonth = @transMonth
                  AND company = @companyId AND branch = @branchId
                  AND section = @sectionId AND expirydate = @expiryDate
                GROUP BY itemean
            ) op ON LTRIM(RTRIM(op.itemean)) = LTRIM(RTRIM(v.ItemEan))
            LEFT JOIN (
                SELECT
                    oi.itemean,
                    SUM(
                        CASE
                            WHEN o.doctype < 2050 THEN (oi.actual_qty + oi.free_qty) * oi.peices
                            ELSE -1 * (oi.actual_qty + oi.free_qty) * oi.peices
                        END
                    ) AS net_qty
                FROM stk_order o
                JOIN stk_order_items oi
                  ON o.company = oi.company AND o.sector = oi.sector
                 AND o.region = oi.region AND o.branch = oi.branch
                 AND o.section = oi.section AND o.transtype = oi.transtype
                 AND o.doctype = oi.doctype AND o.orderno = oi.orderno
                 AND o.orderdate = oi.orderdate
                WHERE o.posting IN (0, 1)
                  AND o.orderdate BETWEEN @fromDate AND @toDate
                  AND o.company = @companyId AND o.branch = @branchId
                  AND o.section = @sectionId AND oi.expirydate = @expiryDate
                GROUP BY oi.itemean
            ) mv ON LTRIM(RTRIM(mv.itemean)) = LTRIM(RTRIM(v.ItemEan))
            WHERE v.Barcode IS NOT NULL
              AND LTRIM(RTRIM(CAST(v.Barcode AS NVARCHAR(50)))) <> ''
              AND v.RetailPrice > 0
              AND ISNULL(v.NotForSale, 0) = 0
            """
        )
        item_rows = cursor.fetchall()
        print(f"  v_hd_items rows: {len(item_rows)}")

        itemeans_raw = []
        for r in item_rows:
            e = str(r.itemean or "").strip()
            if e:
                itemeans_raw.append(e.ljust(13))  # Fujitsu CHAR padding for TVF join
        balance_by_ean = {}
        discount_by_barcode = {}
        batch = 400

        for i in range(0, len(itemeans_raw), batch):
            chunk = itemeans_raw[i : i + batch]
            if not chunk:
                continue
            placeholders = ", ".join(
                "(N'" + s.replace("'", "''") + "')" for s in sorted(set(chunk))
            )
            cursor.execute(
                f"""
                DECLARE @ids dbo.TableType_StrIds;
                INSERT INTO @ids (StrId) VALUES {placeholders};
                SELECT LTRIM(RTRIM(ItemEan)), ItemBalance
                FROM dbo.Func_ItemBalanceOf({BRANCH_ID}, @ids);
                """
            )
            _c, rows = _fetch_last_result(cursor)
            for row in rows or []:
                ean = str(row[0] or "").strip()
                try:
                    balance_by_ean[ean] = int(float(row[1] or 0))
                except (TypeError, ValueError):
                    balance_by_ean[ean] = 0

        # Active discounts — Trusty yellow-star offers.
        #
        # Live retail: Func_ActiveItemDiscountsOf(101, …) returns 0 rows because
        # pos_promotion_items promos (prom_type=3) have NO sys_discount_branchs
        # rows for branch 101. The function's @Branch<=0 path skips that join and
        # returns the real offers (e.g. 6222014350658 → DiscountValue 10 / type 3).
        # Pull the full active set once (no barcode TVP / chunking).
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
                    pi.sales_price - pi.prom_price AS DiscountValue,
                    pi.prom_id AS DiscountNo,
                    pi.prom_type AS DiscountType
                FROM pos_promotion_items pi WITH (NOLOCK)
                WHERE pi.prom_type = 3
                  AND pi.postflag = 0
                  AND pi.sdate IS NOT NULL
                  AND pi.edate IS NOT NULL
                  AND GETDATE() BETWEEN pi.sdate AND pi.edate
            ) active_discounts
            """
        )
        for row in cursor.fetchall() or []:
            bc = str(row[0] or "").strip()
            if not bc:
                continue
            value = float(row[1] or 0)
            dtype = int(row[3] or 0)
            dno = int(row[2] or 0)
            prev = discount_by_barcode.get(bc)
            # Keep the larger absolute discount when several rows overlap.
            if prev is not None:
                if dtype in (102, 3) and prev["type"] in (102, 3):
                    if value <= prev["value"]:
                        continue
                elif dtype == 101 and prev["type"] == 101:
                    if value <= prev["value"]:
                        continue
            discount_by_barcode[bc] = {
                "value": value,
                "no": dno,
                "type": dtype,
            }
        print(f"  active discounts loaded: {len(discount_by_barcode)}")

        data_to_upsert_dict = {}
        for row in item_rows:
            barcode_val = str(row.barcode or "").strip()
            if not barcode_val:
                continue
            itemean = str(row.itemean or "").strip()
            regular_price = float(row.retail_price or 0)
            if regular_price <= 0:
                continue

            full_item_name = str(row.a_name or "").strip() or f"صنف {barcode_val}"

            uom_code = str(row.unit_code).strip() if row.unit_code is not None else ""
            db_unit = unit_map.get(uom_code, uom_code)
            final_unit = db_unit.strip() if db_unit and db_unit != "None" else "قطعة"

            try:
                pieces = int(float(row.pieces)) if row.pieces is not None else 1
            except (TypeError, ValueError):
                pieces = 1
            if pieces < 1:
                pieces = 1

            # Per-barcode rule: weighted ONLY when pieces <= 1.
            # Pieces > 1 is always a pack/sack (integer qty), even if the
            # item name contains «وزن» or the sibling barcode is sold by kg.
            unit_l = final_unit.lower()
            looks_weight_unit = (
                "كيلو" in final_unit
                or unit_l in ("kg", "kilo", "كجم")
                or final_unit.strip() == "وزن"
            )
            looks_weight_name = "وزن" in full_item_name
            is_weighted = pieces <= 1 and (looks_weight_unit or looks_weight_name)

            if is_weighted:
                final_unit = "وزن"
            elif pieces > 1:
                # Prefer ERP carton code «ك * N» so Flutter pack helpers work.
                if not (
                    final_unit.startswith("ك")
                    and any(ch.isdigit() for ch in final_unit)
                ):
                    final_unit = f"ك * {pieces}"

            raw_sec = str(row.section_name or "").strip()
            raw_grp = str(row.group_name or "").strip()
            if raw_grp in UNLISTED_CATEGORIES or raw_sec in UNLISTED_CATEGORIES:
                continue
            exact_app_cat = get_exact_app_category(raw_grp, raw_sec)

            try:
                calc_stock = int(float(row.stock_quantity)) if row.stock_quantity is not None else 0
            except (TypeError, ValueError):
                calc_stock = 0
            real_stock = balance_by_ean.get(itemean, calc_stock)

            disc = discount_by_barcode.get(barcode_val)
            promo_price = None
            if disc:
                unit_disc = _unit_discount(
                    regular_price, disc["value"], disc["type"]
                )
                offered = regular_price - unit_disc
                if offered > 0 and offered < regular_price and offered > (regular_price * 0.2):
                    promo_price = round(offered, 3)

            item_data = {
                "barcode": barcode_val,
                "pos_item_ean": itemean or None,
                "name": full_item_name,
                "price": regular_price,
                "stock_quantity": real_stock,
                "discount_price": promo_price,
                "category": exact_app_cat,
                "subcategory": exact_app_cat,
                "unit": final_unit,
                "pieces": pieces,
                "is_weight_based": is_weighted,
            }
            data_to_upsert_dict[barcode_val] = item_data
        data_to_upsert = list(data_to_upsert_dict.values())
        conn.close()

        print(
            f"[{datetime.now().strftime('%I:%M:%S %p')}] "
            f"جاري رفع أصناف Trusty ({len(data_to_upsert)}) صنف لسوبابيز "
            f"(خصومات نشطة: {len(discount_by_barcode)})..."
        )

        batch_size = 1000
        drop_pieces_col = False
        for i in range(0, len(data_to_upsert), batch_size):
            batch = [dict(row) for row in data_to_upsert[i : i + batch_size]]
            if drop_pieces_col:
                for row in batch:
                    row.pop("pieces", None)
            try:
                supabase.table("products").upsert(
                    batch, on_conflict="barcode"
                ).execute()
            except Exception as exc:
                if not drop_pieces_col and "pieces" in str(exc):
                    drop_pieces_col = True
                    for row in batch:
                        row.pop("pieces", None)
                    supabase.table("products").upsert(
                        batch, on_conflict="barcode"
                    ).execute()
                else:
                    raise

        print(f"[{datetime.now().strftime('%I:%M:%S %p')}] ✅ تمت مزامنة الأصناف/الرصيد/الخصومات بنجاح!")

        print(f"[{datetime.now().strftime('%I:%M:%S %p')}] جاري فحص جميع صفحات سوبابيز بالكامل لحذف الأصناف القديمة...")

        supabase_barcodes = set()
        start = 0
        step = 1000
        while True:
            res = supabase.table("products").select("barcode").range(start, start + step - 1).execute()
            if not res.data:
                break
            supabase_barcodes.update(item["barcode"] for item in res.data if item.get("barcode"))
            if len(res.data) < step:
                break
            start += step

        fujitsu_barcodes = set(data_to_upsert_dict.keys())
        barcodes_to_delete = list(supabase_barcodes - fujitsu_barcodes)

        if barcodes_to_delete:
            print(f"🧹 تم العثور على ({len(barcodes_to_delete)}) صنف زيادة سيتم حذفهم بالكامل لتنظيف الداتابيز...")
            delete_batch_size = 200
            for i in range(0, len(barcodes_to_delete), delete_batch_size):
                batch = barcodes_to_delete[i : i + delete_batch_size]
                supabase.table("products").delete().in_("barcode", batch).execute()
            print(f"[{datetime.now().strftime('%I:%M:%S %p')}] ✅ تم تنظيف سوبابيز بالكامل ليتطابق 100% مع المحل!")
        else:
            print(f"[{datetime.now().strftime('%I:%M:%S %p')}] ✨ سوبابيز نظيف ومطابق تماماً لفوجيتسو!")

    except Exception as e:
        print(f"❌ حصل خطأ أثناء المزامنة: {e}")

if __name__ == "__main__":
    print("🚀 تم تشغيل سكريبت سفير ماركت (المزامنة الشاملة وتنظيف البيانات الكامل)...")
    sync_active_with_categories()
    
    while True:
        print("⏳ في انتظار 3 دقائق للمزامنة القادمة...")
        time.sleep(180)
        sync_active_with_categories()