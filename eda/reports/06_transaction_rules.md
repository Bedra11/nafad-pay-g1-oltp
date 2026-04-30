# Transaction Rules

| Rule | Count | Samples |
|---|---:|---|
| FAILED => balance_before == balance_after | 28 | 46539, 19766, 88264, 95349, 26298, 76340, 32568, 21341, 83478, 22101 |
| amount must be > 0 | 5 | 45196, 90655, 63406, 12608, 51863 |
| fee must be >= 0 | 0 |  |
| balance_before must be >= 0 | 0 |  |
| balance_after must be >= 0 | 19 | 46539, 19766, 88264, 26298, 76340, 32568, 83478, 22101, 80011, 51748 |
| completed_at >= created_at | 6 | 52821, 23010, 83291, 19358, 60280, 23225 |
| status must be one of allowed values | 0 |  |
| same idempotency_key with different payload | 3710 | 6ae7eb7f-7706-4e43-b3e7-5ae422c3c858, 6d62dbaa-33d5-40bd-85bb-2d7b2cd5cad4, 6f161e3f-484a-4001-9b5f-ce186ae348e4, ab88f055-aed3-49a0-ad8c-2ccc0b9dd4bd, e43ce71f-da73-4967-9765-7f8ac23186c1, 5e176050-badc-42c5-a091-f78dcef1da23, 09050d1d-c063-4067-80b2-5f62f8f64966, 5aed39a0-ed8c-42cc-80b9-dd4bd17797dc, 4ebb6cb8-eb88-4fc1-add0-5762f680b522, 09050d1d-c063-4067-80b2-5f62f8f64966 |
| same reference with different amount | 3 | TX20241108547800, TX20240601272037, TX20241212196762 |
| node_id != processing_node | 8006 | 41046, 15968, 22327, 64395, 34838, 8727, 68627, 33903, 45196, 90655 |

