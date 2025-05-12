#!/usr/bin/env bash

set -Eeuf -o pipefail
shopt -s inherit_errexit

readonly DEST="@scanDestination@"

# https://www.camroncade.com/cloud-scanner-with-raspberry-pi-fujitsu-ix500-2/
main() {
  TMPDIR="$(mktemp -d)"
  readonly TMPDIR
  local outfile
  outfile=${TMPDIR}/$(date +'%Y%m%dT%H%M%S')_scan_%03d.jpg.tmp

  scanimage --resolution 300 \
    --batch="${outfile}" \
    --format=jpeg \
    --mode=color \
    --source='ADF Duplex'

  find "${TMPDIR}" -type f -name '*_scan_*.jpg.tmp' -print0 |
    while read -r -d $'\0' file; do
      exiftool -Model='@modelName@' "${file}"

      jpegtran -perfect -rotate 180 "${file}"

      bn="$(basename "${file}")"
      mv "${file}" "${DEST}/${bn%.tmp}"
    done
}
main "$@"
