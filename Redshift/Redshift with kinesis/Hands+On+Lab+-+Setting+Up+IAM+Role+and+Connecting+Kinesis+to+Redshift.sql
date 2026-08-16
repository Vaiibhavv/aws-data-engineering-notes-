CREATE TABLE ev_station
  (
     siteid                INTEGER,
     station_name          VARCHAR(100),
     address_1             VARCHAR(100),
     address_2             VARCHAR(100),
     city                  VARCHAR(100),
     state                 VARCHAR(100),
     postal_code           VARCHAR(100),
     no_of_ports           SMALLINT,
     pricing_policy        VARCHAR(100),
     usage_access          VARCHAR(100),
     category              VARCHAR(100),
     subcategory           VARCHAR(100),
     port_1_connector_type VARCHAR(100),
     voltage               VARCHAR(100),
     port_2_connector_type VARCHAR(100),
     pricing               VARCHAR(100),
     power_select          VARCHAR(100)
  )
distkey (siteid)
sortkey (siteid) ;

COPY ev_station
FROM 's3://datasparksoup-redshift-masterclass/streaming/Charging-Station-Network.csv'
IAM_ROLE 'arn:aws:iam::850995579146:role/service-role/AmazonRedshift-CommandsAccessRole-20241021T120634'
CSV
IGNOREHEADER 1
COMPUPDATE PRESET;


select count(*) from ev_station
--699
select * from ev_station limit 10

--Creating Kinesis schema
  CREATE EXTERNAL SCHEMA evdata FROM KINESIS
  IAM_ROLE ['Serverless IAM Role'];

--Creating Materialized View
CREATE MATERIALIZED VIEW ev_station_data_extract DISTKEY(6) sortkey(1) AUTO REFRESH YES AS
    SELECT
    refresh_time,
    approximate_arrival_timestamp,
    partition_key,
    shard_id,
    sequence_number,
    json_extract_path_text(from_varbyte(kinesis_data, 'utf-8'),'stationID',true)::DECIMAL(10,2) as stationID,
    json_parse(kinesis_data) as payload
    FROM evdata."ev_stream_data"
    WHERE CAN_JSON_PARSE(kinesis_data);

-- Enabling case sensitive identifier
 SET enable_case_sensitive_identifier to TRUE;

--Checking the payload
SELECT payload
from ev_station_data_extract
extract limit 10

SELECT count(*)
from ev_station_data_extract

SELECT date_trunc('minute', payload."connectionTime"::timestamp) as connectiontime
,SUM(payload."kWhDelivered"::DECIMAL(10,2)) AS Energy_Consumed
,count(distinct payload."userID") AS #Users
from ev_station_data_extract
where refresh_time > current_timestamp -interval '5 minutes'
group by 1
order by 1 desc;



SELECT date_trunc('minute', payload."connectionTime"::timestamp) as connectiontime
,SUM(payload."kWhDelivered"::DECIMAL(10,2)) AS Energy_Consumed
,count(distinct payload."userID") AS #Users
,category
from ev_station_data_extract , ev_station
where
stationID=siteid
and refresh_time > current_timestamp -interval '5 minutes'
group by payload."connectionTime"::timestamp, category
order by 1 desc;

