#!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# --- everything configurable lives here ---
EXPERIMENT_NAME="FBML009"
FASTA="/hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas"
SPECLIB="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/spectral_libraries/spectral_libraries/20260721_2026-07-20-sp_tr_isoforms-contam-Human_UP000005640_20260721_gen_tryptic_spec_lib_default_34941631.predicted.speclib"
SEARCH_SPACE_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/configs/20260721_gen_tryptic_spec_lib_default.cfg"
SEARCH_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/configs/v2/search_param/20260721_speclib_search_default.cfg"
TEMP="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test1/diann/temp"
OUTDIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test1/diann"
FILE_CSV="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/FBML009.csv"
THREADS=128
MEM="750G"
TIME="01-00:00:00"
MBR=true

FASTA_TAG="$(basename "${FASTA}" .fas)"
SP_CONFIG_TAG="$(basename "${SEARCH_SPACE_CFG}" .cfg)"

export FASTA SEARCH_SPACE_CFG SEARCH_CFG TEMP OUTDIR THREADS MBR SPECLIB FILE_CSV

sbatch \
  --job-name="${DATE}_${FASTA_TAG}_${SP_CONFIG_TAG}" \
  --output="${OUTDIR}/%x_%j.txt" \
  --error="${OUTDIR}/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  speclib_search.sh