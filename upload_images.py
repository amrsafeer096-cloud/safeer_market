import pandas as pd
import requests
import mimetypes
from supabase import create_client, Client

# ==========================================
# 1. إعدادات سوبابيز
# ==========================================
SUPABASE_URL = "https://jugdxfhmjakmzjvfltjv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE"
BUCKET_NAME = "product_images"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def process_and_upload_images():
    print("📂 جاري قراءة الملفات...")
    
    try:
        # 1. قراءة ملف الـ CSV الأصلي (اللي الباركودات فيه سليمة ومفيهاش أصفار)
        df_csv = pd.read_csv('missing_images_real.csv', sep=';', header=None, dtype=str)
        # تنظيف الأسماء من المسافات الزايدة
        df_csv[1] = df_csv[1].astype(str).str.strip()
        df_csv[0] = df_csv[0].astype(str).str.strip()
        
        # عمل قاموس (Dictionary) بيربط اسم الصنف بالباركود السليم بتاعه
        barcode_dict = dict(zip(df_csv[1], df_csv[0]))
        
        # 2. قراءة الإكسيل اللي فيه الصور واللينكات
        df_excel = pd.read_excel('images.xlsx', header=None, dtype=str)
        success_count = 0
        
        for index, row in df_excel.iterrows():
            item_name = str(row[1]).strip()
            image_url = str(row[2]).strip()
            
            # 💡 السحر هنا: سحب الباركود السليم من القاموس بناءً على اسم الصنف!
            correct_barcode = barcode_dict.get(item_name)
            
            # لو ملقاهوش في الـ CSV لأي سبب، نستخدم اللي في الإكسيل كبديل طوارئ
            if not correct_barcode or correct_barcode.lower() == 'nan':
                correct_barcode = str(row[0]).strip().replace('.0', '')
                
            if correct_barcode.lower() != 'barcode' and pd.notna(image_url) and image_url.startswith('http'):
                print(f"⏳ جاري معالجة: {item_name} ({correct_barcode})...")
                
                try:
                    response = requests.get(image_url, timeout=10)
                    if response.status_code == 200:
                        file_bytes = response.content
                        
                        content_type = response.headers.get('content-type', 'image/png')
                        ext = mimetypes.guess_extension(content_type) or '.png'
                        file_name = f"{correct_barcode}{ext}"
                        
                        # رفع الصورة
                        supabase.storage.from_(BUCKET_NAME).upload(
                            path=file_name,
                            file=file_bytes,
                            file_options={"content-type": content_type, "upsert": "true"}
                        )
                        
                        # اللينك الجديد
                        public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_name)
                        
                        # التحديث باستخدام like لتجاهل مسافات فوجيتسو
                        db_response = supabase.table("products").update({"image_url": public_url}).like("barcode", f"{correct_barcode}%").execute()
                        
                        if db_response.data:
                            print(f"✅ تم الرفع والتحديث بنجاح: {item_name}")
                            success_count += 1
                        else:
                            print(f"⚠️ الصورة اترفعت، لكن الباركود {correct_barcode} مش موجود في الداتابيز.")
                    else:
                        print(f"❌ فشل تحميل صورة {item_name}. اللينك قديم أو مش شغال.")
                        
                except Exception as e:
                    print(f"❌ خطأ أثناء معالجة {item_name}: {e}")
                    
        print(f"\n🎉 تمت العملية بنجاح! تم ربط ({success_count}) صورة بالداتابيز.")
        
    except Exception as e:
        print(f"❌ حصل خطأ: {e}")

if __name__ == "__main__":
    process_and_upload_images()