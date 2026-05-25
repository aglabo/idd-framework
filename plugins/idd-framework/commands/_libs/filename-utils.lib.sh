#!/usr/bin/env bash
# src: .claude/commands/_libs/filename-utils.lib.sh
# @(#) filename-utils.lib.sh
# @description Filename generation utilities for IDD framework
# @version 1.0.0
# @created 2025-10-19
# @author atsushifx
#

# Load io-utils for is_non_ascii()
# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/io-utils.lib.sh"

##
# @brief Translate text to English using codex-mcp
# @description Uses codex-mcp to translate text (especially Japanese) to English
# @param $1 Text to translate
# @return 0 on success, 1 on error
# @stdout Translated English text (lowercase, space-separated)
# @example
#   english=$(to_english_via_ai "ブランチ作成機能")
#   echo "$english"  # "branch creation feature"
##
to_english_via_ai() {
  local text="$1"

  if [ -z "$text" ]; then
    echo ""
    return 0
  fi

  local translate_prompt="
  Translate the following text to English for use in a URL slug.

- Return ONLY the English translation in lowercase words separated by spaces.
- Remove any duplicate consecutive words.
- No explanations, quotes, or punctuation.
---
${text}
"

  # Call codex-mcp and extract result
  local result
  if ! result=$(echo "$translate_prompt" | codex exec 2>/dev/null | tail -n 1 | tr -d '\n\r'); then
    return 1
  fi

  # Return empty if no result
  if [ -z "$result" ]; then
    return 1
  fi

  echo "$result"
  return 0
}

##
# @brief Generate URL-safe slug from text
# @description Converts text to lowercase, replaces spaces/special chars with hyphens, removes consecutive hyphens
# @param $1 Input text (e.g., title, summary)
# @param $2 Max length (optional, default: 50)
# @param $3 Translation function (optional, default: to_english_via_ai)
# @return 0 on success
# @stdout Generated slug (lowercase, hyphens only)
# @example
#   slug=$(generate_slug "Add User Authentication Feature")
#   echo "$slug"  # "add-user-authentication-feature"
#
#   # With custom translation function
#   slug=$(generate_slug "日本語タイトル" 50 "my_custom_translator")
##
generate_slug() {
  local text="$1"
  local max_length="${2:-50}"
  local translator="${3:-to_english_via_ai}"

  # Remove prefix pattern [xxx] from title
  text=$(printf '%s' "$text" | sed 's/^\[[^]]*\][[:space:]]*//')

  # Check if text contains non-ASCII (Japanese) characters
  if is_non_ascii "$text"; then
    # Translate Japanese to English using specified translator
    if ! text=$("$translator" "$text"); then
      # If translation fails, remove non-ASCII and continue
      text=$(printf '%s' "$text" | LC_ALL=C sed 's/[\x80-\xFF]//g')
    fi
  fi

  # Convert to lowercase, replace spaces and special chars with hyphens
  local slug
  slug=$(printf '%s' "$text" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//; s/-$//')

  # Truncate to max length
  slug="${slug:0:$max_length}"

  # Remove trailing incomplete word if truncated (cut at last hyphen)
  if [ ${#slug} -eq $max_length ]; then
    slug="${slug%-*}"  # Remove everything after last hyphen for complete words only
  fi

  echo "$slug"
}

##
# @brief Generate ISO8601 timestamp
# @description Returns current timestamp in format YYYYMMDD-HHMMSS
# @return 0 on success
# @stdout Timestamp string (e.g., "20251019-143052")
# @example
#   timestamp=$(generate_timestamp)
#   echo "$timestamp"  # "20251019-143052"
##
generate_timestamp() {
  date +"%Y%m%d-%H%M%S"
}

##
# @brief Generate issue draft filename
# @description Creates filename: {issue_no}-{timestamp}-{issue_type}-{slug}.md
#              For new issues: new-{timestamp}-{issue_type}-{slug}.md
# @param $1 Issue title
# @param $2 Issue type (feature|bug|enhancement|task|release|open_topic)
# @param $3 Issue number (optional, default: "new")
# @param $4 Translation function (optional, passed to generate_slug)
# @return 0 on success
# @stdout Generated filename
# @example
#   # New issue
#   filename=$(generate_issue_filename "Add User Auth" "feature")
#   echo "$filename"  # "new-20251019-143052-feature-add-user-auth.md"
#
#   # Existing issue
#   filename=$(generate_issue_filename "Add User Auth" "feature" "42")
#   echo "$filename"  # "42-20251019-143052-feature-add-user-auth.md"
##
generate_issue_filename() {
  local title="$1"
  local issue_type="$2"
  local issue_no="${3:-new}"
  local translator="${4:-to_english_via_ai}"

  local timestamp
  timestamp=$(generate_timestamp)

  local slug
  slug=$(generate_slug "$title" 30 "$translator")

  echo "${issue_no}-${timestamp}-${issue_type}-${slug}.md"
}

##
# @brief Generate full path for issue draft file
# @description Combines directory, issue number, timestamp, issue type, and slug into full path
# @param $1 Issue title
# @param $2 Issue type
# @param $3 Issue number (optional, default: "new")
# @param $4 Directory (optional, default: temp/idd/issues)
# @param $5 Translation function (optional, passed to generate_slug)
# @return 0 on success
# @stdout Full file path
# @example
#   # New issue
#   filepath=$(generate_issue_filepath "Add Auth" "feature")
#   echo "$filepath"  # "temp/idd/issues/new-20251019-143052-feature-add-auth.md"
#
#   # Existing issue
#   filepath=$(generate_issue_filepath "Fix Bug" "bug" "123")
#   echo "$filepath"  # "temp/idd/issues/123-20251019-143052-bug-fix-bug.md"
##
generate_issue_filepath() {
  local title="$1"
  local issue_type="$2"
  local issue_no="${3:-new}"
  local dir="${4:-temp/idd/issues}"
  local translator="${5:-to_english_via_ai}"

  local filename
  filename=$(generate_issue_filename "$title" "$issue_type" "$issue_no" "$translator")

  echo "${dir}/${filename}"
}
