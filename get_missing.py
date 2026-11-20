import pandas as pd
from supabase import create_client, Client

# ==========================================
# إعدادات سوبابيز
# ==========================================
SUPABASE_URL = "https://jugdxfhmjakmzjvfltjv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def export_missing_to_excel():
    print("🚀 جاري سحب الأصناف اللي لسه ملهاش صور من الداتابيز...")
    
    offset = 0
    limit = 1000
    all_missing = []
    
    while True:
        # بنسحب الأصناف اللي عمود image_url بتاعها فاضي (null)
        response = supabase.table('products').select('barcode, name').is_('image_url', 'null').range(offset, offset + limit - 1).execute()
        data = response.data
        
        if not data:
            break
            
        all_missing.extend(data)
        
        if len(data) < limit:
            break
            
        offset += limit
        
    print(f"📦 تم العثور على ({len(all_missing)}) صنف بدون صورة.")
    
    if all_missing:
        # تحويل البيانات لملف إكسيل حقيقي (.xlsx)
        df = pd.DataFrame(all_missing)
        df = df[['barcode', 'name']] # ترتيب الأعمدة
        df.columns = ['Barcode', 'Product Name'] # تسمية الأعمدة
        
        file_name = 'missing_talabat_5000.xlsx'
        df.to_excel(file_name, index=False)
        print(f"🎉 تم حفظ النواقص بنجاح في ملف الإكسيل: {file_name}")
    else:
        print("✅ مفيش نواقص! كل المنتجات ليها صور.")

if __name__ == "__main__":
    export_missing_to_excel()