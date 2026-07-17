# What is AWS Glue -
- Aws Glue si serverless data integration service and integrate data from different different sources, once the data ready you can use it for - Analytic, Dashboarding, Machine learning and application development.

- Supported engines- Python, Spark, Ray
- Monitoring - Cloudformation metrics, job run insight, cloud trail

* Aws Glue Component 
1. Data Catalog - we can considere it is a cetral repository , seats between the source data and final data to pe prepared,

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
- In short it it is the process to scan the source data and preparing the the metadata, 

- Note- A crawler populates and updates the Data Catalog, but metadata can also be created manually without using a crawler.

- Crawler has two types 
- a) Custome Classifiers b) Built in classifiers.

- Workflow of Glue Crawler 
![alt text](image-3.png)

![alt text](image-4.png)

* Note - if you don't specify the database, the crawler will stored the metada in default databases.