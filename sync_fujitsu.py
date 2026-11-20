import pyodbc
import asyncio
from datetime import datetime
from supabase import create_async_client, AsyncClient

# ================= إعدادات الاتصال =================
# 1. إعدادات فيجيتسو (SQL Server)
SQL_SERVER = '40.40.40.2'
SQL_DATABASE = 'retail_test'
SQL_USERNAME = 'sa'
SQL_PASSWORD = 'retipr'

# 2. إعدادات سابابيز (Supabase)
SUPABASE_URL = 'https://jugdxfhmjakmzjvfltjv.supabase.co/rest/v1'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE'

def connect_to_sql_server():
    """الاتصال بقاعدة بيانات فيجيتسو"""
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};UID={SQL_USERNAME};PWD={SQL_PASSWORD}'
    return pyodbc.connect(conn_str)

async def sync_receipt_to_fujitsu(supabase: AsyncClient, record: dict):
    """نقل الفاتورة لحظياً إلى فيجيتسو"""
    invoice_no = record.get('invoice_no')
    
    # انتظار ثانيتين لضمان حفظ الأصناف بالكامل في سابابيز قبل السحب
    await asyncio.sleep(2)
    
    try:
        conn = connect_to_sql_server()
        cursor = conn.cursor()

        # تحديد نوع الإذن
        doc_type_text = record.get('doc_type', 'استلام')
        invoice_type = 2050 if doc_type_text == 'استرجاع' else 2010
        invoice_date = record.get('invoice_date')
        supplier_id = record.get('supplier_id')
        receipt_id = record.get('id')
        
        # 1. إدخال الفاتورة
        insert_invoice_query = """
            INSERT INTO pur_invoice (invoiceno, invoicedate, supplierno, invoicetype)
            VALUES (?, ?, ?, ?)
        """
        cursor.execute(insert_invoice_query, (invoice_no, invoice_date, supplier_id, invoice_type))
        
        # 2. جلب الأصناف من سابابيز
        items_response = await supabase.table('app_receipt_items').select('*').eq('receipt_id', receipt_id).execute()
        items = items_response.data
        
        # 3. إدخال الأصناف
        for item in items:
            barcode = item.get('barcode') 
            quantity = item.get('quantity')
            
            insert_item_query = """
                INSERT INTO pur_invoice_item (invoiceno, invoicetype, itemean, quantity)
                VALUES (?, ?, ?, ?)
            """
            cursor.execute(insert_item_query, (invoice_no, invoice_type, barcode, quantity))

        # تأكيد الحفظ
        conn.commit()
        print(f"[{datetime.now()}] ✅ تم نقل الإذن رقم {invoice_no} ({doc_type_text}) بنجاح!")

        # تحديث حالة الفاتورة لمنع التكرار
        await supabase.table('app_receipts').update({'is_synced': True}).eq('id', receipt_id).execute()

    except Exception as e:
        print(f"[{datetime.now()}] ❌ خطأ أثناء نقل الإذن {invoice_no}: {e}")
        if 'conn' in locals():
            conn.rollback()
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals(): conn.close()

async def main():
    # استخدام النسخة غير المتزامنة (AsyncClient) المطلوبة للـ Realtime
    supabase: AsyncClient = await create_async_client(SUPABASE_URL, SUPABASE_KEY)

    def on_new_receipt(payload):
        record = payload.get("record", {})
        print(f"\n[{datetime.now()}] ⚡ إشعار لحظي: تم رصد إذن جديد رقم {record.get('invoice_no')}. جاري المعالجة...")
        # تنفيذ النقل بدون تعطيل الاستماع
        asyncio.create_task(sync_receipt_to_fujitsu(supabase, record))

    print(f"[{datetime.now()}] 🚀 السكريبت يعمل الآن في وضع السكون (Realtime Listener)...")
    
    # فتح القناة اللحظية
    channel = supabase.channel("receipts_channel")
    channel.on("postgres_changes", event="INSERT", schema="public", table="app_receipts", callback=on_new_receipt)
    await channel.subscribe()
    
    # إبقاء السكريبت يعمل إلى الأبد
    while True:
        await asyncio.sleep(3600)

if __name__ == "__main__":
    asyncio.run(main())