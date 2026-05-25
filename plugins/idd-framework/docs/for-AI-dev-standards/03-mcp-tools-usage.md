---
header:
  - src: 03-mcp-tools-usage.md
  - @(#): MCP Tools Complete Usage Guide
title: claude-idd-framework
description: lsmcp・serena-mcp・codex の完全活用ガイドとトークン効率最適化手法
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

## MCPツール完全活用ガイド

agla-logger プロジェクトで使用する MCP ツール (`lsmcp`, `serena-mcp`, `codex-mcp`) の完全活用方法とトークン効率最適化手法を説明します。

## 重要: 必須使用要件

**Claude Code でのコード操作時は、必ず MCP ツールを経由してください。**

### 禁止事項

- 直接的なファイル読み取り: `Read` ツールでのソースコード読み込み。
- 直接的なファイル編集: `Edit` や `Write` ツールでの直接編集。
- 非効率な検索: `Bash` や `Grep` での手動検索。
- 非 MCP ツールの単独使用: MCP 連携なしでのコード操作。

## MCPツール概要

### `lsmcp` (Language Server Protocol MCP)

機能: LSP 機能、型情報取得、シンボル操作、リファクタリング。
用途: 精密なコード解析、型安全な編集、診断・エラー検出。

### `serena-mcp` (セマンティック分析 MCP)

機能: セマンティックコード分析、シンボル検索、構造理解。
用途: プロジェクト全体俯瞰、シンボルによるナビゲーション、アーキテクチャ分析。

### `codex-mcp`

機能: 高度なコード生成、自動リファクタリング、パターン分析。
用途: 複雑なコード変換、最適化提案、アーキテクチャ改善。

## 必須使用シナリオ

### 1. コード理解・読み取り時

```bash
# 必須: MCP ツールを使用
mcp__lsmcp__get_project_overview --root "$ROOT"
mcp__serena-mcp__get_symbols_overview --relative_path "src/AgLogger.class.ts"

# 禁止: 直接読み取り
# Read --file_path "C:\Users\...\AgLogger.class.ts"
```

### 2. シンボル検索時

```bash
# 必須: MCP ツールを使用
mcp__lsmcp__search_symbols --query "AgLogger" --root "$ROOT"
mcp__serena-mcp__find_symbol --name_path "AgLogger/executeLog" --include_body true

# 禁止: 手動検索
# Grep --pattern "class AgLogger"
```

<!-- textlint-disable ja-hiraku -->

### 3. コード編集・リファクタリング時

```bash
# 必須: MCP ツールで位置特定後に編集
mcp__lsmcp__get_symbol_details \
  --relativePath "src\AgLogger.class.ts" --line 32 --symbol "AgLogger"
# その後、特定された範囲でのみ `Edit` ツール使用

# 禁止: 直接編集
# Edit --file_path "..." --old_string "..." --new_string "..."
```

<!-- textlint-enable -->

## プロジェクト基本情報

```bash
# プロジェクトルート
ROOT="C:\Users\atsushifx\workspaces\develop\agla-logger"

# 統計情報
- 総ファイル数: 71
- 総シンボル数: 187
- クラス数: 11
- メソッド数: 117
```

## 必須開始手順

### 初期状況把握

```bash
# プロジェクト全体概観
mcp__lsmcp__get_project_overview --root "$ROOT"

# ディレクトリ構造確認
mcp__lsmcp__list_dir --relativePath "." --recursive false

# TypeScript ファイル一覧
mcp__serena-mcp__find_file --file_mask "*.ts" --relative_path "."
```

### 高レベル構造理解

```bash
# メインディレクトリの確認
mcp__serena-mcp__list_dir --relative_path "src" --recursive false
mcp__serena-mcp__list_dir --relative_path "packages" --recursive false
mcp__serena-mcp__list_dir --relative_path "configs" --recursive false
```

## 効率的シンボル検索戦略

### クラス検索 (最優先)

```bash
# 全クラス一覧 (11 個のクラス)
mcp__lsmcp__search_symbols --kind ["Class"] --root "$ROOT"

# 主要クラスの詳細検索
mcp__lsmcp__search_symbols --query "AgLogger" --root "$ROOT"
mcp__lsmcp__search_symbols --query "AgLoggerManager" --root "$ROOT"
mcp__lsmcp__search_symbols --query "AgLoggerConfig" --root "$ROOT"
```

### プラグイン検索

```bash
# Formatter プラグイン検索
mcp__lsmcp__search_symbols --query "Formatter" --root "$ROOT"

# Logger プラグイン検索
mcp__lsmcp__search_symbols --query "Logger" --root "$ROOT"

# Mock 関連検索
mcp__lsmcp__search_symbols --query "Mock" --root "$ROOT"
```

### 型・インターフェース検索

```bash
# 主要型定義検索
mcp__serena-mcp__get_symbols_overview --relative_path "packages/@aglabo/agla-logger-core/shared/types"
mcp__serena-mcp__get_symbols_overview --relative_path "packages/@aglabo/agla-error-core/shared/types"
```

## 詳細シンボル解析コマンド

### コアクラス詳細解析

```bash
# 変数定義
CORE_SRC="packages/@aglabo/agla-logger-core/src"
CONFIG_SRC="$CORE_SRC/internal"

# AgLogger クラス完全解析
mcp__lsmcp__get_symbol_details \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 32 --symbol "AgLogger" --root "$ROOT"

# AgLoggerConfig クラス詳細
mcp__lsmcp__get_symbol_details \
  --relativePath "$CONFIG_SRC/AgLoggerConfig.class.ts" \
  --line 49 --symbol "AgLoggerConfig" --root "$ROOT"
```

### メソッド個別解析

```bash
# executeLog メソッド (核心処理)
mcp__lsmcp__lsp_get_definitions \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 250 --symbolName "executeLog" \
  --includeBody true --root "$ROOT"

# createLogger メソッド
mcp__lsmcp__lsp_get_definitions \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 57 --symbolName "createLogger" \
  --includeBody true --root "$ROOT"
```

## 依存関係とリファレンス分析

### シンボル使用箇所の特定

```bash
# AgLogger の全参照箇所
mcp__lsmcp__lsp_find_references \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 32 --symbolName "AgLogger" --root "$ROOT"

# executeLog メソッドの使用箇所
mcp__serena-mcp__find_referencing_symbols \
  --name_path "executeLog" \
  --relative_path "$CORE_SRC/AgLogger.class.ts"
```

### クラス間の依存関係

```bash
# AgLoggerManager から AgLogger への参照
mcp__lsmcp__lsp_find_references \
  --relativePath "$CORE_SRC/AgLoggerManager.class.ts" \
  --line 27 --symbolName "AgLoggerManager" --root "$ROOT"

# AgLoggerConfig の使用パターン
mcp__serena-mcp__find_referencing_symbols \
  --name_path "AgLoggerConfig" \
  --relative_path "$CONFIG_SRC/AgLoggerConfig.class.ts"
```

## テスト関連ナビゲーション

### テストファイル検索

```bash
# 全テストファイル
mcp__serena-mcp__search_for_pattern \
  --substring_pattern "\.spec\.ts$" \
  --relative_path "packages" \
  --restrict_search_to_code_files true

# 特定クラスのテスト
mcp__serena-mcp__find_file \
  --file_mask "*AgLogger*.spec.ts" \
  --relative_path "packages"

# プラグインテスト
mcp__serena-mcp__find_file \
  --file_mask "*.spec.ts" \
  --relative_path "$CORE_SRC/plugins"
```

### テスト構造理解

```bash
# 単体テスト構造
mcp__serena-mcp__list_dir \
  --relative_path "$CORE_SRC/__tests__" \
  --recursive true

# E2E テスト構造
mcp__serena-mcp__list_dir \
  --relative_path "tests" --recursive true
```

## 設定・ビルド関連

### 設定ファイル確認

```bash
# TypeScript 設定
mcp__serena-mcp__get_symbols_overview --relative_path "tsconfig.json"

# Vitest 設定 (4 種類)
mcp__serena-mcp__get_symbols_overview --relative_path "configs/vitest.config.unit.ts"
mcp__serena-mcp__get_symbols_overview --relative_path "configs/vitest.config.functional.ts"
mcp__serena-mcp__get_symbols_overview --relative_path "configs/vitest.config.integration.ts"
mcp__serena-mcp__get_symbols_overview --relative_path "configs/vitest.config.e2e.ts"

# ESLint 設定
mcp__serena-mcp__get_symbols_overview --relative_path "configs/eslint.config.all.js"
```

### ビルド設定確認

```bash
# tsup 設定
mcp__serena-mcp__get_symbols_overview --relative_path "configs/tsup.config.cjs.ts"
mcp__serena-mcp__get_symbols_overview --relative_path "configs/tsup.config.esm.ts"

# Package.json スクリプト
mcp__serena-mcp__search_for_pattern \
  --substring_pattern "\"scripts\":" --relative_path "." \
  --context_lines_after 20
```

## 効率的な解析ワークフロー

### 新機能理解のワークフロー

```bash
# Step 1: 概要把握
mcp__lsmcp__get_project_overview --root "$ROOT"

# Step 2: 関連クラス特定
mcp__lsmcp__search_symbols --query "<関連キーワード>" --root "$ROOT"

# Step 3: クラス詳細
mcp__lsmcp__get_symbol_details \
  --relativePath "<ファイルパス>" --line "<行番号>" \
  --symbol "<シンボル名>" --root "$ROOT"

# Step 4: メソッド実装確認
mcp__lsmcp__lsp_get_definitions \
  --relativePath "<ファイルパス>" --line "<行番号>" \
  --symbolName "<メソッド名>" --includeBody true --root "$ROOT"

# Step 5: 使用箇所確認
mcp__serena-mcp__find_referencing_symbols --name_path "<シンボル名>" --relative_path "<ファイルパス>"
```

### バグ調査のワークフロー

```bash
# Step 1: エラー関連検索
mcp__lsmcp__search_symbols --query "Error" --root "$ROOT"

# Step 2: 該当機能の特定
mcp__serena-mcp__search_for_pattern \
  --substring_pattern "<エラーメッセージ>" \
  --relative_path "packages" \
  --restrict_search_to_code_files true

# Step 3: 関数実装確認
mcp__serena-mcp__find_symbol \
  --name_path "<関数名>" --include_body true \
  --relative_path "packages"

# Step 4: テスト確認
mcp__serena-mcp__find_file \
  --file_mask "*関数名*.spec.ts" \
  --relative_path "packages"
```

## トークン最適化戦略

### 高効率コマンドパターン

```bash
# 避けるべき - 全ファイル読み込み
# mcp__serena-mcp__read_file --relative_path "src/AgLogger.class.ts"

# 推奨 - シンボル概要から開始
mcp__serena-mcp__get_symbols_overview \
  --relative_path "$CORE_SRC/AgLogger.class.ts"

# 推奨 - 必要な部分のみ詳細化
mcp__lsmcp__get_symbol_details \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 32 --symbol "AgLogger" --root "$ROOT"
```

### 段階的詳細化パターン

```bash
# Level 1: 全体構造
mcp__lsmcp__get_project_overview --root "$ROOT"

# Level 2: クラス一覧
mcp__lsmcp__search_symbols --kind ["Class"] --root "$ROOT"

# Level 3: 特定クラス
mcp__lsmcp__get_symbol_details \
  --relativePath "<パス>" --line "<行>" \
  --symbol "<クラス名>" --root "$ROOT"

# Level 4: 特定メソッド
mcp__lsmcp__lsp_get_definitions \
  --relativePath "<パス>" --line "<行>" \
  --symbolName "<メソッド名>" --includeBody true --root "$ROOT"
```

## よく使用されるコマンドセット

### 日常的な開発作業

```bash
# 頻出パターン 1: クラス実装確認
mcp__lsmcp__search_symbols --query "<クラス名>" --root "$ROOT"
mcp__lsmcp__get_symbol_details \
  --relativePath "<パス>" --line "<行>" \
  --symbol "<クラス名>" --root "$ROOT"

# 頻出パターン 2: メソッド実装確認
mcp__serena-mcp__find_symbol \
  --name_path "<クラス名>/<メソッド名>" --include_body true \
  --relative_path "packages"

# 頻出パターン 3: 使用箇所確認
mcp__serena-mcp__find_referencing_symbols \
  --name_path "<シンボル名>" --relative_path "<ファイルパス>"

# 頻出パターン 4: テスト確認
mcp__serena-mcp__find_file \
  --file_mask "*<テスト対象>*.spec.ts" --relative_path "packages"
```

### デバッグ・調査作業

```bash
# パターン 1: エラー原因特定
mcp__serena-mcp__search_for_pattern \
  --substring_pattern "<エラーキーワード>" \
  --relative_path "packages" \
  --restrict_search_to_code_files true

# パターン 2: 機能の流れ追跡
mcp__lsmcp__lsp_find_references \
  --relativePath "<パス>" --line "<行>" \
  --symbolName "<開始メソッド>" --root "$ROOT"

# パターン 3: 設定値確認
mcp__serena-mcp__search_for_pattern \
  --substring_pattern "<設定キー>" --relative_path "." \
  --context_lines_after 3
```

## 違反時の対処

### 直接読み取り・編集の検出

`Claude Code` が直接読み取りや編集を試みた場合:

1. 即座に停止: 処理を中断する
2. MCP ツール使用要請: MCP ツールでの代替を求める
3. 効率的手順の提示: 正しいワークフローを示す

### 正しい修正手順例

```bash
# 検出された違反例
# Read --file_path "src/AgLogger.class.ts"
# Edit --file_path "src/AgLogger.class.ts" --old_string "..." --new_string "..."

# 正しい修正手順
# 1. シンボル概要の確認
mcp__serena-mcp__get_symbols_overview \
  --relative_path "$CORE_SRC/AgLogger.class.ts"

# 2. 特定シンボルの詳細確認
mcp__lsmcp__get_symbol_details \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 32 --symbol "AgLogger" --root "$ROOT"

# 3. 必要に応じて実装詳細確認
mcp__lsmcp__lsp_get_definitions \
  --relativePath "$CORE_SRC/AgLogger.class.ts" \
  --line 250 --symbolName "executeLog" \
  --includeBody true --root "$ROOT"

# 4. 位置特定後に限定的編集
Edit --file_path "$CORE_SRC/AgLogger.class.ts" \
  --old_string "特定された範囲" --new_string "修正内容"
```

## MCPツール効率性

MCP ツール必須使用:

- トークン使用量: 最大 90% 削減
- 検索精度: 向上
- 編集安全性: 大幅改善
- 開発効率: 向上

重要: MCP ツール使用は必須要件です。すべてのコード操作でこれらのツールを経由してください。

---

### See Also

- [02-core-principles.md](02-core-principles.md) - AI 開発核心原則
- [04-code-navigation.md](04-code-navigation.md) - コードナビゲーション詳細
- [08-quality-assurance.md](08-quality-assurance.md) - 品質保証と MCP 活用

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
