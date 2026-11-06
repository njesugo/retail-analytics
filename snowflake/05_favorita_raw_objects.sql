-- =============================================================
-- 05_favorita_raw_objects.sql
-- Objets de chargement de la source Favorita : format, stage, tables.
-- Exécuté avec le rôle LOADER :
--   snow sql -c airflow_svc -f snowflake/05_favorita_raw_objects.sql
-- RAW reste permissif (pas de NOT NULL) : la qualité est testée dans dbt.
-- =============================================================

USE ROLE LOADER;
USE WAREHOUSE LOADING_WH;
USE SCHEMA RAW.FAVORITA;

-- Format des fichiers. items.csv contient "LIQUOR,WINE,BEER" :
-- une virgule DANS une valeur, d'où FIELD_OPTIONALLY_ENCLOSED_BY.
CREATE FILE FORMAT IF NOT EXISTS CSV_FAVORITA
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
  COMMENT = 'CSV Kaggle Favorita (en-tete, virgule, guillemets optionnels)';

-- Zone de dépôt : history/, daily/, reference/
CREATE STAGE IF NOT EXISTS LANDING
  FILE_FORMAT = CSV_FAVORITA
  COMMENT = 'Zone de depot des fichiers Favorita';

-- Faits : ventes quotidiennes par magasin et produit (append-only).
CREATE TABLE IF NOT EXISTS TRAIN (
  id            NUMBER(38,0),
  date          DATE,
  store_nbr     NUMBER(38,0),
  item_nbr      NUMBER(38,0),
  unit_sales    NUMBER(12,3),   -- 3 décimales max (produits au poids), négatif = retour
  onpromotion   BOOLEAN,        -- 'True' / 'False' dans le fichier
  _source_file  VARCHAR,
  _loaded_at    TIMESTAMP_LTZ
);

-- Référentiels (rechargés en totalité).
CREATE TABLE IF NOT EXISTS STORES (
  store_nbr     NUMBER(38,0),
  city          VARCHAR,
  state         VARCHAR,
  type          VARCHAR,
  cluster       NUMBER(38,0),
  _source_file  VARCHAR,
  _loaded_at    TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS ITEMS (
  item_nbr      NUMBER(38,0),
  family        VARCHAR,
  class         NUMBER(38,0),
  perishable    NUMBER(1,0),
  _source_file  VARCHAR,
  _loaded_at    TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS HOLIDAYS_EVENTS (
  date          DATE,
  type          VARCHAR,
  locale        VARCHAR,
  locale_name   VARCHAR,
  description   VARCHAR,
  transferred   BOOLEAN,
  _source_file  VARCHAR,
  _loaded_at    TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OIL (
  date          DATE,
  dcoilwtico    NUMBER(10,2),   -- vide les jours sans cotation
  _source_file  VARCHAR,
  _loaded_at    TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS TRANSACTIONS (
  date          DATE,
  store_nbr     NUMBER(38,0),
  transactions  NUMBER(38,0),
  _source_file  VARCHAR,
  _loaded_at    TIMESTAMP_LTZ
);
