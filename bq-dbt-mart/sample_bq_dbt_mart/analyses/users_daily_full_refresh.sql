-- SQL to extract the users/customer data from the thelook_ecommerce.users table
-- Full refresh extract contains all user records up to the end of the batch day.

-- Note that timestamp values are in UTC while the extracts are based on Australia/Melbourne timezone.

{%- set extract_kind = 'full-refresh' %}

{%- set p_year, p_month, p_day = partition_date_keys(var('batch_dt')) %}

export data options (
    uri='gs://{{ var('raw_bucket') + '/' + var('raw_bucket_prefix') }}/{{ extract_kind }}/users/p_year={{ p_year }}/p_month={{ p_month }}/p_day={{ p_day }}/*:w
    .csv',
    format='CSV',
    overwrite=true,
    header=true
) AS
SELECT *
FROM {{ source('thelook_ecommerce', 'users') }}
WHERE
    created_at < CAST('{{ var('batch_dt') }} 00:00:00' AS TIMESTAMP FORMAT 'YYYY-MM-DD HH24:MI:SS' AT TIME ZONE 'Australia/Melbourne') + INTERVAL '1' DAY;
