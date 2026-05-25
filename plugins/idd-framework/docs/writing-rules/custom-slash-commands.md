---
header:
  - src: custom-slash-commands.md
  - @(#): Claude カスタムスラッシュコマンド記述ルール
title: agla-logger
description: Claude Code 向けカスタムスラッシュコマンド記述統一ルール - AI エージェント向けガイド
version: 1.0.0
created: 2025-01-15
authors:
  - atsushifx
changes:
  - 2025-10-03: 実際の /sdd, /idd-issue コマンドに合わせて全面更新 - Bash実装方式への変更
  - 2025-01-15: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

このドキュメントは、Claude Code 向けのカスタムスラッシュコマンドを記述するための統一ルールを定義します。
AI エージェントがコマンド構文を正確に理解し、一貫性のあるコマンドを作成することを目的とします。

## 統合フロントマター仕様

### 基本構成

Claude Code 公式要素と ag-logger プロジェクト要素を統合した統一フロントマター形式を使用します。

#### 標準テンプレート

```yaml
---
# Claude Code 必須要素
allowed-tools: Bash(*), Task(*)
argument-hint: [subcommand] [args]
description: [AI エージェント向けコマンド説明]

# 設定変数 (オプション)
config:
  base_dir: path/to/base
  temp_dir: temp/files
  session_file: .session

# サブコマンド定義 (オプション)
subcommands:
  init: "初期化"
  list: "一覧表示"
  view: "表示"

# ユーザー管理ヘッダー
title: command-name
version: 1.0.0
created: YYYY-MM-DD
authors:
  - atsushifx
changes:
  - YYYY-MM-DD: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

### Claude Code 必須要素

#### allowed-tools フィールド

**目的**: コマンドが使用できるツールのリスト指定。
**形式**: `[tool-name]([pattern])` 形式。

使用例:

- `Bash(*)`: すべての Bash コマンド許可
- `Task(*)`: すべての Task ツール許可
- `Read(*), Write(*)`: ファイル操作ツール許可

#### argument-hint フィールド

**目的**: スラッシュコマンドの引数ヒント表示 (自動補完機能用)。
**形式**: `[subcommand] [args]` 形式。

パターン例:

- `[subcommand] [args]`: 汎用パターン
- `init <namespace>/<module>`: 具体的引数指定
- `add [tagId] | remove [tagId] | list`: 複数選択肢

#### description フィールド

**目的**: AI エージェント向けコマンド説明。
**要件**: 日本語での簡潔な説明文 (50-100 文字程度)。

記述例:

- `Spec-Driven-Development主要コマンド - init/req/spec/task/code サブコマンドで要件定義から実装まで一貫した開発支援`
- `GitHub Issue 作成・管理システム - issue-generatorエージェントによる構造化Issue作成`

### 設定変数セクション (オプション)

#### config フィールド

**目的**: コマンド実行時に使用する設定値の定義。
**形式**: YAML オブジェクト形式。

使用例:

```yaml
config:
  base_dir: docs/.cc-sdd # 基本ディレクトリ
  temp_dir: temp/issues # 一時ファイルディレクトリ
  session_file: .lastSession # セッションファイル名
  subdirs: # サブディレクトリリスト
    - requirements
    - specifications
```

**活用方法**:

- Bash スクリプト内で環境変数として参照
- ファイルパス構築の基準値として使用
- セッション管理のファイル名指定

### サブコマンド定義セクション (オプション)

#### subcommands フィールド

**目的**: コマンドのサブコマンド一覧とその説明の定義。
**形式**: キー: 値のマッピング形式。

使用例:

```yaml
subcommands:
  init: "プロジェクト構造初期化"
  req: "要件定義フェーズ"
  new: "issue-generatorエージェントで新規Issue作成"
  list: "保存済みIssueドラフト一覧表示"
```

**活用方法**:

- ヘルプメッセージの自動生成
- サブコマンドの存在確認
- ドキュメント自動生成

### ユーザー管理ヘッダー

#### 統一要素

- title: コマンド名 (kebab-case)
- version: セマンティックバージョニング形式
- created: 初回作成日 (YYYY-MM-DD 形式)
- authors: 作成者リスト
- changes: 変更履歴
- copyright: MIT ライセンス表記

#### 要素分離ルール

必須: コメント区分により Claude Code 要素とユーザー管理要素を明確に分離。

```yaml
---
# Claude Code 必須要素
[claude-code-elements]

# 設定変数 (オプション)
[config-section]

# サブコマンド定義 (オプション)
[subcommands-section]

# ユーザー管理ヘッダー
[user-management-elements]

copyright:
  [copyright-notice]
---
```

## Bash 実装方式

### 基本実装パターン

#### サブコマンド別 Bash スクリプト構造

各サブコマンドは独立した Bash スクリプトブロックとして実装:

````markdown
### Subcommand: [subcommand-name]

```bash
#!/bin/bash
# サブコマンドの説明

# 環境設定
REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_DIR="$REPO_ROOT/[base-path]"

# 処理実行
echo "✅ 処理完了"
```
````

### 標準実装パターン

#### Pattern 1: 環境設定とセッション管理

```bash
#!/bin/bash
# 環境変数設定
setup_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  BASE_DIR="$REPO_ROOT/[base-path]"
  SESSION_FILE="$BASE_DIR/.session"
}

