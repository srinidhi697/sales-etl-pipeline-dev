import boto3
import json
import uuid
import random
from faker import Faker
from datetime import datetime
from io import BytesIO
import os
import sys
import traceback

# ---------- CONFIG ----------
FALLBACK_BUCKET = "sales-etl-pipeline-dev-datalake"
PREFIX = "raw/sales"
TARGET_FILE_SIZE_MB = 50
MESSY_RATIO = 0.05
# ----------------------------------------------------

# ---------- LOAD CONFIG ----------
def get_bucket_name():
    
    print("going here")
    return FALLBACK_BUCKET

# ---------- AWS CLIENT ----------
fake = Faker()
s3 = boto3.client("s3")

CATEGORIES = ["Liquor", "Grocery", "Clothing", "Electronics", "Furniture"]
PAYMENT_METHODS = ["Credit Card", "Cash", "Debit Card", "Mobile Pay", "PayPal"]
STORES = [
    ("S101", "Rockville LC", "Rockville"),
    ("S102", "Bethesda LC", "Bethesda"),
    ("S103", "Silver LC", "Silver Spring"),
    ("S104", "Gaithersburg LC", "Gaithersburg"),
    ("S105", "Germantown LC", "Germantown"),
]

# ---------- RECORD GENERATORS ----------
def generate_clean_record():
    store_id, store_name, city = random.choice(STORES)
    quantity = random.randint(1, 5)
    unit_price = round(random.uniform(1, 500), 2)
    return {
        "transaction_id": str(uuid.uuid4())[:8],
        "date": str(fake.date_between(start_date="-365d", end_date="today")),
        "store_id": store_id,
        "store_name": store_name,
        "city": city,
        "product_id": f"P{random.randint(1000,9999)}",
        "product_name": fake.word().title(),
        "category": random.choice(CATEGORIES),
        "customer_id": f"C{random.randint(1000,9999)}",
        "customer_name": fake.name(),
        "quantity_sold": quantity,
        "unit_price": unit_price,
        "total_amount": round(quantity * unit_price, 2),
        "payment_method": random.choice(PAYMENT_METHODS)
    }

def generate_messy_record():
    record = generate_clean_record()
    if random.random() < 0.5:
        record["unit_price"] = "FREE"      # wrong type
    if random.random() < 0.5:
        record["customer_name"] = None     # missing value
    if random.random() < 0.3:
        record["quantity_sold"] = -5       # invalid value
    return record

# ---------- S3 UPLOAD ----------
def upload_to_s3(bucket, key, data_bytes):
    try:
        s3.upload_fileobj(BytesIO(data_bytes), bucket, key)
        print(f"Uploaded to s3://{bucket}/{key}")
    except Exception as e:
        print(f"Failed to upload {key} to S3: {e}")
        traceback.print_exc()
        sys.exit(1)

# ---------- MAIN ----------
def generate_sales_data():
    bucket = get_bucket_name()
    today = datetime.today()
    key = f"{PREFIX}/sales_{today.strftime('%Y%m%d_%H%M%S')}.json"

    records, file_size_bytes, row_count = [], 0, 0
    target_bytes = TARGET_FILE_SIZE_MB * 1024 * 1024

    while file_size_bytes < target_bytes:
        record = generate_messy_record() if random.random() < MESSY_RATIO else generate_clean_record()
        line = json.dumps(record) + "\n"
        records.append(line)
        file_size_bytes += len(line.encode("utf-8"))
        row_count += 1

    json_data = "".join(records).encode("utf-8")
    upload_to_s3(bucket, key, json_data)
    print(f"Row Count: {row_count:,} rows, ~{TARGET_FILE_SIZE_MB}MB")

def main():
    try:
        generate_sales_data()
    except Exception as e:
        print("Data generation failed")
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
