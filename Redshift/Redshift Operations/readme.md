## 1. What is WLM ? (WLM = Workload Management.)

- Its job is to manage how Redshift allocates resources to queries.

* Eg. Suppose 20 queries, arrives almost the same time 

```
Q1
Q2
Q3
Q4
...
Q20
 |
 v
Redshift WLM
 |
 +--> Which queue?
 +--> Which query gets resources?
 +--> How many run concurrently?
 +--> Which queries get higher priority?

```
--- 

- Without workload management, a few resource-heavy queries could consume most of the cluster's resources and make other workloads wait.

- AWS recommends automatic WLM for normal provisioned-cluster workloads, and Redshift Serverless uses automatic WLM. Provisioned clusters can also use manual WLM when fine-grained control is required.

## 2. WLM Queue

- A WLM queue is basically a resource-management lane for a particular workload.

![alt text](image.png)

- The purpose is workload isolation.

`A huge ETL query shouldn't necessarily prevent a small dashboard query from getting resources.`

- AWS describes queues as runtime service classes used to control workload concurrency and resource allocation.

## 3. What are WLM Slots?

![alt text](image-1.png)

## 4. Why "More slots ≠ better performance"

![alt text](image-2.png)

![alt text](image-3.png)

` This can cause`
```
More concurrency
      |
      v
Less memory/query
      |
      v
Hash tables don't fit
      |
      v
Spill to disk
      |
      v
Slower queries

```
---
* AWS specifically notes that higher concurrency means less memory per slot and that excessive concurrency can create resource contention.

## 5. What is WLM Queue wait

- In query (panel) the number of queries runs = no.of slots, Suppose the queue panel only have 4 slots concurrancy panel and currently the 4 slots are allocated with 4 queries, and same time if the new query arrives it will be in waiting until one of the slots gets free.


## 6. Automic WLS vs Manual WLM 

![alt text](image-4.png)

![alt text](image-5.png)

## 7. What is Skew ? 

- Data or processing is distributed unevenly across Redshift slices.

* Remember Redshift is an MPP system.

          Redshift
             |
     +-------+-------+
     |       |       |
   Slice1  Slice2  Slice3
     |       |       |
  100GB     10GB     10GB

This is bad distribution.

- `Slice 1 has much more work.`

## Why Skew Problem happens?

![alt text](image-6.png)

## What si Spill 

![alt text](image-7.png)

```
Query
  |
  v
Working memory
  |
  +---- available: 4 GB
  |
  +---- required: 10 GB
               |
               v
        remaining data
               |
               v
             Disk

```
- AWS describes query_temp_blocks_to_disk as temporary disk usage for intermediate results when the query needs more memory than available.

# A short Notes
```Skew  = "One worker has too much work"

Spill = "The worker doesn't have enough memory"

Queue = "There isn't a free execution slot"
```
---
## Query Monitoring Tools

![alt text](image-8.png)

## Graph 
```
                 QUERY
                   |
                   v
                  WLM
                   |
             Which queue?
                   |
                   v
                 QUEUE
                   |
             How many SLOTS?
                   |
                   v
             Query executes
                   |
       +-----------+-----------+
       |                       |
       v                       v
   DATA DISTRIBUTION        MEMORY
       |                       |
       v                       v
     SKEW                    SPILL
       |                       |
       v                       v
 One slice overloaded      Disk I/O
```
## What is Vaccum ? 

![alt text](image-9.png)

![alt text](image-10.png)

* B. Re-sort

- After inserts/updates create an unsorted region, VACUUM can sort the rows according to the table's sort key.

## What is Analyze ?

- ANALYZE is about statistics.

* Simple definition:

`ANALYZE collects/updates statistics that the Redshift query optimizer uses to choose an execution plan.`

- AWS explicitly defines ANALYZE as updating table statistics for the query planner.

![alt text](image-11.png)


| VACUUM                               | ANALYZE                               |
| ------------------------------------ | ------------------------------------- |
| Works on physical table organization | Works on table statistics             |
| Reclaims deleted space               | Updates optimizer statistics          |
| Re-sorts rows                        | Helps optimizer estimate row counts   |
| Deals with unsorted/deleted data     | Deals with stale/missing statistics   |
| Mainly physical maintenance          | Mainly optimizer/planning maintenance |


### Redshift Automatic Analyze

![alt text](image-12.png)

### Automatic Vaccum 

![alt text](image-13.png)

### Vaccum types

![alt text](image-14.png)

![alt text](image-15.png)

![alt text](image-16.png)

![alt text](image-17.png)

### How to check whether the maintainence is required or not ?

```SELECT
    "table",
    size,
    unsorted,
    stats_off
FROM SVV_TABLE_INFO
WHERE "schema" = 'public'
ORDER BY size DESC;
```
--- 
```SVV_TABLE_INFO
      |
      +--> size
      +--> unsorted
      +--> stats_off
      +--> table informa
      
```

---

* Redshift provides `SVV_TABLE_INFO` for table-level metadata, and `SVV_VACUUM_PROGRESS / SVV_VACUUM_SUMMARY` for vacuum-related information.

## Complete Operational Flow 

```
               DATA LOAD / DML
                     |
          +----------+----------+
          |                     |
          v                     v
     Physical changes      Statistics changes
          |                     |
          v                     v
      UNSORTED /             STALE STATS
      DELETED ROWS               |
          |                      |
          v                      v
       VACUUM                  ANALYZE
          |                      |
          v                      v
    Better physical        Better query
      organization           planning
          |                      |
          +----------+-----------+
                     |
                     v
              Better performance
```
---

## Quick Summary

| Problem                         | Tool                         |
| ------------------------------- | ---------------------------- |
| Deleted rows taking space       | **VACUUM**                   |
| Unsorted rows                   | **VACUUM**                   |
| Need to re-sort table           | **VACUUM**                   |
| Statistics outdated             | **ANALYZE**                  |
| Optimizer making poor estimates | **ANALYZE**                  |
| Query waiting for resources     | **WLM**                      |
| Uneven data across slices       | **Distribution/sort design** |

* `VACUUM` fixes the table; `ANALYZE` fixes what the optimizer knows about the table; 
`WLM` controls how queries get compute.