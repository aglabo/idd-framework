#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/run-tests.sh
# @(#): Unified test runner for all test levels
#
# @file run-tests.sh
# @brief Execute shellspec tests for specified test level
# @description
#   This script provides a unified interface for running tests at different levels.
#   Supports unit, functional, integration, e2e tests, and can run all levels sequentially.
#
#   Test hierarchy:
#   - unit: Individual function tests
#   - functional: Feature-level tests
#   - integration: Component integration tests
#   - e2e: End-to-end workflow tests
#
# @usage
#   ./run-tests.sh <subcommand> [test_file]
#
# @arg $1 Subcommand (unit|functional|integration|e2e|all|--help|-h)
# @arg $2 Optional: Specific test file to run (relative to test directory)
#
# @example Run unit tests
#   ./run-tests.sh unit
#
# @example Run specific unit test file
#   ./run-tests.sh unit unit/merge-json.unit.spec.sh
#
# @example Run all tests
#   ./run-tests.sh all
#
# @example Show help
#   ./run-tests.sh --help
#
# @exitcode 0 All tests passed
# @exitcode 1 One or more tests failed
# @exitcode 2 Invalid arguments or missing prerequisites
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# =============================================================================
# Directory Setup
# =============================================================================

# Get script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test runner library
# shellcheck source=./.claude/commands/__tests__/__helpers/test-runner.lib.sh
if [[ ! -f "$SCRIPT_DIR/__helpers/test-runner.lib.sh" ]]; then
  echo "Error: test-runner.lib.sh not found" >&2
  exit 2
fi

. "$SCRIPT_DIR/__helpers/test-runner.lib.sh"

# =============================================================================
# Help Functions
# =============================================================================

##
# @brief Display usage information
# @stdout Help message
# @exitcode 0 Always successful
show_help() {
  cat << 'EOF'
Usage: run-tests.sh <subcommand> [test_file]

Unified test runner for shellspec tests across all test levels.

Subcommands:
  unit          Run unit tests only
  functional    Run functional tests only
  integration   Run integration tests only
  e2e           Run end-to-end tests only
  all           Run all test levels sequentially
  --help, -h    Show this help message

Arguments:
  test_file     Optional: Specific test file to run (relative to test directory)
                Only applicable for single-level subcommands (not 'all')

Test Levels:
  unit          Individual function tests
  functional    Feature-level tests
  integration   Component integration tests
  e2e           End-to-end workflow tests

Examples:
  ./run-tests.sh unit                              # Run all unit tests
  ./run-tests.sh unit unit/merge-json.unit.spec.sh # Run specific unit test
  ./run-tests.sh functional functional/xcp-validation.functional.spec.sh
  ./run-tests.sh all                               # Run all tests
  ./run-tests.sh --help                            # Show help

Exit Codes:
  0   All tests passed
  1   One or more tests failed
  2   Invalid arguments or missing prerequisites

EOF
}

# =============================================================================
# Subcommand Handlers
# =============================================================================

##
# @brief Run tests for a single test level
# @param $1 Test level (unit|functional|integration|e2e)
# @param $@ Additional arguments (optional test file path)
# @exitcode 0 Tests passed
# @exitcode 1 Tests failed
run_single_level() {
  local level="$1"
  shift

  run_tests_for_level "$level" "$SCRIPT_DIR" "$SCRIPT_DIR" "$@"
}

##
# @brief Run all test levels sequentially
# @exitcode 0 All tests passed
# @exitcode 1 One or more test levels failed
run_all_levels() {
  local levels=("unit" "functional" "integration" "e2e")
  local failed_levels=()
  local exit_code=0

  print_test_message "$TEST_GREEN" "=========================================="
  print_test_message "$TEST_GREEN" "  Running All Test Levels"
  print_test_message "$TEST_GREEN" "=========================================="
  echo ""

  for level in "${levels[@]}"; do
    print_test_message "$TEST_YELLOW" "📦 Starting ${level} tests..."
    echo ""

    if ! run_single_level "$level"; then
      failed_levels+=("$level")
      exit_code=1
    fi

    echo ""
    echo ""
  done

  # Print final summary
  print_test_message "$TEST_GREEN" "=========================================="
  print_test_message "$TEST_GREEN" "  Final Summary"
  print_test_message "$TEST_GREEN" "=========================================="
  echo ""

  if [[ "$exit_code" -eq 0 ]]; then
    print_test_message "$TEST_GREEN" "✅ All test levels passed!"
  else
    print_test_message "$TEST_RED" "❌ Failed test levels:"
    for level in "${failed_levels[@]}"; do
      echo "  - $level"
    done
  fi

  echo ""
  print_test_message "$TEST_GREEN" "=========================================="

  return "$exit_code"
}

# =============================================================================
# Argument Validation
# =============================================================================

##
# @brief Validate subcommand argument
# @param $1 Subcommand
# @exitcode 0 Valid subcommand
# @exitcode 1 Invalid subcommand
validate_subcommand() {
  local subcommand="$1"
  local valid_commands=("unit" "functional" "integration" "e2e" "all" "--help" "-h")

  for cmd in "${valid_commands[@]}"; do
    if [[ "$subcommand" == "$cmd" ]]; then
      return 0
    fi
  done

  return 1
}

# =============================================================================
# Main Execution
# =============================================================================

##
# @brief Main entry point
# @param $@ Command-line arguments
# @exitcode 0 Success
# @exitcode 1 Tests failed
# @exitcode 2 Invalid arguments
main() {
  # Check arguments
  if [[ $# -eq 0 ]]; then
    print_test_message "$TEST_RED" "❌ Error: No subcommand specified"
    echo ""
    show_help
    exit 2
  fi

  local subcommand="$1"
  shift

  # Handle help
  if [[ "$subcommand" == "--help" || "$subcommand" == "-h" ]]; then
    show_help
    exit 0
  fi

  # Validate subcommand
  if ! validate_subcommand "$subcommand"; then
    print_test_message "$TEST_RED" "❌ Error: Invalid subcommand '$subcommand'"
    echo ""
    show_help
    exit 2
  fi

  # Route to appropriate handler
  case "$subcommand" in
    all)
      run_all_levels
      ;;
    unit|functional|integration|e2e)
      run_single_level "$subcommand" "$@"
      ;;
    *)
      print_test_message "$TEST_RED" "❌ Error: Unexpected subcommand '$subcommand'"
      exit 2
      ;;
  esac
}

# Execute main function
main "$@"
