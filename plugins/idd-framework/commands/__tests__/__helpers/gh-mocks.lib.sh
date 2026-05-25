#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/gh-mocks.lib.sh
# @(#): GitHub CLI (gh) command mock library for testing
#
# @file gh-mocks.lib.sh
# @brief Provides flexible mock implementations for gh commands
# @description
#   This library provides reusable mock functions for the GitHub CLI (gh).
#   Supports issue, pr, repo, auth, and other subcommands with configurable behavior.
#
#   Key features:
#   - Extensible design supporting multiple gh subcommands
#   - State-based mocking via environment variables
#   - Easy failure mode configuration
#   - JSON output support for structured commands
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/gh-mocks.lib.sh
#   setup_gh_mock
#
#   # Configure mock behavior
#   mock_gh_fails=1              # Force gh to fail
#   mock_issue_number=123        # Set issue number for creation
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Mock State Variables
# =============================================================================

# Issue operations
: "${mock_gh_fails:=0}"                    # 0=success, 1=fail
: "${mock_issue_number:=42}"               # Default issue number for create
: "${mock_new_issue_number:=42}"           # Alias for compatibility

# Authentication
: "${mock_gh_not_authenticated:=0}"        # 0=authenticated, 1=not authenticated

# PR operations
: "${mock_pr_number:=1}"                   # Default PR number
: "${mock_pr_fails:=0}"                    # PR operation failure flag

# Repository
: "${mock_repo_name:=user/repo}"           # Default repository name

# =============================================================================
# Main gh Mock Function
# =============================================================================

##
# @description Setup gh command mock
# @noargs
# @exitcode 0 Always successful
# @see reset_gh_mock_state
# @see set_gh_mock_failure
setup_gh_mock() {
  gh() {
    local subcommand="$1"

    case "$subcommand" in
      issue)
        _gh_mock_issue "$@"
        ;;
      pr)
        _gh_mock_pr "$@"
        ;;
      repo)
        _gh_mock_repo "$@"
        ;;
      auth)
        _gh_mock_auth "$@"
        ;;
      *)
        echo "Mock gh: unknown subcommand '$subcommand'" >&2
        return 1
        ;;
    esac
  }
}

# =============================================================================
# Issue Subcommand Mocks
# =============================================================================

##
# @description Mock for gh issue commands
# @internal
# @arg $@ All arguments passed to gh issue
_gh_mock_issue() {
  shift  # Remove 'issue'
  local action="$1"

  case "$action" in
    create)
      _gh_mock_issue_create "$@"
      ;;
    edit)
      _gh_mock_issue_edit "$@"
      ;;
    list)
      _gh_mock_issue_list "$@"
      ;;
    view)
      _gh_mock_issue_view "$@"
      ;;
    close)
      _gh_mock_issue_close "$@"
      ;;
    *)
      echo "Mock gh issue: unknown action '$action'" >&2
      return 1
      ;;
  esac
}

##
# @description Mock for gh issue create
# @internal
# @arg $@ Arguments for issue create (--title, --body, etc.)
# @stdout GitHub issue URL on success
# @stderr Error message on failure
# @exitcode 0 If mock_gh_fails=0
# @exitcode 1 If mock_gh_fails=1
_gh_mock_issue_create() {
  if [[ "${mock_gh_fails:-0}" -eq 1 ]]; then
    echo "Error: Network error" >&2
    return 1
  fi

  echo "https://github.com/${mock_repo_name}/issues/${mock_issue_number}"
  return 0
}

##
# @description Mock for gh issue edit
# @internal
# @arg $1 Issue number to edit
# @arg $@ Additional arguments (--title, --body, etc.)
# @stdout Success message
# @stderr Error message on failure
# @exitcode 0 If mock_gh_fails=0
# @exitcode 1 If mock_gh_fails=1
_gh_mock_issue_edit() {
  shift  # Remove 'edit'
  local issue_num="$1"

  if [[ "${mock_gh_fails:-0}" -eq 1 ]]; then
    echo "Error: Issue not found" >&2
    return 1
  fi

  echo "Updated issue #${issue_num}"
  return 0
}

##
# @description Mock for gh issue list
# @internal
# @arg $@ Arguments for issue list
# @stdout JSON array of issues
# @exitcode 0 If mock_gh_fails=0
# @exitcode 1 If mock_gh_fails=1
_gh_mock_issue_list() {
  if [[ "${mock_gh_fails:-0}" -eq 1 ]]; then
    echo "Error: Failed to list issues" >&2
    return 1
  fi

  # Return mock issue list in JSON format
  cat <<'EOF'
[
  {
    "number": 1,
    "title": "Test Issue 1",
    "state": "open"
  },
  {
    "number": 2,
    "title": "Test Issue 2",
    "state": "closed"
  }
]
EOF
  return 0
}

##
# @description Mock for gh issue view
# @internal
# @arg $1 Issue number to view
# @arg $@ Additional arguments
# @stdout JSON object with issue details
# @exitcode 0 If mock_gh_fails=0
# @exitcode 1 If mock_gh_fails=1
_gh_mock_issue_view() {
  shift  # Remove 'view'
  local issue_num="$1"

  if [[ "${mock_gh_fails:-0}" -eq 1 ]]; then
    echo "Error: Issue not found" >&2
    return 1
  fi

  # Return mock issue details
  cat <<EOF
{
  "number": ${issue_num},
  "title": "Mock Issue Title",
  "body": "Mock issue body",
  "state": "open"
}
EOF
  return 0
}

