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

def sync_active_with_categories():
    print(f"\n[{datetime.now().strftime('%I:%M:%S %p')}] جاري سحب الأصناف النشطة ذات المخزون الفعلي...")
    
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()

        # سحب قاموس الأقسام والمجموعات
        sec_map = {}
        try:
            cursor.execute("SELECT CAST(section AS VARCHAR), a_name FROM sys_section WHERE a_name IS NOT NULL")
            for row in cursor.fetchall():
                sec_map[str(row[0]).strip()] = str(row[1]).strip()
        except: pass

        grp_map = {}
        try:
            cursor.execute("SELECT CAST(itemgroup AS VARCHAR), a_name FROM sys_group WHERE a_name IS NOT NULL")
            for row in cursor.fetchall():
                grp_map[str(row[0]).strip()] = str(row[1]).strip()
        except: pass

        # سحب قاموس الوحدات (علبة، قطعة، كيلو، إلخ)
        unit_map = {}
        try:
            cursor.execute("SELECT CAST(unit AS VARCHAR), a_name FROM sys_unit WHERE a_name IS NOT NULL")
            for row in cursor.fetchall():
                unit_map[str(row[0]).strip()] = str(row[1]).strip()
        except: pass

        # أضفنا استدعاء u.unit للتعرف على وحدة كل باركود
        sql_query = """
        SELECT 
            LTRIM(RTRIM(CAST(u.barcode AS NVARCHAR(50)))) AS barcode,
            i.a_name AS base_name,
            u.flavour AS unit_flavour,
            u.retailprice AS price,
            (ISNULL(s.total_qty, 0) + ISNULL(unp.unposted_qty, 0)) AS stock_quantity,
            p.prom_price AS offer_price,
            CAST(i.section AS NVARCHAR(100)) AS section_id,
            CAST(i.itemgroup AS NVARCHAR(100)) AS group_id,
            CAST(u.unit AS NVARCHAR(50)) AS uom_code
        FROM sys_item_units u
        JOIN sys_item i ON u.itemean = i.itemean 
        LEFT JOIN (
            SELECT itemean, SUM(inventory_qty) AS total_qty 
            FROM stk_inventory_items 
            GROUP BY itemean
        ) s ON u.itemean = s.itemean
        LEFT JOIN (
            SELECT itemean, SUM(actual_qty) AS unposted_qty 
            FROM stk_order_items 
            WHERE posting = 0 AND doctype = 2010 
              AND orderdate >= DATEADD(day, -15, GETDATE())
            GROUP BY itemean
        ) unp ON u.itemean = unp.itemean
        LEFT JOIN (
            SELECT 
                LTRIM(RTRIM(CAST(pi.barcode AS NVARCHAR(50)))) AS clean_barcode,
                MIN(pi.prom_price) AS prom_price
            FROM pos_promotion_items pi
            LEFT JOIN pos_promotion pr ON (pi.prom_id = pr.prom_id OR pi.promid = pr.prom_id)
            WHERE pi.prom_price > 0
              AND pi.stoped_date IS NULL
              AND (pi.qty_std_price IS NULL OR pi.qty_std_price <= 1)
              AND (
                  (pi.sdate IS NOT NULL AND pi.edate IS NOT NULL AND GETDATE() BETWEEN pi.sdate AND DATEADD(day, 1, pi.edate))
                  OR 
                  (pr.prom_sdate IS NOT NULL AND pr.prom_edate IS NOT NULL AND GETDATE() BETWEEN pr.prom_sdate AND DATEADD(day, 1, pr.prom_edate))
              )
            GROUP BY LTRIM(RTRIM(CAST(pi.barcode AS NVARCHAR(50))))
        ) p ON LTRIM(RTRIM(CAST(u.barcode AS NVARCHAR(50)))) = p.clean_barcode
        WHERE u.barcode IS NOT NULL 
          AND LTRIM(RTRIM(CAST(u.barcode AS NVARCHAR(50)))) != '' 
          AND u.retailprice > 0
          AND i.status = 1
          AND u.transid = 1
          AND (ISNULL(s.total_qty, 0) + ISNULL(unp.unposted_qty, 0)) > 0
        """
        
        cursor.execute(sql_query)
        rows = cursor.fetchall()
        
        data_to_upsert_dict = {}
        for row in rows:
            barcode_val = str(row.barcode).strip()
            regular_price = float(row.price) if row.price else 0
            
            base_name = str(row.base_name or '').strip()
            unit_flavour = str(row.unit_flavour or '').strip()
            
            if unit_flavour and unit_flavour != base_name:
                full_item_name = f"{base_name} - {unit_flavour}" if base_name else unit_flavour
            else:
                full_item_name = base_name if base_name else f"صنف {barcode_val}"

            # ---------------------------------------------
            # استخراج الوحدة الفعلية من الداتابيز مباشرة
            # ---------------------------------------------
            uom_code = str(row.uom_code).strip() if row.uom_code else ""
            db_unit = unit_map.get(uom_code, uom_code)
            
            if db_unit and db_unit != "None" and db_unit != "":
                final_unit = db_unit.strip()
            else:
                final_unit = "قطعة" # حالة افتراضية لو الحقل كان فاضي تماماً
            # ---------------------------------------------

            raw_promo = float(row.offer_price) if row.offer_price else 0
            promo_price = raw_promo if (raw_promo > 0 and raw_promo < regular_price and raw_promo > (regular_price * 0.2)) else None
            
            section_id = str(row.section_id).strip() if row.section_id else ""
            group_id = str(row.group_id).strip() if row.group_id else ""
            
            raw_sec = sec_map.get(section_id, "")
            raw_grp = grp_map.get(group_id, "")
            
            if raw_grp in UNLISTED_CATEGORIES or raw_sec in UNLISTED_CATEGORIES:
                continue

            exact_app_cat = get_exact_app_category(raw_grp, raw_sec)

            real_stock = int(float(row.stock_quantity)) if row.stock_quantity and float(row.stock_quantity) > 0 else 0

            item_data = {
                "barcode": barcode_val,
                "name": full_item_name,
                "price": regular_price,
                "stock_quantity": real_stock,
                "discount_price": promo_price,
                "category": exact_app_cat,      
                "subcategory": exact_app_cat,
                "unit": final_unit # تخزين الوحدة الموثوقة من السيستم
            }
            data_to_upsert_dict[barcode_val] = item_data

        data_to_upsert = list(data_to_upsert_dict.values())
        conn.close()
        
        print(f"[{datetime.now().strftime('%I:%M:%S %p')}] جاري رفع أصناف المخزون الفعلي ({len(data_to_upsert)}) صنف لسوبابيز...")

        batch_size = 1000
        for i in range(0, len(data_to_upsert), batch_size):
            batch = data_to_upsert[i:i + batch_size]
            supabase.table("products").upsert(batch, on_conflict="barcode").execute()
            
        print(f"[{datetime.now().strftime('%I:%M:%S %p')}] ✅ تمت مزامنة المخزون الفعلي والأصناف بنجاح!")

        # ==========================================
        # تنظيف سوبابيز 
        # ==========================================
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
                batch = barcodes_to_delete[i:i + delete_batch_size]
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