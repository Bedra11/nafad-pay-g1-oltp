# G1 - Core Banking Team : Base OLTP PostgreSQL

## Rôle dans l'entreprise

Vous êtes les **Core Banking Backend Engineers**. Votre base stocke chaque centime. Si elle tombe, perd ou corrompt une transaction, la fintech coule. Vous êtes l'équipe la plus proche de la comptabilité - et donc la plus exigeante sur la qualité.

## Objectif en 10 jours

1. Concevoir un schéma relationnel 3NF sur PostgreSQL 16
2. Tourner en Docker Compose avec les CSV fournis chargés
3. Tests techniques (perf, concurrence) + tests métier (idempotence, invariants monétaires)
4. Deux documents d'architecture **AWS** : Early Stage et At Scale
5. Déploiement test sur AWS RDS (compte sandbox fourni)

Référez-vous à `PROJET_NAFAD_PAY.html` à la racine pour le planning détaillé, la grille d'évaluation et le template d'archi.

## Données fournies

| Fichier | Lignes | Colonnes | Notes |
|---|---|---|---|
| `users_sample.csv` | 1 000 | 22 | `email` vide à 59 %, `moughataa_name` et `kyc_level` vides à 100 % |
| `accounts_sample.csv` | 1 099 | 16 | `account_type_label` vide à 100 % |
| `transactions_sample.csv` | 10 000 | 40 | Colonnes clés : `idempotency_key`, `balance_before/after`, `node_id`, `processing_node`, `sequence_number` |
| `merchants_sample.csv` | 100 | 26 | Références aux 13 catégories et 15 wilayas |
| `agencies_sample.csv` | 50 | 20 | Agences avec `float_balance`, `tier`, `license_number` |

## Anomalies intentionnelles mesurées

| Anomalie | Volume | Traitement attendu |
|---|---|---|
| Références `source/destination user/account` orphelines | **4 383 tx (43,8 %)** soit **8 766 refs cumulées (87,7 %)** | Zone quarantine ou rejet strict, à justifier |
| `idempotency_key` en doublon | **2 682 clés (26,8 % - 6 416 tx affectées)** | Contrainte UNIQUE + dedup à l'insertion |
| FAILED avec `balance_before = balance_after` (invariant OK) | 3 684 / 3 712 | Bon comportement |
| **FAILED avec `balance_before ≠ balance_after`** (bug des données) | **28** | À flagger et rejeter en staging |
| `node_id ≠ processing_node` | 8 006 (80 %) | À respecter (tx initiée sur un nœud, traitée par un autre) |
| Trous dans `sequence_number` par compte | **945 / 945 comptes avec seq (100 %)** | Pédagogique : la perte de séquence n'est pas fatale |

## Livrables attendus

1. Document d'architecture **Early Stage** (1-2 pages, PDF ou MD) - MVP sur AWS RDS Single-AZ ou EC2 bare Postgres
2. Document d'architecture **At Scale** (2-3 pages) - AWS RDS Multi-AZ + read replicas + partitionnement + RDS Proxy + PITR cross-region
3. `docker-compose.yml` + `sql/ddl.sql` + `sql/load.sql` + `tests/`
4. Rapport de tests techniques (EXPLAIN ANALYZE + bench concurrence)
5. Rapport de tests métier (invariants respectés sur les 10 000 tx chargées)
6. README du repo reproductible (`make up`, `make test` doivent marcher en 2 commandes)

## Guidelines techniques

### Docker Compose minimal

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: nafadpay
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports: ["5432:5432"]
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d
```

### Schéma 3NF attendu (tables principales)

- `users (id PK, nni UNIQUE, phone UNIQUE, wilaya_id FK, status, kyc_level, ...)`
- `accounts (id PK, user_id FK, account_number UNIQUE, balance, currency, status, ...)`
- `merchants (id PK, code UNIQUE, category_code FK, wilaya_id FK, ...)`
- `agencies (id PK, code UNIQUE, wilaya_id FK, float_balance, license_number, ...)`
- `agents (id PK, agency_id FK, nni UNIQUE, role, ...)`
- `transactions (id PK, reference UNIQUE, idempotency_key UNIQUE, source_account_id FK, destination_account_id FK, merchant_id FK NULL, agency_id FK NULL, amount, fee, status, balance_before, balance_after, node_id, processing_node, sequence_number, created_at, completed_at, ...)`
- `fees (id PK, transaction_id FK, fee_type, amount, ...)`

### Contraintes obligatoires

- `CHECK (amount > 0)`, `CHECK (fee >= 0)`, `CHECK (balance_before >= 0)`, `CHECK (balance_after >= 0)`
- `CHECK (status IN ('SUCCESS','FAILED','PENDING'))`
- `CHECK (currency = 'MRU')`
- `UNIQUE (idempotency_key)`, `UNIQUE (reference)`
- `CHECK (balance_after = balance_before)` pour les `FAILED`

### Index justifiés (5 suffisent)

1. `(source_account_id, created_at DESC)` - historique par compte
2. `(reference)` - lookup par référence externe
3. `(transaction_date, status)` - reporting quotidien
4. `(node_id, sequence_number)` - ordonnancement par nœud
5. `(merchant_id, created_at DESC)` - partial `WHERE merchant_id IS NOT NULL`

### Tests métier (minimum requis)

```sql
-- Test 1 : unicité idempotency_key
INSERT ... sur une clé existante → DOIT échouer

