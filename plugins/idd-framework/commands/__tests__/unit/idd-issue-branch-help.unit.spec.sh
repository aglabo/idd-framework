#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-help.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch help message
#
# @file idd-issue-branch-help.unit.spec.sh
# @brief Unit tests for subcommand_help() function
# @description
#   Unit test suite for help message functionality in /idd:issue:branch command.
#   Tests verify that help message contains all required sections.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Direct function call and output verification
#
#   Covered functionality:
#   - Help message structure and content
#   - Command overview section
#   - Subcommands list
#   - Options list
#   - Usage examples
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

Describe 'subcommand_help() - help message content'
  # ============================================================================
  # T16-1: Help message content verification
  # ============================================================================

  Describe 'Given: help subcommand'
    Context 'When: subcommand_help is called'
      It 'Then: [正常] - displays command overview'
        When call subcommand_help
        The output should include "Usage: /idd:issue:branch"
        The output should include "Create and manage Git branches from issue sessions"
      End

      It 'Then: [正常] - displays subcommands list'
        When call subcommand_help
        The output should include "Subcommands:"
        The output should include "new"
        The output should include "Create branch proposal from issue"
        The output should include "commit"
        The output should include "Create branch and switch to it"
        The output should include "help"
        The output should include "Show this help message"
      End

      It 'Then: [正常] - displays options list'
        When call subcommand_help
        The output should include "Options"
        The output should include "--domain <name>"
        The output should include "Override automatic domain detection"
        The output should include "--base <branch>"
        The output should include "Specify base branch"
      End

      It 'Then: [正常] - displays usage examples'
        When call subcommand_help
        The output should include "Examples:"
        The output should include "/idd:issue:branch"
        The output should include "/idd:issue:branch new"
        The output should include "/idd:issue:branch new --domain"
        The output should include "/idd:issue:branch new --base"
        The output should include "/idd:issue:branch commit"
        The output should include "/idd:issue:branch help"
      End

      It 'Then: [正常] - returns success exit code and outputs help message'
        When call subcommand_help
        The status should be success
        The output should include "Usage:"
      End
    End
  End

End
