---
# Claude Code 必須要素
allowed-tools:
  - mcp__codex-mcp__codex
  - Bash(jq:*)
  - SlashCommand(/_helpers:_edit-summary:*)

argument-hint: title [summary]
description: validate and format title and summary (auto-generate if summary omitted, then allow interactive editing)

# 設定変数
config:
  libs_dir: .claude/commands/_libs

# プロジェクト要素
title: get-summary
version: 0.6.0
created: 2025-10-18
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-18: 初版作成 - summary 生成機能実装
  - 2025-10-18: _edit-summary 統合による対話的編集機能を追加
  - 2025-10-18: トップダウン構造に再構成、関数ライブラリを最後にまとめる
  - 2025-10-18: process_edit_result() 関数を追加し、編集結果処理を関数化
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## _get-summary : Overview

カスタムスラッシュコマンドから呼び出されて、title と summary を受け取り、検証・整形します。
summary が省略された場合は codex-mcp で自動生成し、`_edit-summary` で対話的に編集します。
最終的に検証済みの内容を JSON 形式で出力します。

### ワークフロー

1. title と summary (省略可能) を引数として受け取る
2. title を検証 (必須)
3. summary が空なら codex-mcp で自動生成
4. `/_helpers:_edit-summary` を呼び出して対話的編集
5. 編集結果を JSON で受け取る
6. キャンセル時は `{"cancel": true}` を出力
7. 成功時は `{"result": "success", "title": "...", "summary": "..."}` を出力

### 主要機能

- title の検証 (必須)
- summary の自動生成 (省略時)
- summary の対話的編集 (`_edit-summary` 統合)
- キャンセル処理のサポート
- JSON 形式での出力

## 入出力仕様

### 入力パラメータ

引数として title と summary を受け取ります。summary は省略可能です:

```bash
# summary を指定する場合
/_helpers:_get-summary "新機能の追加" "ユーザー認証機能を実装"

# summary を省略する場合 (自動生成)
/_helpers:_get-summary "新機能の追加"
```

- `title`: タイトル (必須)
- `summary`: 要約 (省略可能、省略時は自動生成)

### 出力形式

#### 成功時

```json
{
  "result": "success",
  "title": "新機能の追加",
  "summary": "ユーザー認証機能を実装"
}
```

#### キャンセル時

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
- `"summary generation failed"`: summary の自動生成に失敗
- `"edit failed"`: summary の編集処理が失敗

## 使用例

### 基本的な使用 (summary 指定 + 編集)

```bash
/_helpers:_get-summary "新機能の追加" "ユーザー認証機能を実装"
```

対話フロー:

1. `_edit-summary` が起動
2. ユーザーが summary を編集または承認
3. 編集結果を JSON で出力

出力例 (承認時):

```json
{
  "result": "success",
  "title": "新機能の追加",
  "summary": "OAuth 2.0とJWT認証を実装し、多要素認証とパスワードリセット機能を含むユーザー認証システムを追加します。"
}
```

出力例 (キャンセル時):

```json
{
  "cancel": true
}
```

### 自動生成の使用 (summary 省略 + 編集)

```bash
/_helpers:_get-summary "データベース最適化"
```

処理フロー:

1. codex-mcp で summary を自動生成
2. `_edit-summary` が起動して対話的編集
3. ユーザーが編集または承認
4. 最終結果を JSON で出力

出力例:

```json
{
  "result": "success",
  "title": "データベース最適化",
  "summary": "クエリ性能を改善し、インデックス最適化とキャッシュ戦略を導入してレスポンス時間を50%短縮します。接続プーリングと非同期処理により、同時実行性を向上させます。"
}
```

### キャンセル例

```bash
/_helpers:_get-summary "新機能の追加" "ユーザー認証を実装"
```

対話フロー:

1. `_edit-summary` が summary を表示
2. ユーザーが `q` を選択してキャンセル

出力:

```json
{
  "cancel": true
}
```

### エラー例 (title なし)

```bash
/_helpers:_get-summary ""
```

出力 (stderr):

```json
{
  "result": "error",
  "reason": "no title"
}
```

## 実装詳細

このヘルパーは bash スクリプト、codex-mcp、および `_edit-summary` の協調処理で動作します。

### アルゴリズム

```text
[開始]
  ↓
[引数パース] → title, summary
  ↓
[title 検証] → 空ならエラー終了
  ↓
[summary チェック]
  ├→ 空でない → [Step 4 へ]
  └→ 空 → [codex-mcp で自動生成]
        ↓
      [生成結果を summary に格納]
        ↓
      [summary が空ならエラー終了]
  ↓
[_edit-summary 呼び出し] → Claude が実行
  ↓
[編集結果を JSON で受け取る]
  ↓
[結果の分岐]
  ├→ cancel: true → キャンセル JSON 出力 → 終了
  ├→ result: success → 最終 JSON 出力 → 終了
  └→ その他 → エラー終了
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

# title 検証 (必須)
[[ -z "$title" ]] && output_error "no title"
```

引数から `title` と `summary` を取得します。`title` のみ必須として検証します。

#### Step 3: summary の自動生成 (省略時)

summary が空の場合、codex-mcp を使用して自動生成します。

