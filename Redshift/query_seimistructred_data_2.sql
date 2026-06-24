
-- the issue isn super data type is, we have to use the nested querying attribute to query the data
select data_json.c_custkey, data_json.c_phone::varchar, data_json.c_acctbal from transaction;

select count(*) from transaction t, t.data_json.c_orders o;

select count(*) from transaction t, t.data_json.c_orders o, o.o_lineitems l;

select data_json.c_custkey::int, data_json.c_phone::varchar, data_json.c_acctbal::decimal(18,2),
       o.o_orderstatus::varchar, l.l_shipmode::varchar, l.l_extendedprice::decimal(18,2)
       from transaction t, t.data_json.c_orders o, o.o_lineitems l;