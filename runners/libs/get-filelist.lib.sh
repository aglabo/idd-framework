#!/usr/bin/env bash
# get-filelist.sh — file list and argument normalization library
# Provides path normalization, glob-to-regex conversion, and file list retrieval

# Guard against double sourcing
[[ -n "${_GET_FILELIST_SH:-}" ]] && return 0
readonly _GET_FILELIST_SH=1

#
# @description Convert shell glob pattern to rg-compatible regex filter
# @arg $1 string Pattern to convert (optional; reads from stdin if omitted)
# @stdout Converted pattern
# @exitcode 0 always
#
args_to_filter() {
  local __pattern
  if [[ $# -gt 0 ]]; then
    __pattern="$1"
  else
    IFS= read -r __pattern
  fi
  __pattern="${__pattern//\*/.*}"
  __pattern="${__pattern//\?/.}"
  printf '%s\n' "${__pattern}"
}

#
# @description Convert Windows backslash path separators to forward slashes
# @arg $1 string Path to normalize (optional; reads from stdin if omitted)
# @stdout Normalized path string
# @exitcode 0 always
#
normalize_path() {
  local __path
  if [[ $# -gt 0 ]]; then
    __path="$1"
  else
    IFS= read -r __path
  fi
  printf '%s\n' "${__path//\\/\/}"
}

#
# @description Test whether a string contains shell glob characters (* or ?)
# @arg $1 string Pattern to test
# @stdout nothing
# @exitcode 0 if pattern contains * or ?, 1 otherwise
#
is_glob_pattern() {
  local __pattern="$1"
  [[ "$__pattern" == *'*'* || "$__pattern" == *'?'* ]]
}

#
# @description Get list of files matching a pattern with optional filters
# @arg $1 string Search root directory
# @arg $2 string File glob pattern (e.g. "*.spec.sh")
# @arg $@ Additional filters, applied left to right and AND-combined: slash-containing
#         args are dir_filters, others are str_filters. A leading `!` marks the filter
#         as an exclusion; the rest is classified the same way and applied as `rg -v`
# @stdout Newline-separated list of matching file paths (./-prefixed, forward slashes); empty output when no files match
# @stderr Diagnostic prefixed with `get_filelist:` on every failure path below
# @exitcode 0 Files matched, or nothing matched (an empty result is not an error)
# @exitcode 1 Search root is not a directory, the search root could not be entered,
#             a filter pattern is empty (a bare `!` or an empty string), or rg exited
#             with 2 or higher (a real rg error)
# @note rg skips hidden directories and honours .gitignore by default, so files
#       under those are never enumerated regardless of the filters given; their
#       absence is rg's default behaviour and not the effect of a filter
#
get_filelist() {
  local __root="$1"
  local __pattern="$2"
  shift 2

  if [[ ! -d "$__root" ]]; then
    printf 'get_filelist: search root is not a directory: %s\n' "$__root" >&2
    return 1
  fi

  # Collect all filters as rg patterns (dir: as-is, str: glob-converted).
  # A leading `!` marks the filter as an exclusion; the polarity is kept in a
  # parallel array so filter and polarity stay index-aligned.
  local -a __filters=()
  local -a __excludes=()
  local __f __body __norm __exclude
  for __f in "$@"; do
    __body="$__f"
    __exclude=0
    if [[ "$__body" == '!'* ]]; then
      __exclude=1
      __body="${__body#!}"
    fi
    if [[ -z "$__body" ]]; then
      printf 'get_filelist: filter pattern is empty: %s\n' "$__f" >&2
      return 1
    fi
    __norm=$(normalize_path "$__body")
    if [[ "$__norm" == */* ]]; then
      __filters+=("$__norm")
    else
      __filters+=("$(args_to_filter "$__norm")")
    fi
    __excludes+=("$__exclude")
  done

  # Enumerate files; normalize separators and prepend ./
  # rg is captured in its own $( ) so the status belongs to rg and not to sed.
  # The `|| __rc=$?` form keeps a `set -e` caller alive when rg reports no match.
  #
  # A failing `cd` leaves the subshell with a sentinel status that rg never
  # produces (rg uses 0 / 1 / 2 only). Letting `cd` report its own 1 instead
  # would be indistinguishable from rg's no-match 1, so a root that clears the
  # `[[ -d ]]` guard but cannot be entered — unsearchable, or deleted between
  # the guard and the `cd` — would come back silently as status 0 and no output.
  local __result __raw
  local __rc=0
  local __cd_failed=64
  __raw=$(
    cd "$__root" || exit "$__cd_failed"
    rg --files -g "$__pattern"
  ) || __rc=$?
  if ((__rc == __cd_failed)); then
    printf 'get_filelist: cannot enter search root: %s\n' "$__root" >&2
    return 1
  fi
  if ((__rc >= 2)); then
    printf 'get_filelist: failed to enumerate files under: %s\n' "$__root" >&2
    return 1
  fi
  __result=$(printf '%s\n' "$__raw" | sed 's|\\|/|g; s|^[^./]|./&|')

  # Apply each filter in order (AND: narrow or subtract; short-circuit on empty)
  local __i __frc
  for __i in "${!__filters[@]}"; do
    [[ -z "$__result" ]] && break
    __frc=0
    if [[ "${__excludes[__i]}" == 1 ]]; then
      __result=$(printf '%s\n' "$__result" | rg -v -e "${__filters[__i]}") || __frc=$?
    else
      __result=$(printf '%s\n' "$__result" | rg -e "${__filters[__i]}") || __frc=$?
    fi
    if ((__frc >= 2)); then
      printf 'get_filelist: filter failed: %s\n' "${__filters[__i]}" >&2
      return 1
    fi
  done

  [[ -z "$__result" ]] && return 0
  printf '%s\n' "$__result"
}