-- Test 2 : invariant solde
SELECT COUNT(*) FROM transactions
WHERE status='SUCCESS' AND balance_after != balance_before - amount - fee
  AND transaction_type IN ('TRF','WIT','PAY','BIL');
-- DOIT retourner 0

-- Test 3 : FAILED ne bouge pas le solde
SELECT COUNT(*) FROM transactions
WHERE status='FAILED' AND balance_after != balance_before;
-- DOIT retourner 0
```

### Tests techniques

- `EXPLAIN ANALYZE` sur les 5 requêtes les plus fréquentes, chaque plan doit utiliser un index
- Bench d'insertion concurrente : 10 workers qui insèrent chacun 1 000 tx, mesurer TPS et deadlocks
- Test de contrainte UNIQUE sur `idempotency_key` avec 2 writers simultanés

## Architecture AWS - points obligatoires

| Dimension | Early Stage | At Scale |
|---|---|---|
| **Compute DB** | RDS PostgreSQL Single-AZ `db.t4g.medium` | RDS Multi-AZ `db.m7g.large` + 2 read replicas |
| **Réseau** | VPC privé, subnet DB isolé | + PrivateLink, + VPC endpoints |
| **Sécurité** | KMS default, Secrets Manager, TLS enforced | + rotation 30 j, audit pgaudit, WAF devant l'API |
| **Backup** | Snapshots quotidiens, PITR 7 j | + cross-region copies vers `eu-west-1` |
| **Scale** | 1 instance | Partitionnement natif par mois sur `transaction_date`, RDS Proxy pour le pooling |
| **Observabilité** | CloudWatch default | Enhanced Monitoring + Performance Insights + alarmes p99 |

### Threat model attendu (top 3)

1. **API backend compromise** (credentials `app_writer` exposés) → IAM conditions + rate limiting + audit pgaudit qui détecte les patterns anormaux
2. **`DROP TABLE` accidentel par un dev** → aucun compte humain avec `DROP`, passage obligatoire par CI/CD, snapshots immutables (AWS Backup Vault Lock)
3. **Snapshot S3 qui fuite** → chiffrement KMS obligatoire sur snapshots, IAM policy qui interdit la copie cross-account non approuvée

## Correspondance des datacenters fictifs

Les données contiennent `NDB-NODE-*`, `NKC-NODE-*`, `DC-*` qui sont **fictifs**. Mappage vers les providers réels :

| Donnée | AWS (implémentation) | GCP (comparaison) | Hetzner (comparaison bare-metal) |
|---|---|---|---|
| `DC-NKC-PRIMARY` | `eu-west-3a` | `europe-west9-a` | `fsn1` (Falkenstein) |
| `DC-NKC-SECONDARY` | `eu-west-3b` | `europe-west9-b` | `nbg1` (Nuremberg) |
| `DC-NDB` | `eu-west-3c` | `europe-west9-c` | `hel1` (Helsinki, DR éloigné) |

Votre implémentation cible est **AWS**. GCP et Hetzner sont listés pour vous permettre de justifier votre choix (coût, services managés, proximité géographique).

## Contexte métier

- Monnaie : MRU (Ouguiya mauritanien)
- NNI : 10 chiffres, unique par utilisateur
- Téléphone : `+222XXXXXXXX`
- 15 wilayas (référence dans `../shared/reference_wilayas.csv`)
- 8 types de transaction : DEP, WIT, AIR, BIL, SAL, REV, TRF, PAY
