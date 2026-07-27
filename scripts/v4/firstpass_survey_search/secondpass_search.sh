#!/bin/bash

set -euo pipefail

module load diann/2.6.1

MASS_ACC=$(grep -E '^--mass-acc\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
MASS_ACC_MS1=$(grep -E '^--mass-acc-ms1\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
WINDOW=$(grep -E '^--window\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")

# Check all required parameters
ERRORS=()
[[ $(echo "$MASS_ACC == 0" | bc -l) -eq 1 ]] && ERRORS+=("--mass-acc (current: ${MASS_ACC})")
[[ $(echo "$MASS_ACC_MS1 == 0" | bc -l) -eq 1 ]] && ERRORS+=("--mass-acc-ms1 (current: ${MASS_ACC_MS1})")
[[ $(echo "$WINDOW == 0" | bc -l) -eq 1 ]] && ERRORS+=("--window (current: ${WINDOW})")

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "ERROR: The following parameters must be non-zero in ${SEARCH_CFG}:"
  printf '  %s\n' "${ERRORS[@]}"
  exit 1
fi

echo "Parameters validated: MASS_ACC=${MASS_ACC}, MASS_ACC_MS1=${MASS_ACC_MS1}, WINDOW=${WINDOW}"

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