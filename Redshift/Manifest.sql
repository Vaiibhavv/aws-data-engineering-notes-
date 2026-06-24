create table customer_manifest (

  C_CUSTKEY bigint NOT NULL,

  C_NAME varchar(25),

  C_ADDRESS varchar(40),

  C_NATIONKEY bigint,

  C_PHONE varchar(15),

  C_ACCTBAL decimal(18,4),

  C_MKTSEGMENT varchar(10),

  C_COMMENT varchar(117))

diststyle all;

COPY 
FROM 's3://redshift-learn-101/copycommandexamples/manifest1'
iam_role 'iam role'
FORMAT AS PARQUET
MANIFEST;


/* manifest json format,
 where we stored multiple files path in one json, by using it we can load the muliple 
 files at one go
*/ 
