"""Upload every .jpg in IMAGES_DIR to the 'product_images' Supabase bucket 
and link them directly to the products table in the database."""

from __future__ import annotations

import sys
import time
from pathlib import Path

from supabase import Client, create_client

# ---------------------------------------------------------------------------
SUPABASE_URL = "https://jugdxfhmjakmzjvfltjv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1Z2R4ZmhtamFrbXpqdmZsdGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MDg1ODQ4MiwiZXhwIjoyMTA2NDM0NDgyfQ.mYevkOHQRX0dYIl73LMm8XI37yd5_i5paUU23uhpUVE"

BUCKET_NAME = "product_images"
DELAY_SECONDS = 0.1  # تم تقليل الوقت لتسريع الرفع

# تم تعديل المسار ليقرأ من مجلد طلبات مباشرة
IMAGES_DIR = Path("C:\\Users\\DELL\\Projects\\safeer_market\\seoudi_images")


def local_images() -> list[Path]:
    return sorted(
        path
        for path in IMAGES_DIR.iterdir()
        if path.is_file() and path.suffix.lower() == ".jpg" and path.stat().st_size > 0
    )


def is_duplicate_error(error: Exception) -> bool:
    text = str(error).lower()
    return "duplicate" in text or "already exists" in text or "409" in text


def main() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        sys.exit("Set SUPABASE_URL and SUPABASE_KEY at the top of the script.")
    if not IMAGES_DIR.is_dir():
        sys.exit(f"Images folder not found: {IMAGES_DIR}")

    images = local_images()
    if not images:
        sys.exit(f"No .jpg files found in {IMAGES_DIR}")

    client = create_client(SUPABASE_URL, SUPABASE_KEY)
    bucket = client.storage.from_(BUCKET_NAME)

    print(f"Found {len(images)} local .jpg files. Uploading and linking to App Database...")

    uploaded = updated = linked = failed = 0
    for index, path in enumerate(images, start=1):
        barcode = path.stem  # استخراج الباركود من اسم الصورة بدون .jpg
        prefix = f"Processing {index}/{len(images)}: {path.name}"
        
        try:
            # 1. قراءة ورفع الصورة (أو تحديثها إذا كانت موجودة)
            file_bytes = path.read_bytes()
            status_msg = ""
            
            try:
                bucket.upload(
                    path.name,
                    file_bytes,
                    {"content-type": "image/jpeg", "upsert": "true"}
                )
                uploaded += 1
                status_msg = "Uploaded"
            except Exception as e:
                if is_duplicate_error(e):
                    # إجبار التحديث في حالة وجود الصورة مسبقاً
                    bucket.update(
                        path.name,
                        file_bytes,
                        {"content-type": "image/jpeg", "upsert": "true"}
                    )
                    updated += 1
                    status_msg = "Updated"
                else:
                    raise e
            
            # 2. ربط الصورة بقاعدة البيانات مباشرة ليقرأها التطبيق
            public_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{path.name}"
            
            # تم التعديل لاستخدام like لتجاهل مسافات فوجيتسو
            db_res = client.table("products").update({"image_url": public_url}).like("barcode", f"{barcode}%").execute()
            
            if len(db_res.data) > 0:
                print(f"{prefix} ... {status_msg} & Linked to App successfully!")
                linked += 1
            else:
                print(f"{prefix} ... {status_msg} (Waiting for product to sync from Fujitsu)")
                
        except Exception as error:
            failed += 1
            print(f"{prefix} ... FAILED: {error}")
            
        if index < len(images):
            time.sleep(DELAY_SECONDS)

    print(
        f"\nFinished. New Uploads: {uploaded}, Replaced: {updated}, Linked in App: {linked}, Failed: {failed}."
    )


if __name__ == "__main__":
    main()