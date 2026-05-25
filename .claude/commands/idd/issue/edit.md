---
# Claude Code 必須要素
allowed-tools:
  - AskUserQuestion(*)
  - Read(temp/idd/issues/**)
  - Edit(temp/idd/issues/**)
  - Bash(cat:*, sed:*, head:*, source:*, git:*)
  - mcp__serena-mcp__*
  - mcp__lsmcp__*
argument-hint: (no arguments)
description: 選択済みIssueドラフトを対話的に編集する

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  libs_dir: .claude/commands/_libs

# ag-logger プロジェクト要素
title: idd-issue-edit
version: 0.6.0
created: 2025-10-20
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-20: 初版作成 - セッションから選択済みIssueの対話的編集機能を実装
  - 2025-10-20: メインブロック再設計、Claude実装ガイド追加、対話ループをClaude主導に変更
  - 2025-10-20: Claude命令を明示化、Issue本文表示を確実にするため必須アクション追加
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd-issue edit

セッションに保存されている選択済み Issue ドラフトを対話的に編集するサブコマンドです。

## 概要

このコマンドは以下の処理を実行します:

1. **セッションから Issue 取得**: `.last.session` から選択済み Issue を取得
2. **検証**: Issue ファイルの存在を確認
3. **一時ファイル作成**: 編集用の `.tmp` ファイルを作成
4. **Claude への制御委譲**: Claude が以下を実装
   - Issue 内容の読み込みと表示
   - AskUserQuestion による対話ループ
   - Edit ツールによる一時ファイルの編集
   - 承認後の確定処理 (一時ファイルを元のファイルに上書き)

## Bash 初期設定

各サブコマンドは `.claude/commands/_libs/` のヘルパー関数を使用します。
詳細は `.claude/commands/_helpers/README.md` を参照。

```bash
#!/bin/bash
# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/io-utils.lib.sh"
. "$LIBS_DIR/idd-env.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"

# Issue-specific environment setup
setup_repo_env
ISSUES_DIR=$(get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
```

## メインブロック

```bash
#!/bin/bash
# Main execution flow
issue_file=$(get_selected_issue) || exit 1
validate_issue_file "$issue_file" || exit 1

# 一時ファイルを作成
create_temp_file "$issue_file" || exit 1

# Claude に制御を委譲
echo ""
echo "Selected Issue: $issue_file"
echo "Temporary file: ${issue_file}.tmp"
echo ""
echo "=== CLAUDE INSTRUCTIONS ==="
echo "1. IMMEDIATELY read the temporary file: temp/idd/issues/${issue_file}.tmp"
echo "2. Display the full Issue content to the user"
echo "3. Start the interactive edit loop (see Claude Implementation Guide below)"
echo "=========================="
```

**重要**: Claude はこの出力を受け取った直後に、必ず以下を実行してください:

1. **Read ツールで一時ファイルを読み込む** (`temp/idd/issues/{ISSUE_FILE}.tmp`)
2. Issue の全文をユーザーに表示する
3. 対話編集ループを開始する (詳細は「Claude 実装ガイド」セクション参照)

## Claude 実装ガイド

### 必須アクション

Claude は Bash 出力の `CLAUDE INSTRUCTIONS` を受け取った直後に、**以下を順番に実行**してください:

**Action 1: Issue 内容を読み込んで表示**

```
ISSUE_FILE を Bash 出力から取得 (例: "29-251020-101304-enhancement-edit-rework")

Read(temp/idd/issues/{ISSUE_FILE}.tmp)

ユーザーに表示:
  Selected Issue: {ISSUE_FILE}

  --- Issue Content ---
  {Read ツールで取得した全文}
```

**Action 2: 対話編集ループ**

```
while (true):
  AskUserQuestion(
    question: "このIssueを編集しますか?",
    options: [
      "Yes" - 編集完了、承認して終了
      "Cancel" - 編集をキャンセル
      (Other - 自動追加)
    ]
  )

  if "Yes":
    commit_changes() を Bash で実行
    "✓ 編集が完了しました" を表示
    終了

  if "Cancel":
    cleanup_temp_file() を Bash で実行
    "編集をキャンセルしました" を表示
    終了

  if "Other" (編集指示):
    Edit(temp/idd/issues/{ISSUE_FILE}.tmp) で修正
    Read(temp/idd/issues/{ISSUE_FILE}.tmp) で再表示
    ループ継続
```

### Bash 関数呼び出し方法

`commit_changes` と `cleanup_temp_file` を呼び出す際の Bash コマンド:

```bash
# commit_changes の呼び出し
Bash(source .claude/commands/_libs/io-utils.lib.sh && source .claude/commands/_libs/idd-env.lib.sh && setup_repo_env && ISSUES_DIR=$(get_temp_dir "idd/issues") && commit_changes "{ISSUE_FILE}")

# cleanup_temp_file の呼び出し
Bash(source .claude/commands/_libs/io-utils.lib.sh && source .claude/commands/_libs/idd-env.lib.sh && setup_repo_env && ISSUES_DIR=$(get_temp_dir "idd/issues") && cleanup_temp_file "{ISSUE_FILE}")
```

注意: 環境変数 `ISSUES_DIR` の設定が必要なため、ライブラリを source してから呼び出します。

## 依存関係

### ヘルパーライブラリ

- `io-utils.lib.sh`: エラー出力 (`error_print`)
- `idd-env.lib.sh`: リポジトリ環境設定 (`setup_repo_env`, `get_temp_dir`)
- `idd-session.lib.sh`: セッション管理 (`_load_last_file`)

詳細は `.claude/commands/_helpers/README.md` を参照してください。

## 使用例

### 基本的な使用方法

```bash
# 1. まず Issue を選択
/idd:issue:list

# 2. 選択した Issue を編集
/idd:issue:edit
```

**出力例:**

```text
EDIT_MODE: interactive
ISSUE_FILE: 29-251020-101304-enhancement-edit-rework
TEMP_FILE: 29-251020-101304-enhancement-edit-rework.tmp

Selected Issue: 29-251020-101304-enhancement-edit-rework
Title: [Enhancement] editコマンドの再構成

--- Issue Content ---
(一時ファイルの全文が Read ツールで表示される)

このIssueを編集しますか?
□ Yes: 編集完了。このIssueで問題なければ承認して終了します
□ Cancel: 編集をキャンセルして一時ファイルを削除します
□ Other: (カスタム入力)
```

### 編集フロー

**ケース 1: 編集指示を出して修正**

```text
選択: Other
入力: "タイトルをもっと具体的にして、目的を明確にしてください"

(Claude が Edit ツールで一時ファイルを編集)

Selected Issue: 29-251020-101304-enhancement-edit-rework
Title: [Enhancement] /idd:issue:edit コマンドの対話編集フロー改善

--- Issue Content ---
(修正後の内容が Read ツールで再度表示される)

このIssueを編集しますか?
□ Yes: 編集完了。このIssueで問題なければ承認して終了します
□ Cancel: 編集をキャンセルして一時ファイルを削除します
□ Other: (カスタム入力)

選択: Yes

✓ 編集が完了しました
```

**ケース 2: 即座に承認**

```text
このIssueを編集しますか?
選択: Yes

✓ 編集が完了しました
```

**ケース 3: キャンセル**

```text
このIssueを編集しますか?
選択: Cancel

編集をキャンセルしました
(一時ファイルは削除され、元のファイルは変更されていません)
```

## Bash 関数ライブラリ

```bash
# ============================================================
# セッション管理関数
# ============================================================

# .last_draft から選択済み Issue を取得
# 戻り値: 標準出力に Issue ファイル名、未選択時は exit 1
get_selected_issue() {
  local issue_file
  issue_file=$(_load_last_file "$ISSUES_DIR" "")

  if [ -z "$issue_file" ]; then
    error_print "No issue selected. Run: /idd:issue:list"
    return 1
  fi

  echo "$issue_file"
  return 0
}

# ============================================================
# 検証関数
# ============================================================

# Issue ファイルの存在を確認
# 引数: $1 - Issue ファイル名 (拡張子なし)
# 戻り値: 0=存在, 1=不在 (エラーメッセージ表示)
validate_issue_file() {
  local issue_file="$1"
  local full_path="$ISSUES_DIR/${issue_file}.md"

  if [ ! -f "$full_path" ]; then
    error_print <<EOF
Issue file not found: ${issue_file}.md
Run: /idd:issue:list
EOF
    return 1
  fi

  return 0
}

# ============================================================
# 一時ファイル管理関数
# ============================================================

# 一時ファイルを作成
# 引数: $1 - Issue ファイル名 (拡張子なし)
# 戻り値: 0=成功, 1=失敗
create_temp_file() {
  local issue_file="$1"
  local source="$ISSUES_DIR/${issue_file}.md"
  local temp="$ISSUES_DIR/${issue_file}.tmp"

  cp "$source" "$temp" || {
    error_print "一時ファイルの作成に失敗しました"
    return 1
  }

  echo "一時ファイルを作成しました: ${issue_file}.tmp"
  return 0
}

# 一時ファイルを削除
# 引数: $1 - Issue ファイル名 (拡張子なし)
cleanup_temp_file() {
  local issue_file="$1"
  local temp="$ISSUES_DIR/${issue_file}.tmp"

  if [ -f "$temp" ]; then
    rm "$temp"
  fi
}

# 一時ファイルを確定 (元のファイルに上書き)
# 引数: $1 - Issue ファイル名 (拡張子なし)
# 戻り値: 0=成功, 1=失敗
commit_changes() {
  local issue_file="$1"
  local temp="$ISSUES_DIR/${issue_file}.tmp"
  local target="$ISSUES_DIR/${issue_file}.md"

  mv "$temp" "$target" || {
    error_print "ファイルの更新に失敗しました"
    return 1
  }

  return 0
}

```

---

## See Also

- `/idd:issue:list`: Issue 一覧から選択
- `/idd:issue:view`: Issue 表示
- `/idd:issue:push`: GitHub に Issue をプッシュ (未実装)

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
