# gold_to_redshift_csv.py
import sys, time, traceback, boto3
from awsglue.utils import getResolvedOptions

args = getResolvedOptions(sys.argv, [
    "REDSHIFT_CLUSTER_ID","REDSHIFT_DB","REDSHIFT_USER",
    "REDSHIFT_ROLE","SOURCE_PATH"
])

CLUSTER = args["REDSHIFT_CLUSTER_ID"]
DB      = args["REDSHIFT_DB"]
USER    = args["REDSHIFT_USER"]
ROLE    = args["REDSHIFT_ROLE"]
SOURCE  = args["SOURCE_PATH"].rstrip("/") + "/"

rsd = boto3.client("redshift-data")

def run_sql(sql: str):
    print("SQL>", sql[:120])
    sid = rsd.execute_statement(ClusterIdentifier=CLUSTER, Database=DB, DbUser=USER, Sql=sql)["Id"]
    while True:
        d = rsd.describe_statement(Id=sid)
        if d["Status"] in ("FINISHED","FAILED","ABORTED"):
            break
        time.sleep(2)
    if d["Status"] != "FINISHED":
        raise RuntimeError(d.get("Error","SQL failed"))
    return d

def copy_csv(table, s3_path, truncate=True):
    if truncate:
        run_sql(f"TRUNCATE TABLE {table};")
    run_sql(f"""
        COPY {table}
        FROM '{s3_path}'
        IAM_ROLE '{ROLE}'
        DELIMITER ','
        IGNOREHEADER 1
        CSV
        DATEFORMAT 'auto'
        TIMEFORMAT 'auto';
    """)

def load_dimensions():
    bases = [
        ("dim_store",    SOURCE + "dim_store_csv/"),
        ("dim_product",  SOURCE + "dim_product_csv/"),
        ("dim_customer", SOURCE + "dim_customer_csv/"),
    ]
    for tbl, pref in bases:
        print(f"Loading {tbl} …")
        copy_csv(tbl, pref)

def load_fact():
    print("Loading fact_sales …")
    copy_csv("fact_sales", SOURCE + "fact_sales_csv/")

def main():
    try:
        print(f"Source: {SOURCE}")
        load_dimensions()
        load_fact()
        print("All files loaded to Redshift")
    except Exception as e:
        print("FAILED", e)
        traceback.print_exc()
        raise

if __name__ == "__main__":
    main()
