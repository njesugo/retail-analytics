-- =============================================================
-- 06_favorita_load_history.sql
-- Chargement initial : historique des ventes + référentiels.
-- Le flux quotidien (daily/) sera chargé par Airflow.
-- Exécuté avec le rôle LOADER :
--   snow sql -c airflow_svc -f snowflake/06_favorita_load_history.sql \
--     -D "landing_dir=$HOME/data/favorita/landing"
-- =============================================================

USE ROLE LOADER;
USE WAREHOUSE LOADING_WH;
USE SCHEMA RAW.FAVORITA;

-- 1) Envoi des fichiers dans le stage (compressés en gzip par le client).
PUT 'file://<% landing_dir %>/history/*.csv' @LANDING/history/
  PARALLEL = 8 AUTO_COMPRESS = TRUE OVERWRITE = FALSE;

PUT 'file://<% landing_dir %>/reference/*.csv' @LANDING/reference/
  PARALLEL = 8 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- 2) Faits : COPY INTO mémorise les fichiers déjà chargés (64 jours),
--    donc rejouer ce script ne crée pas de doublons.
COPY INTO TRAIN (id, date, store_nbr, item_nbr, unit_sales, onpromotion, _source_file, _loaded_at)
FROM (
  SELECT $1, $2, $3, $4, $5, $6, METADATA$FILENAME, CURRENT_TIMESTAMP()
  FROM @LANDING/history/
)
PATTERN = '.*train_history_[0-9]+[.]csv[.]gz'
ON_ERROR = ABORT_STATEMENT;

-- 3) Référentiels : rechargement complet (TRUNCATE + FORCE),
--    car une nouvelle version du fichier remplace l'ancienne.
TRUNCATE TABLE STORES;
COPY INTO STORES (store_nbr, city, state, type, cluster, _source_file, _loaded_at)
FROM (SELECT $1, $2, $3, $4, $5, METADATA$FILENAME, CURRENT_TIMESTAMP()
      FROM @LANDING/reference/stores.csv.gz)
FORCE = TRUE ON_ERROR = ABORT_STATEMENT;

TRUNCATE TABLE ITEMS;
COPY INTO ITEMS (item_nbr, family, class, perishable, _source_file, _loaded_at)
FROM (SELECT $1, $2, $3, $4, METADATA$FILENAME, CURRENT_TIMESTAMP()
      FROM @LANDING/reference/items.csv.gz)
FORCE = TRUE ON_ERROR = ABORT_STATEMENT;

TRUNCATE TABLE HOLIDAYS_EVENTS;
COPY INTO HOLIDAYS_EVENTS (date, type, locale, locale_name, description, transferred, _source_file, _loaded_at)
FROM (SELECT $1, $2, $3, $4, $5, $6, METADATA$FILENAME, CURRENT_TIMESTAMP()
      FROM @LANDING/reference/holidays_events.csv.gz)
FORCE = TRUE ON_ERROR = ABORT_STATEMENT;

TRUNCATE TABLE OIL;
COPY INTO OIL (date, dcoilwtico, _source_file, _loaded_at)
FROM (SELECT $1, $2, METADATA$FILENAME, CURRENT_TIMESTAMP()
      FROM @LANDING/reference/oil.csv.gz)
FORCE = TRUE ON_ERROR = ABORT_STATEMENT;

TRUNCATE TABLE TRANSACTIONS;
COPY INTO TRANSACTIONS (date, store_nbr, transactions, _source_file, _loaded_at)
FROM (SELECT $1, $2, $3, METADATA$FILENAME, CURRENT_TIMESTAMP()
      FROM @LANDING/reference/transactions.csv.gz)
FORCE = TRUE ON_ERROR = ABORT_STATEMENT;

-- 4) Réconciliation : comparer avec les lignes des fichiers source.
SELECT 'TRAIN' AS table_name, COUNT(*) AS row_count, 54184003 AS expected FROM TRAIN
UNION ALL SELECT 'STORES',          COUNT(*), 54    FROM STORES
UNION ALL SELECT 'ITEMS',           COUNT(*), 4100  FROM ITEMS
UNION ALL SELECT 'HOLIDAYS_EVENTS', COUNT(*), 350   FROM HOLIDAYS_EVENTS
UNION ALL SELECT 'OIL',             COUNT(*), 1218  FROM OIL
UNION ALL SELECT 'TRANSACTIONS',    COUNT(*), 83488 FROM TRANSACTIONS;
