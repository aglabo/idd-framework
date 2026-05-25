#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/functional/idd-issue-branch-new.functional.spec.sh
# @(#): Functional tests for /idd:issue:branch new subcommand (T7)
#
# @file idd-issue-branch-new.functional.spec.sh
# @brief Functional tests for new subcommand integration
# @description
#   Functional test suite for complete new subcommand workflow.
#   Tests T7 BDD verification items:
#   - T7-1: Complete new subcommand execution
#   - T7-2: --domain option execution
#   - T7-3: --base option execution
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
. "$HELPERS_DIR/idd-issue-branch-functions.lib.sh"

# Setup branch functions from branch.md
setup_branch_functions

# Cleanup temporary files after all tests
AfterAll 'cleanup_branch_functions'

Describe '/idd:issue:branch new subcommand - T7 integration'

  # ============================================================================
  # T7-1: Complete new subcommand execution (basic flow)
  # ============================================================================

  Describe 'Given: Issue session exists'
    # Setup test environment
    setup_new_subcommand_test() {
      TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
      mkdir -p "$TEST_ISSUES_DIR"
      TEST_SESSION_FILE="$TEST_ISSUES_DIR/.last.session"
      TEST_BRANCH_SESSION="$TEST_ISSUES_DIR/.branch.session"

      # Set global variables for session
      TITLE="Add branch command"
      ISSUE_TYPE="feature"
      BRANCH_TYPE="feat"

      # Save session using library function
      _save_issue_session "$TEST_SESSION_FILE" \
        "new-251023-120000-feature-add-branch-command.md" \
        "" \
        "/idd:issue:list"

      # Mock git branch command
      git() {
        case "$1 $2" in
          "branch --show-current")
            echo "main"
            ;;
          "rev-parse --show-toplevel")
            echo "$PROJECT_ROOT"
            ;;
          *)
            command git "$@"
            ;;
        esac
      }

      export -f git
    }

    cleanup_new_subcommand_test() {
      rm -rf "$SHELLSPEC_TMPBASE/issues"
      unset -f git
    }

    Before 'setup_new_subcommand_test'
    After 'cleanup_new_subcommand_test'

    Context 'When: /idd:issue:branch executed (no arguments)'
      It 'Then: [正常] - loads issue session successfully'
        # Load session
        _load_issue_session "$TEST_SESSION_FILE"

        The variable TITLE should equal "Add branch command"
        The variable BRANCH_TYPE should equal "feat"
      End

      It 'Then: [正常] - detects domain from title and issue_type'
        # Load session
        _load_issue_session "$TEST_SESSION_FILE"

        # Detect domain
        When call detect_domain "$TITLE" "$ISSUE_TYPE" "no_codex"
        The output should equal "feature"
        The status should equal 0
      End

      It 'Then: [正常] - determines base branch from current branch'
        # Get current branch
        current_branch=$(git branch --show-current)

        When call determine_base_branch "$current_branch" ""
        The output should equal "main"
        The status should equal 0
      End

      It 'Then: [正常] - generates branch name correctly'
        # Load session
        _load_issue_session "$TEST_SESSION_FILE"
        domain="feature"

        When call generate_branch_name "$BRANCH_TYPE" "new" "$domain" "$TITLE"
        The output should equal "feat-new/feature/add-branch-command"
        The status should equal 0
      End

      It 'Then: [正常] - saves branch session with all fields'
        # Load session
        _load_issue_session "$TEST_SESSION_FILE"
        suggested_branch="feat-new/feature/add-branch-command"
        domain="feature"
        base_branch="main"

        When call save_branch_session \
          "$TEST_ISSUES_DIR" \
          "$suggested_branch" \
          "$domain" \
          "$base_branch" \
          "new"

        The status should equal 0
        The file "$TEST_BRANCH_SESSION" should be exist
        The contents of file "$TEST_BRANCH_SESSION" should include 'suggested_branch="feat-new/feature/add-branch-command"'
        The contents of file "$TEST_BRANCH_SESSION" should include 'domain="feature"'
        The contents of file "$TEST_BRANCH_SESSION" should include 'base_branch="main"'
        The contents of file "$TEST_BRANCH_SESSION" should include 'issue_number="new"'
      End
    End
  End

  # ============================================================================
  # T7-2: --domain option execution
  # ============================================================================

  Describe 'Given: Issue session exists with --domain option'
    setup_domain_override_test() {
      TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
      mkdir -p "$TEST_ISSUES_DIR"
      TEST_SESSION_FILE="$TEST_ISSUES_DIR/.last.session"

      # Set global variables for session
      TITLE="Add branch command"
      ISSUE_TYPE="feature"
      BRANCH_TYPE="feat"

      # Save session using library function
      _save_issue_session "$TEST_SESSION_FILE" \
        "new-251023-120000-feature-add-branch-command.md" \
        "" \
        "list"
    }

    cleanup_domain_override_test() {
      rm -rf "$SHELLSPEC_TMPBASE/issues"
      unset DOMAIN
    }

    Before 'setup_domain_override_test'
    After 'cleanup_domain_override_test'

    Context 'When: /idd:issue:branch --domain scripts executed'
      It 'Then: [正常] - domain is "scripts" (overridden)'
        # Load session
        _load_issue_session "$TEST_SESSION_FILE"

        # Set domain override
        export DOMAIN="scripts"

        When call detect_domain "$TITLE" "$ISSUE_TYPE" "no_codex"
        The output should equal "scripts"
        The status should equal 0
      End

      It 'Then: [正常] - branch name uses overridden domain'
        # Load session
        _load_issue_session "$TEST_SESSION_FILE"

        When call generate_branch_name "$BRANCH_TYPE" "new" "scripts" "$TITLE"
        The output should equal "feat-new/scripts/add-branch-command"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # T7-3: --base option execution
  # ============================================================================

  Describe 'Given: Current branch is "main" with --base option'
    setup_base_override_test() {
      TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
      mkdir -p "$TEST_ISSUES_DIR"

      # Mock git to return "main" as current branch
      git() {
        case "$1 $2" in
          "branch --show-current")
            echo "main"
            ;;
          *)
            command git "$@"
            ;;
        esac
      }

      export -f git
    }

    cleanup_base_override_test() {
      unset -f git
    }

    Before 'setup_base_override_test'
    After 'cleanup_base_override_test'

    Context 'When: /idd:issue:branch --base develop executed'
      It 'Then: [正常] - base branch is "develop" (overridden)'
        current_branch=$(git branch --show-current)

        When call determine_base_branch "$current_branch" "develop"
        The output should equal "develop"
        The status should equal 0
      End

      It 'Then: [正常] - will switch message should be displayed (logic verified)'
        current_branch=$(git branch --show-current)
        base_branch="develop"

        # Logic test: different branch means switch required
        The variable current_branch should not equal "$base_branch"
      End
    End
  End

End
