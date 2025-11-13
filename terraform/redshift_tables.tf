resource "aws_redshiftdata_statement" "create_gold_tables" {
  cluster_identifier = var.redshift_cluster_id
  database           = var.redshift_db_name
  db_user            = var.redshift_user

  sql = <<EOT
  -- Fact Table
  CREATE TABLE IF NOT EXISTS fact_sales (
      transaction_id   VARCHAR(50),
      date             DATE,
      store_id         VARCHAR(20),
      product_id       VARCHAR(20),
      customer_id      VARCHAR(20),
      quantity_sold    INT,
      unit_price       DOUBLE PRECISION,
      total_amount     DOUBLE PRECISION,
      payment_method   VARCHAR(50)
  );

  -- Dimension: Store
  CREATE TABLE IF NOT EXISTS dim_store (
      store_id   VARCHAR(20) PRIMARY KEY,
      store_name VARCHAR(100),
      city       VARCHAR(100)
  );

  -- Dimension: Product
  CREATE TABLE IF NOT EXISTS dim_product (
      product_id   VARCHAR(20) PRIMARY KEY,
      product_name VARCHAR(100),
      category     VARCHAR(50)
  );

  -- Dimension: Customer
  CREATE TABLE IF NOT EXISTS dim_customer (
      customer_id   VARCHAR(20) PRIMARY KEY,
      customer_name VARCHAR(100)
  );
  EOT
}
