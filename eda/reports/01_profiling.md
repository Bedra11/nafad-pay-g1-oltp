# Profiling

## users_sample.csv

- Rows: 1000
- Columns: 22

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 1000 | integer | 1010 | 9997 | 817, 1721, 1685, 641, 6641 |
| nni | 0 | 0.00 | 1000 | string | 0001003004 | 9915827674 | 8802937782, 8515199525, 8404540106, 0301643XX7, 7105714XX1 |
| first_name | 0 | 0.00 | 229 | string | Abdallah | Zeinab | Mohamed Lemine, Demba, Khadijetou, Mohamed Vall, Moctar |
| last_name | 0 | 0.00 | 139 | string | Anne | Yatabaré | Ould Hadrami, Soumaré, Mint Vall, Ould Ahmed, Diagana |
| full_name | 0 | 0.00 | 924 | string | Abdallah Ba | Zeinab Thiam | Mohamed Lemine Ould Hadrami, Demba Soumaré, Khadijetou Mint Vall, Mohamed Vall Ould Ahmed, Moctar Diagana |
| gender | 0 | 0.00 | 2 | string | F | M | M, F |
| birth_date | 0 | 0.00 | 939 | date/datetime | 1960-01-07 | 2005-12-05 | 1988-03-01, 1985-08-07, 1984-05-20, 2003-03-21, 1971-04-02 |
| ethnicity | 0 | 0.00 | 4 | string | MAURE | WOLOF | MAURE, SONINKE, PEUL, WOLOF |
| phone | 0 | 0.00 | 995 | integer | +22222003153 | +22249985346 | +22224172007, +22234268059, +22236957006, +22224946361, +22223531847 |
| email | 593 | 59.30 | 407 | string | abdallah.ba331@outlook.com | zeinab.thiam136@outlook.com | khadijetou.mintvall623@gmail.com, lala.guèye748@outlook.com, cheikhsidiya.ouldsalem484@yahoo.fr, mohamedyahya.ouldeleya165@gmail.com, mariem.mintelmokhtar579@hotmail.fr |
| wilaya_id | 0 | 0.00 | 15 | integer | 1 | 9 | 2, 15, 4, 1, 5 |
| wilaya_name | 0 | 0.00 | 15 | string | Adrar | Trarza | Nouakchott-Ouest, Tiris Zemmour, Dakhlet Nouadhibou, Nouakchott-Nord, Trarza |
| moughataa_id | 0 | 0.00 | 55 | integer | 1 | 9 | 4, 54, 10, 3, 13 |
| moughataa_name | 1000 | 100.00 | 0 | empty |  |  |  |
| profile_type | 0 | 0.00 | 6 | string | ACTIVE | VIP | STANDARD, ACTIVE, VIP, OCCASIONAL, DORMANT |
| kyc_level | 1000 | 100.00 | 0 | empty |  |  |  |
| status | 0 | 0.00 | 5 | string | ACTIVE | SUSPENDED | ACTIVE, INACTIVE, BLOCKED, SUSPENDED, PENDING_KYC |
| device_type | 0 | 0.00 | 5 | string | ANDROID | WEB | WEB, ANDROID, USSD, IOS, API |
| registration_date | 0 | 0.00 | 643 | date/datetime | 2022-01-05 | 2035-06-15T10:00:00.000Z | 2024-11-09, 2023-03-27, 2023-03-02, 2022-06-04, 2023-11-28 |
| last_login | 0 | 0.00 | 980 | date/datetime | 2022-03-06T09:02:21.684Z | 2024-12-30T23:17:35.484Z | 2024-12-19T14:37:14.780Z, 2024-02-17T13:59:55.117Z, 2024-07-07T16:23:26.114Z, 2024-12-22T04:41:52.869Z, 2023-12-01T04:06:22.449Z |
| created_at | 0 | 0.00 | 980 | date/datetime | 2022-01-05T18:12:47.604Z | 2024-12-30T12:35:02.456Z | 2024-11-09T09:32:12.087Z, 2023-03-27T06:31:19.432Z, 2023-03-02T05:38:27.231Z, 2022-06-04T02:46:58.383Z, 2023-11-28T03:15:16.452Z |
| updated_at | 0 | 0.00 | 980 | date/datetime | 2022-03-06T09:02:21.684Z | 2024-12-30T23:17:35.484Z | 2024-12-19T14:37:14.780Z, 2024-02-17T13:59:55.117Z, 2024-07-07T16:23:26.114Z, 2024-12-22T04:41:52.869Z, 2023-12-01T04:06:22.449Z |

