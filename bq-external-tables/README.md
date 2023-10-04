# BQ External Tables
An example of the components to demonstrate a `file => target table` batch style pipeline using external tables.

Data transformation tools such as [dbt](https://docs.getdbt.com/docs/introduction) automate the creation and 
management of these objects reducing data engineering drugery, but useful to understand what those tools are
generating to both understand the workflow and to tune solutions for specific use cases.

While the example objects are based on a daily style batch cycle, the general pattern applies to discrete bounded set based processing at any given set interval, e.g. monthly to hourly.  Note that
once a data load latency requirement reduces below hourly a continuous unbounded stream processing
pattern is preferrable due to batch stop/start overheads.

## Concepts Considered
* organisation of data files within a GCP bucket using date based partitioning

* view and table pipeline for loading raw data into a target mart table

* using hive style partitioning on the external table for controlling what data gets loaded into the target table

* injecting operational/control metadata into tables using the BigQuery view and table objects.

* demonstration of batch run error handling