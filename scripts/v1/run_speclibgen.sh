#!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# --- everything configurable lives here ---
FASTA="/hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas"
CONFIG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/configs/20260721_gen_tryptic_spec_lib_default.cfg"
OUTDIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/spectral_libraries/spectral_libraries"
LOGDIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/spectral_libraries/logs"
THREADS=128
MEM="750G"
TIME="01-00:00:00"

FASTA_TAG="$(basename "${FASTA}" .fas)"
CONFIG_TAG="$(basename "${CONFIG}" .cfg)"

export FASTA CONFIG OUTDIR THREADS LOGDIR OUTNAME

sbatch \
  --job-name="${DATE}_${FASTA_TAG}_${CONFIG_TAG}" \
  --output="${LOGDIR}/%x_%j.txt" \
  --error="${LOGDIR}/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  generate_speclib.sh