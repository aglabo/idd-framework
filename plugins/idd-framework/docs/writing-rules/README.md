---
header:
  - src: README.md
  - @(#): Documentation Writing Guidelines
title: agla-logger
description: ドキュメント作成・執筆ガイドライン集約ディレクトリ
version: 1.0.0
created: 2025-09-19
authors:
  - atsushifx
changes:
  - 2025-09-19: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## ドキュメント作成ガイドライン

このディレクトリは agla-logger プロジェクトのドキュメント作成で使用するガイドライン・ルール・テンプレートを集約しています。
統一された品質基準と textlint 準拠により、プロジェクト全体のドキュメント品質を保証します。

### 必要要件

- textlint: プロジェクト設定済み
- markdownlint: 品質チェック対応
- dprint: フォーマッター統一
- 基本知識: Markdown 記法・YAML フロントマター

### ガイドライン一覧

#### ドキュメントテンプレート

[ドキュメントテンプレート](document-template.md) では以下を提供します。

- 統一フォーマット・基本構造
- フロントマター・メインコンテンツ形式
- 実用的なサンプルコード

#### フロントマターガイド

[フロントマターガイド](frontmatter-guide.md) では以下を説明します。

- `@(#)` 記法の詳細説明
- description・title の記入例
- プロジェクト固有ルール

#### ライティングルールズ

[ライティングルールズ](writing-rules.md) に従って、文章を記述します。

- 箇条書き+強調表現の禁止
- '()'は、半角括でそろえる
- あいまいな書き方の禁止

### 品質チェックコマンド

```bash
# ドキュメント品質チェック (必須)
pnpm run lint:text          # textlint チェック
pnpm run lint:markdown      # markdownlint チェック
pnpm run check:dprint       # フォーマットチェック

# ドキュメント修正
pnpm run format:dprint      # 自動フォーマット
```

### 使用ワークフロー

#### 新規ドキュメント作成時

1. [document-template.md](document-template.md) を参照
2. 目的に応じたテンプレートを選択・コピー
3. [frontmatter-guide.md](frontmatter-guide.md) でフロントマター記入
4. [naming-conventions.md](naming-conventions.md) でファイル名決定
5. 品質チェックコマンドで検証

#### 既存ドキュメント改善時

1. フロントマター形式の標準化
2. 品質チェックコマンドでエラー解消

### ドキュメント分類・配置ルール

```bash
docs/
├── getting-started/     # 入門・導入ガイド
├── projects/           # プロジェクト概要・技術情報
├── rules/              # 開発ルール・ガイドライン
└── writing/            # ドキュメント作成ルール (このディレクトリ)
```

### 品質基準

- textlint 準拠: エラー 0 件必須
- markdownlint 準拠: 統一された形式
- プロジェクト統一: `@(#)` 記法・MIT ライセンス
- 読みやすさ: 明確で理解しやすい見出し階層・箇条書き

---

### See Also

- [プロジェクト概要](../projects/00-project-overview.md) - 全体アーキテクチャ
- [開発ワークフロー](../rules/01-development-workflow.md) - 開発手順
- [品質保証システム](../rules/03-quality-assurance.md) - 品質管理

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
