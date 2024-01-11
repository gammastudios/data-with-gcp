# Using dbt to create working set tables
One load pattern for data uses `working set` slices of the raw data in object storage files loaded into Big Query
internal tables.  Compared to Big Query external tables enable more efficient data storage and processing, improving
performance and helping to manage costs.  Further info on BigQuery external table limitations can be found
[here](https://cloud.google.com/bigquery/docs/external-tables#limitations).

The raw data slices most often consist of one batch day's worth of data, but may include window of multiple batch
days if there are concerns with data delays or delays in batch processing.

In addition to filtering the amount of data, the working set is also useful for converting the csv text data from
string into the appropriate Big Query native data types.  Note that BigQuery, by default will attempt to infer the
field data types when the external tables are created, but given the process only uses a sample of records, the
data types assigned by BigQuery can sometimes be incorrect.  Further, there can be issues with future data
if the fields don't match the required format.  This is especially true for timestamp values that can't be converted
to valid timestamps.

The exception to this guidance is when the raw data is stored in a file format that supports schemas and data typing
such as parquet or avro.  If the raw data is provided in parquet or avro (or similar typed format), then there may
not be a need to process all the raw data as strings.

## Update the `users` external table to use strings
In the previous `step 01`, the external table definition has inferred the data types for the fields.  Now convert
the Big Query external table to only use strings.  BigQuery doesn't support a generic `select * ...` approach
that both defines the columns names and tries to guess column types.  (Some databases do support this option)
As a work-around, explicitly define the external table fields and set the data type of each field to `'string`.

Explicitly define the external columns and data types by updating the definition in the dbt `sources.yml` file.
Note that the order of the columns in the yaml definition must match the order of the columns in the csv file.
This does mean that if there is a new column added to the csv file between existing columns, then the external 
table defintiion will need to be updated.

Apply the updated external table definition using the `dbt run-operation stage_external_sources` command
to apply the new spec.

By default the `dbt-external-tables` package won't update the existing table 
defition.  Force a re-apply using the refresh flag:
```shell
dbt run-operation stage_external_sources --vars "ext_full_refresh: true"
```

Confirm in the BigQuery console that the externa table definition now has all `string` fields, except
for the partition virtual columns.

Query the external table again.
```sql
select *
from <dbt-schema-prefix>_stg_thelook.users
where p_year = 2023
  and p_month = 12
  and p_day = 5
limit 20
```
Now all returned values should be string values, expect for the parition
key values.  In the BigQuery console when viewing query results, `string` values are left justified
while numeric values are right justified.

## Creating the users working set
Define a `dbt` model to create a working set table containing a single batch day of data.  This will involve
creating the dbt model (SQL statement) and using dbt run variables to pass in the target batch date.

Despite having explicitly defined the external table columns in the previous step, it is good practice to again
explicitly redefine the columns for the working set table to ensure a clean segregation boundary between
the external table raw staged data and the working set objects.

### Define the working set model
In dbt, a `model` can be thought of as a SQL SELECT statement that is used to either create a table
of physical data or a logical view of the data (like a virtual table).

First define the model metadata organisation in the `dbt_project.yml` file.  Good practice will match
the layout of the `models:` section of the `dbt_project.yml` file with the actual `models/...` directory
layout.  The model metadata is defined in the `models:` section
```yaml
models:
  bq_dbt_mart:
    staging:
      thelook:
        ws:
          schema: thelook_ws
          materialized: table
```
There are a number of options and configuration settings that can be added to the metadata, but for this
step:
- the target schema name for the new working set view is defined.
- the dbt materialisation is set to 'table'
The way dbt treats a model, whether a table, view, etc, is defined by the [materialisation](https://docs.getdbt.com/docs/build/materializations).  This model uses `table`, which will replace the table with a
new copy on each `dbt run`.

One nice feature of physical BigQuery tables is that they can be "previewed" for free in the BigQuery console.

Add the new SQL statement in a file under the `./models/staging/thelook/ws/...` directory.  Directories provide
one of the main mechanisms for organising the dbt model content.  Organising model directories by data
tier is a common practice.

Create a new file called `users_ws.sql` that will contain the defition of the new working set table.
To start, use a simple SQL SELECT statement that hard codes the batch date.

```sql
select
    <column-list>
from {{ source('stg_thelook', 'users') }}
where p_year = 2023
  and p_month = 12
  and p_day = 5
```

In the `<column-list>` apply any required data type conversions, e.g:
- id as integer
- age as integer
- latitude as numeric
- longitude as numeric
- created_at as timestamp

### Apply the static working set model
The `dbt run` command is used to run all the models that are configured in the dbt project.

First remove or disable the sql and yml files under the `./models/example/.` directory.

Execute dbt to apply the new model, creating the new working set table with 1 batch day of data.
```
dbt run
```
There should now be a table at `<dbt-schema-prefix>_thelook_ws.users`

### Adding operational metadata
Operational metadata in a table, is data about the processing of the data.  Operational metadata is useful
for managing the day to day data processing and data quality.

In this scenario, the following operational metadata will be added to the working set table:
* batch id for the data (batch date in this scenario)
* file name in object storage that contains the record
* the job run timestamp
* the job run id

These additional fields will be added as columns in the working set table.
In dbt, variables and special values are included in the SQL template using the `{{ ... }}` double
bracket operators.

First in the `users_ws.sql` file, set the `batch_id` as a dbt model variable (string):
```
{% set batch_id = '2023-12-05' -%}
```

Use the local dbt macro `set_partition_keys(...)` to extract the year, month, and day values from the
batch id:
```
{%- set p_year, p_month, p_day = partition_date_keys(var('batch_dt')) -%}
```

Now user these values in the dbt model SQL statement:
```sql
select
    ...
    , '{{ batch_id }}' as batch_id 
from {{ source(...) }}
where p_year = {{ p_year }}
    and p_month = {{ p_month }}
    and p_day = {{ p_day }}
```
Note the single quotes around `{{ batch_id }}`.  The `batch_id` variable is a template string and will
be replaced in a SQL statement.  In SQL, string literals must be includes in single ticks.

`dbt` provides some special runtime variables that we can use for the additional operational metadata
fields:
- run_started_at for the dbt_run_dttm
- invocation_id for the dbt_job_id

* https://docs.getdbt.com/reference/dbt-jinja-functions/invocation_id
* https://docs.getdbt.com/reference/dbt-jinja-functions/run_started_at

Use the [BigQuery external table pseudo-column](https://cloud.google.com/bigquery/docs/query-cloud-storage-data#query_the_file_name_pseudo-column) to add the source filename and object storage location.

```sql
select
    ...
    , '{{ invocation_id }}' as dbt_job_id
    , cast('{{ run_started_at }}' as timestamp) as dbt_run_dttm
    , _FILE_NAME as file_uri
from ...
```

Run the dbt model again and validate the new operational metadata columns.
```shell
dbt run
```

### Make the batch date/id dynamic
Up to this point, the batch date value used to generate the working set table has been static or hard
coded in the dbt model SQL.  Now convert the model to use a dbt variable that can be passed in at
runtime to enable running the dbt pipeline for different days without having to modify the code.

The variable will be called `batch_dt`.  It's good practice to include a safe and sane default value
for a variable so that other dbt operations can be run without needing to supply the dbt variable in the
dbt run command - makes life easier.

The dbt variable is declared in the `dbt_project.yml` file, in the `vars:` section.
Check that the dbt project has a variable for batch_dt with a default value of '1900-01-01'.

Update the `users_ws.sql` model to use the new dbt variable.  Modify the first 2 `set` commands to 
reference the variable.
```sql
{%- set batch_id = var('batch_dt') -%}
{%- set p_year, p_month, p_day = partition_date_keys(batch_dt) -%}
```
The dbt `var(...)` template function is used to access the dbt variables from SQL model templates.
Note that the variable name must be quoted as a string.

Run the model with the default argument value.  Note that there should be 0 rows and data processed.
Verify that the target able is empty in the `users_ws` table preview.

Now run the model, specifying a batch date as a dbt job variable.
```shell
dbt run --vars "{'batch_dt': '2023-12-05'}"
```
The table should now contain data again for '2023-12-05'.

Run for the next batch day, '2023-12-06'
```
dbt run --vars "{'batch_dt': '2023-12-06'}"
```
Preview the table again to confirm there is data for the next batch day.

This mechanism allows the dbt data pipline jobs to be run for any given batch day, especially useful
when needing to fix errors from previous batch runs.