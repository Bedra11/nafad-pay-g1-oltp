# Duplicate Checks

| Dataset | Column | Empty | Distinct | Duplicate Keys | Duplicate Rows | Strict Unique? | Samples |
|---|---|---:|---:|---:|---:|---|---|
| users_sample.csv | id | 0 | 1000 | 0 | 0 | true |  |
| users_sample.csv | nni | 0 | 1000 | 0 | 0 | true |  |
| users_sample.csv | phone | 0 | 995 | 5 | 10 | false | +22223531847, +22224172007, +22224946361, +22234268059, +22236957006 |
| users_sample.csv | email | 593 | 407 | 0 | 0 | false |  |
| accounts_sample.csv | id | 0 | 1099 | 0 | 0 | true |  |
| accounts_sample.csv | account_number | 0 | 1099 | 0 | 0 | true |  |
| accounts_sample.csv | user_id | 0 | 1000 | 66 | 165 | false | 2650, 4000, 4193, 4457, 5945, 8122, 8351, 8443, 8919, 9441 |
| transactions_sample.csv | id | 0 | 10000 | 0 | 0 | true |  |
| transactions_sample.csv | reference | 0 | 9997 | 3 | 6 | false | TX20240601272037, TX20241108547800, TX20241212196762 |
| transactions_sample.csv | idempotency_key | 0 | 6266 | 2682 | 6416 | false | 0f1f10af-8fb4-47d1-9176-e502f3fbaa18, 2d7d2fca-974f-4e6e-a2dc-4fda85ecec56, 591b803f-6bfe-4fd2-845b-16276dffd044, 765f57a9-91a6-495f-aa36-70883fbda027, 7fe403b7-a736-4005-b0fd-864c3447d90e, bc280464-190b-46a9-ab24-78045207af76, da73967d-7657-4f8a-8231-86c1e3393764, df73dcf0-3cb8-40e8-afb2-dc5e42acaa9c, e54c96c4-58f7-4656-b968-5987e12c574e, e6ee2dc4-fda8-45ec-ac56-2c478752a49e |
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