# セッション保存
save_session() {
  local key="$1"
  local value="$2"

  mkdir -p "$BASE_DIR"
  cat > "$SESSION_FILE" << EOF
${key}=${value}
timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
EOF

  echo "💾 Session saved: $key=$value"
}

# セッション読み込み
load_session() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "❌ No active session found."
    return 1
  fi

  source "$SESSION_FILE"
  echo "📂 Session: loaded"
  return 0
}
```

#### Pattern 2: ディレクトリ構造初期化

```bash
#!/bin/bash
# ディレクトリ構造初期化

REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_PATH="$REPO_ROOT/[base-path]"

for subdir in [subdir1] [subdir2] [subdir3]; do
  FULL_PATH="$BASE_PATH/$subdir"
  mkdir -p "$FULL_PATH"
  echo "✅ Created: $FULL_PATH"
done

echo ""
echo "🎉 Structure initialized"
```

#### Pattern 3: エージェント起動

```bash
#!/bin/bash
# エージェント起動フロー

echo "🚀 Launching [agent-name] agent..."
echo ""
echo "📝 Agent will:"
echo "  - [処理内容1]"
echo "  - [処理内容2]"
echo ""

# Note: Claude will invoke Task tool with [agent-name] agent
```

### 処理制約・要件

#### 技術制約

- Shell: Bash (Git Bash on Windows 対応)
- 依存関係: Git コマンドのみ必須
- 実行時間: 即座完了 (数秒以内)
- 処理複雑度: シンプルな処理 (複雑なロジック禁止)

#### エラーハンドリング

基本パターン:

```bash
if [ -z "$REQUIRED_VAR" ]; then
  echo "❌ Error: Required variable not set"
  exit 1
fi

echo "✅ Success: 処理完了"
```

メッセージ形式:

```bash
- `❌ Error: [Specific error description]`
- `✅ Success: [成功メッセージ]`
- `✅ Created: [作成されたファイル/ディレクトリ]`
- `💾 Session saved: [セッション情報]`
- `🚀 Launching: [起動内容]`
```

## コマンド構造標準

### ファイル配置・命名

#### ディレクトリ構造

```bash
.claude/
└── commands/
    ├── [command-name].md
    ├── [command-name-2].md
    └── ...
```

#### 命名規則

**形式**: `[command-name].md`

**要件**:

- 小文字のみ使用
- ハイフン区切り (`command-name`)
- 拡張子は `.md`
- スペース・アンダースコア禁止

**パターン例**:

- `commit-message.md` (action-target)
- `validate-debug.md` (action-target)
- `project-init.md` (target-action)

### ドキュメント構造標準

#### 必須セクション構成

```markdown
---
[Frontmatter]
---

## Quick Reference

[使用方法概要]

## Help Display

'''python
[Help display code]
'''
```

## [Function] Handler

```python
[Implementation code]
```

## Examples

[使用例と期待される出力]。

### セクション階層ルール

- Level 1: `# [Command Name]` (通常省略、ファイル名で代替)
- Level 2: `## [Major Section]`
- Level 3: `### [Sub Section]` (必要時のみ)

#### セクション命名規約

**基本機能セクション**:

- `Help Display`: ヘルプ表示
- `Version Info`: バージョン情報表示
- `Quick Setup`: 初期設定

**処理機能セクション**:

- `[Command] Handler`: 各コマンド処理
- `Initialize [Target]`: 初期化処理
- `Create [Resource]`: リソース作成
- `Update [Configuration]`: 設定更新

**命名ルール**:

