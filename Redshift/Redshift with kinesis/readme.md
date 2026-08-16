
# Kinesis Data Stream with Amazon Redshift

Kinesis Data Streams is the streaming source. Redshift is the analytics destination. Redshift can ingest records directly from Kinesis into a Redshift materialized view, without first landing the data in S3.

## Architecture
                 Applications
                      |
                      | Events
                      v
          +--------------------------+
          | Kinesis Data Stream      |
          |--------------------------|
          | Shard 1                  |
          | Shard 2                  |
          | Shard 3                  |
          +------------+-------------+
                       |
                       | Streaming ingestion
                       v
          +--------------------------+
          | Redshift Serverless      |
          | / Provisioned Cluster    |
          |                          |
          | External Schema          |
          |       ↓                  |
          | Streaming Materialized   |
          | View                     |
          +------------+-------------+
                       |
                       v
                SQL Analytics ```
----



## What is kinesis Data Generator and CloudFormation?

 ```                INFRASTRUCTURE
                      |
                CloudFormation
                      |
          creates/configures resources
                      |
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
    Kinesis          IAM         Redshift
        |
        |
        v
      DATA
        |
       KDG
        |
   generates fake
      records
        |
        v
     Kinesis
        |
        v
     Redshift
        |
   Streaming MV
        |
        v
    Analytics 

```

```
CloudFormation
    ↓
Creates AWS infrastructure

Kinesis Data Generator
    ↓
Generates fake/test events
    ↓
Kinesis Data Stream
    ↓
Redshift
```
---

### CloudFormation

Problem - 
```
Kinesis Stream
IAM Role
IAM Policy
VPC
Security Group
Redshift
Lambda
S3 Bucket
```
- You have to create the above things manually on aws console, to solve this problem all this configuration is available in cloudformation `template` called as `stack`.

- CloudFormation lets you describe the infrastructure in a YAML or JSON template and AWS creates the resources for you as a stack. AWS describes a stack as a collection of resources managed as a single unit.

* eg. 
```
Resources:

  MyStream:
    Type: AWS::Kinesis::Stream

  MyBucket:
    Type: AWS::S3::Bucket

  MyRole:
    Type: AWS::IAM::Role
```

- With cloudformation the IAC (Infr code will be same on all other envs.)
```
                  template.yaml
                       |
             ┌─────────┼─────────┐
             ↓         ↓         ↓
            DEV       TEST      PROD
```

--- 


