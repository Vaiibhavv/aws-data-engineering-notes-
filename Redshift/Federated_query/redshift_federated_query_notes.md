# Amazon Redshift Federated Query

## 1. What is a Federated Query?

The clean mental model is:

> **Federated Query = Redshift querying a live operational database such as RDS/Aurora without first loading that data into Redshift.**

Suppose the architecture is:

```text
Operational system
        |
        v
   RDS PostgreSQL
   orders
   customers
   payments
        |
        v
   Redshift Serverless
       analytics
```

Normally, you might do:

```text
RDS
 ↓
ETL / DMS / Glue
 ↓
Redshift
 ↓
Analytics
```

That creates a copy of the operational data.

With Federated Query:

```text
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
```

Redshift connects to the remote database, gets its metadata, sends queries to it, retrieves the result rows, and can then continue processing those results on Redshift compute. Some computation can be pushed to the remote source.

---

## 2. Why do we need Federated Query?

The main reason is:

> **Operational data is already in RDS, and you do not always want to copy it into Redshift just to answer a query.**

Typical use cases:

### Near-real-time analytics

RDS contains current:

- orders
- inventory
- customer status
- payments

You want analytics against current operational data.

### Avoiding ETL for small or limited datasets

Copying data every hour just to answer a small report may be unnecessary.

### Joining operational and warehouse data

You can combine:

```text
RDS + Redshift
```

in one analytical query.

### Migration or augmentation scenarios

You can access operational data directly while gradually building a warehouse ingestion pipeline.

---

# 3. Simple Example

RDS has:

```text
orders
---------
order_id
customer_id
amount
```

Redshift has:

```text
customer_dim
------------
customer_id
customer_name
segment
```

You want customer names from Redshift and current order totals from RDS.

With Federated Query:

```sql
SELECT
    c.customer_name,
    SUM(o.amount) AS total_amount
FROM customer_dim c
JOIN rds_schema.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_name;
```

The `orders` table is not a normal Redshift internal table. It represents data in RDS.

---

# 4. Is Federated Query a tool?

No.

It is a **Redshift feature/capability**.

You do not:

```text
install Federated Query
download Federated Query
start a Federated Query service
```

Instead, you configure an **external schema** that points to the remote database.

---

# 5. What is an External Schema here?

An external schema acts as the bridge between Redshift and an external data source.

### Federated Query

```text
External Schema
      ↓
RDS PostgreSQL / MySQL
```

### Spectrum

```text
External Schema
      ↓
Glue / Athena / Hive Catalog
      ↓
S3 files
```

So the same Redshift concept, `EXTERNAL SCHEMA`, can connect Redshift to different types of external systems.

---

# 6. Federated Query vs Redshift Spectrum

They are **not the same feature**.

| | Federated Query | Redshift Spectrum |
|---|---|---|
| External source | RDS / Aurora | S3 |
| Data type | Operational DB tables | Data lake files |
| Typical formats | PostgreSQL/MySQL tables | Parquet, ORC, CSV, etc. |
| Metadata | Remote DB catalog/schema | Glue/Athena/Hive catalog or external table definition |
| Data physically stays | RDS | S3 |
| Redshift copies data first? | No | No |
| Main purpose | Query operational data | Query data lake |
| Typical use | Live operational + warehouse analytics | Lake + warehouse analytics |

### Why do both features exist?

Because RDS and S3 are fundamentally different.

RDS is a database and understands:

```text
tables
indexes
transactions
locks
schemas
database queries
```

S3 is object storage and contains:

```text
objects
files
Parquet
ORC
CSV
partitions
file statistics
```

Therefore:

```text
Federated Query
= remote database access

Spectrum
= remote data-lake access
```

---

# 7. How Federated Query Works

Suppose:

```sql
SELECT *
FROM rds_schema.orders
WHERE amount > 1000;
```

Conceptually:

```text
        Redshift Serverless
               |
        Parse / Optimize
               |
               v
       RDS PostgreSQL
               |
      Execute remote scan
               |
        WHERE amount > 1000
               |
               v
        matching rows
               |
               v
       Redshift compute
               |
        further joins/
        aggregations
               |
               v
             Result
```

Redshift does not necessarily retrieve the complete table and filter it all locally.

The engine can issue appropriate queries against the remote database, and some computation can be pushed down to the remote source.

---

# 8. RDS PostgreSQL → Redshift Serverless: Setup

Assume:

```text
Region: ap-south-1

RDS:
  PostgreSQL
  database = salesdb
  schema   = public
  table    = orders

Redshift:
  Serverless workgroup
```

---

## Step 1 — Configure Networking

Redshift Serverless must be able to reach the RDS endpoint.

A common architecture is:

```text
                VPC
 ┌─────────────────────────────────────┐
 │                                     │
 │   Redshift Serverless               │
 │          |                          │
 │          | TCP 5432                │
 │          v                          │
 │     RDS PostgreSQL                  │
 │                                     │
 └─────────────────────────────────────┘
```

Make sure:

- Redshift Serverless and RDS have network connectivity.
- Routing is configured correctly.
- DNS resolution works.
- The RDS endpoint is reachable from Redshift.

AWS recommends appropriate VPC connectivity and security-group configuration.

---

## Step 2 — Configure the RDS Security Group

For PostgreSQL:

```text
Port = 5432
```

Allow inbound traffic from the Redshift Serverless security group.

Conceptually:

```text
Protocol: TCP
Port: 5432
Source: Redshift Serverless security group
```

Do not open the database to the entire internet just to make the connection work.

Avoid:

```text
0.0.0.0/0
```

for production.

---

## Step 3 — Create a Read-Only RDS User

Create a dedicated user:

```sql
CREATE USER redshift_federated
WITH PASSWORD 'strong-password';
```

Grant only the required permissions:

```sql
GRANT CONNECT ON DATABASE salesdb
TO redshift_federated;

GRANT USAGE ON SCHEMA public
TO redshift_federated;

GRANT SELECT ON ALL TABLES IN SCHEMA public
TO redshift_federated;
```

For production, use a dedicated least-privilege account rather than an application/admin account.

---

## Step 4 — Store Credentials in AWS Secrets Manager

Do not hard-code the RDS password in Redshift configuration.

Create a Secrets Manager secret containing the RDS credentials.

Conceptually:

```text
Secrets Manager
----------------
username = redshift_federated
password = ********
engine   = postgres
host     = RDS endpoint
port     = 5432
```

The secret is referenced by ARN.

---

## Step 5 — Create an IAM Role

Redshift Serverless needs permission to read the secret.

Conceptually:

```text
Redshift Serverless
       |
       | Assume IAM role
       v
IAM Role
       |
       | secretsmanager:GetSecretValue
       v
Secrets Manager
```

A tightly scoped permission conceptually looks like:

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue"
  ],
  "Resource": "arn:aws:secretsmanager:ap-south-1:123456789012:secret:rds-creds-*"
}
```

In production, scope the ARN tightly and configure the trust relationship so the Redshift service can assume the role.

---

## Step 6 — Attach the IAM Role to Redshift Serverless

Associate the IAM role with the Redshift Serverless workgroup.

The role will be used to retrieve the credentials from Secrets Manager.

---

## Step 7 — Create the External Schema

This is the key SQL statement:

```sql
CREATE EXTERNAL SCHEMA rds_sales
FROM POSTGRES
DATABASE 'salesdb'
SCHEMA 'public'
URI 'mydb.xxxxx.ap-south-1.rds.amazonaws.com'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftFederatedRole'
SECRET_ARN 'arn:aws:secretsmanager:ap-south-1:123456789012:secret:rds-creds';
```

For MySQL, use `FROM MYSQL`.

The important parameters are:

```text
FROM POSTGRES
DATABASE
SCHEMA
URI
IAM_ROLE
SECRET_ARN
```

---

## Step 8 — Query the RDS Table

Suppose RDS has:

```text
public.orders
```

Then:

```sql
SELECT *
FROM rds_sales.orders;
```

The data is being read from RDS; it was not first loaded into a Redshift internal table.

---

## Step 9 — Join RDS Data with Redshift Data

Example:

```sql
SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.amount) AS total_amount
FROM customer_dim c
JOIN rds_sales.orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name;
```

Now:

```text
Redshift warehouse
       +
