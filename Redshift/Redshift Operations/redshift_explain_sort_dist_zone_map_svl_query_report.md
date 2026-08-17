# Amazon Redshift: EXPLAIN, SORTKEY, DISTKEY, DISTSTYLE, Zone Maps & SVL_QUERY_REPORT

This note explains some of the most important Redshift performance concepts in simple language.

The easiest way to remember them is:

```text
DISTKEY  → WHERE does the row live?
SORTKEY  → HOW are rows organized?
ZONE MAP → Which blocks can Redshift skip?
EXPLAIN  → What does Redshift PLAN to do?
SVL_QUERY_REPORT → What did Redshift ACTUALLY do?
```

---

# 1. Big Picture: How Redshift Stores and Processes Data

Redshift is an **MPP (Massively Parallel Processing)** database.

A table is distributed across the compute resources, and each compute slice processes part of the data.

Conceptually:

```text
                    Redshift Cluster
                          |
             +------------+------------+
             |            |            |
           Slice 1      Slice 2      Slice 3
             |            |            |
          blocks        blocks        blocks
             |            |            |
          data          data          data
```

When a query runs, Redshift tries to process the data in parallel.

Three important questions are:

```text
1. Where should each row be stored?
       → DISTSTYLE / DISTKEY

2. How should rows be physically organized?
       → SORTKEY

3. Which blocks can be ignored during a query?
       → ZONE MAP
```

Then we use:

```text
EXPLAIN
→ Understand the planned execution

SVL_QUERY_REPORT
→ Understand the actual execution
```

---

# 2. What is EXPLAIN?

`EXPLAIN` shows the **execution plan** that Redshift intends to use.

It does not normally execute the query.

Example:

```sql
EXPLAIN
SELECT
    c.customer_id,
    SUM(o.amount)
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date >= '2026-01-01'
GROUP BY c.customer_id;
```

The output may contain operations such as:

```text
SCAN
  ↓
JOIN
  ↓
AGGREGATE
  ↓
SORT
  ↓
RESULT
```

The exact plan depends on the query and table design.

## Why use EXPLAIN?

Suppose a query is slow.

Instead of immediately changing WLM, DISTKEY or SORTKEY, first ask:

> What is Redshift planning to do?

EXPLAIN can help identify:

- Large table scans
- Joins
- Aggregations
- Sort operations
- Data redistribution
- Other expensive operations

### Simple memory trick

```text
EXPLAIN = What will Redshift do?
```

---

# 3. EXPLAIN vs Actual Execution

This distinction is very important.

```text
                  SQL Query
                      |
              +-------+-------+
              |               |
              v               v
           EXPLAIN         Execute
              |               |
              v               v
       Planned execution   Actual execution
                              |
                              v
                       SVL_QUERY_REPORT
```

So:

```text
EXPLAIN
→ Before execution
→ Planned behavior

SVL_QUERY_REPORT
→ After execution
→ Actual behavior
```

---

# 4. What is SVL_QUERY_REPORT?

`SVL_QUERY_REPORT` is a Redshift system view used to inspect how a completed query actually executed.

It is especially useful for checking:

- Query steps
- Segments
- Slices
- Rows processed
- Execution time
- Memory
- Data produced
- Slice imbalance / skew

Conceptually:

```text
Query
 |
 +-- Segment 0
 |     |
 |     +-- Step 0 → Scan
 |     +-- Step 1 → Project
 |     +-- Step 2 → Hash
 |
 +-- Segment 1
 |     |
 |     +-- Step 0 → Scan
 |     +-- Step 1 → Join
 |
 +-- Segment 2
       |
       +-- Step 0 → Aggregate
```

The exact steps depend on the query.

---

# 5. Segment, Step and Slice

These terms appear in `SVL_QUERY_REPORT`.

## Query

The overall SQL statement.

Example:

```text
query = 1677
```

## Segment

A group of execution steps that can be processed together.

## Step

