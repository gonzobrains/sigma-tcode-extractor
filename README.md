# Sigma T-code Extractor

Extract Sigma rules related to MITRE ATT&CK T-codes and export them in a CSV format with YAML rule contents and tactics.

## Note

This script is currently designed to work on MACOS.  You may need to change it to grep/sed/awk/bash better on other systems.

## Features

- Extracts Sigma rule file paths and metadata from a local Sigma repo
- Looks up the MITRE tactic name for each T-code
- Outputs a CSV ready for Excel or analysis tools

## Requirements

- bash, curl, grep, sed, awk
- `xmllint` (for tactic scraping from MITRE ATT&CK site)

## Usage

```bash
export SIGMA_DIR=~/dev/sigma
./getsigma.sh T1059 T1078 T1486
```

Or from a file:

```bash
./getsigma.sh $(cat t_codes.txt)
```

## License

MIT