## accounts_sample.csv

- Rows: 1099
- Columns: 16

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 1099 | integer | 10032 | 9997 | 6, 16, 17, 29, 34 |
| user_id | 0 | 0.00 | 1000 | integer | 10098 | 993 | 6, 16, 28, 33, 62 |
| account_number | 0 | 0.00 | 1099 | string | NA013833045 | NW995894194 | NW127549767, NW068077445, NS355636239, NS141694545, NW131669789 |
| account_type | 0 | 0.00 | 5 | string | AGENT | WALLET | WALLET, SAVINGS, AGENT, CORPORATE, MERCHANT |
| account_type_label | 1099 | 100.00 | 0 | empty |  |  |  |
| currency | 0 | 0.00 | 1 | string | MRU | MRU | MRU |
| balance | 0 | 0.00 | 674 | integer | 0 | 997450 | 31000, 60000, 211075, 24000, 378 |
| available_balance | 0 | 0.00 | 280 | integer | 1000 | 99000 | 31000, 60000, 266000, 24000, 1300 |
| daily_limit | 0 | 0.00 | 1 | integer | 500000 | 500000 | 500000 |
| monthly_limit | 0 | 0.00 | 1 | integer | 15000000 | 15000000 | 15000000 |
| status | 0 | 0.00 | 4 | string | ACTIVE | FROZEN | FROZEN, ACTIVE, CLOSED, DORMANT |
| is_primary | 0 | 0.00 | 2 | string | false | true | true, false |
| opened_date | 0 | 0.00 | 640 | date/datetime | 2022-01-05 | 2024-12-30 | 2024-02-07, 2022-01-05, 2023-11-20, 2023-06-14, 2022-11-02 |
| last_activity | 0 | 0.00 | 1099 | date/datetime | 2022-02-21T21:23:07.860Z | 2024-12-30T21:50:11.072Z | 2024-05-05T06:39:38.325Z, 2024-11-11T04:45:54.579Z, 2024-07-12T05:48:42.187Z, 2024-07-26T04:32:25.579Z, 2023-11-30T05:33:37.141Z |
| created_at | 0 | 0.00 | 980 | date/datetime | 2022-01-05T18:12:47.604Z | 2024-12-30T12:35:02.456Z | 2024-02-07T08:15:17.797Z, 2022-01-05T18:12:47.604Z, 2023-11-20T08:58:48.784Z, 2023-06-14T22:04:52.281Z, 2022-11-02T02:18:13.252Z |
| updated_at | 0 | 0.00 | 1099 | date/datetime | 2022-02-21T21:23:07.860Z | 2024-12-30T21:50:11.072Z | 2024-05-05T06:39:38.325Z, 2024-11-11T04:45:54.579Z, 2024-07-12T05:48:42.187Z, 2024-07-26T04:32:25.579Z, 2023-11-30T05:33:37.141Z |

## transactions_sample.csv

