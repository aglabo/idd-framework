#!/usr/bin/env bash
# src: ./scripts/xcp.sh
# @(#): eXtended CoPy utility
#
# @file xcp.sh
# @brief eXtended CoPy utility with advanced file handling capabilities
# @description
#   Advanced copy utility that extends standard cp with additional features:
#   - Multiple operation modes (skip, overwrite, update, backup)
#   - Dry-run mode for safe testing
#   - Recursive copying with pattern matching
#   - Automatic directory creation (-p flag)
#   - Symlink handling options
#   - Error tracking and fail-fast mode
#
# @example
#   # Copy with parent directory creation
#   xcp.sh -p source.txt /path/to/dest/
#
#   # Dry-run mode
#   xcp.sh --dry-run -R source/ dest/
#
#   # Verbose output
#   xcp.sh -v source.txt dest.txt
#
# @help<<
# eXtended CoPy utility with advanced file handling capabilities.
#
# Usage: <SCRIPT_NAME> [OPTIONS] SOURCE... DEST
#
# OPTIONS:
#   Operation modes:
#     -n, --noclobber     Skip existing files (default)
#     -f, --force         Overwrite existing files
#     -u, --update        Update only if source is newer
#     -b, --backup        Backup existing files before overwriting
#
#  Copy options:
#     -r, -R, --recursive Copy directories recursively
#     -p, --parents       Create parent directories as needed
#     -L, --dereference   Dereference symbolic links
#     -H, --hidden        Include hidden files (dotfiles)
#
#  Execution control:
#     --dry-run           Show what would be done without executing
#     --fail-fast         Stop on first error
#
#  Output control:
#     -v, --verbose       Show detailed progress information
#     -q, --quiet         Show errors only
#
#  Other:
#     -h, --help          Display this help message
#     -V, --version       Display version information
#
# EXAMPLES:
#  # Copy with parent directory creation
#  <SCRIPT_NAME> -p source.txt /path/to/dest/
#
#  # Copy directory including hidden files
#  <SCRIPT_NAME> -RH source/ dest/
#
#  # Dry-run mode
#  <SCRIPT_NAME> --dry-run -R source/ dest/
#
#  # Verbose output with update mode
#  <SCRIPT_NAME> -v -u source.txt dest.txt
#<<
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# Enable strict mode for safer scripting
set -euo pipefail

# ============================================================================
# Dependencies
# ============================================================================

##
# @description Script directory path (absolute)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source logger library
# shellcheck source=libs/logger.lib.sh
. "${SCRIPT_DIR}/libs/logger.lib.sh"

# ============================================================================
# Configuration & Global Variables
# ============================================================================

##
# @description Skip existing files (operation mode)
# @default 0
readonly MODE_SKIP=0

##
# @description Overwrite existing files (operation mode)
# shellcheck disable=SC2034
readonly MODE_OVERWRITE=1

##
# @description Update only if source is newer (operation mode)
# shellcheck disable=SC2034
readonly MODE_UPDATE=2

##
# @description Create backup of existing files (operation mode)
# shellcheck disable=SC2034
readonly MODE_BACKUP=3

##
# @description Current operation mode (default: skip existing files)
# @default MODE_SKIP
# @see init_variables
# shellcheck disable=SC2034
OPERATION_MODE=

##
# @description Enable dry-run mode (0=disabled, 1=enabled)
# @default 0
# @see init_variables
# shellcheck disable=SC2034
FLAG_DRY_RUN=

##
# @description Enable recursive copying (0=disabled, 1=enabled)
# @default 0
# @see init_variables
# shellcheck disable=SC2034
FLAG_RECURSIVE=

##
# @description Create parent directories as needed (0=disabled, 1=enabled)
# @default 0
# @see init_variables
FLAG_PARENTS=

##
# @description Dereference symbolic links (0=disabled, 1=enabled)
# @default 0
# @see init_variables
# shellcheck disable=SC2034
FLAG_DEREFERENCE=

