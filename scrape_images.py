"""Download a product image for every barcode in barcodes.txt.
Uses the specific searchClientProductsV4 Cloud Function for Instashop.
"""

from __future__ import annotations

import json
import random
import sys
import time
from pathlib import Path
from urllib.parse import urlparse

import requests

# URL for the Cloud Function
PARSE_SERVER_URL = "https://data3.instashop.ae/parse/functions/searchClientProductsV4"

HEADERS = {
    "X-Parse-Application-Id": "Q8p0cZiOEs6POXNb4tNqqP7NdzXsQkd9Mzzdkdq6",
    "X-Parse-Rest-Api-Key": "UCOGUXAS6gqQRy3p184T0TI7M8UDWOoR1AQ5JF7y",
    "X-Parse-Session-Token": "r:86265a062cba7d31070158e620fc5b2d",
    "X-Parse-Client-Id": "KJwgLHjHof",
    "X-Is-Installation": "63fd4d3f-0d6b-4487-89e4-46c3f25d91e5",
    "X-Is-User": "mWMJUAN3AC",
    "Content-Type": "application/json;charset=UTF-8"
}

BATCH_SIZE = 5
COOLDOWN_MIN_SECONDS = 60
COOLDOWN_MAX_SECONDS = 120
MAX_RETRIES = 2
RETRY_STATUSES = {400, 429, 403, 500}
TIMEOUT_SECONDS = 30

ROOT = Path(__file__).resolve().parent
BARCODES_FILE = ROOT / "barcodes.txt"
IMAGES_DIR = ROOT / "images"
NOT_FOUND_FILE = IMAGES_DIR / "not_found.txt"


def load_barcodes() -> list[str]:
    lines = BARCODES_FILE.read_text(encoding="utf-8").splitlines()
    return list(dict.fromkeys(line.strip() for line in lines if line.strip()))


def already_done(barcode: str, not_found: set[str]) -> bool:
    if barcode in not_found:
        return True
    return any(
        path.suffix != ".part" and path.stat().st_size > 0
        for path in IMAGES_DIR.glob(f"{barcode}.*")
    )


def image_url(record: dict) -> str | None:
    # We check if 'image' exists and has a url, or if 'imageUrl' exists
    image_data = record.get("image")
    if isinstance(image_data, dict):
        return image_data.get("url")
    
    if isinstance(image_data, str) and image_data.startswith("http"):
         return image_data

    # Fallback to check if they return it directly
    if record.get("imageUrl"):
         return record.get("imageUrl")
    
    return None


def cooldown() -> None:
    seconds = random.randint(COOLDOWN_MIN_SECONDS, COOLDOWN_MAX_SECONDS)
    print(f"  ({seconds}s cooldown)")
    time.sleep(seconds)


class Throttle:
    def __init__(self) -> None:
        self.attempts = 0

    def count_attempt(self) -> None:
        self.attempts += 1
        if self.attempts % BATCH_SIZE == 0:
            print("Batch finished. Cooling down...")
            cooldown()


def fetch_with_retry(
    session: requests.Session, throttle: Throttle, url: str, method: str = "GET", **kwargs
) -> requests.Response:
    for attempt in range(MAX_RETRIES + 1):
        try:
            if method == "POST":
                response = session.post(url, timeout=TIMEOUT_SECONDS, **kwargs)
            else:
                response = session.get(url, timeout=TIMEOUT_SECONDS, **kwargs)
        except requests.RequestException as e:
            print(f"Request Error: {e}. Waiting 30 seconds...")
            time.sleep(30)
            throttle.count_attempt()
            continue
            
        if response.status_code in RETRY_STATUSES and attempt < MAX_RETRIES:
            print(
                f"HTTP {response.status_code}, retry {attempt + 1}/{MAX_RETRIES}. "
                "Cooling down..."
            )
            cooldown()
            continue
            
        response.raise_for_status()
        return response
    raise AssertionError("unreachable")


def lookup(session: requests.Session, throttle: Throttle, barcode: str) -> str | None:
    # Build the Payload exactly as it appeared in your image
    payload = {
        "businessType": {"grocery": True},
        "clientCategoriesIds": ["FHXfQPOp4", "lFgRQpgLBE", "TLGZN21KUW", "XE7kc3ZoS8", "YfYGGbDH6t", "Q1KSfIRQar", "6t7iySKMFG"],
        "clientId": "KJwgLHjHof",
        "hiddenCategoriesIds": ["aNAk1YWyaQ", "E83lN5h9LJ", "ujNu1lXvaX", "GebFyT9vXz"],
        "queryObject": {
            "size": 60,
            "page": 0,
            "q": barcode, # Put the barcode as the search query
            "active": False,
            "inactive": False,
            "hasprice": False,
            "noprice": False
        },
        "systemInfo": {"countryId": "vrii93Zwoj"}
    }

    response = fetch_with_retry(
        session,
        throttle,
        PARSE_SERVER_URL,
        method="POST",
        json=payload
    )
    
    # Parse the result
    data = response.json()
    # Depending on their exact response structure, the products are usually nested in 'result' -> 'content' or just 'result'
    result = data.get("result", {})
    content = result.get("content", []) if isinstance(result, dict) else result
    
    if not content or not isinstance(content, list):
         return None
         
    # Take the first product from the search results
    return image_url(content[0])


def download(
    session: requests.Session, throttle: Throttle, barcode: str, url: str
) -> Path:
    response = fetch_with_retry(session, throttle, url, method="GET")
    extension = Path(urlparse(url).path).suffix or ".jpg"
    target = IMAGES_DIR / f"{barcode}{extension}"
    partial = target.with_suffix(target.suffix + ".part")
    partial.write_bytes(response.content)
    partial.replace(target)
    return target


def main() -> None:
    IMAGES_DIR.mkdir(exist_ok=True)
    not_found = (
        set(NOT_FOUND_FILE.read_text(encoding="utf-8").split())
        if NOT_FOUND_FILE.exists()
        else set()
    )

    barcodes = load_barcodes()
    
    # هنا التعديل السحري: هنفلتر الباركودز تماماً قبل ما اللوب يبدأ أصلاً!
    pending = [b for b in barcodes if not already_done(b, not_found)]
    
    already_completed_count = len(barcodes) - len(pending)
    print(f"🎉 Great news: {already_completed_count} products ALREADY DONE! Skipping them entirely without waiting.")
    print(f"🚀 {len(pending)} remaining products to go. Starting now...")

    if not pending:
        print("Everything is already done! Nothing to download.")
        return

    session = requests.Session()
    session.headers.update(HEADERS)
    throttle = Throttle()

    for index, barcode in enumerate(pending, start=1):
        prefix = f"[{index}/{len(pending)}] {barcode}:"
        try:
            url = lookup(session, throttle, barcode)
            if url is None:
                with NOT_FOUND_FILE.open("a", encoding="utf-8") as handle:
                    handle.write(f"{barcode}\n")
                print(f"{prefix} no image found from search")
                continue
            saved = download(session, throttle, barcode, url)
            print(f"{prefix} saved {saved.name}")
        except requests.HTTPError as error:
            body = error.response.text[:200] if error.response is not None else ""
            print(f"{prefix} HTTP error {error}: {body}")
        except requests.RequestException as error:
            print(f"{prefix} request failed: {error}")