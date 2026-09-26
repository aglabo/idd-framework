#!/usr/bin/env bash
# src: ./scripts/prepare-commit-msg.sh
# @(#) : Prepare commit message using Codex CLI
#
# Copyright (c) 2026- atsushifx <http://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file prepare-commit-msg.sh
# @brief Prepare commit message using AI (Codex, Claude, or similar)
# @description
#   Automatically generates Conventional Commits format messages by analyzing
#   staged changes and recent commit history using AI.
#
#   **Design Contract (CRITICAL):**
#   1. Template (commit-message-generator.md) MUST output:
#      - === commit header === marker at start
#      - === commit footer === marker at end
#      - Message content between markers (no context data)
#   2. Git context (diff/log) is INPUT ONLY to the AI:
#      - NOT included in final message
#      - Filtered out before extracting message
#   3. Git Hook Compatibility:
#      - Conforms to prepare-commit-msg hook interface
#      - Can be symlinked to .git/hooks/prepare-commit-msg
#      - A non-zero exit ABORTS the commit, so hook mode (--output FILE) exits 0
#        when generation or the write fails, leaving Git's default message untouched
#
#   Features:
#   - Conventional Commits format compliance
#   - Context-aware message generation
#   - Dual output modes: stdout or file output
#   - Skips if existing message detected (hook mode)
#   - Fail-safe in hook mode: a generation or write failure leaves Git's default message intact
#   - Fail-first in stdout mode: a generation or write failure exits 1
#
# @example
#   # Output to stdout (interactive)
#   prepare-commit-msg.sh
#
#   # Output to Git commit buffer (hook mode)
#   prepare-commit-msg.sh --output .git/COMMIT_EDITMSG
#
#   # Use specific AI model
#   prepare-commit-msg.sh --output .git/COMMIT_EDITMSG --model claude-sonnet-4-5
#
# @exitcode 0 Success, skipped (existing message found), or a generation/write failure
#             in hook mode (--output FILE): Git's default message is left untouched
# @exitcode 1 Usage error, or a generation/write failure in stdout mode (no --output)
#
# @author atsushifx
# @version 1.3.1
# @license MIT

# shellcheck disable=SC2034

set -euo pipefail

# ============================================================================
# Path Initialization
# ============================================================================

##
# @description Repository root path
REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly REPO_ROOT

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Output file path for commit message (empty string means stdout)
OUTPUT_FILE=""

##
# @description AI model name for commit message generation (default: sonnet)
DEFAULT_AI_MODEL="sonnet"

###
# @description AI model name for commit message generation (default: sonnet)
AI_MODEL="sonnet"

##
# @description Path to commit message generator template
readonly AGENT_TEMPLATE_PATH=".claude/agents/commit-message-generator.md"

##
# @description Maximum number of recent commits to show in context
readonly MAX_LOG_ENTRIES=10

##
# @description Global array to store AI model command and arguments
# Populated by get_model_command() for safe command execution (no eval needed)
declare -a AI_COMMAND=()

# ============================================================================
# Functions
# ============================================================================

##
# @description Display usage information and help message
# @stdout Help message in standard format
# @return Always exits with 0
# @example
#   display_help
display_help() {
  local script_name
  script_name=$(basename "$0")
  cat <<EOF
Usage: $script_name [OPTIONS]

Generate Conventional Commits format messages by analyzing staged changes
and recent commit history using AI.

Options:
  --output FILE, -o FILE      Write commit message to FILE instead of stdout
  --model MODEL               AI model name (default: sonnet)
                              Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
  -h, --help                  Show this help message

Examples:
  # Output to stdout
  $script_name

  # Output to Git buffer with specific model
  $script_name --output .git/COMMIT_EDITMSG --model claude-sonnet-4-5

  # Short option form
  $script_name -o .git/COMMIT_EDITMSG
EOF
}

