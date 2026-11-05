-- =============================================================
-- 01_warehouses.sql
-- Entrepôts de calcul par usage + garde-fou budgétaire.
-- Rejouable : IF NOT EXISTS ne recrée rien si l'objet existe déjà.
-- =============================================================

-- 1) Garde-fou de coûts : seul ACCOUNTADMIN peut gérer les resource monitors.
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS RM_MONTHLY_BUDGET
  WITH CREDIT_QUOTA = 50
       FREQUENCY = MONTHLY
       START_TIMESTAMP = IMMEDIATELY
       TRIGGERS ON 75 PERCENT DO NOTIFY
                ON 90 PERCENT DO SUSPEND
                ON 100 PERCENT DO SUSPEND_IMMEDIATE;

-- Appliqué au niveau du compte : couvre TOUS les warehouses.
ALTER ACCOUNT SET RESOURCE_MONITOR = RM_MONTHLY_BUDGET;

-- 2) Warehouses : création par SYSADMIN, le rôle qui possède les objets.
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS LOADING_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Chargement des donnees brutes (Airflow)';

CREATE WAREHOUSE IF NOT EXISTS TRANSFORMING_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Transformations dbt';

CREATE WAREHOUSE IF NOT EXISTS REPORTING_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Requetes Tableau';

-- Le warehouse fourni par défaut avec l'essai : on limite aussi sa consommation.
ALTER WAREHOUSE IF EXISTS COMPUTE_WH SET AUTO_SUSPEND = 60;