- 英語での記述 (Claude 認識確実性)
- 具体的で明確な表現
- 一貫した語順: `[Action] [Object]` または `[Object] [Action]`

## 品質検証ワークフロー

### 検証フェーズ

#### Phase 1: 基本検証

**ファイル存在確認**:

```python
import os
file_path = ".claude/commands/[command-file].md"
if not os.path.exists(file_path):
    print("Error: Command file not found")
```

**フロントマター確認**:

```python
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
if not content.startswith('---'):
    print("Error: Frontmatter not found")
```

### Phase 2: フロントマター検証

**YAML 構文検証**:

```python
import yaml
try:
    frontmatter = yaml.safe_load(frontmatter_content)
except yaml.YAMLError as e:
    print(f"Error: Invalid YAML syntax - {e}")
```

**必須フィールド確認**:

```python
required_claude_fields = ['allowed-tools', 'argument-hint', 'description']
required_project_fields = ['title', 'version', 'created', 'authors']

for field in required_claude_fields:
    if field not in frontmatter:
        print(f"Error: Missing Claude Code field: {field}")
```

### Phase 3: Python コード検証

**構文正確性確認**:

```python
import ast
try:
    ast.parse(python_code)
    print("Success: Python syntax valid")
except SyntaxError as e:
    print(f"Error: Python syntax error - {e}")
```

**実行テスト**:

```python
try:
    exec(python_code)
    print("Success: Code execution completed")
except Exception as e:
    print(f"Error: Runtime error - {e}")
```

### 品質基準

#### 検証レポート形式

```bash
=== Quality Validation Report ===
File: [command-file].md
Date: YYYY-MM-DD HH:MM:SS

[✓/✗] Frontmatter Validation
[✓/✗] Structure Validation
[✓/✗] Python Code Validation
[✓/✗] Integration Validation
[✓/✗] Project Compliance Validation

Overall Status: [PASS/FAIL]
Issues Found: [N]
Warnings: [N]
```

#### ag-logger 準拠チェック

- `pnpm run lint:text docs/writing-rules/custom-slash-commands.md` エラー 0 件
- `pnpm run lint:markdown docs/writing-rules/custom-slash-commands.md` エラー 0 件
- Claude Code 公式仕様との完全互換性確保

## 実践的活用例

### 例1: /sdd コマンド

Spec-Driven-Development (SDD) ワークフロー実装例。

#### コマンドファイル: `.claude/commands/sdd.md`

```yaml
---
# Claude Code 必須要素
allowed-tools: Bash(*), Read(*), Write(*), Task(*)
argument-hint: [subcommand] [additional args]
description: Spec-Driven-Development主要コマンド - init/req/spec/task/code サブコマンドで要件定義から実装まで一貫した開発支援

# 設定変数
config:
  base_dir: docs/.cc-sdd
  session_file: .lastSession
  subdirs:
    - requirements
    - specifications
    - tasks
    - implementation

# サブコマンド定義
subcommands:
  init: "プロジェクト構造初期化"
  req: "要件定義フェーズ"
  spec: "設計仕様作成フェーズ"
  task: "タスク分解フェーズ"
  code: "BDD実装フェーズ"

# ユーザー管理ヘッダー
title: sdd
version: 2.0.0
created: 2025-09-28
authors:
  - atsushifx
---
```

#### /sdd 主要サブコマンド実装

**init サブコマンド**:

```bash
#!/bin/bash
# プロジェクト構造初期化

NAMESPACE_MODULE="$1"
NAMESPACE="${NAMESPACE_MODULE%%/*}"
MODULE="${NAMESPACE_MODULE##*/}"

REPO_ROOT=$(git rev-parse --show-toplevel)
SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
BASE_PATH="$SDD_BASE/$NAMESPACE/$MODULE"

for subdir in requirements specifications tasks implementation; do
  FULL_PATH="$BASE_PATH/$subdir"
  mkdir -p "$FULL_PATH"
  echo "✅ Created: $FULL_PATH"
done

# セッション保存
SESSION_FILE="$SDD_BASE/.lastSession"
cat > "$SESSION_FILE" << EOF
namespace=$NAMESPACE
module=$MODULE
timestamp=$(date -Iseconds)
EOF

echo "🎉 SDD structure initialized for $NAMESPACE/$MODULE"
```

**code サブコマンド** (bdd-coder エージェント起動):

