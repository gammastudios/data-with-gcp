-- drop table gamma_mart.purchase_txn;

create table gamma_mart.purchase_txn (
  customer_id INT64
  , txn_id INT64
  , txn_dts TIMESTAMP
  , order_id INT64
  , amount NUMERIC
  , insert_dts TIMESTAMP
  , src_filename STRING
)