##
# @description Stop on first error (0=continue, 1=stop)
# @default 0
# @see init_variables
# shellcheck disable=SC2034
FLAG_FAIL_FAST=

##
# @description Indicates fail-fast abort requested after error
# @default 0
# @see init_variables
# shellcheck disable=SC2034
FLAG_ABORT_REQUESTED=

##
# @description Include hidden files (dotfiles) in directory copy (0=disabled, 1=enabled)
# @default 0
# @see init_variables
# shellcheck disable=SC2034
FLAG_INCLUDE_HIDDEN=

##
# @description Script version (extracted from file header @version)
# shellcheck disable=SC2034
VERSION=$(sed -n '1,/^$/p' "${BASH_SOURCE[0]}" | sed -n 's/^# @version //p')
readonly VERSION

##
# @description Script name (from $0)
# shellcheck disable=SC2034
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# ============================================================================
# Initialization Functions
# ============================================================================

##
# @description Initialize or reset all state variables to default values
# @example
#   init_variables  # Reset all variables to defaults
# @exitcode 0 Always succeeds
# @see logger_init
init_variables() {
  # Re-initialize logger
  logger_init

  # Operation mode and flags
  OPERATION_MODE=$MODE_SKIP
  FLAG_DRY_RUN=0
  FLAG_RECURSIVE=0
  FLAG_PARENTS=0
  FLAG_DEREFERENCE=0
  FLAG_FAIL_FAST=0
  FLAG_ABORT_REQUESTED=0
  FLAG_INCLUDE_HIDDEN=0

  # Command-line arguments
  SOURCE_ARGS=()
  DEST_ARG=""

  return 0
}

# ============================================================================
# Utility Functions - Validation
# ============================================================================

##
# @description Check if source file or directory exists and is accessible
# @arg $1 string Path to source file or directory
# @example
#   if validate_source "/path/to/file"; then
#     echo "Source is valid"
#   fi
# @exitcode 0 If source exists and is readable
# @exitcode 1 If source not found or not readable
# @see log_error
validate_source() {
  local source="$1"

  if [[ ! -e "$source" ]]; then
    log_error "Source not found: $source"
    return 1
  fi

  if [[ ! -r "$source" ]]; then
    log_error "Source not readable: $source"
    return 1
  fi

  return 0
}

##
# @description Validate destination directory accessibility without side effects
# @arg $1 string Path to destination directory
# @example
#   if check_destination_directory "/path/to/dest"; then
#     echo "Destination ready"
#   fi
# @exitcode 0 If directory exists and is writable
# @exitcode 1 If path is empty, not a directory, or not writable
# @exitcode 2 If directory does not exist
# @see log_error
check_destination_directory() {
  local dest_dir="$1"

  # Early return for error: empty path
  if [[ -z "$dest_dir" ]]; then
    log_error "Destination path is empty"
    return 1
  fi

  # Early return for error: path exists but not a directory
  if [[ -e "$dest_dir" && ! -d "$dest_dir" ]]; then
    log_error "Destination path exists but is not a directory: $dest_dir"
    return 1
  fi

  # Early return for error: directory exists but not writable
  if [[ -d "$dest_dir" && ! -w "$dest_dir" ]]; then
    log_error "Destination directory not writable: $dest_dir"
    return 1
  fi

  # Early return for status: directory does not exist
  if [[ ! -d "$dest_dir" ]]; then
    return 2
  fi

  # Success: directory exists and is writable
  return 0
}

# ============================================================================
# Utility Functions - Directory Handling
# ============================================================================