RDS operational data
       ↓
single analytical query
```

---

# 9. Important Networking Failure Scenario

You may successfully create the external schema but get a timeout when running:

```sql
SELECT *
FROM rds_sales.orders;
```

Investigate:

```text
1. RDS security group
2. Redshift Serverless VPC/subnet
3. Route tables
4. RDS endpoint/DNS
5. Port 5432
6. Network ACLs
7. VPC connectivity
8. Enhanced VPC routing where required
```

The SQL configuration can be correct while network connectivity is wrong.

---

# 10. What Happens When the Query Runs?

A simplified execution flow:

```text
                 SELECT ...
                     |
                     v
            Redshift Optimizer
                     |
             external table
                     |
                     v
              RDS PostgreSQL
                     |
              remote execution
                     |
               result rows
                     |
                     v
            Redshift compute
                     |
             joins / aggregations
                     |
                     v
                 Final Result
```

Some operations can be pushed to RDS, which can reduce the amount of data transferred to Redshift.

---

# 11. Major Use Cases

## Near-Real-Time Analytics

Example:

```text
RDS
orders
inventory
customer status
      ↓
Redshift Serverless
```

Useful when you need fresher operational data than a periodic ETL pipeline provides.

---

## Joining Operational and Warehouse Data

```text
RDS
  +
Redshift
  ↓
JOIN
```

For example:

- Customer master from Redshift
- Current orders from RDS

---

## Small or Limited Queries

If only a small amount of operational data is needed occasionally, copying it into Redshift may be unnecessary overhead.

---

## Migration / Transitional Architecture

While building a proper ingestion/CDC pipeline:

```text
RDS
 ↓
Federated Query
 ↓
Redshift analytics
```

can provide temporary direct access to operational data.

---

# 12. Limitations

## 1. RDS is still an OLTP Database

This is the biggest practical limitation.

Suppose RDS contains:

```text
500 million rows
```

and you run:

```sql
SELECT *
FROM rds_sales.orders;
```

That is a bad idea.

You are turning your operational database into an analytical scan engine.

Prefer:

```text
RDS
 ↓
CDC / DMS / ETL
 ↓
S3 / Redshift
 ↓
Analytics
```

for large, repeated analytics.

---

## 2. Remote Database Dependency

If RDS is unavailable:

```text
RDS unavailable
       ↓
Federated query fails
```

The Redshift query depends on the remote system.

---

## 3. Network Latency

You have:

```text
Redshift
   ↓
network
   ↓
RDS
```

This adds latency compared with data already inside Redshift.

---

## 4. Cross-Region Cost and Latency

Cross-Region access can introduce:

- network latency
- additional data-transfer costs

---

## 5. Read-Oriented Feature

Federated Query is designed for reading/querying external operational databases.

It is not a mechanism for using Redshift SQL as an arbitrary write interface into RDS.

---

## 6. Concurrency and OLTP Impact

If many analysts repeatedly issue expensive federated queries:

```text
100 analysts
   ↓
RDS
```

the operational database can become the bottleneck.

Monitor the RDS workload carefully.

---

# 13. Performance Comparison

## Federated Query

```text
RDS
 ↓
live query
 ↓
Redshift
```

### Advantages

- Fresh operational data
- No persistent copy
- No ETL delay
- Easy to combine with Redshift data

### Disadvantages

- Network latency
- RDS resource consumption
- Repeated queries repeatedly access RDS

---

## Load Data into Redshift

```text
RDS
 ↓
CDC / ETL
 ↓
