#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/integration/prepare-commit-msg-failsafe.integration.spec.sh
# @(#): Integration tests for prepare-commit-msg.sh fail-safe behavior
#
# @file prepare-commit-msg-failsafe.integration.spec.sh
# @brief Integration tests for prompt normalization and AI failure handling
# @description
#   Sources prepare-commit-msg.sh and shadows make_context_block()/codex()
#   to inspect the prompt actually delivered to the AI CLI.
#   AI_MODEL="gpt-mock" routes get_model_command() to the codex branch,
#   so a codex() shadow intercepts the AI call in a sourced context.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - prompt UTF-8 normalization'
  Include scripts/prepare-commit-msg.sh

  # Captures the prompt the AI CLI receives on stdin, and every AI CLI invocation
  PROMPT_CAPTURE=""
  CODEX_CALL_LOG=""

  setup_prompt_capture() {
    PROMPT_CAPTURE=$(mktemp)
    CODEX_CALL_LOG=$(mktemp)
    AI_MODEL="gpt-mock"
  }

  teardown_prompt_capture() {
    rm -f "$PROMPT_CAPTURE" "$CODEX_CALL_LOG"
  }

  BeforeEach 'setup_prompt_capture'
  AfterEach 'teardown_prompt_capture'

  # codex() shadow: records stdin, then replies with a marker-wrapped message
  mock_codex() {
    codex() {
      cat > "$PROMPT_CAPTURE"
      echo 'called' >> "$CODEX_CALL_LOG"
      printf '=== commit header ===\nfix(hook): normalize prompt\n=== commit footer ===\n'
    }
  }

  # make_context_block() shadow: emits a stray CP932 lead byte (0x93) like the
  # real bug did, so the prompt is invalid UTF-8 before normalization
  mock_context_with_invalid_byte() {
    make_context_block() { printf 'diff --git a/x b/x\n\x93\x41\n'; }
  }

  # Runs generate_commit_message in a real subprocess so the script's own
  # `set -euo pipefail` stays in effect (shellspec's `When call` suppresses it)
  run_generate_in_subprocess() {
    bash -c '
      source scripts/prepare-commit-msg.sh
      AI_MODEL="gpt-mock"
      make_context_block() { printf "diff --git a/x b/x\n\x93\x41\n"; }
      codex() {
        cat > /dev/null
        printf "=== commit header ===\nfix(hook): normalize prompt\n=== commit footer ===\n"
      }
      generate_commit_message
    '
  }

  # Exit status of a strict UTF-8 validation over the captured prompt (0 = valid)
  prompt_utf8_status() {
    iconv -f UTF-8 -t UTF-8 < "$PROMPT_CAPTURE" > /dev/null 2>&1
    echo "$?"
  }

  # Number of raw 0x93 bytes in the captured prompt. Meaningful only for prompts with
  # no legitimate multi-byte text, where 0x93 can only be the stray CP932 lead byte
  # (a UTF-8 continuation byte of, say, 日 is 0x93 as well).
  prompt_invalid_byte_count() {
    LC_ALL=C tr -dc '\223' < "$PROMPT_CAPTURE" | wc -c | tr -d ' '
  }

  # Size of the captured prompt, so "valid UTF-8" cannot be satisfied by an empty file
  prompt_byte_count() {
    wc -c < "$PROMPT_CAPTURE" | tr -d ' '
  }

  # Runs generate_commit_message in a real subprocess whose entire prompt is invalid
  # bytes: cat() is shadowed so the agent template contributes nothing and only the
  # stray CP932 bytes remain. The shadow stays inside the subprocess because a cat()
  # shadow in the example shell would also intercept shellspec's own use of cat.
  run_generate_with_all_invalid_prompt() {
    CAPTURE="$PROMPT_CAPTURE" bash -c '
      source scripts/prepare-commit-msg.sh
      AI_MODEL="gpt-mock"
      cat() { :; }
      make_context_block() { printf "\x93\x93\x93"; }
      codex() {
        command cat > "$CAPTURE"
        printf "=== commit header ===\nfix(hook): normalize prompt\n=== commit footer ===\n"
      }
      generate_commit_message
    '
  }

  # Runs generate_commit_message against an iconv that drains the prompt, emits a
  # fragment and exits 139 (signal death). `iconv -c` already exits 1 when it merely
  # strips bytes, so only a status above that marks the output as truncated.
  run_generate_with_dying_iconv() {
    CALL_LOG="$CODEX_CALL_LOG" bash -c '
      source scripts/prepare-commit-msg.sh
      AI_MODEL="gpt-mock"
      make_context_block() { printf "diff --git a/x b/x\ncontext\n"; }
      iconv() { command cat > /dev/null; printf "diff --g"; return 139; }
      codex() {
        command cat > /dev/null
        echo called >> "$CALL_LOG"
        printf "=== commit header ===\nfix(hook): normalize prompt\n=== commit footer ===\n"
      }
      generate_commit_message
    '
  }

  Describe 'Given: iconv is available on PATH'
    Context 'When: generate_commit_message is called'
      It 'Then: [正常] - passes valid UTF-8 (Japanese) through to the AI CLI unchanged'
        make_context_block() { printf 'diff --git a/x b/x\nテスト\n'; }
        mock_codex

        When call generate_commit_message

        The status should equal 0
        The output should equal 'fix(hook): normalize prompt'
        The contents of file "$PROMPT_CAPTURE" should include 'テスト'
      End

      It 'Then: [異常] - strips a stray CP932 byte so the delivered prompt is valid UTF-8'
        mock_context_with_invalid_byte
        mock_codex

        When call generate_commit_message

        The status should equal 0
        The output should equal 'fix(hook): normalize prompt'
        The value "$(prompt_utf8_status)" should equal 0
        The value "$(prompt_byte_count)" should not equal 0
        The contents of file "$PROMPT_CAPTURE" should include 'diff --git'
      End

      It 'Then: [エッジケース] - still reaches the AI CLI when the context block is empty'
        make_context_block() { :; }
        mock_codex

        When call generate_commit_message

        The status should equal 0
        The output should equal 'fix(hook): normalize prompt'
        The value "$(grep -c '^called$' "$CODEX_CALL_LOG")" should equal 1
      End

      It 'Then: [異常] - does not abort the script under set -euo pipefail when the prompt holds invalid bytes'
        When call run_generate_in_subprocess

        The status should equal 0
        The output should equal 'fix(hook): normalize prompt'
      End
    End
  End

  Describe 'Given: the whole prompt normalizes to nothing (every byte is invalid)'
    Context 'When: generate_commit_message is called'
      It 'Then: [異常] - delivers a prompt free of the invalid bytes instead of restoring them'
        When call run_generate_with_all_invalid_prompt

        The status should equal 0
        The output should equal 'fix(hook): normalize prompt'
        The value "$(prompt_invalid_byte_count)" should equal 0
        The value "$(prompt_utf8_status)" should equal 0
      End
    End
  End

  Describe 'Given: iconv dies mid-stream and leaves truncated output'
    Context 'When: generate_commit_message is called'
      It 'Then: [異常] - refuses to send the truncated prompt and never calls the AI CLI'
        When call run_generate_with_dying_iconv

        The status should equal 1
        The output should equal ''
        The stderr should include 'prompt normalization failed'
        The contents of file "$CODEX_CALL_LOG" should equal ''
      End
    End
  End

  Describe 'Given: iconv is not available on PATH'
    Context 'When: generate_commit_message is called'
      It 'Then: [エッジケース] - passes the prompt through untouched instead of failing'
        mock_context_with_invalid_byte
        mock_codex
        # Hide iconv only; every other `command` use is delegated to the builtin
        command() {
          if [[ "$1" == "-v" && "$2" == "iconv" ]]; then
            return 1
          fi
          builtin command "$@"
        }

        When call generate_commit_message

        The status should equal 0
        The output should equal 'fix(hook): normalize prompt'
        The value "$(prompt_utf8_status)" should not equal 0
      End
    End
  End
