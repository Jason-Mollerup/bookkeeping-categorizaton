# Transaction Data Generator

Generate dummy transaction data for testing bulk imports and performance with large datasets (1M+ transactions).

## Usage

```bash
# Generate 1,000 transactions
ruby scripts/generate_transactions.rb

# Generate 100,000 transactions
ruby scripts/generate_transactions.rb 100000

# Generate 1,000,000 transactions with custom filename
ruby scripts/generate_transactions.rb 1000000 my_large_dataset.csv
```

## Generated Data Structure

The CSV file contains the following columns:

| Column          | Type    | Description                          |
| --------------- | ------- | ------------------------------------ |
| `amount`        | Decimal | Transaction amount                   |
| `description`   | String  | Transaction description              |
| `date`          | Date    | Transaction date (YYYY-MM-DD format) |
| `category_id`   | Integer | Category ID (1-10)                   |
| `category_name` | String  | Category name                        |
