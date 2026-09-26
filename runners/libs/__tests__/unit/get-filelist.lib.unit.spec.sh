#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./runners/libs/__tests__/unit/get-filelist.lib.unit.spec.sh
# @(#): ShellSpec unit tests for get-filelist.lib.sh get_filelist()
#
# @file get-filelist.lib.unit.spec.sh
# @brief ShellSpec unit tests for get-filelist.lib.sh get_filelist()
# @description
#   Unit test suite for the fail-first contract of get_filelist(): status 1 with a
#   `get_filelist:` prefixed stderr diagnostic when the search root is not a
#   directory, when the search root cannot be entered, when a filter body is empty,
#   or when either rg stage exits with 2 or higher.
#
#   Every example here drives a failure path, so none of them needs a populated
#   fixture tree. The search roots are paths ShellSpec already provides. `rg` is never
#   invoked: five examples return at a guard before the enumeration block is reached, and
#   the remaining two shadow `rg` (or `cd`) totally, so this suite creates no temporary
#   directory and does
#   not require `rg` on PATH. The behaviour of the real rg — enumerated output
#   format, filter semantics, non-deterministic output order — is covered by
#   runners/libs/__tests__/functional/get-filelist.lib.functional.spec.sh.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) -> When (action) -> Then (expected result)
#
#   Note: get_filelist() enters the search root in a subshell, so every search root
#   handed to the function under test must be absolute. Both $SHELLSPEC_TMPBASE and
#   $SHELLSPEC_PROJECT_ROOT are absolute.
#
#   Note: each example pins the specific diagnostic of the guard it exercises, not
#   only the `get_filelist:` prefix. Without that an example could fire an
#   unintended guard (for example the search-root guard, because the chosen root
#   turned out not to be a directory) and still look green.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#
  # 正確には、TMPBASE は *.sh を 1 つも含まないため、誤って列挙に到達しても一致なしの
  # status 0 になり、各 example の status should eq 1 がそれを捕まえる。これは現在の
  # TMPBASE の性質であって spec が強制するものではない。