An individual operation.

Examples:

```text
scan
project
hash
hjoin
aggr
return
```

## Slice

A unit of parallel processing inside the Redshift compute layer.

The slice information is very useful for finding imbalance.

---

# 6. Why Slice Information Is Important

Suppose there are four slices.

### Healthy distribution

```text
Slice 1 → 25 million rows
Slice 2 → 24 million rows
Slice 3 → 26 million rows
Slice 4 → 25 million rows
```

The work is reasonably balanced.

### Bad distribution

```text
Slice 1 → 90 million rows
Slice 2 → 10 million rows
Slice 3 → 10 million rows
Slice 4 → 10 million rows
```

Now Slice 1 has much more work.

This is **data distribution skew**.

The other slices may finish quickly, but the query cannot finish until the overloaded slice finishes.

```text
One slice overloaded
        ↓
More work on that slice
        ↓
Longer query
```

---

# 7. Important SVL_QUERY_REPORT Columns

The exact view contains many columns, but these are useful for troubleshooting.

## `label`

Shows what operation is being performed.

Examples:

```text
scan
project
hash
hjoin
aggr
return
```

---

## `rows`

Number of rows produced by that step.

Example:

```text
rows = 15,000,000
```

means that step produced approximately 15 million rows.

---

## `rows_pre_filter`

For permanent-table scans, this represents rows before filtering deleted/ghost rows and before applying user query filters.

Conceptually:

```text
Rows in table
     ↓
Remove deleted/ghost rows
     ↓
Apply query filter
     ↓
Rows
```

---

## `pct_filter`

Shows how much filtering occurred at that step.

If a table scan processes a huge number of rows but filters very little data, that can indicate that the query is reading much more data than necessary.

Example:

```text
150 million rows scanned
+
very little filtering
=
large amount of data processed
```

---

## `memory_mb`

Memory used by the execution step.

---

## `mb_produced`

Amount of data produced by the step.

---

# 8. What is a SORTKEY?

A sort key determines how Redshift organizes table data physically.

Example:

```sql
CREATE TABLE orders
(
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    amount DECIMAL(12,2)
)
SORTKEY(order_date);
```

The idea is that rows are organized around `order_date`.

Conceptually:

```text
Block 1 → Jan 1 - Jan 7
Block 2 → Jan 8 - Jan 14
Block 3 → Jan 15 - Jan 21
Block 4 → Jan 22 - Jan 31
```

Now consider:

```sql
SELECT *
FROM orders
WHERE order_date BETWEEN '2026-01-10' AND '2026-01-12';
```

Redshift can potentially avoid reading blocks that cannot contain those dates.

This is called **block pruning**.

---

# 9. What is a Zone Map?

This is one of the most important Redshift concepts.

Redshift stores data in blocks. For each block, Redshift maintains metadata about the values in that block, including minimum and maximum values.

Conceptually:

```text
Block 1
min = Jan 1
max = Jan 7

Block 2
min = Jan 8
max = Jan 14

Block 3
min = Jan 15
max = Jan 21

Block 4
min = Jan 22
max = Jan 31
```

This metadata is commonly called a **zone map**.

Now query:

```sql
WHERE order_date = 'Jan 10'
```

Redshift can reason:

```text
Block 1 → Jan 10 possible? NO
Block 2 → Jan 10 possible? YES
Block 3 → Jan 10 possible? NO
Block 4 → Jan 10 possible? NO
```

So it can potentially scan only Block 2.

---

# 10. SORTKEY and Zone Map Relationship

This relationship is extremely important:

```text
SORTKEY
   ↓
Organizes data
   ↓
Values become clustered in blocks
   ↓
Useful min/max information
   ↓
ZONE MAP
   ↓
Skip irrelevant blocks
   ↓
Less I/O
   ↓
Faster query
```

Therefore:

> A good sort key makes zone maps much more useful.

---

# 11. What Happens When Data Is Not Well Sorted?

