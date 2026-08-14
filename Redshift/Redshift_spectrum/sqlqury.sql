/*
Creating external schema and query the external TABLE
*/

CREATE external SCHEMA external101
FROM data catalog DATABASE 'database101'
IAM_ROLE 'arn:aws:iam::850995579146:role/service-role/AmazonRedshift-CommandsAccessRole-20241021T120634'


SELECT TO_CHAR(pickup_datetime, 'YYYY-MM-DD'),COUNT(*)
FROM external101.ny_pub
WHERE YEAR = 2016 and Month = 01
GROUP BY 1
ORDER BY 2;

select count(*) from external101.ny_pub

show external table external101.ny_pub

/*
Creating new Redshift schema and loading the data from External table as CTAS
*/

CREATE SCHEMA internal101;

CREATE TABLE internal101.taxi_201601 AS
SELECT *
FROM external101.ny_pub
WHERE year = 2016 AND month = 1 AND type = 'green';

select * from internal101.taxi_201601

show table internal101.taxi_201601

ANALYZE COMPRESSION internal101.taxi_201601;

INSERT INTO internal101.taxi_201601 (
SELECT *
FROM external101.ny_pub
WHERE year = 2016 AND month = 1 AND type != 'green');

select count(*) from internal101.taxi_201601



-- -----------------------------------------------------------------


select * from stage_lineitem where l_suppkey = 790001
select * from supplier where s_suppkey = 790001
select * from lineitem where l_suppkey = 790001

select s.* from lineitem l
 inner join supplier s
on l.l_suppkey = s.s_suppkey
where l_suppkey = 790001

select current_namespace;


show datashares;

-- We will be creating database from console
--CREATE DATABASE datashare_db FROM DATASHARE dataspark_share OF ACCOUNT '850995579146';

SELECT * FROM SVV_DATASHARES;

SELECT * FROM SVV_DATASHARES WHERE share_name = 'dataspark_share';


select * from datashare_db.public.lineitem limit 10