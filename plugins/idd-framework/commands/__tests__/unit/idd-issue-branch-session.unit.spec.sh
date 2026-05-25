#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-session.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch session update function
#
# @file idd-issue-branch-session.unit.spec.sh
# @brief Unit tests for update_session_with_branch() function (T12)
# @description
#   Unit test suite for session update functionality in /idd:issue:branch command.
#   Tests cover all BDD verification items from tasks.md T12.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Direct function calls with temporary session files
#
#   Covered functionality:
#   - T12-1: Add branch_name field to existing session
#   - T12-2: Overwrite existing branch_name in session
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"
HELPERS_DIR="$PROJECT_ROOT/.claude/commands/__tests__/__helpers"
. "$HELPERS_DIR/test-setup.lib.sh"
. "$HELPERS_DIR/idd-issue-branch-functions.lib.sh"

# Setup branch functions from branch.md
setup_branch_functions

# Cleanup temporary files after all tests
AfterAll 'cleanup_branch_functions'

# Test-specific setup
BeforeEach 'setup_session_test'
AfterEach 'cleanup_session_test'

# Setup function for each test
setup_session_test() {
  TEST_SESSION_FILE="${TMPDIR:-/tmp}/test-session-$$.sh"
}

# Cleanup function for each test
cleanup_session_test() {
  if [ -f "$TEST_SESSION_FILE" ]; then
    rm -f "$TEST_SESSION_FILE"
  fi
}

Describe 'update_session_with_branch() - T12 Session update functionality'

  # ============================================================================
  # T12-1: ブランチ名フィールド追加
  # ============================================================================

  Describe 'Given: existing .last.session without branch_name'
    # Create initial session without branch_name before each test
    BeforeEach 'create_initial_session'

    create_initial_session() {
      create_test_last_session "$TEST_SESSION_FILE"
    }

    Describe 'When: update_session_with_branch("feat-27/test") is called'
      It 'Then: [正常] - should add LAST_BRANCH_NAME field'
        When call update_session_with_branch "$TEST_SESSION_FILE" "feat-27/test"
        The status should be success
        The file "$TEST_SESSION_FILE" should be exist
        The contents of file "$TEST_SESSION_FILE" should include "LAST_BRANCH_NAME="
      End

      It 'Then: [正常] - should preserve existing fields'
        When call update_session_with_branch "$TEST_SESSION_FILE" "feat-27/test"
        The status should be success
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_ISSUE_FILE="issue-027-add-feature.md"'
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_ISSUE_NUMBER="027"'
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_COMMAND="new"'
      End

      It 'Then: [正常] - LAST_BRANCH_NAME should contain correct value'
        When call update_session_with_branch "$TEST_SESSION_FILE" "feat-27/test"
        The status should be success
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_BRANCH_NAME="feat-27/test"'
      End
    End
  End

  # ============================================================================
  # T12-2: 既存branch_name上書き
  # ============================================================================

  Describe 'Given: .last.session with existing LAST_BRANCH_NAME'
    # Create session with existing branch_name before each test
    BeforeEach 'create_session_with_branch'

    create_session_with_branch() {
      create_test_last_session "$TEST_SESSION_FILE" "old-branch"
    }

    Describe 'When: update_session_with_branch("new-branch") is called'
      It 'Then: [正常] - should update LAST_BRANCH_NAME to new value'
        When call update_session_with_branch "$TEST_SESSION_FILE" "new-branch"
        The status should be success
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_BRANCH_NAME="new-branch"'
      End

      It 'Then: [正常] - should not contain old branch name'
        When call update_session_with_branch "$TEST_SESSION_FILE" "new-branch"
        The status should be success
        The contents of file "$TEST_SESSION_FILE" should not include 'LAST_BRANCH_NAME="old-branch"'
      End

      It 'Then: [正常] - should preserve other fields'
        When call update_session_with_branch "$TEST_SESSION_FILE" "new-branch"
        The status should be success
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_ISSUE_FILE="issue-027-add-feature.md"'
        The contents of file "$TEST_SESSION_FILE" should include 'LAST_ISSUE_NUMBER="027"'
      End
    End
  End

  # ============================================================================
  # T13: ブランチセッション削除
  # ============================================================================

  Describe 'cleanup_branch_session() - T13 Branch session cleanup'

    # ============================================================================
    # T13-1: セッションファイル削除
    # ============================================================================

    Describe 'Given: .branch.session file exists'
      BeforeEach 'create_branch_session_file'

      create_branch_session_file() {
        create_test_branch_session "$TEST_SESSION_FILE" "feat-27/test"
      }

      Describe 'When: cleanup_branch_session() is called'
        It 'Then: [正常] - should delete .branch.session file'
          When call cleanup_branch_session "$TEST_SESSION_FILE"
          The status should be success
          The path "$TEST_SESSION_FILE" should not be exist
        End
      End
    End

    # ============================================================================
    # T13-2: ファイル不存在時の安全処理
    # ============================================================================

    Describe 'Given: .branch.session file does not exist'
      Describe 'When: cleanup_branch_session() is called'
        It 'Then: [正常] - should not error'
          When call cleanup_branch_session "$TEST_SESSION_FILE"
          The status should be success
        End

        It 'Then: [正常] - should exit successfully'
          When call cleanup_branch_session "$TEST_SESSION_FILE"
          The status should equal 0
        End
      End
    End
  End
End