Suppose a block contains random dates:

```text
Block 1 → Jan, Apr, Sep, Dec, Jan
Block 2 → Mar, Jan, Jul, Oct, Apr
Block 3 → Feb, Dec, Jan, Aug, Mar
```

Every block may have something like:

```text
min = Jan
max = Dec
```

Now if the query asks for January, every block looks like it could contain January.

So Redshift may need to scan many blocks.

```text
Poor sorting
    ↓
Zone maps less useful
    ↓
More blocks scanned
    ↓
More I/O
    ↓
Slower query
```

This is why table sorting matters.

---

# 12. Compound Sort Key

A compound sort key contains multiple columns in a defined order.

Example:

```sql
SORTKEY(region, order_date)
```

The first column is the **leading column**.

The ordering is conceptually:

```text
APAC
   Jan
   Feb
   Mar

EU
   Jan
   Feb
   Mar

US
   Jan
   Feb
   Mar
```

The first column (`region`) has the strongest importance.

---

# 13. Compound Sort Key and Prefix

Suppose:

```sql
SORTKEY(region, order_date, customer_id)
```

The prefix is:

```text
region
region + order_date
region + order_date + customer_id
```

Good query:

```sql
WHERE region = 'US'
```

Good query:

```sql
WHERE region = 'US'
  AND order_date >= '2026-01-01';
```

Also good when using all:

```sql
WHERE region = 'US'
  AND order_date >= '2026-01-01'
  AND customer_id = 100;
```

But if the query only uses:

```sql
WHERE order_date >= '2026-01-01'
```

the compound ordering is generally less useful because the leading column `region` was skipped.

### Memory trick

```text
Compound = First column matters most.
```

---

# 14. Interleaved Sort Key

Interleaved sorting is designed for workloads where different columns are independently important.

Example:

```sql
SORTKEY INTERLEAVED
(
    customer_id,
    order_date,
    region
);
```

Imagine:

```text
Query A → filters customer_id
Query B → filters order_date
Query C → filters region
```

There isn't one obvious leading column.

Interleaved sorting gives the sort-key columns more equal weight.

Conceptually:

```text
customer_id  ↘
               multidimensional organization
order_date   ↗

region also contributes
```

This can be useful when queries filter on different sort-key columns.

---

# 15. Compound vs Interleaved

| Compound | Interleaved |
|---|---|
| First column is most important | Columns have more equal importance |
| Good for predictable query patterns | Good for different filter patterns |
| Works well with leading-column predicates | Useful when different columns are independently filtered |
| Usually easier to maintain | More maintenance overhead |
| Good for regularly changing tables | Specialized use case |

Important:

> Do not use interleaved sorting everywhere.

Interleaved sorting can increase maintenance cost, including load and vacuum work.

For frequently changing tables, compound sorting is often a better choice.

---

# 16. DISTKEY

Now we move from sorting to **data distribution**.

A DISTKEY answers:

> **Which slice should store a particular row?**

Example:

```sql
DISTKEY(customer_id)
```

Conceptually:

```text
customer_id = 101
        ↓
      hash
        ↓
     Slice 2

customer_id = 102
        ↓
      hash
        ↓
     Slice 4
```

The exact hashing implementation is handled by Redshift. The important idea is that the distribution key determines where the row goes.

---

# 17. Why is DISTKEY Important?

The biggest reason is **JOIN performance**.

Suppose:

```text
orders
DISTKEY(customer_id)

customers
DISTKEY(customer_id)
```

And the query is:

```sql
SELECT *
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id;
```

Because both tables are distributed using the same key, matching rows can be colocated on the same slices.

That can reduce the amount of data Redshift needs to move across the cluster.

---

# 18. What Happens With a Bad DISTKEY?

Suppose:

```text
orders
DISTKEY(order_id)
```

but your major join is:

```sql
orders.customer_id = customers.customer_id
```

Matching rows may be on different slices.

