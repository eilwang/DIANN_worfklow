#!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# --- everything configurable lives here ---
FASTA="/hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas"
SEARCH_SPACE_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/configs/20260722_searchspace_tryptic_default.cfg"
SPECLIB_DIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/speclib"
LOGDIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/speclib/logs"

THREADS=128
MEM="750G"
TIME="01-00:00:00"

FASTA_TAG="$(basename "${FASTA}" .fas)"
SP_CONFIG_TAG="$(basename "${SEARCH_SPACE_CFG}" .cfg)"

export FASTA SEARCH_SPACE_CFG SPECLIB_DIR THREADS LOGDIR

sbatch \
  --job-name="${DATE}_${FASTA_TAG}_${SP_CONFIG_TAG}" \
  --output="${LOGDIR}/%x_%j.txt" \
  --error="${LOGDIR}/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  generate_insilico_speclib.sh


  #!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# --- everything configurable lives here ---
EXPERIMENT_NAME="FBML009"
OUT_DIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/"

FASTA="/hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas"
SPECLIB="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/speclib/20260722_2026-07-20-sp_tr_isoforms-contam-Human_UP000005640_20260722_searchspace_tryptic_default_34977331.predicted.speclib"
FILE_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/configs/files.cfg"

SEARCH_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/configs/20260722_search_FDR1_MA15_RTprof.cfg"

THREADS=32
MEM="512G"
TIME="01-00:00:00"

FASTA_TAG="$(basename "${FASTA}" .fas)"
SPECLIB_TAG="$(basename "${SPECLIB}" .predicted.speclib)"

# Create directories if they don't exist
mkdir -p "${OUT_DIR}/first_pass/logs"
mkdir -p "${OUT_DIR}/first_pass/quant"
mkdir -p "${OUT_DIR}/first_pass/empirical_library"
mkdir -p "${OUT_DIR}/first_pass/reports"

export FASTA SEARCH_CFG OUT_DIR THREADS SPECLIB FILE_CFG

sbatch \
  --job-name="${DATE}_${EXPERIMENT_NAME}_firstpass" \
  --output="${OUT_DIR}/first_pass/logs/%x_%j.txt" \
  --error="${OUT_DIR}/first_pass/logs/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  firstpass_search.sh


  #!/bin/bash
set -euo pipefail
DATE=$(date +%Y%m%d)

# --- everything configurable lives here ---
EXPERIMENT_NAME="FBML009"
OUT_DIR="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/"

FASTA="/hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas"
EMPLIB="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklows/testing/test3_2pass/first_pass/empirical_library/20260722_FBML009_20260722_2026-07-20-sp_tr_isoforms-contam-Human_UP000005640_20260722_searchspace_tryptic_default_34977331_34977778_emp-lib.parquet"
FILE_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/configs/files.cfg"

SEARCH_CFG="/hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test3_2pass/configs/20260722_search_FDR1_MA15_RTprof.cfg"

THREADS=32
MEM="512G"
TIME="01-00:00:00"

FASTA_TAG="$(basename "${FASTA}" .fas)"
EMPLIB_TAG="$(basename "${EMPLIB}" _emp-lib.parquet)"

# Create directories if they don't exist
mkdir -p "${OUT_DIR}/second_pass/logs"
mkdir -p "${OUT_DIR}/second_pass/quant"
# mkdir -p "${OUT_DIR}/second_pass/empirical_library"
mkdir -p "${OUT_DIR}/second_pass/reports"

export FASTA SEARCH_CFG OUT_DIR THREADS EMPLIB FILE_CFG

sbatch \
  --job-name="${DATE}_${EXPERIMENT_NAME}_secondpass" \
  --output="${OUT_DIR}/second_pass/logs/%x_%j.txt" \
  --error="${OUT_DIR}/second_pass/logs/%x_%j_error.txt" \
  --cpus-per-task="${THREADS}" \
  --mem="${MEM}" \
  --time="${TIME}" \
  --export=ALL \
  secondpass_search.sh