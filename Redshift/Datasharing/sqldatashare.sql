select current_namespace;


-- Creating a datashare
CREATE DATASHARE dataspark_share SET PUBLICACCESSIBLE TRUE;

-- Adding schema to datashare
ALTER DATASHARE dataspark_share ADD SCHEMA public;

-- Adding lineitem tables to datshares.  We can add all the tables also if required
ALTER DATASHARE dataspark_share ADD TABLE public.lineitem;

show datashares;
select * from SVV_DATASHARE_OBJECTS;


-- Granting access to data spark soup namespace
Grant USAGE ON DATASHARE dataspark_share to NAMESPACE '{namespace}'
GRANT USAGE ON DATASHARE dataspark_share TO ACCOUNT '{accountid}';

-- Second tab
SELECT 'ALTER DATASHARE my_datashare ADD TABLE ' || table_schema || '.' || table_name || ';'
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';


  select * FROM information_schema.tables
