# Source : Corporación Favorita (Kaggle)

## Origine
- Compétition Kaggle *Favorita Grocery Sales Forecasting* (enseigne de supermarchés, Équateur).
- Téléchargement : `kaggle competitions download -c favorita-grocery-sales-forecasting` (règlement à accepter).
- Fichiers non utilisés : `test.csv`, `sample_submission.csv` (artefacts de la compétition de prévision).

## Périmètre retenu
| Flux | Période | Lignes | Chargement |
|---|---|---|---|
| Historique | 2016-01-01 → 2017-06-30 | 54 184 003 (11 fichiers) | manuel, `snowflake/06_favorita_load_history.sql` |
| Quotidien | 2017-07-01 → 2017-08-15 | 4 854 129 (46 fichiers) | Airflow (phase 4) |
| Référentiels | complet | stores 54, items 4 100, holidays 350, oil 1 218, transactions 83 488 | rechargement complet |

Pourquoi démarrer en 2016 : `onpromotion` est vide pour toutes les lignes avant le 2014-04-01
(21,6 M lignes), et 2016 → 2017 suffit pour comparer une année à l'autre.

## Préparation
`bash data_generator/prepare_favorita.sh` découpe `train.csv` en `history/` (morceaux de 5 M lignes,
chargés en parallèle) et `daily/` (un fichier par jour), puis contrôle que le total des lignes
produites est égal au total attendu.

## Tables RAW.FAVORITA
| Table | Grain | Remarques |
|---|---|---|
| `TRAIN` | date × magasin × produit | une ligne n'existe que s'il y a eu une vente |
| `STORES` | magasin | `type` (A–E) et `cluster` : groupes de magasins comparables |
| `ITEMS` | produit | `family` = rayon ; `perishable` 0/1 |
| `HOLIDAYS_EVENTS` | date × événement | `transferred = TRUE` : jour férié déplacé, donc non chômé à cette date |
| `OIL` | date | prix du pétrole, vide les jours sans cotation |
| `TRANSACTIONS` | date × magasin | nombre de tickets |

Chaque table porte `_source_file` et `_loaded_at` (traçabilité du chargement).

## Points d'attention pour dbt
- `unit_sales` : 3 décimales au maximum (produits au poids) ; 7 795 valeurs négatives sur tout l'historique (retours).
- `onpromotion` : `True`/`False`, aucune valeur vide sur le périmètre retenu.
- `items.family` contient `"LIQUOR,WINE,BEER"` (virgule entre guillemets dans le CSV).
- Absence de ligne ≠ absence de donnée : un produit sans vente un jour donné n'a pas de ligne.
  C'est la base de la détection des ruptures.
- Doublons : `COPY INTO` évite de recharger un fichier pendant 64 jours ; un test d'unicité sur `TRAIN.id` est prévu dans dbt.

## Coût constaté
Chargement initial exécuté deux fois (test d'idempotence) : environ 0,05 crédit sur `LOADING_WH`.
