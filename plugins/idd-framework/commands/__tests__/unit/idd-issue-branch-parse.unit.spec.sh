#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-parse.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch subcommand parsing function
#
# @file idd-issue-branch-parse.unit.spec.sh
# @brief Unit tests for parse_subcommand_and_options() function
# @description
#   Unit test suite for argument parsing functionality in /idd:issue:branch command.
#   Tests cover all cases for subcommand and option parsing.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Direct function calls with various argument patterns
#
#   Covered functionality:
#   - Default subcommand "new" when no arguments
#   - Subcommand explicit + options
#   - Options only → default "new" + options
#   - Subcommand only (no options)
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

Describe 'parse_subcommand_and_options() - argument parsing'
  # ============================================================================
  # Case 1: No arguments → default 'new' with no options
  # ============================================================================

  Describe 'Given: no arguments'
    Context 'When: parse_subcommand_and_options is called without arguments'
      It 'Then: [正常] - sets SUBCOMMAND to "new"'
        When call parse_subcommand_and_options
        The variable SUBCOMMAND should equal "new"
      End

      It 'Then: [正常] - BRANCH_OPTIONS array is empty'
        When call parse_subcommand_and_options
        The value "${#BRANCH_OPTIONS[@]}" should equal 0
      End
    End
  End

  # ============================================================================
  # Case 2: Options only → default 'new' + options
  # ============================================================================

  Describe 'Given: options without explicit subcommand'
    Context 'When: first argument starts with "--"'
      It 'Then: [正常] - sets SUBCOMMAND to "new"'
        When call parse_subcommand_and_options --domain scripts
        The variable SUBCOMMAND should equal "new"
      End

      It 'Then: [正常] - BRANCH_OPTIONS contains options'
        When call parse_subcommand_and_options --domain scripts
        The value "${BRANCH_OPTIONS["domain"]}" should equal "scripts"
      End
    End

    Context 'When: multiple options are provided without subcommand'
      It 'Then: [正常] - sets SUBCOMMAND to "new"'
        When call parse_subcommand_and_options --domain claude-commands --base main
        The variable SUBCOMMAND should equal "new"
      End

      It 'Then: [正常] - BRANCH_OPTIONS contains all options'
        When call parse_subcommand_and_options --domain claude-commands --base main
        The value "${#BRANCH_OPTIONS[@]}" should equal 2
        The value "${BRANCH_OPTIONS["domain"]}" should equal "claude_commands"
        The value "${BRANCH_OPTIONS["base"]}" should equal "main"
      End
    End
  End

  # ============================================================================
  # Case 3: Subcommand explicit + options
  # ============================================================================

  Describe 'Given: explicit subcommand with options'
    Context 'When: subcommand "new" is provided with options'
      It 'Then: [正常] - sets SUBCOMMAND to "new"'
        When call parse_subcommand_and_options new --domain scripts --base develop
        The variable SUBCOMMAND should equal "new"
      End

      It 'Then: [正常] - BRANCH_OPTIONS contains options'
        When call parse_subcommand_and_options new --domain scripts --base develop
        The value "${#BRANCH_OPTIONS[@]}" should equal 2
        The value "${BRANCH_OPTIONS["domain"]}" should equal "scripts"
        The value "${BRANCH_OPTIONS["base"]}" should equal "develop"
      End
    End

    Context 'When: subcommand "commit" is provided with options'
      It 'Then: [正常] - sets SUBCOMMAND to "commit"'
        When call parse_subcommand_and_options commit --domain docs
        The variable SUBCOMMAND should equal "commit"
      End

      It 'Then: [正常] - BRANCH_OPTIONS contains options'
        When call parse_subcommand_and_options commit --domain docs
        The value "${#BRANCH_OPTIONS[@]}" should equal 1
        The value "${BRANCH_OPTIONS["domain"]}" should equal "docs"
      End
    End
  End

  # ============================================================================
  # Case 4: Subcommand only (no options)
  # ============================================================================

  Describe 'Given: subcommand without options'
    Context 'When: only subcommand "new" is provided'
      It 'Then: [正常] - sets SUBCOMMAND to "new"'
        When call parse_subcommand_and_options new
        The variable SUBCOMMAND should equal "new"
      End

      It 'Then: [正常] - BRANCH_OPTIONS array is empty'
        When call parse_subcommand_and_options new
        The value "${#BRANCH_OPTIONS[@]}" should equal 0
      End
    End

    Context 'When: only subcommand "commit" is provided'
      It 'Then: [正常] - sets SUBCOMMAND to "commit"'
        When call parse_subcommand_and_options commit
        The variable SUBCOMMAND should equal "commit"
      End

      It 'Then: [正常] - BRANCH_OPTIONS array is empty'
        When call parse_subcommand_and_options commit
        The value "${#BRANCH_OPTIONS[@]}" should equal 0
      End
    End

    Context 'When: only subcommand "help" is provided'
      It 'Then: [正常] - sets SUBCOMMAND to "help"'
        When call parse_subcommand_and_options help
        The variable SUBCOMMAND should equal "help"
      End

      It 'Then: [正常] - BRANCH_OPTIONS array is empty'
        When call parse_subcommand_and_options help
        The value "${#BRANCH_OPTIONS[@]}" should equal 0
      End
    End
  End

  # ============================================================================
  # Case 5: Invalid subcommand → error
  # ============================================================================

  Describe 'Given: invalid subcommand'
    Context 'When: unknown subcommand "invalid" is provided'
      It 'Then: [異常] - returns failure status and outputs error message'
        When call parse_subcommand_and_options invalid
        The status should be failure
        The stderr should include "Invalid subcommand"
      End
    End

    Context 'When: unknown subcommand "test" is provided'
      It 'Then: [異常] - returns failure status and outputs error message'
        When call parse_subcommand_and_options test
        The status should be failure
        The stderr should include "Invalid subcommand"
        The stderr should include "Valid subcommands: new, commit, help"
      End
    End
  End

End
