#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/idd-issue-branch-functions.lib.sh
# @(#): Test mock functions for /idd:issue:branch command
#
# @file idd-issue-branch-functions.lib.sh
# @brief Provides mock functions for testing branch.md implementation
# @description
#   This library contains mock functions to replace external dependencies
#   during unit and integration tests. The actual implementation functions
#   are now located in branch.md and can be sourced from there.
#
#   Mock functions:
#   - mock_codex_mcp: Mocks Codex-MCP inference behavior
#   - setup_branch_functions: Test setup helper
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/idd-issue-branch-functions.lib.sh
#   setup_branch_functions
#
# @author atsushifx
# @version 2.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Setup Function
# =============================================================================

##
# @description Setup test environment by sourcing branch.md implementation
# @noargs
# @exitcode 0 Always successful
##
setup_branch_functions() {
  # Source the actual implementation from branch.md
  local repo_root
  repo_root=$(git rev-parse --show-toplevel)

  # Load required libraries
  . "$repo_root/.claude/commands/_libs/io-utils.lib.sh"
  . "$repo_root/.claude/commands/_libs/filename-utils.lib.sh"
  . "$repo_root/.claude/commands/_libs/idd-session.lib.sh"

  # Extract and source shell functions from branch.md
  local branch_md="$repo_root/.claude/commands/idd/issue/branch.md"

  # Extract bash code blocks from Script Library section using awk
  # Create temporary file to avoid stdin sourcing issues
  BRANCH_FUNCTIONS_TEMP_SCRIPT="${TMPDIR:-/tmp}/branch-functions-$$.sh"
  sed -n '/^## スクリプトライブラリ/,/^## License$/p' "$branch_md" | \
    awk '/^```bash$/ {flag=1; next} /^```$/ {flag=0; next} flag' > "$BRANCH_FUNCTIONS_TEMP_SCRIPT"

  # Source the extracted functions
  . "$BRANCH_FUNCTIONS_TEMP_SCRIPT"

  return 0
}

##
# @description Cleanup test environment by removing temporary script
# @noargs
# @exitcode 0 Always successful
##
cleanup_branch_functions() {
  if [ -n "$BRANCH_FUNCTIONS_TEMP_SCRIPT" ] && [ -f "$BRANCH_FUNCTIONS_TEMP_SCRIPT" ]; then
    rm -f "$BRANCH_FUNCTIONS_TEMP_SCRIPT"
  fi
  return 0
}

# =============================================================================
# Mock Functions
# =============================================================================

##
# @brief Mock Codex-MCP command for testing
# @description Simulates Codex-MCP behavior without actual API calls
# @param --prompt Prompt string (contains title and issue type)
# @return 0 on success, 1 on failure (based on prompt content)
# @stdout Mocked domain inference result
# @example
#   result=$(mock_codex_mcp --prompt "Title: Add feature, Type: feature")
##
mock_codex_mcp() {
  local prompt=""

  # Parse --prompt argument
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt)
        prompt="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  # Extract title from prompt (simplified pattern matching)
  if [[ "$prompt" =~ \"([^\"]+)\" ]]; then
    local title="${BASH_REMATCH[1]}"

    # Simple domain inference based on keywords
    case "$title" in
      *"/idd-issue"*|*"claude-commands"*)
        echo "claude-commands"
        return 0
        ;;
      *"xcp.sh"*|*"scripts"*)
        echo "scripts"
        return 0
        ;;
      *"README"*|*"docs"*)
        echo "docs"
        return 0
        ;;
      *"Add"*|*"Implement"*)
        echo "feature"
        return 0
        ;;
      *"Fix"*)
        echo "bugfix"
        return 0
        ;;
      *)
        # Unknown case - simulate failure
        return 1
        ;;
    esac
  fi

  # No title found - simulate failure
  return 1
}

##
# @brief Detect domain from issue title (coordinator function)
# @description Determines domain using priority-based strategy:
#   1. DOMAIN variable (--domain option, highest priority)
#   2. Codex-MCP inference (unless no_codex="no_codex")
#   3. Issue type mapping (fallback)
# @param $1 Title string
# @param $2 Issue type (default: "feature")
# @param $3 no_codex flag ("no_codex" to disable Codex, empty to enable)
# @return 0 on success
# @stdout Domain string
# @example
#   domain=$(detect_domain "Add /idd-issue command" "feature")
#   domain=$(detect_domain "Fix bug" "bug" "no_codex")
##
detect_domain() {
  local title="$1"
  local issue_type="${2:-feature}"
  local no_codex="${3:-}"

  # Priority 1: --domain option override
  if [ -n "${DOMAIN:-}" ]; then
    echo "$DOMAIN"
    return 0
  fi

  # Priority 2: Codex-MCP inference
  if [ "$no_codex" != "no_codex" ]; then
    local domain
    if domain=$(_get_domain_use_codex "$title" "$issue_type"); then
      echo "$domain"
      return 0
    fi
  fi

  # Priority 3: Map issue_type to default domain (fallback)
  case "$issue_type" in
    bug)
      echo "bugfix"
      ;;
    feature)
      echo "feature"
      ;;
    enhancement)
      echo "enhancement"
      ;;
    task)
      echo "task"
      ;;
    *)
      # Fallback to issue_type as-is
      echo "$issue_type"
      ;;
  esac

  # No title found - simulate failure
  return 1
}

# =============================================================================
# Mock Command Alias
# =============================================================================

##
# @brief Alias 'claude' command to mock_codex_mcp for tests
# @description This allows tests to use "claude mcp__codex-mcp__codex --prompt ..."
#   which will be intercepted by the mock function
# @note This should be set up in test environment before running tests
##
claude() {
  if [[ "$1" == "mcp__codex-mcp__codex" ]]; then
    shift
    mock_codex_mcp "$@"
  else
    # Fallback to actual claude command (if needed)
    command claude "$@"
  fi
}

##
# @brief Generate Git branch name from issue information
# @description Constructs branch name in format: {type}-{number}/{domain}/{slug}
# @param $1 Branch type (e.g., "feat", "fix", "docs")
# @param $2 Issue number (e.g., "27" or "new")
# @param $3 Domain (e.g., "claude-commands", "scripts")
# @param $4 Issue title (will be converted to slug)
# @return 0 on success
# @stdout Branch name (e.g., "feat-27/claude-commands/add-branch-command")
# @example
#   branch=$(generate_branch_name "feat" "27" "claude-commands" "Add branch command")
#   echo "$branch"  # "feat-27/claude-commands/add-branch-command"
##
generate_branch_name() {
  local branch_type="$1"
  local issue_number="$2"
  local domain="$3"
  local title="$4"

  # Generate slug from title using filename-utils.lib.sh
  local slug
  slug=$(generate_slug "$title")

  # Construct branch name: {type}-{number}/{domain}/{slug}
  echo "${branch_type}-${issue_number}/${domain}/${slug}"
}

# =============================================================================
# T5: Base Branch Determination
# =============================================================================

##
# @brief Determine base branch for new branch creation
# @description Returns --base option if specified, otherwise current branch
# @param $1 Current branch name
# @param $2 BASE_BRANCH override (optional, from --base option)
# @return 0 on success
# @stdout Base branch name
# @example
#   base=$(determine_base_branch "main" "")
#   # Returns: "main"
#   base=$(determine_base_branch "main" "develop")
#   # Returns: "develop"
##
determine_base_branch() {
  local current_branch="$1"
  local base_override="${2:-}"

  if [ -n "$base_override" ]; then
    echo "$base_override"
  else
    echo "$current_branch"
  fi

  return 0
}
