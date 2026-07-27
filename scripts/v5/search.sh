#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"
SURVEY=${SURVEY:-false}

# Validate search parameters based on mode
if [[ "${SEARCH_MODE}" == "survey" ]]; then
  # Survey mode: forcibly set window to 0 by editing the config
  WINDOW=$(grep -E '^--window\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  
  if [[ $(echo "$WINDOW != 0" | bc -l) -eq 1 ]]; then
    echo "WARNING: --window=${WINDOW} found in ${SEARCH_CFG}"
    echo "Survey mode: creating modified config with --window 0 (will be auto-determined per run)"
    
    # Create temporary modified config with --window forced to 0, preserving all other flags
    TEMP_SEARCH_CFG="${OUT_SUBDIR}/logs/search_cfg_modified_${SLURM_JOB_ID}.cfg"
    sed -E 's/^(--window\s+)[0-9.]+(.*)$/\10\2/' "${SEARCH_CFG}" > "${TEMP_SEARCH_CFG}"
    SEARCH_CFG_TO_USE="${TEMP_SEARCH_CFG}"
  else
    echo "Survey mode: --window is 0 or not set (will be auto-determined per run)"
    SEARCH_CFG_TO_USE="${SEARCH_CFG}"
  fi
  
  WINDOW_OVERRIDE=""

elif [[ "${SEARCH_MODE}" == "firstpass" ]]; then
  # First pass: validate mass accuracy parameters, window can be 0 (will be optimized)
  SEARCH_CFG_TO_USE="${SEARCH_CFG}"
  WINDOW_OVERRIDE=""
  MASS_ACC=$(grep -E '^--mass-acc\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  MASS_ACC_MS1=$(grep -E '^--mass-acc-ms1\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  WINDOW=$(grep -E '^--window\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  
  # Validate mass accuracy parameters
  if [[ $(echo "$MASS_ACC == 0" | bc -l) -eq 1 ]] || [[ $(echo "$MASS_ACC_MS1 == 0" | bc -l) -eq 1 ]]; then
    echo "ERROR: --mass-acc and --mass-acc-ms1 must be non-zero in ${SEARCH_CFG}"
    echo "Current values: --mass-acc=${MASS_ACC}, --mass-acc-ms1=${MASS_ACC_MS1}"
    exit 1
  fi
  
  if [[ -z "${WINDOW}" ]] || [[ $(echo "$WINDOW == 0" | bc -l) -eq 1 ]]; then
    echo "First pass: --window not set or is 0, will use optimal value"
  else
    echo "First pass: --window=${WINDOW}"
  fi
  
  echo "Parameters validated: --mass-acc=${MASS_ACC}, --mass-acc-ms1=${MASS_ACC_MS1}"

elif [[ "${SEARCH_MODE}" == "secondpass" ]]; then
  # Second pass: all parameters must be set and non-zero
  SEARCH_CFG_TO_USE="${SEARCH_CFG}"
  WINDOW_OVERRIDE=""
  MASS_ACC=$(grep -E '^--mass-acc\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  MASS_ACC_MS1=$(grep -E '^--mass-acc-ms1\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")
  WINDOW=$(grep -E '^--window\s+' "${SEARCH_CFG}" 2>/dev/null | awk '{print $2}' || echo "0")

  # Check all required parameters
  ERRORS=()
  [[ $(echo "$MASS_ACC == 0" | bc -l) -eq 1 ]] && ERRORS+=("--mass-acc (current: ${MASS_ACC})")
  [[ $(echo "$MASS_ACC_MS1 == 0" | bc -l) -eq 1 ]] && ERRORS+=("--mass-acc-ms1 (current: ${MASS_ACC_MS1})")
  [[ $(echo "$WINDOW == 0" | bc -l) -eq 1 ]] && ERRORS+=("--window (current: ${WINDOW})")

  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "ERROR: The following parameters must be non-zero in ${SEARCH_CFG} for second pass:"
    printf '  %s\n' "${ERRORS[@]}"
    exit 1
  fi

  echo "Second pass parameters validated: --mass-acc=${MASS_ACC}, --mass-acc-ms1=${MASS_ACC_MS1}, --window=${WINDOW}"
else
  echo "ERROR: Unknown SEARCH_MODE='${SEARCH_MODE}'" >&2
  echo "Valid values: 'survey', 'firstpass' (or 'first_pass'), 'secondpass' (or 'second_pass')" >&2
  exit 1
fi

if [[ "${SEARCH_MODE}" == "survey" ]]; then
  ADD_FLAGS="--individual-windows"
elif [[ "${SEARCH_MODE}" == "firstpass" ]]; then
  ADD_FLAGS="--gen-spec-lib \
  --out-lib "${OUT_DIR}/first_pass/empirical_library/${OUTNAME}.empirical.parquet" \
  --export-quant \
  --matrices \ "
else
  ADD_FLAGS="--export-quant \
  --matrices"
fi

diann \
--cfg "${SEARCH_CFG_TO_USE}" \
--cfg "${FILE_CFG}" \
--lib "${SPECLIB}" \
--fasta "${FASTA}" \
--temp "${OUT_SUBDIR}/quant" \
${ADD_FLAGS} \
--out "${OUT_SUBDIR}/reports/report.parquet" \
--threads "${THREADS}" \
--quant-ori-names \
--fix-scoring \
--verbose 1 \

if [[ "${SEARCH_MODE}" == "survey" ]]; then

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