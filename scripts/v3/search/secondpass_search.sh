#!/bin/bash

set -euo pipefail

module load diann/2.6.1

diann \
--cfg "${SEARCH_CFG}" \
--cfg "${FILE_CFG}" \
--lib "${EMPLIB}" \
--fasta "${FASTA}" \
--temp "${OUT_DIR}/first_pass/quant" \
--out "${OUT_DIR}/second_pass/secondpass_report.parquet" \
--matrices \
--threads "${THREADS}" \
--verbose 1 \