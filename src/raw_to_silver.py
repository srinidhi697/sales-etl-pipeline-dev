import sys
import datetime
import boto3
import traceback
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import (
    col, current_timestamp, round as spark_round,
    to_date, year, month, dayofmonth
)
from pyspark.sql.types import (
    StructType, StructField, StringType,
    IntegerType, DoubleType
)


# -----------------------------
# Strict Schema Definition
# -----------------------------
def get_expected_schema():
    return StructType([
        StructField("transaction_id", StringType(), False),
        StructField("date", StringType(), False),
        StructField("store_id", StringType(), False),
        StructField("store_name", StringType(), True),
        StructField("city", StringType(), True),
        StructField("product_id", StringType(), False),
        StructField("product_name", StringType(), True),
        StructField("category", StringType(), True),
        StructField("customer_id", StringType(), False),
        StructField("customer_name", StringType(), True),
        StructField("quantity_sold", IntegerType(), True),
        StructField("unit_price", DoubleType(), True),
        StructField("total_amount", DoubleType(), True),
        StructField("payment_method", StringType(), True),
    ])


# -----------------------------
# Helper: Parse filename → timestamp
# -----------------------------
def filename_to_epoch(key: str) -> int:
    filename = key.split("/")[-1]  # sales_20250822_195142.json
    timestamp_str = filename.replace("sales_", "").replace(".json", "")
    dt = datetime.datetime.strptime(timestamp_str, "%Y%m%d_%H%M%S")
    return int(dt.replace(tzinfo=datetime.timezone.utc).timestamp())


# -----------------------------
# Rename parquet files in partition
# -----------------------------
def rename_parquet_files(bucket, prefix, job_timestamp):
    """Rename part-xxxxx.snappy.parquet -> sales_<ts>_<i>.parquet inside partition folder"""
    s3 = boto3.client("s3")

    resp = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    if "Contents" not in resp:
        print(f"No parquet files found under {prefix}")
        return

    i = 0
    for obj in resp["Contents"]:
        key = obj["Key"]
        if key.endswith(".parquet"):
            new_key = f"{prefix}sales_{job_timestamp}_{i:05d}.parquet"
            print(f"Renaming {key} -> {new_key}")
            s3.copy_object(Bucket=bucket, CopySource={"Bucket": bucket, "Key": key}, Key=new_key)
            s3.delete_object(Bucket=bucket, Key=key)
            i += 1


# -----------------------------
# Main ETL Job
# -----------------------------
def main():
    args = getResolvedOptions(
        sys.argv,
        ["JOB_NAME", "SOURCE_PATH", "TARGET_PATH"]
    )

    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    try:
        print("Starting Raw → Silver ETL")

        # --------- Locate latest raw file ---------
        raw_path = args["SOURCE_PATH"].rstrip("/")
        bucket = raw_path.replace("s3://", "").split("/")[0]
        prefix = "/".join(raw_path.replace("s3://", "").split("/")[1:])

        s3 = boto3.client("s3")
        paginator = s3.get_paginator("list_objects_v2")
        pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

        json_files = [
            obj["Key"]
            for page in pages if "Contents" in page
            for obj in page["Contents"]
            if obj["Key"].endswith(".json") and "sales_" in obj["Key"]
        ]

        if not json_files:
            raise Exception(f"No sales_*.json files found in {args['SOURCE_PATH']}")

        latest_key = max(json_files, key=filename_to_epoch)
        latest_path = f"s3://{bucket}/{latest_key}"
        print(f"Latest raw file: {latest_path}")

        # --------- Read raw JSON ---------
        raw_df = spark.read.schema(get_expected_schema()).json(latest_path)
        total_rows = raw_df.count()
        print(f"Read {total_rows} rows from {latest_path}")

        # --------- Transformations ---------
        df_cleaned = (
            raw_df
            .dropDuplicates()
            .dropna(subset=["transaction_id", "store_id", "product_id", "customer_id"])
            .withColumn("quantity_sold", col("quantity_sold").cast("int"))
            .withColumn("unit_price", col("unit_price").cast("double"))
            .filter(col("quantity_sold") > 0)
            .filter(col("unit_price") > 0)
            .withColumn("total_amount", spark_round(col("quantity_sold") * col("unit_price"), 2))
            .withColumn("date", to_date(col("date"), "yyyy-MM-dd"))
            .withColumn("ingested_at", current_timestamp())
            .withColumn("sales_year", year(current_timestamp()))
            .withColumn("sales_month", month(current_timestamp()))
            .withColumn("sales_day", dayofmonth(current_timestamp()))
        )

        cleaned_rows = df_cleaned.count()
        print(f"After cleaning: {cleaned_rows} rows remain")

        # --------- Write to Silver ---------
        (
            df_cleaned.write
            .mode("append")
            .partitionBy("sales_year", "sales_month", "sales_day")
            .parquet(args["TARGET_PATH"])
        )
        print(f"Written to {args['TARGET_PATH']} partitioned by sales_year/sales_month/sales_day")

        # --------- Rename parquet files inside latest partition ---------
        job_timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        partition_prefix = (
            f"{args['TARGET_PATH'].replace(f's3://{bucket}/', '')}"
            f"sales_year={datetime.datetime.now().year}/"
            f"sales_month={datetime.datetime.now().month}/"
            f"sales_day={datetime.datetime.now().day}/"
        )
        rename_parquet_files(bucket, partition_prefix, job_timestamp)

        job.commit()
        print("Raw → Silver job completed successfully")

    except Exception as e:
        print("Raw → Silver job failed")
        traceback.print_exc()
        job.commit()
        raise e


if __name__ == "__main__":
    main()
