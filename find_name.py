import pyodbc

connection_string = "DRIVER={ODBC Driver 18 for SQL Server};SERVER=40.40.40.2;DATABASE=retail;UID=sa;PWD=retipr;TrustServerCertificate=yes;"

print("🔍 جاري البحث عن مكان اسم (جردل 10 كجم) في كل جداول السيستم...")
try:
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    
    # بنجيب كل الأعمدة النصية في الداتابيز
    cursor.execute("SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar')")
    columns = cursor.fetchall()
    
    found = False
    for table, col in columns:
        try:
            # بندور على أي سطر مكتوب فيه كلمة جردل
            query = f"SELECT TOP 1 {col} FROM {table} WHERE {col} LIKE N'%جردل 10%'"
            cursor.execute(query)
            if cursor.fetchone():
                print(f"✅ قفشناه! الاسم المخصص متسجل في جدول: {table} | عمود: {col}")
                found = True
        except:
            continue
            
    if not found:
        print("❌ ملقيناش الكلمة.. اتأكد إنك كاتبها في السيستم بنفس الحروف بالظبط.")
        
    conn.close()
except Exception as e:
    print(f"❌ خطأ: {e}")