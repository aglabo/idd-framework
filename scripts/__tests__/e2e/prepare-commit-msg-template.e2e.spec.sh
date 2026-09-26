#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/e2e/prepare-commit-msg-template.e2e.spec.sh
# @(#): E2E tests for prepare-commit-msg.sh agent template path resolution
#
# @file prepare-commit-msg-template.e2e.spec.sh
# @brief End-to-end tests for the agent definition path the hook reads
# @description
#   Runs prepare-commit-msg.sh inside a throwaway git repository so that
#   `git rev-parse --show-toplevel` resolves to the sandbox instead of this
#   repository. The real repository still carries a working agent definition at
#   both the canonical and the legacy path, so only a sandbox with hand-placed
#   sentinel files can tell which path the hook actually reads.
#   AI_MODEL is set through `--model gpt-mock`, which routes get_model_command()
#   to the codex branch, so `Mock codex` intercepts the AI call and records the
#   prompt it received.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# cspell:words defence workdir RELPATH relpath


Describe 'prepare-commit-msg.sh - agent template path'
  HOOK_SCRIPT=""
  TEMPLATE_TMPDIR=""
  SANDBOX=""
  MSG_FILE=""
  PROMPT_CAPTURE=""

  # Canonical agent definition path, relative to the repository root
  CANONICAL_TEMPLATE_RELPATH="plugins/idd-framework/agents/commit-message-generator.md"
  # Legacy agent definition path the hook must no longer read
  LEGACY_TEMPLATE_RELPATH=".claude/agents/commit-message-generator.md"

  setup_template_sandbox() {
    # Absolute path: the hook runs with its CWD inside the sandbox, so a
    # repository-relative path to the script under test cannot be used
    HOOK_SCRIPT="$(git rev-parse --show-toplevel)/scripts/prepare-commit-msg.sh"

    TEMPLATE_TMPDIR=$(mktemp -d)
    SANDBOX="${TEMPLATE_TMPDIR}/repo"
    # Kept outside the sandbox repository so they never show up in its git context
    MSG_FILE="${TEMPLATE_TMPDIR}/COMMIT_EDITMSG"
    PROMPT_CAPTURE="${TEMPLATE_TMPDIR}/prompt.capture"

    mkdir -p "$SANDBOX"
    git -C "$SANDBOX" init -q

    # The mock runs in a subprocess, so the capture path must cross the process boundary
    export PROMPT_CAPTURE
  }

  teardown_template_sandbox() {
    rm -rf "$TEMPLATE_TMPDIR"
  }

  BeforeEach 'setup_template_sandbox'
  AfterEach 'teardown_template_sandbox'

  # Writes an agent definition carrying the given sentinel at the given sandbox-relative path
  write_sandbox_template() {
    local relpath="$1"
    local sentinel="$2"

    mkdir -p "${SANDBOX}/$(dirname "$relpath")"
    printf '# Agent Definition\n\n%s\n' "$sentinel" > "${SANDBOX}/${relpath}"
  }

  # Runs the hook as a real process with its CWD inside the sandbox repository,
  # so the script resolves REPO_ROOT to the sandbox. `When run script` cannot be
  # used here because it offers no control over the CWD.
  run_hook_in_sandbox() {
    (cd "$SANDBOX" && bash "$HOOK_SCRIPT" --output "$MSG_FILE" --model gpt-mock)
  }

  # Sources the script from a subdirectory of the sandbox repository and calls
  # generate_commit_message directly. Sourcing skips the main block, so the
  # `cd "$REPO_ROOT"` it performs never runs and the CWD stays on the subdirectory:
  # only a template path anchored to the repository root can still resolve.
  # A real subprocess is required to keep the script's own `set -euo pipefail` in
  # effect, which shellspec's `When call` would otherwise suppress.
  source_generate_from_subdir() {
    local workdir="${SANDBOX}/sub/dir"
    mkdir -p "$workdir"

    (
      cd "$workdir" && bash -c '
        source "$1"
        AI_MODEL="gpt-mock"
        generate_commit_message
      ' _ "$HOOK_SCRIPT"
    )
  }

  Describe 'Given: a sandbox repository holding the agent definition only at the canonical path'
    Mock codex
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): sandbox message\n=== commit footer ===\n'
    End

    Context 'When: the hook generates a commit message'
      It 'Then: [正常] - the prompt handed to the AI CLI carries the canonical definition'
        write_sandbox_template "$CANONICAL_TEMPLATE_RELPATH" 'CANONICAL-TEMPLATE-SENTINEL'

        When call run_hook_in_sandbox

        The status should equal 0
        The contents of file "$PROMPT_CAPTURE" should include 'CANONICAL-TEMPLATE-SENTINEL'
        The stderr should include 'Commit message written to'
      End
    End
  End

  Describe 'Given: the script is sourced with its CWD inside a subdirectory of the sandbox repository'
    Mock codex
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): sourced message\n=== commit footer ===\n'
    End

    Context 'When: generate_commit_message is called'
      It 'Then: [エッジケース] - the definition is still read from the repository root, so the prompt carries the canonical sentinel'
        write_sandbox_template "$CANONICAL_TEMPLATE_RELPATH" 'CANONICAL-TEMPLATE-SENTINEL'

        When call source_generate_from_subdir

        The status should equal 0
        The contents of file "$PROMPT_CAPTURE" should include 'CANONICAL-TEMPLATE-SENTINEL'
        The stdout should include 'fix(hook): sourced message'
        # An unresolved template path would leave `cat` complaining here instead of aborting:
        # the command substitution around it survives a failing `cat` under `set -euo pipefail`
        The stderr should not include 'No such file or directory'
      End
    End
  End

  Describe 'Given: a sandbox repository holding no agent definition at the canonical path'
    Mock codex
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): message from a template-less prompt\n=== commit footer ===\n'
    End

    Context 'When: the hook generates a commit message'
      It 'Then: [異常] - stderr reports the missing agent template and names the path it looked for'
        When call run_hook_in_sandbox

        The status should equal 0
        # Matched as one substring so that `cat`'s own "No such file or directory",
        # which also names the path, cannot satisfy this expectation
        The stderr should match pattern "*agent template not found: *${CANONICAL_TEMPLATE_RELPATH}*"
        The stderr should include 'Keeping the Git default message'
      End
    End
  End

  Describe 'Given: a sandbox repository holding a different agent definition at each of the canonical and legacy paths'
    Mock codex
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): canonical wins\n=== commit footer ===\n'
    End

    Context 'When: the hook generates a commit message'
      It 'Then: [正常] [characterization] - the prompt carries the canonical sentinel and none of the legacy one'
        write_sandbox_template "$CANONICAL_TEMPLATE_RELPATH" 'CANONICAL-TEMPLATE-SENTINEL'
        write_sandbox_template "$LEGACY_TEMPLATE_RELPATH" 'LEGACY-TEMPLATE-SENTINEL'

        When call run_hook_in_sandbox

        The status should equal 0
        The contents of file "$PROMPT_CAPTURE" should include 'CANONICAL-TEMPLATE-SENTINEL'
        # The legacy file sits inside the sandbox working tree but is never staged,
        # so the git diff in the context block cannot leak its sentinel either
        The contents of file "$PROMPT_CAPTURE" should not include 'LEGACY-TEMPLATE-SENTINEL'
        The stderr should include 'Commit message written to'
      End
    End
  End

  Describe 'Given: the template guard fires while the output file holds only Git default comments'
    MSG_BASELINE=""

    # Never called once the guard fires, but it has to exist on PATH: the AI CLI
    # pre-flight check runs before the template guard and would otherwise fail first
    Mock codex
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): message from a template-less prompt\n=== commit footer ===\n'
    End

    # Seeds the output file with a comment-only body, which has_existing_message()
    # treats as absent, and snapshots it so a byte comparison can prove the failing
    # run neither rewrote nor truncated it
    seed_default_message_file() {
      MSG_BASELINE="${TEMPLATE_TMPDIR}/COMMIT_EDITMSG.baseline"
      printf '%s\n' '# Please enter the commit message for your changes.' > "$MSG_FILE"
      cp "$MSG_FILE" "$MSG_BASELINE"
    }

    # Byte-level comparison: comparing file contents as strings would hide a
    # trailing-newline-only change
    output_file_state() {
      if cmp -s "$MSG_FILE" "$MSG_BASELINE"; then
        echo 'unchanged'
      else
        echo 'changed'
      fi
    }

    Context 'When: the script runs in hook mode'
      It 'Then: [異常] [characterization] - exits 0 and leaves the output file byte-for-byte unchanged'
        seed_default_message_file

        When call run_hook_in_sandbox

        The status should equal 0
        The value "$(output_file_state)" should equal 'unchanged'
        The stderr should include 'agent template not found'
        The stderr should include 'Keeping the Git default message'
      End
    End
  End

  Describe 'Given: the template guard fires and every AI CLI invocation is recorded'
    CODEX_CALL_LOG=""

    # Runs after the outer BeforeEach, so TEMPLATE_TMPDIR already exists.
    # The mock runs in a subprocess, so the log path must cross the process boundary.
    setup_codex_call_log() {
      CODEX_CALL_LOG="${TEMPLATE_TMPDIR}/codex.calls"
      : > "$CODEX_CALL_LOG"
      export CODEX_CALL_LOG
    }

    BeforeEach 'setup_codex_call_log'

    # Records the invocation before anything else, so even a template-less prompt
    # reaching the AI CLI leaves a trace
    Mock codex
      echo 'called' >> "$CODEX_CALL_LOG"
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): message from a template-less prompt\n=== commit footer ===\n'
    End

    codex_call_count() {
      grep -c '^called$' "$CODEX_CALL_LOG" || true
    }

    Context 'When: the script runs'
      It 'Then: [異常] - the AI CLI is never invoked'
        When call run_hook_in_sandbox

        The status should equal 0
        The value "$(codex_call_count)" should equal 0
        The stderr should include 'agent template not found'
        The stderr should include 'Keeping the Git default message'
      End
    End
  End

  Describe 'Given: the canonical template is absent and AI_MODEL matches no branch'
    # Sources the script inside the sandbox repository and calls
    # generate_commit_message with an explicit AI_MODEL, so the order in which
    # model resolution and the template guard fail becomes observable.
    # A real subprocess keeps the script's own `set -euo pipefail` in effect.
    source_generate_with_model() {
      local model="$1"

      (
        cd "$SANDBOX" && bash -c '
          source "$1"
          AI_MODEL="$2"
          generate_commit_message
        ' _ "$HOOK_SCRIPT" "$model"
      )
    }

    Context 'When: generate_commit_message is called'
      It 'Then: [異常] [characterization] - model resolution fails first and the template guard never reports'
        When call source_generate_with_model 'unknown-model'

        The status should equal 1
        The output should equal ''
        The stderr should include 'Unsupported model: unknown-model'
        # Self-defence for the guard placement: moving the guard above
        # get_model_command would surface the template warning here instead
        The stderr should not include 'agent template not found'
      End
    End
  End

  Describe 'Given: a sandbox repository whose canonical agent definition exists but cannot be read'
    CODEX_CALL_LOG=""

    # Runs after the outer BeforeEach, so TEMPLATE_TMPDIR already exists.
    # The mock runs in a subprocess, so the log path must cross the process boundary.
    setup_unreadable_call_log() {
      CODEX_CALL_LOG="${TEMPLATE_TMPDIR}/codex.calls"
      : > "$CODEX_CALL_LOG"
      export CODEX_CALL_LOG
    }

    BeforeEach 'setup_unreadable_call_log'

    # Records the invocation before anything else, so even a template-less prompt
    # reaching the AI CLI leaves a trace
    Mock codex
      echo 'called' >> "$CODEX_CALL_LOG"
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): message from a template-less prompt\n=== commit footer ===\n'
    End

    codex_call_count() {
      grep -c '^called$' "$CODEX_CALL_LOG" || true
    }

    # Sources the script inside the sandbox repository and shadows cat() so that
    # reading a definition which does exist fails. The shadow has to stay inside
    # the subprocess: a cat() shadow in the example shell would also intercept
    # shellspec's own use of cat, and it cannot cross a `bash "$HOOK_SCRIPT"`
    # boundary, so the sourced form is the only way to reach this path.
    # `chmod 000` is not an option because MSYS2 ACLs make an unreadable file
    # unreliable, and pointing the path at a directory is not either: `[[ -f ]]`
    # would turn false and the existing not-found guard would fire first.
    # A real subprocess also keeps the script's own `set -euo pipefail` in effect,
    # which shellspec's `When call` would otherwise suppress.
    source_generate_with_failing_cat() {
      (
        cd "$SANDBOX" && bash -c '
          source "$1"
          AI_MODEL="gpt-mock"
          cat() { return 1; }
          generate_commit_message
        ' _ "$HOOK_SCRIPT"
      )
    }

    Context 'When: generate_commit_message is called'
      It 'Then: [異常] - the read failure is reported, the AI CLI is never invoked, and the call returns 1'
        write_sandbox_template "$CANONICAL_TEMPLATE_RELPATH" 'CANONICAL-TEMPLATE-SENTINEL'

        When call source_generate_with_failing_cat

        The status should equal 1
        The output should equal ''
        # Matched as one substring so the message has to name the path it failed on
        The stderr should match pattern "*failed to read the agent template: *${CANONICAL_TEMPLATE_RELPATH}*"
        # A swallowed read failure would hand the AI CLI a template-less prompt
        The value "$(codex_call_count)" should equal 0
        # The file is present, so the absent-definition guard must not be the one reporting
        The stderr should not include 'agent template not found'
      End
    End
  End

  Describe 'Given: a sandbox repository holding no agent definition, with the script sourced inside it'
    # Never called once the guard fires, but it has to exist on PATH: the AI CLI
    # pre-flight check runs before the template guard and would otherwise fail first
    Mock codex
      cat > "$PROMPT_CAPTURE"
      printf '=== commit header ===\nfix(hook): message from a template-less prompt\n=== commit footer ===\n'
    End

    # Sources the script inside the sandbox repository and calls
    # generate_commit_message directly, so which guard reports stays observable
    # instead of being folded into the main block's hook-mode fail-safe exit 0.
    # A real subprocess keeps the script's own `set -euo pipefail` in effect.
    source_generate_in_sandbox() {
      (
        cd "$SANDBOX" && bash -c '
          source "$1"
          AI_MODEL="gpt-mock"
          generate_commit_message
        ' _ "$HOOK_SCRIPT"
      )
    }

    Context 'When: generate_commit_message is called'
      It 'Then: [異常] [characterization] - the absent-definition guard reports and the read-failure path stays silent'
        When call source_generate_in_sandbox

        The status should equal 1
        The output should equal ''
        The stderr should match pattern "*agent template not found: *${CANONICAL_TEMPLATE_RELPATH}*"
        # The two guards have to stay distinguishable, so that a caller can tell an
        # absent definition from one it could not read
        The stderr should not include 'failed to read'
      End
    End
  End
End
