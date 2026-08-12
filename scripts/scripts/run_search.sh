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

# Determine base output subdirectory name
if [[ "${SEARCH_MODE}" == "survey" ]]; then
  BASE_SUBDIR="survey_pass"
elif [[ "${SEARCH_MODE}" == "firstpass" ]]; then
  BASE_SUBDIR="first_pass"
elif [[ "${SEARCH_MODE}" == "secondpass" ]]; then
  BASE_SUBDIR="second_pass"
else
  echo "ERROR: Unknown SEARCH_MODE='${SEARCH_MODE}'" >&2
  echo "Valid values: 'survey', 'firstpass' (or 'first_pass'), 'secondpass' (or 'second_pass')" >&2
  exit 1
fi

# Apply out_suffix if specified
if [[ -n "${OUT_SUFFIX:-}" ]]; then
  OUT_SUBDIR="${OUT_DIR}/${BASE_SUBDIR}_${OUT_SUFFIX}"
else
  OUT_SUBDIR="${OUT_DIR}/${BASE_SUBDIR}"
fi

# Create empirical_library for firstpass
if [[ "${SEARCH_MODE}" == "firstpass" ]]; then
  mkdir -p "${OUT_SUBDIR}/empirical_library"
fi

# Set QUANT_DIR if not specified
if [[ -z "${QUANT_DIR:-}" ]]; then
  QUANT_DIR="${OUT_SUBDIR}/quant"
fi

mkdir -p "${QUANT_DIR}"
mkdir -p "${OUT_SUBDIR}/logs"
mkdir -p "${OUT_SUBDIR}/reports"

# Convert FILE_CFG array to a delimited string for export (arrays can't be exported)
if [[ ${#FILE_CFG[@]} -gt 0 ]]; then
  FILE_CFG_STR=$(IFS='|'; echo "${FILE_CFG[*]}")
else
  FILE_CFG_STR=""
fi

export FASTA SEARCH_CFG OUT_DIR THREADS SPECLIB FILE_CFG_STR OUT_SUBDIR SEARCH_MODE QUANT_DIR

sbatch \
  --job-name="${DATE}_${EXPERIMENT_NAME}_${SEARCH_MODE}" \
  --output="${OUT_SUBDIR}/logs/%x_%j.txt" \
  --error="${OUT_SUBDIR}/logs/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  search.sh