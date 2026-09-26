#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/prepare-commit-msg-options.unit.spec.sh
# @(#): Unit tests for parse_options() argument handling
#
# @file prepare-commit-msg-options.unit.spec.sh
# @brief Unit tests for command-line option and positional argument parsing
# @description
#   Tests parse_options() in a real subprocess so that process exit codes and
#   non-termination (infinite loop) are observable as assertable statuses.
#   An external timeout guards every example: a hang is reported as status 124
#   instead of blocking the test suite.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - parse_options()'
  # Run parse_options in a subprocess under an external timeout.
  # The script is sourced (not executed), so the main block is skipped and no
  # AI generation is triggered. Parsed globals are echoed for inspection.
  run_parse_options() {
    timeout 10 bash -c '
      source scripts/prepare-commit-msg.sh
      parse_options "$@"
      echo "OUTPUT_FILE=[${OUTPUT_FILE}]"
      echo "AI_MODEL=[${AI_MODEL}]"
    ' parse-options-driver "$@"
  }

  Context 'Given: positional arguments in Git native hook convention'
    Context 'When: a single positional argument is given'
      It 'Then: [正常] - terminates and adopts the argument as OUTPUT_FILE'
        When run run_parse_options .git/COMMIT_EDITMSG
        The status should equal 0
        The output should include 'OUTPUT_FILE=[.git/COMMIT_EDITMSG]'
      End
    End

    Context 'When: three positional arguments are given (<msgfile> <source> <sha>)'
      It 'Then: [エッジケース] - terminates and adopts only the first argument as OUTPUT_FILE'
        When run run_parse_options .git/COMMIT_EDITMSG message HEAD
        The status should equal 0
        The output should include 'OUTPUT_FILE=[.git/COMMIT_EDITMSG]'
      End
    End
  End

  Context 'Given: the --output option is used'
    Context 'When: --output FILE is given together with a positional argument'
      It 'Then: [正常] - keeps the --output value and ignores the positional argument'
        When run run_parse_options --output ./temp/explicit-output.txt .git/COMMIT_EDITMSG
        The status should equal 0
        The output should include 'OUTPUT_FILE=[./temp/explicit-output.txt]'
      End
    End

    Context 'When: --output is given an explicitly empty value'
      It 'Then: [エッジケース] - accepts the empty value and falls back to stdout mode'
        When run run_parse_options --output ''
        The status should equal 0
        The output should include 'OUTPUT_FILE=[]'
      End
    End

    Context 'When: --output is the last token with no value following'
      It 'Then: [異常] - reports the missing argument and exits 1'
        When run run_parse_options --output
        The status should equal 1
        The stderr should include 'Error: --output requires an argument'
      End
    End
  End

  Context 'Given: the --model option is used'
    Context 'When: --model is given an explicitly empty value'
      It 'Then: [エッジケース] - accepts the empty value instead of reporting a missing argument'
        When run run_parse_options --model ''
        The status should equal 0
        The output should include 'AI_MODEL=[]'
      End
    End

    Context 'When: --model is the last token with no value following'
      It 'Then: [異常] - reports the missing argument and exits 1'
        When run run_parse_options --model
        The status should equal 1
        The stderr should include 'Error: --model requires an argument'
      End
    End
  End

  Context 'Given: an unknown option is given'
    Context 'When: -x is passed'
      It 'Then: [異常] - reports the unknown option and exits 1'
        When run run_parse_options -x
        The status should equal 1
        The stderr should include 'Error: Unknown option: -x'
      End
    End
  End

  Context 'Given: the --help option is used'
    Context 'When: --help is passed'
      It 'Then: [正常] - prints usage and exits 0'
        When run run_parse_options --help
        The status should equal 0
        The output should include 'Usage:'
      End
    End
  End
End