##
# @description Parse command-line options and set configuration
# Positional arguments follow Git's native hook convention
# (<msgfile> <commit-source> <sha>): only the message file is used as the
# output file, and an explicit --output takes precedence over it.
# @arg $@ string Command-line arguments to parse
# @option --output FILE|-o FILE Write commit message to FILE instead of stdout
# @option --model MODEL Specify AI model name (default: sonnet)
# @option -h|--help Display usage information
# @example
#   parse_options "$@"
#   parse_options --model claude-sonnet-4-5 --output .git/COMMIT_EDITMSG
# @exitcode 0 If parsing succeeds
# @exitcode 1 If unknown option provided or required argument missing
# @global OUTPUT_FILE
# @global AI_MODEL
parse_options() {
  local positional_index=0
  local output_option_given=false

  while [[ $# -gt 0 ]]; do
    case $1 in
    --output | -o)
      if [[ $# -lt 2 ]]; then
        echo "Error: --output requires an argument" >&2
        exit 1
      fi
      OUTPUT_FILE="$2"
      output_option_given=true
      shift 2
      ;;
    --model)
      if [[ $# -lt 2 ]]; then
        echo "Error: --model requires an argument" >&2
        exit 1
      fi
      AI_MODEL="$2"
      shift 2
      ;;
    --help | -h)
      display_help
      exit 0
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      # Git native hook argument order: <msgfile> <commit-source> <sha>
      # Only the message file is used; the remaining arguments are ignored
      if [[ $positional_index -eq 0 && "$output_option_given" == "false" ]]; then
        OUTPUT_FILE="$1"
      fi
      positional_index=$((positional_index + 1))
      shift
      ;;
    esac
  done
}

##
# @description Check if an existing commit message is present in file
# Filters out comment lines (starting with #) and empty lines, then checks for content
# @arg $1 string Path to commit message file
# @return 0 If file exists and non-comment, non-empty content found
# @return 1 If file not found, or only comments/empty lines found
# @example
#   if has_existing_message ".git/COMMIT_EDITMSG"; then
#     echo "Message already exists"
#   fi
has_existing_message() {
  local file="$1"

  # Fail safely if file does not exist
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Check for non-comment, non-empty lines
  grep -vE '^\s*(#|$)' "$file" | grep -q '.'
}

##
# @description Build context block with recent git logs and staged diff
# Provides AI with repository context to make informed commit messages
# @stdout Formatted context block with clear delimiters
# @return 0 Always succeeds (includes fallback messages if git commands fail)
# @example
#   context=$(make_context_block)
#   echo "$context" | claude -p
make_context_block() {
  echo "----- GIT LOGS -----"
  git log --oneline -10 || echo "No logs available."
  echo "----- END LOGS -----"
  echo ""

  echo "----- GIT DIFF -----"
  git diff --cached || echo "No diff available."
  echo "----- END DIFF -----"
}

##
# @description Set AI command array for specified model
#
# **Design Contract:**
# - Maps model names to provider CLI commands
# - Populates global AI_COMMAND array (not echo output)
# - Array format: (command arg1 arg2 ... )
# - Supports piped stdin: ... | "${AI_COMMAND[@]}"
#
# **Supported Providers:**
# - OpenAI (gpt-*, o1-*) → codex exec --model <model>
# - Anthropic (claude-*, haiku, sonnet, opus) → claude -p --model <model>
# - OpenCode (org/model) → opencode run --model <model>
#
# **Safety Notes:**
# - Uses array expansion, NOT eval (shell injection safe)
# - All model names validated before array creation
# - Unknown models exit with error
#
# @arg $1 string AI model name (default: sonnet)
# @return 0 If model is supported and AI_COMMAND is set
# @return 1 If model is unsupported
# @global AI_COMMAND Array populated with (command arg1 arg2 ...)
# @example
#   get_model_command "claude-sonnet-4-5"
#   echo "data" | "${AI_COMMAND[@]}"
#
#   get_model_command "gpt-5" || { echo "Error"; exit 1; }
get_model_command() {
  local model="${1:-${DEFAULT_AI_MODEL}}"

  case "$model" in
  # OpenAI models
  gpt-* | o1-*)
    AI_COMMAND=("codex" "exec" "--model" "${model}")
    ;;

  # Anthropic (Claude) models
  claude-* | haiku | sonnet | opus)
    # execute claude with no-mcp, accept edits permission
    AI_COMMAND=("claude" "-p" "--permission-mode" "acceptEdits" "--strict-mcp-config" "--mcp-config" '{"mcpServers":{}}' "--model" "${model}")
    ;;

  # Copilot models (copilot/model format)
  copilot/*)
    local copilot_model="${model#copilot/}"
    AI_COMMAND=("copilot" "--model" "${copilot_model}")
    ;;

  # OpenCode models (provider/model format)
  */*)
    AI_COMMAND=("opencode" "run" "--model" "${model}")
    ;;

  # Unsupported model
  *)
    echo "Error: Unsupported model: ${model}" >&2
    return 1
    ;;
  esac
}

