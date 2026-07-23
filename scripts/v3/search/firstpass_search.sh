#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"

diann \
--cfg "${SEARCH_CFG}" \
--cfg "${FILE_CFG}" \
--lib "${SPECLIB}" \
--fasta "${FASTA}" \
--temp "${OUT_DIR}/first_pass/quant" \
--gen-spec-lib \
--out-lib "${OUT_DIR}/first_pass/empirical_library/${OUTNAME}_emp-lib.parquet" \
--out "${OUT_DIR}/first_pass/reports/report.parquet" \
--threads "${THREADS}" \
--verbose 1