-- create the external table on raw data
create or replace external table gamma_mart.purchase_txn_ext (
  customer_id STRING
  , txn_id STRING
  , txn_dts STRING
  , order_id STRING
  , amount STRING
)
with partition columns
options (
  format='CSV',
  skip_leading_rows=1,
  field_delimiter=',',
  uris=['gs://gamma-data-with-bq/gamma-mart/purchase-txn/*.csv'],
  hive_partition_uri_prefix='gs://gamma-data-with-bq/gamma-mart/purchase-txn/'
);