- Rows: 10000
- Columns: 40

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 10000 | integer | 10004 | 99993 | 41046, 6138, 78473, 15968, 22327 |
| reference | 0 | 0.00 | 9997 | string | TX20240101196611 | TX20241230977017 | TX20241212196762, TX20240601272037, TX20241108547800, TX20240308467775, TX20240306952908 |
| idempotency_key | 0 | 0.00 | 6266 | string | 00091cdc-ddd1-4f91-964e-237e1d8dcffd | fff82078-2887-4463-941e-b7b168cd8cd5 | 26dc6727-e75f-4b36-b047-e0bc59003674, 33548389-51c9-4d19-85e6-dda8dd70621d, 33e2e0ce-866a-40dd-ad7e-0dcc579b000a, e1a8dc47-c743-49b7-915c-b20fc6bd4963, fcf9259d-c1b8-4f04-a99e-0dad9f45e5b0 |
| transaction_type | 0 | 0.00 | 8 | string | AIR | WIT | TRF, WIT, BIL, AIR, PAY |
| transaction_type_label | 10000 | 100.00 | 0 | empty |  |  |  |
| amount | 0 | 0.00 | 214 | integer | -1000 | 99000 | 1300, 4900, 3800, 500, 2300 |
| fee | 0 | 0.00 | 160 | integer | 0 | 995 | 25, 50, 100, 0, 200 |
| total_amount | 0 | 0.00 | 429 | integer | 100 | 9898 | 1325, 4925, 3825, 550, 2325 |
| currency | 0 | 0.00 | 1 | string | MRU | MRU | MRU |
| source_account_id | 0 | 0.00 | 945 | integer | 10028 | 9999 | 1430, 4395, 532, 5177, 7432 |
| source_account_number | 0 | 0.00 | 945 | string | NA013833045 | NW998951793 | NW065889477, NW108852624, NM743834734, NS780456543, NW805945396 |
| source_user_id | 0 | 0.00 | 901 | integer | 1010 | 9997 | 1295, 3999, 490, 4705, 6762 |
| source_user_name | 0 | 0.00 | 839 | string | Abdallah Ba | Zeinab Wade | Noura Mint Mahmoud, Coumba Diagana, Mohamed Vall Diop, Hacen Ould Sidi, Moulaye Ould Mokhtar |
| destination_account_id | 5366 | 53.66 | 588 | integer | 1 | 9997 | 9643, 2440, 280, 1868, 2802 |
| destination_account_number | 5366 | 53.66 | 588 | string | NA002789020 | NW985816985 | NW918159366, NW747740745, NS152303695, NS245801448, NS530611515 |
| destination_user_id | 5366 | 53.66 | 582 | integer | 1 | 9987 | 8754, 2238, 263, 1705, 2567 |
| destination_user_name | 5366 | 53.66 | 553 | string | Abdallah Fall | Zeinab Thiam | Tekber Mint Sidi, Hamadi Ould Nagi, Youssouf Ould Nenni, Moulaye Diakité, Soumaïla Soumaré |
| merchant_id | 8630 | 86.30 | 162 | integer | 102 | 99 | 380, 336, 87, 404, 361 |
| merchant_code | 8630 | 86.30 | 162 | string | MRC007774 | MRC999445 | MRC604180, MRC190368, MRC007774, MRC289083, MRC630009 |
| merchant_name | 8630 | 86.30 | 101 | string | undefined Al Amane Dakhlet Nouadhibou | undefined du Sahel Nouakchott-Sud | undefined Al Amane Nouakchott-Ouest, undefined Ksar Dakhlet Nouadhibou, undefined El Mouna Nouakchott-Ouest, undefined Central Hodh El Gharbi, undefined Teyarett Nouakchott-Nord |
| agency_id | 6850 | 68.50 | 94 | integer | 1 | 99 | 70, 38, 75, 82, 77 |
| agency_code | 6850 | 68.50 | 94 | string | ADR-001 | TYS-005 | TRZ-001, NKC-O-019, BRK-001, GDM-001, BRK-003 |
| agency_name | 6850 | 68.50 | 94 | string | Agence Adrar 1 | Agence Trarza 5 | Agence Trarza 1, Agence Nouakchott-Ouest 19, Agence Brakna 1, Agence Guidimaka 1, Agence Brakna 3 |
| agent_id | 6850 | 68.50 | 232 | integer | 10 | 99 | 280, 160, 296, 322, 304 |
| agent_name | 6850 | 68.50 | 231 | string | Abdallah Niang | Zeinab Mint Cheikh | Brahim Ould Nenni, Boubacar Ould Jiddou, Malick Koné, Maguette Anne, Safiya Mint Mahmoud |
| status | 0 | 0.00 | 2 | string | FAILED | SUCCESS | FAILED, SUCCESS |
| failure_reason | 6288 | 62.88 | 16 | string | ACC_INACT | WRONG_PIN | INSUFFICIENT_BALANCE, ACC_LOCKED, INSUF_BAL, LIMIT_DAY, WRONG_PIN |
| balance_before | 0 | 0.00 | 4998 | integer | 0 | 998400 | 1275, 282000, 21350, 1550, 18750 |
| balance_after | 0 | 0.00 | 5092 | integer | -15356 | 9990 | 1275, 277075, 17525, 1000, 16425 |
| node_id | 0 | 0.00 | 5 | string | NDB-NODE-1 | NKC-NODE-3 | NDB-NODE-1, NDB-NODE-2, NKC-NODE-3, NKC-NODE-1, NKC-NODE-2 |
| processing_node | 0 | 0.00 | 5 | string | NDB-NODE-1 | NKC-NODE-3 | NKC-NODE-2, NDB-NODE-2, NDB-NODE-1, NKC-NODE-1, NKC-NODE-3 |
| sequence_number | 0 | 0.00 | 9996 | integer | 10 | 99990 | 10, 20, 30, 40, 50 |
| channel | 0 | 0.00 | 5 | string | AGENCY | WEB | MOBILE_APP, USSD, AGENCY, API, WEB |
| device_type | 0 | 0.00 | 5 | string | ANDROID | WEB | ANDROID, USSD, IOS, WEB, API |
| ip_address | 0 | 0.00 | 6265 | string | 10.0.100.140 | 10.99.93.22 | 10.204.55.70, 10.95.14.104, 10.13.211.129, 10.245.119.68, 10.175.233.22 |
| description | 0 | 0.00 | 1068 | string | Dépôt de 100 000 MRU | Virement salaire de 98 000 MRU | Transfert de 1 300 MRU vers Tekber Mint Sidi, Transfert de 4 900 MRU vers Hamadi Ould Nagi, Transfert de 3 800 MRU vers Youssouf Ould Nenni, Retrait de 500 MRU, Transfert de 2 300 MRU vers Moulaye Diakité |
| transaction_date | 0 | 0.00 | 355 | date/datetime | 2024-01-01 | 2024-12-30 | 2024-12-12, 2024-06-01, 2024-11-08, 2024-03-08, 2024-03-06 |
| transaction_time | 0 | 0.00 | 1368 | string | 00:17:02 | 23:59:55 | 18:04:51, 08:55:23, 08:43:39, 08:21:26, 09:49:06 |
| created_at | 0 | 0.00 | 1412 | date/datetime | 2024-01-01T10:54:12.339Z | 2035-01-27T12:00:00.000Z | 2024-12-12T17:04:51.918Z, 2024-06-01T06:55:23.919Z, 2024-11-08T07:43:39.644Z, 2024-03-08T07:21:26.855Z, 2024-03-06T08:49:06.233Z |
| completed_at | 3712 | 37.12 | 6285 | date/datetime | 2024-01-01T10:54:13.030Z | 2024-12-30T08:40:17.584Z | 2024-06-01T06:55:26.874Z, 2024-11-08T07:43:41.677Z, 2024-03-08T07:21:28.898Z, 2024-03-06T08:49:09.909Z, 2024-04-23T18:59:54.622Z |

