---
# Claude Code 必須要素
allowed-tools:
  - Bash(jq:*)
  - Bash(awk:*)
  - Bash(grep:*)
  - Bash(sed:*)
  - mcp__codex-mcp__codex

argument-hint: title [summary]
description: title (と summary) から commit種別、issue種別、branch種別を判定。summary なしの場合はタイトルプレフィックスから高速判定

# 設定変数
config:
  commitlint_config: configs/commitlint.config.js

# プロジェクト要素
title: _get-issue-types
version: 0.6.0
created: 2025-10-19
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-20: すべてAI判定に変更、柔軟性を優先（高速パス削除）
  - 2025-10-20: summary をオプション化、タイトルプレフィックスから高速判定機能を追加
  - 2025-10-19: 初版作成、issue-generator.md のロジックを抽出
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## _get-issue-types : Overview

title と summary から commit種別、issue種別、branch種別を AI判定で取得する汎用ヘルパー。
`issue-generator.md` のAI判定ロジックを抽出し、他のコマンドから再利用可能にしたもの。

### ワークフロー

1. title と summary を引数として受け取る
2. commitlint.config.js から commit種別を動的抽出
3. issue種別定義テーブルを生成
4. AI判定プロンプトを構築
5. Codex に送信して AI判定を実行
6. JSON 形式で結果を返す

### 主要機能

- **commit種別動的抽出**: `configs/commitlint.config.js` から14種類を動的取得
- **issue種別テーブル生成**: 6種類のissue種別を定義
- **Codex AI判定**: title/summaryを深層分析して種別を決定
- **JSON出力**: 判定結果を構造化されたJSON形式で返す

## 入出力仕様

### 入力パラメータ

引数として title と summary を受け取ります:

```bash
# AI判定モード (summary あり)
/_helpers:_get-issue-types "ユーザー認証機能を追加したい" "メール+パスワードでログインできるようにしたい"

# 高速モード (summary なし、タイトルプレフィックスから判定)
/_helpers:_get-issue-types "[Enhancement]既存機能を改善" ""
```

- `title`: タイトル (必須)
- `summary`: サマリー (オプション、空文字列の場合はタイトルから判定)

### 出力形式

#### 成功時

```json
{
  "commit_type": "feat",
  "issue_type": "feature",
  "branch_type": "feat",
  "reasoning": "新機能追加要求のためcommit種別feat、issue種別feature、branch種別はcommit種別優先でfeat"
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
- `"commit types extraction failed"`: commit種別の抽出に失敗
- `"ai judgment failed"`: AI判定に失敗

## 使用例

### タイトルのみでAI判定 (GitHub Issueロード時)

```bash
/_helpers:_get-issue-types "[Enhancement]Claudeのカスタムスラッシュコマンドとエージェントを再構成" ""
```

出力:

```json
{
  "commit_type": "refactor",
  "issue_type": "enhancement",
  "branch_type": "enhancement",
  "reasoning": "タイトルプレフィックス [Enhancement] と内容から、既存機能の再構成による改善と判定"
}
```

### タイトル+サマリーでAI判定 (Issue作成時)

```bash
/_helpers:_get-issue-types "ログ出力機能を追加" "デバッグ用にコンソールログを出力できるようにしたい"
```

出力:

```json
{
  "commit_type": "feat",
  "issue_type": "feature",
  "branch_type": "feat",
  "reasoning": "デバッグ用のログ出力機能を新規追加するため、commit種別feat、issue種別feature、branch種別はcommit種別優先でfeat"
}
```

### ドキュメント改善の例

```bash
/_helpers:_get-issue-types "READMEを改善する" "インストール手順をより詳しく説明したい"
```

出力:

```json
{
  "commit_type": "docs",
  "issue_type": "enhancement",
  "branch_type": "enhancement",
  "reasoning": "ドキュメント更新だがREADMEの改善提案であるため、commit種別docs、issue種別enhancement、相応しさ判定でbranch種別enhancement"
}
```

### エラー例 (タイトル未指定)

```bash
/_helpers:_get-issue-types "" ""
```

出力 (stderr):

```json
{
  "result": "error",
  "reason": "no title"
}
```

## 実装詳細

このヘルパーは bash スクリプトと Codex の協調処理で動作します。

### アルゴリズム

```text
[開始]
  ↓
[引数パース] → title, summary
  ↓
[title検証] → 空ならエラー終了
  ↓
[commit種別抽出] → extract_commit_types()
  ↓
