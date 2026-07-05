select count(*) from lineitem;

-- create the merge upsert using stored procecure for sequential exectuion . 

create table stage_lineitem (
  L_ORDERKEY bigint NOT NULL,
  L_PARTKEY bigint,
  L_SUPPKEY bigint,
  L_LINENUMBER integer NOT NULL,
  L_QUANTITY decimal(18,4),
  L_EXTENDEDPRICE decimal(18,4),
  L_DISCOUNT decimal(18,4),
  L_TAX decimal(18,4),
  L_RETURNFLAG varchar(1),
  L_LINESTATUS varchar(1),
  L_SHIPDATE date,
  L_COMMITDATE date,
  L_RECEIPTDATE date,
  L_SHIPINSTRUCT varchar(25),
  L_SHIPMODE varchar(10),
  L_COMMENT varchar(44));


CREATE OR REPLACE PROCEDURE lineitem_incremental()
AS $$
BEGIN

truncate stage_lineitem;

copy stage_lineitem from 's3://datasparksoup-redshift-masterclass/elt/merge/lineitem.tbl.025.lzo'
iam_role 'arn:aws:iam::850995579146:role/service-role/AmazonRedshift-CommandsAccessRole-20241021T120634'
lzop delimiter '|' COMPUPDATE PRESET;

copy stage_lineitem from 's3://datasparksoup-redshift-masterclass/elt/merge/lineitem.tbl.026.lzo'
iam_role 'arn:aws:iam::850995579146:role/service-role/AmazonRedshift-CommandsAccessRole-20241021T120634'
lzop delimiter '|' COMPUPDATE PRESET;

copy stage_lineitem from 's3://datasparksoup-redshift-masterclass/elt/merge/lineitem.tbl.027.lzo'
iam_role 'arn:aws:iam::850995579146:role/service-role/AmazonRedshift-CommandsAccessRole-20241021T120634'
lzop delimiter '|' COMPUPDATE PRESET;

-- merge into lineitem
-- using stage_lineitem
-- on stage_lineitem.l_orderkey = lineitem.l_orderkey
-- and stage_lineitem.l_linenumber = lineitem.l_linenumber
-- remove duplicates
-- ;

END;
$$ LANGUAGE plpgsql;


call lineitem_incremental();
