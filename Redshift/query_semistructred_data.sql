drop table if exists transaction;
create table transaction (
    data_json super
    );


-- reference https://docs.aws.amazon.com/redshift/latest/dg/ingest-super.html
-- reference https://docs.aws.amazon.com/redshift/latest/dg/c_Supported_data_types.html
copy transaction
from 's3://YOUR BUCKET NAME/copycommandexamples/customer_order_lineitem.json'
iam_role 'YOUR IAM ROLE ASSOCIATED WITH CLUSTER'
json 'noshred';

select * from transaction limit 1;

select count(*) from transaction;

--select c_custkey, c_phone, c_acctbal from transaction;

select data_json.c_custkey, data_json.c_phone, data_json.c_acctbal from transaction;