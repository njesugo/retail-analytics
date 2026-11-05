-- =============================================================
-- 02_databases.sql
-- Bases et schémas. Convention : RAW = brut, ANALYTICS = dbt.
-- =============================================================

USE ROLE SYSADMIN;

-- Données brutes : un schéma par source.
CREATE DATABASE IF NOT EXISTS RAW
  COMMENT = 'Donnees brutes, telles que recues des sources';

CREATE SCHEMA IF NOT EXISTS RAW.FAVORITA
  COMMENT = 'Source reelle : Kaggle Corporacion Favorita';

CREATE SCHEMA IF NOT EXISTS RAW.ENRICHMENT
  COMMENT = 'Donnees SIMULEES : prix, couts, remises, stocks (hypotheses)';

-- Données transformées : les schémas sont créés par dbt.
CREATE DATABASE IF NOT EXISTS ANALYTICS
  COMMENT = 'Modeles dbt (staging, intermediate, marts)';