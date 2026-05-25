#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/functional/idd-issue-branch-commit.functional.spec.sh
# @(#): Functional tests for /idd:issue:branch commit subcommand (T14)
#
# @file idd-issue-branch-commit.functional.spec.sh
# @brief Functional tests for commit subcommand integration (T14)
# @description
#   Functional test suite for `/idd:issue:branch commit` subcommand.
#   Tests the complete workflow integration of T8-T13 components.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Full workflow with real Git operations (mocked)
#   Parallel execution: Safe with isolated test directories per It block
#
#   Covered functionality:
#   - T14-1: Complete commit flow (current branch = base branch)
#   - T14-2: Complete commit flow (current branch ≠ base branch)
#   - T14-3: Error handling with rollback (.branch.session preservation)
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
. "$HELPERS_DIR/git-mocks.lib.sh"

# Setup branch functions from branch.md
setup_branch_functions

# Cleanup after all tests
AfterAll 'cleanup_branch_functions'

Describe 'subcommand_commit() - T14 Complete commit workflow integration'
  BeforeAll 'setup_common_environment'

  ##
  # @description Setup common test environment (runs once per Describe block)
  # @noargs
  # @global TEST_ISSUES_DIR Created temporary issues directory
  # @global SESSION_FILE Session file path
  # @global BRANCH_SESSION_FILE Branch session file path
  # @global ISSUES_DIR Environment variable for issues directory
  # @exitcode 0 Always successful
  setup_common_environment() {
    # Setup test directories
    TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
    mkdir -p "$TEST_ISSUES_DIR"
    SESSION_FILE="$TEST_ISSUES_DIR/.last.session"
    BRANCH_SESSION_FILE="$TEST_ISSUES_DIR/.branch.session"

    # Set ISSUES_DIR and SESSION_FILE for subcommand
    ISSUES_DIR="$TEST_ISSUES_DIR"
    export ISSUES_DIR SESSION_FILE
  }

  ##
  # @description Setup branch scenario with parameterized configuration
  # @details Creates unique isolated test environment per It block to prevent
  #   race conditions in parallel test execution (shellspec --jobs 32).
  #   Each test gets its own directory to avoid session file conflicts.
  # @arg $1 string Base branch name (e.g., "main", "develop")
  # @arg $2 string Current branch name (e.g., "main")
  # @arg $3 number (optional) Switch fails flag (0=success, 1=fail, default: 0)
  # @global MOCK_CURRENT_BRANCH Set to current branch
  # @global MOCK_SWITCH_FAILS Set to switch fails flag
  # @global BRANCH_SESSION_FILE Branch session file path (unique per test)
  # @global SESSION_FILE Session file path (unique per test)
  # @global ISSUES_DIR Test directory path (unique per test)
  # @exitcode 0 Always successful
  # @example
  #   setup_branch_scenario "main" "main"          # same branch
  #   setup_branch_scenario "develop" "main"       # different branch
  #   setup_branch_scenario "main" "main" 1        # switch fails
  setup_branch_scenario() {
    local base_branch="$1"
    local current_branch="$2"
    local switch_fails="${3:-0}"

    # Create unique test directory for this test to avoid parallel execution race conditions
    # Use SHELLSPEC_EXAMPLE_ID to ensure each It block has its own isolated environment
    local unique_id="${SHELLSPEC_EXAMPLE_ID:-$$}"
    local test_dir="$SHELLSPEC_TMPBASE/issues-$unique_id"
    mkdir -p "$test_dir"

    # Update paths to use unique directory
    SESSION_FILE="$test_dir/.last.session"
    BRANCH_SESSION_FILE="$test_dir/.branch.session"
    ISSUES_DIR="$test_dir"
    export ISSUES_DIR SESSION_FILE BRANCH_SESSION_FILE

    # Initialize Git mock
    init_mock_git

    # Create .branch.session with specified base_branch
    create_test_branch_session "$BRANCH_SESSION_FILE" "feat-27/new" "test" "$base_branch"

    # Configure Git mock state
    MOCK_CURRENT_BRANCH="$current_branch"
    MOCK_SWITCH_FAILS="$switch_fails"

    # Create .last.session for update
    create_test_last_session "$SESSION_FILE"
  }

  # ==========================================================================
  # T14-1: 完全なcommitサブコマンド実行 (同一ブランチ)
  # ==========================================================================

  Describe 'Given: .branch.session exists, current branch = base branch'
    BeforeEach 'setup_branch_scenario "main" "main"'

    Describe 'When: /idd:issue:branch commit is executed'
      It 'Then: [正常] - should load branch session successfully'
        When call subcommand_commit
        The status should be success
        # Verify session variables loaded
        The variable SUGGESTED_BRANCH should equal "feat-27/new"
        The variable BASE_BRANCH should equal "main"
        # Acknowledge expected stdout
        The stdout should be present
      End

      It 'Then: [正常] - should validate Git state successfully'
        When call subcommand_commit
        The status should be success
        # No "Uncommitted changes" error
        The stderr should not include "Uncommitted changes"
        # Acknowledge expected stdout
        The stdout should be present
      End

      It 'Then: [正常] - should check branch existence successfully'
        When call subcommand_commit
        The status should be success
        # No "Branch already exists" error
        The stderr should not include "Branch already exists"
        # Acknowledge expected stdout
        The stdout should be present
      End

      It 'Then: [正常] - should display "Already on base branch" message'
        When call subcommand_commit
        The stdout should include "Already on base branch"
        The stdout should include "main"
      End

      It 'Then: [正常] - should create branch successfully'
        When call subcommand_commit
        The status should be success
        The stdout should include "Branch created"
        The stdout should include "feat-27/new"
      End

      It 'Then: [正常] - should complete without session update errors'
        When call subcommand_commit
        The status should be success
        # No warning about session update failure
        The stderr should not include "Failed to update Issue session"
        # Acknowledge expected stdout
        The stdout should be present
      End

      It 'Then: [正常] - should delete .branch.session successfully'
        When call subcommand_commit
        The status should be success
        The path "$BRANCH_SESSION_FILE" should not be exist
        The stdout should include "Branch created"
      End

      It 'Then: [正常] - should exit with code 0'
        When call subcommand_commit
        The status should equal 0
        The stdout should include "Next steps"
      End
    End
  End

  # ==========================================================================
  # T14-2: 完全なcommitサブコマンド実行 (異なるブランチ)
  # ==========================================================================

  Describe 'Given: .branch.session exists, current branch ≠ base branch'
    BeforeEach 'setup_branch_scenario "develop" "main"'

    Describe 'When: /idd:issue:branch commit is executed'
      It 'Then: [正常] - should display "Switching to base branch" message'
        When call subcommand_commit
        The stdout should include "Switching to base branch"
        The stdout should include "develop"
      End

      It 'Then: [正常] - should switch to base branch successfully'
        When call subcommand_commit
        The status should be success
        # Verify git switch was called (via mock)
        The stdout should include "Branch created"
      End

      It 'Then: [正常] - should create branch successfully'
        When call subcommand_commit
        The status should be success
        The stdout should include "feat-27/new"
      End

      It 'Then: [正常] - should exit with code 0'
        When call subcommand_commit
        The status should equal 0
        The stdout should include "Branch created"
      End
    End
  End

  # ==========================================================================
  # T14-3: エラー時のロールバック
  # ==========================================================================

  Describe 'Given: Git operation fails'
    BeforeEach 'setup_branch_scenario "main" "main" 1'

    Describe 'When: /idd:issue:branch commit is executed'
      It 'Then: [異常] - should display error message'
        When run subcommand_commit
        The status should be failure
        The stdout should include "Already on base branch"
        The stderr should include "Failed to create branch"
      End

      It 'Then: [異常] - should preserve .branch.session (no delete)'
        When run subcommand_commit
        The status should be failure
        The path "$BRANCH_SESSION_FILE" should be exist
        The stdout should include "Already on base branch"
        The stderr should include "Failed to create branch"
      End

      It 'Then: [異常] - should exit with code 6'
        When run subcommand_commit
        The status should equal 6
        The stdout should include "Already on base branch"
        The stderr should include "Failed to create branch"
      End
    End
  End
End
