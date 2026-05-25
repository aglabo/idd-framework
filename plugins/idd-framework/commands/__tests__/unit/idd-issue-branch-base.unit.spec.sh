#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-base.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch base branch determination
#
# @file idd-issue-branch-base.unit.spec.sh
# @brief Unit tests for determine_base_branch() function
# @description
#   Unit test suite for base branch determination in /idd:issue:branch command.
#   Tests verify correct base branch selection based on current branch and --base option.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Direct function call with various branch scenarios
#
#   Covered functionality:
#   - Current branch retrieval with git branch --show-current
#   - Base branch determination without --base option
#   - Base branch determination with --base option
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
. "$HELPERS_DIR/git-mocks.lib.sh"

# Setup branch functions from branch.md
setup_branch_functions

# Cleanup temporary files after all tests
AfterAll 'cleanup_branch_functions'

Describe 'determine_base_branch() - base branch determination'
  # ============================================================================
  # T5-1: Get current branch
  # ============================================================================

  Describe 'Given: Git repository'
    Before 'init_mock_git'

    Context 'When: git branch --show-current is called'
      It 'Then: [正常] - returns current branch name'
        # Note: Uses mock to avoid affecting real repository
        # Mock returns "main" as default current branch
        When call git branch --show-current
        The status should be success
        The output should equal "main"
      End
    End
  End

  # ============================================================================
  # T5-2: Determine base branch (no --base option)
  # ============================================================================

  Describe 'Given: current branch "main", no --base option'
    Context 'When: determine_base_branch is called'
      It 'Then: [正常] - uses "main" as base branch'
        When call determine_base_branch "main" ""
        The output should equal "main"
        The status should be success
      End
    End
  End

  Describe 'Given: current branch "feat-27/test", no --base option'
    Context 'When: determine_base_branch is called'
      It 'Then: [正常] - uses current branch as base branch'
        When call determine_base_branch "feat-27/test" ""
        The output should equal "feat-27/test"
        The status should be success
      End
    End
  End

  # ============================================================================
  # T5-3: Determine base branch (with --base option)
  # ============================================================================

  Describe 'Given: current branch "main", --base "develop"'
    Context 'When: determine_base_branch is called'
      It 'Then: [正常] - uses "develop" as base branch'
        When call determine_base_branch "main" "develop"
        The output should equal "develop"
        The status should be success
      End
    End
  End

  Describe 'Given: current branch "feat-27/test", --base "main"'
    Context 'When: determine_base_branch is called'
      It 'Then: [正常] - overrides current branch with "main"'
        When call determine_base_branch "feat-27/test" "main"
        The output should equal "main"
        The status should be success
      End
    End
  End

End