End

Describe 'prepare-commit-msg.sh - AI CLI failure handling'
  Include scripts/prepare-commit-msg.sh

  # Records every AI CLI invocation, so "the AI was never called" is observable
  CODEX_CALL_LOG=""

  setup_ai_mocks() {
    CODEX_CALL_LOG=$(mktemp)
  }

  teardown_ai_mocks() {
    rm -f "$CODEX_CALL_LOG"
  }

  BeforeEach 'setup_ai_mocks'
  AfterEach 'teardown_ai_mocks'

  # Mock snippets: evaluated inside the subprocess, so they cannot contain single quotes
  # and must stay unexpanded here (SC2016 is intentional throughout this section)
  # shellcheck disable=SC2016
  MOCK_CODEX_OK='
    codex() {
      cat > /dev/null
      echo called >> "$CALL_LOG"
      printf "=== commit header ===\nfix(hook): guard ai failure\n=== commit footer ===\n"
    }
  '

  # Realistic AI output: the message is wrapped in markers and surrounded by chatter
  # shellcheck disable=SC2016
  MOCK_CODEX_VERBOSE_OK='
    codex() {
      cat > /dev/null
      echo called >> "$CALL_LOG"
      printf "thinking about the diff...\n"
      printf "=== commit header ===\nfix(hook): guard ai failure\n=== commit footer ===\n"
      printf "tokens used: 1234\n"
    }
  '

  # AI CLI that drains the prompt and then fails (rate limit / auth error)
  # shellcheck disable=SC2016
  MOCK_CODEX_FAIL='
    codex() {
      cat > /dev/null
      echo called >> "$CALL_LOG"
      return 1
    }
  '

  # AI CLI that succeeds but prints nothing (the prompt was silently rejected)
  # shellcheck disable=SC2016
  MOCK_CODEX_EMPTY='
    codex() {
      cat > /dev/null
      echo called >> "$CALL_LOG"
    }
  '

  # AI CLI that answers without reading stdin, fed a prompt far larger than the
  # 64 KiB pipe buffer: with a pipe the writer dies of SIGPIPE (141) under pipefail
  # shellcheck disable=SC2016
  MOCK_CODEX_IGNORES_STDIN='
    make_context_block() { printf "diff --git a/x b/x\n"; printf "%*s\n" 1048576 ""; }
    codex() {
      echo called >> "$CALL_LOG"
      printf "=== commit header ===\nfix(hook): guard ai failure\n=== commit footer ===\n"
    }
  '

  # Hides codex from `command -v` only; every other `command` use is delegated
  # shellcheck disable=SC2016
  MOCK_COMMAND_NO_CODEX='
    command() {
      if [ "$1" = "-v" ] && [ "$2" = "codex" ]; then
        return 1
      fi
      builtin command "$@"
    }
  '

  # Runs generate_commit_message in a real subprocess so the script keeps its own
  # `set -euo pipefail` (shellspec's `When call` suppresses it and hides abort bugs)
  # $1: shell snippet defining this scenario's shadows
  # $2: AI model override (defaults to the codex-routed mock model)
  run_generate_isolated() {
    SHADOWS="$1" CALL_LOG="$CODEX_CALL_LOG" MODEL="${2:-gpt-mock}" bash -c '
      source scripts/prepare-commit-msg.sh
      AI_MODEL="$MODEL"
      make_context_block() { printf "diff --git a/x b/x\ncontext\n"; }
      eval "$SHADOWS"
      generate_commit_message
    '
  }

  codex_call_count() {
    grep -c '^called$' "$CODEX_CALL_LOG" || true
  }

  Describe 'Given: the configured AI CLI is installed'
    Context 'When: generate_commit_message is called'
      It 'Then: [正常] - clears the existence check and invokes the AI CLI once'
        When call run_generate_isolated "$MOCK_CODEX_OK"

        The status should equal 0
        The output should equal 'fix(hook): guard ai failure'
        The value "$(codex_call_count)" should equal 1
      End
    End
  End

  Describe 'Given: the configured AI CLI is not installed'
    Context 'When: generate_commit_message is called'
      It 'Then: [異常] - warns with the command name and fails without invoking the AI'
        When call run_generate_isolated "${MOCK_CODEX_OK}${MOCK_COMMAND_NO_CODEX}"

        The status should equal 1
        The output should equal ''
        The stderr should include 'codex'
        The value "$(codex_call_count)" should equal 0
      End
    End
  End

  Describe 'Given: AI_MODEL names a model no branch supports'
    Context 'When: generate_commit_message is called'
      It 'Then: [異常] - fails on model resolution before reaching the AI CLI'
        When call run_generate_isolated "$MOCK_CODEX_OK" 'unknown-model'

        The status should equal 1
        The output should equal ''
        The stderr should include 'Error: Unsupported model: unknown-model'
        The value "$(codex_call_count)" should equal 0
      End
    End
  End

  Describe 'Given: the AI CLI exits 0 with a marker-wrapped message among other chatter'
    Context 'When: generate_commit_message is called'
      It 'Then: [正常] - returns only the text between the markers'
        When call run_generate_isolated "$MOCK_CODEX_VERBOSE_OK"

        The status should equal 0
        The output should equal 'fix(hook): guard ai failure'
      End
    End
  End

  Describe 'Given: the AI CLI exits non-zero'
    Context 'When: generate_commit_message is called'
      It 'Then: [異常] - warns and returns 1 instead of aborting under set -euo pipefail'
        When call run_generate_isolated "$MOCK_CODEX_FAIL"

        The status should equal 1
        The output should equal ''
        The stderr should include 'codex'
        The stderr should include 'failed'
        The value "$(codex_call_count)" should equal 1
      End
    End
  End

  Describe 'Given: the AI CLI exits 0 with empty output'
    Context 'When: generate_commit_message is called'
      It 'Then: [エッジケース] - reports the missing markers and returns 1'
        When call run_generate_isolated "$MOCK_CODEX_EMPTY"

        The status should equal 1
        The output should equal ''
        The stderr should include 'Error: commit message not found in AI output'
      End
    End
  End

  Describe 'Given: the AI CLI answers a large prompt without reading stdin'
    Context 'When: generate_commit_message is called'
      It 'Then: [エッジケース] - delivers the message instead of dying of SIGPIPE'
        When call run_generate_isolated "$MOCK_CODEX_IGNORES_STDIN"

        The status should equal 0
        The output should equal 'fix(hook): guard ai failure'
      End
    End
  End
End
