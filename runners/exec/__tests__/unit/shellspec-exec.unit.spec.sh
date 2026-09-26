#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/exec/__tests__/unit/shellspec-exec.unit.spec.sh
# @(#): ShellSpec unit tests for shellspec-exec.sh get_filelist failure propagation
#
# @file shellspec-exec.unit.spec.sh
# @brief ShellSpec unit tests for shellspec-exec.sh get_filelist failure propagation
# @description
#   Unit test suite scoped to a single concern of shellspec-exec.sh: a non-zero
#   exit status from get_filelist must travel all the way out through
#   get_spec_files() and resolve_spec_files() instead of being swallowed and
#   degraded into a "No spec files found" warning with exit 0.
#
#   A genuine zero-match result is not an error, so the control cases pin that
#   the warning path still fires when get_filelist succeeds with empty output.
#
#   Note: Include-ing shellspec-exec.sh enables `set -euo pipefail` in the example
#   shell and sources init-vars.lib.sh and get-filelist.lib.sh as a side effect,
#   so a shadow installed here is what every call site downstream observes.
#   `--execdir @project` is what makes its root-relative source paths resolve.
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

Describe 'shellspec-exec.sh - get_filelist failure propagation Unit Tests'
  Include runners/exec/shellspec-exec.sh

  # get_filelist is shadowed so the exit status and the listing reaching the
  # functions under test are fully controlled and no filesystem walk happens.
  # The failing shadow stays silent so stderr assertions observe only the
  # messages shellspec-exec.sh itself produces.
  shadow_failing_get_filelist() {
    get_filelist() { return 1; }
  }

  # A successful shadow that emits one root-relative spec path, mirroring the
  # shape of real get_filelist output.
  shadow_listing_get_filelist() {
    get_filelist() { printf '%s\n' './runners/exec/__tests__/unit/dummy.spec.sh'; }
  }

  # A successful shadow that emits nothing: a genuine zero-match, which the
  # get_filelist contract defines as success rather than an error.
  shadow_empty_get_filelist() {
    get_filelist() { return 0; }
  }

  # A successful shadow that emits two root-relative spec paths. Two lines are what
  # make an element-splitting bug visible: a one-line listing looks identical whether
  # it is split or kept whole.
  shadow_two_line_get_filelist() {
    get_filelist() { printf '%s\n' './a.spec.sh' './b.spec.sh'; }
  }

  # A successful shadow that emits a bare newline and nothing else. `$( )` strips the
  # trailing newline, so the listing reaching mapfile is the empty string: the here-string
  # then leaves exactly one empty element, which is the case _drop_empty_resolved exists for.
  shadow_newline_only_get_filelist() {
    get_filelist() { printf '\n'; }
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

  # Prints the element count of RESOLVED_SPEC_FILES, which resolve_spec_files sets as
  # a global rather than writing to stdout, so it is only observable from the calling
  # shell (`When call`, never `When run`).
  # `When call` suppresses errexit, so the status is captured explicitly and re-returned
  # after the count is printed: the probe stays usable for the failing shadows too.
  probe_resolved_count() {
    local status=0
    resolve_spec_files "$@" || status=$?
    printf 'COUNT=%s\n' "${#RESOLVED_SPEC_FILES[@]}"
    return "$status"
  }

  # Prints SKIP_INTEGRATION_TESTS, the other global resolve_spec_files writes to instead of
  # returning a value. Deliberately kept separate from probe_resolved_count: that probe's
  # output is asserted with `should equal 'COUNT=N'`, so adding a field to it would break
  # the examples that use it.
  # `When call` suppresses errexit, so the non-zero status is captured before the flag is
  # printed and re-returned afterwards; printing first is what makes the flag observable
  # on the failure path at all.
  probe_skip_integration_flag() {
    local status=0
    # Pin the pre-call value instead of inheriting it. shellspec-exec.sh seeds the flag
    # from the environment (`${SKIP_INTEGRATION_TESTS:-1}`) and run_shellspec() exports it,
    # so a run under `--integration`, or any caller that already exported 0, would make the
    # SKIP=0 assertion vacuously true and stop detecting the hoist this Case exists to kill.
    SKIP_INTEGRATION_TESTS=1
    resolve_spec_files "$@" || status=$?
    printf 'SKIP=%s\n' "$SKIP_INTEGRATION_TESTS"
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
      It 'Then: [正常] - status 0 でその 1 行がそのまま stdout に出力される'
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

  # ============================================================================
  # T-01-02: a multi-line listing has to arrive as separate array elements
  # ============================================================================

  # 誤実装を殺す Case: `mapfile -t RESOLVED_SPEC_FILES <<<"$__listing"` を
  # `RESOLVED_SPEC_FILES=("$__listing")` と書くと listing 全体が改行込みの 1 要素に
  # 潰れ、COUNT が 2 ではなく 1 になってこの Case が RED になる。
  Describe 'Given: get_filelist が ./a.spec.sh と ./b.spec.sh の 2 行を返すシャドウ'
    Context 'When: resolve_spec_files unit を呼ぶ'
      It 'Then: [正常] - status 0 で RESOLVED_SPEC_FILES が 2 要素になる'
        When call with_shadowed_get_filelist shadow_two_line_get_filelist probe_resolved_count unit
        The status should be success
        The output should equal 'COUNT=2'
      End
    End
  End

  # ============================================================================
  # T-01-03: a newline-only listing has to normalize to an empty array
  # ============================================================================

  # 誤実装を殺す Case: here-string 直後の `_drop_empty_resolved` 呼び出しを落とすと
  # `<<<""` が残した空要素 1 つがそのまま生き、COUNT が 0 ではなく 1 になって
  # この Case が RED になる。
  # 上の「真の一致 0 件」control example と入力状態は収束する: `$( )` が末尾改行を
  # 落とすため、改行のみの producer も無出力の producer も `__listing=""` になる。
  # 観点が異なるので両方を残す: control example は warning + status を、この Case は
  # RESOLVED_SPEC_FILES の要素数 (COUNT) を観測する。
  Describe 'Given: get_filelist が改行 1 つだけを返すシャドウ'
    Context 'When: resolve_spec_files unit を呼ぶ'
      It 'Then: [エッジケース] - status 0 で RESOLVED_SPEC_FILES が空になり warning が出る'
        When call with_shadowed_get_filelist shadow_newline_only_get_filelist probe_resolved_count unit
        The status should be success
        The output should equal 'COUNT=0'
        The stderr should include "Warning: No spec files found for test type 'unit'"
      End
    End
  End

  # ============================================================================
  # T-01-04: the `system` side effect is settled before the failure path
  # ============================================================================

  # 誤実装を殺す Case: `if ! __listing=$(get_spec_files ...); then return 1; fi` を
  # `[[ "$test_type" == "system" ]] && SKIP_INTEGRATION_TESTS=0` より前に持ち上げる
  # (「先に失敗させる」リファクタ) と、失敗時に副作用が確定しないまま関数を抜けるため
  # SKIP が 0 ではなく既定値 1 のままになり、この Case が RED になる。status の伝播だけを
  # 見ていてもこの並べ替えは検出できない (並べ替えても status は 1 のまま) ので、観測対象は
  # SKIP の値そのものにしている。
  # 前提 1: example 開始時の値が既定値 1 であること。shellspec-exec.sh の
  # `SKIP_INTEGRATION_TESTS="${SKIP_INTEGRATION_TESTS:-1}"` が与える値なので、環境変数で
  # 0 を渡した状態でこの spec を走らせるとこの Case は前提を失う。
  # 前提 2: ShellSpec は example ごとに独立したサブシェルで評価するため、ここで 0 になった
  # 値は後続 example に漏れない。同じ `:-1` 初期化を持つ 2 example の使い捨て spec で
  # 実測して確認済み (2 例目は既定値 1 を観測)。
  Describe 'Given: get_filelist が status 1 を返すシャドウ (system 種別)'
    Context 'When: resolve_spec_files system を呼ぶ'
      It 'Then: [エッジケース] - status 1 を返すが SKIP_INTEGRATION_TESTS は 0 のまま残る'
        When call with_shadowed_get_filelist shadow_failing_get_filelist probe_skip_integration_flag system
        The status should be failure
        The output should equal 'SKIP=0'
      End
    End
  End
End