##
# @description Create destination directory with error handling
# @arg $1 string Destination directory path
# @example
#   FLAG_PARENTS=1
#   create_destination_directory "/path/to/dir"
# @exitcode 0 If directory already exists or creation succeeds
# @exitcode 1 If directory cannot be created or path invalid
# @see log_error log_verbose log_info log_dry_run
create_destination_directory() {
  local dest_dir="$1"

  # Early return for error: empty path
  if [[ -z "$dest_dir" ]]; then
    log_error "Destination directory path is empty"
    return 1
  fi

  # Early return for success: directory already exists
  if [[ -d "$dest_dir" ]]; then
    return 0
  fi

  # Early return for error: path exists but not a directory
  if [[ -e "$dest_dir" && ! -d "$dest_dir" ]]; then
    log_error "Destination path exists but is not a directory: $dest_dir"
    return 1
  fi

  # Early return for error: no parent creation flag
  if [[ $FLAG_PARENTS -eq 0 ]]; then
    log_error "Destination directory does not exist: $dest_dir (use -p to create)"
    return 1
  fi

  # Early return for dry-run mode
  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    log_dry_run "mkdir -p \"$dest_dir\""
    return 0
  fi

  # Attempt directory creation
  log_verbose "Creating directory: $dest_dir"
  if ! mkdir -p "$dest_dir" 2>/dev/null; then
    log_error "Failed to create directory: $dest_dir"
    return 1
  fi

  # Success: directory created
  log_info "Created directory: $dest_dir"
  return 0
}

# ============================================================================
# Utility Functions - Timestamp Operations
# ============================================================================

##
# @description Return current timestamp in YYMMDDHHMMSS format
# @example
#   timestamp=$(get_timestamp)
#   backup_file="config.${timestamp}.bak"
# @stdout Timestamp string in YYMMDDHHMMSS format (e.g., "250108153045")
# @exitcode 0 Always succeeds
# @see date(1)
get_timestamp() {
  date +%y%m%d%H%M%S
}

##
# @description Get modification time of file as Unix timestamp
# @arg $1 string File path
# @example
#   mtime=$(get_mtime "/path/to/file")
#   if [[ -n "$mtime" ]]; then
#     echo "File modified at: $mtime"
#   fi
# @stdout Unix timestamp (seconds since epoch) or empty string on error
# @exitcode 0 Always succeeds (errors return empty string)
# @see stat(1)
get_mtime() {
  local file="$1"

  if command -v stat &>/dev/null; then
    # Try GNU stat first, then BSD stat, suppress all errors
    stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || true
  else
    # Fallback: return empty string when stat unavailable
    echo ""
  fi
}

##
# @description Determine if source file is newer than destination file
# @arg $1 string Source file path
# @arg $2 string Destination file path
# @arg $3 string Optional source mtime override for testing (Unix timestamp)
# @arg $4 string Optional dest mtime override for testing (Unix timestamp)
# @example
#   if is_newer "$src" "$dest"; then
#     echo "Update required"
#   fi
#   # Testing with virtual timestamps
#   is_newer "" "" "1700000000" "1600000000"  # src newer
# @exitcode 0 If source is newer or comparison unavailable
# @exitcode 1 If source is not newer than destination
# @see get_mtime log_verbose
is_newer() {
  local src="$1"
  local dest="$2"
  local src_time_override="${3:-}"
  local dest_time_override="${4:-}"

  local src_time dest_time

  # Use override if provided, otherwise get from file
  if [[ -n "$src_time_override" ]]; then
    src_time="$src_time_override"
  else
    src_time="$(get_mtime "$src")"
  fi

  if [[ -n "$dest_time_override" ]]; then
    dest_time="$dest_time_override"
  else
    dest_time="$(get_mtime "$dest")"
  fi

  if [[ -z "$src_time" || -z "$dest_time" ]]; then
    log_verbose "mtime unavailable: src=$src_time dest=$dest_time"
    return 0
  fi

  if [[ $src_time -le $dest_time ]]; then
    log_verbose "Source not newer: $src_time <= $dest_time"
    return 1
  fi

  log_verbose "Source newer: $src_time > $dest_time"
  return 0
}

