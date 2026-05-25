#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/git-mocks.lib.sh
# @(#): Immutable Git command mocks for T11 branch creation tests
#
# @file git-mocks.lib.sh
# @brief Provides immutable Git mock functions using associative arrays
# @description
#   This library provides a completely immutable mock for Git commands.
#   Mock state is set once during initialization and never changes.
#   Tests use different branch names to simulate different scenarios.
#
#   Design principles:
#   - Mock state is immutable after init_mock_git()
#   - No state-changing functions needed
#   - Branch names express test scenarios
#
#   Branch naming convention:
#   - Existing branches: main, develop, feat-27/exist
#   - Non-existent branches: nonexistent, invalid, feat-27/new
#
# @example Basic usage
#   BeforeEach 'init_mock_git'
#
#   It 'creates new branch on existing base'
#     When call create_branch "feat-27/new" "main"
#     The status should be success
#   End
#
#   It 'fails when base branch does not exist'
#     When call create_branch "feat-27/new" "nonexistent"
#     The status should equal 7
#   End
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Global Variables (Immutable after init_mock_git)
# =============================================================================

# Current branch name
MOCK_CURRENT_BRANCH=""

# Associative array of existing branches
declare -A MOCK_BRANCHES

# Flag to simulate git switch failure (for T11-4)
MOCK_SWITCH_FAILS=0

# =============================================================================
# Initialization Function
# =============================================================================

##
# @brief Initialize Git mock with fixed state
# @description Sets up immutable mock state with predefined branches
#
#   Existing branches (registered in MOCK_BRANCHES):
#   - main: Main branch (also set as current)
#   - develop: Development branch
#   - feat-27/exist: Pre-existing feature branch
#
#   Non-existent branches (not registered):
#   - nonexistent: For testing base branch not found
#   - invalid: For testing invalid branch scenarios
#   - feat-27/new: For testing new branch creation
#
# @noargs
# @exitcode 0 Always successful
# @example
#   BeforeEach 'init_mock_git'
##
init_mock_git() {
  # Set current branch
  MOCK_CURRENT_BRANCH="main"

  # Register existing branches
  MOCK_BRANCHES=(
    ["main"]=1
    ["develop"]=1
    ["feat-27/exist"]=1
  )

  # Reset switch failure flag
  MOCK_SWITCH_FAILS=0

  # Activate git() mock
  mock_git
}

# =============================================================================
# Helper Functions
# =============================================================================

##
# @brief Check if a branch exists in mock state
# @description Internal helper to check branch existence
#   A branch exists if MOCK_BRANCHES[branch_name] equals 1.
#   If not in the array or equals 0, the branch does not exist.
# @param $1 Branch name to check
# @exitcode 0 Branch exists, 1 Branch does not exist
# @example
#   if branch_exists "main"; then
#     echo "main exists"
#   fi
##
branch_exists() {
  local branch_name="$1"
  [ "${MOCK_BRANCHES[$branch_name]}" = 1 ]
}

# =============================================================================
# Git Mock Function
# =============================================================================

##
# @brief Define git() mock function
# @description Replaces git command with mock implementation
#
#   Supported commands:
#   - git branch --show-current: Returns MOCK_CURRENT_BRANCH
#   - git branch --list <branch>: Checks if MOCK_BRANCHES[branch] equals 1
#   - git switch <branch>: Switches only if MOCK_BRANCHES[branch] equals 1
#   - git switch -c <branch>: Creates new branch only if MOCK_BRANCHES[branch] != 1
#
#   Branch existence logic:
#   - MOCK_BRANCHES[xx] = 1: branch exists
#   - MOCK_BRANCHES[xx] = 0 or undefined: branch does not exist
#
# @noargs
# @exitcode 0 Always successful
# @example
#   mock_git  # Called automatically by init_mock_git
##
mock_git() {
  git() {
    case "$1 $2" in
      "branch --show-current")
        # Return current branch
        echo "$MOCK_CURRENT_BRANCH"
        ;;

      "branch --list")
        # Check if branch exists in associative array
        if branch_exists "$3"; then
          echo "$3"
        fi
        ;;

      "rev-parse --abbrev-ref")
        # Support git rev-parse --abbrev-ref HEAD
        if [ "$3" = "HEAD" ]; then
          echo "$MOCK_CURRENT_BRANCH"
        fi
        ;;

      "rev-parse --verify")
        # Support git rev-parse --verify --quiet <branch>
        # Check if branch exists in associative array
        if branch_exists "$4"; then
          echo "$4"
          return 0
        fi
        return 1
        ;;

      "switch -c")
         # Create new branch (only if it doesn't already exist)
         if [ "${MOCK_BRANCHES[$3]}" = 1 ]; then
           echo "fatal: a branch named '$3' already exists" >&2
           return 1
         fi
         if [ "$MOCK_SWITCH_FAILS" = 1 ]; then
           echo "fatal: unable to create branch" >&2
           return 1
         fi
         echo "Switched to a new branch '$3'" >&2
         return 0
         ;;

      "switch "*)
         # Switch to existing branch (only if it exists)
         if [ "${MOCK_BRANCHES[$2]}" != 1 ]; then
           echo "error: pathspec '$2' did not match any file(s) known to git" >&2
           return 1
         fi
         if [ "$MOCK_SWITCH_FAILS" = 1 ]; then
           echo "fatal: unable to switch to branch '$2'" >&2
           return 1
         fi
         echo "Switched to branch '$2'" >&2
         return 0
         ;;

      *)
        # Unsupported command - do nothing
        return 0
        ;;
    esac
  }
}
