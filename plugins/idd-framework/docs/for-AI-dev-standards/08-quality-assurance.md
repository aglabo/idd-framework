---
header:
  - src: 08-quality-assurance.md
  - @(#): Quality Assurance System
title: claude-idd-framework
description: AIコーディングエージェント用品質ゲート・自動チェックシステム
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

## AI用品質ゲート・自動チェック

このドキュメントは AI コーディングエージェントが agla-logger プロジェクトで実装完了前に実行すべき品質ゲートと自動チェックシステムを定義します。
実装の信頼性と品質確保を目的とします。

## 必須品質ゲート

### 5項目必須チェック

🔴 必須: 実装完了前の 5 項目チェック実行。
🔴 必須: エラー・警告がある場合は修正まで完了。

```bash
# 5項目品質チェック (必須順序)
1. pnpm run check:types    # 型安全性確認
2. pnpm run lint:all       # コード品質確認
3. pnpm run check:dprint   # フォーマット確認
4. pnpm run test:develop   # 基本テスト確認
5. pnpm run build          # ビルド成功確認
```

### 品質ゲート実行原則

- エラー・警告が解決されるまで次のステップに進まない
- 自動修正可能な問題は修正コマンドを実行
- 修正不可能な問題は詳細分析・手動対応

## 詳細チェック手順

### 1. 型チェック (最優先)

```bash
# TypeScript型エラー確認
pnpm run check:types

# 成功例
✓ Type check completed successfully

# エラー時の対応
mcp__lsmcp__lsp_get_diagnostics --relativePath "<エラーファイル>" --root "$ROOT"
```

#### 型エラー解決戦略

- 型定義の不整合確認
- インポート・エクスポートの確認
- 型アサーション・型ガードの適用
- 汎用型パラメータの調整

### 2. コード品質チェック

```bash
# ESLint実行
pnpm run lint:all

# 自動修正実行
pnpm run lint:all -- --fix
```

#### リント問題対応

- 自動修正優先実行
- 手動修正が必要な警告の解決
- リントルールから除外した場合は、理由を記述

### 3. フォーマットチェック

```bash
# dprint フォーマット確認
pnpm run check:dprint

# 自動フォーマット適用
pnpm run format
```

### 4. テスト実行

```bash
# 基本テスト実行
pnpm run test:develop

# テスト失敗時の詳細確認
pnpm run test:develop -- --reporter=verbose
```

#### テスト失敗対応

- 失敗原因の分析
- テストケース・実装の修正
- モック・スタブ設定の分析

### 5. ビルド確認

```bash
# プロダクションビルド実行
pnpm run build

# ビルドエラー時の確認
pnpm run build 2>&1 | head -20
```

## 自動品質保証 (`lefthook`)

### Pre-commit フック

```yaml
# .lefthook.yml 設定例
pre-commit:
  commands:
    format-check:
      run: pnpm run check:dprint
    type-check:
      run: pnpm run check:types
    lint-check:
      run: pnpm run lint:all
    test-check:
      run: pnpm run test:develop
    build-check:
      run: pnpm run build
```

### フック実行フロー

```bash
1. フォーマット確認 → 自動修正 → 再確認
2. 型チェック → エラー修正 → 再確認
3. リント確認 → 自動修正 → 再確認
4. テスト実行 → 失敗修正 → 再確認
5. ビルド確認 → エラー修正 → 再確認
```

## 品質ゲート実行パターン

### 段階的実行

```bash
# 基本品質確認
pnpm run check:types      # 1. 型安全性確認
pnpm run lint:all         # 2. コード品質確認
pnpm run check:dprint     # 3. フォーマット確認

# テスト・ビルド確認
pnpm run test:develop     # 4. 基本テスト確認
pnpm run build            # 5. ビルド成功確認
```

### 自動修正付き実行

```bash
# 修正可能な問題の自動対応
pnpm run lint:all -- --fix     # 自動修正可能な問題
pnpm run format                 # フォーマット自動適用
```

### 一括ステータス確認

```bash
# 全項目ステータス確認
pnpm run check:types && echo "OK: TypeScript" || echo "NG: TypeScript"
pnpm run lint:all && echo "OK: ESLint" || echo "NG: ESLint"
pnpm run check:dprint && echo "OK: Format" || echo "NG: Format"
pnpm run test:develop && echo "OK: Tests" || echo "NG: Tests"
pnpm run build && echo "OK: Build" || echo "NG: Build"
```

## エラー解決戦略

### TypeScript型エラー

```bash
# 診断情報取得
pnpm run check:types      # 型エラー特定

# LSP活用詳細調査
mcp__lsmcp__lsp_get_diagnostics --relativePath "<対象ファイル>" --root "$ROOT"
mcp__lsmcp__lsp_get_hover --textTarget "<エラー箇所>" --relativePath "<対象ファイル>"
```

### `ESLint` 警告・エラー

```bash
# リント実行・修正
pnpm run lint:all
pnpm run build
```

### テスト失敗

```bash
# 個別テストファイル実行
pnpm run test:develop -- <test/target.test.ts>

# テスト詳細・デバッグ
pnpm run test:develop -- --reporter=verbose --bail
```

### ビルドエラー

```bash
# 依存関係確認
pnpm install

# 型定義確認
pnpm run check:types

# 段階的ビルド
pnpm run build:clean && pnpm run build
```

## 品質メトリクス

### 必須達成基準

- 型エラー: `0` 件
- ESLint エラー: `0` 件
- テスト失敗: `0` 件
- ビルドエラー: `0` 件
- フォーマット違反: `0` 件

### 許容基準

- `ESLint` 警告: 新規追加分のみ (既存は維持)
- テストカバレッジ: 新規コードで低下させない
- ビルド時間: 大幅な増加なし

## `MCP` ツール連携品質確認

### 実装影響範囲確認

```bash
# 変更シンボルの参照確認
mcp__serena-mcp__find_referencing_symbols --name_path "<変更シンボル>" --relative_path "<変更ファイル>"

# 依存関係確認
mcp__lsmcp__lsp_find_references --symbolName "<変更シンボル>" --relativePath "<変更ファイル>"
```

### 型安全性詳細確認

```bash
# 型情報確認
mcp__lsmcp__lsp_get_hover --textTarget "<型名>" --relativePath "<対象ファイル>"

# 型定義確認
mcp__lsmcp__lsp_get_definitions --symbolName "<型名>" --relativePath "<対象ファイル>"
```

## 完了基準

### ONLY mark a task as completed when you have FULLY accomplished it

- テストがすべて成功している
- 実装が完了している
- エラー・警告が解決されている
- 必要なファイル・依存関係が存在している

### 未完了時の対応

- エラー・ブロッカー・部分実装の場合は in_progress を維持
- ブロック時は新しいタスクで解決事項を記述
- 失敗・エラー時は原因分析と修正

---

### See Also

- [02-core-principles.md](02-core-principles.md) - AI 開発核心原則
- [05-bdd-workflow.md](05-bdd-workflow.md) - BDD 開発フロー詳細
- [03-mcp-tools-usage.md](03-mcp-tools-usage.md) - MCP ツール完全ガイド

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
