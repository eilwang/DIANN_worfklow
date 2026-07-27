#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"

#if survery windows, include this to find the optimal setting for windows
# --individual-windows 
# reccomended hard coding accuracy of 15, but if not, --individual-mass-acc

diann \
--cfg "${SEARCH_CFG}" \
--cfg "${FILE_CFG}" \
--lib "${SPECLIB}" \
--fasta "${FASTA}" \
--temp "${OUT_DIR}/first_pass/quant" \
--gen-spec-lib \
--out-lib "${OUT_DIR}/first_pass/empirical_library/${OUTNAME}.empirical.parquet" \
--out "${OUT_DIR}/first_pass/reports/report.parquet" \
--export-quant \ # include to export fragment intensities into the report for additional normalization strategies
--threads "${THREADS}" \
--verbose 1