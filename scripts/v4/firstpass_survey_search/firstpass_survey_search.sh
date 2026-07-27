#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"
SURVEY=${SURVEY:-false}

# Check if MASS_ACC and MASS_ACC_MS1 are set in the config file, assume we're just setting them already
MASS_ACC=$(grep -E '^--mass-acc\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
MASS_ACC_MS1=$(grep -E '^--mass-acc-ms1\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  
if [[ $(echo "$MASS_ACC == 0" | bc -l) -eq 1 ]] || [[ $(echo "$MASS_ACC_MS1 == 0" | bc -l) -eq 1 ]]; then
  echo "ERROR: --mass-acc and --mass-acc-ms1 must be non-zero in ${SEARCH_CFG} when not in survey mode"
  exit 1
else
  echo "Mass accuracy parameters validated: MASS_ACC=${MASS_ACC}, MASS_ACC_MS1=${MASS_ACC_MS1}"
fi

# Validate mass accuracy settings
if [[ "${SURVEY}" == false ]]; then
  # Check WINDOW parameter
  WINDOW=$(grep -E '^--window\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "")
  
  if [[ -z "${WINDOW}" ]] || [[ "${WINDOW}" == "0" ]]; then
    echo "WINDOW not defined or is 0 in config - will use optimal value for the first run"
  else
    echo "Window parameter: WINDOW=${WINDOW}"
  fi
else
  # Validate window parameter is 0 or unset when in survey mode
  echo "Checking window parameter in config for survey mode..."
  
  WINDOW=$(grep -E '^--window\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  
  if [[ $(echo "$WINDOW != 0" | bc -l) -eq 1 ]]; then
    echo "ERROR: --window must be 0 or not set in ${SEARCH_CFG} when in survey mode (will be auto-determined)"
    echo "Current value: WINDOW=${WINDOW}"
    echo "Update the search config file to remove --window or set --window 0"
    exit 1
  fi
fi

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
--temp "${OUT_SUBDIR}/quant" \
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