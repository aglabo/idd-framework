#!/usr/bin/env bash
# src: ./scripts/run-shellcheck.sh
# @(#) : shellcheck runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"
# shellcheck source=runners/libs/get-filelist.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/get-filelist.lib.sh"
cd "${SCRIPT_ROOT}/.."

SHELLCHECKRC="${SHELLCHECKRC:-${SCRIPT_ROOT}/../configs/shellcheckrc}"

#
# @description Collect .sh files to lint. Directory targets are enumerated with
#   get_filelist (excluding .tools/ and shellspec test files) and re-prefixed with
#   the target path; explicit file paths are taken as-is without any filtering.
#   The `.tools/` filter is currently redundant — rg already skips it as a hidden
#   directory — and is kept as defence in depth should `--hidden` ever be added.
# @arg $@ string Target paths (directories or files)
# @stdout NUL-separated file paths
# @exitcode 0 All target paths were collected successfully
# @exitcode 1 get_filelist failed for a directory target (aborts immediately,
#             leaving the remaining targets unwalked)
# @note The spec exclusion is anchored with a trailing `$` so it matches only
#       names ENDING in `.spec.sh`. Without the anchor the filter is an
#       unanchored regex over the whole path and would also drop names that
#       merely contain `.spec.sh` (e.g. `tool.spec.sh.wrapper.sh`,
#       `x.spec.sh.d/helper.sh`), which the `find ! -name "*.spec.sh"`
#       predicate this replaced did lint.
# @note Enumeration goes through rg, which skips hidden directories and honours
#       .gitignore by default. Files under those are never handed to shellcheck,
#       so at the CLI "nothing was linted" and "everything linted clean" look
#       alike; a mis-scoped target surfaces only as the "No .sh files found."
#       notice on stderr.
#
collect_target_files() {
  local target listing file
  for target in "$@"; do
    if [[ -d $target ]]; then
      if ! listing=$(get_filelist "$target" "*.sh" '!*[.]spec[.]sh$' '![.]tools/'); then
        echo "Failed to collect .sh files under: $target" >&2
        return 1
      fi
      # An empty listing must be skipped: a here-string of "" still iterates
      # once with an empty line and would emit a phantom "$target/" record.
      if [[ -n "$listing" ]]; then
        while IFS= read -r file; do
          printf '%s\0' "${target%/}/${file#./}"
        done <<<"$listing"
      fi
    else
      printf '%s\0' "$target"
    fi
  done
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --rcfile | -r)
      SHELLCHECKRC="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    *) break ;;
    esac
  done
  local -a targets=("$@")
  if [[ ${#targets[@]} -eq 0 ]]; then
    targets=(".")
  fi
  targets=("${targets[@]//\\//}")
  local -a files=()
  local f collected_file
  collected_file=$(mktemp)
  if ! collect_target_files "${targets[@]}" >"$collected_file"; then
    rm -f "$collected_file"
    return 1
  fi
  while IFS= read -r -d '' f; do
    files+=("$f")
  done <"$collected_file"
  rm -f "$collected_file"
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .sh files found." >&2
    return 0
  fi
  (shellcheck --rcfile="$SHELLCHECKRC" "${files[@]}")
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
