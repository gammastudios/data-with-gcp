-- transformed data modified on each batch run
-- alternative would be to load a staging table from the external table
create or replace view gamma_mart.purchase_txn_tx as
select
    cast(customer_id as INT64) as customer_id
    , cast(txn_id as INT64) as txn_id
    , cast(txn_dts as TIMESTAMP) as txn_dts
    , cast(order_id as INT64) as order_id
    , cast(amount as NUMERIC) as amount
    , current_timestamp as insert_dts
    , _file_name as src_filename
from gamma_mart.purchase_txn_ext
where p_year=2023
  and p_month=10
  and p_day=03
