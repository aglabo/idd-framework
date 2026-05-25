---
 Copyright (c) 2025 atsushifx <http://github.com/atsushifx>

 This software is released under the MIT License.
 https://opensource.org/licenses/MIT---
header:
  - src: 02-core-principles.md
  - @(#): AI Development Core Principles
title: claude-idd-framework
description: AIコーディングエージェント向け開発の核心原則とMCP必須ルール
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

## AI開発核心原則

このドキュメントは AI コーディングエージェントが agla-logger プロジェクトで開発する際の核心原則と MCP 必須ルールを定義します。
すべての開発作業で厳格に遵守してください。

## 必須遵守事項

### MCPツール活用の必須化

- 必須: すべての開発段階で MCP ツール (lsmcp, serena-mcp) を積極活用
- 必須: ファイル編集前の既存パターン調査・理解
- 必須: 実装後の影響範囲確認・整合性チェック

#### 必須使用場面

- コード理解: 既存コード構造の把握
- パターン調査: 実装パターンの研究
- 影響範囲分析: 変更の影響確認
- 依存関係確認: ライブラリ・モジュールの使用状況確認
- テスト戦略立案: 既存テストパターンの研究

### BDD開発プロセスの厳格遵守

- 必須: Red-Green-Refactor サイクルの段階的実行。
- 必須: 1 message = 1 test の原則を守る。
- 必須: 3階層 BDD 構造 (Given/Feature → When → Then) の遵守。

#### BDDサイクル実行手順

```text
1. RED: 失敗するテスト作成
   ↓
2. GREEN: テスト通過する最小実装
   ↓
3. REFACTOR: コード品質向上
   ↓
4. 次のテストで繰り返し
```

### 品質ゲートの確実な実行

- 必須: 実装完了前の 5 項目チェック実行
- 必須: 型チェック・テスト・リント・フォーマット・ビルドの確認
- 必須: エラー・警告がある場合は修正まで完了

#### 5項目品質チェック

```bash
1. pnpm run check:types    # 型安全性確認
2. pnpm run lint:all       # コード品質確認
3. pnpm run check:dprint   # フォーマット確認
4. pnpm run test:develop   # 基本テスト確認
5. pnpm run build          # ビルド成功確認
```

## 段階的開発アプローチ

### 推奨実装フロー

```text
1. 既存コード理解 → MCP ツールで構造・パターン分析
2. テスト作成 → 既存テストパターンを参考に BDD 構造で記述
3. 最小実装 → テスト通過に必要な最小限のコード実装
4. リファクタリング → コード品質向上・パフォーマンス改善
5. 影響範囲確認 → MCP ツールで参照先・依存関係チェック
```

### MCPツール活用パターン

#### 作業開始時の理解フェーズ

```bash
mcp__lsmcp__get_project_overview --root "$ROOT"
mcp__lsmcp__search_symbols --query "対象機能" --root "$ROOT"
```

#### 実装中の調査フェーズ

```bash
mcp__serena-mcp__find_symbol --name_path "関連シンボル" --include_body true
mcp__serena-mcp__search_for_pattern --substring_pattern "パターン" --relative_path "src"
```

#### 完了前の確認フェーズ

```bash
mcp__serena-mcp__find_referencing_symbols --name_path "変更シンボル" --relative_path "ファイル"
mcp__lsmcp__lsp_get_diagnostics --relativePath "ファイル" --root "$ROOT"
```

## エラー処理・品質確保

### 必須対応項目

- TypeScript 型エラーの完全解決
- テスト失敗時の原因分析・修正
- リント警告の修正またはルール除外理由の明記
- 実装変更時の既存機能への影響確認

### セキュリティプラクティス

- セキュリティベストプラクティス: 常時遵守
- 秘匿情報排除: シークレット・キーの露出・ログ出力禁止
- コミット安全性: シークレット・キーのリポジトリコミット禁止

## ファイル編集制限

### 編集禁止ディレクトリ

- `lib/` - ビルド出力
- `module/` - ESM ビルド出力
- `maps/` - ソースマップ
- `.cache/` - キャッシュ
- `node_modules/` - 依存関係

### 編集対象ディレクトリ

- `src/` - ソースコード
- `configs/` - 設定ファイル
- `__tests__/` - テストファイル
- `tests/` - テストスイート

## プロジェクト理解の必須事項

### 基本情報

- プロジェクト: agla-logger - TypeScript 用軽量・プラガブルロガー
- アーキテクチャ: pnpm ワークスペース使用のモノレポ
- 現在フォーカス: AglaError フレームワークへの移行

### 技術スタック

- ESM-first + CommonJS 互換性
- デュアルビルド: `lib/` (CJS), `module/` (ESM)
- TypeScript 厳格モード + 包括的型定義
- 4層テスト戦略: Unit/Functional/Integration/E2E

### パッケージ構成

```bash
packages/@aglabo/
├── agla-logger-core/  # 構造化ロガーパッケージ
└── agla-error-core/   # エラーハンドリングフレームワーク
```

## タスク完了の基準

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

- [05-bdd-workflow.md](05-bdd-workflow.md) - BDD 開発フロー詳細
- [10-bdd-implementation-details.md](10-bdd-implementation-details.md) - atsushifx 式 BDD 実装ガイド詳細
- [03-mcp-tools-usage.md](03-mcp-tools-usage.md) - MCP ツール完全ガイド
- [08-quality-assurance.md](08-quality-assurance.md) - 品質ゲート詳細

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
