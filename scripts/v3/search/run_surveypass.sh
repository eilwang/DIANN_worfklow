#!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# --- everything configurable lives here ---
EXPERIMENT_NAME="FBML009"
OUT_DIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklows/testing/test3_2pass/"

FASTA="/hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas"
SPECLIB="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklows/testing/test3_2pass/speclib/20260722_2026-07-20-sp_tr_isoforms-contam-Human_UP000005640_20260722_searchspace_tryptic_default_34977331.predicted.speclib"
FILE_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklows/testing/test3_2pass/configs/files.cfg"

SEARCH_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklows/testing/test3_2pass/configs/20260722_search_FDR1_MA15_RTprof.cfg"

CHECK_MASS_ACC=false

THREADS=32
MEM="512G"
TIME="01-00:00:00"

FASTA_TAG="$(basename "${FASTA}" .fas)"
SPECLIB_TAG="$(basename "${SPECLIB}" .predicted.speclib)"

# Create directories if they don't exist
mkdir -p "${OUT_DIR}/survey_pass/logs"

export FASTA SEARCH_CFG OUT_DIR THREADS SPECLIB FILE_CFG CHECK_MASS_ACC

sbatch \
  --job-name="${DATE}_${EXPERIMENT_NAME}_surveypass" \
  --output="${OUT_DIR}/survey_pass/logs/%x_%j.txt" \
  --error="${OUT_DIR}/survey_pass/logs/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  firstpass_search.sh