```bash
# summary が空なら自動生成
if [[ -z "$summary" ]]; then
  # プロンプト準備
  prompt="以下のタイトルに対して、100-150文字程度の技術的な説明を日本語で生成してください。

要件:
- 簡潔で技術的な表現
- 主要な機能や利点を含める
- 100-150文字程度
- 日本語で記述

生成した説明のみを出力してください。
---

タイトル: ${title}"

  # codex-mcp で生成 (Claude が実行)
  echo "$prompt"
fi
```

処理の詳細:

1. summary が空かチェック
2. 空の場合、プロンプトテンプレートを作成し `${title}` を埋め込む
3. プロンプトを stdout に出力
4. Claude が `mcp__codex-mcp__codex` ツールでプロンプトを処理
5. 生成結果を summary に格納

```bash
# summary 取得 (Claude からの入力を想定、summary が空の場合のみ)
if [[ -z "$summary" ]]; then
  read -r summary

  # summary が空ならエラー
  [[ -z "$summary" ]] && output_error "summary generation failed"
fi
```

#### Step 4: _edit-summary の呼び出し

summary の生成または取得が完了したら、`_edit-summary` を呼び出して対話的編集を行います。

```bash
# _edit-summary を呼び出す (Claude が実行)
echo "CALL_EDIT_SUMMARY: $title|$summary"
```

Claude は以下のように処理します:

1. `/_helpers:_edit-summary "$title" "$summary"` を実行
2. 対話的編集フローを開始
3. 編集結果を JSON で取得

#### Step 5: 編集結果の処理

`process_edit_result()` 関数で編集結果を処理します。

```bash
# _edit-summary の呼び出しと結果処理
process_edit_result "$title" "$summary"
```

この関数は以下の処理を行います:

1. Claude が `/_helpers:_edit-summary` を SlashCommand ツールで実行
2. 編集結果を `edit_result` 変数に格納
3. 結果を分岐処理:
   - `{"cancel": true}` → キャンセル JSON を出力して終了
   - `{"result": "success", "summary": "..."}` → 編集済み summary を抽出し最終 JSON を出力
   - その他 → `output_error("edit failed")` を呼び出す

詳細は「関数ライブラリ」セクションの `process_edit_result()` を参照してください。

## Claude への実装指示

このコマンドを実行する Claude は、以下の処理を厳守してください:

### 処理フロー

1. **bash スクリプト実行**: title と summary の検証、必要に応じて自動生成
2. **`CALL_EDIT_SUMMARY` 検出**: bash から `CALL_EDIT_SUMMARY: title|summary` を受け取る
3. **`_edit-summary` 呼び出し**: `/_helpers:_edit-summary "$title" "$summary"` を実行
4. **編集結果の取得**: JSON レスポンスを受け取る
5. **結果の処理**:
   - `{"cancel": true}` → そのまま出力して終了
   - `{"result": "success", "summary": "..."}` → title と編集済み summary で最終 JSON を出力
   - `{"result": "error", ...}` → エラー処理

### 実装例

```bash
# Step 1-3: title 検証、summary 生成/取得

# Step 4: _edit-summary 呼び出しシグナル
echo "CALL_EDIT_SUMMARY: $title|$summary"
```

Claude が検出したら `process_edit_result()` 関数を呼び出します:

```bash
# _edit-summary の呼び出しと結果処理
process_edit_result "$title" "$summary"
```

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
[[ -z "$summary" ]] && output_error "summary generation failed"
# 編集処理が失敗した場合
output_error "edit failed"
```

### process_edit_result()

`_edit-summary` を呼び出し、編集結果を処理して最終 JSON を出力します。

定義:

```bash
# _edit-summary 呼び出しと結果処理
# 引数: $1 - title, $2 - summary
# 出力: JSON 形式の結果
# 終了コード: 0 (成功またはキャンセル), 1 (エラー)
process_edit_result() {
  local title="$1"
  local summary="$2"
  local edit_result
  local edited_summary

  # NOTE: この部分は Claude が SlashCommand ツールで実行する
  # /_helpers:_edit-summary "$title" "$summary"
  # edit_result='<_edit-summary からの JSON レスポンス>'

  # キャンセル判定
  if echo "$edit_result" | jq -e '.cancel' > /dev/null 2>&1; then
    cat <<EOF
{
  "cancel": true
}
EOF
    exit 0
  fi

  # 成功判定
  if echo "$edit_result" | jq -e '.result == "success"' > /dev/null 2>&1; then
    edited_summary=$(echo "$edit_result" | jq -r '.summary')
    jq -n \
      --arg t "$title" \
      --arg s "$edited_summary" \
      '{"result": "success", "title": $t, "summary": $s}'
    exit 0
  fi

  # エラー時
  output_error "edit failed"
}
```

使用例:

```bash
# _edit-summary 呼び出しシグナル検出後
process_edit_result "$title" "$summary"
```

処理フロー:

1. `/_helpers:_edit-summary` を Claude が SlashCommand ツールで実行
2. 編集結果を `edit_result` 変数に格納 (Claude が実行)
3. キャンセル判定: `{"cancel": true}` を出力して終了
4. 成功判定: `edited_summary` を抽出し最終 JSON を出力
5. エラー時: `output_error()` を呼び出す

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
