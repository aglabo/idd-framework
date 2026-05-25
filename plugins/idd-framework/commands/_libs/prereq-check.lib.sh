#!/bin/bash
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
##
# Prerequisites Check Library
#
# Git および GitHub 環境の前提条件チェック関数を提供します。
#
# 低レベル関数（チェックのみ）と高レベル関数（チェック+エラー表示）を分離し、
# 1関数1責任の原則に基づいて設計されています。
#
# @file prereq-check.lib.sh
# @version 1.0.0
# @license MIT

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
. "$SCRIPT_DIR/io-utils.lib.sh"

# ============================================================================
# 低レベル関数（チェックのみ、エラー表示なし）
# ============================================================================

##
# @brief Check if git command is available
# @description Tests if git command exists in PATH
#
# @return 0 if git command found
# @return 1 if git command not found
#
# @example
#   if check_git_command; then
#     echo "Git is available"
#   fi
##
check_git_command() {
  command -v git &>/dev/null
}

##
# @brief Check if current directory is inside git repository
# @description Tests if current working directory is part of a git repository
#
# @return 0 if inside git repository
# @return 1 if not in git repository
#
# @example
#   if check_git_repository; then
#     echo "In git repository"
#   fi
##
check_git_repository() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

##
# @brief Check if git version meets minimum requirement
# @description Validates git version is >= 2.23 (required for 'git switch')
#
# @return 0 if git version >= 2.23
# @return 1 if git version < 2.23
#
# @example
#   if check_git_version; then
#     echo "Git version is sufficient"
#   fi
##
check_git_version() {
  local git_version major minor

  git_version=$(git --version 2>/dev/null | awk '{print $3}' | sed 's/\.windows.*//')
  major=$(echo "$git_version" | cut -d. -f1)
  minor=$(echo "$git_version" | cut -d. -f2)

  if [ "$major" -lt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -lt 23 ]; }; then
    return 1
  fi

  return 0
}

##
# @brief Check if gh (GitHub CLI) command is available
# @description Tests if gh command exists in PATH
#
# @return 0 if gh command found
# @return 1 if gh command not found
#
# @example
#   if check_gh_command; then
#     echo "GitHub CLI is available"
#   fi
##
check_gh_command() {
  command -v gh &>/dev/null
}

##
# @brief Check if GitHub CLI is authenticated
# @description Tests if gh is properly authenticated with GitHub
#
# @return 0 if authenticated
# @return 1 if not authenticated
#
# @example
#   if check_gh_auth; then
#     echo "GitHub CLI is authenticated"
#   fi
##
check_gh_auth() {
  gh auth status &>/dev/null
}

# ============================================================================
# 高レベル関数（チェック + エラー表示）
# ============================================================================

##
# @brief Validate git command availability with error message
# @description Checks git command and displays error if not found
#
# @return 0 if git command found
# @return 1 if git command not found (displays error)
#
# @example
#   validate_git_command || exit 1
##
validate_git_command() {
  if ! check_git_command; then
    error_print "❌ Error: 'git' command not found"
    error_print "💡 Please install Git: https://git-scm.com/"
    return 1
  fi
  return 0
}

##
# @brief Validate git repository with error message
# @description Checks if in git repository and displays error if not
#
# @return 0 if in git repository
# @return 1 if not in git repository (displays error)
#
# @example
#   validate_git_repository || exit 1
##
validate_git_repository() {
  if ! check_git_repository; then
    error_print "❌ Error: Not in a git repository"
    error_print "💡 Run 'git init' or navigate to a git repository"
    return 1
  fi
  return 0
}

##
# @brief Validate git version with error message
# @description Checks git version and displays error if too old
#
# @return 0 if git version >= 2.23
# @return 1 if git version < 2.23 (displays error)
#
# @example
#   validate_git_version || exit 1
##
validate_git_version() {
  if ! check_git_version; then
    local current_version
    current_version=$(git --version 2>/dev/null | awk '{print $3}')
    error_print "❌ Error: Git version too old (current: $current_version)"
    error_print "💡 Git 2.23+ required for 'git switch' command"
    error_print "💡 Please upgrade Git: https://git-scm.com/"
    return 1
  fi
  return 0
}

##
# @brief Validate gh command availability with error message
# @description Checks gh command and displays error if not found
#
# @return 0 if gh command found
# @return 1 if gh command not found (displays error)
#
# @example
#   validate_gh_command || exit 1
##
validate_gh_command() {
  if ! check_gh_command; then
    error_print "❌ Error: 'gh' command not found"
    error_print "💡 Please install GitHub CLI: https://cli.github.com/"
    return 1
  fi
  return 0
}

##
# @brief Validate gh authentication with error message
# @description Checks gh authentication and displays error if not authenticated
#
# @return 0 if authenticated
# @return 1 if not authenticated (displays error)
#
# @example
#   validate_gh_auth || exit 1
##
validate_gh_auth() {
  if ! check_gh_auth; then
    error_print "❌ Error: GitHub CLI not authenticated"
    error_print "💡 Run 'gh auth login' to authenticate"
    return 1
  fi
  return 0
}

# ============================================================================
# 統合関数（複数のチェックを組み合わせ）
# ============================================================================

##
# @brief Validate basic git environment (command + repository)
# @description Validates git command and repository status
#
# @return 0 if all checks pass
# @return 1 if any check fails (displays error)
#
# @example
#   validate_git_basic || exit 1
##
validate_git_basic() {
  validate_git_command || return 1
  validate_git_repository || return 1
  return 0
}

##
# @brief Validate full git environment (command + repository + version)
# @description Validates git command, repository, and version
#
# @return 0 if all checks pass
# @return 1 if any check fails (displays error)
#
# @example
#   validate_git_full || exit 1
##
validate_git_full() {
  validate_git_command || return 1
  validate_git_repository || return 1
  validate_git_version || return 1
  return 0
}

##
# @brief Validate full GitHub environment (gh command + authentication)
# @description Validates GitHub CLI command and authentication status
#
# @return 0 if all checks pass
# @return 1 if any check fails (displays error)
#
# @example
#   validate_github_full || exit 1
##
validate_github_full() {
  validate_gh_command || return 1
  validate_gh_auth || return 1
  return 0
}
