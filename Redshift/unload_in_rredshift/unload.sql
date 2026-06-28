UNLOAD ('SELECT * FROM lineitem')
TO 's3://YOUR BUCKET NAME/unload/new/'
iam_role 'YOUR IAM ROLE ASSOCIATED WITH CLUSTER'
FORMAT AS PARQUET
MAXFILESIZE 100 MB;

-- for manifest file
UNLOAD ('SELECT * FROM lineitem')
TO 's3://YOUR BUCKET NAME/unload/manifest/'
iam_role 'YOUR IAM ROLE ASSOCIATED WITH CLUSTER'
FORMAT AS PARQUET
MAXFILESIZE 100 MB
MANIFEST;

-- with  compressed and kms keys file
UNLOAD ('SELECT * FROM customer_orders WHERE order_date >= DATE ''2023-01-01''')
TO 's3://my-company-data-exports/customer_orders/'
IAM_ROLE 'arn:aws:iam::your-account-id:role/my-redshift-role'
DELIMITER ',' ADDQUOTES HEADER
GZIP
MANIFEST
ENCRYPTED KMS_KEY_ID 'your-kms-key-id'
PARALLEL ON;