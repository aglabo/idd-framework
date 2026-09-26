#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/e2e/prepare-commit-msg-hook.e2e.spec.sh
# @(#): E2E tests for prepare-commit-msg.sh main block fail-safe behavior
#
# @file prepare-commit-msg-hook.e2e.spec.sh
# @brief End-to-end tests for hook mode fail-safe and stdout mode fail-first
# @description
#   Runs prepare-commit-msg.sh as a real process so the main block and its
#   exit code are actually exercised (shellspec's `When call` cannot do this).
#   AI_MODEL is set through `--model gpt-mock`, which routes get_model_command()
#   to the codex branch, so `Mock codex` intercepts the AI call in the subprocess.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - main block fail-safe'
  HOOK_TMPDIR=""
  MSG_FILE=""
  MSG_BASELINE=""
  CODEX_CALL_LOG=""

  setup_hook_workspace() {
    HOOK_TMPDIR=$(mktemp -d)
    MSG_FILE="${HOOK_TMPDIR}/COMMIT_EDITMSG"
    MSG_BASELINE="${HOOK_TMPDIR}/COMMIT_EDITMSG.baseline"
    CODEX_CALL_LOG="${HOOK_TMPDIR}/codex-calls.log"
    : > "$CODEX_CALL_LOG"
    # The mock runs in a subprocess, so the log path must cross the process boundary
    export CODEX_CALL_LOG
  }

  teardown_hook_workspace() {
    rm -rf "$HOOK_TMPDIR"
  }

  BeforeEach 'setup_hook_workspace'
  AfterEach 'teardown_hook_workspace'

  # Exit status of a byte-for-byte comparison against the pre-run snapshot (0 = unchanged)
  msg_file_unchanged_status() {
    cmp "$MSG_FILE" "$MSG_BASELINE" > /dev/null 2>&1
    echo "$?"
  }

  Describe 'Given: hook mode (--output FILE) and the AI CLI fails'
    Mock codex
      exit 1
    End

    Context 'When: the output file holds only Git default comments'
      It 'Then: [異常] - exits 0 and leaves the output file byte-for-byte unchanged'
        printf '\n# Please enter the commit message for your changes.\n' > "$MSG_FILE"
        cp "$MSG_FILE" "$MSG_BASELINE"

        When run script ./scripts/prepare-commit-msg.sh --output "$MSG_FILE" --model gpt-mock

        The status should equal 0
        The stderr should include 'generation failed'
        The value "$(msg_file_unchanged_status)" should equal 0
      End
    End

    Context 'When: the output file does not exist yet'
      It 'Then: [エッジケース] - exits 0 without creating the output file'
        When run script ./scripts/prepare-commit-msg.sh --output "$MSG_FILE" --model gpt-mock

        The status should equal 0
        The stderr should include 'generation failed'
        The path "$MSG_FILE" should not be exist
      End
    End
  End

  Describe 'Given: hook mode (--output FILE) and the AI CLI succeeds'
    Mock codex
      printf '=== commit header ===\nfix(hook): ok\n=== commit footer ===\n'
    End

    Context 'When: the output file holds only Git default comments'
      It 'Then: [正常] - writes the generated message to the output file and exits 0'
        printf '\n# Please enter the commit message for your changes.\n' > "$MSG_FILE"

        When run script ./scripts/prepare-commit-msg.sh --output "$MSG_FILE" --model gpt-mock

        The status should equal 0
        The stderr should include 'Commit message written to'
        The contents of file "$MSG_FILE" should equal 'fix(hook): ok'
      End
    End
  End

  Describe 'Given: stdout mode (no --output) and the AI CLI fails'
    Mock codex
      exit 1
    End

    Context 'When: the script runs'
      It 'Then: [異常] - keeps fail-first and exits 1 without printing to stdout'
        When run script ./scripts/prepare-commit-msg.sh --model gpt-mock

        The status should equal 1
        The stdout should equal ''
        The stderr should include 'Warning: AI command failed'
      End
    End
  End

  Describe 'Given: stdout mode (no --output) and the AI CLI succeeds'
    Mock codex
      printf '=== commit header ===\nfix(hook): ok\n=== commit footer ===\n'
    End

    Context 'When: the script runs'
      It 'Then: [正常] - prints the generated message to stdout and exits 0'
        When run script ./scripts/prepare-commit-msg.sh --model gpt-mock

        The status should equal 0
        The stdout should equal 'fix(hook): ok'
      End
    End
  End

  Describe 'Given: hook mode (--output FILE) and the output file already holds a message'
    Mock codex
      # Records the call so the test can prove the AI CLI was never reached
      echo 'called' >> "$CODEX_CALL_LOG"
      printf '=== commit header ===\nfix(hook): regenerated\n=== commit footer ===\n'
    End

    Context 'When: the script runs'
      It 'Then: [正常] - skips generation, leaves the file unchanged, and never calls the AI CLI'
        printf 'feat: existing message\n' > "$MSG_FILE"
        cp "$MSG_FILE" "$MSG_BASELINE"

        When run script ./scripts/prepare-commit-msg.sh --output "$MSG_FILE" --model gpt-mock

        The status should equal 0
        The stderr should include 'Skipping generation'
        The value "$(msg_file_unchanged_status)" should equal 0
        The contents of file "$CODEX_CALL_LOG" should equal ''
      End
    End
  End

  Describe 'Given: hook mode (--output FILE) and the output directory rejects new files'
    Mock codex
      printf '=== commit header ===\nfix(hook): ok\n=== commit footer ===\n'
    End

    # Denies "create a new file" on the output directory while leaving the existing
    # file writable, which is what a read-only parent looks like to the hook.
    # POSIX chmod does not restrict writes on MSYS2 (the Windows ACL decides), so the
    # deny entry is set through icacls when that tool is available.
    block_new_files() {
      chmod a-w "$1" 2> /dev/null || true
      if command -v icacls > /dev/null 2>&1; then
        MSYS2_ARG_CONV_EXCL='*' icacls "$(cygpath -w "$1")" /deny "$(whoami):(WD,AD)" > /dev/null 2>&1 || true
      fi
    }

    unblock_new_files() {
      if command -v icacls > /dev/null 2>&1; then
        MSYS2_ARG_CONV_EXCL='*' icacls "$(cygpath -w "$1")" /remove:d "$(whoami)" > /dev/null 2>&1 || true
      fi
      chmod u+w "$1" 2> /dev/null || true
    }

    restore_hook_workspace() {
      unblock_new_files "$HOOK_TMPDIR"
    }

    AfterEach 'restore_hook_workspace'

    # Guards the examples below: without a working deny entry there is no write failure to observe
    new_files_still_creatable() {
      ( : > "${HOOK_TMPDIR}/.write-probe" ) 2> /dev/null || return 1
      rm -f "${HOOK_TMPDIR}/.write-probe"
      return 0
    }

    # Counts leftovers in the output directory, whatever a temp file happens to be named
    unexpected_file_count() {
      find "$HOOK_TMPDIR" -maxdepth 1 -type f \
        ! -name 'COMMIT_EDITMSG' ! -name 'COMMIT_EDITMSG.baseline' ! -name 'codex-calls.log' |
        wc -l | tr -d ' '
    }

    Context 'When: the output file holds only Git default comments'
      It 'Then: [異常] - exits 0, keeps the file byte-for-byte unchanged, and leaves no temp file'
        printf '\n# Please enter the commit message for your changes.\n' > "$MSG_FILE"
        cp "$MSG_FILE" "$MSG_BASELINE"
        block_new_files "$HOOK_TMPDIR"
        Skip if 'the sandbox still allows creating new files' new_files_still_creatable

        When run script ./scripts/prepare-commit-msg.sh --output "$MSG_FILE" --model gpt-mock

        The status should equal 0
        The stderr should include 'Keeping the Git default message'
        The value "$(msg_file_unchanged_status)" should equal 0
        The value "$(unexpected_file_count)" should equal 0
      End
    End
  End
End
