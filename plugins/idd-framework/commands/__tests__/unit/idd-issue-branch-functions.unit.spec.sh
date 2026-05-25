#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-functions.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch domain detection function
#
# @file idd-issue-branch-functions.unit.spec.sh
# @brief Unit tests for detect_domain() function (T3)
# @description
#   Unit test suite for domain detection functionality in /idd:issue:branch command.
#   Tests cover all BDD verification items from tasks.md T3.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Direct function calls with various inputs
#
#   Covered functionality:
#   - T3-1: Extract domain from [domain] pattern in title
#   - T3-2: Default to issue_type when no brackets
#   - T3-3: Support DOMAIN variable for --domain option override
#   - T3-4: Map issue_type to default domains (bug→bugfix, etc.)
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

Describe '_get_domain_from_issue_type() - T3 issue type mapping'

  # ============================================================================
  # T3-4: Simple issue type to domain mapping tests
  # ============================================================================

  Describe 'Given: issue type mapping'
    Context 'When: issue_type is provided'
      Parameters
        "bug" "bugfix"
        "feature" "feature"
        "enhancement" "enhancement"
        "task" "task"
        "custom-type" "custom-type"
      End

      It 'Then: [正常] - returns mapped domain for "%1" → "%2"'
        When call _get_domain_from_issue_type "$1"
        The output should equal "$2"
        The status should equal 0
      End
    End
  End

End