Redshift may have to redistribute data:

```text
Slice 1              Slice 2
Orders                Customers
   |                      |
   +----------+-----------+
              |
              v
       NETWORK REDISTRIBUTION
              |
              v
             JOIN
```

Network data movement can be expensive.

So a good distribution strategy can reduce redistribution.

---

# 19. What is DISTSTYLE?

`DISTSTYLE` defines the overall strategy used to distribute a table.

Important styles:

```text
AUTO
EVEN
KEY
ALL
```

---

# 20. DISTSTYLE EVEN

Rows are distributed approximately evenly across slices.

Example:

```text
100 rows

Slice 1 → 25
Slice 2 → 25
Slice 3 → 25
Slice 4 → 25
```

This helps avoid data imbalance.

But it does not guarantee that matching join rows are colocated.

Use it when there is no useful distribution key or when even distribution is more important than join colocation.

---

# 21. DISTSTYLE KEY

Example:

```sql
DISTSTYLE KEY
DISTKEY(customer_id)
```

Rows are distributed according to the distribution key.

Good candidates often have:

- Frequent joins
- High enough cardinality
- Reasonably even value distribution
- Important joins where colocation can reduce redistribution

Bad candidate:

```text
A column where almost every row has the same value
```

because that can create skew.

---

# 22. DISTSTYLE ALL

Every compute node gets a full copy of the table.

Conceptually:

```text
Small dimension table
       |
       +----> Node 1
       |
       +----> Node 2
       |
       +----> Node 3
```

This can make joins easier because the table is available on every node.

Good candidate:

```text
Small dimension table
```

Bad candidate:

```text
Huge fact table
```

because storage and maintenance costs become much larger.

---

# 23. DISTSTYLE AUTO

Modern Redshift can automatically choose and adjust distribution behavior.

Conceptually:

```text
Small table
    ↓
AUTO
    ↓
Redshift chooses suitable distribution

Table grows / workload changes
    ↓
Redshift can adjust strategy
```

For many modern Redshift workloads, automatic table optimization is preferable to manually hard-coding distribution and sort choices unless there is a specific reason to control them.

---

# 24. DISTKEY vs SORTKEY

This is a common interview question.

| DISTKEY | SORTKEY |
|---|---|
| Controls where rows are distributed | Controls physical ordering |
| Works across slices/nodes | Organizes data within the table |
| Helps reduce data redistribution | Helps reduce blocks scanned |
| Important for joins | Important for filters/range scans |
| Goal: reduce network movement | Goal: reduce I/O |

### Simple memory trick

```text
DISTKEY → WHERE does the row live?

SORTKEY → HOW is the row organized?
```

---

# 25. Can the Same Column Be DISTKEY and SORTKEY?

Yes.

Example:

```sql
CREATE TABLE orders
(
    customer_id BIGINT DISTKEY SORTKEY,
    order_date DATE,
    amount DECIMAL(12,2)
);
```

Now `customer_id` affects both:

```text
Distribution
    ↓
Which slice?

Sorting
    ↓
How rows are organized?
```

But don't automatically use the same column for both.

Choose based on the actual workload.

---

# 26. How DISTKEY, SORTKEY and Zone Maps Work Together

Suppose:

```sql
CREATE TABLE orders
(
    order_id BIGINT,
    customer_id BIGINT,
    order_date DATE,
    amount DECIMAL(12,2)
)
DISTSTYLE KEY
DISTKEY(customer_id)
SORTKEY(order_date);
```

When data is inserted:

```text
Row
 |
 v
DISTKEY(customer_id)
 |
 v
Determine slice
 |
 v
Store data
 |
 v
SORTKEY(order_date)
 |
 v
Data organized into blocks
 |
 v
Zone-map min/max metadata
```

Now query:

```sql
SELECT *
FROM orders
WHERE customer_id = 101
  AND order_date BETWEEN '2026-01-01'
                     AND '2026-01-31';
```