## merchants_sample.csv

- Rows: 100
- Columns: 26

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 100 | integer | 103 | 95 | 72, 41, 279, 481, 367 |
| code | 0 | 0.00 | 100 | string | MRC041977 | MRC999347 | MRC096681, MRC787227, MRC188664, MRC243462, MRC140319 |
| mcc | 0 | 0.00 | 13 | integer | 4121 | 8211 | 5912, 5651, 7011, 5541, 8211 |
| name | 0 | 0.00 | 68 | string | undefined Al Amane Dakhlet Nouadhibou | undefined du Sahel Nouakchott-Ouest | undefined Capital Nouakchott-Sud, undefined du Progrès Nouakchott-Nord, undefined El Khair Nouakchott-Ouest, undefined du Marché Dakhlet Nouadhibou, undefined Al Madina Nouakchott-Ouest |
| category_code | 0 | 0.00 | 13 | string | ALM | TRN | SAN, HAB, HTL, CRB, EDU |
| category_label | 100 | 100.00 | 0 | empty |  |  |  |
| owner_first_name | 0 | 0.00 | 79 | string | Abdallah | Zein | Mariama, Ahmed Salem, Zahra, Messoud, Isselmou |
| owner_last_name | 0 | 0.00 | 67 | string | Ba | Yatabaré | Bah, Barry, Mint Habiboullah, Mint Cheikh, Ly |
| owner_full_name | 0 | 0.00 | 100 | string | Abdallah Diallo | Zein Ould Taleb | Mariama Bah, Ahmed Salem Barry, Zahra Mint Habiboullah, Zahra Mint Cheikh, Messoud Ly |
| owner_gender | 0 | 0.00 | 2 | string | F | M | F, M |
| owner_ethnicity | 0 | 0.00 | 4 | string | MAURE | WOLOF | SONINKE, PEUL, MAURE, WOLOF |
| phone | 0 | 0.00 | 100 | integer | +22222102645 | +22249741323 | +22246811539, +22234416802, +22248741318, +22233741328, +22244741322 |
| email | 0 | 0.00 | 25 | string | undefinedalaman@nafadpay.mr | undefinedteyare@nafadpay.mr | undefinedcapita@nafadpay.mr, undefinedduprog@nafadpay.mr, undefinedelkhai@nafadpay.mr, undefineddumarc@nafadpay.mr, undefinedalmadi@nafadpay.mr |
| wilaya_id | 0 | 0.00 | 15 | integer | 1 | 9 | 3, 1, 2, 4, 5 |
| wilaya_name | 0 | 0.00 | 15 | string | Adrar | Trarza | Nouakchott-Sud, Nouakchott-Nord, Nouakchott-Ouest, Dakhlet Nouadhibou, Trarza |
| moughataa_id | 0 | 0.00 | 28 | integer | 1 | 9 | 8, 3, 5, 10, 11 |
| moughataa_name | 100 | 100.00 | 0 | empty |  |  |  |
| address | 0 | 0.00 | 92 | string | 107 Avenue Principale | 97 Avenue de la Paix | 115 Avenue du Commerce, 147 Avenue de la Paix, 16 Avenue Principale, 34 Avenue de la Paix, 144 Avenue du Commerce |
| latitude | 0 | 0.00 | 1 | float | NaN | NaN | NaN |
| longitude | 0 | 0.00 | 1 | float | NaN | NaN | NaN |
| commission_rate | 0 | 0.00 | 77 | float | 0.0053 | 0.0293 | 0.0255, 0.0283, 0.0226, 0.0227, 0.0083 |
| avg_transaction_min | 0 | 0.00 | 8 | integer | 1000 | 5000 | 500, 2000, 20000, 1000, 10000 |
| avg_transaction_max | 0 | 0.00 | 9 | integer | 10000 | 500000 | 50000, 30000, 200000, 20000, 100000 |
| status | 0 | 0.00 | 2 | string | ACTIVE | INACTIVE | ACTIVE, INACTIVE |
| registration_date | 0 | 0.00 | 98 | date/datetime | 2021-01-25 | 2024-12-30 | 2021-06-06, 2022-09-03, 2021-12-17, 2023-01-13, 2021-04-15 |
| created_at | 0 | 0.00 | 99 | date/datetime | 2021-01-25T21:41:34.800Z | 2024-12-30T17:20:30.225Z | 2021-06-06T15:25:48.378Z, 2022-09-03T20:03:09.676Z, 2021-12-17T00:10:06.459Z, 2023-01-13T07:21:14.169Z, 2021-04-15T17:41:28.792Z |

