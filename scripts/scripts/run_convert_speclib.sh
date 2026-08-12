#!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# Require param file as argument
if [[ $# -eq 0 ]]; then
  echo "Error: Param file required" >&2
  echo "Usage: $0 <param.yaml>" >&2
  exit 1
fi

RUN_PARAM="$1"

if [[ ! -f "${RUN_PARAM}" ]]; then
  echo "Error: Param file '${RUN_PARAM}' not found" >&2
  exit 1
fi

# Load configuration from YAML
eval "$(python3 parse_run_param.py "${RUN_PARAM}")"
LOGDIR="${OUT_DIR}/logs"

SPECLIB_TAG="$(basename "${SPECLIB}" .speclib)"

export SPECLIB OUT_DIR THREADS LOGDIR SPECLIB_TAG
sbatch \
  --job-name="${DATE}_${SPECLIB_TAG}_convert" \
  --output="${LOGDIR}/%x_%j.txt" \
  --error="${LOGDIR}/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  convert_speclibtoparquet.sh