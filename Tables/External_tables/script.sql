CREATE TABLE IF NOT EXISTS expensive
  WITH ( format='parquet', external_location='s3://vp-bucket-pract/destination_for_external_table/') AS
SELECT
  *
FROM
  orders
WHERE
  item='Monitor';