## agencies_sample.csv

- Rows: 50
- Columns: 20

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 50 | integer | 1 | 99 | 63, 51, 44, 33, 23 |
| code | 0 | 0.00 | 50 | string | ASB-003 | TYS-004 | NDB-006, NKC-S-009, NKC-S-002, NKC-O-014, NKC-O-004 |
| name | 0 | 0.00 | 50 | string | Agence Assaba 3 | Agence Trarza 5 | Agence Dakhlet Nouadhibou 6, Agence Nouakchott-Sud 9, Agence Nouakchott-Sud 2, Agence Nouakchott-Ouest 14, Agence Nouakchott-Ouest 4 |
| wilaya_id | 0 | 0.00 | 12 | integer | 1 | 9 | 4, 3, 2, 1, 15 |
| wilaya_name | 0 | 0.00 | 12 | string | Assaba | Trarza | Dakhlet Nouadhibou, Nouakchott-Sud, Nouakchott-Ouest, Nouakchott-Nord, Tiris Zemmour |
| moughataa_id | 0 | 0.00 | 20 | integer | 1 | 9 | 10, 8, 5, 7, 2 |
| moughataa_name | 50 | 100.00 | 0 | empty |  |  |  |
| address | 0 | 0.00 | 41 | string | Rue 10, undefined | Rue 97, undefined | Rue 2, undefined, Rue 36, undefined, Rue 90, undefined, Rue 29, undefined, Rue 95, undefined |
| latitude | 0 | 0.00 | 1 | float | NaN | NaN | NaN |
| longitude | 0 | 0.00 | 1 | float | NaN | NaN | NaN |
| phone | 0 | 0.00 | 50 | integer | +22222070629 | +22249833019 | +22223138435, +22225184775, +22233502834, +22222956224, +22236911728 |
| email | 0 | 0.00 | 50 | string | agence.asb003@nafadpay.mr | agence.tys004@nafadpay.mr | agence.ndb006@nafadpay.mr, agence.nkcs009@nafadpay.mr, agence.nkcs002@nafadpay.mr, agence.nkco014@nafadpay.mr, agence.nkco004@nafadpay.mr |
| opening_hours | 0 | 0.00 | 1 | string | 08:00-18:00 | 08:00-18:00 | 08:00-18:00 |
| status | 0 | 0.00 | 2 | string | ACTIVE | INACTIVE | ACTIVE, INACTIVE |
| tier | 0 | 0.00 | 3 | string | BRONZE | SILVER | BRONZE, GOLD, SILVER |
| float_balance | 0 | 0.00 | 50 | integer | 1330000 | 955000 | 2824000, 3880000, 2620000, 1501000, 4675000 |
| max_float | 0 | 0.00 | 3 | integer | 10000000 | 5000000 | 2000000, 10000000, 5000000 |
| license_number | 0 | 0.00 | 50 | string | LIC-000001 | LIC-000099 | LIC-000063, LIC-000051, LIC-000044, LIC-000033, LIC-000023 |
| license_expiry | 0 | 0.00 | 49 | date/datetime | 2025-01-12 | 2027-12-20 | 2027-01-04, 2026-08-21, 2027-08-21, 2027-12-20, 2025-12-04 |
| created_at | 0 | 0.00 | 50 | date/datetime | 2020-01-08T01:14:16.796Z | 2023-12-20T19:17:14.853Z | 2020-06-24T08:28:57.793Z, 2020-07-21T20:28:05.812Z, 2022-02-07T15:54:41.921Z, 2022-06-25T01:51:14.292Z, 2023-06-03T12:22:27.241Z |

