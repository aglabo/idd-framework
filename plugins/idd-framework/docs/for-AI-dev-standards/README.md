---
header:
  - src: README.md
  - @(#): AI Development Standards
title: claude-idd-framework
description: AI コーディングエージェント専用開発標準・実装ルール集
version: 1.0.0
created: 2025-09-27
authors:
  - atsushifx
changes:
  - 2025-09-27: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## AI開発標準ディレクトリ

このディレクトリは 'Claude Code' などの AI コーディングエージェント専用の開発標準・実装ルールを集約しています。
トークン効率的で実践的な AI 開発支援を目的とします。

### 重要事項

- 必須: このディレクトリの内容は AI エージェント専用である
- 必須: すべての開発段階で 'MCP' ツール ('lsmcp', 'serena-mcp') を積極活用する
- 必須: 'BDD' 開発プロセス ('Red-Green-Refactor') を厳格遵守する

### ドキュメント構成

<!-- markdownlint-disable ol-prefix -->

#### 1. 環境準備・基本原則

1. [AI 開発環境セットアップ・オンボーディング](01-setup-and-onboarding.md)
2. [AI 開発の核心原則・MCP 必須ルール](02-core-principles.md)

#### 2. ツール活用

3. [MCP ツール完全活用ガイド](03-mcp-tools-usage.md)
4. [プロジェクトナビゲーション・コード検索](04-code-navigation.md)

#### 3. 開発プロセス

5. [BDD 開発フロー・Red-Green-Refactor サイクル](05-bdd-workflow.md)
6. [コーディング規約・MCP 活用パターン](06-coding-conventions.md)
7. [テスト実装・BDD 階層構造](07-test-implementation.md)

#### 4. 品質保証・高度なガイド

8. [AI 用品質ゲート・自動チェック](08-quality-assurance.md)
9. [ソースコードテンプレート・JSDoc ルール](09-templates-and-standards.md)
10. [atsushifx 式 BDD 実装ガイド詳細](10-bdd-implementation-details.md)

<!-- markdownlint-enable ol-prefix -->

### 使用方法

#### 開発開始前

1. [AI 開発環境セットアップ・オンボーディング](01-setup-and-onboarding.md) で環境セットアップ
2. [AI 開発の核心原則・MCP 必須ルール](02-core-principles.md) で基本原則を確認
3. [MCP ツール完全活用ガイド](03-mcp-tools-usage.md) で MCP ツール使用法を習得

#### 実装時

1. [BDD 開発フロー・Red-Green-Refactor サイクル](05-bdd-workflow.md) で BDD サイクル実行
2. [atsushifx 式 BDD 実装ガイド詳細](10-bdd-implementation-details.md) で詳細実装ガイド確認
3. [プロジェクトナビゲーション・コード検索](04-code-navigation.md) でプロジェクト理解
4. [コーディング規約・MCP 活用パターン](06-coding-conventions.md) で規約遵守

#### 品質確認時

1. [AI 用品質ゲート・自動チェック](08-quality-assurance.md) で品質ゲート実行
2. [テスト実装・BDD 階層構造](07-test-implementation.md) でテスト検証

### プロジェクト理解

'agla-logger' は 'TypeScript' 用軽量・Pluggable ロガーです。

- 'ESM-first' + 'CommonJS' 互換性
- 'pnpm' ワークスペース使用のモノレポ
- 4層テスト戦略 ('Unit'/'Functional'/'Integration'/'E2E')
- 'AglaError' フレームワーク統合

### 主要パッケージ

```bash
packages/@aglabo/
├── agla-logger-core/  # 構造化ロガーパッケージ
└── agla-error-core/   # エラーハンドリングフレームワーク
```

### 必須コマンド

```bash
# 型チェック (最優先)
pnpm run check:types

# 4層テストシステム
pnpm run test:develop    # 開発用テスト
pnpm run test:ci         # 全テスト実行

# 品質確認
pnpm run lint:all        # リント
pnpm run check:dprint    # フォーマット
pnpm run build           # ビルド
```

---

### See Also

- [../docs/dev-standards/16-ai-assisted-development.md](../docs/dev-standards/16-ai-assisted-development.md) - 開発者向け AI 使用ガイド
- [../docs/projects/00-project-overview.md](../docs/projects/00-project-overview.md) - プロジェクト全体概要
- [../CLAUDE.md](../CLAUDE.md) - 総合開発ガイド

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
