# Duplicate Checks

| Dataset | Column | Empty | Distinct | Duplicate Keys | Duplicate Rows | Strict Unique? | Samples |
|---|---|---:|---:|---:|---:|---|---|
| users_sample.csv | id | 0 | 1000 | 0 | 0 | true |  |
| users_sample.csv | nni | 0 | 1000 | 0 | 0 | true |  |
| users_sample.csv | phone | 0 | 995 | 5 | 10 | false | +22223531847, +22224172007, +22224946361, +22234268059, +22236957006 |
| users_sample.csv | email | 593 | 407 | 0 | 0 | false |  |
| accounts_sample.csv | id | 0 | 1099 | 0 | 0 | true |  |
| accounts_sample.csv | account_number | 0 | 1099 | 0 | 0 | true |  |
| accounts_sample.csv | user_id | 0 | 1000 | 66 | 165 | false | 16, 2650, 3331, 3434, 3999, 4991, 5962, 7355, 7785, 8122 |
| transactions_sample.csv | id | 0 | 10000 | 0 | 0 | true |  |
| transactions_sample.csv | reference | 0 | 9997 | 3 | 6 | false | TX20240601272037, TX20241108547800, TX20241212196762 |
| transactions_sample.csv | idempotency_key | 0 | 6266 | 2682 | 6416 | false | 39f99a82-5ee6-4879-88e5-885344f0f4b7, 40bb5628-121e-4c31-9257-56566775d4de, 6233193d-1760-42d3-a847-f90540959a11, 7d934e84-ac5a-4d2e-b17c-3e825a3be8ae, 9dfc6635-f4e4-467c-b6e0-e30e84c0e0b1, b5341373-5baf-4ddc-ba71-64a1a8572404, b819dea4-2275-4d92-9eaf-b0ddc581d841, cb9a3719-6c72-4c0c-96be-d0375aab55f3, d48031ac-7d57-4f31-8633-8161ff578dde, e4f9a0b6-23c6-4046-9229-dc29164640ee |
| merchants_sample.csv | id | 0 | 100 | 0 | 0 | true |  |
| merchants_sample.csv | code | 0 | 100 | 0 | 0 | true |  |
| agencies_sample.csv | id | 0 | 50 | 0 | 0 | true |  |
| agencies_sample.csv | code | 0 | 50 | 0 | 0 | true |  |
| reference_categories.csv | id | 0 | 13 | 0 | 0 | true |  |
| reference_categories.csv | code | 0 | 13 | 0 | 0 | true |  |
| reference_tx_types.csv | id | 0 | 8 | 0 | 0 | true |  |
| reference_tx_types.csv | code | 0 | 8 | 0 | 0 | true |  |
| reference_wilayas.csv | id | 0 | 15 | 0 | 0 | true |  |
| reference_wilayas.csv | code | 0 | 15 | 0 | 0 | true |  |

