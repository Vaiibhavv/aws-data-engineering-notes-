# What is AWS Glue -
- Aws Glue is serverless data integration service and integrate data from different different sources, once the data ready you can use it for - Analytic, Dashboarding, Machine learning and application development.

- Supported engines- Python, Spark, Ray
- Monitoring - Cloudformation metrics, job run insight, cloud trail

* Aws Glue Component 
1. Data Catalog - we can considere it is a central repository , seats between the source data and final data to pe prepared,

![alt text](image.png)
 
- A data catalog simplifies how you manage and access the data.

![alt text](image-1.png)

- Data catalog store the metadata, it does not stores the actual data, 
- eg.
    Database: sales
    Table: orders

    Columns:
    order_id bigint
    customer_id bigint
    amount double

    Location:
    s3://sales/orders/

![alt text](image-2.png)

2. AWS Glue Crawler- 
- AWS Glue Crawler is an automated schema discovery service that scans data sources and infers metadata such as table names, columns, and partitions.
- In short it is the process to scan the source data and preparing the metadata, 

- Note- A crawler populates and updates the Data Catalog, but metadata can also be created manually without using a crawler.

- Crawler has two types 
- a) Custome Classifiers b) Built in classifiers.

- Workflow of Glue Crawler 
![alt text](image-3.png)

![alt text](image-4.png)

* Note - if you don't specify the database, the crawler will stored the metadata in default databases.

## Data discvoery in Glue 
![alt text](image-5.png)

- What are native services and what does mean? 
AWS Native generally refers to cloud-native applications that are specifically designed, built, and optimized to run on Amazon Web Services (AWS) infrastructure. These applications leverage AWS-managed services, serverless computing, container orchestration, and DevOps practices to deliver scalable, resilient, and cost-efficient solutions.

At their core, AWS native applications follow cloud-native principles — microservices architecture, containerization, immutable infrastructure, and automated CI/CD pipelines — but are tightly integrated with AWS offerings like AWS Lambda, Amazon ECS/EKS, Amazon DynamoDB, and AWS API Gateway.4

### Aws Glue Built in Classifiers
![alt text](image-6.png)

## What is Data Partitioning ? 
Data partitioning is a technique that divides large datasets into smaller, more manageable segments called partitions. In the context of AWS Glue Zero-ETL integrations, partitioning organizes your data in the target location based on specific column values or transformations of those values.
![alt text](image-7.png)

![alt text](image-8.png)
![alt text](image-9.png)

#### What is Table partitioned Index 
A partitioned index is an index created on a partitioned table. Instead of maintaining one large index for the entire table, the index can also be partitioned. In a local partitioned index, each table partition has its own corresponding index partition, which improves performance for queries that filter on the partition key and simplifies maintenance. A global partitioned index spans all table partitions and is useful for queries that don't filter on the partition key, but it is generally more expensive to maintain.

| Concept                | Purpose                                                   |
| ---------------------- | --------------------------------------------------------- |
| **Table Partitioning** | Divides a large table into smaller physical partitions.   |
| **Partitioned Index**  | Divides the index to match or work with those partitions. |


| Local Partitioned Index               | Global Partitioned Index             |
| ------------------------------------- | ------------------------------------ |
| One index per partition               | One index for all partitions         |
| Easier maintenance                    | Harder maintenance                   |
| Faster for partition-based queries    | Better for queries across partitions |
| Automatically aligned with partitions | Independent of partitions            |

- Benefits of Partition Indexes:

Faster Query Execution: By quickly locating the relevant partitions, query execution time is reduced.

Efficient Data Management: Makes it easier to manage and update partitions in heavily partitioned  datasets.

Improved Performance: Reduces the overhead of managing large numbers of partitions, particularly beneficial in data lakes with numerous partitions.

** If the number of partitions in your database table is greater than 100, you can start considering "partition indexes".

### What is Column Statistics ?
Column statistics are metadata about the values stored in each column. Query engines use them to optimize query execution. 

- *Note- It does not store the actual values of the columns, it only stored the statitistics of the column, to summarize the columns data. 

- Benifits:
These statistics are stored in the Glue Data Catalog and are used by query engines like Athena, Redshift data warehouse and Spark to estimate data distribution, optimize joins, improve filter and aggregation planning, reduce unnecessary scans, and generate more efficient execution plans. The statistics describe the data—they do not contain the data itself.

![alt text](image-11.png)

- Types of Column Statistics

![alt text](image-10.png)

- How to Generate Column Statistics 

![alt text](image-12.png)

- Also need to add IAM Role with below managed and custom policies, 

![alt text](image-13.png)