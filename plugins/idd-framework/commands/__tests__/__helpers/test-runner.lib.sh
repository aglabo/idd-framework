#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/test-runner.lib.sh
# @(#): Common test runner library for shellspec tests
#
# @file test-runner.lib.sh
# @brief Provides common test runner functions for all test levels
# @description
#   This library provides reusable functions for running shellspec tests
#   across different test levels (unit, functional, integration, e2e).
#   Includes colored output, test discovery, and execution logic.
#
# @example Basic usage
#   source .claude/commands/__tests__/__helpers/test-runner.lib.sh
#
#   check_shellspec || exit 1
#   test_files=$(find_tests_by_level "unit") || exit 1
#   run_tests_for_level "unit" "$test_files"
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Color Constants
# =============================================================================

##
# @description ANSI color codes for terminal output
readonly TEST_RED='\033[0;31m'
readonly TEST_GREEN='\033[0;32m'
readonly TEST_YELLOW='\033[1;33m'
readonly TEST_NC='\033[0m' # No Color

# =============================================================================
# Test Level Configuration
# =============================================================================

##
# @description Map test level to directory name and file pattern
# @internal
declare -A TEST_LEVEL_DIRS=(
  ["unit"]="unit"
  ["functional"]="functional"
  ["integration"]="integration"
  ["e2e"]="e2e"
)

declare -A TEST_LEVEL_PATTERNS=(
  ["unit"]="*.unit.spec.sh"
  ["functional"]="*.functional.spec.sh"
  ["integration"]="*.integration.spec.sh"
  ["e2e"]="*.e2e.spec.sh"
)

declare -A TEST_LEVEL_NAMES=(
  ["unit"]="Unit"
  ["functional"]="Functional"
  ["integration"]="Integration"
  ["e2e"]="E2E"
)

# =============================================================================
# Output Functions
# =============================================================================

##
# @brief Print colored message to stdout
# @param $1 Color code (TEST_RED, TEST_GREEN, TEST_YELLOW, TEST_NC)
# @param $2 Message text
# @stdout Colored message
# @exitcode 0 Always successful
print_test_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${TEST_NC}"
}

##
# @brief Print test runner header
# @param $1 Test level name (e.g., "Unit", "E2E")
# @stdout Formatted header
# @exitcode 0 Always successful
print_test_header() {
  local level_name="$1"
  print_test_message "$TEST_GREEN" "=========================================="
  print_test_message "$TEST_GREEN" "  ${level_name} Tests Runner"
  print_test_message "$TEST_GREEN" "=========================================="
  echo ""
}

##
# @brief Print list of test files
# @param $1 Base directory (SCRIPT_DIR)
# @param $2 Test files (newline-separated)
# @stdout Formatted file list
# @exitcode 0 Always successful
print_test_files() {
  local base_dir="$1"
  local test_files="$2"

  print_test_message "$TEST_YELLOW" "📋 Test files:"
  while IFS= read -r file; do
    local rel_path="${file#"$base_dir"/}"
    echo "  - $rel_path"
  done <<< "$test_files"
  echo ""
}

##
# @brief Print test result summary
# @param $1 Test level name
# @param $2 Exit code from shellspec
# @stdout Result message
# @exitcode Same as $2
print_test_result() {
  local level_name="$1"
  local exit_code="$2"

  echo ""
  print_test_message "$TEST_GREEN" "=========================================="

  if [[ "$exit_code" -eq 0 ]]; then
    print_test_message "$TEST_GREEN" "  ✅ All ${level_name} tests passed!"
  else
    print_test_message "$TEST_RED" "  ❌ Some ${level_name} tests failed"
  fi

  print_test_message "$TEST_GREEN" "=========================================="

  return "$exit_code"
}

# =============================================================================
# Prerequisite Checks
# =============================================================================

##
# @brief Check if shellspec is available
# @stdout Error message if not found
# @exitcode 0 shellspec found
# @exitcode 1 shellspec not found
check_shellspec() {
  if ! command -v shellspec &> /dev/null; then
    print_test_message "$TEST_RED" "❌ Error: shellspec not found"
    echo ""
    echo "Please install shellspec:"
    echo "  npm install -g shellspec"
    echo ""
    return 1
  fi
  return 0
}

# =============================================================================
# Test Discovery Functions
# =============================================================================

