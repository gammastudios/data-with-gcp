-- load batch of data into the target table
insert into `gamma_mart.purchase_txn`
select * from gamma_mart.purchase_txn_tx