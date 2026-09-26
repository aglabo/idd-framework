#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/__tests__/unit/run-shellspec.unit.spec.sh
# @(#): ShellSpec unit tests for run-shellspec.sh get_filelist failure propagation
#
# @file run-shellspec.unit.spec.sh
# @brief ShellSpec unit tests for run-shellspec.sh get_filelist failure propagation
# @description
#   Unit test suite scoped to a single concern of run-shellspec.sh: a non-zero
#   exit status from get_filelist must travel all the way out through
#   get_spec_files() and resolve_spec_files() instead of being swallowed and
#   degraded into a "No spec files found" warning with exit 0.
#
#   A genuine zero-match result is not an error, so the control cases pin that
#   the warning path still fires when get_filelist succeeds with empty output.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) -> When (action) -> Then (expected result)
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'run-shellspec.sh - get_filelist failure propagation Unit Tests'
  Include runners/run-shellspec.sh

  # get_filelist is shadowed so the exit status and the listing reaching the
  # functions under test are fully controlled and no filesystem walk happens.
  # The failing shadow stays silent so stderr assertions observe only the
  # messages run-shellspec.sh itself produces.
  shadow_failing_get_filelist() {
    get_filelist() { return 1; }
  }

  # A successful shadow that emits one root-relative spec path, mirroring the
  # shape of real get_filelist output.
  shadow_listing_get_filelist() {
    get_filelist() { printf '%s
' './runners/__tests__/unit/dummy.spec.sh'; }
  }

  # A successful shadow that emits nothing: a genuine zero-match, which the
  # get_filelist contract defines as success rather than an error.
  shadow_empty_get_filelist() {
    get_filelist() { return 0; }
  }

  # Runs <callee> with get_filelist replaced by <shadow>, then restores it.
  # A function shadow is inherited by subshells, so every call site sees it.
  with_shadowed_get_filelist() {
    local shadow="$1" callee="$2"
    shift 2
    "$shadow"
    "$callee" "$@"
    local status=$?
    unset -f get_filelist
    return "$status"
  }

  # ============================================================================
  # Given: get_filelist fails while get_spec_files enumerates specs
  # ============================================================================

  Describe 'Given: get_filelist を status 1 を返す関数でシャドウする'
    Context 'When: get_spec_files unit を呼ぶ'
      It 'Then: [異常] - プロセス置換で捨てず get_spec_files が非ゼロを返す'
        When call with_shadowed_get_filelist shadow_failing_get_filelist get_spec_files unit
        The status should be failure
        The output should equal ""
      End
    End
  End

  # ============================================================================
  # Given: get_filelist succeeds (control cases for the rewritten happy path)
  # ============================================================================

  Describe 'Given: get_filelist が status 0 で spec パスを 1 行返すシャドウ'
    Context 'When: get_spec_files unit を呼ぶ'
      It 'Then: [正常] - status 0 でその 1 行が filter_runnable_specs を通って出力される'
        When call with_shadowed_get_filelist shadow_listing_get_filelist get_spec_files unit
        The status should be success
        The output should include 'dummy.spec.sh'
      End
    End
  End

  Describe 'Given: get_filelist が status 0 で何も出力しないシャドウ'
    Context 'When: get_spec_files unit を呼ぶ'
      It 'Then: [エッジケース] - 一致 0 件はエラーではないので status 0 / 出力が空'
        When call with_shadowed_get_filelist shadow_empty_get_filelist get_spec_files unit
        The status should be success
        The output should equal ""
      End
    End
  End

  # ============================================================================
  # Given: the failure has to survive the second hop, resolve_spec_files()
  # ============================================================================

  Describe 'Given: get_filelist を status 1 を返す関数でシャドウする (resolve 経由)'
    Context 'When: resolve_spec_files unit を呼ぶ'
      It 'Then: [異常] - 非ゼロを返し No spec files found の偽陽性パスに落ちない'
        When call with_shadowed_get_filelist shadow_failing_get_filelist resolve_spec_files unit
        The status should be failure
        The output should equal ""
        The stderr should not include 'Warning: No spec files found'
      End
    End
  End

  Describe 'Given: get_filelist が status 0 で無出力のシャドウ (真の一致 0 件)'
    Context 'When: resolve_spec_files unit を呼ぶ'
      It 'Then: [エッジケース] - 従来どおり warning を stderr に出し status 0 を返す'
        When call with_shadowed_get_filelist shadow_empty_get_filelist resolve_spec_files unit
        The status should be success
        The stderr should include "Warning: No spec files found for test type 'unit'"
      End
    End
  End
End
