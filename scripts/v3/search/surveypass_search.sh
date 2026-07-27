#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"
SURVEY=false

if [[ "${SURVEY}" == true ]]; then
  FIRST_SURVEY_FLAG="--individual-windows"
else
 FIRST_SURVEY_FLAG="
  --temp "${OUT_DIR}/first_pass/quant" \
  --gen-spec-lib \
  --out-lib "${OUT_DIR}/first_pass/empirical_library/${OUTNAME}.empirical.parquet" \
  --out "${OUT_DIR}/first_pass/reports/report.parquet" \
  --export-quant"
fi

diann \
--cfg "${SEARCH_CFG}" \
--cfg "${FILE_CFG}" \
--lib "${SPECLIB}" \
--fasta "${FASTA}" \
${FIRST_SURVEY_FLAG} \
--out "${OUT_SUBDIR}/reports/report.parquet" \
--threads "${THREADS}" \
--verbose 1 \

if [[ "${SURVEY}" == true ]]; then

# Parse scan windows and mass accuracy from log
echo ""
echo "=== Parsing DIA-NN Results ==="

# Extract scan windows (looking for "Scan window:" or "Optimal window:" patterns)
WINDOWS=$(grep -oP '(?<=window:\s)\d+(?:\.\d+)?' "${LOG_FILE}" 2>/dev/null || echo "")
if [[ -n "${WINDOWS}" ]]; then
  FIRST_WINDOW=$(echo "${WINDOWS}" | head -n1)
  MEDIAN_WINDOW=$(echo "${WINDOWS}" | sort -n | awk '{a[NR]=$1} END {print (NR%2==1)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2}')
  AVERAGE_WINDOW=$(echo "${WINDOWS}" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
  
  echo "Scan Window (first): ${FIRST_WINDOW}"
  echo "All Scan Windows: ${WINDOWS}" | tr '\n' ' '
  echo ""
  echo "Median Window: ${MEDIAN_WINDOW}"
  echo "Average Window: ${AVERAGE_WINDOW}"
else
  echo "Scan Windows - Not found in log"
fi

echo "==========================="