#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"

diann \
--cfg "${SEARCH_SPACE_CFG}" \
--fasta "${FASTA}" \
--out-lib "${SPECLIB_DIR}/${OUTNAME}.parquet" \
--gen-spec-lib \
--predictor \
--fasta-search \
--threads "${THREADS}" \
--verbose 1 \

# Move DIA-NN's auto-generated log file to the logs directory
if [[ -f "${SPECLIB_DIR}/${OUTNAME}.log.txt" ]]; then
  mv "${SPECLIB_DIR}/${OUTNAME}.log.txt" "${LOGDIR}/"
  echo "Moved DIA-NN log file to ${LOGDIR}/${OUTNAME}.log.txt"
fi