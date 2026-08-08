#!/usr/bin/env bash
# Decrypts the sops-encrypted .env file in the current directory straight
# into $GITHUB_ENV, masking each value in the log along the way. No
# plaintext .env file is ever written to disk.
set -euo pipefail

while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" == \#* ]] && continue
  echo "::add-mask::$value"
  echo "$key=$value" >> "$GITHUB_ENV"
done < <(sops -d .env)