##
# @description Create timestamped backup of existing file
# @arg $1 string File path to backup
# @arg $2 string Optional timestamp (default: auto-generated via get_timestamp)
# @example
#   backup_file "/path/to/file.txt"
#   backup_file "/path/to/file.txt" "250112120000"  # For testing
# @exitcode 0 If backup created successfully
# @exitcode 1 If backup failed (validation error, collision, mv failed)
# @see get_timestamp log_info log_verbose log_error log_dry_run
backup_file() {
  local file="$1"
  local timestamp="${2:-$(get_timestamp)}"
  local backup_path

  # Early return for error: empty file path
  if [[ -z "$file" ]]; then
    log_error "backup_file: Empty file path"
    return 1
  fi

  # Early return for error: file does not exist
  if [[ ! -e "$file" ]]; then
    log_error "backup_file: File does not exist: $file"
    return 1
  fi

  backup_path="${file}.bak.${timestamp}"

  # Early return for error: timestamp collision
  if [[ -e "$backup_path" ]]; then
    log_error "Backup file already exists (timestamp collision): $backup_path"
    return 1
  fi

  # Early return for dry-run mode
  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    log_dry_run "mv \"$file\" \"$backup_path\""
    return 0
  fi

  # Attempt backup
  log_verbose "Backing up: $file -> $backup_path"
  if ! mv "$file" "$backup_path" 2>/dev/null; then
    log_error "Failed to backup: $file (mv failed)"
    return 1
  fi

  # Success: backup created
  log_info "Backed up: $file -> $backup_path"
  return 0
}

# ============================================================================
# Core Operations - File Copy
# ============================================================================

##
# @description Resolve destination file path for copy operation
# @arg $1 string Source file path
# @arg $2 string Destination path (file or directory)
# @stdout Resolved destination file path
# @exitcode 0 Always succeeds
resolve_destination_path() {
  local src="$1"
  local dest="$2"

  if [[ -d "$dest" ]]; then
    printf '%s/%s\n' "$dest" "$(basename "$src")"
    return 0
  fi

  printf '%s\n' "$dest"
  return 0
}

##
# @description Assess existing destination and decide whether to proceed with copy
# @arg $1 string Source file path
# @arg $2 string Destination file path
# @exitcode 0 When copy should proceed
# @exitcode 1 When copy should be skipped without error
# @exitcode 2 When copy should abort due to error
# @see OPERATION_MODE MODE_SKIP MODE_OVERWRITE MODE_UPDATE MODE_BACKUP
assess_copy_preconditions() {
  local src="$1"
  local dest_file="$2"

  if [[ ! -e "$dest_file" ]]; then
    return 0
  fi

  case $OPERATION_MODE in
  "$MODE_SKIP")
    log_info "Skipped (exists): $dest_file"
    return 1
    ;;
  "$MODE_OVERWRITE")
    log_verbose "Overwriting: $dest_file"
    return 0
    ;;
  "$MODE_UPDATE")
    if is_newer "$src" "$dest_file"; then
      log_verbose "Updating: $src -> $dest_file"
      return 0
    fi
    log_info "Skipped (not newer): $dest_file"
    return 1
    ;;
  "$MODE_BACKUP")
    if backup_file "$dest_file"; then
      return 0
    fi
    return 2
    ;;
  *)
    return 0
    ;;
  esac
}

##
# @description Execute cp command with configured flags
# @arg $1 string Source file path
# @arg $2 string Destination file path
# @exitcode 0 If copy succeeds
# @exitcode 1 If copy fails
# @see log_verbose log_dry_run log_error
perform_copy_operation() {
  local src="$1"
  local dest_file="$2"
  local -a cp_flags=("-p")

  if [[ $FLAG_DEREFERENCE -eq 1 ]]; then
    cp_flags+=("-L")
    log_verbose "Dereferencing symlink: $src"
  else
    cp_flags+=("-P")
    log_verbose "Preserving symlink: $src"
  fi

  log_verbose "Copying: $src -> $dest_file"

  # Early return for dry-run mode
  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    # shellcheck disable=SC2145
    log_dry_run "cp ${cp_flags[*]} \"$src\" \"$dest_file\""
    return 0
  fi

  # Attempt copy operation
  if ! cp "${cp_flags[@]}" "$src" "$dest_file" 2>/dev/null; then
    log_error "Failed to copy: $src -> $dest_file"
    if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
      FLAG_ABORT_REQUESTED=1
      log_verbose "Fail-fast requested after copy failure"
    fi
    return 1
  fi

  # Success: copy completed
  return 0
}

