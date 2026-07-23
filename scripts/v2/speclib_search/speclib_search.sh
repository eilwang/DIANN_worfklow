#!/bin/bash

set -euo pipefail

module load diann/2.6.1

# ---if MBR enabled, add the reanalyse command---
if [ "${MBR:-}" = true ]; then
  MBR_CMD="--reanalyse"
else
  MBR_CMD=""
fi

# ---files included as lines in a csv
FILES=""
while IFS= read -r line; do
  FILES="$FILES --f $line"
done < ${FILE_CSV}

diann \
--cfg "${SEARCH_CFG}" \
--gen-spec-lib \
${FILES} \
--lib ${SPECLIB} \
--fasta "${FASTA}" \
--temp "${TEMP}" \
${MBR_CMD} \
--out-lib ${OUTDIR}/${SLURM_JOB_NAME}_emp-lib.parquet \
--out "${OUTDIR}/report.parquet" \
--threads "${THREADS}" \
--verbose 1 \
