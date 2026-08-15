
## What is Federated Query ( Amazon RDS TO Amazon Redshift)

* Federated Query = Redshift querying a live operational database such as RDS/Aurora without first loading that data into Redshift.

`Redshift Spectrum = Redshift querying files/data in S3 without first loading them into Redshift.`

                 Redshift Serverless
                       |
                    SQL query
                       |
                       v
                 RDS PostgreSQL
                       |
                live rows returned
                       |
                       v
                Redshift processing

* Example

CREATE EXTERNAL SCHEMA rds_schema
FROM POSTGRES
DATABASE 'sales_db'
SCHEMA 'public'
URI 'my-rds.xxxxxxxxx.ap-south-1.rds.amazonaws.com'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftFederatedRole'
SECRET_ARN 'arn:aws:secretsmanager:ap-south-1:123456789012:secret:rds-creds';

- what is inbound and otbount rule (for security group) with RDS and redshift

- The IAM role should be specify the secret manager policy ( I am attaching the json here(inline_policy.json))

- Also Provide the same vpc group which is associated with the  Redshift server.