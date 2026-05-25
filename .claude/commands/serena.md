---
# Claude Code 必須要素
allowed-tools: Read, Glob, Grep, Edit, MultiEdit, Write, Bash, TodoWrite, mcp__serena__check_onboarding_performed, mcp__serena__delete_memory, mcp__serena__find_file, mcp__serena__find_referencing_symbols, mcp__serena__find_symbol, mcp__serena__get_symbols_overview, mcp__serena__insert_after_symbol, mcp__serena__insert_before_symbol, mcp__serena__list_dir, mcp__serena__list_memories, mcp__serena__onboarding, mcp__serena__read_memory, mcp__serena__remove_project, mcp__serena__replace_regex, mcp__serena__replace_symbol_body, mcp__serena__restart_language_server, mcp__serena__search_for_pattern, mcp__serena__switch_modes, mcp__serena__think_about_collected_information, mcp__serena__think_about_task_adherence, mcp__serena__think_about_whether_you_are_done, mcp__serena__write_memory, mcp__context7__resolve-library-id, mcp__context7__get-library-docs
argument-hint: <problem> [options]
description: serena-mcp を活用した構造化アプリ開発・問題解決コマンド

# ユーザー管理ヘッダー
title: serena
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

## Quick Reference

```bash
/serena <problem> [options]           # 基本使用法
/serena debug "memory leak in prod"   # デバッグパターン (5-8 思考)
/serena design "auth system"          # 設計パターン (8-12 思考)
/serena review "optimize this code"   # レビューパターン (4-7 思考)
/serena implement "add feature X"     # 実装パターン (6-10 思考)
```

## Options

| オプション | 説明                        | 使用例                              | 使用場面                         |
| ---------- | --------------------------- | ----------------------------------- | -------------------------------- |
| `-q`       | クイックモード (3-5 思考)   | `/serena "fix button" -q`           | 簡単なバグ・軽微な機能           |
| `-d`       | ディープモード (10-15 思考) | `/serena "architecture design" -d`  | 複雑なシステム・重要な意思決定   |
| `-c`       | コード重視分析              | `/serena "optimize performance" -c` | コードレビュー・リファクタリング |
| `-s`       | ステップバイステップ実装    | `/serena "build dashboard" -s`      | フル機能開発                     |
| `-v`       | 詳細出力 (プロセス表示)     | `/serena "debug issue" -v`          | 学習・プロセス理解               |
| `-r`       | リサーチフェーズ含む        | `/serena "choose framework" -r`     | 技術選定                         |
| `-t`       | 実装 TODO 作成              | `/serena "new feature" -t`          | プロジェクト管理                 |

## 使用パターン

### 基本的な使用法

```bash
# シンプルな問題解決
/serena "fix login bug"

# クイック機能実装
/serena "add search filter" -q

# コード最適化
/serena "improve load time" -c
```

### 高度な使用法

```bash
# 複雑なシステム設計とリサーチ
/serena "design microservices architecture" -d -r -v

# フル機能開発と TODO 作成
/serena "implement user dashboard with charts" -s -t -c

# 詳細分析とドキュメント作成
/serena "migrate to new framework" -d -r -v --focus=frontend
```

## コンテキスト (自動収集)

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

- プロジェクトファイル: `find . -maxdepth 2 -type f \( -name "*.config.*" -o -name "*rc" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) | head -5 2>/dev/null || echo "No config files"`
- Git ステータス: `git status --porcelain 2>/dev/null | head -3 || echo "Not git repo"`

<!-- markdownlint-enable -->
<!-- textlint-enable -->

## コアワークフロー

### 1. 問題検出とテンプレート選択

キーワードに基づく思考パターンの自動選択。

<!-- textlint-disable ja-technical-writing/max-comma -->

- デバッグ: error, bug, issue, broken, failing → 5-8 思考
- 設計: architecture, system, structure, plan → 8-12 思考
- 実装: build, create, add, feature → 6-10 思考
- 最適化: performance, slow, improve, refactor → 4-7 思考
- レビュー: analyze, check, evaluate → 4-7 思考