Describe 'detect_domain() - T3 priority-based coordinator'

  # ============================================================================
  # T3-3: --domain option override (DOMAIN variable)
  # ============================================================================

  Describe 'Given: --domain option override (DOMAIN variable)'
    Context 'When: DOMAIN variable is set to "scripts"'
      setup_domain_override() {
        export DOMAIN="scripts"
      }
      cleanup_domain_override() {
        unset DOMAIN
      }
      Before 'setup_domain_override'
      After 'cleanup_domain_override'

      It 'Then: [正常] - returns "scripts" (option priority)'
        When call detect_domain "Add feature" "feature"
        The output should equal "scripts"
        The status should equal 0
      End

      It 'Then: [正常] - overrides [domain] pattern in title'
        When call detect_domain "[claude-commands] Add feature" "feature"
        The output should equal "scripts"
        The status should equal 0
      End

      It 'Then: [正常] - overrides issue_type mapping'
        When call detect_domain "Fix bug" "bug"
        The output should equal "scripts"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # T3: Priority chain test (Priority 2-3: Codex disabled, fallback to mapping)
  # ============================================================================
  # Note: Codex inference is tested manually or in integration tests
  # Unit tests use no_codex="no_codex" parameter to test fallback behavior only

  Describe 'Given: Codex disabled (no_codex="no_codex"), uses fallback mapping'
    Context 'When: fallback to issue_type mapping'
      It 'Then: [正常] - returns mapped domain via _get_domain_from_issue_type()'
        When call detect_domain "Fix validation bug" "bug" "no_codex"
        The output should equal "bugfix"
        The status should equal 0
      End

      It 'Then: [正常] - returns "feature" for feature type'
        When call detect_domain "Add feature" "feature" "no_codex"
        The output should equal "feature"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # Edge Cases
  # ============================================================================

  Describe 'Given: edge cases and boundary conditions'
    Context 'When: issue_type is empty (uses default "feature")'
      It 'Then: [エッジケース] - uses default "feature" (no_codex)'
        When call detect_domain "Add feature" "" "no_codex"
        The output should equal "feature"
        The status should equal 0
      End
    End

    Context 'When: title is empty'
      It 'Then: [エッジケース] - returns issue_type mapping (no_codex)'
        When call detect_domain "" "bug" "no_codex"
        The output should equal "bugfix"
        The status should equal 0
      End
    End

    Context 'When: DOMAIN variable is empty string'
      setup_empty_domain() {
        export DOMAIN=""
      }
      cleanup_empty_domain() {
        unset DOMAIN
      }
      Before 'setup_empty_domain'
      After 'cleanup_empty_domain'

      It 'Then: [エッジケース] - falls back to mapping (empty DOMAIN, no_codex)'
        When call detect_domain "Add utility" "feature" "no_codex"
        The output should equal "feature"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # T5: Base Branch Determination
  # ============================================================================

  Describe 'Given: determine_base_branch function'
    Context 'When: no --base option (base_override is empty)'
      It 'Then: [正常] - returns current branch as base'
        When call determine_base_branch "main" ""
        The output should equal "main"
        The status should equal 0
      End

      It 'Then: [正常] - returns feature branch as base when on feature branch'
        When call determine_base_branch "feat-123/test" ""
        The output should equal "feat-123/test"
        The status should equal 0
      End
    End

    Context 'When: --base option is specified (base_override has value)'
      It 'Then: [正常] - returns specified base branch (develop)'
        When call determine_base_branch "main" "develop"
        The output should equal "develop"
        The status should equal 0
      End

      It 'Then: [正常] - returns specified base branch (main) when on different branch'
        When call determine_base_branch "feat-123/test" "main"
        The output should equal "main"
        The status should equal 0
      End

      It 'Then: [正常] - overrides current branch with custom base'
        When call determine_base_branch "develop" "release/v1.0"
        The output should equal "release/v1.0"
        The status should equal 0
      End
    End

    Context 'When: edge cases'
      It 'Then: [エッジケース] - handles empty current branch'
        When call determine_base_branch "" ""
        The output should equal ""
        The status should equal 0
      End

      It 'Then: [エッジケース] - base_override takes precedence even with empty current'
        When call determine_base_branch "" "main"
        The output should equal "main"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # T4: Branch Name Generation
  # ============================================================================

  Describe 'Given: generate_branch_name function'
    # Source filename-utils.lib.sh for generate_slug dependency
    LIBS_DIR="$SHELLSPEC_PROJECT_ROOT/.claude/commands/_libs"
    Include "$LIBS_DIR/filename-utils.lib.sh"

    Context 'When: generating basic branch name'
      Parameters
        "feat" "27" "claude-commands" "Add branch command" "feat-27/claude-commands/add-branch-command"
      End

      It 'Then: [正常] - returns correct branch name format'
        When call generate_branch_name "$1" "$2" "$3" "$4"
        The output should equal "$5"
        The status should equal 0
      End
    End

    Context 'When: title is very long (60 characters)'
      long_title="This is a very long title that exceeds fifty character limit"

      # Helper function to validate max length
      is_max_50_chars() {
        [ "${#1}" -le 50 ]
      }

      # Helper function to validate slug format (lowercase, numbers, hyphens only)
      is_valid_slug_format() {
        # Check if string contains only lowercase letters, numbers, and hyphens
        case "$1" in
          *[!a-z0-9-]*) return 1 ;;  # Contains invalid chars
          *) return 0 ;;               # Valid format
        esac
      }

      It 'Then: [正常] - slug is truncated to max 50 chars'
        result=$(generate_branch_name "feat" "28" "scripts" "$long_title")
        slug_part="${result##*/}"  # Extract slug part after last /
        The variable slug_part should not be blank
        # Check slug length is at most 50 characters
        The value "$slug_part" should satisfy is_max_50_chars
      End

      It 'Then: [正常] - slug is lowercase with hyphens'
        result=$(generate_branch_name "feat" "28" "scripts" "$long_title")
        slug_part="${result##*/}"
        # Slug should contain only lowercase letters, numbers, and hyphens
        The value "$slug_part" should satisfy is_valid_slug_format
      End
    End

    Context 'When: title has special characters'
      It 'Then: [正常] - converts to Git-compatible characters only'
        When call generate_branch_name "feat" "29" "scripts" "Add feature (WIP)"
        The output should equal "feat-29/scripts/add-feature-wip"
        The status should equal 0
      End
    End

    Context 'When: issue number is "new"'
      It 'Then: [正常] - returns branch name with "new" in format'
        When call generate_branch_name "feat" "new" "claude-commands" "Add new feature"
        The output should equal "feat-new/claude-commands/add-new-feature"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # T6: Branch Session Save
  # ============================================================================

  Describe 'Given: save_branch_session function'
    Context 'When: saving new branch session (T6-1)'
      # Setup test environment
      setup_branch_session_test() {
        TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
        mkdir -p "$TEST_ISSUES_DIR"
        TEST_SESSION_FILE="$TEST_ISSUES_DIR/.branch.session"
      }
      cleanup_branch_session_test() {
        rm -rf "$SHELLSPEC_TMPBASE/issues"
      }
      Before 'setup_branch_session_test'
      After 'cleanup_branch_session_test'

      It 'Then: [正常] - creates .branch.session file with all required fields'
        When call save_branch_session \
          "$TEST_ISSUES_DIR" \
          "feat-27/claude-commands/add-branch-command" \
          "claude-commands" \
          "main" \
          "27"
        The status should equal 0
        The file "$TEST_SESSION_FILE" should be exist

        # Verify required fields (with double quotes from _save_session format)
        The contents of file "$TEST_SESSION_FILE" should include 'suggested_branch="feat-27/claude-commands/add-branch-command"'
        The contents of file "$TEST_SESSION_FILE" should include 'domain="claude-commands"'
        The contents of file "$TEST_SESSION_FILE" should include 'base_branch="main"'
        The contents of file "$TEST_SESSION_FILE" should include 'issue_number="27"'
        The contents of file "$TEST_SESSION_FILE" should include "LAST_MODIFIED="
      End
    End

    Context 'When: overwriting existing session (T6-2)'
      # Setup with existing session
      setup_existing_session() {
        TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
        mkdir -p "$TEST_ISSUES_DIR"
        TEST_SESSION_FILE="$TEST_ISSUES_DIR/.branch.session"

        # Create initial session using save_branch_session
        save_branch_session \
          "$TEST_ISSUES_DIR" \
          "old-branch-name" \
          "old-domain" \
          "old-base" \
          "99"
      }
      cleanup_existing_session() {
        rm -rf "$SHELLSPEC_TMPBASE/issues"
      }
      Before 'setup_existing_session'
      After 'cleanup_existing_session'

      It 'Then: [正常] - overwrites existing session with new data'
        When call save_branch_session \
          "$TEST_ISSUES_DIR" \
          "feat-30/scripts/new-feature" \
          "scripts" \
          "develop" \
          "30"
        The status should equal 0
        The file "$TEST_SESSION_FILE" should be exist

        # Verify new data (with double quotes from _save_session format)
        The contents of file "$TEST_SESSION_FILE" should include 'suggested_branch="feat-30/scripts/new-feature"'
        The contents of file "$TEST_SESSION_FILE" should include 'domain="scripts"'
        The contents of file "$TEST_SESSION_FILE" should include 'base_branch="develop"'
        The contents of file "$TEST_SESSION_FILE" should include 'issue_number="30"'

        # Verify old data is replaced
        The contents of file "$TEST_SESSION_FILE" should not include "old-branch-name"
        The contents of file "$TEST_SESSION_FILE" should not include "old-domain"
        The contents of file "$TEST_SESSION_FILE" should not include "old-base"
        The contents of file "$TEST_SESSION_FILE" should not include 'issue_number="99"'
      End
    End

    # ============================================================================
    # T7: Branch Session Load
    # ============================================================================

    Describe 'Given: load_branch_session function'
      Context 'When: loading existing session (T7-1)'
        # Setup test environment with existing session
        setup_load_session_test() {
          TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
          mkdir -p "$TEST_ISSUES_DIR"
          TEST_SESSION_FILE="$TEST_ISSUES_DIR/.branch.session"

          # Create test session file
          save_branch_session \
            "$TEST_ISSUES_DIR" \
            "feat-40/scripts/test-feature" \
            "scripts" \
            "main" \
            "40"
        }
        cleanup_load_session_test() {
          rm -rf "$SHELLSPEC_TMPBASE/issues"
        }
        Before 'setup_load_session_test'
        After 'cleanup_load_session_test'

        It 'Then: [正常] - loads all session variables correctly'
          When call load_branch_session "$TEST_ISSUES_DIR"
          The status should equal 0
          The output should be blank
        End

        It 'Then: [正常] - exports all session variables'
          # Call function to export variables
          load_branch_session "$TEST_ISSUES_DIR"

          # Verify all exported variables
          The variable SUGGESTED_BRANCH should equal "feat-40/scripts/test-feature"
          The variable DOMAIN should equal "scripts"
          The variable BASE_BRANCH should equal "main"
          The variable ISSUE_NUMBER should equal "40"
          The variable LAST_MODIFIED should not be blank
        End
      End

      Context 'When: session file does not exist (T7-2)'
        # Setup test environment without session file
        setup_no_session() {
          TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
          mkdir -p "$TEST_ISSUES_DIR"
        }
        cleanup_no_session() {
          rm -rf "$SHELLSPEC_TMPBASE/issues"
        }
        Before 'setup_no_session'
        After 'cleanup_no_session'

        It 'Then: [異常] - returns error status'
          When call load_branch_session "$TEST_ISSUES_DIR"
          The status should equal 1
          The error should include "Session file not found"
        End
      End

      Context 'When: session file is corrupted (T7-3)'
        # Setup with corrupted session file
        setup_corrupted_session() {
          TEST_ISSUES_DIR="$SHELLSPEC_TMPBASE/issues"
          mkdir -p "$TEST_ISSUES_DIR"
          TEST_SESSION_FILE="$TEST_ISSUES_DIR/.branch.session"

          # Create corrupted session file (invalid format)
          cat > "$TEST_SESSION_FILE" << 'EOF'
# Corrupted session
invalid_format_line_without_equals
EOF
        }
        cleanup_corrupted_session() {
          rm -rf "$SHELLSPEC_TMPBASE/issues"
        }
        Before 'setup_corrupted_session'
        After 'cleanup_corrupted_session'

        It 'Then: [異常] - returns error status'
          When call load_branch_session "$TEST_ISSUES_DIR"
          The status should equal 1
          The error should include "Failed to load session file"
        End
      End

      Context 'When: issues_dir parameter is missing (T7-4)'
        It 'Then: [異常] - returns error status'
          When call load_branch_session ""
          The status should equal 1
          The error should include "issues_dir required"
        End
      End
    End
  End

End