Describe 'get-filelist.lib.sh - get_filelist() Unit Tests'
  Include runners/libs/get-filelist.lib.sh

  # 検索ルートには ShellSpec が渡す既存パスをそのまま使い、フィクスチャを作らない。
  # $SHELLSPEC_TMPBASE は run ごとに作られる実ディレクトリ、
  # $SHELLSPEC_PROJECT_ROOT/.shellspec は実在する通常ファイル。
  #
  # ルートに $SHELLSPEC_PROJECT_ROOT を使わない理由: [[ -d ]] は同じく通るが、将来の
  # リグレッションで列挙ブロックまで実行が落ちた場合にリポジトリ全体を歩いてしまい、
  # 「遅いだけで通る」テストになる。TMPBASE は小さいので挙動変化として表面化する。

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
        The stderr should include "get_filelist: search root is not a directory"
      End
    End
  End

  # ディレクトリではなく通常ファイルを渡した場合も同じガードで弾く。
  # root は spec が作るものではなく外部所有なので、通常ファイルであること自体を assert する。
  # これが無いと .shellspec が消えた場合に同じ診断が出て /no/such/dir の重複に退化し、
  # [[ -e ]] ミューテーションを検出できなくなったことに気づけない。
  # ガードを [[ -e ]] で実装するとこの Case だけが RED になる。
  Describe 'Given: 検索ルートにディレクトリではなくファイルのパスを指定する'
    Context "When: get_filelist \"\${SHELLSPEC_PROJECT_ROOT}/.shellspec\" '*.sh' を呼ぶ"
      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "${SHELLSPEC_PROJECT_ROOT}/.shellspec" '*.sh'
        The path "${SHELLSPEC_PROJECT_ROOT}/.shellspec" should be file
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist: search root is not a directory"
      End
    End
  End

  # ============================================================================
  # T-01-02: empty filter body guard
  # Given: a filter whose body is empty once a leading `!` has been stripped
  # ============================================================================

  Describe "Given: 検索ルートと glob '*.sh' に本体が空になるフィルタを渡す"
    Context "When: 単体の '!' だけのフィルタを渡して呼ぶ"
      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "$SHELLSPEC_TMPBASE" '*.sh' '!'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist: filter pattern is empty"
      End
    End

    # ガードを剥がした後の本体に掛けているので、'!' と '' は同じ同値クラスとして弾かれる。
    # 生引数を '!' と比較する実装にするとこの Case だけが RED になる。
    Context 'When: 空文字列のフィルタ (! なし) を渡して呼ぶ'
      It 'Then: [エッジケース] - 同じ空パターンガードで status 1 になる'
        When call get_filelist "$SHELLSPEC_TMPBASE" '*.sh' ''
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist: filter pattern is empty"
      End
    End
  End

  # ============================================================================
  # T-01-03: rg exit status propagation
  # Given: rg is shadowed by a function so its exit status can be driven
  # ============================================================================

  Describe 'Given: rg を関数シャドウして終了ステータスを制御する'

    # rg は列挙段 (rg --files ...) とフィルタ段 (rg [-v] -e <pat>) の両方で使われるため、
    # シャドウは argv の第 1 引数で両者を弁別する。列挙段はサブシェル内で呼ばれるが
    # 関数シャドウはサブシェルに継承されるので届く。
    #
    # どちらのシャドウも実 rg には委譲しない。委譲すると unit テストが rg の実在・実ツリーの
    # 内容・rg の並列列挙による出力順の非決定性に依存してしまう。実 rg 側の観点は
    # functional spec でカバーする。

    # 列挙段が status 2 を返した時点で get_filelist は return するため、フィルタ段には
    # 到達しないのが正しい実装。到達した場合は列挙エラーを握り潰した証拠なので、出力なしの
    # status 0 を返して example を RED に落とす (status 2 を返すと誤って GREEN になる)。
    # 失敗前に部分出力を 1 行出すのが重要。何も出さないと握り潰す実装でも __result が空に
    # なりフィルタループが即 break してトリップワイヤが発火しない (死んだ分岐になる)。
    # 呼び出し側がフィルタ引数を渡しているのも同じ理由。
    shadow_enumeration_error() {
      rg() {
        if [[ "$1" == '--files' ]]; then
          printf '%s
' './partial.sh'
          printf 'rg: forced enumeration error\n' >&2
          return 2
        fi
        printf 'rg: filter stage must not be reached after an enumeration error\n' >&2
        return 0
      }
    }

    unshadow_rg() {
      unset -f rg
    }

    # 列挙段は固定リストを返し、フィルタ段だけが status 2 を返す。固定リストにすることで
    # フィルタ段への入力が実ファイルツリーから切り離され、常に非空になる (列挙結果が空だと
    # フィルタループが break してこのシャドウが空振りする)。
    shadow_filter_error() {
      rg() {
        if [[ "$1" == '--files' ]]; then
          printf '%s\n' './a.sh' './libs/c.sh'
          return 0
        fi
        printf 'rg: forced filter error\n' >&2
        return 2
      }
    }

    Context "When: 列挙段の rg が exit 2 を返す状態で get_filelist \"\$SHELLSPEC_TMPBASE\" '*.sh' を呼ぶ"
      BeforeEach 'shadow_enumeration_error'
      AfterEach 'unshadow_rg'

      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "$SHELLSPEC_TMPBASE" '*.sh' 'partial'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist: failed to enumerate files under"
      End
    End

    # 列挙段だけ直してフィルタ段のエラー抑制を残すとこの Case が RED になる。
    Context "When: フィルタ段の rg が exit 2 を返す状態で get_filelist \"\$SHELLSPEC_TMPBASE\" '*.sh' 'libs/' を呼ぶ"
      BeforeEach 'shadow_filter_error'
      AfterEach 'unshadow_rg'

      It 'Then: [異常] - status 1 を返し stderr に get_filelist: 接頭辞付きメッセージを出力する'
        When call get_filelist "$SHELLSPEC_TMPBASE" '*.sh' 'libs/'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist: filter failed"
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
      if [[ "$1" == "$SHELLSPEC_TMPBASE" ]]; then
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
    Context "When: get_filelist \"\$SHELLSPEC_TMPBASE\" '*.sh' を呼ぶ"
      It 'Then: [異常] - 一致なし扱いで黙らず status 1 と get_filelist: 接頭辞付き stderr を返す'
        When call get_filelist "$SHELLSPEC_TMPBASE" '*.sh'
        The output should eq ""
        The status should eq 1
        The stderr should include "get_filelist: cannot enter search root"
      End
    End
  End

End
