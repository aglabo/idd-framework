#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/__tests__/unit/run-shellcheck.unit.spec.sh
# @(#): ShellSpec unit tests for run-shellcheck.sh collect_target_files()
#
# @file run-shellcheck.unit.spec.sh
# @brief ShellSpec unit tests for run-shellcheck.sh collect_target_files()
# @description
#   Unit test suite for the target file collection logic of run-shellcheck.sh.
#   Verifies that directory targets are enumerated through get_filelist for
#   `.sh` files while shellspec test files (`*.spec.sh`) and the vendored
#   `.tools/` tree are excluded, and that a get_filelist failure aborts the walk.
#
#   Note: the `.tools/` absence is produced by rg's hidden-directory default,
#   not by the `'![.]tools/'` filter; that filter is defence in depth and no
#   example here can tell the two apart.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) -> When (action) -> Then (expected result)
#
#   Note: sourcing run-shellcheck.sh changes CWD to the project root, so every
#   fixture path handed to the function under test must be absolute.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'run-shellcheck.sh - collect_target_files() Unit Tests'
  Include runners/run-shellcheck.sh

  # NUL-separated output is converted to lines so it can be asserted line-wise.
  collect_lines() { collect_target_files "$@" | tr '\0' '\n'; }

  setup() {
    FIXTURE_DIR="$(mktemp -d)"
    : >"${FIXTURE_DIR}/a.sh"
    : >"${FIXTURE_DIR}/b.spec.sh"
    mkdir -p "${FIXTURE_DIR}/.tools"
    : >"${FIXTURE_DIR}/.tools/x.sh"
  }

  cleanup() {
    if [[ -n "${FIXTURE_DIR:-}" ]]; then
      rm -rf "$FIXTURE_DIR"
    fi
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  # ============================================================================
  # Given: a fixture directory holding a.sh, b.spec.sh and .tools/x.sh
  # ============================================================================

  Describe 'Given: フィクスチャディレクトリに a.sh / b.spec.sh / .tools/x.sh が存在する'
    Context 'When: そのディレクトリの絶対パスを渡して collect_lines を呼ぶ'
      It 'Then: [正常] - 通常の .sh (a.sh) が収集される'
        When call collect_lines "$FIXTURE_DIR"
        The output should include "${FIXTURE_DIR}/a.sh"
        The status should be success
      End

      It 'Then: [正常] - shellspec テストコード (b.spec.sh) は収集されない'
        When call collect_lines "$FIXTURE_DIR"
        The output should not include "b.spec.sh"
        The status should be success
      End

      # この Case で .tools/x.sh が消えているのは rg の hidden ディレクトリ既定スキップに
      # よるもので、'![.]tools/' フィルタの効果ではない (フィルタを外しても出力は同一)。
      # 明示フィルタは --hidden を追加した場合に備えた多重防御として意図的に残している。
      It 'Then: [エッジケース] - 隠しディレクトリ配下 (.tools/x.sh) は収集されない'
        When call collect_lines "$FIXTURE_DIR"
        The output should not include "${FIXTURE_DIR}/.tools/x.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: a non-directory path is handed to collect_target_files
  # ============================================================================

  Describe 'Given: フィクスチャ内の b.spec.sh の絶対パス'
    Context 'When: そのファイルパスを直接渡して collect_lines を呼ぶ'
      It 'Then: [正常] - 明示指定されたファイルは除外されずそのまま出力される'
        When call collect_lines "${FIXTURE_DIR}/b.spec.sh"
        The output should equal "${FIXTURE_DIR}/b.spec.sh"
        The status should be success
      End
    End
  End

  Describe 'Given: 存在しないパス (no-such-file.sh)'
    Context 'When: そのパスを渡して collect_lines を呼ぶ'
      It 'Then: [異常] - ディレクトリ扱いされず入力値がそのまま出力され、エラー終了しない'
        When call collect_lines "${FIXTURE_DIR}/no-such-file.sh"
        The output should equal "${FIXTURE_DIR}/no-such-file.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: a directory target that holds no .sh file at all
  # ============================================================================

  setup_empty_target() {
    mkdir -p "${FIXTURE_DIR}/empty"
  }

  Describe 'Given: .sh ファイルを 1 つも含まない空ディレクトリ'
    BeforeEach 'setup_empty_target'

    Context 'When: その空ディレクトリを渡して collect_lines を呼ぶ'
      It 'Then: [エッジケース] - 出力は完全に空で幽霊レコード ("$target/") を出力しない'
        When call collect_lines "${FIXTURE_DIR}/empty"
        The output should equal ""
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: the argument list itself is the boundary (zero / multiple arguments)
  # ============================================================================

  Describe 'Given: 引数を 1 つも渡さない'
    Context 'When: collect_lines を呼ぶ'
      It 'Then: [エッジケース] - 出力は空で status 0 を返す (set -u 下でも中断しない)'
        When call collect_lines
        The output should equal ""
        The status should be success
      End
    End
  End

  Describe 'Given: ディレクトリと明示ファイルを同時に渡す'
    Context 'When: collect_lines を呼ぶ'
      It 'Then: [エッジケース] - 全引数が処理され両方のパスが出力される'
        When call collect_lines "$FIXTURE_DIR" "${FIXTURE_DIR}/b.spec.sh"
        The output should include "${FIXTURE_DIR}/a.sh"
        The output should include "${FIXTURE_DIR}/b.spec.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: shellcheck is shadowed so main()'s invocation can be captured
  # ============================================================================

  # main() invokes shellcheck inside a subshell, so the shadow records the
  # received arguments into a file under the fixture directory; the wrapper then
  # replays them on stdout so they can be asserted.
  main_with_shellcheck_shadow() {
    shellcheck() { printf '%s\n' "$@" >"${FIXTURE_DIR}/captured-args.txt"; }
    main "$@"
    local status=$?
    unset -f shellcheck
    cat "${FIXTURE_DIR}/captured-args.txt"
    return "$status"
  }

  Describe 'Given: shellcheck を関数シャドウした状態で main にフィクスチャディレクトリを渡す'
    Context 'When: main "$FIXTURE_DIR" を呼ぶ'
      It 'Then: [正常] - 捕捉引数に a.sh を含み b.spec.sh を含まない (収集結果が main に配線されている)'
        When call main_with_shellcheck_shadow "$FIXTURE_DIR"
        The output should include "${FIXTURE_DIR}/a.sh"
        The output should not include "b.spec.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: get_filelist exits non-zero for a target (fail-first propagation)
  # ============================================================================

  # A second directory target is required so that the silent dropping of the
  # remaining targets is what the assertions actually cover.
  setup_second_target() {
    mkdir -p "${FIXTURE_DIR}/second"
    : >"${FIXTURE_DIR}/second/c.sh"
  }

  # get_filelist is shadowed so that each call appends its search root to a log
  # before failing; the log is the direct evidence of where the walk stopped.
  # A function shadow is inherited by subshells, so main()'s collection sees it too.
  shadow_failing_get_filelist() {
    get_filelist() {
      printf '%s\n' "$1" >>"${FIXTURE_DIR}/get_filelist-calls.log"
      printf 'get_filelist: forced failure\n' >&2
      return 1
    }
  }

  collect_with_failing_get_filelist() {
    shadow_failing_get_filelist
    collect_target_files "$@"
    local status=$?
    unset -f get_filelist
    return "$status"
  }

  Describe 'Given: get_filelist を非ゼロ終了する関数でシャドウする'
    BeforeEach 'setup_second_target'

    Context 'When: ディレクトリターゲットを 2 つ渡して collect_target_files を呼ぶ'
      It 'Then: [異常] - 非ゼロを返し stderr に失敗したターゲット名を出し 2 つ目は走査されない'
        When call collect_with_failing_get_filelist "$FIXTURE_DIR" "${FIXTURE_DIR}/second"
        The status should be failure
        The stderr should include "Failed to collect .sh files under: ${FIXTURE_DIR}"
        # Aborting on the first failure means later targets are never walked.
        The contents of file "${FIXTURE_DIR}/get_filelist-calls.log" should not include "${FIXTURE_DIR}/second"
      End
    End
  End

  # main() runs shellcheck inside a subshell, so the shadow records its
  # invocation as a marker file; the absence of that marker is what proves
  # the shadow was never reached.
  main_with_failing_get_filelist() {
    shadow_failing_get_filelist
    shellcheck() { : >"${FIXTURE_DIR}/shellcheck-called.marker"; }
    main "$@"
    local status=$?
    unset -f get_filelist shellcheck
    return "$status"
  }

  Describe 'Given: get_filelist を非ゼロ終了する関数でシャドウし shellcheck もシャドウする'
    Context 'When: main "$FIXTURE_DIR" を呼ぶ'
      It 'Then: [異常] - main が非ゼロ終了し shellcheck は一度も呼ばれない'
        When call main_with_failing_get_filelist "$FIXTURE_DIR"
        The status should be failure
        The file "${FIXTURE_DIR}/shellcheck-called.marker" should not be exist
        The stderr should include "$FIXTURE_DIR"
      End
    End
  End
  # ============================================================================
  # Given: file names that merely CONTAIN `.spec.sh` without ending in it
  # 除外フィルタが末尾アンカーを持たないと、`.spec.sh` を名前の途中に含むだけの
  # 通常スクリプトまで巻き込んで落ちる。置き換え前の `find ! -name "*.spec.sh"`
  # はベース名の末尾に固定されていたので、この 2 ファイルは lint 対象だった。
  # ============================================================================

  setup_spec_lookalikes() {
    : >"${FIXTURE_DIR}/tool.spec.sh.wrapper.sh"
    mkdir -p "${FIXTURE_DIR}/x.spec.sh.d"
    : >"${FIXTURE_DIR}/x.spec.sh.d/helper.sh"
  }

  Describe 'Given: 名前の途中にだけ .spec.sh を含む tool.spec.sh.wrapper.sh / x.spec.sh.d/helper.sh が存在する'
    BeforeEach 'setup_spec_lookalikes'

    Context 'When: そのディレクトリの絶対パスを渡して collect_lines を呼ぶ'
      It 'Then: [エッジケース] - 末尾が .spec.sh でないファイルは除外されず収集される'
        When call collect_lines "$FIXTURE_DIR"
        The output should include "${FIXTURE_DIR}/tool.spec.sh.wrapper.sh"
        The output should include "${FIXTURE_DIR}/x.spec.sh.d/helper.sh"
        The status should be success
      End

      # 対照ケース: アンカーを付けても真の spec ファイルの除外は効いたままであること。
      It 'Then: [正常] - 末尾が .spec.sh の b.spec.sh は引き続き除外される'
        When call collect_lines "$FIXTURE_DIR"
        The output should not include "${FIXTURE_DIR}/b.spec.sh"
        The status should be success
      End
    End
  End
End
