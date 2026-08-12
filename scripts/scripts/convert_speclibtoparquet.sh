#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"

diann \
--lib "${SPECLIB}" \
--out-lib "${OUT_DIR}/${SPECLIB_TAG}.parquet" \
--gen-spec-lib \
--threads "${THREADS}" \
--verbose 1 \

# Move DIA-NN's auto-generated log file to the logs directory
[[ -f "${OUT_DIR}/${SPECLIB_TAG}.log.txt" ]] && \
  mv "${OUT_DIR}/${SPECLIB_TAG}.log.txt" "${LOGDIR}/${OUTNAME}.log.txt"