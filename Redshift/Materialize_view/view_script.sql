create table supplier (
  S_SUPPKEY bigint NOT NULL,
  S_NAME varchar(25),
  S_ADDRESS varchar(40),
  S_NATIONKEY bigint,
  S_PHONE varchar(15),
  S_ACCTBAL decimal(18,4),
  S_COMMENT varchar(101))
diststyle all;

copy supplier from 's3://YOUR BUCKET NAME/elt/materializedview/supplier.json'
iam_role 'YOUR IAM ROLE ASSOCIATED WITH CLUSTER'
manifest
lzop delimiter '|' COMPUPDATE PRESET;

explain
select n_name, s_name, l_shipmode,
  SUM(L_QUANTITY) Total_Qty
from lineitem
join supplier on l_suppkey = s_suppkey
join nation on s_nationkey = n_nationkey
--where datepart(year, L_SHIPDATE) > 1997
group by 1,2,3
order by 3 desc


/* creae the materialzie ( view, the materialize view in redshit is used for performence
 optimization 
it is auto refresh property in redshift. in other database system like oracle and 
postreg the materilize view are not autom refresh */


CREATE MATERIALIZED VIEW supplier_shipmode_agg
AUTO REFRESH YES AS
select l_suppkey, l_shipmode, datepart(year, L_SHIPDATE) l_shipyear,
  SUM(L_QUANTITY)   TOTAL_QTY,
  SUM(L_DISCOUNT) TOTAL_DISCOUNT,
  SUM(L_TAX) TOTAL_TAX,
  SUM(L_EXTENDEDPRICE) TOTAL_EXTENDEDPRICE
from LINEITEM
group by 1,2,3;


select n_name, s_name, l_shipmode,
  SUM(TOTAL_QTY) Total_Qty
from supplier_shipmode_agg
join supplier on l_suppkey = s_suppkey
join nation on s_nationkey = n_nationkey
where l_shipyear > 1997
group by 1,2,3
order by 3 desc
limit 1000;

explain
select n_name, s_name, l_shipmode, SUM(L_QUANTITY) Total_Qty
from lineitem
join supplier on l_suppkey = s_suppkey
join nation on s_nationkey = n_nationkey
where datepart(year, L_SHIPDATE) > 1997
group by 1,2,3
order by 3 desc
limit 1000;


-- directly query on materialize view 
select SUM(TOTAL_QTY) Total_Qty from supplier_shipmode_agg;
--637601817

delete from lineitem
where datepart(year, L_SHIPDATE) = 1993

-- 
REFRESH MATERIALIZED VIEW supplier_shipmode_agg

select SUM(TOTAL_QTY) Total_Qty from supplier_shipmode_agg;
--460120415