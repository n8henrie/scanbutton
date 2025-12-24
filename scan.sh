#!/usr/bin/env bash

set -Eeuf -o pipefail

# https://www.camroncade.com/cloud-scanner-with-raspberry-pi-fujitsu-ix500-2/
main() {
  local model=${1:-unknown_model} dest=${2:-/tmp} tmpdir outfile
  tmpdir="$(mktemp -d)"
  outfile=${tmpdir}/$(date +'%Y%m%dT%H%M%S')_scan_%03d.jpg.tmp

  pushd "${tmpdir}"
  scanimage --resolution 300 \
    --batch="${outfile}" \
    --format=jpeg \
    --mode=color \
    --source='ADF Duplex'

  local name
  find . -type f -name '*_scan_*.jpg.tmp' -print0 |
    while read -r -d $'\0' f; do
      : "$(basename -- "${f}")"
      name=${_%.tmp}

      exiftool -Model="${model}" -overwrite_original -- "${f}"
      magick "${f}" -rotate 180 "${name}"
      rm "${f}"

      mv -- "${name}" "${dest}/"
    done
}
main "$@"
