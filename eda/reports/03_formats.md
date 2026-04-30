# Format Checks

| Rule | Count | Samples |
|---|---:|---|
| phone must match +222XXXXXXXX | 0 |  |
| nni must be 10 digits | 5 | 0301643XX7, 7105714XX1, 6711718XX1, 9602130XX2, 9101040XX1 |
| transactions.amount > 0 | 5 | -800, -3400, -9800, -8400, -1000 |
| transactions.fee >= 0 | 0 |  |
| transactions.balance_before >= 0 | 0 |  |
| transactions.balance_after >= 0 | 19 | -700, -25, -400, -15356, -700, -400, -325, -6272, -50, -6472 |
| transactions.created_at parsable | 0 |  |
| transactions.completed_at parsable | 0 |  |
| transactions.status in {SUCCESS,FAILED,PENDING} | 0 |  |

