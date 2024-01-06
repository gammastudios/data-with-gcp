# Using dbt to manage external tables

## Overview
Use dbt to create external tables that access data in files stored in GCS object storage/buckets.

Data in the GCS bucket is organised using a 'hive' style partition layout, consisting of a path following the pattern
`<bucket>/<data-collection>/<source-data-set>/<partitions>/<data-files>`
With external tables, BigQuery is able to read all the data in the data files while being able to filter by
the partition keys.  Filtering is accomplished by treating the parition keys like virtual columns that can be
used in SQL `WHERE <virtual-partition-col> = <partition-value>`.

A common practice is to define externa tables to select all available fields in the data all presented as string 
values.  Subsequent processing is then used to convert to appropriate data types and perform data validation and
quality checking.

## Objective
Create an external table using `dbt` for `users` data stored underthe `thelook/full-refresh/users/...` directory.
While the data file in the GCS bucket reside in a common location accessible by multiple users/developers, the external
table will reside in private dataset/schema for external data.

### Partitions
With the `hive` style paritioned data files layout, there are one or more partition keys following a `key=value`
format.  For example, for data partitioned by date, the partition key layout might be
```
gs://<bucket>/thelook/full-refresh/users/p_year=2023/p_month=12/p_day=08/<data-files>.csv
```
Regardless of the `key` or `value` BigQuery treats both as simple strings and integers.

Note that some solutions with daily style partitioning will use a single key/value partition key, like 
```
gs://<bucket>/thelook/full-refresh/users/p_date=20231208/<data-files>.csv
```
However, this simple structure quickly becomes difficuly to manage as the number of values grows.  Within a year
there is a list of 365 items to navigate through.  The simple structure and can also make removing old data more
difficult as each day must be removed individually, as opposed to dropping everying under a month or year key.

### Source Data Format
Big Query supports multiple native data file formats, with csv being one of simplest and most frequently encountered.
A `csv` file may have headers naming each field, but little else in terms of metadata, such as data type.
Other formats such as parquet or avro provide more efficient formats for writing and access data, but are often
perceived as more complex to read and write.

The csv source files for this exercise include header rows describing the fields in each file.

### Meta-columns
Explore the meta-columns available with external tables.

## Creating the External Tables with dbt
### add dbt_external_tables package to project
Add in the [dbt-external-tables](https://github.com/dbt-labs/dbt-external-tables) package to the project.  Packages
added via the `<dbt-project-dir>/packages.yml` file and installed using `dbt deps`.  Pacakges are installed into
the project directory `<dbt-project-dir>/dbt_packages/`

### BQ dataset for external tables
Despite the `dbt-external-tables` package docs specifying that the target dataset for external tables must exist prior
to running the macro to create external tables, the the `dbt run-operation stage-external-sources` command will
create the target schema if it does not exist.

While `dbt` will create the schemas, good practice dictates creating the required datasets outside of the dbt model
to ensure schema configuration errors are identified early in the development and testing phases.  Creation of
datasets outside of the dbt project also supports a 'least priviledge' security model with the datasets security
policies being set independently of the dbt model code.

To manually create the target datasets, use a BQ SQL client and issue DDL directly.  For this exercise, as each person
has their own external staging tables, use the dbt schema/dataset prefix as set in the `dbt_profiles.yml` config file
when creating the dataset for the external tables to give a unique dataset for developer use.

In a BQ SQL client use [BQ SQL DDL statement](https://cloud.google.com/bigquery/docs/datasets#create-dataset) to create the new staging data set for the external tables.
```sql
create schema if not exists `<project-id>.<dbt-schema-prefix>_stg_thelook`
  options (
    location='australia-southeast1'
  )
```

### External source table definition
Add the definition for the external table as a model source, typically in a `sources.yml` file.

The sample sources file in `sample_bq_dbt_mart/models/sources/sources.yml` contains an example implementation.

The `sources:` configuration enables use of the developer specific dataset name while using the more generic
cross environment `stg_looker` in as the `{{ source('stg_looker',' 'users') }}` references in modeles.

Example BQ external table declaration:
```yaml
sources:
  - name: stg_thelook
    database: <project-id>
    schema: "{{ target.schema }}_stg_thelook"
    tables:
      - name: users
        description: "stacked daily full refresh from TheLook users data"
        external:
          location: "gs://{{ var('raw_bucket') }}/{{ var('raw_bucket_prefix') }}/full-refresh/users/*.csv"
          options:
            format: CSV
            skip_leading_rows: 1
            hive_partition_uri_prefix: "gs://{{ var('raw_bucket') }}/{{ var('raw_bucket_prefix') }}/full-refresh/users/"
        partitions:
          - name: p_year
            data_type: int
          - name: p_month
            data_type: int
          - name: p_day
            data_type: int
```

### Create the external table
Use the `dbt run-operation stage_external_sources` command to create the external tables in the staging
dataset.

Following a successful run, the new external table should be visible in the BQ console.  (may require 
a refresh)

Query the new external table to verify the new external table works as expected.  BigQuery good practice 
is to reduce the volume of data read by queries to control costs, but this example queries the full 
dataset as an example.

```sql
select
  p_year
  , p_month
  , p_day
  , count(*) as user_cnt
from `<schema-prefix>_stg_thelook.users`
group by 1,2,3
order by 1,2,3
```

Query by a single partition.
```sql
select
  p_year
  , p_month
  , p_day
  , count(*) as user_cnt
from `<schema-prefix>_stg_thelook.users`
where p_year=2023
  and p_month=12
  and p_day in (13, 14, 15)
group by 1,2,3
order by 1,2,3
```

When run from the BQ web console, the differences in the two queries can be seen in the "Job Information" panel.  Note that BigQuery will attempt to respond to a query using cached results from a previous 
execution where possible.  In that case, the "Job Information" may show 0 Bytes processed.