Redshift
```

### Advantages

- Fast repeated analytics
- Redshift's warehouse optimizations
- Less pressure on RDS

### Disadvantages

- Data pipeline required
- Duplicate storage
- Replication delay
- More operational complexity

---

# 14. Spectrum vs Federated Query

### Spectrum

```text
Redshift
   |
   v
S3
   |
Parquet / ORC / CSV
```

Used for:

> **Querying data-lake data stored in S3.**

### Federated Query

```text
Redshift
   |
   v
RDS / Aurora
   |
Database tables
```

Used for:

> **Querying live operational database data.**

---

# 15. Can You Use Both?

Yes.

A Redshift environment can combine:

```text
                 Redshift
                    |
       ┌────────────┼────────────┐
       |            |            |
       v            v            v
   Redshift        RDS           S3
    tables        tables        files
       |            |            |
    internal     Federated     Spectrum
                  Query
```

A single analytical query can combine data from:

```text
Redshift + RDS + S3
```

For example:

```sql
SELECT
    c.customer_id,
    SUM(o.amount),
    COUNT(l.event_id)
FROM customer_dim c

JOIN rds_sales.orders o
    ON c.customer_id = o.customer_id

JOIN spectrum.web_logs l
    ON c.customer_id = l.customer_id

GROUP BY c.customer_id;
```

---

# 16. Why Don't AWS Make Spectrum and Federated Query One Feature?

Because the sources are fundamentally different.

```text
RDS
----
Database
Tables
Indexes
Transactions
Locks
SQL engine
```

versus:

```text
S3
----
Object storage
Files
Objects
Parquet
ORC
CSV
Partitions
File statistics
```

So:

```text
Federated Query
= remote database access

Spectrum
= remote data-lake access
```

They have different:

- metadata models
- query execution mechanisms
- authentication models
- pushdown behavior
- performance characteristics
- failure modes

---

# 17. When Should You Use Which?

| Requirement | Best Choice |
|---|---|
| Data already in Redshift | Internal Redshift table |
| Data in S3 Parquet/ORC | Spectrum |
| Data in RDS PostgreSQL/MySQL | Federated Query |
| Need current operational data | Federated Query |
| Huge historical lake data | Spectrum |
| Huge repeated analytics | Load into Redshift/S3 first |
| One-off/light operational lookup | Federated Query |
| Data lake exploration | Spectrum |
| High-performance BI | Redshift internal tables |

---

# 18. Interview Answer

> **Redshift Federated Query is a Redshift capability that allows Redshift, including Redshift Serverless, to query supported external operational databases such as Amazon RDS and Aurora PostgreSQL/MySQL without first copying the data into Redshift. Redshift creates an external schema pointing to the remote database, authenticates using an IAM role and Secrets Manager secret, and can push some computation to the remote source before bringing results back for further processing. It is useful for near-real-time analytics, joining operational data with warehouse data, and avoiding unnecessary ETL for limited workloads.**
>
> **Federated Query and Redshift Spectrum are not the same. Spectrum is designed primarily for querying data-lake data stored in S3, while Federated Query is designed for querying live operational databases such as RDS and Aurora. The reason both exist is that S3 and relational databases have fundamentally different storage, metadata, query, and execution characteristics.**

---

# 19. Core Mental Model

```text
Internal Redshift
-----------------
Data already in the warehouse

Federated Query
---------------
Redshift ↔ RDS/Aurora

Spectrum
--------
Redshift ↔ S3
```

The one line to remember:

```text
Federated Query → Redshift ↔ RDS/Aurora
Spectrum        → Redshift ↔ S3
```

---

## AWS Documentation

- Federated query overview: https://docs.aws.amazon.com/redshift/latest/dg/federated-overview.html
- Getting started with federated query: https://docs.aws.amazon.com/redshift/latest/gsg/federated-query.html
- CREATE EXTERNAL SCHEMA: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_EXTERNAL_SCHEMA.html
- Federated query limitations: https://docs.aws.amazon.com/redshift/latest/dg/federated-limitations.html
