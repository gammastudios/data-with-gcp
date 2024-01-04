# BQ Mart with dbt
Data mart using dbt to manage the data flow from GCP object storage to target mart tables.

Packages and tools used:
* python 3.9
* VSCode
* jupyterlab

[dbt BigQuery setup docs](https://docs.getdbt.com/docs/core/connect-data-platform/bigquery-setup):
detailed information on configuring dbt with BigQuery.

## Environment Setup
Install the `dbt-bigquery` python package using poetry.
```
poetry env use 3.9
poetry add dbt-bigquery
poetry install
poetry shell
```

*Bonus* List the packages used by `dbt-bigquery`
```
poetry show dbt-bigquery
```

Configure VSCode to use the poetry python environment.  The location of the python virtual env can be
found using the python env info command.
```
poetry env info --path
```

## log into GCP using gcloud auth
Log into GCP using the gcloud cli OAuth authentication following the browser prompts to complete the login process.
```
gcloud auth login
```