##
# @description Copy single file or symlink with option-aware handling
# @arg $1 string Source file path
# @arg $2 string Destination path (file or directory)
# @example
#   OPERATION_MODE=$MODE_SKIP
#   copy_single_item "/path/to/source.txt" "/path/to/dest.txt"
# @exitcode 0 If copy succeeds or file skipped
# @exitcode 1 If copy fails
# @see assess_copy_preconditions perform_copy_operation resolve_destination_path
copy_single_item() {
  local src="$1"
  local dest="$2"
  local dest_file
  local precondition_status

  dest_file="$(resolve_destination_path "$src" "$dest")"

  # Check preconditions
  assess_copy_preconditions "$src" "$dest_file"
  precondition_status=$?
  case $precondition_status in
  0)
    ;;
  1)
    # Skipped - not an error
    return 0
    ;;
  2)
    # Error in precondition
    if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
      FLAG_ABORT_REQUESTED=1
      log_verbose "Fail-fast requested after precondition failure: $src -> $dest_file"
    fi
    return 1
    ;;
  esac

  # Perform copy operation
  if ! perform_copy_operation "$src" "$dest_file"; then
    return 1
  fi

  # Success
  return 0
}

# ============================================================================
# Core Operations - Directory Copy
# ============================================================================

##
# @description List direct children of a directory with type-prefixed encoding
# @arg $1 string Source directory path
# @arg $2 string Name of array variable to receive entries (`d:<path>` or `f:<path>`)
# @arg $3 [optional] integer Include hidden files flag (defaults to FLAG_INCLUDE_HIDDEN)
# @example
#   list_directory_entries "/path/to/src" entries
# @example
#   list_directory_entries "/path/to/src" entries 1
# @exitcode 0 If entries enumerated successfully
# @exitcode 1 If validation fails
# @see copy_directory_tree
list_directory_entries() {
  local target_dir="$1"
  local entries_var="$2"
  local include_hidden="${3:-$FLAG_INCLUDE_HIDDEN}"
  local -n entries_ref="$entries_var"
  local entry entry_basename prefix dotglob_state nullglob_state

  entries_ref=()

  if [[ ! -d "$target_dir" ]]; then
    log_error "Target is not a directory: $target_dir"
    return 1
  fi

  dotglob_state="$(shopt -p dotglob || true)"
  nullglob_state="$(shopt -p nullglob || true)"

  if [[ $include_hidden -eq 1 ]]; then
    shopt -s dotglob
  else
    shopt -u dotglob
  fi
  shopt -s nullglob

  for entry in "$target_dir"/*; do
    [[ -e "$entry" ]] || continue
    entry_basename="${entry##*/}"
    if [[ "$entry_basename" == "." || "$entry_basename" == ".." ]]; then
      continue
    fi
    if [[ -d "$entry" && ! -L "$entry" ]]; then
      prefix="d"
    else
      prefix="f"
    fi
    entries_ref+=("${prefix}:${entry}")
  done

  if [[ -n "$dotglob_state" ]]; then
    eval "$dotglob_state"
  else
    shopt -u dotglob
  fi

  if [[ -n "$nullglob_state" ]]; then
    eval "$nullglob_state"
  else
    shopt -u nullglob
  fi

  return 0
}

