---
# Claude Code 必須要素
allowed-tools:
  - mcp__codex-mcp__codex
  - Bash(jq:*)

argument-hint: title summary
description: interactively edit summary with user feedback loop using codex-mcp

# 設定変数
config:
  libs_dir: .claude/commands/_libs

# プロジェクト要素
title: edit-summary
version: 0.6.0
created: 2025-10-18
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-18: show_summary() と get_choice() に分離、yes/no/quit 入力対応
  - 2025-10-18: ユーザー指示による summary 修正機能実装

copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## _edit-summary : Overview

カスタムスラッシュコマンドから呼び出されて、title と summary を受け取ります。
summary を表示後、Claude がユーザーと対話しながら summary を繰り返し編集します。
ユーザーが承認 (y) またはキャンセル (q) するまでループを継続します。

### ワークフロー

1. title と summary を引数として受け取る
2. title と summary を検証 (両方必須)
3. 対話ループ開始:
   - サマリー表示: 現在の summary をユーザーに表示
   - y/n/q 選択: ユーザーに選択を求める
     - y (yes): 編集終了 → ステップ4へ
     - n (no): 修正指示入力 → codex-mcp で編集 → ループ継続
     - q (quit): キャンセル → ステップ5へ
4. y の場合: `{"result": "success", "summary": "..."}` を出力して終了
5. q の場合: `{"cancel": true}` を出力して終了

### 主要機能

- title と summary の検証 (両方必須)
- 対話的 UI による y/n/q 選択
- ユーザー指示に基づく summary の修正 (codex-mcp 使用)
- 承認されるまで繰り返し修正
- キャンセル処理のサポート
- JSON 形式での出力

## 入出力仕様

### 入力パラメータ

引数として title と summary を受け取ります。両方とも必須です:

```bash
/_helpers:_edit-summary "新機能の追加" "現在のsummary"
```

- `title`: タイトル (必須)
- `summary`: 現在の summary テキスト (必須)

対話ループ内でユーザー入力を受け取ります:

- `y/n/q 選択`: 承認/修正/キャンセルの選択
- `user_instruction`: 修正指示 (n 選択時のみ)

### 出力形式

#### 対話的出力 (ループ中)

1. 現在の summary を表示
2. y/n/q の選択を求める
3. n の場合: ユーザーインストラクションを入力
4. 修正結果を表示
5. ステップ1に戻る

#### 最終出力 (y: 承認時)

```json
{
  "result": "success",
  "summary": "承認された最終 summary テキスト"
}
```

#### キャンセル出力 (q: キャンセル時)

```json
{
  "cancel": true
}
```

#### エラー時

```json
{
  "result": "error",
  "reason": "エラー理由"
}
```

エラー理由の種類:

- `"no title"`: title が指定されていない
- `"no summary"`: summary が指定されていない
- `"edit failed"`: 修正処理が失敗

## 使用例

### 基本的な使用 (修正して承認)

```bash
/_helpers:_edit-summary "データベース最適化" "クエリ性能を改善します。"
```

対話フロー:

```text
現在のサマリー:
「クエリ性能を改善します。」

このサマリーで確定しますか？
y: 承認して終了
n: 修正を続ける
q: キャンセルして終了

選択してください (y/n/q): n

どのように修正しますか？ 具体的な指示を入力してください: 具体的な数値を含めて

[codex-mcp で修正中...]

現在のサマリー:
「クエリ性能を改善し、インデックス最適化とキャッシュ戦略を導入してレスポンス時間を50%短縮します。」

このサマリーで確定しますか？
y: 承認して終了
n: 修正を続ける
q: キャンセルして終了

選択してください (y/n/q): y
```

最終出力:

```json
{
  "result": "success",
  "summary": "クエリ性能を改善し、インデックス最適化とキャッシュ戦略を導入してレスポンス時間を50%短縮します。"
}
```

### キャンセル例

