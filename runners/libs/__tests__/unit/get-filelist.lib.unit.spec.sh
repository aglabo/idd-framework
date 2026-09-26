#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/libs/__tests__/unit/get-filelist.lib.unit.spec.sh
# @(#): ShellSpec unit tests for get-filelist.lib.sh get_filelist()
#
# @file get-filelist.lib.unit.spec.sh
# @brief ShellSpec unit tests for get-filelist.lib.sh get_filelist()
# @description
#   Unit test suite for the file enumeration logic of get-filelist.lib.sh.
#   Locks down the fail-first contract of get_filelist(): glob based enumeration
#   rooted at the given directory, `./`-prefixed forward-slash relative paths,
#   status 0 when nothing matches, and status 1 with a `get_filelist:` prefixed
#   stderr diagnostic when the search root is not a directory, the search root
#   cannot be entered, a filter pattern is empty, or rg exits with 2 or higher.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) -> When (action) -> Then (expected result)
#
#   Note: get_filelist() enters the search root in a subshell, so every fixture
#   path handed to the function under test must be absolute.
#
#   Note: `rg --files` walks the tree in parallel and its output order varies
#   between runs, so multi-line expectations are written as include/not-include
#   assertions instead of exact whole-output comparisons.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'get-filelist.lib.sh - get_filelist() Unit Tests'
  Include runners/libs/get-filelist.lib.sh

  setup() {
    FIXTURE_DIR="$(mktemp -d)"
    : >"${FIXTURE_DIR}/a.sh"
    : >"${FIXTURE_DIR}/b.spec.sh"
    : >"${FIXTURE_DIR}/note.txt"
    # パス文字列中に rg のオプションと紛らわしい -q / -x を含むフィクスチャ。
    : >"${FIXTURE_DIR}/opt-q.sh"
    : >"${FIXTURE_DIR}/opt-x.sh"
    # 先頭以外の位置にリテラルの ! を含むフィクスチャ。
    : >"${FIXTURE_DIR}/a!b.sh"
    mkdir -p "${FIXTURE_DIR}/libs" "${FIXTURE_DIR}/vendor" "${FIXTURE_DIR}/.tools"
    : >"${FIXTURE_DIR}/libs/c.sh"
    : >"${FIXTURE_DIR}/libs/d.spec.sh"
    : >"${FIXTURE_DIR}/vendor/v.sh"
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
  # T-01-01: pattern enumeration and output format
  # Given: a.sh / b.spec.sh / note.txt / libs/c.sh / libs/d.spec.sh /
  #        vendor/v.sh / .tools/x.sh live under the fixture directory
  # ============================================================================

  Describe 'Given: フィクスチャディレクトリに a.sh / b.spec.sh / note.txt / libs/c.sh / libs/d.spec.sh / vendor/v.sh / .tools/x.sh が存在する'
    Context "When: フィルタなしで get_filelist \"\$FIXTURE_DIR\" '*.sh' を呼ぶ"
      It 'Then: [正常] - ルート直下の .sh が ./ 接頭辞付きで列挙される'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should include "./a.sh"
        The status should be success
      End

      It 'Then: [正常] - サブディレクトリ配下もスラッシュ区切りの相対パスで列挙される'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should include "./libs/c.sh"
        The status should be success
      End

      It 'Then: [正常] - glob に一致しないファイル (note.txt) は列挙されない'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should not include "note.txt"
        The status should be success
      End

      # フィルタを渡していないので、隠しディレクトリが消えるのは rg の hidden 既定スキップによる。
      It 'Then: [エッジケース] - 隠しディレクトリ配下 (.tools/x.sh) は列挙されない'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should not include ".tools/x.sh"
        The status should be success
      End

      # 対照ケース: ルートガードが正常系を巻き込んでいないこと、および rg の診断が
      # stderr に漏れていないことを同時に pin する。
      It 'Then: [正常] - ルートガードに掛からず status 0 を返し stderr は空である'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should include "./a.sh"
        The status should be success
        The stderr should eq ""
      End
    End

    # rg exit 1 (一致なし) はエラーではない。閾値を「2 以上」ではなく「0 以外」で実装すると
    # この Case が RED になる。境界値 1 を pin する Case。
    Context "When: どのファイルにも一致しない glob '*.nomatch' を渡して呼ぶ"
      It 'Then: [エッジケース] - 出力は空で status 0 を返す (no-match はエラーではない)'
        When call get_filelist "$FIXTURE_DIR" '*.nomatch'
        The output should eq ""
        The status should be success
        The stderr should eq ""
      End
    End
  End

  # ============================================================================
  # T-01-01: search root guard
  # Given: the search root is not an existing directory
  # ============================================================================

  Describe 'Given: 存在しないディレクトリパスを検索ルートに指定する'
    Context "When: get_filelist \"/no/such/dir\" '*.sh' を呼ぶ"
      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "/no/such/dir" '*.sh'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End
  End

  # ディレクトリではなく通常ファイルを渡した場合も同じガードで弾く。
  # ガードを [[ -e ]] で実装するとこの Case だけが RED になる。
  Describe 'Given: 検索ルートにディレクトリではなくファイルのパスを指定する'
    Context "When: get_filelist \"\${FIXTURE_DIR}/a.sh\" '*.sh' を呼ぶ"
      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "${FIXTURE_DIR}/a.sh" '*.sh'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End
  End

  # ============================================================================
  # T-01-02: empty filter body guard
  # Given: a filter whose body is empty once a leading `!` has been stripped
  # ============================================================================

  Describe "Given: フィクスチャディレクトリと glob '*.sh' に本体が空になるフィルタを渡す"
    Context "When: 単体の '!' だけのフィルタを渡して呼ぶ"
      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End

    # ガードを剥がした後の本体に掛けているので、'!' と '' は同じ同値クラスとして弾かれる。
    # 生引数を '!' と比較する実装にするとこの Case だけが RED になる。
    Context 'When: 空文字列のフィルタ (! なし) を渡して呼ぶ'
      It 'Then: [エッジケース] - 同じ空パターンガードで status 1 になる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' ''
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End
  End

  # ============================================================================
  # T-01-02: existing include (絞り込み) filters
  # Given: a single filter without a `!` prefix is passed alongside the '*.sh' glob
  # ============================================================================

  Describe "Given: フィクスチャディレクトリと glob '*.sh' に ! の付かないフィルタを 1 つ渡す"
    Context "When: スラッシュを含むフィルタ 'libs/' (ディレクトリ形) を渡して呼ぶ"
      It 'Then: [正常] - raw regex として適用され ./libs/ 配下のみに絞り込まれる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' 'libs/'
        The output should include "./libs/c.sh"
        The output should include "./libs/d.spec.sh"
        The output should not include "./a.sh"
        The status should be success
        The stderr should eq ""
      End
    End

    Context "When: スラッシュを含まない glob フィルタ '*[.]spec[.]sh' を渡して呼ぶ"
      It 'Then: [正常] - args_to_filter の glob→regex 変換が効き spec ファイルのみに絞り込まれる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '*[.]spec[.]sh'
        The output should include "./b.spec.sh"
        The output should include "./libs/d.spec.sh"
        The output should not include "./a.sh"
        The status should be success
      End
    End

    # normalize_path が 'libs\' を 'libs/' に変換するため、T-01-02-01 と同じ結果になる。
    Context 'When: 区切りにバックスラッシュを使うフィルタ libs\ を渡して呼ぶ'
      It 'Then: [エッジケース] - normalize_path により libs/ として扱われ T-01-02-01 と同じ結果になる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' 'libs\'
        The output should include "./libs/c.sh"
        The output should include "./libs/d.spec.sh"
        The output should not include "./a.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # T-02-01: single exclusion (除外) filter
  # Given: a single filter prefixed with `!` is passed alongside the '*.sh' glob
  # ============================================================================

  Describe "Given: フィクスチャディレクトリと glob '*.sh' に ! で始まるフィルタを 1 つ渡す"
    Context "When: ! + glob パターンのフィルタ '!*[.]spec[.]sh' を渡して呼ぶ"
      It 'Then: [正常] - args_to_filter 変換後に rg -v が適用され spec ファイルだけが除外される'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!*[.]spec[.]sh'
        The output should include "./a.sh"
        The output should not include "./b.spec.sh"
        The output should not include "./libs/d.spec.sh"
        The status should be success
      End
    End

    Context "When: ! + ディレクトリ形 (スラッシュ有り) のフィルタ '!vendor/' を渡して呼ぶ"
      It 'Then: [正常] - ! を外した残りが raw regex として扱われ ./vendor/ 配下だけが除外される'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!vendor/'
        The output should not include "./vendor/v.sh"
        The output should include "./a.sh"
        The output should include "./libs/c.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # T-02-02: mixed include (絞り込み) and exclude (除外) filters
  # Given: both an include filter and an exclude filter are passed alongside '*.sh'
  # ============================================================================

  Describe "Given: フィクスチャディレクトリと glob '*.sh' に絞り込みフィルタと除外フィルタを両方渡す"
    Context "When: 絞り込み -> 除外 の順で 'libs/' '!d' を渡して呼ぶ"
      It 'Then: [正常] - ./libs/ に絞った後 d を含む行が除外され ./libs/c.sh のみが残る'
        When call get_filelist "$FIXTURE_DIR" '*.sh' 'libs/' '!d'
        The output should eq "./libs/c.sh"
        The status should be success
      End
    End

    # '!d' は args_to_filter 変換後も部分一致 regex 'd' なので "vendor" にも一致する。
    # この Case では vendor が先に落ちるだけで、最終結果は T-02-02-01 と同じになる。
    Context "When: 除外 -> 絞り込み の順で '!d' 'libs/' を渡して呼ぶ (T-02-02-01 と順序を入れ替える)"
      It 'Then: [エッジケース] - AND 適用のため結果は T-02-02-01 と同じ ./libs/c.sh のみになる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!d' 'libs/'
        The output should eq "./libs/c.sh"
        The status should be success
      End
    End
  End

  # ============================================================================
  # T-01-03: rg exit status propagation
  # Given: rg is shadowed by a function so its exit status can be driven,
  #        or the natural exit status of the real rg is observed
  # ============================================================================

  Describe 'Given: rg を関数シャドウして終了ステータスを制御する、または実 rg の自然な status を観測する'
    # rg は列挙段 (rg --files ...) とフィルタ段 (rg [-v] -e <pat>) の両方で使われるため、
    # シャドウは argv の第 1 引数で両者を弁別する。列挙段はサブシェル内で呼ばれるが
    # 関数シャドウはサブシェルに継承されるので届く。
    shadow_enumeration_error() {
      rg() {
        if [[ "$1" == '--files' ]]; then
          printf 'rg: forced enumeration error\n' >&2
          return 2
        fi
        command rg "$@"
      }
    }

    unshadow_rg() {
      unset -f rg
    }

    shadow_filter_error() {
      rg() {
        if [[ "$1" == '--files' ]]; then
          command rg "$@"
          return
        fi
        printf 'rg: forced filter error\n' >&2
        return 2
      }
    }

    Context "When: 列挙段の rg が exit 2 を返す状態で get_filelist \"\$FIXTURE_DIR\" '*.sh' を呼ぶ"
      BeforeEach 'shadow_enumeration_error'
      AfterEach 'unshadow_rg'

      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End

    # 列挙段だけ直してフィルタ段のエラー抑制を残すとこの Case が RED になる。
    Context "When: フィルタ段の rg が exit 2 を返す状態で get_filelist \"\$FIXTURE_DIR\" '*.sh' 'libs/' を呼ぶ"
      BeforeEach 'shadow_filter_error'
      AfterEach 'unshadow_rg'

      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "$FIXTURE_DIR" '*.sh' 'libs/'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End

    # 全件除外はフィルタ段の rg が exit 1 (一致なし) を返すケース。エラーではない。
    # 'The stderr should eq ""' があるため、rg exit 1 を誤ってエラー扱いする実装では RED になる。
    Context "When: 列挙結果の全件に一致する除外フィルタ '!sh' を渡して呼ぶ (実 rg が exit 1 を返す)"
      It 'Then: [エッジケース] - 全件除外は一致なしと同じ扱いで status 0 / 出力空 / stderr 空になる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!sh'
        The output should eq ""
        The status should be success
        The stderr should eq ""
      End
    End

    # run-shellcheck.sh / run-shellspec.sh はいずれも set -euo pipefail で動くため、
    # rg exit 1 で呼び出し元が死なないことを実運用どおり別プロセスで検証する。
    # ShellSpec の `When call` は errexit を抑制してしまうので `When run` を使う。
    Context 'When: set -euo pipefail を有効にした呼び出し元から rg が exit 1 になる呼び出しを行う'
      It 'Then: [エッジケース] - 呼び出し元は中断せず呼び出し後のマーカー行まで到達する'
        When run bash -c 'set -euo pipefail; . runners/libs/get-filelist.lib.sh; get_filelist "$1" "*.sh" "!sh"; printf "REACHED-AFTER-CALL\n"' _ "$FIXTURE_DIR"
        The output should include "REACHED-AFTER-CALL"
        The status should be success
        The stderr should eq ""
      End
    End
  End

  # ============================================================================
  # T-01-04: patterns starting with `-` must not be parsed as rg options
  # Given: opt-q.sh / opt-x.sh carry `-q` / `-x` inside their path strings
  # ============================================================================

  Describe "Given: フィクスチャに -q / -x をパス文字列に含む opt-q.sh / opt-x.sh が存在する"
    # `rg -v -q` は quiet モードになり出力ゼロ / exit 0 で全件を黙って消す。
    # パターンを `-e` の後に渡す実装でのみ、ただの部分一致除外として働く。
    Context "When: - で始まる除外フィルタ '!-q' を渡して呼ぶ"
      It 'Then: [異常] - -q はオプションではなくパターンとして扱われ ./opt-q.sh だけが除外される'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!-q'
        The output should include "./a.sh"
        The output should not include "./opt-q.sh"
        The status should be success
        The stderr should eq ""
      End
    End

    # `rg -x` は --line-regexp と解釈されパターンが欠落するため rg が exit 2 を返す。
    # A-3 適用後はそれが status 1 として表面化するので、-e 抜けは必ず RED になる。
    Context "When: - で始まる絞り込みフィルタ '-x' を渡して呼ぶ"
      It 'Then: [異常] - -x はオプションではなくパターンとして扱われ ./opt-x.sh のみに絞り込まれる'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '-x'
        The output should eq "./opt-x.sh"
        The status should be success
        The stderr should eq ""
      End
    End
  End

  # ============================================================================
  # T-01-05: previously unpinned breakage modes
  # Given: multiple exclusions, a backslash-separated exclusion body, and a
  #        literal `!` that does not sit at the head of the filter
  # ============================================================================

  Describe "Given: フィクスチャディレクトリと glob '*.sh' に除外フィルタを 2 つ渡す"
    # __excludes を単一スカラーに退化させる実装 (最後のフィルタの極性で全件を塗る等) を検出する。
    Context "When: '!vendor/' '!libs/' を渡して呼ぶ"
      It 'Then: [正常] - 両方のディレクトリが除外されルート直下のファイルだけが残る'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!vendor/' '!libs/'
        The output should include "./a.sh"
        The output should not include "./vendor/v.sh"
        The output should not include "./libs/c.sh"
        The status should be success
        The stderr should eq ""
      End
    End
  End

  Describe "Given: フィクスチャディレクトリと glob '*.sh' に normalize_path が必要な除外フィルタを渡す"
    # ! を剥がす前に normalize_path を呼ぶ実装、または剥がした本体ではなく生引数を
    # 渡す実装では、バックスラッシュが残って libs/ に一致せず RED になる。
    Context 'When: 区切りにバックスラッシュを使う除外フィルタ !libs\ を渡して呼ぶ'
      It 'Then: [エッジケース] - normalize_path により libs/ として扱われ ./libs/ 配下だけが除外される'
        When call get_filelist "$FIXTURE_DIR" '*.sh' '!libs\'
        The output should include "./a.sh"
        The output should not include "./libs/c.sh"
        The output should not include "./libs/d.spec.sh"
        The status should be success
        The stderr should eq ""
      End
    End
  End

  Describe 'Given: フィクスチャに先頭以外の位置にリテラルの ! を含む a!b.sh が存在する'
    # ! の検出を部分一致 (== *'!'*) で書くと除外扱いになり RED になる。正しくは先頭一致。
    Context "When: 先頭以外に ! を含むフィルタ 'a!b' を渡して呼ぶ"
      It 'Then: [エッジケース] - 除外ではなく絞り込みとして働き ./a!b.sh のみが残る'
        When call get_filelist "$FIXTURE_DIR" '*.sh' 'a!b'
        The output should eq "./a!b.sh"
        The status should be success
        The stderr should eq ""
      End
    End
  End
  # ============================================================================
  # T-04: a `cd` failure into the search root must not look like rg's no-match 1
  # Given: the search root clears the [[ -d ]] guard but cannot be entered
  # ============================================================================

  # Windows / Git Bash では POSIX のパーミッションビットが無効なので、`chmod -x` では
  # 「ディレクトリではあるが入れないルート」を作れない。代わりに cd を関数シャドウし、
  # 対象ルートに対してだけ失敗させる。関数シャドウは $( ) サブシェルに継承されるため、
  # 列挙段の `cd "$__root"` に確実に届く。ルートがガード通過後に消えた場合も同値。
  shadow_failing_cd() {
    cd() {
      if [[ "$1" == "$FIXTURE_DIR" ]]; then
        return 1
      fi
      builtin cd "$@"
    }
  }

  unshadow_cd() {
    unset -f cd
  }

  Describe 'Given: [[ -d ]] は通るが cd に失敗する検索ルートを与える'
    BeforeEach 'shadow_failing_cd'
    AfterEach 'unshadow_cd'

    # cd の失敗をそのまま $( ) の status にすると 1 になり、rg の「一致なし 1」と
    # 同じ値になるため 2 以上の閾値をすり抜けて status 0 / 出力空の沈黙になる。
    # cd の status を rg と衝突しない値で分離する実装でのみ GREEN になる Case。
    Context "When: get_filelist \"\$FIXTURE_DIR\" '*.sh' を呼ぶ"
      It 'Then: [異常] - 一致なし扱いで黙らず status 1 と get_filelist: 接頭辞付き stderr を返す'
        When call get_filelist "$FIXTURE_DIR" '*.sh'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist:"
      End
    End
  End
End
