#!/usr/bin/env bash
set -e
set +x

trap "cd $(pwd -P)" EXIT
cd "$(dirname $0)"

CLI_VERSION=$(head -1 ./CLI_VERSION)
FILE_PREFIX=playwright-cli-$CLI_VERSION

if [[ ! -d driver ]]; then
  echo "driver not downloaded. run 'install_local_dirver.sh' to install driver first."
  exit 1;
fi
cd driver
echo "Generating API"
./playwright-cli print-api-json > api.json
crystal run ../../src/gen/apigen.cr -- $(pwd)/api.json
