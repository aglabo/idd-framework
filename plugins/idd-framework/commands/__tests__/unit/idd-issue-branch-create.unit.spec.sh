#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-create.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch branch creation (T11)
#
# @file idd-issue-branch-create.unit.spec.sh
# @brief Unit tests for create_branch() function (T11)
# @description
#   Unit test suite for branch creation functionality in /idd:issue:branch command.
#   Tests cover all BDD verification items from tasks.md T11.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Immutable mock with scenario-based branch names
#
#   Branch naming convention:
#   - Existing branches: main, develop, feat-27/exist
#   - Non-existent branches: nonexistent, feat-27/new
#
#   Covered functionality:
#   - T11-1: Branch creation when current branch = base branch
#   - T11-2: Branch creation when current branch ≠ base branch
#   - T11-3: Error when base branch does not exist
#   - T11-4: Error when Git operation fails
#
# @author atsushifx
# @version 2.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"
HELPERS_DIR="$PROJECT_ROOT/.claude/commands/__tests__/__helpers"

# Load helper libraries
. "$HELPERS_DIR/idd-issue-branch-functions.lib.sh"
. "$HELPERS_DIR/git-mocks.lib.sh"

# Setup branch functions from branch.md
setup_branch_functions

# Cleanup temporary files after all tests
AfterAll 'cleanup_branch_functions'

Describe 'create_branch() - T11 Branch creation functionality'
  # Initialize immutable mock state before each test
  BeforeEach 'init_mock_git'

  # ============================================================================
  # T11-1: 現在のブランチ = ベースブランチの場合
  # ============================================================================

  Describe 'Given: current branch equals base branch'
    Describe 'When: create_branch("feat-27/new", "main") is called on main'
      It 'Then: [正常] - should show "Already on base branch" message'
        When call create_branch "feat-27/new" "main"
        The output should include "Already on base branch"
        The status should be success
      End

      It 'Then: [正常] - should show branch creation success message'
        When call create_branch "feat-27/new" "main"
        The output should include "Branch created successfully"
        The status should be success
      End
    End
  End

  # ============================================================================
  # T11-2: 現在のブランチ ≠ ベースブランチの場合
  # ============================================================================

  Describe 'Given: current branch differs from base branch'
    Describe 'When: create_branch("feat-27/new", "develop") is called on main'
      It 'Then: [正常] - should show "Switching to base branch" message'
        When call create_branch "feat-27/new" "develop"
        The output should include "Switching to base branch"
        The output should include "develop"
        The status should be success
      End

      It 'Then: [正常] - should show branch creation success message'
        When call create_branch "feat-27/new" "develop"
        The output should include "Branch created successfully"
        The status should be success
      End
    End
  End

  # ============================================================================
  # T11-3: ベースブランチが存在しない場合
  # ============================================================================

  Describe 'Given: base branch does not exist'
    Describe 'When: create_branch("feat-27/new", "nonexistent") is called'
      It 'Then: [異常] - should return exit code 7'
        When call create_branch "feat-27/new" "nonexistent"
        The status should equal 7
        The error should include "Base branch does not exist"
      End

      It 'Then: [異常] - should show "Base branch does not exist" message'
        When call create_branch "feat-27/new" "nonexistent"
        The status should be failure
        The error should include "Base branch does not exist"
      End

      It 'Then: [異常] - should not create new branch'
        When call create_branch "feat-27/new" "nonexistent"
        The status should be failure
        The error should not include "Switched to a new branch"
      End
    End
  End

  # ============================================================================
  # T11-4: Git操作が失敗する場合
  # ============================================================================

  Describe 'Given: Git operation fails'
    Describe 'When: create_branch() is called and git switch fails'
      It 'Then: [異常] - should return exit code 6'
        MOCK_SWITCH_FAILS=1
        When call create_branch "feat-27/new" "main"
        The status should equal 6
        The output should include "Already on base branch"
        The error should include "Failed to create branch"
      End

      It 'Then: [異常] - should show error message'
        MOCK_SWITCH_FAILS=1
        When call create_branch "feat-27/new" "main"
        The status should be failure
        The output should include "Already on base branch"
        The error should include "Failed to create branch"
      End
    End
  End

  # ============================================================================
  # Additional: ブランチ既存チェック (将来のT10対応)
  # ============================================================================

  Describe 'Given: target branch already exists'
    Describe 'When: create_branch("feat-27/exist", "main") is called'
      It 'Then: [異常] - should detect existing branch and fail'
        When call create_branch "feat-27/exist" "main"
        The status should equal 6
        The output should include "Already on base branch"
        The error should include "Failed to create branch"
      End
    End
  End

End
