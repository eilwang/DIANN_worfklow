#!/bin/bash

set -euo pipefail

module load diann/2.6.1

OUTNAME="$(basename "${SLURM_JOB_NAME}" .txt)_${SLURM_JOB_ID}"
DIANN_LOG="${LOGDIR}/${OUTNAME}.log.txt"

diann \
--cfg "${CONFIG}" \
--fasta "${FASTA}" \
--out-lib "${OUTDIR}/${OUTNAME}.parquet" \
--threads 128 \
--verbose 1 \
> "${DIANN_LOG}" 2>&1