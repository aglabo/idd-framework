---
# Claude Code 必須要素
allowed-tools:
  - AskUserQuestion(*)
  - SlashCommand(/_helpers:_get-summary)
  - SlashCommand(/_helpers:_get-issue-types)
  - Task(issue-generator)
  - Bash(mkdir:*, jq:*)
  - Write(temp/idd/issues/**)
argument-hint: [title]
description: 新しくIssueを作成する

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session

# ag-logger プロジェクト要素
title: /idd:issue:new
version: 0.6.0
created: 2025-10-16
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-19: セッション管理機能を追加 (idd-session.lib.sh 使用)
  - 2025-10-19: issue-generator エージェントによる下書き生成機能を追加
  - 2025-10-19: /_helpers/_get-issue-types 統合で種別判定機能を追加
  - 2025-10-18: AskUserQuestion ツールを使った対話的実装に変更
  - 2025-10-16: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd:issue:new - 新しいIssue作成

ユーザーから Issue のタイトルを取得し、確認ループを行います。

## 初期設定

コマンド実行の最初に、以下の初期設定を行います:

```bash
#!/bin/bash
set -euo pipefail

# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/filename-utils.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"

# Issue-specific environment setup
setup_repo_env
ISSUES_DIR=$(get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
```

この初期設定により:

- `set -euo pipefail`: エラー時の即座終了、未定義変数の検出、パイプラインエラーの伝播
- リポジトリルートを動的に取得し、ライブラリパスを構築
- 必要なライブラリを事前に読み込み、全ステップで利用可能に
- Issue管理用のディレクトリとセッションファイルのパスを設定

## 処理フロー

このコマンドは以下のステップを**自動的に連続実行**します:

1. **タイトル取得**
   - 引数でタイトルが渡された場合: それを初期値として使用
   - 引数がない場合: ユーザーに「Issue タイトルを入力してください」と質問

2. **タイトル確認ループ**
   - 取得したタイトルを表示: `入力されたタイトル: {title}`
   - AskUserQuestion ツールで確認:
     - 質問: "このタイトルでよろしいですか?"
     - 選択肢:
       - "はい (確定)" → 次のステップへ
       - "キャンセル" → 処理を中止
       - "Other" → カスタム入力で新しいタイトルを入力

3. **サマリー取得**
   - `/_helpers:_get-summary "$title"` を呼び出し (summary は空で渡す)
   - `_get-summary` が自動生成・対話的編集を実行
   - 出力 JSON を変数 `ret` に格納
   - **→ 自動的にステップ4へ進む**

4. **結果処理と種別判定への自動遷移**
   - キャンセル判定: `ret` に `"cancel": true` があれば中止
   - summary 抽出: `jq` で JSON から summary を取得
   - 確定メッセージを表示: `✓ 確定したタイトル: {title}` と `✓ 確定したサマリー: {summary}`
   - **→ 自動的にステップ5へ進む**

5. **種別判定と下書き生成への自動遷移**
   - `/_helpers:_get-issue-types "$title" "$summary"` を呼び出し
   - AI判定で commit種別、issue種別、branch種別を取得
   - 出力 JSON を変数 `types` に格納
   - 各種別を抽出して表示
   - **→ 自動的にステップ6へ進む**

6. **下書き生成**
   - issue-generator エージェントを呼び出し
   - JSON入力: `{"title": "$title", "issue_type": "$issue_type", "summary": "$summary"}`
   - Markdown形式の下書きを取得
   - `temp/idd/issues/` ディレクトリに保存
   - ファイル名: `{issue番号}-{YYYYMMDD-HHMMSS}-{issue_type}-{slug}.md`
   - slugはタイトルを英訳し、それを小文字で繋ぐ(12文字まで)
   - issue番号: 新規作成時は `new` (GitHub Issue作成後に実際の番号に更新)
   - 例: `new-20251016-151030-enhancement-claude-mcp-integration.md`
   - 保存完了メッセージを表示

7. **セッション保存**
   - `.last.session` ファイルに作成情報を保存
   - 保存内容: `filename`, `title`, `issue_type`, `commit_type`, `branch_type`, `command`
   - `.last_draft` ファイルに最終ファイル名を保存
   - 次回コマンド実行時に両方から参照可能

## 実装指示

### Step.1 セッション環境の初期化

初期設定で定義された環境変数を使用して、必要なコマンドの存在を確認し、セッションディレクトリを作成します:

```bash
# jq コマンド存在チェック
if ! command -v jq > /dev/null 2>&1; then
  error_print <<EOF
❌ Error: 'jq' command not found.
This command requires 'jq' for JSON parsing.

Please install jq before running this script.
  macOS:  brew install jq
  Ubuntu: sudo apt-get install jq
  Windows: scoop install jq
EOF
  exit 1
fi

# セッションディレクトリ作成
mkdir -p "$ISSUES_DIR"
```

### Step.2 タイトル取得

引数 `$1` が渡されているか確認してください：

- 引数あり: `$1` を初期タイトルとして使用
- 引数なし: ユーザーにタイトル入力を求める（通常のテキスト応答で）

#### 確認ループ

AskUserQuestion ツールを使って以下の質問を繰り返してください：

```yaml
question: "このタイトルでよろしいですか?"
header: "確認"
options:
  - label: "はい (確定)"
    description: "このタイトルで Issue を作成します"
  - label: "キャンセル"
    description: "Issue 作成を中止します"
multiSelect: false
```

再入力したい場合は、ユーザーが "Other" (カスタム入力) で新しいタイトルを入力できます。

#### 選択による分岐

- **"はい (確定)"**: ループを抜けて次のステップへ
- **"キャンセル"**: `Issue作成を中止しました` と表示して処理終了
- **"Other" (カスタム入力)**: 入力されたテキストを新しいタイトルとして使用し、再度確認ループ

### Step.3 サマリー取得

タイトル確定後、`/_helpers:_get-summary` を呼び出してサマリーを取得します:

```bash
# _get-summary を呼び出し (Claude が SlashCommand ツールで実行)
# summary は空文字列で渡す (_get-summary が自動生成する)
ret=$(/_helpers:_get-summary "$title" "")
```

`_get-summary` は以下を実行します:

1. summary が空なので codex-mcp で自動生成
2. `_edit-summary` で対話的編集
3. JSON 形式で結果を返す

#### 結果処理とフロー連携

`ret` に格納された JSON を処理し、自動的に次のステップへ進みます:

```bash
# キャンセル判定
if echo "$ret" | jq -e '.cancel' > /dev/null 2>&1; then
  cat <<EOF
Issue作成を中止しました
EOF
  exit_code=0
  exit $exit_code
fi

# summary 抽出
summary=$(echo "$ret" | jq -r '.summary')

# 確定メッセージを表示
cat <<EOF

✓ 確定したタイトル: $title
✓ 確定したサマリー: $summary

[Step.4] 種別判定を実行中
EOF
```

### Step.4 種別判定

タイトルとサマリーが確定したら、`/_helpers:_get-issue-types` を呼び出して種別を判定します:

```bash
# _get-issue-types を呼び出し (Claude が SlashCommand ツールで実行)
types=$(/_helpers:_get-issue-types "$title" "$summary")
```

`_get-issue-types` は以下を実行します:

1. commitlint.config.js から commit種別を動的抽出
2. issue種別テーブルを生成
3. codex-mcp で AI判定を実行
4. JSON 形式で結果を返す

### Step.5 種別結果処理とフロー連携

`types` に格納された JSON から各種別を抽出し、自動的に下書き生成へ進みます:

```bash
# エラー判定
if echo "$types" | jq -e '.result == "error"' > /dev/null 2>&1; then
  reason=$(echo "$types" | jq -r '.reason')
  cat <<EOF
エラー: 種別判定に失敗しました ($reason)
EOF
  exit_code=1
  exit $exit_code
fi

# 各種別を抽出
commit_type=$(echo "$types" | jq -r '.commit_type')
issue_type=$(echo "$types" | jq -r '.issue_type')
branch_type=$(echo "$types" | jq -r '.branch_type')
reasoning=$(echo "$types" | jq -r '.reasoning')

# 判定結果を表示
cat <<EOF

[Step.5] AI判定結果
コミット種別: $commit_type
Issue種別: $issue_type
ブランチ種別: $branch_type
判定理由: $reasoning

[Step.6] 下書き生成を実行中
EOF
```

### Step.6 下書き生成

タイトル、サマリー、種別が確定したら、issue-generator エージェントを呼び出して下書きを生成します。

#### ファイル名生成

```bash
# ファイル名を生成 (new-{timestamp}-{issue_type}-{slug}.md)
filepath=$(generate_issue_filepath "$title" "$issue_type")
cat <<EOF

下書きファイル: $filepath
EOF
```

#### エージェント呼び出し

```bash
# issue-generator エージェントを呼び出す (Claude が Task ツールで実行)
# JSON入力を構築
input_json=$(jq -n \
  --arg title "$title" \
  --arg issue_type "$issue_type" \
  --arg summary "$summary" \
  '{title: $title, issue_type: $issue_type, summary: $summary}')

cat <<EOF
下書きを生成中...
CALL_AGENT_ISSUE_GENERATOR: $input_json
EOF
```

Claude が検出したら Task ツールで issue-generator エージェントを実行します:

```bash
# Claude が Task ツールで実行
# Task(subagent_type="issue-generator", prompt="<input_json>")
# レスポンス: Markdown形式の下書き
```

#### 下書き保存

```bash
# エージェントからの下書きを取得 (Claude が実行)
read -r draft

# ディレクトリ作成
mkdir -p "$(dirname "$filepath")"

# ファイル保存 (Claude が Write ツールで実行)
# Write(file_path="$filepath", content="$draft")

# 完了メッセージ
cat <<EOF

✓ Issue下書きを作成しました
  ファイル: $filepath

EOF
```

### Step.7 セッション保存

下書き作成後、セッション情報とファイル名の両方を保存します:

```bash
# ファイル名を抽出
filename=$(basename "$filepath")

# 1. セッション情報を保存 (.last.session)
save_issue_session "$filename" "" "$title" "$issue_type" "new" ""

# 2. 最終ファイル名を保存 (.last_draft)
_save_last_file "$ISSUES_DIR" "$filename"

cat <<EOF
✓ セッション情報を保存しました

EOF
```

## See Also

- `/idd-issue`: IDD Issue 管理システムのメインコマンド
- `/_helpers/_get-summary`: タイトルとサマリーの検証・編集ヘルパー
- `/_helpers/_get-issue-types`: commit/issue/branch種別のAI判定ヘルパー
- `issue-generator`: Issue下書き生成エージェント
- `.claude/commands/_libs/filename-utils.lib.sh`: ファイル名生成ユーティリティ
- `.claude/commands/_libs/idd-session.lib.sh`: セッション管理ライブラリ

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
