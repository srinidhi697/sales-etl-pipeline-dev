import pyarrow.parquet as pq
 
# Path to your Parquet file
file_path = r"c:\Users\srini\Downloads\part-00000-02ce87b2-9049-4e0e-b585-58bd34cf84ef-c000.snappy.parquet"

# Open the Parquet file
parquet_file = pq.ParquetFile(file_path)

# Print the schema
print("Schema of Parquet file:")
print(parquet_file.schema)

# Print a sample of the data
print("First 10 rows of data:")
print(parquet_file.read_row_group(0).to_pandas().head(10))
