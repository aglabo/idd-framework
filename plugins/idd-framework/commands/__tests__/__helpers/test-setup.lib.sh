#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/test-setup.lib.sh
# @(#): Common test setup and teardown helpers
#
# @file test-setup.lib.sh
# @brief Provides common test setup and cleanup functions
# @description
#   This library provides reusable setup and teardown functions for tests.
#   Includes environment initialization, cleanup, and mock state management.
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/test-setup.lib.sh
#   . .claude/commands/__tests__/__helpers/gh-mocks.lib.sh
#   . .claude/commands/__tests__/__helpers/idd-session-mocks.lib.sh
#
#   BeforeAll 'setup_test_environment'
#   AfterAll 'cleanup_test_environment'
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Environment Setup Functions
# =============================================================================

##
# @description Setup test environment with temp directories and session files
# @noargs
# @global ISSUES_DIR Created temporary issues directory
# @global SESSION_FILE Session file path
# @exitcode 0 Always successful
setup_test_env() {
  # Create temp directories
  ISSUES_DIR=$(mktemp -d)
  SESSION_FILE="$ISSUES_DIR/.last.session"

  # Reset all mock variables
  reset_all_mock_state

  # Reset global variables
  unset filename issue_number issue_file TITLE title body new_filename
  unset saved_session_filename saved_session_issue_number saved_session_command
}

##
# @description Clean up test environment
# @noargs
# @global ISSUES_DIR Issues directory to remove
# @exitcode 0 Always successful
cleanup_test_env() {
  if [[ -n "${ISSUES_DIR:-}" && -d "$ISSUES_DIR" ]]; then
    rm -rf "$ISSUES_DIR"
  fi
}

# =============================================================================
# Mock State Management
# =============================================================================

##
# @description Reset all mock state variables to defaults
# @noargs
# @exitcode 0 Always successful
reset_all_mock_state() {
  # Reset gh mock state
  if declare -F reset_gh_mock_state &>/dev/null; then
    reset_gh_mock_state
  fi

  # Reset IDD session mock state
  if declare -F reset_idd_session_mock_state &>/dev/null; then
    reset_idd_session_mock_state
  fi

  # Additional resets for test-specific variables
  mock_gh_not_found=0
  mock_new_issue_number=42
}

# =============================================================================
# Convenience Setup Functions
# =============================================================================

##
# @description Setup complete test environment with all mocks
# @noargs
# @exitcode 0 Always successful
# @example
#   BeforeAll 'setup_complete_test_environment'
setup_complete_test_environment() {
  setup_test_env

  # Setup all mocks if their setup functions are available
  if declare -F setup_gh_mock &>/dev/null; then
    setup_gh_mock
  fi

  if declare -F setup_idd_session_mocks &>/dev/null; then
    setup_idd_session_mocks
  fi

  if declare -F setup_push_functions &>/dev/null; then
    setup_push_functions
  fi

  if declare -F setup_main_routine &>/dev/null; then
    setup_main_routine
  fi
}

##
# @description Alias for setup_test_env (for compatibility)
# @noargs
# @exitcode 0 Always successful
setup_test_environment() {
  setup_test_env
}

##
# @description Alias for cleanup_test_env (for compatibility)
# @noargs
# @exitcode 0 Always successful
cleanup_test_environment() {
  cleanup_test_env
}

# =============================================================================
# Per-Test Reset Functions
# =============================================================================

##
# @description Reset environment for each test (use in BeforeEach)
# @noargs
# @exitcode 0 Always successful
reset_for_each_test() {
  reset_all_mock_state

  # Ensure ISSUES_DIR exists
  if [[ -n "${ISSUES_DIR:-}" ]]; then
    mkdir -p "$ISSUES_DIR"
  fi
}
