---
header:
  - src: document-template.md
  - @(#): Document Template
title: agla-logger
description: ドキュメント作成用統一テンプレート
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

## ドキュメント作成統一テンプレート

このテンプレートは agla-logger プロジェクトのドキュメント作成で使用する統一フォーマットです。
textlint 準拠の品質基準を満たし、プロジェクト共通のスタイルを保証します。

## 基本テンプレート

### フロントマター (必須)

```markdown
---
header:
  - src: [ファイル名.md]
  - @(#): [セクション名・機能概要]
title: [ドキュメントタイトル]
description: [ドキュメントの目的・概要説明]
version: 1.0.0
created: [YYYY-MM-DD]
authors:
  - atsushifx
changes:
  - [YYYY-MM-DD]: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

### メインコンテンツ構造

```markdown
## [メインタイトル]

[ドキュメントの目的と対象読者を明確に記述]

### 必要要件 (技術文書の場合)

- Node.js: v20 以上 (ESM サポートのため)
- ランタイム対応:
  - Node.js: 完全対応 (v20+)
  - Deno: 対応済み (ESM-first 設計)
  - Bun: 対応済み (高速ビルド)
- パッケージマネージャ:
  - pnpm 推奨 (プロジェクト標準)
  - npm/yarn 対応済み
- TypeScript: v5.0 以上推奨

### 目次 (複数セクションがある場合)

1. [セクション1](01-section.md)
   - サブトピック1
   - サブトピック2

2. [セクション2](02-section.md)
   - サブトピック1
   - サブトピック2

3. [セクション3](03-section.md)
   - サブトピック1
   - サブトピック2

---

### See Also (関連文書がある場合)

- [関連ドキュメント1](../category1/) - 説明
- [関連ドキュメント2](../category2/) - 説明
- [関連ドキュメント3](../category3/) - 説明

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
```

## テンプレート種類別サンプル

### 1. 入門ガイド用テンプレート

```markdown
## [機能名] Getting Started

この[機能名]は[対象読者]のための[目的]です。
順に読めば、[学習内容]を短時間で習得できます。

### 必要要件

- Node.js: v20 以上 (ESM サポートのため)
- ランタイム対応:
  - Node.js: 完全対応 (v20+)
  - Deno: 対応済み (ESM-first 設計)
  - Bun: 対応済み (高速ビルド)
- パッケージマネージャ:
  - pnpm 推奨 (プロジェクト標準)
  - npm/yarn 対応済み
- TypeScript: v5.0 以上推奨

### クイックスタート

'''bash

- インストール

pnpm add @aglabo/agla-logger-core

- 基本的な使用方法

npm start
'''

### 学習パス

1. [基本概念](01-concepts.md)
2. [インストール](02-install.md)
3. [基本的な使い方](03-basic-usage.md)
4. [応用例](04-examples.md)
5. [トラブルシューティング](05-troubleshooting.md)
```

### 2. 技術リファレンス用テンプレート

```markdown
## [システム名] リファレンス

この文書は[システム名]の技術仕様・API・設計思想を詳述します。
開発者向けの包括的なリファレンスガイドです。

### アーキテクチャ概要

'''typescript
// 基本的な使用例
interface Example {
property: string;
}
'''

### API リファレンス

#### `className.methodName()`

概要:[メソッドの目的・機能]。

パラメーター:

- `param1: string` - パラメーター説明
- `param2: number` - パラメーター説明

戻り値: `ReturnType` - 戻り値説明。

使用例:

'''typescript
const result = className.methodName('example', 42);
'''
```

### 3. 開発ルール用テンプレート

```markdown
## [ルール名] 開発ルール

この文書は[対象範囲]での[ルール目的]を定義します。
すべての開発者が遵守すべき必須ルールです。

### 基本原則

1. 原則1: 詳細説明
2. 原則2: 詳細説明
3. 原則3: 詳細説明

### 必須チェックリスト

- [ ] チェック項目1
- [ ] チェック項目2
- [ ] チェック項目3

### 禁止事項

❌ 禁止: 具体的な禁止事項
✅ 推奨: 代替手段・推奨方法

### 実装例

'''typescript
// 良い例
const goodExample = () => {
// 推奨実装
};

// 悪い例
const badExample = () => {
// 非推奨実装
};
'''
```

## 使用ガイドライン

### 1. テンプレート選択指針

- 入門・ガイド系: 入門ガイド用テンプレート
- API・技術仕様: 技術リファレンス用テンプレート
- 開発ルール・規約: 開発ルール用テンプレート
- その他・汎用: 基本テンプレート

### 2. 必須要件セクション使い分け

#### 技術文書 (API・開発ガイド)

上記の完全な要件リスト使用。

#### 概念・説明文書

```markdown
### 前提知識

- TypeScript の基本的な理解
- ログシステムの概念
- プラグインパターンの理解
```

#### ルール・ガイドライン文書

```markdown
### 適用範囲

- 対象プロジェクト: agla-logger 全体
- 対象開発者: すべてのコントリビューター
- 対象フェーズ: 設計・実装・テスト
```

### 3. フロントマター記入例

#### header.@(#) の記入例

- `Getting Started` - 入門ガイド
- `Development Workflow` - 開発手順
- `Plugin System` - プラグインシステム
- `Type System Reference` - 型システムリファレンス
- `API Reference` - API リファレンス
- `Coding Standards` - コーディング規約

#### description の記入例

- `agla-logger を初めて利用する開発者のための入門ガイド`
- `BDD開発フローと実装手順の詳細ガイド`
- `プラグインシステムの設計と実装方法`
- `TypeScript型システムの包括的リファレンス`

### 4. See Also セクション

#### プロジェクト内リンク優先順位

1. **直接関連**: 同一カテゴリ・関連機能
2. **参考情報**: 背景知識・詳細情報
3. **上位概念**: 全体アーキテクチャ・概要

#### リンク記述例

```markdown
- [プロジェクト概要](../projects/00-project-overview.md) - 全体アーキテクチャ
- [開発ワークフロー](../rules/01-development-workflow.md) - 実装手順
- [品質保証システム](../rules/03-quality-assurance.md) - テスト戦略
```

## 品質チェックポイント

### textlint 準拠確認

```bash
# テンプレート使用後の必須チェック
pnpm run lint:text          # textlint エラーチェック
pnpm run lint:markdown      # markdownlint チェック
pnpm run check:dprint       # フォーマットチェック
```

### 主要チェック項目

- [ ] フロントマター形式正確性
- [ ] `@(#)` 記法の適切性
- [ ] 必要要件セクションの適切性
- [ ] See Also リンクの有効性
- [ ] ライセンス表記の統一性

---

### See Also

- [フロントマターガイド](frontmatter-guide.md): フロントマター詳細ルール
- [執筆ルール](writing-rules.md): Claude 向け執筆禁則事項

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
