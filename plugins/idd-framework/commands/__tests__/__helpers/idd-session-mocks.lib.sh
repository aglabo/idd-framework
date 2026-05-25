#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/idd-session-mocks.lib.sh
# @(#): IDD session management mock library for testing
#
# @file idd-session-mocks.lib.sh
# @brief Provides mock implementations for IDD session management functions
# @description
#   This library provides reusable mock functions for IDD session operations.
#   Mocks include session loading, saving, file validation, and content extraction.
#
#   Key features:
#   - Configurable mock behavior via environment variables
#   - Failure mode support for error testing
#   - Compatible with both integration and E2E tests
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/idd-session-mocks.lib.sh
#   setup_idd_session_mocks
#
#   # Configure mock behavior
#   mock_session_load_fails=1    # Force session load to fail
#   mock_session_filename="new-test"
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Mock State Variables
# =============================================================================

# Session operations
: "${mock_session_load_fails:=0}"          # 0=success, 1=fail
: "${mock_session_save_fails:=0}"          # 0=success, 1=fail
: "${mock_session_filename:=new-bug-login}"
: "${mock_session_issue_number:=}"
: "${mock_session_title:=Test Issue Title}"
: "${mock_session_issue_type:=bug}"
: "${mock_session_commit_type:=fix}"
: "${mock_session_branch_type:=fix}"

# File operations
: "${mock_file_not_found:=0}"              # 0=file exists, 1=not found
: "${mock_file_exists:=1}"                 # 1=file exists, 0=not found (for _validate_issue_file)

# Content extraction
: "${mock_extract_fails:=0}"               # 0=success, 1=fail
: "${mock_extracted_title:=}"
: "${mock_extracted_body:=Test issue body content with details.}"

# =============================================================================
# Session Management Mocks
# =============================================================================

##
# @description Setup mock for _load_issue_session function
# @noargs
# @exitcode 0 Always successful
setup_load_session_mock() {
  _load_issue_session() {
    if [[ "${mock_session_load_fails:-0}" -eq 1 ]]; then
      echo "❌ Error: Session file not found"
      return 1
    fi

    # Load mock session data into global variables
    filename="${mock_session_filename:-new-bug-login}"
    issue_number="${mock_session_issue_number:-}"
    command="push"
    TITLE="${mock_session_title:-Test Issue Title}"
    title="${TITLE}"  # Set both uppercase and lowercase for compatibility
    ISSUE_TYPE="${mock_session_issue_type:-bug}"
    COMMIT_TYPE="${mock_session_commit_type:-fix}"
    BRANCH_TYPE="${mock_session_branch_type:-fix}"
    return 0
  }
}

##
# @description Setup mock for _save_issue_session function
# @noargs
# @exitcode 0 Always successful
setup_save_session_mock() {
  _save_issue_session() {
    if [[ "${mock_session_save_fails:-0}" -eq 1 ]]; then
      return 1
    fi

    # Record session save for verification in tests
    saved_session_filename="$2"
    saved_session_issue_number="$3"
    saved_session_command="$4"
    return 0
  }
}

# =============================================================================
# File Operation Mocks
# =============================================================================

##
# @description Setup mock for _validate_issue_file function
# @noargs
# @exitcode 0 Always successful
setup_validate_file_mock() {
  _validate_issue_file() {
    local dir="$1"
    local fname="$2"

    if [[ "${mock_file_not_found:-0}" -eq 1 ]] || [[ "${mock_file_exists:-1}" -eq 0 ]]; then
      echo "❌ Error: Issue file not found: $dir/${fname}.md"
      return 1
    fi

    issue_file="$dir/${fname}.md"
    return 0
  }
}

##
# @description Setup mock for _extract_issue_content function
# @noargs
# @exitcode 0 Always successful
setup_extract_content_mock() {
  _extract_issue_content() {
    if [[ "${mock_extract_fails:-0}" -eq 1 ]]; then
      echo "❌ Error: Failed to extract title"
      return 1
    fi

    # Set both TITLE and title for compatibility
    TITLE="${mock_extracted_title:-${TITLE}}"
    title="${TITLE}"
    body="${mock_extracted_body:-Test issue body content with details.}"
    return 0
  }
}

# =============================================================================
# Prerequisite Check Mock
# =============================================================================

##
# @description Setup mock for check_prerequisites function
# @noargs
# @exitcode 0 Always successful
setup_check_prerequisites_mock() {
  check_prerequisites() {
    if [[ "${mock_gh_not_found:-0}" -eq 1 ]]; then
      return 1
    fi
    if [[ "${mock_gh_not_authenticated:-0}" -eq 1 ]]; then
      return 2
    fi
    return 0
  }
}

# =============================================================================
# Convenience Functions
# =============================================================================

##
# @description Setup all IDD session mocks at once
# @noargs
# @exitcode 0 Always successful
# @example
#   setup_idd_session_mocks
setup_idd_session_mocks() {
  setup_load_session_mock
  setup_save_session_mock
  setup_validate_file_mock
  setup_extract_content_mock
  setup_check_prerequisites_mock
}

##
# @description Reset all IDD session mock state variables to defaults
# @noargs
# @exitcode 0 Always successful
reset_idd_session_mock_state() {
  mock_session_load_fails=0
  mock_session_save_fails=0
  mock_session_filename="new-bug-login"
  mock_session_issue_number=""
  mock_session_title="Test Issue Title"
  mock_session_issue_type="bug"
  mock_session_commit_type="fix"
  mock_session_branch_type="fix"

  mock_file_not_found=0
  mock_file_exists=1

  mock_extract_fails=0
  mock_extracted_title=""
  mock_extracted_body="Test issue body content with details."

  mock_gh_not_found=0
}