##
# @description Recursively copy directory contents using recursive approach
# @arg $1 string Source directory path
# @arg $2 string Destination directory path
# @example
#   FLAG_RECURSIVE=1
#   copy_directory_tree "/path/to/src" "/path/to/dest"
# @exitcode 0 If all entries copied successfully
# @exitcode 1 If any copy operation fails
# @see create_destination_directory copy_single_item
# @internal
#   Implementation: Recursive traversal using list_directory_entries()
#   - FLAG_INCLUDE_HIDDEN controls hidden files inclusion
#   - Symlinks to directories are NOT recursed (treated as files)
#   - Delegates file copying to copy_single_item for mode handling
copy_directory_tree() {
  local src="$1"
  local dest="$2"
  local dest_check_status=0
  local entry entry_type entry_path
  local src_path dest_path
  local -a entries=()
  local status=0

  # Validate source
  if ! validate_source "$src"; then
    return 1
  fi

  if [[ ! -d "$src" ]]; then
    log_error "Source is not a directory: $src"
    return 1
  fi

  # Ensure destination directory exists
  check_destination_directory "$dest"
  dest_check_status=$?
  case $dest_check_status in
  0)
    ;;
  2)
    if ! create_destination_directory "$dest"; then
      return 1
    fi
    ;;
  *)
    return 1
    ;;
  esac

  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    log_dry_run "find \"$src\" -type d -print0"
    log_dry_run "find \"$src\" \\( -type f -o -type l \\) -print0"
  fi

  if ! list_directory_entries "$src" entries; then
    return 1
  fi

  # Traverse directories first
  for entry in "${entries[@]}"; do
    entry_type="${entry%%:*}"
    entry_path="${entry#*:}"
    if [[ "$entry_type" != "d" ]]; then
      continue
    fi

    src_path="$entry_path"
    dest_path="$dest/$(basename "$entry_path")"

    if ! create_destination_directory "$dest_path"; then
      status=1
      if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
        return 1
      fi
      continue
    fi

    log_verbose "Recursing into directory: $src_path"
    if ! copy_directory_tree "$src_path" "$dest_path"; then
      status=1
      if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
        return 1
      fi
    fi
  done

  # Then process files and symlinks
  for entry in "${entries[@]}"; do
    entry_type="${entry%%:*}"
    entry_path="${entry#*:}"
    if [[ "$entry_type" != "f" ]]; then
      continue
    fi

    src_path="$entry_path"
    dest_path="$dest/$(basename "$entry_path")"

    if ! copy_single_item "$src_path" "$dest_path"; then
      status=1
      if [[ $FLAG_FAIL_FAST -eq 1 && $FLAG_ABORT_REQUESTED -eq 1 ]]; then
        return 1
      fi
    fi
  done

  # Early return for error: any operation failed
  if [[ $status -ne 0 ]]; then
    return 1
  fi

  # Success: all operations completed
  return 0
}

# ============================================================================
# Main Processing Functions
# ============================================================================

##
# @description Main entry point for xcp.sh
# @arg $@ All command-line arguments
# @example
#   main "$@"
# @exitcode 0 If all operations succeeded
# @exitcode 1 If any errors occurred
# @see init_variables parse_args check_destination_directory validate_source copy_single_item copy_directory_tree
main() {
  # Parse arguments
  if ! parse_args "$@"; then
    return 1
  fi

  # Validate destination
  local dest_dir
  if [[ -d "$DEST_ARG" ]]; then
    dest_dir="$DEST_ARG"
  else
    dest_dir="$(dirname "$DEST_ARG")"
  fi

  local dest_check_status=0
  check_destination_directory "$dest_dir"
  dest_check_status=$?
  case $dest_check_status in
  0)
    ;;
  2)
    if ! create_destination_directory "$dest_dir"; then
      return 1
    fi
    ;;
  *)
    return 1
    ;;
  esac

  # Process each source
  local src
  for src in "${SOURCE_ARGS[@]}"; do
    if ! validate_source "$src"; then
      if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
        return 1
      fi
      continue
    fi

    if [[ -d "$src" ]]; then
      if [[ $FLAG_RECURSIVE -eq 0 ]]; then
        log_error "Skipping directory (use -r): $src"
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
        continue
      fi

      # Determine destination path for directory
      local dest_path
      if [[ -d "$DEST_ARG" ]]; then
        dest_path="$DEST_ARG/$(basename "$src")"
      else
        dest_path="$DEST_ARG"
      fi

      if ! copy_directory_tree "$src" "$dest_path"; then
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
      fi
    else
      if ! copy_single_item "$src" "$DEST_ARG"; then
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
      fi
    fi
  done

  # Report errors if any
  local error_count
  error_count=$(logger_get_error_count)
  if [[ $error_count -gt 0 ]]; then
    log_error "Completed with $error_count error(s)"
    return 1
  fi

  return 0
}

