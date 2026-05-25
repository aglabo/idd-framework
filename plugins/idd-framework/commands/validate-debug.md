---
# Claude Code 必須要素
name: validate-debug
allowed-tools: Bash(pnpm:*), Read(*), Write(*), Edit(*)
argument-hint: ""
description: 6 段階包括的品質検証・デバッグワークフローコマンド

# ユーザー管理ヘッダー
title: validate-debug
version: 0.6.0
created: 2025-09-28
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-09-28: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## コマンドOverview

コード品質・テスト・型安全性を包括的に検証するワークフロー。

## Workflow Phases

### Phase 1: Code Quality

プロジェクトのコーディング規約準拠とコード品質を検証:

- ESLint によるコード解析
- TypeScript ESLint による型安全性チェック
- エラー時の対応:
  - Linter 出力を解析してエラー分類
  - 自動修正可能な項目を処理
  - 残りの問題に対して修正案を提示

### Phase 2: Testing

複数レベルのテスト実行で機能と品質を保証:

- ユニットテスト: 個別関数・モジュールの単体テスト
- 機能テスト: 機能単位の動作検証
- 統合テスト: コンポーネント間の連携テスト
- E2E テスト: エンドツーエンドの動作検証
- エラー時の対応:
  - テスト出力を読み取り失敗テストを特定
  - エラーメッセージを解析
  - 一般的な問題 (import・型・async/await・モック) をチェック
  - 具体的な修正案を提示

### Phase 3: Type Checking

TypeScript コンパイラによる型安全性検証:

- 型定義の完全性チェック
- 型推論の検証
- エラー時の対応:
  - TypeScript コンパイラエラーを解析
  - 型不足・import 問題・型不一致を特定
  - 各エラーに対する具体的な修正案を提示

### Phase 4: Content Validation

ドキュメント・コメント・文字列のスペルチェック:

- コード内の文字列検証
- ドキュメントファイルの検証
- エラー時の対応:
  - スペルミスした単語をリスト化
  - 修正候補を提示
  - 辞書への追加要否を確認

### Phase 5: Filename Validation

ファイル命名規則の準拠確認:

- プロジェクト固有の命名規則チェック
- エラー時の対応:
  - 不正なファイル名をリスト化
  - 修正候補を提示
  - 命名規則への適合要否を確認

### Phase 6: Formatting

コードフォーマットの統一性検証:

- フォーマッター (dprint/Prettier 等) による検証
- エラー時の対応:
  - 自動フォーマット実行
  - 再チェックを実行

## Error Analysis Protocol

For each failed command:

1. Capture and parse error output
2. Identify error patterns and root causes
3. Cross-reference with codebase to understand context
4. Provide specific, actionable fix recommendations
5. Offer to implement fixes automatically where safe
6. Track all issues in a summary report

## Final Report

- Passed steps
- Failed steps with detailed analysis
- Suggested fixes (manual and automatic)
- Overall health score

<!-- markdownlint-disable no-duplicate-heading -->

---

## ag-logger プロジェクトでの実装例

### Phase 1: Code Quality

```bash
pnpm run lint         # ESLint code analysis
pnpm run lint:types   # TypeScript ESLint analysis
```

### Phase 2: Testing

```bash
pnpm run test:develop     # 単体／開発テスト
pnpm run test:functional  # 機能テスト
pnpm run test:ci          # CI (インテグレーション) テスト
pnpm run test:e2e         # E2E テスト
```

Note: `/shared/` パッケージ (定数・型定義のみ) では node_modules 不足・テストファイル不足が予想されます。これは正常であり、エラーとして報告すべきではありません。

### Phase 3: Type Checking

```bash
pnpm run check:types  # TypeScript compiler validation
```

### Phase 4: Content Validation

```bash
pnpm run check:spells "**/*.{js,ts,json,md}"  # Spell checking
```

### Phase 5: Filename Validation

```bash
pnpm run lint:filenames  # Filename lint
```

### Phase 6: Formatting

```bash
pnpm run check:dprint   # Code formatting validation
pnpm run format:dprint  # Auto-format (エラー時に自動実行)
```

### See Also

- [開発ワークフロー](../docs/rules/01-development-workflow.md) - BDD 開発プロセス詳細
- [品質保証システム](../docs/rules/03-quality-assurance.md) - 品質ゲート・テスト戦略
- [コマンドリファレンス](../docs/projects/07-command-reference.md) - 開発コマンド一覧

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
