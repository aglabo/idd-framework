#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/idd-issue-push-functions.lib.sh
# @(#): Implementation functions for /idd:issue:push command testing
#
# @file idd-issue-push-functions.lib.sh
# @brief Provides implementation functions extracted from push.md for testing
# @description
#   This library contains the actual implementation functions from push.md
#   that are used in both integration and E2E tests.
#
#   Included functions:
#   - parse_issue_number_from_url
#   - push_new_issue
#   - push_existing_issue
#   - rename_new_issue_file
#   - update_session_after_push
#   - main_routine (for E2E tests)
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/idd-issue-push-functions.lib.sh
#   setup_push_functions
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Setup Function
# =============================================================================

##
# @description Setup all push command implementation functions
# @noargs
# @exitcode 0 Always successful
setup_push_functions() {
  # Functions are defined in this file and become available when sourced
  # This function exists for consistency with other libraries
  return 0
}

# =============================================================================
# Helper Functions
# =============================================================================

##
# @description Parse issue number from GitHub URL using sed (portable)
# @arg $1 string GitHub CLI output containing URL
# @set issue_number Extracted issue number from URL
# @exitcode 0 If issue number successfully parsed and set
# @exitcode 1 If URL parsing failed or issue number not found
parse_issue_number_from_url() {
  local gh_output="$1"

  # Extract issue number from URL using sed (portable)
  issue_number=$(echo "$gh_output" | \
    sed -n 's|.*https://github.com/[^/]*/[^/]*/issues/\([0-9]*\).*|\1|p' | head -n 1)

  if [[ -z "$issue_number" ]]; then
    echo "❌ Failed to parse issue number from GitHub response."
    echo "   Response: $gh_output"
    return 1
  fi

  return 0
}

# =============================================================================
# GitHub Operation Functions
# =============================================================================

##
# @description Create new issue on GitHub using gh CLI
# @arg $1 string Issue title
# @arg $2 string Issue body
# @set issue_number Issue number assigned by GitHub
# @set issue_url Full URL to the created issue
# @exitcode 0 If issue created successfully
# @exitcode 5 If gh CLI command failed
# @exitcode 6 If issue number parsing failed
push_new_issue() {
  local title="$1"
  local body="$2"
  local gh_output
  local gh_exit_code=0

  echo "🆕 Detected new issue (will create on GitHub)"
  echo "📤 Creating new issue on GitHub..."

  # Create issue with gh CLI
  gh_output=$(gh issue create --title "$title" --body "$body" 2>&1) || gh_exit_code=$?

  # Handle errors
  if [[ $gh_exit_code -ne 0 ]]; then
    echo "❌ Failed to create issue on GitHub."
    echo "   Error: $gh_output"
    echo "💡 Check your network connection and repository permissions."
    return 5
  fi

  # Parse issue number from URL
  if ! parse_issue_number_from_url "$gh_output"; then
    return 6
  fi

  # Extract full URL using sed (portable)
  issue_url=$(echo "$gh_output" | \
    sed -n 's|.*\(https://github.com/[^/]*/[^/]*/issues/[0-9]*\).*|\1|p' | \
    head -n 1)

  echo "✅ Issue created: #$issue_number"
  echo "   URL: $issue_url"

  return 0
}

##
# @description Update existing issue on GitHub
# @arg $1 string Filename without extension
# @arg $2 string Updated issue title
# @arg $3 string Updated issue body
# @set issue_number Issue number extracted from filename
# @exitcode 0 If issue updated successfully
# @exitcode 7 If filename format invalid
# @exitcode 8 If gh CLI command failed
push_existing_issue() {
  local filename="$1"
  local title="$2"
  local body="$3"
  local gh_output
  local gh_exit_code=0

  # Extract issue number from filename
  if [[ "$filename" =~ ^([0-9]+)- ]]; then
    issue_number="${BASH_REMATCH[1]}"
    echo "📝 Detected existing issue #$issue_number (will update on GitHub)"
  else
    echo "❌ Invalid filename format: $filename"
    echo "💡 Expected format: 'new-*' or '{number}-*'"
    echo "   Run '/idd:issue:list' to see available issues."
    return 7
  fi

  echo "📤 Updating issue #$issue_number on GitHub..."

  # Update issue with gh CLI
  gh_output=$(gh issue edit "$issue_number" \
    --title "$title" --body "$body" 2>&1) || gh_exit_code=$?

  # Handle errors
  if [[ $gh_exit_code -ne 0 ]]; then
    echo "❌ Failed to update issue #$issue_number"
    echo "   Error: $gh_output"
    echo "💡 Check that issue #$issue_number exists and you have"
    echo "   permission to edit it."
    return 8
  fi

  echo "✅ Issue updated: #$issue_number"
  echo "   URL: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/$issue_number"

  return 0
}

# =============================================================================
# File Operation Functions
# =============================================================================

