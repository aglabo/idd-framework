#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/e2e/idd-issue-push.e2e.spec.sh
# @(#): E2E tests for /idd:issue:push complete workflow
#
# @file idd-issue-push.e2e.spec.sh
# @brief End-to-end tests for complete Issue push workflow
# @description
#   E2E test suite for /idd:issue:push command main routine.
#   Tests complete workflow from prerequisites through GitHub push to next steps.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Mock external dependencies, execute main routine, verify state
#
#   Covered workflows:
#   - Complete new issue creation pipeline
#   - Complete existing issue update pipeline
#   - Error handling and exit codes
#   - Output validation and next steps
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
COMMANDS_ROOT="${COMMANDS_ROOT:-$PROJECT_ROOT/plugins/idd-framework/commands}"
HELPERS_DIR="$COMMANDS_ROOT/__tests__/__helpers"
. "$HELPERS_DIR/gh-mocks.lib.sh"
. "$HELPERS_DIR/idd-session-mocks.lib.sh"
. "$HELPERS_DIR/idd-issue-push-functions.lib.sh"
. "$HELPERS_DIR/test-setup.lib.sh"

Describe 'idd-issue-push - E2E workflow tests'
  # ============================================================================
  # Test Setup and Mocks
  # ============================================================================

  BeforeAll 'setup_test_env'
  BeforeAll 'setup_gh_mock'
  BeforeAll 'setup_idd_session_mocks'
  BeforeAll 'setup_push_functions'
  BeforeAll 'setup_main_routine'
  AfterAll 'cleanup_test_env'

  reset_e2e_env() {
    cleanup_test_env
    setup_test_env
    return 0
  }

  # ============================================================================
  # E2E Test Cases: New Issue Complete Workflow
  # ============================================================================

  Describe 'Given: Complete new issue workflow'
    reset_new_issue_state() {
      reset_e2e_env
      mock_session_filename="new-bug-login-20251022"
      mock_session_title="Bug: Login fails on mobile"

      # Create test issue file
      mkdir -p "$ISSUES_DIR"
      echo "# ${mock_session_title}" > "$ISSUES_DIR/${mock_session_filename}.md"
      echo "" >> "$ISSUES_DIR/${mock_session_filename}.md"
      echo "Test issue body content" >> "$ISSUES_DIR/${mock_session_filename}.md"
    }
    BeforeEach 'reset_new_issue_state'

    Context 'When: executing complete pipeline for new issue'
      It 'Then: [正常] - completes all steps successfully'
        When call main_routine
        The status should equal 0
        The output should include "🆕 Detected new issue"
        The output should include "✅ Issue created: #42"
        The output should include "✅ Renamed:"
        The output should include "💾 Session updated:"
        The output should include "💡 Next steps:"
      End

      It 'Then: [正常] - file renamed from new-* to {number}-*'
        When call main_routine
        The status should equal 0
        The path "$ISSUES_DIR/new-bug-login-20251022.md" should not be exist
        The path "$ISSUES_DIR/42-bug-login-20251022.md" should be exist
        The output should include "✅ Renamed: new-bug-login-20251022.md → 42-bug-login-20251022.md"
      End

      It 'Then: [正常] - session updated with new issue number and filename'
        When call main_routine
        The status should equal 0
        The variable saved_session_filename should equal "42-bug-login-20251022"
        The variable saved_session_issue_number should equal "42"
        The variable saved_session_command should equal "push"
        The output should include "💾 Session updated: 42-bug-login-20251022 (#42)"
      End

      It 'Then: [正常] - displays all next step suggestions'
        When call main_routine
        The output should include "/idd:issue:view"
        The output should include "/idd:issue:branch"
        The output should include "/idd:issue:list"
      End
    End

    Context 'When: verifying issue creation details'
      It 'Then: [正常] - issue_number variable set to created issue'
        When call main_routine
        The status should equal 0
        The variable issue_number should equal "42"
        The output should include "✅ Issue created: #42"
      End

      It 'Then: [正常] - new_filename variable set to renamed file'
        When call main_routine
        The status should equal 0
        The variable new_filename should equal "42-bug-login-20251022"
        The output should include "✅ Renamed:"
      End
    End
  End

  # ============================================================================
  # E2E Test Cases: Existing Issue Complete Workflow
  # ============================================================================

  Describe 'Given: Complete existing issue workflow'
    reset_existing_issue_state() {
      reset_e2e_env
      mock_session_filename="123-feature-auth"
      mock_session_issue_number="123"
      mock_session_title="Feature: Add OAuth authentication"

      # Create test issue file
      mkdir -p "$ISSUES_DIR"
      echo "# ${mock_session_title}" > "$ISSUES_DIR/${mock_session_filename}.md"
      echo "" >> "$ISSUES_DIR/${mock_session_filename}.md"
      echo "Updated issue body content" >> "$ISSUES_DIR/${mock_session_filename}.md"
    }
    BeforeEach 'reset_existing_issue_state'

    Context 'When: executing complete pipeline for existing issue'
      It 'Then: [正常] - completes all steps successfully'
        When call main_routine
        The status should equal 0
        The output should include "📝 Detected existing issue #123"
        The output should include "✅ Issue updated: #123"
        The output should include "💾 Session updated:"
        The output should include "💡 Next steps:"
      End

      It 'Then: [正常] - filename unchanged (no rename)'
        When call main_routine
        The status should equal 0
        The path "$ISSUES_DIR/123-feature-auth.md" should be exist
        The variable new_filename should be undefined
        The output should include "📝 Detected existing issue #123"
      End

      It 'Then: [正常] - session updated with same filename'
        When call main_routine
        The status should equal 0
        The variable saved_session_filename should equal "123-feature-auth"
        The variable saved_session_issue_number should equal "123"
        The output should include "💾 Session updated: 123-feature-auth (#123)"
      End
    End

    Context 'When: verifying issue update details'
      It 'Then: [正常] - issue_number extracted from filename'
        When call main_routine
        The status should equal 0
        The variable issue_number should equal "123"
        The output should include "📝 Detected existing issue #123"
      End

      It 'Then: [正常] - displays update confirmation'
        When call main_routine
        The output should include "Issue updated: #123"
        The output should include "URL: https://github.com/user/repo/issues/123"
      End
    End
  End

  # ============================================================================
  # E2E Test Cases: Error Handling
  # ============================================================================

  Describe 'Given: Error handling in main workflow'
    reset_error_test() {
      reset_e2e_env
    }
    BeforeEach 'reset_error_test'

    Context 'When: prerequisites check fails'
      It 'Then: [異常] - exits with code 1 when gh not found'
        mock_gh_not_found=1
        When call main_routine
        The status should equal 1
        The output should include "❌ Error: 'gh' command not found"
        The output should include "💡 Please install GitHub CLI"
      End

      It 'Then: [異常] - exits with code 2 when authentication required'
        mock_gh_not_authenticated=1
        When call main_routine
        The status should equal 2
        The output should include "❌ Error: GitHub authentication required"
        The output should include "💡 Run: gh auth login"
      End
    End

    Context 'When: session operations fail'
      It 'Then: [異常] - exits with code 1 when session load fails'
        mock_session_load_fails=1
        When call main_routine
        The status should equal 1
        The output should include "❌ Error: Session file not found"
      End

      It 'Then: [異常] - exits with code 1 when file validation fails'
        mock_session_filename="new-test"
        mock_file_not_found=1
        When call main_routine
        The status should equal 1
        The output should include "❌ Error: Issue file not found"
      End

      It 'Then: [異常] - exits with code 1 when content extraction fails'
        mock_session_filename="new-test"
        mock_extract_fails=1
        mkdir -p "$ISSUES_DIR"
        touch "$ISSUES_DIR/new-test.md"
        When call main_routine
        The status should equal 1
        The output should include "❌ Error: Failed to extract title"
      End
    End

    Context 'When: GitHub operations fail (new issue)'
      It 'Then: [異常] - exits with code 5 when gh issue create fails'
        set_gh_mock_failure issue
        mock_session_filename="new-test"
        mkdir -p "$ISSUES_DIR"
        touch "$ISSUES_DIR/new-test.md"
        When call main_routine
        The status should equal 5
        The output should include "❌ Failed to create issue on GitHub"
        The output should not include "✅ Issue created"
      End
    End

    Context 'When: GitHub operations fail (existing issue)'
      It 'Then: [異常] - exits with code 8 when gh issue edit fails'
        set_gh_mock_failure issue
        mock_session_filename="123-test"
        mock_session_issue_number="123"
        mkdir -p "$ISSUES_DIR"
        touch "$ISSUES_DIR/123-test.md"
        When call main_routine
        The status should equal 8
        The output should include "❌ Failed to update issue #123"
      End
    End

    Context 'When: file rename operations fail'
      It 'Then: [異常] - exits with code 9 when source file not found after creation'
        mock_session_filename="new-missing"
        # Don't create the file to simulate rename failure
        When call main_routine
        The status should equal 9
        The output should include "❌ Source file not found"
      End

      It 'Then: [異常] - exits with code 10 when target file already exists'
        mock_session_filename="new-conflict"
        mkdir -p "$ISSUES_DIR"
        touch "$ISSUES_DIR/new-conflict.md"
        touch "$ISSUES_DIR/42-conflict.md"  # Conflict file
        When call main_routine
        The status should equal 10
        The output should include "❌ Target file already exists"
      End
    End

    Context 'When: session save fails after push'
      It 'Then: [異常] - exits with code 1 and shows warning'
        mock_session_filename="new-test"
        mock_session_save_fails=1
        mkdir -p "$ISSUES_DIR"
        touch "$ISSUES_DIR/new-test.md"
        When call main_routine
        The status should equal 1
        The output should include "⚠️ Warning: Failed to update session"
      End
    End
  End

  # ============================================================================
  # E2E Test Cases: Output Validation
  # ============================================================================

  Describe 'Given: Output and next steps validation'
    reset_output_test() {
      reset_e2e_env
      mock_session_filename="new-test-output"
      mkdir -p "$ISSUES_DIR"
      touch "$ISSUES_DIR/new-test-output.md"
    }
    BeforeEach 'reset_output_test'

    Context 'When: workflow completes successfully'
      It 'Then: [正常] - displays emoji-rich status messages'
        When call main_routine
        The output should include "🆕"
        The output should include "📤"
        The output should include "✅"
        The output should include "💾"
        The output should include "💡"
      End

      It 'Then: [正常] - outputs structured progress messages'
        When call main_routine
        The line 1 should include "Detected new issue"
        The output should include "Creating new issue on GitHub"
        The output should include "Issue created:"
        The output should include "Renamed:"
        The output should include "Session updated:"
      End

      It 'Then: [正常] - displays complete next steps section'
        When call main_routine
        The output should include "Next steps:"
        The output should include "/idd:issue:view"
        The output should include "/idd:issue:branch"
        The output should include "/idd:issue:list"
      End
    End
  End

End
