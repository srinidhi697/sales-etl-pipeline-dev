import boto3, json, uuid, random, tempfile, os, time
from faker import Faker
from datetime import datetime
import traceback, sys

BUCKET = "sales-etl-pipeline-dev-datalake"
PREFIX = "raw/sales"
TARGET_FILE_SIZE_MB = 5000
MESSY_RATIO = 0.05

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
        record["unit_price"] = "FREE"
    if random.random() < 0.5:
        record["customer_name"] = None
    if random.random() < 0.3:
        record["quantity_sold"] = -5
    return record

def generate_sales_data():
    bucket = BUCKET
    today = datetime.today()
    key = f"{PREFIX}/sales_{today.strftime('%Y%m%d_%H%M%S')}.json" #file_name
    target_bytes = TARGET_FILE_SIZE_MB * 1024 * 1024

    row_count, file_size_bytes = 0, 0

    # Write directly to a temp file on disk
    t1 = time.time()
    with tempfile.NamedTemporaryFile(delete=False, mode="w", encoding="utf-8") as tmp:
        tmp_name = tmp.name
        while file_size_bytes < target_bytes:
            record = generate_messy_record() if random.random() < MESSY_RATIO else generate_clean_record()
            line = json.dumps(record) + "\n"
            tmp.write(line)
            row_count += 1
            file_size_bytes += len(line.encode("utf-8")) #getting number of bytes written into the file

            if row_count % 10000 == 0:
                print(f"Done with generating {round(file_size_bytes/(1024 ** 3),3)}Gb of data")
    t2 = time.time()
    print("Time required for generating the data",t2-t1)

    # Upload the single file to S3
    s3.upload_file(tmp_name, bucket, key)
    os.remove(tmp_name)

    print(f"Uploaded one file to s3://{bucket}/{key}")
    print(f"Row Count: {row_count:,}, Size: ~{TARGET_FILE_SIZE_MB} MB")

if __name__ == "__main__":
    try:
        generate_sales_data()
    except Exception:
        traceback.print_exc()
        sys.exit(1)
