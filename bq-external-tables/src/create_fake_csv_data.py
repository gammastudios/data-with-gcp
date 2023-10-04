from faker import Faker
from datetime import datetime, timedelta
from faker.providers import BaseProvider

class TxnDatetimeProvider(BaseProvider):
    def __init__(self, generator, days_of_data=365):
        super().__init__(generator)
        self.generator = generator
        self.end_dts = datetime.now()
        self.start_dts = self.end_dts - timedelta(days=days_of_data)
        self.format = '%Y-%m-%d %H:%M:%S'

    def txn_datetime(self):
        fake_date = self.generator.date_time_between(start_date=self.start_dts, end_date=self.end_dts)
        return fake_date.strftime(self.format)

    def txn_amount(self):
        return self.generator.pydecimal(left_digits=3, right_digits=2, positive=True)


if __name__ == '__main__':
    Faker.seed(0)
    fake = Faker()
    txn_datetime_provider = TxnDatetimeProvider(generator=fake, days_of_data=365*2)
    fake.add_provider(txn_datetime_provider)

    csv_data = fake.csv(
        header=('customer_id', 'txn_id', 'txn_dts', 'order_id', 'amount'),
        data_columns=('{{pyint}}', '{{pyint}}', '{{txn_datetime}}', '{{pyint}}', '{{txn_amount}}'),
        num_rows=1000
    )
    
    print(csv_data)