##
# @brief Find all test files for a given test level
# @param $1 Test level (unit|functional|integration|e2e)
# @param $2 Base test directory (optional, defaults to current dir)
# @stdout Newline-separated list of test file paths
# @exitcode 0 Tests found
# @exitcode 1 No tests found or invalid level
find_tests_by_level() {
  local level="$1"
  local base_dir="${2:-.}"

  # Validate test level
  if [[ ! -v TEST_LEVEL_DIRS[$level] ]]; then
    print_test_message "$TEST_RED" "❌ Error: Invalid test level '$level'"
    return 1
  fi

  local test_dir="$base_dir/${TEST_LEVEL_DIRS[$level]}"
  local pattern="${TEST_LEVEL_PATTERNS[$level]}"

  # Check if directory exists
  if [[ ! -d "$test_dir" ]]; then
    print_test_message "$TEST_YELLOW" "⚠️  Warning: ${level} directory not found: $test_dir"
    return 1
  fi

  # Find test files and filter out those with '# skip shellspec' marker
  local test_files=""
  local file
  for file in $(find "$test_dir" -name "$pattern" -type f | sort); do
    # Check first 5 lines for skip marker
    if ! head -n 5 "$file" 2>/dev/null | grep -q '^# skip shellspec'; then
      test_files="${test_files}${file}"$'\n'
    fi
  done

  test_files="${test_files%$'\n'}"  # Remove trailing newline

  if [[ -z "$test_files" ]]; then
    print_test_message "$TEST_YELLOW" "⚠️  Warning: No ${level} tests found in $test_dir"
    return 1
  fi

  echo "$test_files"
}

##
# @brief Get display name for test level
# @param $1 Test level (unit|functional|integration|e2e)
# @stdout Test level display name
# @exitcode 0 Always successful
get_level_name() {
  local level="$1"
  echo "${TEST_LEVEL_NAMES[$level]:-$level}"
}

# =============================================================================
# Test Execution Functions
# =============================================================================

##
# @brief Run shellspec tests for a specific test level
# @param $1 Test level (unit|functional|integration|e2e)
# @param $2 Test files (newline-separated paths)
# @stdout shellspec output
# @exitcode 0 All tests passed
# @exitcode 1 Some tests failed
run_shellspec_tests() {
  local test_files="$1"

  print_test_message "$TEST_GREEN" "🚀 Running tests..."
  echo ""

  # shellspec executes tests and returns exit code
  # shellcheck disable=SC2086
  shellspec $test_files
}

##
# @brief Complete test execution workflow for a test level
# @param $1 Test level (unit|functional|integration|e2e)
# @param $2 Base test directory
# @param $3 Script directory (for relative path display)
# @param $4 Optional: Specific test file to run (relative to base_dir or absolute path)
# @stdout Test execution output
# @exitcode 0 All tests passed
# @exitcode 1 Tests failed or not found
run_tests_for_level() {
  local level="$1"
  local base_dir="$2"
  local script_dir="$3"
  local test_file="${4:-}"

  local level_name
  level_name=$(get_level_name "$level")

  # Print header
  print_test_header "$level_name"

  # Check prerequisites
  if ! check_shellspec; then
    return 1
  fi

  local test_files

  # If specific test file is provided
  if [[ -n "$test_file" ]]; then
    # Resolve absolute path
    local abs_test_file
    if [[ "$test_file" = /* ]]; then
      abs_test_file="$test_file"
    else
      abs_test_file="$base_dir/$test_file"
    fi

    # Validate file exists
    if [[ ! -f "$abs_test_file" ]]; then
      print_test_message "$TEST_RED" "❌ Error: Test file not found: $test_file"
      return 1
    fi

    # Validate file matches level pattern
    local pattern="${TEST_LEVEL_PATTERNS[$level]}"
    local basename="${abs_test_file##*/}"
    if [[ ! "$basename" == $pattern ]]; then
      print_test_message "$TEST_RED" "❌ Error: File '$test_file' does not match ${level} test pattern ($pattern)"
      return 1
    fi

    test_files="$abs_test_file"
    print_test_message "$TEST_GREEN" "✓ Using specified test file"
    echo ""
  else
    # Find all test files in directory (existing behavior)
    print_test_message "$TEST_YELLOW" "📁 Searching for ${level} tests..."
    if ! test_files=$(find_tests_by_level "$level" "$base_dir"); then
      return 1
    fi

    local test_count
    test_count=$(echo "$test_files" | wc -l)
    print_test_message "$TEST_GREEN" "✓ Found $test_count ${level} test file(s)"
    echo ""
  fi

  # List test files
  print_test_files "$script_dir" "$test_files"

  # Run tests
  local exit_code=0
  run_shellspec_tests "$test_files" || exit_code=$?

  # Print results
  print_test_result "$level_name" "$exit_code"

  return "$exit_code"
}
