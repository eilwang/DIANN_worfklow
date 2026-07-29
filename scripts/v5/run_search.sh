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

FASTA_TAG="$(basename "${FASTA}" .fas)"

if [[ "${SEARCH_MODE}" == "survey" ]]; then
  OUT_SUBDIR="${OUT_DIR}/survey_pass"

elif [[ "${SEARCH_MODE}" == "firstpass" ]]; then
  OUT_SUBDIR="${OUT_DIR}/first_pass"
  mkdir -p "${OUT_SUBDIR}/empirical_library"

else
  echo "ERROR: Unknown SEARCH_MODE='${SEARCH_MODE}'" >&2
  echo "Valid values: 'survey', 'firstpass' (or 'first_pass'), 'secondpass' (or 'second_pass')" >&2
  exit 1
fi

mkdir -p "${OUT_SUBDIR}/quant"
mkdir -p "${OUT_SUBDIR}/logs"
mkdir -p "${OUT_SUBDIR}/reports"

export FASTA SEARCH_CFG OUT_DIR THREADS SPECLIB FILE_CFG OUT_SUBDIR SEARCH_MODE

sbatch \
  --job-name="${DATE}_${EXPERIMENT_NAME}_${SEARCH_MODE}" \
  --output="${OUT_SUBDIR}/logs/%x_%j.txt" \
  --error="${OUT_SUBDIR}/logs/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  search.sh