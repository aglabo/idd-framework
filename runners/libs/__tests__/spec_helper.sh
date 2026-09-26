#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/libs/__tests__/spec_helper.sh
# @(#): Shared ShellSpec helpers for the runners/libs test tree
#
# @file spec_helper.sh
# @brief Shared ShellSpec helpers for the runners/libs test tree
# @description
#   Holds only what is genuinely duplicated across the spec files in this directory:
#   the temporary fixture-directory lifecycle, and an opt-in guard that makes an
#   accidental real `rg` invocation fail loudly.
#
#   Shadow helpers are deliberately NOT here. Each one has exactly one consumer, and
#   the shadow body is itself the specification of the example that uses it (which of
#   the two rg call sites is being driven, for instance), so moving it out of the spec
#   would make that example unreadable on its own. A helper with one caller is a jump,
#   not an abstraction.
#
#   This file is NOT auto-loaded. `.shellspec` has no --require, and adding one is not
#   possible here: --require resolves against SHELLSPEC_HELPERDIR (default `spec/`,
#   which this repository does not have) and --helperdir is single-valued, so it cannot
#   serve several __tests__ trees. Each spec loads this file explicitly with
#   `Include runners/libs/__tests__/spec_helper.sh`, which resolves correctly because
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
[[ -n "${_RUNNERS_LIBS_SPEC_HELPER:-}" ]] && return 0
_RUNNERS_LIBS_SPEC_HELPER=1

#
# @description Create a private empty fixture directory for the current example.
#              get_filelist() enters its search root in a subshell, so every fixture
#              path handed to it must be absolute; mktemp -d's path is used as-is.
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

#
# @description Replace `rg` with a stub that fails loudly, turning an accidental real
#              rg invocation into a visible failure instead of a silent pass. Opt-in on
#              purpose: this directory holds both the unit specs (which must never run
#              rg) and the functional specs (which require the real one), so installing
#              it unconditionally from here would break every functional example.
#              Enable it per spec with `BeforeEach 'deny_real_rg'`.
#
#              A function shadow, not a PATH stub: get_filelist() calls rg inside
#              `$( cd "$root"; rg ... )` and a function shadow is inherited by that
#              subshell. It also matches how the specs already control rg.
# @noargs
# @exitcode 0 Always
# @sideeffect Defines a shell function named `rg` in the caller's shell
#
deny_real_rg() {
  # Invoked indirectly: get_filelist() calls `rg`, which resolves to this function once
  # installed. ShellCheck cannot trace that, and SC2329's own text allows for it. Unlike
  # the spec files -- which the directory-scoped lint excludes -- this helper is a lint
  # target, so the finding is suppressed here at its definition site rather than
  # file-wide, which would also mask a genuinely dead helper added later.
  # shellcheck disable=SC2329
  rg() {
    printf 'spec_helper: real rg must not be invoked from this example (argv: %s)\n' "$*" >&2
    # Status 0 with no stdout, deliberately -- not a failing status. get_filelist() maps
    # any rg status >= 2 onto its own `return 1`, which is exactly what these examples
    # already assert, so a failing stub would let an accidental rg call pass unnoticed.
    # Returning 0 with an empty listing instead drives get_filelist to its
    # `[[ -z "$__result" ]] && return 0` path, so `The status should eq 1` fails and the
    # stderr line above says why. Same reasoning as shadow_enumeration_error's
    # "must not be reached" branch in the unit spec.
    return 0
  }
}

#
# @description Remove the stub installed by deny_real_rg(), restoring the real rg.
#              Tolerates being called when no stub is installed, so it is safe as an
#              AfterEach even for an example whose own shadow already unset it.
# @noargs
# @exitcode 0 Always
# @sideeffect Removes the shell function named `rg`, if any
#
allow_real_rg() {
  unset -f rg
}