Two optimizations may help:

```text
customer_id
    ↓
distribution
    ↓
less redistribution

order_date
    ↓
sort order
    ↓
zone maps
    ↓
skip irrelevant blocks
```

---

# 27. How VACUUM Connects to SORTKEY

This connects directly to the previous VACUUM topic.

Suppose:

```sql
SORTKEY(order_date)
```

Initially:

```text
Jan
Feb
Mar
Apr
```

Then data arrives out of order:

```text
Jan
Feb
Mar
Apr
Jan
Mar
Feb
```

The unsorted region increases.

That can reduce the effectiveness of the sort key and zone maps.

Then:

```text
VACUUM
   ↓
Re-sort data
   ↓
Better physical ordering
   ↓
Better block pruning
```

So:

```text
SORTKEY + VACUUM + ZONE MAP
```

are closely related.

---

# 28. How ANALYZE Connects to EXPLAIN

This connects to the previous ANALYZE topic too.

The optimizer needs statistics to estimate:

```text
How many rows will this filter return?
How large will a join be?
Which execution strategy is cheaper?
```

If statistics are stale:

```text
Bad statistics
      ↓
Bad estimates
      ↓
Potentially poor execution plan
```

`ANALYZE` updates statistics.

So:

```text
ANALYZE
   ↓
Better statistics
   ↓
Better optimizer estimates
   ↓
Potentially better EXPLAIN plan
```

---

# 29. Example: Troubleshooting a Slow Query

Suppose:

```sql
SELECT *
FROM orders
WHERE order_date >= '2026-01-01';
```

The query is taking too long.

Do not immediately increase the cluster size.

Use a systematic approach.

### Step 1 — EXPLAIN

```sql
EXPLAIN
SELECT *
FROM orders
WHERE order_date >= '2026-01-01';
```

Check the plan.

---

### Step 2 — Check actual execution

Use:

```sql
SELECT *
FROM SVL_QUERY_REPORT
WHERE query = <query_id>
ORDER BY segment, step, slice;
```

Look for:

- Large row counts
- Large elapsed time
- Slice imbalance
- Large intermediate results

---

### Step 3 — Check table design

Ask:

```text
Is order_date a useful SORTKEY?

Is the table heavily unsorted?

Is there a useful distribution strategy?
```

---

### Step 4 — Check zone-map effectiveness

If the table is poorly sorted:

```text
Many blocks
    ↓
Many blocks potentially contain the requested dates
    ↓
More scanning
```

---

### Step 5 — Check table maintenance

If the table has significant unsorted data:

```text
Consider VACUUM
```

If statistics are stale:

```text
Consider ANALYZE
```

---

# 30. Example: Detecting Distribution Skew

Suppose `SVL_QUERY_REPORT` shows:

```text
Slice 0 → 100 million rows
Slice 1 → 25 million rows
Slice 2 → 24 million rows
Slice 3 → 26 million rows
```

This is suspicious.

You should investigate:

```text
DISTKEY
DISTSTYLE
Data cardinality
Distribution of values
Join strategy
```

Do not solve it by simply increasing WLM slots.

The underlying problem is data distribution.

---

# 31. Example: Large Scan

Suppose you see:

```text
rows_pre_filter = 150 million
rows = 145 million
```

Only a small amount of data was filtered.

That means the query processed a huge amount of data.

Ask:

```text
Why is the filter not eliminating more data?

Is the filter on a useful sort-key column?

Is the data well sorted?

Can zone maps eliminate blocks?
```

This is where SORTKEY and zone maps become important.

---

# 32. Complete Troubleshooting Flow

For a slow Redshift query:

```text
                    Slow Query
                        |
                        v
                    EXPLAIN
                        |
                        v
             Understand the plan
                        |
                        v
               Run the query
                        |
                        v
              SVL_QUERY_REPORT
                        |
          +-------------+-------------+
          |                           |
          v                           v
     Slice imbalance              Huge scan
          |                           |
          v                           v
      DISTKEY /                  SORTKEY /
      DISTSTYLE                  Zone Map
          |                           |
          v                           v
       Skew?                    Many blocks?
                                      |
                                      v
                              Check table sorting
                                      |
                         +------------+------------+
                         |                         |
                         v                         v
                    Unsorted?                 Stats stale?
                         |                         |
                         v                         v
                      VACUUM                    ANALYZE
```

---

# 33. All Concepts Together

```text
                         REDSHIFT TABLE
                              |
                +-------------+-------------+
                |                           |
           DISTSTYLE                    SORTKEY
                |                           |
        Where should row             How should rows
           be stored?                  be ordered?
                |                           |
        +-------+-------+              +----+----+
        |       |       |              |         |
      EVEN     KEY     ALL          COMPOUND  INTERLEAVED
        |       |       |              |
        |       |       |              v
        |       |       |        Organized blocks
        |       |       |              |
        |       |       |              v
        |       |       |          ZONE MAP
        |       |       |              |
        |       |       |          min / max
        |       |       |              |
        |       |       |              v
        |       |       |        Skip blocks
        |       |       |
        +-------+-------+
                |
                v
         JOIN / AGGREGATION
                |
                v
       Less data redistribution


                    QUERY
                      |
                      v
                   EXPLAIN
                      |
                      v
                Planned execution
                      |
                      v
                Actual execution
                      |
                      v
             SVL_QUERY_REPORT
                      |
                      v
              Slice-level metrics
                      |
                      v
              Detect skew/problems
```

---

# 34. Interview-Ready Answer

> **EXPLAIN in Redshift shows the planned execution steps of a query without executing it. I use it to identify scans, joins, aggregations, sorts and data redistribution. After execution, I can use SVL_QUERY_REPORT to inspect actual execution at the slice level and identify issues such as uneven row processing and slice skew.**
>
> **DISTSTYLE controls how table rows are distributed across slices, while DISTKEY is the column used for KEY distribution. A good distribution strategy can colocate rows that are frequently joined and reduce network redistribution. SORTKEY controls the physical ordering of table data. Redshift maintains min/max metadata for data blocks, commonly called zone maps, so when data is well sorted the engine can skip blocks that cannot satisfy a filter.**
>
> **Compound sort keys prioritize the first column and work best when queries use the leading columns. Interleaved sort keys give multiple columns more equal importance and can help when different queries filter on different columns, but they have higher maintenance overhead.**

---

# 35. Final Memory Tricks

```text
DISTKEY
→ WHERE does the row live?

DISTSTYLE
→ HOW is the table distributed?

SORTKEY
→ HOW are rows physically organized?

COMPOUND
→ First column matters most.

INTERLEAVED
→ Multiple columns have more equal importance.

ZONE MAP
→ Which blocks can I skip?

EXPLAIN
→ What will Redshift do?

SVL_QUERY_REPORT
→ What did Redshift actually do?

VACUUM
→ Fix physical table organization.

ANALYZE
→ Refresh optimizer statistics.
```

## The Most Important Relationship

```text
DISTKEY
   ↓
Reduces data movement

SORTKEY
   ↓
Organizes data

ZONE MAP
   ↓
Skips irrelevant blocks

VACUUM
   ↓
Maintains sorting / physical organization

ANALYZE
   ↓
Maintains optimizer statistics

EXPLAIN
   ↓
Shows planned execution

SVL_QUERY_REPORT
   ↓
Shows actual slice-level execution
```

This gives you the complete Redshift performance picture:

```text
Bad DISTKEY
    ↓
Distribution skew
    ↓
One slice does more work


Bad / unsorted SORTKEY
    ↓
Weak zone-map pruning
    ↓
More blocks scanned
    ↓
More I/O


Large join + insufficient memory
    ↓
Spill to disk


Too many concurrent queries
    ↓
WLM queue wait
```
