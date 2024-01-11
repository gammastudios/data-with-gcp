

# ?= will use the env var value if it exists, otherwise use the default value

# batch date of the target run
BATCH_DT ?= '1900-01-01'

# used for running a portion of the dbt project
DBT_MODEL_PATH ?= "*"

DBT_VARS := {"batch_dt": $(BATCH_DT)}


.PHONY: dbt-vars dbt-run

check-vars:
	echo $(DBT_VARS)

dbt-run:
	@echo "Running dbt model for batch date BATCH_DT=$(BATCH_DT)"
	dbt run --vars '$(DBT_VARS)' --models $(DBT_MODEL_PATH)