```bash
/_helpers:_edit-summary "新機能" "ユーザー認証を追加"
```

対話フロー:

```text
現在のサマリー:
「ユーザー認証を追加」

このサマリーで確定しますか？
y: 承認して終了
n: 修正を続ける
q: キャンセルして終了

選択してください (y/n/q): q
```

出力:

```json
{
  "cancel": true
}
```

### エラー例 (引数不足)

```bash
/_helpers:_edit-summary "タイトル"
```

出力 (stderr):

```json
{
  "result": "error",
  "reason": "no summary"
}
```

## 実装詳細

このヘルパーは bash スクリプトによる初期検証と、Claude の対話機能および codex-mcp を組み合わせたループ処理で動作します。

### アルゴリズム

```text
[開始]
  ↓
[引数パース] → title, summary
  ↓
[引数検証] → 空ならエラー終了
  ↓
[Claude に制御移行] → TITLE, INITIAL_SUMMARY を出力
  ↓
[対話ループ開始]
  ↓
[サマリー表示] → show_summary()
  ↓
[y/n/q 選択]
  ├→ y → 最終 JSON 出力 → 終了
  ├→ q → キャンセル JSON 出力 → 終了
  └→ n → [ユーザー指示入力] → get_user_instruction()
        ↓
      [codex-mcp で編集] → edit_with_codex()
        ↓
      [ループ継続] → [サマリー表示] へ戻る
```

### 処理ステップ

#### Step 1: bash 初期設定

```bash
#!/usr/bin/env bash
set -euo pipefail
```

bash strict mode を有効化します。

#### Step 2: 引数検証

```bash
# 引数パース
title="${1:-}"
summary="${2:-}"

# 引数検証
[[ -z "$title" ]] && output_error "no title"
[[ -z "$summary" ]] && output_error "no summary"

# 初期 summary を表示 (Claude に引き継ぐ)
echo "TITLE: $title"
echo "INITIAL_SUMMARY: $summary"
```

title と summary が指定されていることを確認し、Claude に引き継ぎます。

#### Step 3: 対話ループ起動

bash スクリプトから Claude に制御が移り、対話ループを実行します。
詳細は「bash スクリプト実装」セクションと「関数ライブラリ」セクションを参照してください。

## bash スクリプト実装

bash スクリプトによる対話ループの実装です。

### Step 3: 初期値の取得と対話ループ

```bash
# bash から受け取った TITLE と INITIAL_SUMMARY を検出
# title="..." summary="..." として変数に格納済みと仮定

# 対話ループ
while true; do
  # サマリー表示
  show_summary "$summary"

  # y/n/q 選択 (入力検証ループ付き)
  choice=$(get_choice)

  case "$choice" in
    y)
      # 承認: 成功 JSON を出力して終了
      output_success "$summary"
      exit 0
      ;;
    q)
      # キャンセル: キャンセル JSON を出力して終了
      output_cancel
      exit 0
      ;;
    n)
      # 修正続行: ユーザー指示を取得
      user_instruction=$(get_user_instruction)

      # codex-mcp 用プロンプトを生成
      prompt=$(build_codex_prompt "$title" "$summary" "$user_instruction")

      # codex-mcp で編集 (Claude が実行)
      echo "CALL_CODEX: $prompt"
      # 編集結果を summary に格納 (Claude が read で渡す)
      read -r summary
      ;;
  esac
done
```

このスクリプトは関数ライブラリの関数を使用してシンプルに実装されています。

**改善ポイント:**

- `show_summary()` と `get_choice()` に分離することで、それぞれの責務が明確
- `get_choice()` が入力検証を行うため、case 文では y/n/q のみ処理
- yes/no/quit も入力可能（`get_choice()` 内で y/n/q に正規化）

## 関数ライブラリ

### output_error()

エラー出力を行い、スクリプトを終了します。

定義:

```bash
# エラー出力関数（JSON形式）
# 引数: $1 - エラー理由
# 終了コード: 1
output_error() {
  local reason="$1"
  cat <<EOF >&2
{
  "result": "error",
  "reason": "$reason"
}
EOF
  exit 1
}
```

使用例:

```bash
[[ -z "$title" ]] && output_error "no title"
[[ -z "$summary" ]] && output_error "no summary"
```

### show_summary()

現在のサマリーを表示します。

定義:

```bash
# サマリー表示
# 引数: $1 - summary
# 終了コード: 0
show_summary() {
  local summary="$1"

  cat <<EOF

現在のサマリー:
「$summary」

このサマリーで確定しますか？
y/yes: 承認して終了
n/no: 修正を続ける
q/quit: キャンセルして終了
EOF
}
```

使用例:

```bash
show_summary "$summary"
```

### get_choice()

y/n/q の選択を求め、入力検証を行います。

定義:

```bash
# y/n/q 選択入力 (入力検証ループ付き)
# 出力: y/n/q (小文字に正規化)
# 終了コード: 0
get_choice() {
  local choice

  while true; do
    read -r -p "選択してください (y/n/q): " choice

    # 小文字に変換
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    case "$choice" in
      y|yes)
        echo "y"
        return 0
        ;;
      n|no)
        echo "n"
        return 0
        ;;
      q|quit)
        echo "q"
        return 0
        ;;
      *)
        echo "エラー: y/yes, n/no, q/quit のいずれかを入力してください" >&2
        ;;
    esac
  done
}
```

使用例:

```bash
choice=$(get_choice)
```

### show_summary_and_get_choice()

サマリー表示と選択入力を組み合わせた便利関数です。

定義:

```bash
# サマリー表示と y/n/q 選択 (組み合わせ関数)
# 引数: $1 - summary
# 出力: y/n/q (小文字に正規化)
# 終了コード: 0
show_summary_and_get_choice() {
  local summary="$1"

  show_summary "$summary"
  get_choice
}
```

使用例:

```bash
choice=$(show_summary_and_get_choice "$summary")
```

### get_user_instruction()

ユーザーに修正指示を求めます。

定義:

```bash
# ユーザー指示入力
# 出力: user_instruction
# 終了コード: 0
get_user_instruction() {
  local instruction

  echo ""
  read -r -p "どのように修正しますか？ 具体的な指示を入力してください: " instruction
  echo "$instruction"
}
```

使用例:

```bash
user_instruction=$(get_user_instruction)
```

### build_codex_prompt()

codex-mcp 用のプロンプトを生成します。

定義:

```bash
# codex-mcp 用プロンプト生成
# 引数: $1 - title, $2 - summary, $3 - user_instruction
# 出力: プロンプトテキスト
# 終了コード: 0
build_codex_prompt() {
  local title="$1"
  local summary="$2"
  local instruction="$3"

  cat <<EOF
以下の summary を、ユーザーの指示に従って修正してください。

要件:
- 300-500文字程度を維持
- 簡潔で技術的な表現
- 日本語で記述

修正後の説明のみを出力してください。
---

タイトル: ${title}
現在の summary: ${summary}
ユーザーの指示: ${instruction}
EOF
}
```

使用例:

```bash
prompt=$(build_codex_prompt "$title" "$summary" "$user_instruction")
echo "CALL_CODEX: $prompt"
```

### output_success()

成功時の JSON を出力します。

定義:

```bash
# 成功時 JSON 出力
# 引数: $1 - summary
# 出力: JSON 形式
# 終了コード: 0
output_success() {
  local summary="$1"
  jq -n --arg s "$summary" '{"result": "success", "summary": $s}'
}
```

使用例:

```bash
output_success "$summary"
```

### output_cancel()

キャンセル時の JSON を出力します。

定義:

```bash
# キャンセル時 JSON 出力
# 出力: JSON 形式
# 終了コード: 0
output_cancel() {
  echo '{"cancel": true}'
}
```

使用例:

```bash
output_cancel
```

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
