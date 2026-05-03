-- All tables + row counts across all schemas
SELECT
    schemaname                  AS schema,
    relname                     AS table_name,
    n_live_tup                  AS row_count
FROM pg_stat_user_tables
ORDER BY schemaname, n_live_tup DESC;