##
# @description Generate commit message using configured AI model
#
# **Execution Contract:**
# 1. Loads commit-message-generator.md template
# 2. Appends git context (logs + diff) as AI input
# 3. Pipes combined input to AI command
# 4. Extracts message from either markdown code blocks or header markers
# 5. Validates markers exist and message is non-empty
#
# **Input Format to AI:**
#   cat template.md | cat logs | cat diff | <AI_COMMAND>
#
# **Supported Output Formats:**
#   Format 1 (Header markers - traditional):
#     === commit header ===
#     <commit message here>
#     === commit footer ===
#
#   Format 2 (Markdown code block - fallback):
#     ```text
#     <commit message here>
#     ```
#
# Execution flow:
#   Template + Context → AI → Try Markers → Fallback to Code Block → Return
#
# @arg $1 string Optional test message (for testing/debugging only)
# @return 0 If generation and validation succeeds
# @return 1 If model setup fails, the AI CLI is missing or fails, markers missing, or message empty
# @stdout Generated Conventional Commits format message
# @global AI_MODEL Used to determine AI command
# @global AI_COMMAND Populated by get_model_command()
# @example
#   commit_msg=$(generate_commit_message) || exit 1
#   echo "$commit_msg"
#
#   # For testing with mock message
#   generate_commit_message "fix: test message" || exit 1
generate_commit_message() {
  local test_message="${1:-}"

  # Return test message if provided (for testing purposes)
  if [[ -n "$test_message" ]]; then
    echo "${test_message}"
    return 0
  fi

  # Set up AI command for the configured model
  get_model_command "${AI_MODEL}" || return 1

  # Fail before invoking a missing AI CLI: exit 127 would abort the script under set -e
  if ! command -v "${AI_COMMAND[0]}" >/dev/null 2>&1; then
    echo "Warning: AI command not found: ${AI_COMMAND[0]}" >&2
    return 1
  fi

  local diff_output

  diff_output=$({
    cat .claude/agents/commit-message-generator.md
    echo ""
    make_context_block
  })

  # Normalize the prompt to valid UTF-8 (drops stray CP932 bytes that make the AI reject it)
  # Environments without iconv are the only case that passes the prompt through unchanged:
  # falling back on the unnormalized text would restore the very bytes this removes
  if command -v iconv >/dev/null 2>&1; then
    local normalized_output
    local iconv_status=0
    normalized_output=$(printf '%s' "$diff_output" | iconv -c -f UTF-8 -t UTF-8) || iconv_status=$?

    # `iconv -c` exits 1 whenever it drops a byte, even though the text it produced is
    # complete and valid, so status 1 is the expected success-with-stripping case.
    # A higher status means iconv died mid-stream (signal, 128+N): its output is then a
    # truncated prompt, and a commit message describing a partial diff is worse than none.
    if [[ $iconv_status -gt 1 ]]; then
      echo "Warning: prompt normalization failed: iconv exited ${iconv_status}" >&2
      return 1
    fi

    diff_output="$normalized_output"
  fi

  local full_output
  local ai_status=0

  # Here-string instead of a pipe: an AI CLI that answers without draining a large
  # prompt would kill the writer with SIGPIPE (141) and fail the pipeline under pipefail
  # Capture the AI exit status: an unguarded failure would abort the script under set -e
  full_output=$("${AI_COMMAND[@]}" <<<"$diff_output") || ai_status=$?

  if [[ $ai_status -ne 0 ]]; then
    echo "Warning: AI command failed: ${AI_COMMAND[0]} (exit ${ai_status})" >&2
    return 1
  fi

  # Extract the commit message from AI response
  # Skip context output and extract only the message between markers
  local after_diff
  if echo "$full_output" | grep -q "^----- END DIFF -----$"; then
    after_diff=$(echo "$full_output" | sed -n '/^----- END DIFF -----$/,$p' | sed '1d')
  else
    after_diff="$full_output"
  fi

  local extracted_msg=""

  # Format 1: Try extracting from standard markers (traditional format)
  # Also handles backtick-wrapped markers: `=== commit header ===`
  # shellcheck disable=SC2016
  if echo "$after_diff" | grep -qE '^`?=== commit header ===`?'; then
    # shellcheck disable=SC2016
    extracted_msg=$(echo "$after_diff" |
      sed -n '/^`\?=== commit header ===`\?/,/^`\?=== commit footer ===`\?/p' |
      sed '1d;$d')
  fi

  # Format 2: If not found, try markdown code blocks (```text, ```yaml, or plain ```)
  # shellcheck disable=SC2016
  if [[ -z "$extracted_msg" ]] && echo "$after_diff" | grep -qE '^```(text|yaml)?$'; then
    extracted_msg=$(echo "$after_diff" |
      sed -nE '/^```(text|yaml)?$/,/^```$/p' |
      sed '1d;$d')
  fi

  # If still not found, report error
  if [[ -z "$extracted_msg" ]]; then
    echo "Error: commit message not found in AI output" >&2
    echo 'Expected format: either === commit header === markers or ```text code blocks' >&2
    echo "Debug output:" >&2
    echo "$full_output" >&2
    return 1
  fi

  echo "$extracted_msg"
}

