# AWS Data Engineering Notes

Comprehensive notes on AWS services and concepts used in Data Engineering. These notes focus on understanding the architecture, working principles, use cases, and interactions between AWS services.

---

# Table of Contents

* IAM

  * Users
  * Groups
  * Policies
  * Roles
* Amazon S3

  * Buckets
  * Object Storage
  * Internal Architecture
  * Block Storage vs Object Storage
* AWS Glue

  * Components
  * Data Catalog
  * Crawlers
  * Glue Jobs
  * IAM Role for Glue
* Amazon EC2
* Amazon Athena
* External Tables vs Managed Tables
* Upcoming Topics

---

# IAM (Identity and Access Management)

IAM is the security service of AWS. It controls **who can access AWS resources** and **what actions they are allowed to perform**.

Without IAM, every AWS service would be publicly accessible.

IAM follows three principles:

1. Authentication (Who are you?)
2. Authorization (What can you do?)
3. Least Privilege (Give only necessary permissions)

---

## Users

An IAM user represents a person or application.

Examples:

* Admin
* Developer
* Data Engineer

Each user can have:

* Username
* Password
* Access Keys
* Permissions

Example:

Suppose Vaibhav logs into AWS.

AWS first authenticates him and then checks whether he has permission to perform the requested operation.

```
Vaibhav
     ↓
IAM User
     ↓
Policy
     ↓
Access Granted
```

---

## Groups

A group is a collection of users.

Instead of assigning permissions to every user separately, permissions are assigned to the group.

Example:

```
Data Engineers Group

Members:
--------
User1
User2
User3
```

Attach S3 permissions to the group, and every member automatically gets those permissions.

---

## Policies

Policies define permissions.

Policies are JSON documents.

Example:

```json
{
 "Effect":"Allow",
 "Action":"s3:GetObject",
 "Resource":"*"
}
```

Policy answers questions like:

* Can this user read S3?
* Can this user start EC2?
* Can this user create Glue jobs?

AWS evaluates all attached policies before allowing access.

---

## Roles

A role is a temporary identity assumed by AWS services.

Unlike users, roles don't have passwords.

Examples:

* Glue Role
* EC2 Role
* Lambda Role

Suppose a Glue Job wants to read files from S3.

```
Glue Job
     ↓
Assumes Glue Role
     ↓
Role contains S3 permissions
     ↓
Reads data from S3
```

Services never directly access resources.

They assume roles to obtain temporary credentials.

---

# Amazon S3

Amazon S3 (Simple Storage Service) is AWS's object storage system.

S3 is designed to store:

* CSV files
* JSON files
* Parquet files
* Images
* Videos
* Backups
* Logs

It provides:

* High durability
* Scalability
* Low cost

---

## Bucket

A bucket is a container that stores objects.

Example:

```
s3://company-data

sales/
employees/
customers/
```

Buckets are globally unique.

Inside buckets, objects are stored.

Example:

```
s3://company-data/sales/2026/data.parquet
```

---

# How S3 Stores Data Internally

When you upload a file:

```
customer.parquet
```

S3 creates an object consisting of:

```
Object
│
├── Data
├── Metadata
└── Object Key
```

Internally AWS distributes and replicates this object across multiple storage nodes.

Users never see disks or blocks.

S3 exposes only objects.

This architecture provides 11 nines durability.

---

# Block Storage vs Object Storage

## Block Storage

Used by EBS.

Data is divided into blocks.

```
Disk
│
├── Block 1
├── Block 2
└── Block 3
```

The operating system assembles blocks into files.

Used for:

* Databases
* EC2 root volumes
* Operating systems

---

## Object Storage

Used by S3.

Stores complete objects.

```
Object

Data
Metadata
Key
```

No filesystem is exposed.

Access happens through APIs.

Best suited for:

* Data Lakes
* Backups
* Analytics

---

# AWS Glue

AWS Glue is a serverless ETL and metadata management service.

Glue provides:

1. Data Catalog
2. Crawlers
3. ETL Jobs
4. Triggers
5. Workflows

Glue internally uses Apache Spark for processing.

---

## Data Catalog

Data Catalog stores metadata.

Metadata means information about data.

Example:

Actual file:

```
s3://sales/data.parquet
```

Metadata stored inside Data Catalog:

```
Database : sales_db

Table : sales

Columns

customer_id BIGINT
amount DOUBLE
country STRING
```

Data Catalog does NOT contain actual data.

Only schema information is stored.

Services using Data Catalog:

* Athena
* Glue
* EMR
* Redshift Spectrum

---

## Crawlers

Crawlers automatically discover schema.

Process:

```
S3 Bucket
     ↓
Crawler scans files
     ↓
Detects format
     ↓
Infers schema
     ↓
Creates table in Data Catalog
```

Supported formats:

* CSV
* JSON
* ORC
* Parquet
* Avro

Crawler removes the need for manually creating tables.

---

## Glue Job Permissions

Glue itself has no permissions.

AWS services obtain permissions through IAM Roles.

Example:

```
Glue Job
     ↓
Assume Role
     ↓
Temporary Credentials
     ↓
Access S3
```

Common permissions:

### S3

* GetObject
* PutObject
* ListBucket

### Glue

* CreateTable
* GetTable

### CloudWatch

* CreateLogGroup
* CreateLogStream

---

# Amazon EC2

EC2 stands for Elastic Compute Cloud.

EC2 is simply a virtual machine running inside AWS.

It provides:

* CPU
* Memory
* Disk
* Network

Use cases:

* Hosting applications
* Databases
* Spark clusters
* Airflow servers

Think of EC2 as renting a server instead of buying one.

---

# Amazon Athena

Athena is a serverless query engine.

It allows SQL queries directly on files stored in S3.

Internally Athena uses Trino (formerly Presto).

Example:

```sql
SELECT * FROM sales;
```

Execution flow:

```
User Query
     ↓
Athena
     ↓
Reads table metadata from Glue Data Catalog
     ↓
Gets S3 file location
     ↓
Reads Parquet files from S3
     ↓
Trino executes query
     ↓
Returns results
```

Athena stores no data.

Data remains in S3.

Data Catalog provides schema information.

---

# External Tables

An external table contains metadata only.

Actual files remain outside the table.

Example:

```
Metadata
Glue Catalog

Data
s3://sales/data.parquet
```

Dropping an external table removes metadata but keeps files.

---

# Managed Tables

Managed tables own both metadata and data.

Traditional Hive behavior:

```
Warehouse Directory

warehouse/sales/
```

When the table is dropped:

* Metadata deleted
* Files deleted

However, in modern formats like Iceberg and Delta Lake, files may be retained for safety and time travel.

---

# Upcoming Topics

* Lambda
* CloudWatch
* VPC
* EMR
* Redshift
* DynamoDB
* Kinesis
* Lake Formation
* Glue Workflows
* Glue Studio
* Partitioning
* Parquet vs ORC
* Iceberg
* Delta Lake
* Hudi
* Trino
* Data Warehousing
* Medallion Architecture
