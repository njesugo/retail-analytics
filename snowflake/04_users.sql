-- =============================================================
-- 04_users.sql
-- Utilisateurs de service (pas de mot de passe, auth par clé RSA).
-- Les clés publiques ne sont PAS versionnées : remplacer les
-- valeurs <...> uniquement au moment d'exécuter dans Snowsight.
-- =============================================================

USE ROLE USERADMIN;

CREATE USER IF NOT EXISTS AIRFLOW_SVC
  TYPE = SERVICE
  DEFAULT_ROLE = LOADER
  DEFAULT_WAREHOUSE = LOADING_WH
  COMMENT = 'Service : chargements Airflow';

CREATE USER IF NOT EXISTS DBT_SVC
  TYPE = SERVICE
  DEFAULT_ROLE = TRANSFORMER
  DEFAULT_WAREHOUSE = TRANSFORMING_WH
  COMMENT = 'Service : dbt en production (Airflow, CI)';

ALTER USER AIRFLOW_SVC SET RSA_PUBLIC_KEY = '<AIRFLOW_SVC_PUBLIC_KEY>';
ALTER USER DBT_SVC     SET RSA_PUBLIC_KEY = '<DBT_SVC_PUBLIC_KEY>';

USE ROLE SECURITYADMIN;

GRANT ROLE LOADER      TO USER AIRFLOW_SVC;
GRANT ROLE TRANSFORMER TO USER DBT_SVC;