
-- create a table for loading the data 
CREATE TABLE nation (
    N_NATIONKEY BIGINT NOT NULL,
    N_NAME      VARCHAR(25),
    N_REGIONKEY BIGINT,
    N_COMMENT   VARCHAR(152)
)
DISTSTYLE ALL;  -- distribution type while slicing 

--no rows 
select * from nation;

-- 

-- use this resource link for more details- https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html#r_COPY-permissions
--eg.1
copy nation 
from 's3/location/path'
iam_role 'iam/rol/path'
csv
IGNOREHEADER 1

-- query transaction detail, store every query details
select * from sys_load_error_detail;