##
# @description Output commit message to stdout or write to file
# Handles both interactive (stdout) and Git hook (file) output modes
# In file mode the message lands through a temp sibling and a rename, so a failed
# write leaves the existing file (Git's default message) untouched
# @arg $1 string Commit message content
# @arg $2 string Optional output file path (defaults to OUTPUT_FILE)
# @return 0 If the message was delivered
# @return 1 If the output file could not be written; the existing file is left untouched
# @stdout Commit message (if OUTPUT_FILE is empty)
# @stderr Status message (if outputting to file), or a warning on a failed write
# @global OUTPUT_FILE Output file path (empty means stdout)
# @example
#   output_commit_message "$commit_msg" || exit 1
output_commit_message() {
  local commit_msg="$1"
  local output_file="${2:-${OUTPUT_FILE}}"

  if [[ "${FLAG_OUTPUT_TO_STDOUT:-}" == "true" || -z "$output_file" ]]; then
    # Output to stdout (interactive mode)
    echo "$commit_msg"
    return 0
  fi

  # Write to file (Git hook mode)
  # Never truncate the destination first: a failed write there would destroy Git's
  # default message and abort the commit. Fill a temp sibling, then rename it in.
  local temp_file="${output_file}.tmp.$$"

  if ! echo "${commit_msg}" >"${temp_file}"; then
    rm -f "${temp_file}"
    echo "Warning: failed to write the commit message to ${temp_file}" >&2
    return 1
  fi

  if ! mv -f "${temp_file}" "${output_file}"; then
    rm -f "${temp_file}"
    echo "Warning: failed to move the commit message into ${output_file}" >&2
    return 1
  fi

  echo "✦ Commit message written to ${output_file}" >&2
}

# ============================================================================
# Main Execution
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cd "$REPO_ROOT"

  # Parse command-line options
  parse_options "$@"

  # Check for existing message in Git buffer mode
  # Skip generation if commit message was previously generated
  if [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]]; then
    if has_existing_message "$OUTPUT_FILE"; then
      echo "[OK] Detected existing Git-generated commit message. Skipping generation." >&2
      exit 0
    fi
  fi

  # Generate commit message
  # Hook mode must never abort the commit: report the failure and leave Git's
  # default message untouched (no write, no placeholder). Stdout mode stays fail-first.
  if ! commit_msg=$(generate_commit_message); then
    if [[ -n "$OUTPUT_FILE" ]]; then
      echo "[WARN] Commit message generation failed. Keeping the Git default message." >&2
      exit 0
    fi
    exit 1
  fi

  # Output commit message
  # Hook mode must never abort the commit either: a failed write leaves the existing
  # file untouched, so report it and let Git keep its default message.
  if ! output_commit_message "$commit_msg"; then
    if [[ -n "$OUTPUT_FILE" ]]; then
      echo "[WARN] Commit message write failed. Keeping the Git default message." >&2
      exit 0
    fi
    exit 1
  fi
fi
