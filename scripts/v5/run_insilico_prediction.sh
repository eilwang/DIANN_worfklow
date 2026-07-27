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
LOGDIR="${SPECLIB_DIR}/logs"

FASTA_TAG="$(basename "${FASTA}" .fas)"
SP_CONFIG_TAG="$(basename "${SEARCH_SPACE_CFG}" .cfg)"

export FASTA SEARCH_SPACE_CFG SPECLIB_DIR THREADS LOGDIR

sbatch \
  --job-name="${DATE}_${FASTA_TAG}_${SP_CONFIG_TAG}" \
  --output="${LOGDIR}/%x_%j.txt" \
  --error="${LOGDIR}/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  generate_insilico_speclib.sh