##
# @description Rename new issue file from new-{suffix} to {number}-{suffix}
# @arg $1 string Old filename without .md extension
# @arg $2 string Issue number assigned by GitHub
# @set new_filename New filename after rename
# @exitcode 0 If file renamed successfully
# @exitcode 9 If source file not found or mv failed
# @exitcode 10 If target filename already exists
rename_new_issue_file() {
  local old_filename="$1"
  local issue_number="$2"
  local suffix

  # Extract suffix from new-* filename
  if [[ "$old_filename" =~ ^new-(.+)$ ]]; then
    suffix="${BASH_REMATCH[1]}"
    new_filename="${issue_number}-${suffix}"
  else
    echo "❌ Invalid filename format: $old_filename"
    echo "💡 Expected format: new-*"
    return 9
  fi

  # Construct file paths
  local old_file="$ISSUES_DIR/${old_filename}.md"
  local new_file="$ISSUES_DIR/${new_filename}.md"

  # Check source file exists
  if [[ ! -f "$old_file" ]]; then
    echo "❌ Source file not found: $old_file"
    return 9
  fi

  # Check for filename conflict
  if [[ -f "$new_file" ]]; then
    echo "❌ Target file already exists: $new_file"
    echo "💡 Please resolve the conflict manually or delete the existing file."
    return 10
  fi

  # Perform rename
  if ! mv "$old_file" "$new_file"; then
    echo "❌ Failed to rename file"
    return 9
  fi

  echo "✅ Renamed: $old_filename.md → $new_filename.md"
  return 0
}

# =============================================================================
# Session Management Functions
# =============================================================================

##
# @description Update session file after successful push
# @arg $1 string Filename without .md extension
# @arg $2 string Issue number
# @exitcode 0 If session file updated successfully
# @exitcode 1 If _save_issue_session failed
update_session_after_push() {
  local new_filename="$1"
  local new_issue_number="$2"

  # _save_issue_session references global variables (TITLE, ISSUE_TYPE, etc.)
  if ! _save_issue_session "$SESSION_FILE" "$new_filename" "$new_issue_number" "push"; then
    echo "⚠️ Warning: Failed to update session"
    return 1
  fi

  echo "💾 Session updated: $new_filename (#$new_issue_number)"
  return 0
}

# =============================================================================
# Main Routine (for E2E tests)
# =============================================================================

##
# @description Main routine for push command (E2E workflow)
# @noargs
# @global ISSUES_DIR Issue directory path
# @global SESSION_FILE Session file path
# @exitcode 0 If successful
# @exitcode 1-10 Various error codes (see push.md for details)
setup_main_routine() {
  main_routine() {
    # Step 1: Check prerequisites
    local prereq_exit_code=0
    check_prerequisites || prereq_exit_code=$?

    if [[ $prereq_exit_code -ne 0 ]]; then
      case $prereq_exit_code in
        1)
          echo "❌ Error: 'gh' command not found."
          echo "💡 Please install GitHub CLI: https://cli.github.com/"
          return 1
          ;;
        2)
          echo "❌ Error: GitHub authentication required."
          echo "💡 Run: gh auth login"
          return 2
          ;;
      esac
    fi

    # Step 2: Load session
    if ! _load_issue_session "$SESSION_FILE"; then
      return 1
    fi

    # Step 3: Validate issue file
    if ! _validate_issue_file "$ISSUES_DIR" "$filename"; then
      return 1
    fi

    # Step 4: Extract issue content
    if ! _extract_issue_content "$issue_file"; then
      return 1
    fi

    # Step 5: Push to GitHub (detect new vs existing)
    local push_exit_code=0
    if [[ "$filename" =~ ^new- ]]; then
      push_new_issue "$title" "$body" || push_exit_code=$?
      if [[ $push_exit_code -ne 0 ]]; then
        return $push_exit_code
      fi

      # T5: Rename file for new issue
      local rename_exit_code=0
      rename_new_issue_file "$filename" "$issue_number" || rename_exit_code=$?
      if [[ $rename_exit_code -ne 0 ]]; then
        return $rename_exit_code
      fi

      # T5: Update session with new filename
      if ! update_session_after_push "$new_filename" "$issue_number"; then
        return 1
      fi
    else
      push_existing_issue "$filename" "$title" "$body" || push_exit_code=$?
      if [[ $push_exit_code -ne 0 ]]; then
        return $push_exit_code
      fi

      # T5: Update session (no rename needed)
      if ! update_session_after_push "$filename" "$issue_number"; then
        return 1
      fi
    fi

    # Step 6: Display next steps
    echo ""
    echo "💡 Next steps:"
    echo "   - '/idd:issue:view' to view the issue"
    echo "   - '/idd:issue:branch' to create a branch for this issue"
    echo "   - '/idd:issue:list' to see all issues"

    return 0
  }
}
