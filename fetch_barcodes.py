"""Fetch in-stock barcodes from public.products into barcodes.txt.

Only rows with stock_quantity above zero are requested, matching the app's
in-stock rule (null stock counts as zero and is excluded). Uses the same
Supabase URL and publishable (anon) key as the Flutter app
(lib/core/config/app_config.dart). Override with SUPABASE_URL /
SUPABASE_ANON_KEY environment variables if needed.

    pip install supabase
    python fetch_barcodes.py
"""

from __future__ import annotations

import os
from pathlib import Path

from supabase import create_client

SUPABASE_URL = os.environ.get(
    "SUPABASE_URL", "https://jugdxfhmjakmzjvfltjv.supabase.co"
)
SUPABASE_ANON_KEY = os.environ.get(
    "SUPABASE_ANON_KEY", "sb_publishable_sG4TQm_Y90WEVVha9zC8hQ_aGM0C0ia"
)

PAGE_SIZE = 1000
OUTPUT_FILE = Path(__file__).resolve().parent / "barcodes.txt"


def fetch_all_barcodes() -> list[str]:
    client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    barcodes: list[str] = []
    offset = 0

    while True:
        response = (
            client.table("products")
            .select("barcode")
            .not_.is_("barcode", "null")
            .gt("stock_quantity", 0)
            .order("id")
            .range(offset, offset + PAGE_SIZE - 1)
            .execute()
        )
        rows = response.data or []
        if not rows:
            break

        barcodes.extend(str(row["barcode"]) for row in rows)
        # Advance by what the server actually returned: its max-rows cap may
        # be smaller than PAGE_SIZE.
        offset += len(rows)
        print(f"Fetched {offset} barcodes...")

    return barcodes


def main() -> None:
    barcodes = fetch_all_barcodes()
    OUTPUT_FILE.write_text(
        "".join(f"{barcode}\n" for barcode in barcodes), encoding="utf-8"
    )
    print(f"Saved {len(barcodes)} barcodes to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
