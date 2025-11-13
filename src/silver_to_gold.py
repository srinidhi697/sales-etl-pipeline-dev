import sys, datetime, boto3, traceback
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F

def get_latest_partition(bucket, base_prefix):
    s3 = boto3.client("s3")
    paginator = s3.get_paginator("list_objects_v2")
    result = paginator.paginate(Bucket=bucket, Prefix=base_prefix)

    partitions = set()
    for page in result:
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if "sales_day=" in key:
                partition_prefix = (
                    key.split("sales_day=")[0]
                    + "sales_day="
                    + key.split("sales_day=")[1].split("/")[0]
                    + "/"
                )
                partitions.add(partition_prefix)

    if not partitions:
        raise Exception("No day-level partitions found under Silver path")

    latest_partition = max(partitions)
    print(f"Latest Silver partition selected: {latest_partition}")
    return f"s3://{bucket}/{latest_partition}"

def main():
    args = getResolvedOptions(sys.argv, ["JOB_NAME", "SOURCE_PATH", "TARGET_PATH"])

    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    try:
        print("Starting Silver → Gold ETL (CSV mode, no ingested_at)")

        source_path = args["SOURCE_PATH"].rstrip("/")
        bucket = source_path.replace("s3://", "").split("/")[0]
        prefix = "/".join(source_path.replace("s3://", "").split("/")[1:])

        latest_partition = get_latest_partition(bucket, prefix)
        silver_df = spark.read.parquet(latest_partition)
        print(f"Read {silver_df.count()} rows")

        # Ensure schema
        silver_df = (
            silver_df.withColumn("date", F.col("date").cast("date"))
            .withColumn("quantity_sold", F.col("quantity_sold").cast("int"))
            .withColumn("unit_price", F.col("unit_price").cast("double"))
            .withColumn("total_amount", F.col("total_amount").cast("double"))
        )

        # Dimension Tables
        dim_store    = silver_df.select("store_id","store_name","city").dropDuplicates(["store_id"])
        dim_product  = silver_df.select("product_id","product_name","category").dropDuplicates(["product_id"])
        dim_customer = silver_df.select("customer_id","customer_name").dropDuplicates(["customer_id"])

        # Fact Table (drop ingested_at)
        fact_sales = silver_df.select(
            "transaction_id","date","store_id","product_id",
            "customer_id","quantity_sold","unit_price",
            "total_amount","payment_method"
        )

        fact_path       = f"{args['TARGET_PATH']}/fact_sales_csv/"
        dim_store_path  = f"{args['TARGET_PATH']}/dim_store_csv/"
        dim_product_path= f"{args['TARGET_PATH']}/dim_product_csv/"
        dim_customer_path=f"{args['TARGET_PATH']}/dim_customer_csv/"

        # Write CSVs with header
        fact_sales.write.option("header","true").option("delimiter",",").mode("overwrite").csv(fact_path)
        dim_store.write.option("header","true").option("delimiter",",").mode("overwrite").csv(dim_store_path)
        dim_product.write.option("header","true").option("delimiter",",").mode("overwrite").csv(dim_product_path)
        dim_customer.write.option("header","true").option("delimiter",",").mode("overwrite").csv(dim_customer_path)

        print("Silver → Gold completed successfully")

        job.commit()
    except Exception:
        traceback.print_exc()
        job.commit()
        raise

if __name__ == "__main__":
    main()
