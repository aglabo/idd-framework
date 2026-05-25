---
header:
  - src: custom-agents.md
  - @(#): Claude カスタムエージェント記述ルール
title: agla-logger
description: Claude Code 向けカスタムエージェント記述統一ルール - AI エージェント向けガイド
version: 1.0.0
created: 2025-01-28
authors:
  - atsushifx
changes:
  - 2025-10-03: /sdd, /idd-issue コマンド記述を削除し、bdd-coder, commit-message-generator エージェント実例に置き換え
  - 2025-10-03: 実際の /sdd, /idd-issue コマンドと bdd-coder, issue-generator エージェントに合わせて全面更新
  - 2025-01-28: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

このドキュメントは、Claude Code 向けのカスタムエージェントを記述するための統一ルールを定義します。
AI エージェントがエージェント構文を正確に理解し、一貫性のあるエージェントを作成することを目的とします。

## 統合フロントマター仕様

### 基本構成

Claude Code 公式要素と ag-logger プロジェクト要素を統合した統一フロントマター形式を使用します。

#### 標準テンプレート

```yaml
---
# Claude Code 必須要素
name: your-agent-name
<!-- markdownlint-disable MD013 -->
description: [エージェントの実行タイミング説明] Examples: <example>Context: [状況] user: "[ユーザー入力]" assistant: "[アシスタント応答]" <commentary>[解説]</commentary></example>
<!-- markdownlint-enable MD013 -->
tools: tool1, tool2, tool3  # オプション - 省略された場合はすべてのツールを継承
model: inherit  # オプション - モデルエイリアスまたは'inherit'を指定
color: blue  # オプション - エージェント識別色

# ユーザー管理ヘッダー
title: agent-name
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

#### name フィールド

**目的**: エージェントの識別名指定。
**形式**: `your-agent-name` 形式 (ハイフン区切り)。

命名規則:

- 小文字のみ使用
- ハイフン区切り (`agent-name`)
- 動詞+目的語または機能名
- 簡潔で明確な命名

使用例:

- `typescript-bdd-coder`: TypeScript BDD コーダー
- `git-commit-generator`: Git コミットメッセージ生成
- `test-suite-runner`: テストスイート実行

#### description フィールド

**目的**: エージェントが呼び出されるべき条件・タイミングの説明。
**要件**: 簡潔で具体的な条件説明 + Examples 記法での使用例。

記述パターン:

```yaml
[核心機能説明] Examples: <example>Context: [状況] user: "[入力]" assistant: "[応答]" <commentary>[解説]</commentary></example>
```

記述例:

```yaml
description: >
  atsushifx式BDD厳格プロセスで多言語対応コードを実装する汎用エージェント。
  Red-Green-Refactor サイクルを厳格に遵守し、1 message = 1 test の原則で段階的実装を行う。
  Examples: <example>Context: 新機能の BDD 実装要求 user: "バリデーション機能を BDD で実装して"
  assistant: "bdd-coder エージェントで厳格な Red-Green-Refactor サイクルによる実装を開始します"
  <commentary>BDD 厳格プロセスが必要なので、単一テストから始める段階的実装を実行</commentary></example>
```

Examples 記法の構造:

- Context: 状況説明
- user: ユーザー入力例
- assistant: アシスタント応答例
- commentary: 判断理由・解説

#### tools フィールド (オプション)

**目的**: エージェントが使用するツールの制限指定。
**形式**: カンマ区切りツールリスト。

使用パターン:

- `*`: すべてのツール継承 (デフォルト)
- `Read, Edit, Bash`: 特定ツールのみ
- `*` (省略): 親エージェントからすべて継承

#### model フィールド (オプション)

**目的**: エージェントが使用するモデル指定。
**形式**: モデルエイリアスまたは継承指定。

**プロジェクト標準**: `inherit`

使用パターン:

- `inherit`: 親エージェントのモデル継承 (推奨)
- `sonnet`: Claude 3.5 Sonnet
- `haiku`: Claude 3 Haiku
- `opus`: Claude 3 Opus

#### color フィールド (オプション)

**目的**: エージェント識別色の指定。
**形式**: 色名文字列。

使用例:

- `blue`: bdd-coder エージェント
- `green`: issue-generator エージェント
- `red`: エラー処理系エージェント
- `yellow`: 警告・レビュー系エージェント

### ユーザー管理ヘッダー

#### 統一要素

- title: エージェント名 (kebab-case)
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

# ユーザー管理ヘッダー
[user-management-elements]

copyright:
  [copyright-notice]
---
```

## エージェント構造標準

### ファイル配置・命名

#### ディレクトリ構造

```bash
.claude/
└── agents/
    ├── [agent-name].md
    ├── [agent-name-2].md
    └── ...
```

#### 命名規則

**形式**: `[agent-name].md`

**要件**:

- 小文字のみ使用
- ハイフン区切り (`agent-name`)
- 拡張子は `.md`
- スペース・アンダースコア禁止

**パターン例**:

- `typescript-bdd-coder.md` (language-methodology-role)
- `git-commit-generator.md` (tool-action-type)
- `test-coverage-analyzer.md` (domain-function-role)

### ドキュメント構造標準

#### 必須セクション構成

```markdown
---
[Frontmatter]
---

## Agent Overview

[エージェントの概要説明]

## Activation Conditions

[エージェントが起動される条件]

## Core Functionality

[主要機能の詳細説明]

## Integration Guidelines

[他のエージェントやツールとの連携方法]

## Examples

[使用例と期待される動作]
```

### セクション階層ルール

- Level 1: `# [Agent Name]` (通常省略、ファイル名で代替)
- Level 2: `## [Major Section]`
- Level 3: `### [Sub Section]` (必要時のみ)

#### セクション命名規約

**基本機能セクション**:

- `Agent Overview`: エージェント概要
- `Activation Conditions`: 起動条件
- `Core Functionality`: 核機能
- `Integration Guidelines`: 連携ガイドライン

**詳細機能セクション**:

- `Input Processing`: 入力処理
- `Output Generation`: 出力生成
- `Error Handling`: エラーハンドリング
- `Performance Considerations`: パフォーマンス考慮事項

**命名ルール**:

- 英語での記述 (Claude 認識確実性)
- 具体的で明確な表現
- 一貫した語順: `[Aspect] [Function]` または `[Function] [Aspect]`

## 品質検証ワークフロー

### 検証フェーズ

#### Phase 1: 基本検証

**ファイル存在確認**:

```python
import os
file_path = ".claude/agents/[agent-file].md"
if not os.path.exists(file_path):
    print("Error: Agent file not found")
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
required_claude_fields = ['name', 'description']
required_project_fields = ['title', 'version', 'created', 'authors']

for field in required_claude_fields:
    if field not in frontmatter:
        print(f"Error: Missing Claude Code field: {field}")
```

### Phase 3: エージェント固有検証

**model フィールド検証** (ag-logger 標準):

```python
model_value = frontmatter.get('model', 'inherit')
if model_value != 'inherit':
    print(f"Warning: Model should be 'inherit' for ag-logger project, found: {model_value}")
```

**名前一貫性確認**:

```python
import os
filename = os.path.basename(file_path).replace('.md', '')
agent_name = frontmatter.get('name', '')
if filename != agent_name:
    print(f"Error: Filename '{filename}' does not match agent name '{agent_name}'")
```

### 品質基準

#### 検証レポート形式

```bash
=== Agent Quality Validation Report ===
File: [agent-file].md
Date: YYYY-MM-DD HH:MM:SS

[✓/✗] Frontmatter Validation
[✓/✗] Structure Validation
[✓/✗] Naming Convention Validation
[✓/✗] ag-logger Standard Compliance
[✓/✗] Documentation Completeness

Overall Status: [PASS/FAIL]
Issues Found: [N]
Warnings: [N]
```

#### ag-logger 準拠チェック

- `pnpm run lint:text docs/writing-rules/custom-agents.md` エラー 0 件
- `pnpm run lint:markdown docs/writing-rules/custom-agents.md` エラー 0 件
- Claude Code 公式仕様との完全互換性確保
- model フィールドは `inherit` 設定

## 実践的活用例

### 例1: bdd-coder エージェント

実際のプロジェクトで使用されている多言語対応 BDD 実装エージェント。

#### エージェントファイル: `.claude/agents/bdd-coder.md`

<!-- markdownlint-disable line-length -->

```markdown
---
# Claude Code 必須要素
name: bdd-coder
description: atsushifx式BDD厳格プロセスで多言語対応コードを実装する汎用エージェント。Red-Green-Refactor サイクルを厳格に遵守し、1 message = 1 test の原則で段階的実装を行う。TodoWrite ツールと temp/todo.md の完全同期による進捗管理と、プロジェクト固有の品質ゲート自動実行で高品質コードを保証する。
tools: Bash, Read, Write, Edit, Grep, Glob, TodoWrite
model: inherit
color: blue

# ユーザー管理ヘッダー
title: bdd-coder
version: 3.0.0
created: 2025-01-28
authors:
  - atsushifx
changes:
  - 2025-10-02: 多言語対応に汎用化、プロジェクト固有要素を削除
  - 2025-01-28: 初版作成
---

## エージェント Overview

atsushifx 式 BDD を厳格に実践する多言語対応実装エージェント。
Red-Green-Refactor サイクルと TodoWrite 連携による段階的実装を提供。

### 核心原則

1. 1 message = 1 test
2. 厳格プロセス遵守 (RED → GREEN → REFACTOR)
3. TodoWrite 連携
4. 品質ゲート統合

### 主要機能

- BDD 三層階層構造 (Given/When/Then)
- MCP ツール活用
- 進捗管理とタスク追跡
- 品質保証システム統合
```

<!-- markdownlint-enable -->

#### 例1 bdd-coder の特徴

- 多言語対応: TypeScript/Vitest、Python/pytest、Java/JUnit など任意の言語対応
- 厳格プロセス: 1 message = 1 test 原則の徹底
- TodoWrite 連携: temp/todo.md との完全同期
- MCP ツール活用: serena-mcp, lsmcp による効率的コードナビゲーション
- 品質ゲート: プロジェクト固有の品質チェック自動実行

### 例2: issue-generator エージェント

GitHub Issue 作成を専門とするエージェント。

#### エージェントファイル: `.claude/agents/issue-generator.md`

<!-- markdownlint-disable line-length -->

```markdown
---
# Claude Code 必須要素
name: issue-generator
description: 一般的なプロジェクト用の GitHub Issue 作成エージェント。Feature リクエスト、Bug レポート、Enhancement、Task の構造化された Issue ドラフトを temp/ ディレクトリに作成し、プロジェクトの開発プロセスと品質基準に準拠した内容を生成する。
tools: Read, Write, Grep
model: inherit
color: green

# ユーザー管理ヘッダー
title: issue-generator
version: 2.0.0
created: 2025-09-30
authors:
  - atsushifx
---

## エージェント Overview

GitHub Issue 作成スペシャリスト。YML テンプレートから動的に Issue 構造を生成。

### 主要責務

1. YML テンプレート読み込み (`.github/ISSUE_TEMPLATE/`)
2. 対話的情報収集
3. Markdown ドラフト生成
4. temp/issues/ への保存

### 対応 Issue 種別

- feature: 新機能追加要求
- bug: バグレポート
- enhancement: 既存機能改善
- task: 開発・メンテナンスタスク
```

<!-- markdownlint-enable -->

#### issue-generator の主要特徴

- 動的テンプレート: `.github/ISSUE_TEMPLATE/` から YML 読み込み
- 自動ファイル名生成: `new-{timestamp}-{type}-{slug}.md` 形式
- セッション連携: `/idd-issue` コマンドとの統合
- GitHub CLI 統合: gh コマンドでの Issue push サポート

### 例3: bdd-coder エージェント

atsushifx 式 BDD 厳格プロセスでの多言語対応コード実装エージェント。

#### bdd-coder エージェントファイル

<!-- markdownlint-disable line-length -->

```yaml
---
# Claude Code 必須要素
name: bdd-coder
description: atsushifx式BDD厳格プロセスで多言語対応コードを実装する汎用エージェント。Red-Green-Refactor サイクルを厳格に遵守し、1 message = 1 test の原則で段階的実装を行う。
tools: Bash, Read, Write, Edit, Grep, Glob, TodoWrite
model: inherit
color: blue

# ユーザー管理ヘッダー
title: bdd-coder
version: 3.0.0
created: 2025-01-28
authors:
  - atsushifx
---
```

<!-- markdownlint-enable -->

#### bdd-coder の起動条件

以下の場合にエージェントが起動:

- atsushifx 式 BDD でのコード実装要求時
- Red-Green-Refactor サイクルでの厳格な開発プロセスが必要な場合
- テスト駆動開発 (TDD) の実践が必要な場合
- `/sdd code` コマンド実行時
- bdd-coder の明示的呼び出し時

トリガー例:

```bash
"バリデーション機能を BDD で実装して"
"エラーハンドリング機能を BDD プロセスで拡張して"
```

#### bdd-coder の主要特徴

**核心原則**:

- 1 message = 1 test: 各メッセージで 1 つの `it()` のみを実装
- 厳格プロセス遵守: RED → GREEN → REFACTOR の順序を絶対遵守
- ToDo 連携: TodoWrite ツールと temp/todo.md の完全同期
- 品質ゲート統合: types/lint/test/format/build の必須実行

**BDD 三層階層構造**:

- Feature レベル (Given): 機能やコンポーネントの状態
- Scenario レベル (When): 特定のアクションやイベント
- Case レベル (Then): 期待される結果 ([正常]/[異常]/[エッジケース])

**多言語対応**:

- TypeScript/Vitest、Python/pytest、Java/JUnit、Ruby/RSpec など
- 任意のプログラミング言語とテストフレームワークの組み合わせに対応

**進捗管理**:

- TodoWrite ツールでタスク状態の自動更新
- expect 文完了時の即座完了報告
- タスクグループ完了時の進捗レポート (X/N タスク完了)

### 例4: commit-message-generator エージェント

Git ステージファイルから Conventional Commits 準拠メッセージを生成するエージェント。

#### commit-message-generator エージェントファイル

<!-- markdownlint-disable line-length -->

```yaml
---
# Claude Code 必須要素
name: commit-message-generator
description: Git ステージされたファイルから適切なコミットメッセージを生成するエージェント。プロジェクトの慣例を分析し、Conventional Commits 準拠のメッセージを提供する
tools: Bash, Read, Grep
model: inherit

# ユーザー管理ヘッダー
title: agla-logger
version: 1.0.0
created: 2025-01-28
authors:
  - atsushifx
---
```

<!-- markdownlint-enable  -->

#### commit-message-generator の起動条件

以下の場合にエージェントが起動:

- ユーザーがコミットメッセージの生成を要求した場合
- ファイルがステージされており、コミット準備が整っている場合
- プロジェクト慣例に沿ったメッセージが必要な場合

トリガー例:

```bash
"コミットメッセージを作成して"
"このコミットのメッセージを生成して"
```

#### commit-message-generator の主要特徴

**統一出力形式**:

```text
=== commit header ===
type(scope): summary

- file1.ext:
  変更概要1
- file2.ext:
  変更概要2
=== commit footer ===
```

**プロジェクト慣例分析**:

- 最近 10 件のコミットメッセージ形式を確認
- 言語 (日本語/英語)、プレフィックス使用パターンを特定
- CLAUDE.md、README.md からコミットルールを検索

**Type 分類**:

- `feat`: 新機能追加
- `fix`: バグ修正
- `docs`: ドキュメント更新
- `test`: テスト追加・修正
- `chore`: ルーチンタスク・メンテナンス
- `refactor`: バグ修正や機能追加を伴わないコード変更

**Scope 自動判定**:

- ファイル種別による自動判定 (設定ファイル、スクリプト、ドキュメント、ソースコード、テストなど)
- ファイルパス分析で scope を自動決定

使用例:

機能追加時:

```bash
=== commit header ===
feat(logger): ログレベルフィルタリング機能を追加

- src/logger/core.ts:
  LogLevel enum とフィルタリングロジックを実装
- __tests__/logger.test.ts:
  ログレベルフィルタリングのユニットテストを追加
=== commit footer ===
```

## 関連ドキュメント

### ドキュメント作成ルール

- [カスタムスラッシュコマンド](./custom-slash-commands.md): スラッシュコマンド記述ルール
- [執筆ルール](./writing-rules.md): Claude 向け執筆禁則事項
- [ドキュメントテンプレート](./document-template.md): 標準テンプレート
- [フロントマターガイド](./frontmatter-guide.md): フロントマター統一ルール

### プロジェクト開発ルール

- [開発ワークフロー](../rules/01-development-workflow.md): BDD 開発プロセス
- [品質保証システム](../rules/03-quality-assurance.md): 多層品質保証
- [MCP ツール必須要件](../rules/04-mcp-tools-mandatory.md): MCP ツール活用ルール
- [BDD テスト階層](../rules/07-bdd-test-hierarchy.md): BDD 階層構造統一ルール

### AI 開発標準ドキュメント

- [AI 開発標準 README](../for-AI-dev-standards/README.md): AI 開発標準全体概要
- [セットアップとオンボーディング](../for-AI-dev-standards/01-setup-and-onboarding.md): 環境構築・初期設定
- [核心原則](../for-AI-dev-standards/02-core-principles.md): 開発における基本原則
- [MCP ツール使用法](../for-AI-dev-standards/03-mcp-tools-usage.md): MCP ツールの活用方法
- [BDD ワークフロー](../for-AI-dev-standards/05-bdd-workflow.md): BDD 開発プロセス詳細
- [BDD 実装詳細](../for-AI-dev-standards/10-bdd-implementation-details.md): BDD 実装の技術的詳細

### エージェント実装例

<!-- markdownlint-disable line-length -->

- [.claude/agents/bdd-coder.md](../../.claude/agents/bdd-coder.md): bdd-coder エージェント実装
- [.claude/agents/issue-generator.md](../../.claude/agents/issue-generator.md): issue-generator エージェント実装
- [.claude/agents/commit-message-generator.md](../../.claude/agents/commit-message-generator.md): commit-message-generator エージェント実装

<!-- markdownlint-enable -->

## 注意事項・制約

### 絶対遵守事項

1. **フロントマター統一**: Claude Code 公式要素の厳格遵守
2. **model フィールド**: ag-logger プロジェクトでは `inherit` 必須
3. **セキュリティ**: 機密情報の処理・ログ出力禁止
4. **ファイル配置**: `.claude/agents/` 直下の配置厳守

### プロジェクト固有制約

- model フィールドは常に `inherit` を指定
- MCP ツール (`lsmcp`, `serena-mcp`) の積極活用
- 4層テスト戦略との整合性確保:
  - Unit tests: `pnpm run test:develop`
  - Functional tests: `pnpm run test:functional`
  - Integration tests: `pnpm run test:ci`
  - E2E tests: `pnpm run test:e2e`
- 品質ゲート (5 項目) との連携:
  - 型チェック: `pnpm run check:types`
  - リンター: `pnpm run lint:all`
  - テスト実行: `pnpm run test:develop`
  - フォーマット: `pnpm run check:dprint`
  - ビルド確認: `pnpm run build`
- lefthook による pre-commit 自動品質保証

### 品質保証要件

- textlint・markdownlint 準拠
- Claude Code エージェントシステムとの互換性確保
- ag-logger プロジェクト体系との整合性維持
- 実際に動作する機能仕様の提供

## See Also

- [カスタムスラッシュコマンド](custom-slash-commands.md): スラッシュコマンド記述ルール
- [フロントマターガイド](frontmatter-guide.md): フロントマター統一ルール
- [執筆ルール](writing-rules.md): Claude 向け執筆禁則事項
- [ドキュメントテンプレート](document-template.md): 標準テンプレート
- [AI Development Standards](../for-ai-dev-standards/README.md): AI 開発標準ドキュメント

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx

---

このルールは AI エージェントによるエージェント作成の品質・一貫性・実用性確保のため必須遵守。