```bash
#!/bin/bash
# BDD実装フェーズ

REPO_ROOT=$(git rev-parse --show-toplevel)
SESSION_FILE="$REPO_ROOT/docs/.cc-sdd/.lastSession"

source "$SESSION_FILE"
echo "📂 Session: $namespace/$module"
echo ""
echo "💻 BDD Implementation Phase"
echo "🚀 Launching BDD coder agent..."

# Note: Claude will invoke Task tool with bdd-coder agent
```

#### /sdd 使用例

```bash
# 1. プロジェクト初期化
/sdd init core/logger

# 2-4. 要件定義・設計・タスク分解
/sdd req
/sdd spec
/sdd task

# 5. BDD実装
/sdd code
```

### 例2: /idd-issue コマンド

GitHub Issue 作成・管理システム実装例。

#### コマンドファイル: `.claude/commands/idd-issue.md`

```yaml
---
# Claude Code 必須要素
allowed-tools: Bash(git:*, gh:*), Read(*), Write(*), Task(*)
argument-hint: [subcommand] [options]
description: GitHub Issue 作成・管理システム - issue-generatorエージェントによる構造化Issue作成

# 設定変数
config:
  temp_dir: temp/issues
  issue_types:
    - feature
    - bug
    - enhancement
    - task

# サブコマンド定義
subcommands:
  new: "issue-generatorエージェントで新規Issue作成"
  list: "保存済みIssueドラフト一覧表示"
  view: "特定のIssueドラフト表示"
  edit: "Issueドラフト編集"
  load: "GitHub IssueをローカルにImport"
  push: "ドラフトをGitHubにPush"

# ユーザー管理ヘッダー
title: idd-issue
version: 2.1.0
created: 2025-09-30
authors:
  - atsushifx
---
```

#### /idd-issue 主要サブコマンド実装

**new サブコマンド** (issue-generator エージェント起動):

```bash
#!/bin/bash
setup_issue_env
ensure_issues_dir

echo "🚀 Launching issue-generator agent..."
echo ""
show_issue_types

# Note: Claude will invoke issue-generator agent via Task tool
# Agent will save session using: save_session()
```

**list サブコマンド**:

```bash
#!/bin/bash
setup_issue_env

echo "📋 Issue drafts:"
echo "=================================================="

for file in "$ISSUES_DIR"/*.md; do
  filename=$(basename "$file" .md)
  title=$(extract_title "$file")
  echo "📄 $filename"
  echo "   Title: $title"
  echo ""
done
```

**push サブコマンド**:

```bash
#!/bin/bash
setup_issue_env
find_issue_file "$1"

TITLE=$(extract_title "$ISSUE_FILE")
TEMP_BODY=$(mktemp)
tail -n +2 "$ISSUE_FILE" > "$TEMP_BODY"

if [[ "$ISSUE_NAME" =~ ^new- ]]; then
  gh issue create --title "$TITLE" --body-file "$TEMP_BODY"
else
  ISSUE_NUM=$(extract_issue_number "$ISSUE_NAME")
  gh issue edit "$ISSUE_NUM" --title "$TITLE" --body-file "$TEMP_BODY"
fi

rm -f "$TEMP_BODY"
```

#### /idd-issue 使用例

```bash
# 1. 新規Issue作成
/idd-issue new

# 2. Issue確認
/idd-issue list
/idd-issue view 123

# 3. GitHubへプッシュ
/idd-issue push 123
```

## See Also

- [カスタムエージェント](custom-agents.md): エージェント記述ルール
- [フロントマターガイド](frontmatter-guide.md): フロントマター統一ルール
- [執筆ルール](writing-rules.md): Claude 向け執筆禁則事項
- [ドキュメントテンプレート](document-template.md): 標準テンプレート
- [AI Development Standards](../for-ai-dev-standards/README.md): AI 開発標準ドキュメント

## 注意事項・制約

### 絶対遵守事項

1. **フロントマター統一**: Claude Code 公式要素の厳格遵守
2. **Bash 制約**: 標準コマンドのみ使用、Git 依存、シェル移植性確保
3. **セキュリティ**: 機密情報のコード記述・ログ出力禁止
4. **ファイル配置**: `.claude/commands/` 直下の配置厳守

### 品質保証要件

- textlint・markdownlint 準拠
- Claude Code 自動補完機能との互換性確保
- ag-logger プロジェクト体系との整合性維持
- 実際に動作するサンプルコードの提供

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx

---

このルールは AI エージェントによるコマンド作成の品質・一貫性・実用性確保のため必須遵守。
