# Retail Analytics : performance des ventes et des promotions

## Contexte métier
Le directeur commercial d'une enseigne multi-magasins veut savoir :
1. Quels magasins et quels rayons sous-performent ?
2. Les promotions rapportent-elles vraiment de la marge ?
3. Où les ruptures de stock font-elles perdre du chiffre d'affaires ?

## Données
- **Source réelle** : Kaggle, *Corporación Favorita Grocery Sales Forecasting* (périmètre 2016 à 2017).
  Ventes quotidiennes par magasin et par produit, indicateur de promotion, magasins, produits, jours fériés.
- **Enrichissements simulés** (hypothèses documentées, stockées séparément) :
  prix de vente, prix d'achat, niveau de remise des promotions, niveaux de stock.

## Stack
| Brique | Rôle |
|---|---|
| Snowflake | Entrepôt de données (RAW → STAGING → MARTS) |
| dbt | Transformations, tests, documentation |
| Airflow (Docker) | Orchestration quotidienne |
| Tableau | Tableaux de bord pour le directeur commercial |
| GitHub Actions | CI : `dbt build` à chaque pull request |

## Structure du dépôt
| Dossier | Contenu |
|---|---|
| `data_generator/` | Préparation de Favorita et génération des enrichissements |
| `snowflake/` | Scripts d'administration (rôles, entrepôts, bases) |
| `dbt/` | Projet dbt |
| `airflow/` | DAG et `docker-compose` |
| `tableau/` | Classeurs et captures d'écran |
| `docs/` | Documentation et architecture |

## Démarrage
_À compléter au fil du projet._
