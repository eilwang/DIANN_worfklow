#!/bin/bash
#SBATCH --job-name=diann_gen_tryptic_NoRedAlk_speclib
#SBATCH --output=job_output_%j.txt
#SBATCH --error=job_error_%j.txt
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=128
#SBATCH --mem=750G

set -euo pipefail

module load diann/2.6.1

diann \
--threads 128 \
--verbose 1 \
--qvalue 0.05 \
--matrices \
--gen-spec-lib \
--f /hpc/projects/mass_spec/projects/FBLM009/raw_data/7_inputlysateforI_F1_R1_T1_50msW102V1-ML10m100nlV10A5TrapNS5_013520_FBLM009_timsTOF_R-A1_1_16362.d \
--out /hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test2/report.parquet \
--lib /hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/spectral_libraries/spectral_libraries/20260721_2026-07-20-sp_tr_isoforms-contam-Human_UP000005640_20260721_gen_tryptic_spec_lib_default_34941631.predicted.speclib \
--temp /hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test2/temp \
--out-lib /hpc/projects/mass_spec/eileenwang/DIANN/DIANN_worfklow/testing/test2/testing2_emp-lib.parquet \
--fasta /hpc/projects/mass_spec/FASTA/2026-07-20-sp_tr_isoforms-contam-Human_UP000005640.fas \
--rt-profiling \