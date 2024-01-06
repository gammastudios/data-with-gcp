{#-
 Working set of one batch day of data from the `users` source table.
#}

{%- set batch_id = var('batch_dt') -%}
{%- set p_year, p_month, p_day = partition_date_keys(var('batch_dt')) -%}

select
    cast(id as integer) as id
    , first_name
    , last_name
    , email
    , cast(age as integer) as age
    , gender
    , state
    , street_address
    , postal_code
    , city
    , country
    , cast(latitude as numeric) as latitude
    , cast(longitude as numeric) as longitude
    , traffic_source
    , cast(created_at as timestamp) as created_at
    , '{{ batch_id }}' as batch_id
    , '{{ invocation_id }}' as dbt_job_id
    , '{{ run_started_at }}' as dbt_run_dttm
    , _FILE_NAME as file_uri
from {{ source('stg_thelook', 'users') }}
where p_year = {{ p_year }}
  and p_month = {{ p_month }}
  and p_day = {{ p_day }}