# ============================================================================
# Arguments & Command Variables
# ============================================================================

##
# @description Source file/directory arguments (array)
# @see init_variables
declare -a SOURCE_ARGS

##
# @description Destination file/directory argument
# @see init_variables
DEST_ARG=

# ============================================================================
# Help & Version Functions
# ============================================================================

##
# @description Display help message (extracted from file header @help block)
# @stdout Help text with usage and options
show_help() {
  sed -n '/^# @help<</,/^#<</p' "${BASH_SOURCE[0]}" |
    sed '1d;$d' |
    sed 's/^# //' |
    sed 's/^#$//' |
    sed "s/<SCRIPT_NAME>/$SCRIPT_NAME/g"
  echo ""
  return 0
}

##
# @description Display version information (extracted from file header @license)
# @stdout Version and copyright information
show_version() {
  local copyright_lines
  copyright_lines=$(sed -n '1,/^$/p' "${BASH_SOURCE[0]}" |
    sed -n '/^# @license/,/^$/p' |
    sed '1d;$d' |
    sed 's/^# //' |
    sed 's/^#$//' |
    sed '/^$/d')

  printf '%s version %s\n\n%s\n\n' "$SCRIPT_NAME" "$VERSION" "$copyright_lines"
  return 0
}

# ============================================================================
# Argument Parsing
# ============================================================================

##
# @description Parse command-line arguments
# @arg $@ All command-line arguments
# @exitcode 0 If arguments parsed successfully
# @exitcode 1 If arguments invalid or help/version requested
parse_args() {
  local -a sources=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      return 1
      ;;
    -V | --version)
      show_version
      return 1
      ;;
    -n | --noclobber)
      OPERATION_MODE=$MODE_SKIP
      shift
      ;;
    -f | --force)
      OPERATION_MODE=$MODE_OVERWRITE
      shift
      ;;
    -u | --update)
      OPERATION_MODE=$MODE_UPDATE
      shift
      ;;
    -b | --backup)
      OPERATION_MODE=$MODE_BACKUP
      shift
      ;;
    -r | -R | --recursive)
      FLAG_RECURSIVE=1
      shift
      ;;
    -p | --parents)
      FLAG_PARENTS=1
      shift
      ;;
    -L | --dereference)
      FLAG_DEREFERENCE=1
      shift
      ;;
    -H | --hidden)
      FLAG_INCLUDE_HIDDEN=1
      shift
      ;;
    --dry-run)
      FLAG_DRY_RUN=1
      shift
      ;;
    --fail-fast)
      FLAG_FAIL_FAST=1
      shift
      ;;
    -v | --verbose)
      logger_set_level "$LOGGER_LEVEL_VERBOSE"
      shift
      ;;
    -q | --quiet)
      logger_set_level "$LOGGER_LEVEL_ERROR"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      log_error "Unknown option: $1"
      show_help >&2
      return 1
      ;;
    *)
      sources+=("$1")
      shift
      ;;
    esac
  done

  # Collect remaining arguments as sources
  while [[ $# -gt 0 ]]; do
    sources+=("$1")
    shift
  done

  # Validate argument count
  if [[ ${#sources[@]} -lt 2 ]]; then
    log_error "Missing arguments: at least SOURCE and DEST required"
    show_help >&2
    return 1
  fi

  # Last argument is destination
  DEST_ARG="${sources[-1]}"
  unset 'sources[-1]'

  # Remaining arguments are sources
  SOURCE_ARGS=("${sources[@]}")

  return 0
}

# ============================================================================
# Script Entry Point
# ============================================================================
init_variables
# Execute main function only when script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
