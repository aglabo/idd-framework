#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/__tests__/spec_helper.sh
# @(#): Shared ShellSpec helpers for the top-level runners test tree
#
# @file spec_helper.sh
# @brief Shared ShellSpec helpers for the top-level runners test tree
# @description
#   Holds only what is genuinely duplicated across the spec files in this directory:
#   the temporary fixture-directory lifecycle. This tree covers the runner entry points
#   (runners/*.sh); specs for runners/<subdir>/ live in that subdirectory's own
#   __tests__ with its own spec_helper.
#
#   Shadow helpers are deliberately NOT here. Each has exactly one consumer and differs
#   in body and restore semantics between specs, so the shadow stays next to the example
#   whose behaviour it defines.
#
#   The two functions below are byte-identical to their counterparts in
#   runners/libs/__tests__/spec_helper.sh. That duplication is the accepted cost of
#   per-directory locality: at two small functions it is cheaper than a libs spec
#   reaching up into this directory. Collapsing it later is one Include line per
#   consumer, so this is reversible, not a fork.
#
#   No `deny_real_rg` guard here, unlike the libs helper: run-shellcheck.unit.spec.sh
#   drives collect_lines through the real get_filelist, so it legitimately invokes rg.
#
#   This file is NOT auto-loaded. `.shellspec` has no --require, and adding one is not
#   possible: --require resolves against SHELLSPEC_HELPERDIR (default `spec/`, absent
#   here) and --helperdir is single-valued, so it cannot serve several __tests__ trees.
#   Each spec loads this file explicitly with
#   `Include runners/__tests__/spec_helper.sh`, which resolves correctly because
#   `--execdir @project` runs every spec from the project root.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# Guard against double sourcing. A plain assignment, not `readonly`: ShellSpec may
# source this into a shell where the variable is already set, and re-assigning a
# readonly variable aborts the run.
[[ -n "${_RUNNERS_SPEC_HELPER:-}" ]] && return 0
_RUNNERS_SPEC_HELPER=1

#
# @description Create a private empty fixture directory for the current example.
#              The helpers under test enter their search root in a subshell, so every
#              fixture path handed to them must be absolute; mktemp -d's path is used
#              as-is.
# @noargs
# @stdout nothing
# @exitcode 0 Directory created
# @exitcode 1 mktemp failed; no directory is left behind and FIXTURE_DIR stays unset
# @sideeffect Sets FIXTURE_DIR to the absolute path of the new directory
#
new_fixture_dir() {
  # FIXTURE_DIR is read only by spec files, which shellcheck never sees from here.
  # It must be global (no `local`) so the example body and later hooks can read it.
  # Failing early matters: without the `|| return 1` an unset FIXTURE_DIR would let a
  # spec's setup build its tree at the filesystem root instead.
  # shellcheck disable=SC2034
  FIXTURE_DIR=$(mktemp -d) || return 1
}

#
# @description Remove the directory created by new_fixture_dir(). Refuses to act on an
#              unset, empty or `/` value, so an AfterEach that runs after a failed
#              setup can never widen into a destructive `rm -rf`.
# @noargs
# @exitcode 0 Removed, or nothing to remove
# @exitcode 1 FIXTURE_DIR holds an unsafe value; nothing is removed
# @sideeffect Removes $FIXTURE_DIR from disk and unsets FIXTURE_DIR
#
remove_fixture_dir() {
  [[ -n "${FIXTURE_DIR:-}" ]] || return 0
  [[ "$FIXTURE_DIR" == '/' ]] && return 1
  rm -rf "$FIXTURE_DIR"
  unset FIXTURE_DIR
}