[issue種別テーブル生成] → build_issue_types_table()
  ↓
[AI判定プロンプト構築] → build_ai_judgment_prompt()
  ├─ summary あり: タイトル+サマリーで判定
  └─ summary なし: タイトルのみで判定
  ↓
[Codex AI判定] → Claude が実行
  ↓
[JSON出力] → commit_type, issue_type, branch_type, reasoning
  ↓
[終了]
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

# title 検証
[[ -z "$title" ]] && output_error "no title"
```

title が指定されていることを確認します。summary はオプションです。
summary が空の場合もStep 3以降のAI判定処理に進みます。

#### Step 3: commit種別抽出

```bash
# commit種別抽出
commit_types_table=$(extract_commit_types)

# 抽出失敗チェック
[[ -z "$commit_types_table" ]] && output_error "commit types extraction failed"
```

`configs/commitlint.config.js` から commit種別を動的抽出します。

#### Step 4: issue種別テーブル生成

```bash
# issue種別テーブル生成
issue_types_table=$(build_issue_types_table)
```

6種類のissue種別定義をJSON配列として生成します。

#### Step 5: AI判定プロンプト構築

```bash
# AI判定プロンプト構築
prompt=$(build_ai_judgment_prompt "$title" "$summary" "$commit_types_table" "$issue_types_table")

# Claude に渡すシグナル
echo "CALL_AI_JUDGMENT: $prompt"
```

プロンプトを構築し、Claude に AI判定を依頼します。

#### Step 6: Codex AI判定

Claude が Codex を使用して AI判定を実行します:

1. `echo "CALL_AI_JUDGMENT: ..."` を検出
2. `mcp__codex-mcp__codex` ツールでプロンプトを送信
3. JSON レスポンスを受け取る
4. JSON を stdout に出力

## Claude への実装指示

このコマンドを実行する Claude は、以下の処理を厳守してください:

### 処理フロー

1. **bash スクリプト実行**: title と summary の検証、テーブル生成、プロンプト構築
2. **`CALL_AI_JUDGMENT` 検出**: bash から `CALL_AI_JUDGMENT: <prompt>` を受け取る
3. **Codex 呼び出し**: `mcp__codex-mcp__codex` でプロンプトを送信
4. **JSON 出力**: Codex からの JSON レスポンスをそのまま出力

### 実装例

```bash
# Step 1-5: 引数検証、テーブル生成、プロンプト構築