##
# @description Mock for gh issue close
# @internal
# @arg $1 Issue number to close
# @exitcode 0 If mock_gh_fails=0
# @exitcode 1 If mock_gh_fails=1
_gh_mock_issue_close() {
  shift  # Remove 'close'
  local issue_num="$1"

  if [[ "${mock_gh_fails:-0}" -eq 1 ]]; then
    echo "Error: Failed to close issue" >&2
    return 1
  fi

  echo "Closed issue #${issue_num}"
  return 0
}

# =============================================================================
# PR Subcommand Mocks
# =============================================================================

##
# @description Mock for gh pr commands
# @internal
# @arg $@ All arguments passed to gh pr
_gh_mock_pr() {
  shift  # Remove 'pr'
  local action="$1"

  case "$action" in
    create)
      _gh_mock_pr_create "$@"
      ;;
    list)
      _gh_mock_pr_list "$@"
      ;;
    view)
      _gh_mock_pr_view "$@"
      ;;
    *)
      echo "Mock gh pr: unknown action '$action'" >&2
      return 1
      ;;
  esac
}

##
# @description Mock for gh pr create
# @internal
# @arg $@ Arguments for pr create
# @stdout GitHub PR URL on success
# @exitcode 0 If mock_pr_fails=0
# @exitcode 1 If mock_pr_fails=1
_gh_mock_pr_create() {
  if [[ "${mock_pr_fails:-0}" -eq 1 ]]; then
    echo "Error: Failed to create PR" >&2
    return 1
  fi

  echo "https://github.com/${mock_repo_name}/pull/${mock_pr_number}"
  return 0
}

##
# @description Mock for gh pr list
# @internal
# @stdout JSON array of PRs
# @exitcode 0 Always successful
_gh_mock_pr_list() {
  cat <<'EOF'
[
  {
    "number": 1,
    "title": "Test PR 1",
    "state": "open"
  }
]
EOF
  return 0
}

##
# @description Mock for gh pr view
# @internal
# @arg $1 PR number to view
# @stdout JSON object with PR details
# @exitcode 0 Always successful
_gh_mock_pr_view() {
  shift  # Remove 'view'
  local pr_num="$1"

  cat <<EOF
{
  "number": ${pr_num},
  "title": "Mock PR Title",
  "body": "Mock PR body",
  "state": "open"
}
EOF
  return 0
}

# =============================================================================
# Repo Subcommand Mocks
# =============================================================================

##
# @description Mock for gh repo commands
# @internal
# @arg $@ All arguments passed to gh repo
_gh_mock_repo() {
  shift  # Remove 'repo'
  local action="$1"

  case "$action" in
    view)
      _gh_mock_repo_view "$@"
      ;;
    *)
      echo "Mock gh repo: unknown action '$action'" >&2
      return 1
      ;;
  esac
}

##
# @description Mock for gh repo view
# @internal
# @arg $@ Arguments for repo view (--json, -q, etc.)
# @stdout Repository name or JSON based on arguments
# @exitcode 0 Always successful
_gh_mock_repo_view() {
  shift  # Remove 'view'

  # Handle --json nameWithOwner -q .nameWithOwner
  if [[ "$*" =~ -q ]]; then
    echo "${mock_repo_name}"
  else
    echo "{\"nameWithOwner\":\"${mock_repo_name}\"}"
  fi
  return 0
}

# =============================================================================
# Auth Subcommand Mocks
# =============================================================================

##
# @description Mock for gh auth commands
# @internal
# @arg $@ All arguments passed to gh auth
_gh_mock_auth() {
  shift  # Remove 'auth'
  local action="$1"

  case "$action" in
    status)
      _gh_mock_auth_status "$@"
      ;;
    *)
      echo "Mock gh auth: unknown action '$action'" >&2
      return 1
      ;;
  esac
}

##
# @description Mock for gh auth status
# @internal
# @stdout Authentication status message
# @exitcode 0 If mock_gh_not_authenticated=0
# @exitcode 1 If mock_gh_not_authenticated=1
_gh_mock_auth_status() {
  if [[ "${mock_gh_not_authenticated:-0}" -eq 1 ]]; then
    return 1
  fi

  echo "✓ Logged in to github.com as mockuser"
  return 0
}

# =============================================================================
# Helper Functions
# =============================================================================

##
# @description Reset all gh mock state variables to defaults
# @noargs
# @exitcode 0 Always successful
reset_gh_mock_state() {
  mock_gh_fails=0
  mock_issue_number=42
  mock_new_issue_number=42
  mock_pr_number=1
  mock_gh_not_authenticated=0
  mock_pr_fails=0
  mock_repo_name="user/repo"
}

##
# @description Configure gh mock to fail for specific operations
# @arg $1 Operation type (issue|pr|auth|all)
# @exitcode 0 If operation type recognized
# @exitcode 1 If unknown operation type
# @example
#   set_gh_mock_failure issue  # Make issue operations fail
#   set_gh_mock_failure all    # Make all operations fail
set_gh_mock_failure() {
  local operation="$1"

  case "$operation" in
    issue)
      mock_gh_fails=1
      ;;
    pr)
      mock_pr_fails=1
      ;;
    auth)
      mock_gh_not_authenticated=1
      ;;
    all)
      mock_gh_fails=1
      mock_pr_fails=1
      ;;
    *)
      echo "Unknown operation: $operation" >&2
      return 1
      ;;
  esac
}