<!-- textlint-enable -->

### 2. MCP 選択と実行

```text
アプリ開発タスク → serena-mcp
- コンポーネント実装
- API 開発
- 機能構築
- システムアーキテクチャ

すべてのタスク → serena-mcp
- コンポーネント実装
- API 開発
- 機能構築
- システムアーキテクチャ
- 問題解決と分析
```

### 3. 出力モード

- デフォルト: 重要な洞察 + 推奨アクション
- 詳細 (-v): 思考プロセス表示
- 実装 (-s): TODO 作成 + 実行開始

## 問題特有テンプレート

### デバッグパターン (5-8 思考)

1. 症状分析と再現
2. エラーコンテキストと環境確認
3. 根本原因仮説生成
4. 証拠収集と検証
5. 解決策設計とリスク評価
6. 実装計画
7. 検証戦略
8. 予防策

### 設計パターン (8-12 思考)

1. 要件明確化
2. 制約と前提条件
3. ステークホルダー分析
4. アーキテクチャオプション生成
5. オプション評価 (長所・短所)
6. 技術選定
7. 設計決定とトレードオフ
8. 実装フェーズ
9. リスク軽減
10. 成功指標
11. 検証計画
12. ドキュメント要件

### 実装パターン (6-10 思考)

1. 機能仕様とスコープ
2. 技術アプローチ選択
3. コンポーネント・モジュール設計
4. 依存関係と統合ポイント
5. 実装シーケンス
6. テスト戦略
7. エッジケース処理
8. パフォーマンス考慮事項
9. エラーハンドリングと復旧
10. デプロイとロールバック計画

### レビュー・最適化パターン (4-7 思考)

1. 現状分析
2. ボトルネック特定
3. 改善機会
4. 解決策オプションと実現可能性
5. 実装優先度
6. パフォーマンス影響推定
7. 検証・監視計画

## 高度なオプション

思考制御:

- `--max-thoughts=N`: デフォルト思考数の上書き
- `--focus=AREA`: ドメイン特有分析 (frontend, backend, database, security)
- `--token-budget=N`: トークン制限での最適化

統合:

- `-r`: Context7 リサーチフェーズ含む
- `-t`: 実装 TODO 作成
- `--context=FILES`: 特定ファイルの優先分析

出力:

- `--summary`: 要約のみ出力
- `--json`: 自動化向け構造化出力
- `--progressive`: 要約優先、詳細は要求時

## タスク実行

serena-mcp を主に使用するエキスパートアプリ開発者・問題解決者として、各リクエストに対して次のように対応します。

1. 問題タイプの自動検出とアプローチ選択 (問題キーワードに基づく)
2. serena-mcp 使用:
   - すべての開発タスク: [serena-mcp ツール](https://github.com/oraios/serena) 使用
   - 分析・デバッグ・実装: serena のセマンティックコードツール活用
3. 選択した MCP による構造化アプローチ実行
4. Context7 MCP による関連ドキュメントリサーチ (必要時)
5. 具体的な次のステップを含む実行可能解決策の統合
6. `-s` フラグ使用時の実装 TODO 作成

主要ガイドライン:

- プライマリ: すべてのタスクで serena-mcp ツール使用 (コンポーネント・API・機能・分析)
- 活用: serena のセマンティックコード取得・編集機能
- 問題分析から開始し、具体的なアクションで終了
- 深度とトークン効率のバランス
- 常に具体的で実行可能な推奨事項提供
- セキュリティ・パフォーマンス・保守性を考慮

トークン効率化のヒント:

- シンプルな問題には `-q` 使用 (約 40% トークン節約)
- 概要のみ必要な場合は `--summary` 使用
- 関連問題を単一セッションで組み合わせ
- 無関係な分析を避けるため `--focus` 使用

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
