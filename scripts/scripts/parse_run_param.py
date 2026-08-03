#!/usr/bin/env python3
"""
Generic YAML config parser that exports bash variables.

Handles nested structures and converts keys to uppercase bash variable names.
Special handling for common nested sections like 'slurm' and 'paths'.
"""

import sys
import yaml
from typing import Any, Dict

# Mapping for nested keys to flat bash variable names
KEY_MAPPINGS = {
    "slurm.threads": "THREADS",
    "slurm.memory": "MEM",
    "slurm.time": "TIME",
    "slurm.partition": "PARTITION",
    "paths.fasta": "FASTA",
    "paths.out_dir": "OUT_DIR",
    "paths.quant_dir": "QUANT_DIR",
    "paths.out_suffix": "OUT_SUFFIX",
    "paths.speclib": "SPECLIB",
    "paths.file_cfg": "FILE_CFG",
    "paths.search_cfg": "SEARCH_CFG",
    "paths.search_space_cfg": "SEARCH_SPACE_CFG",
    "paths.speclib_dir": "SPECLIB_DIR",
    "experiment.name": "EXPERIMENT_NAME",
    "options.search_mode": "SEARCH_MODE",
    "options.survey": "SURVEY",
}

def flatten_dict(d: Dict[str, Any], parent_key: str = '', sep: str = '.') -> Dict[str, Any]:
    """Flatten nested dictionary with dot notation."""
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

def get_bash_var_name(key: str) -> str:
    """Convert config key to bash variable name."""
    # Check if there's a custom mapping
    if key in KEY_MAPPINGS:
        return KEY_MAPPINGS[key]
    # Otherwise convert to uppercase and replace dots/hyphens with underscores
    return key.upper().replace('.', '_').replace('-', '_')

def format_value(value: Any) -> str:
    """Format value for bash export."""
    if isinstance(value, bool):
        return 'true' if value else 'false'
    elif isinstance(value, (int, float)):
        return str(value)
    else:
        # Quote strings
        return f'"{value}"'

def main():
    if len(sys.argv) != 2:
        print("Usage: parse_run_param.py <param.yaml>", file=sys.stderr)
        sys.exit(1)
    
    config_file = sys.argv[1]
    
    try:
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)
        
        if not config:
            print("Error: Empty config file", file=sys.stderr)
            sys.exit(1)
        
        # Flatten nested structure
        flat_config = flatten_dict(config)
        
        # Export all variables
        for key, value in sorted(flat_config.items()):
            var_name = get_bash_var_name(key)
            var_value = format_value(value)
            print(f'{var_name}={var_value}')
        
    except FileNotFoundError:
        print(f"Error: Config file '{config_file}' not found", file=sys.stderr)
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing YAML: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
