# `make`-ing it work
The dbt model is now driven by dynamic dbt job variables, enabling the data pipelines to be run without
needing to modify the SQL/model files for each different batch date.

```shell
dbt run --vars "{'batch-dt': '2023-12-05'}"
```

This makes running the models easier, but starts to make the command line more complicated and longer,
especially with the mixture of single quotes and double quotes needed to create strings of json.  While less of an
issue for automated jobs/runs, where scripts can be written and validated, it does make interactive development
work more complicated.

## Wrapping `dbt run ...`
Wrapping the `dbt run ...` commands with an easier to use command line makes interactive development work
more straightforward and less prone to typing errors issues.  There are a number of options for wrapping
the `dbt run ...` commands including shell scripts, custom python scripting, or using a scheduling and
orchestration tool.  The `make` tool sits closer to the shell scripts approach, but with the benefit of
the familiar `Makefile` constructs and features.

## Running with `make`
Setup a `Makefile` that will run the dbt model for a given batch date.  This example uses environment
variables to dynamically pass in batch date values for running the dbt without needing to struggle with
json formatting and nested quote debugging.

An example initial `Makefile` based on the [sample Makefile](../sample_bq_dbt_mart/Makefile)

```make

# the target batch date
BATCH_DT ?= '2023-12-05'

# make magic to let `make` know which jobs produce outputs
.PHONY: dbt-run

# set DBT_VARS as a makefile variable to enable future inclusion of additional options
DBT_VARS := {"batch_dt": $(BATCH_DT)}

# dbt run target
dbt-run:
    dbt run --vars '$(DBT_VARS)'

```

This can be used to run dbt for a given batch date.
```bash
BATCH_DT="2023-12-05" make dbt-run
```

This batch date env var could also be set as a shell env var if running the same date multiple times.

```shell
export BATCH_DT="2023-12-05"

make dbt-run
```