# Step 6: AI判定呼び出しシグナル
echo "CALL_AI_JUDGMENT: $prompt"
```

Claude が検出したら Codex を呼び出します:

```bash
# Claude が mcp__codex-mcp__codex ツールで実行
# レスポンス例:
# {
#   "commit_type": "feat",
#   "issue_type": "feature",
#   "branch_type": "feat",
#   "reasoning": "..."
# }
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
[[ -z "$commit_types_table" ]] && output_error "commit types extraction failed"
```

### extract_commit_types()

commitlint.config.js から commit種別を抽出します。

定義:

```bash
##
# @brief Extract commit types from commitlint config
# @description Parses configs/commitlint.config.js and extracts commit type definitions as JSON array
#
# @given commitlint.config.js にcommit種別定義が存在する
# @when extract_commit_types() を呼び出す
# @then JSON配列 [{"type":"feat","description":"..."},...]を標準出力に返す
#
# @param $1 Config file path (default: configs/commitlint.config.js)
# @return 0 on success, 1 on file not found
# @stdout JSON array: [{"type":"feat","description":"New feature"},...]
# @example
#   commit_types_table=$(extract_commit_types)
#   echo "$commit_types_table" | jq '.[0].type'
##
extract_commit_types() {
  local config_file="${1:-configs/commitlint.config.js}"

  [[ ! -f "$config_file" ]] && return 1

  awk '/type-enum.*\[/,/\]\]/' "$config_file" \
    | grep -E "^\s*'[a-z]+'" \
    | sed -E "s/\s*'([a-z]+)',?\s*\/\/\s*(.*)/{\n  \"type\": \"\1\",\n  \"description\": \"\2\"\n},/" \
    | sed '$ s/,$//' \
    | sed '1 i[' \
    | sed '$ a]' \
    | jq -c '.'
}
```

使用例:

```bash
commit_types_table=$(extract_commit_types)
echo "$commit_types_table" | jq -r '.[].type'
```

### build_issue_types_table()

issue種別定義テーブルを生成します。

定義:

```bash
##
# @brief Build issue types definition table
# @description Creates a JSON array of issue type definitions with template mappings
#
# @given 6種類のissue種別定義 (feature/bug/enhancement/task/release/question)
# @when build_issue_types_table() を呼び出す
# @then JSON配列 [{"type":"...","description":"...","template":"..."},...]を標準出力に返す
#
# @return 0 on success
# @stdout JSON array: [{"type":"feature","description":"新機能追加要求","template":"feature_request.yml"},...]
# @example
#   issue_types_table=$(build_issue_types_table)
#   echo "$issue_types_table" | jq -r '.[].type'
##
build_issue_types_table() {
  jq -n -c '[
    {
      "type": "feature",
      "description": "新機能追加要求",
      "template": "feature_request.yml"
    },
    {
      "type": "bug",
      "description": "バグレポート",
      "template": "bug_report.yml"
    },
    {
      "type": "enhancement",
      "description": "既存機能改善",
      "template": "enhancement.yml"
    },
    {
      "type": "task",
      "description": "開発・メンテナンスタスク",
      "template": "task.yml"
    },
    {
      "type": "release",
      "description": "リリース関連",
      "template": "release.yml"
    },
    {
      "type": "open_topic",
      "description": "オープントピック",
      "template": "open_topic.yml"
    }
  ]'
}
```

使用例:

```bash
issue_types_table=$(build_issue_types_table)
echo "$issue_types_table" | jq -r '.[].description'
```

### build_ai_judgment_prompt()

AI判定用プロンプトを構築します。

定義:

```bash
##
# @brief Build AI judgment prompt for Codex
# @description Constructs a prompt for LLM to judge commit type, issue type, and branch type
#
# @given タイトル、サマリー、commit種別テーブル、issue種別テーブルが与えられる
# @when build_ai_judgment_prompt() を呼び出す
# @then AI判定用のプロンプトテキストを標準出力に返す
#
# @param $1 Issue title
# @param $2 Issue summary
# @param $3 Commit types JSON array
# @param $4 Issue types JSON array
# @return 0 on success
# @stdout Prompt text for AI judgment
# @example
#   prompt=$(build_ai_judgment_prompt "タイトル" "サマリー" "$commit_types_table" "$issue_types_table")
##
build_ai_judgment_prompt() {
  local title="$1"
  local summary="$2"
  local commit_types_table="$3"
  local issue_types_table="$4"

  cat <<EOF
以下の情報から、最適なcommit種別、issue種別、branch種別を判定してJSON形式で返してください。

【コミット種別定義】
${commit_types_table}

【Issue種別定義】
${issue_types_table}

【入力】
- タイトル: "${title}"
- サマリー: "${summary}"

【判定ルール】
1. サマリーの内容を深く分析してcommit種別を判定 (第一優先)
   - 「何を」作成・修正するかを重視
   - 例: "ドキュメント作成" → docs、"機能追加" → feat
2. サマリーの内容からissue種別を判定 (第二優先)
   - バグ報告、機能追加、改善提案、タスクのいずれか
3. branch種別決定:
   - 基本: commit種別を採用
   - 相応しさ判定で切り替え:
     * docs + 改善文脈 → enhancement
     * test + bug文脈 → bug
     * refactor + enhancement文脈 → enhancement

【出力形式】
必ずJSON形式で返してください:
{
  "commit_type": "選択したcommit種別",
  "issue_type": "選択したissue種別",
  "branch_type": "最終決定したbranch種別",
  "reasoning": "判定理由の簡潔な説明 (日本語)"
}
EOF
}
```

使用例:

```bash
prompt=$(build_ai_judgment_prompt "$title" "$summary" "$commit_types_table" "$issue_types_table")
echo "$prompt"
```

## AI判定の詳細

### 判定ルール

1. **サマリー深層分析**: 「何を」作成・修正するかを重視し、文脈から真の目的を理解
2. **commit種別優先**: 第一優先でcommit種別を決定 (コミット履歴の一貫性維持)
3. **issue種別補助**: 第二優先でissue種別を決定 (Issue管理の観点)
4. **branch種別決定**: 基本はcommit種別を採用、相応しさ判定で切り替え

### AI判定の利点

- **文脈理解**: キーワードマッチングを超えた意味理解
- **柔軟性**: 新しい表現パターンにも自動対応
- **透明性**: reasoning フィールドで判定根拠を明示
- **動的適応**: テーブル定義変更に自動追従

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
