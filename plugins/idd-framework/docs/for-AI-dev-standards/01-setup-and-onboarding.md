---
header:
  - src: 01-setup-and-onboarding.md
  - @(#): AI Development Environment Setup
title: claude-idd-framework
description: AIコーディングエージェント向け開発環境セットアップ・オンボーディング
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

## AI開発環境セットアップ

このドキュメントは AI コーディングエージェントが agla-logger プロジェクトで開発を開始する際のセットアップとオンボーディング手順を定義します。
効率的で一貫した開発環境の構築を目的とします。

## プロジェクト理解の必須事項

### 基本情報

- プロジェクト: agla-logger - TypeScript 用軽量・Pluggable ロガー
- アーキテクチャ: pnpm ワークスペース使用のモノレポ
- 現在フォーカス: AglaError フレームワークへの移行

### 技術スタック

- ESM-first + CommonJS 互換性
- デュアルビルド: `lib/` (CJS), `module/` (ESM)
- TypeScript 厳格モード + 包括的型定義
- 4層テスト戦略: Unit/Functional/Integration/E2E

### パッケージ構成

モノレポ構造の主要パッケージ一覧:

```bash
packages/@aglabo/
├── agla-logger-core/  # 構造化ロガーパッケージ
└── agla-error-core/   # エラーハンドリングフレームワーク
```

## 必須セットアップ手順

### 1. プロジェクト概要把握

必須: 開発開始前のプロジェクト理解。

MCP ツールを使用したプロジェクト構造の把握と既存知識の読み込み:

```bash
# プロジェクト全体構造確認
mcp__lsmcp__get_project_overview --root "$ROOT"

# メモリ確認 (既存の知識ベース)
mcp__lsmcp__list_memories --root "$ROOT"

# 重要メモリの読み込み
mcp__lsmcp__read_memory --memoryName "<memory-name>" --root "$ROOT"
mcp__lsmcp__read_memory --memoryName "<memory-name>" --root "$ROOT"
```

### 2. 開発環境確認

依存関係のインストールと基本的な動作確認:

```bash
# 依存関係インストール確認
pnpm install

# 基本コマンド動作確認
pnpm run check:types
pnpm run test:develop
pnpm run build
```

### 3. MCPツール活用環境

シンボルインデックスの初期化と外部ライブラリの登録:

```bash
# シンボルインデックス初期化
mcp__lsmcp__get_project_overview --root "$ROOT"

# 外部ライブラリインデックス
mcp__lsmcp__index_external_libraries --root "$ROOT"

# TypeScript依存関係確認
mcp__lsmcp__get_typescript_dependencies --root "$ROOT"
```

## 開発ルール理解

### 必須ルール確認

必須: 以下のルールを開発前に確認。

1. MCP ツール必須使用 - 全開発段階で lsmcp・serena-mcp 活用
2. BDD 開発プロセス - Red-Green-Refactor サイクル厳守
3. 品質ゲート - 5 項目チェック (型・リント・フォーマット・テスト・ビルド)
4. 3階層 BDD 構造 - Given/When/Then 階層の徹底

### 開発フロー理解

BDD 開発サイクルの基本的な流れ:

```bash
# 基本開発フロー
1. 既存コード理解 → MCPツールで構造・パターン分析
2. テスト作成 → 既存テストパターンを参考にBDD構造で記述
3. 最小実装 → テスト通過に必要な最小限のコード実装
4. リファクタリング → コード品質向上・パフォーマンス改善
5. 影響範囲確認 → MCPツールで参照先・依存関係チェック
```

## プロジェクト構造理解

### 主要ディレクトリ

プロジェクトの主要なディレクトリ構造と役割:

```bash
# ソースコード (編集対象)
src/                    # メインソースコード
├── core/              # コア機能
├── types/             # 型定義
├── utils/             # ユーティリティ
└── plugins/           # プラグイン

# テスト (編集対象)
__tests__/             # Unit・Functionalテスト
├── unit/              # Unit tests (27ファイル)
└── functional/        # Functional tests (4ファイル)

tests/                 # Integration・E2Eテスト
├── integration/       # Integration tests (14ファイル)
└── e2e/              # E2E tests (8ファイル)

# 設定 (編集対象)
configs/               # 設定ファイル
├── eslint/           # ESLint設定
├── typescript/       # TypeScript設定
└── vitest/           # テスト設定

# ビルド出力 (編集禁止)
lib/                   # CommonJS出力
module/                # ESM出力
maps/                  # ソースマップ
```

### 重要ファイル

開発に必要な主要設定ファイル:

```bash
# パッケージ管理
package.json           # メインパッケージ設定
pnpm-workspace.yaml    # ワークスペース設定

# 品質管理
lefthook.yml         # Pre-commitフック
tsconfig.json         # TypeScript設定

# AI開発ガイド
CLAUDE.md             # 総合開発ガイド
docs/for-AI-dev-standards/ # AI専用開発標準
```

## 必須コマンド習得

### 開発コマンド

開発時に使用する基本的なコマンド一覧:

```bash
# 型チェック (最優先)
pnpm run check:types

# 4層テストシステム
pnpm run test:develop      # Unit tests (27ファイル)
pnpm run test:functional   # Functional tests (4ファイル)
pnpm run test:ci           # Integration tests (14ファイル)
pnpm run test:e2e          # E2E tests (8ファイル)

# 品質確認
pnpm run lint:all          # ESLint実行
pnpm run check:dprint      # フォーマット確認
pnpm run build             # ビルド確認
```

### 修正コマンド

コード修正とクリーンビルドのコマンド:

```bash
# 自動修正
pnpm run lint:all -- --fix  # ESLint自動修正
pnpm run format:dprint      # フォーマット自動適用

# クリーン・リビルド
pnpm run clean              # ビルド出力削除
```

## MCPツール基本操作

### プロジェクト理解

プロジェクト全体の構造把握とシンボル検索:

```bash
# 概要確認
mcp__lsmcp__get_project_overview --root "$ROOT"

# 主要シンボル確認
mcp__lsmcp__search_symbols --kind ["Class"] --root "$ROOT"
mcp__lsmcp__search_symbols --query "AgLogger" --root "$ROOT"

# ディレクトリ構造確認
mcp__serena-mcp__list_dir --relative_path "." --recursive true
```

### コード調査

シンボルの詳細確認とパターン検索:

```bash
# シンボル詳細確認
mcp__serena-mcp__find_symbol --name_path "<class-name>" --include_body true

# パターン検索
mcp__serena-mcp__search_for_pattern --substring_pattern "<pattern>" --relative_path "src"

# 参照箇所確認
mcp__serena-mcp__find_referencing_symbols --name_path "<symbol-name>" --relative_path "<file-path>"
```

### 型・依存関係確認

LSP ツールを使用した型情報と診断の確認:

```bash
# 型情報確認
mcp__lsmcp__lsp_get_hover --textTarget "<type-name>" --relativePath "<file-path>"

# 定義確認
mcp__lsmcp__lsp_get_definitions --symbolName "<symbol-name>" --relativePath "<file-path>"

# 診断情報確認
mcp__lsmcp__lsp_get_diagnostics --relativePath "<file-path>" --root "$ROOT"
```

## 実践的オンボーディング

### MCP ツール初回オンボーディング

lsmcp と serena-mcp の初回セットアップ手順:

```bash
# 1. lsmcp オンボーディング
mcp__lsmcp__index_onboarding --root "$ROOT"
# ↑ シンボルインデックスの初期化とオンボーディングガイドの表示

# 2. serena-mcp オンボーディング
mcp__serena-mcp__onboarding
# ↑ プロジェクト構造の分析とメモリの作成
```

### 初回開発タスク例

初めて開発する際の段階的な作業手順:

```bash
# 1. プロジェクト理解
mcp__lsmcp__get_project_overview --root "$ROOT"

# 2. 既存ロガー実装確認
mcp__lsmcp__search_symbols --query "AgLogger" --root "$ROOT"
mcp__serena-mcp__find_symbol --name_path "AgLogger" --include_body true

# 3. テストパターン確認
mcp__serena-mcp__search_for_pattern --substring_pattern "describe.*AgLogger"

# 4. 簡単な機能追加 (BDDサイクル実践)
# - RED: テスト作成
# - GREEN: 最小実装
# - REFACTOR: 品質向上
```

### 品質確認習慣

実装後に必ず実行する品質確認と影響範囲の確認:

```bash
# 実装後必須チェック
pnpm run check:types      # 型エラー確認
pnpm run lint:all         # コード品質確認
pnpm run test:develop     # テスト実行
pnpm run build           # ビルド確認

# 影響範囲確認
mcp__serena-mcp__find_referencing_symbols --name_path "<modified-symbol>"
```

## トラブルシューティング

### よくある問題と解決策

#### 型エラー

型エラーの詳細確認と原因調査:

```bash
# 型エラー詳細確認
mcp__lsmcp__lsp_get_diagnostics --relativePath "<error-file-path>" --root "$ROOT"

# 型定義確認
mcp__lsmcp__lsp_get_hover --textTarget "<error-location>"
```

#### テスト失敗

個別テストの実行と詳細な出力確認:

```bash
# 個別テスト実行
pnpm run test:develop -- "<test-file-path>"

# 詳細出力
pnpm run test:develop -- --reporter=verbose
```

#### ビルドエラー

依存関係の再インストールとクリーンビルド:

```bash
# 依存関係再インストール
pnpm install

# クリーンビルド
pnpm run clean && pnpm run build
```

#### MCPツールエラー

MCP ツールの設定確認とインデックス再構築:

```bash
# プロジェクトルート確認
echo $ROOT

# インデックス再構築
mcp__lsmcp__get_project_overview --root "$ROOT"
```

## 継続的学習

### プロジェクト知識の蓄積

学習した内容のメモリ保存と既存メモリの確認:

```bash
# 新しい知識のメモリ保存
mcp__lsmcp__write_memory --memoryName "<memory-name>" --content "<content>" --root "$ROOT"

# 既存メモリの更新確認
mcp__lsmcp__list_memories --root "$ROOT"
```

### 改善提案

- 効率的だった MCP ツール使用パターンの記録
- 失敗事例からの学習・改善
- 新しいベストプラクティスの提案

---

### See Also

- [02-core-principles.md](02-core-principles.md) - AI 開発核心原則
- [03-mcp-tools-usage.md](03-mcp-tools-usage.md) - MCP ツール完全ガイド
- [05-bdd-workflow.md](05-bdd-workflow.md) - BDD 開発フロー詳細

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
