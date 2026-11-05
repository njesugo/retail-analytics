-- =============================================================
-- 03_roles.sql
-- Rôles fonctionnels et droits (principe du moindre privilège).
-- =============================================================

-- 1) Création des rôles : c'est le métier de USERADMIN.
USE ROLE USERADMIN;

CREATE ROLE IF NOT EXISTS LOADER      COMMENT = 'Chargement des donnees brutes (Airflow)';
CREATE ROLE IF NOT EXISTS TRANSFORMER COMMENT = 'Transformations (dbt)';
CREATE ROLE IF NOT EXISTS REPORTER    COMMENT = 'Lecture des marts (Tableau)';

-- 2) Distribution des droits : c'est le métier de SECURITYADMIN.
USE ROLE SECURITYADMIN;

-- Hiérarchie : SYSADMIN hérite des rôles fonctionnels,
-- pour que les administrateurs voient les objets créés par ces rôles.
GRANT ROLE LOADER      TO ROLE SYSADMIN;
GRANT ROLE TRANSFORMER TO ROLE SYSADMIN;
GRANT ROLE REPORTER    TO ROLE SYSADMIN;

-- Chaque rôle a son propre warehouse : coûts séparés et lisibles.
GRANT USAGE ON WAREHOUSE LOADING_WH      TO ROLE LOADER;
GRANT USAGE ON WAREHOUSE TRANSFORMING_WH TO ROLE TRANSFORMER;
GRANT USAGE ON WAREHOUSE REPORTING_WH    TO ROLE REPORTER;

-- LOADER : écrit dans RAW, et nulle part ailleurs.
GRANT USAGE ON DATABASE RAW TO ROLE LOADER;
GRANT USAGE, CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA RAW.FAVORITA   TO ROLE LOADER;
GRANT USAGE, CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA RAW.ENRICHMENT TO ROLE LOADER;

-- TRANSFORMER : lit RAW (y compris les futures tables)...
GRANT USAGE  ON DATABASE RAW                       TO ROLE TRANSFORMER;
GRANT USAGE  ON ALL SCHEMAS    IN DATABASE RAW     TO ROLE TRANSFORMER;
GRANT USAGE  ON FUTURE SCHEMAS IN DATABASE RAW     TO ROLE TRANSFORMER;
GRANT SELECT ON ALL TABLES     IN DATABASE RAW     TO ROLE TRANSFORMER;
GRANT SELECT ON FUTURE TABLES  IN DATABASE RAW     TO ROLE TRANSFORMER;
GRANT SELECT ON ALL VIEWS      IN DATABASE RAW     TO ROLE TRANSFORMER;
GRANT SELECT ON FUTURE VIEWS   IN DATABASE RAW     TO ROLE TRANSFORMER;

-- ... et construit ANALYTICS : dbt crée lui-même ses schémas.
GRANT USAGE, CREATE SCHEMA ON DATABASE ANALYTICS TO ROLE TRANSFORMER;

-- REPORTER : accès à la base seulement. Les droits SELECT sur les marts
-- seront donnés par dbt (config `grants`), table par table.
GRANT USAGE ON DATABASE ANALYTICS TO ROLE REPORTER;

-- 3) Mon utilisateur reçoit les 3 rôles, pour pouvoir tester leurs droits.
SET my_user = CURRENT_USER();
GRANT ROLE LOADER      TO USER IDENTIFIER($my_user);
GRANT ROLE TRANSFORMER TO USER IDENTIFIER($my_user);
GRANT ROLE REPORTER    TO USER IDENTIFIER($my_user);