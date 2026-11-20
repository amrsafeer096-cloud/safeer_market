const sql = require('mssql');
const { createClient } = require('@supabase/supabase-js');

// 1. إعدادات السيرفر
const sqlConfig = {
    user: 'sa',
    // تنبيه: لو كنت رجعت الباسورد القديم عشان برنامج فيجيتسو يشتغل، امسح ده واكتب الباسورد القديم مكانه
    password: 'retipr', 
    server: '40.40.40.2', 
    database: 'retail',
    port: 1433,
    options: {
        encrypt: false, 
        trustServerCertificate: true 
    }
};

// 2. إعدادات Supabase
const supabaseUrl = 'https://jugdxfhmjakmzjvfltjv.supabase.co'; 
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE'; // متنساش تحط المفتاح بتاعك هنا
const supabase = createClient(supabaseUrl, supabaseKey);

function cleanText(value) {
    if (value == null) return null;
    const text = String(value).trim();
    return text === '' ? null : text;
}

// Optional `products` columns, forwarded only when the SELECT returns them
// under these names; otherwise Supabase keeps the stored values.
function optionalFields(item) {
    const fields = {};
    if ('category_id' in item) fields.category_id = cleanText(item.category_id);
    if ('sub_category' in item) fields.sub_category = cleanText(item.sub_category);
    if ('stock_quantity' in item) {
        fields.stock_quantity = Math.max(0, Math.floor(Number(item.stock_quantity) || 0));
    }
    if ('discount_price' in item) {
        const discount = Number(item.discount_price);
        fields.discount_price = item.discount_price == null || !Number.isFinite(discount) ? null : discount;
    }
    if ('is_active' in item) fields.is_active = Boolean(item.is_active);
    return fields;
}

async function syncAllProducts() {
    try {
        console.log('Connecting to Market SQL Server...');
        await sql.connect(sqlConfig);
        
        // جلب كل الأصناف من الجدول الأساسي
        const result = await sql.query(`
            SELECT 
                barcode, 
                a_name AS name, 
                sell_price AS price
            FROM dbo.pos_items
            WHERE barcode IS NOT NULL AND barcode != ''
        `);

        const products = result.recordset;
        console.log(`Found ${products.length} rows. Cleaning up duplicates...`);

        // فلترة الباركود المتكرر عشان نمنع إيرور Supabase
        const uniqueProductsMap = new Map();
        // SQL Server char columns pad with spaces; the app matches barcodes exactly.
        for (const item of products) {
            const barcode = item.barcode == null ? '' : String(item.barcode).trim();
            if (barcode) {
                uniqueProductsMap.set(barcode, {
                    barcode,
                    name: (item.name || '').trim() || 'بدون اسم',
                    price: Number(item.price) || 0,
                    ...optionalFields(item)
                });
            }
        }
        
        const uniqueProducts = Array.from(uniqueProductsMap.values());
        console.log(`Ready to sync ${uniqueProducts.length} UNIQUE products to Supabase.`);

        // الرفع في دفعات (500 صنف كل مرة عشان السرعة)
        const BATCH_SIZE = 500;
        for (let i = 0; i < uniqueProducts.length; i += BATCH_SIZE) {
            const batch = uniqueProducts.slice(i, i + BATCH_SIZE);

            const { error } = await supabase
                .from('products') 
                .upsert(batch, { onConflict: 'barcode' });

            if (error) {
                console.error(`Error syncing batch starting at ${i}:`, error.message);
            } else {
                console.log(`Successfully synced ${Math.min(i + BATCH_SIZE, uniqueProducts.length)} / ${uniqueProducts.length} products`);
            }
        }

        console.log('SYNC 100% COMPLETED!');
        process.exit();

    } catch (err) {
        console.error('CRITICAL ERROR:', err);
        process.exit(1);
    }
}

syncAllProducts();