## reference_categories.csv

- Rows: 13
- Columns: 7

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 13 | integer | 1 | 9 | 1, 2, 3, 4, 5 |
| code | 0 | 0.00 | 13 | string | ALM | TRN | ALM, RST, TRN, TEL, CRB |
| mcc | 0 | 0.00 | 13 | integer | 4121 | 8211 | 5411, 5812, 4121, 4812, 5541 |
| label | 13 | 100.00 | 0 | empty |  |  |  |
| description | 13 | 100.00 | 0 | empty |  |  |  |
| avg_min | 0 | 0.00 | 8 | integer | 1000 | 5000 | 200, 300, 500, 1000, 2000 |
| avg_max | 0 | 0.00 | 9 | integer | 10000 | 500000 | 5000, 3000, 10000, 20000, 50000 |

## reference_tx_types.csv

- Rows: 8
- Columns: 8

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 8 | integer | 1 | 8 | 1, 2, 3, 4, 5 |
| code | 0 | 0.00 | 8 | string | AIR | WIT | DEP, WIT, TRF, PAY, BIL |
| label | 8 | 100.00 | 0 | empty |  |  |  |
| description | 8 | 100.00 | 0 | empty |  |  |  |
| requires_destination | 0 | 0.00 | 1 | string | false | false | false |
| requires_merchant | 0 | 0.00 | 1 | string | false | false | false |
| requires_agency | 0 | 0.00 | 1 | string | false | false | false |
| is_credit | 0 | 0.00 | 1 | string | false | false | false |

## reference_wilayas.csv

- Rows: 15
- Columns: 8

| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |
|---|---:|---:|---:|---|---|---|---|
| id | 0 | 0.00 | 15 | integer | 1 | 9 | 1, 2, 3, 4, 5 |
| code | 0 | 0.00 | 15 | string | ADR | TYS | NKC-N, NKC-O, NKC-S, NDB, TRZ |
| name | 0 | 0.00 | 15 | string | Adrar | Trarza | Nouakchott-Nord, Nouakchott-Ouest, Nouakchott-Sud, Dakhlet Nouadhibou, Trarza |
| capital | 0 | 0.00 | 15 | string | Akjoujt | Zouerate | Dar Naim, Tevragh-Zeina, Arafat, Nouadhibou, Rosso |
| latitude | 15 | 100.00 | 0 | empty |  |  |  |
| longitude | 15 | 100.00 | 0 | empty |  |  |  |
| population | 0 | 0.00 | 15 | integer | 123000 | 80000 | 366000, 163000, 435000, 123000, 272000 |
| economic_weight | 0 | 0.00 | 9 | float | 0.01 | 0.25 | 0.2, 0.25, 0.15, 0.12, 0.05 |

