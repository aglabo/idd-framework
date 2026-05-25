#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/integration/idd-issue-push.integration.spec.sh
# @(#): Integration tests for /idd:issue:push command
#
# @file idd-issue-push.integration.spec.sh
# @brief Integration tests for Issue push workflow with mocked dependencies
# @description
#   Mock-based integration test suite for /idd:issue:push command.
#   Tests core workflows without external dependencies (gh CLI, file system).
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Mock gh CLI, session management, and file operations
#
#   Covered workflows:
#   - New issue creation (T3)
#   - Existing issue update (T4)
#   - File rename operations (T5)
#   - Session management (T5)
#   - Error handling (all exit codes: 0,1,5,6,7,8,9,10)
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# Load helper libraries
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
HELPERS_DIR="$PROJECT_ROOT/.claude/commands/__tests__/__helpers"
. "$HELPERS_DIR/gh-mocks.lib.sh"
. "$HELPERS_DIR/idd-session-mocks.lib.sh"
. "$HELPERS_DIR/idd-issue-push-functions.lib.sh"
. "$HELPERS_DIR/test-setup.lib.sh"

Describe 'idd-issue-push - Integration tests with mocks'
  # ============================================================================
  # Test Setup and Mocks
  # ============================================================================

  BeforeAll 'setup_test_env'
  BeforeAll 'setup_gh_mock'
  BeforeAll 'setup_idd_session_mocks'
  AfterAll 'cleanup_test_env'
  BeforeAll 'setup_push_functions'

  # ============================================================================
  # Test Cases: parse_issue_number_from_url
  # ============================================================================

  Describe 'Given: parse_issue_number_from_url function'
    reset_issue_vars() {
      unset issue_number
    }
    BeforeEach 'reset_issue_vars'

    Context 'When: valid GitHub issue URL provided'
      It 'Then: [正常] - extracts issue number from URL'
        When call parse_issue_number_from_url "https://github.com/user/repo/issues/42"
        The status should be success
        The variable issue_number should equal 42
      End

      It 'Then: [正常] - extracts from URL with trailing content'
        When call parse_issue_number_from_url "Created: https://github.com/user/repo/issues/123 - Success"
        The status should be success
        The variable issue_number should equal 123
      End
    End

    Context 'When: invalid or missing URL provided'
      It 'Then: [異常] - returns error for non-URL text'
        When call parse_issue_number_from_url "No URL here"
        The status should be failure
        The output should include "Failed to parse issue number"
      End

      It 'Then: [異常] - returns error for incomplete URL'
        When call parse_issue_number_from_url "https://github.com/user/repo"
        The status should be failure
        The output should include "Failed to parse issue number"
      End

      It 'Then: [エッジケース] - returns error for empty string'
        When call parse_issue_number_from_url ""
        The status should be failure
        The output should include "❌ Failed to parse issue number"
      End
    End
  End

  # ============================================================================
  # Test Cases: push_new_issue
  # ============================================================================

  Describe 'Given: push_new_issue workflow'
    reset_push_new_vars() {
      unset issue_number issue_url
      reset_gh_mock_state
      mock_gh_fails=0
      mock_issue_number=42
    }
    BeforeEach 'reset_push_new_vars'

    Context 'When: creating new issue successfully'
      It 'Then: [正常] - creates issue and sets issue_number and issue_url'
        When call push_new_issue "Test Title" "Test Body"
        The status should equal 0
        The variable issue_number should equal 42
        The variable issue_url should equal "https://github.com/user/repo/issues/42"
        The output should include "✅ Issue created: #42"
      End

      It 'Then: [正常] - outputs creation messages'
        When call push_new_issue "Bug Fix" "Description"
        The output should include "🆕 Detected new issue"
        The output should include "📤 Creating new issue on GitHub"
      End
    End

    Context 'When: gh CLI fails (network/permission error)'
      It 'Then: [異常] - returns exit code 5'
        mock_gh_fails=1
        When call push_new_issue "Test" "Body"
        The status should equal 5
        The output should include "❌ Failed to create issue on GitHub"
        The output should include "💡 Check your network connection"
      End
    End

    Context 'When: URL parsing fails'
      It 'Then: [異常] - returns exit code 6 if gh returns invalid response'
        # Override gh to return invalid URL
        gh() {
          echo "Invalid response without URL"
          return 0
        }
        When call push_new_issue "Test" "Body"
        The status should equal 6
        The output should include "❌ Failed to parse issue number"
      End
    End
  End

  # ============================================================================
  # Test Cases: push_existing_issue
  # ============================================================================

  Describe 'Given: push_existing_issue workflow'
    reset_push_existing_vars() {
      unset issue_number
      reset_gh_mock_state
      mock_gh_fails=0
    }
    BeforeEach 'reset_push_existing_vars'

    Context 'When: updating existing issue successfully'
      It 'Then: [正常] - updates issue and extracts number from filename'
        When call push_existing_issue "42-bug-fix" "Updated Title" "Updated Body"
        The status should equal 0
        The variable issue_number should equal 42
        The output should include "✅ Issue updated: #42"
      End

      It 'Then: [正常] - outputs update messages'
        When call push_existing_issue "123-feature-request" "Title" "Body"
        The output should include "📝 Detected existing issue #123"
        The output should include "📤 Updating issue"
      End

      It 'Then: [正常] - handles multi-digit issue numbers'
        When call push_existing_issue "999-enhancement" "Title" "Body"
        The variable issue_number should equal 999
        The output should include "✅ Issue updated: #999"
      End
    End

    Context 'When: filename format is invalid'
      It 'Then: [異常] - returns exit code 7 for filename without number'
        When call push_existing_issue "invalid-filename" "Title" "Body"
        The status should equal 7
        The output should include "❌ Invalid filename format"
        The output should include "Expected format:"
        The output should include "new-*"
        The output should include "{number}-*"
      End

      It 'Then: [異常] - returns exit code 7 for new-* pattern in existing issue'
        When call push_existing_issue "new-bug-fix" "Title" "Body"
        The status should equal 7
        The output should include "❌ Invalid filename format"
      End
    End

    Context 'When: gh CLI fails (issue not found/permission error)'
      It 'Then: [異常] - returns exit code 8'
        mock_gh_fails=1
        When call push_existing_issue "42-test" "Title" "Body"
        The status should equal 8
        The output should include "❌ Failed to update issue #42"
        The output should include "💡 Check that issue #42 exists"
      End
    End
  End

  # ============================================================================
  # Test Cases: rename_new_issue_file
  # ============================================================================

  Describe 'Given: rename_new_issue_file workflow'
    reset_rename_vars() {
      unset new_filename
      mkdir -p "$ISSUES_DIR"
    }
    BeforeEach 'reset_rename_vars'

    Context 'When: renaming new-* file successfully'
      It 'Then: [正常] - renames to {number}-{suffix} format'
        # Create source file
        touch "$ISSUES_DIR/new-bug-login.md"

        When call rename_new_issue_file "new-bug-login" "42"
        The status should equal 0
        The variable new_filename should equal "42-bug-login"
        The path "$ISSUES_DIR/42-bug-login.md" should be exist
        The output should include "✅ Renamed: new-bug-login.md → 42-bug-login.md"

        # Cleanup
        rm -f "$ISSUES_DIR/42-bug-login.md"
      End

      It 'Then: [正常] - preserves suffix with timestamp'
        touch "$ISSUES_DIR/new-feature-auth-20251022.md"

        When call rename_new_issue_file "new-feature-auth-20251022" "123"
        The variable new_filename should equal "123-feature-auth-20251022"
        The path "$ISSUES_DIR/123-feature-auth-20251022.md" should be exist
        The output should include "✅ Renamed: new-feature-auth-20251022.md → 123-feature-auth-20251022.md"

        rm -f "$ISSUES_DIR/123-feature-auth-20251022.md"
      End
    End

    Context 'When: source file does not exist'
      It 'Then: [異常] - returns exit code 9'
        When call rename_new_issue_file "new-nonexistent" "42"
        The status should equal 9
        The output should include "❌ Source file not found"
      End
    End

    Context 'When: target file already exists (conflict)'
      It 'Then: [異常] - returns exit code 10'
        # Create both source and target files
        touch "$ISSUES_DIR/new-duplicate.md"
        touch "$ISSUES_DIR/42-duplicate.md"

        When call rename_new_issue_file "new-duplicate" "42"
        The status should equal 10
        The output should include "❌ Target file already exists"
        The output should include "💡 Please resolve the conflict"

        # Cleanup
        rm -f "$ISSUES_DIR/new-duplicate.md" "$ISSUES_DIR/42-duplicate.md"
      End
    End

    Context 'When: filename format is invalid'
      It 'Then: [異常] - returns exit code 9 for non-new-* filename'
        When call rename_new_issue_file "invalid-filename" "42"
        The status should equal 9
        The output should include "❌ Invalid filename format"
        The output should include "Expected format: new-*"
      End
    End
  End

  # ============================================================================
  # Test Cases: update_session_after_push
  # ============================================================================

  Describe 'Given: update_session_after_push workflow'
    reset_session_vars() {
      mock_session_save_fails=0
      TITLE="Test Title"
      ISSUE_TYPE="bug"
      COMMIT_TYPE="fix"
      BRANCH_TYPE="fix"
    }
    BeforeEach 'reset_session_vars'

    Context 'When: session save succeeds'
      It 'Then: [正常] - updates session file successfully'
        When call update_session_after_push "42-bug-fix" "42"
        The status should equal 0
        The output should include "💾 Session updated: 42-bug-fix (#42)"
      End
    End

    Context 'When: session save fails'
      It 'Then: [異常] - returns exit code 1'
        mock_session_save_fails=1
        When call update_session_after_push "42-test" "42"
        The status should equal 1
        The output should include "⚠️ Warning: Failed to update session"
      End
    End

    Context 'When: called with various filename patterns'
      It 'Then: [正常] - handles renamed files'
        When call update_session_after_push "123-feature-request" "123"
        The status should equal 0
        The output should include "💾 Session updated: 123-feature-request (#123)"
      End

      It 'Then: [正常] - handles complex suffixes'
        When call update_session_after_push "999-bug-auth-login-20251022" "999"
        The status should equal 0
        The output should include "💾 Session updated: 999-bug-auth-login-20251022 (#999)"
      End
    End
  End

End
