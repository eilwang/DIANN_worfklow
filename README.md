# DIANN pipeline

This directory contains SLURM wrapper scripts for three DIANN operations:

- in-silico spectral-library prediction
- survey, first-pass, and second-pass searches
- conversion of a spectral library to Parquet format

The wrapper scripts read a YAML parameter file with `parse_run_param.py`, export
the values as shell variables, and submit the corresponding worker script with
`sbatch`.

## Directory layout

```text
templates/yamls/       Example parameter files
scripts/               YAML parser, SLURM submitters, and worker scripts
spectral_libraries/    Library output and logs (when configured here)
```

## Running a workflow

Run the submitter from `scripts/` or provide its path explicitly:

```bash
bash scripts/run_insilico_prediction.sh templates/yamls/KEBA_insilicolib.yaml
bash scripts/run_search.sh templates/yamls/LIPR026_027_all_firstpass.yaml
bash scripts/run_search.sh templates/yamls/LIPR026_027_all_secondpass.yaml
bash scripts/run_convert_speclib.sh path/to/convert.yaml
```

The submitters do not run DIANN directly. They parse the YAML, create output
directories where needed, and submit a worker script with SLURM options such as
`--cpus-per-task`, `--mem`, `--time`, `--output`, and `--error`.

## YAML values used by the scripts

The parser maps these nested keys to shell variables:

| YAML key | Shell variable | Used by |
| --- | --- | --- |
| `paths.fasta` | `FASTA` | library prediction and search |
| `paths.search_space_cfg` | `SEARCH_SPACE_CFG` | in-silico prediction |
| `paths.speclib_dir` | `SPECLIB_DIR` | in-silico prediction |
| `paths.out_dir` | `OUT_DIR` | search and conversion |
| `paths.speclib` | `SPECLIB` | search and conversion |
| `paths.file_cfg` | `FILE_CFG` | search; one path or a list |
| `paths.search_cfg` | `SEARCH_CFG` | search |
| `paths.quant_dir` | `QUANT_DIR` | search; defaults to the mode output directory |
| `paths.out_suffix` | `OUT_SUFFIX` | search; optional output suffix |
| `experiment.name` | `EXPERIMENT_NAME` | search job name |
| `options.search_mode` | `SEARCH_MODE` | search mode and extra flags |
| `options.reuse_quant` | `REUSE_QUANT` | optional `--use-quant` |
| `slurm.threads` | `THREADS` | DIANN `--threads` and SLURM CPUs |
| `slurm.memory` | `MEM` | SLURM memory only |
| `slurm.time` | `TIME` | SLURM wall time only |

`parse_run_param.py` flattens other YAML keys too, but a value only affects a
workflow if the shell script reads the resulting variable.

## DIANN flags added by each worker script

The flags below are the complete DIANN command construction as implemented in
the current scripts. Values shown as `${NAME}` come from YAML or are derived by
the wrapper; they are not literal flags that users type into the command.

### `generate_insilico_speclib.sh`

The command is:

```bash
diann \
  --cfg "${SEARCH_SPACE_CFG}" \
  --fasta "${FASTA}" \
  --out-lib "${SPECLIB_DIR}/${OUTNAME}.parquet" \
  --gen-spec-lib \
  --predictor \
  --fasta-search \
  --threads "${THREADS}" \
  --verbose 1
```

Flags not supplied directly in the YAML:

- `--out-lib`: generated from the SLURM job name and job ID, under
  `SPECLIB_DIR`.
- `--gen-spec-lib`: always enabled.
- `--predictor`: always enabled.
- `--fasta-search`: always enabled.
- `--verbose 1`: always enabled.

The `--cfg`, `--fasta`, and `--threads` values come from YAML.

### `search.sh`

Every search starts with one `--cfg` from `paths.search_cfg` and adds one more
`--cfg` for each entry in `paths.file_cfg`. In survey mode, the search config
may first be copied to a temporary config with `--window 0`.

The common flags are:

```bash
--lib "${SPECLIB}"
--fasta "${FASTA}"
--temp "${QUANT_DIR}"
--out "${OUT_SUBDIR}/reports/report.parquet"
--threads "${THREADS}"
--quant-ori-names
--fix-scoring
--verbose 1
```

The following common flags are added or derived by the script rather than
being typed into the YAML as DIANN command-line flags:

- `--temp`: defaults to the selected pass directory's `quant` subdirectory
  unless `paths.quant_dir` is set.
- `--out`: always points to `reports/report.parquet` below the selected pass
  directory.
- `--quant-ori-names`: always enabled.
- `--fix-scoring`: always enabled.
- `--verbose 1`: always enabled.

The mode-specific flags are:

| `options.search_mode` | Extra DIANN flags |
| --- | --- |
| `survey` | `--individual-windows` |
| `firstpass` | `--gen-spec-lib`, `--out-lib "${OUT_DIR}/first_pass/empirical_library/${OUTNAME}.empirical.parquet"`, `--export-quant`, `--matrices` |
| `secondpass` | `--export-quant`, `--matrices` |

If `options.reuse_quant: true`, the script also adds:

```bash
--use-quant
```

The script validates `--mass-acc`, `--mass-acc-ms1`, and `--window` by reading
the search config. Those options are not added to the DIANN command by the
script; they remain in the config file. Survey mode allows a zero or missing
`--window` and forces a non-zero configured window to zero in a temporary copy.
First pass requires non-zero mass-accuracy values, and second pass requires
non-zero mass-accuracy and window values.

### `convert_speclibtoparquet.sh`

The command is:

```bash
diann \
  --lib "${SPECLIB}" \
  --out-lib "${OUT_DIR}/${SPECLIB_TAG}.parquet" \
  --gen-spec-lib \
  --threads "${THREADS}" \
  --verbose 1
```

Flags and values added by the script:

- `--out-lib`: derived from the input library basename and `OUT_DIR`.
- `--gen-spec-lib`: always enabled.
- `--verbose 1`: always enabled.
- `--threads`: supplied from `slurm.threads`.

The input `--lib` comes from `paths.speclib`.

## Script responsibilities

| Script | Responsibility |
| --- | --- |
| `parse_run_param.py` | Parse YAML, flatten nested keys, and print shell assignments |
| `run_insilico_prediction.sh` | Parse YAML and submit `generate_insilico_speclib.sh` |
| `generate_insilico_speclib.sh` | Run in-silico library prediction |
| `run_search.sh` | Parse YAML, select the pass directory, create output directories, and submit `search.sh` |
| `search.sh` | Validate pass parameters, assemble the search DIANN command, and optionally parse survey windows from the log |
| `run_convert_speclib.sh` | Parse YAML and submit `convert_speclibtoparquet.sh` |
| `convert_speclibtoparquet.sh` | Convert a DIANN spectral library to Parquet |

All worker scripts load `diann/2.6.1` with the environment module system before
calling DIANN.

## Important maintenance notes

- The current workers use `diann/2.6.1`; changing the module version changes
  the executable used by all three workflows.
- The YAML examples contain project-specific absolute paths and should be
  updated when experiment output directories or FASTA files change.
- `scripts/README_parse_config.md` describes the parser, but this README is
  the source of truth for the actual DIANN flags assembled by the worker
  scripts.