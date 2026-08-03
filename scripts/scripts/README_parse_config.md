# Generic Config Parser for DIANN Workflows

## Overview
`parse_run_param.py` is a generic YAML parser that converts any YAML configuration into bash variables for use in SLURM job submission scripts.

## Features
- **Automatic flattening**: Nested YAML structures are flattened with dot notation
- **Smart variable naming**: Keys are automatically converted to uppercase bash variable names
- **Custom mappings**: Common nested keys have predefined bash variable names (see below)
- **Type handling**: Properly formats booleans, numbers, and strings for bash

## Custom Key Mappings

The parser recognizes these nested paths and maps them to standard bash variables:

```
slurm.threads       → THREADS
slurm.memory        → MEM
slurm.time          → TIME
slurm.partition     → PARTITION
paths.fasta         → FASTA
paths.out_dir       → OUT_DIR
paths.speclib       → SPECLIB
paths.emplib        → EMPLIB
paths.file_cfg      → FILE_CFG
paths.search_cfg    → SEARCH_CFG
paths.search_space_cfg → SEARCH_SPACE_CFG
paths.speclib_dir   → SPECLIB_DIR
```

## YAML Structure

Organize your config with two main sections:

### 1. Paths Section
```yaml
paths:
  fasta: "/path/to/fasta.fas"
  out_dir: "/path/to/output"
  search_cfg: "/path/to/search.cfg"
  # ... any other paths
```

### 2. SLURM Section
```yaml
slurm:
  threads: 128
  memory: "750G"
  time: "01-00:00:00"
  partition: "compute"  # optional
```

### 3. Additional Sections
You can add any other sections:
```yaml
experiment:
  name: "MyExperiment"

options:
  survey: false
  verbose: 3
```

These will be converted to:
- `EXPERIMENT_NAME="MyExperiment"`
- `OPTIONS_SURVEY=false`
- `OPTIONS_VERBOSE=3`

## Usage in Scripts

### Basic Usage
```bash
#!/bin/bash
set -euo pipefail

# Parse config file (default or provided)
RUN_PARAM="${1:-configs/default_param.yaml}"

if [[ ! -f "${RUN_PARAM}" ]]; then
  echo "Error: Config file '${RUN_PARAM}' not found" >&2
  exit 1
fi

# Load configuration
eval "$(python3 parse_run_param.py "${RUN_PARAM}")

# Now all variables are available
echo "Using FASTA: ${FASTA}"
echo "Threads: ${THREADS}"
```

### Running the Script
```bash
# Use default config
bash run_script.sh

# Use specific config
bash run_script.sh configs/my_param.yaml
```

## Examples

See example configs in `configs/`:
- `insilico_example.yaml` - In-silico spectral library prediction
- `firstpass_example.yaml` - First pass survey search
- `secondpass_example.yaml` - Second pass search

## Testing

Test the parser directly:
```bash
python3 parse_run_param.py configs/example.yaml
```

This outputs the bash variable assignments that would be exported.
