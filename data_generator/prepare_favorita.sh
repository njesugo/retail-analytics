#!/usr/bin/env bash
# =============================================================
# prepare_favorita.sh
# Prépare les fichiers Favorita pour le chargement dans Snowflake :
#   - history/   : 2016-01-01 -> 2017-06-30, découpé en morceaux (backfill)
#   - daily/     : un fichier par jour à partir du 2017-07-01 (flux Airflow)
#   - reference/ : stores, items, holidays_events, oil, transactions
# Usage : bash data_generator/prepare_favorita.sh [SRC_DIR] [OUT_DIR]
# =============================================================
set -euo pipefail

SRC_DIR="${1:-$HOME/data/favorita}"
OUT_DIR="${2:-$HOME/data/favorita/landing}"
HISTORY_START="2016-01-01"
DAILY_START="2017-07-01"
CHUNK_LINES=5000000

# Repartir de zéro : le script est rejouable.
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/history" "$OUT_DIR/daily" "$OUT_DIR/reference"

export HEADER
HEADER=$(head -1 "$SRC_DIR/train.csv")

# Un seul passage sur train.csv (4,7 Go) :
#  - avant HISTORY_START      -> ignoré
#  - avant DAILY_START        -> sortie standard -> split en morceaux
#  - à partir de DAILY_START  -> un fichier par jour
echo "Découpage de train.csv..."
awk -F, -v hs="$HISTORY_START" -v ds="$DAILY_START" \
        -v out="$OUT_DIR/daily" -v h="$HEADER" '
  NR == 1     { next }
  $2 < hs     { next }
  $2 < ds     { print; next }
  {
    f = out "/train_" $2 ".csv"
    if (!(f in seen)) { print h > f; seen[f] = 1 }
    print > f
  }
' "$SRC_DIR/train.csv" \
| split -l "$CHUNK_LINES" -d -a 3 --additional-suffix=.csv \
        --filter='{ echo "$HEADER"; cat; } > "$FILE"' \
        - "$OUT_DIR/history/train_history_"

echo "Copie des référentiels..."
for t in stores items holidays_events oil transactions; do
  cp "$SRC_DIR/$t.csv" "$OUT_DIR/reference/"
done

# Contrôle de réconciliation : lignes produites = lignes attendues.
count_rows() {   # lignes de données (hors en-têtes) d'un ensemble de fichiers
  local files=("$@")
  echo $(( $(cat "${files[@]}" | wc -l) - ${#files[@]} ))
}
hist=$(count_rows "$OUT_DIR"/history/*.csv)
daily=$(count_rows "$OUT_DIR"/daily/*.csv)
expected=$(awk -F, -v hs="$HISTORY_START" 'NR > 1 && $2 >= hs' "$SRC_DIR/train.csv" | wc -l)

echo "Historique : $hist lignes en $(ls "$OUT_DIR"/history | wc -l) fichiers"
echo "Quotidien  : $daily lignes en $(ls "$OUT_DIR"/daily | wc -l) fichiers"
echo "Attendu    : $expected lignes"
if [ $((hist + daily)) -eq "$expected" ]; then echo "OK : réconciliation"; else echo "ERREUR : écart"; exit 1; fi
