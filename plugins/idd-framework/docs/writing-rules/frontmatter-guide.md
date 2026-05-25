---
header:
  - src: frontmatter-guide.md
  - @(#): Frontmatter Guide
title: agla-logger
description: YAML フロントマター記入詳細ガイド
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

## フロントマター記入ガイド

この文書は agla-logger プロジェクトの YAML フロントマターの記入方法を詳述します。
統一された形式により、ドキュメントのメタデータ管理と品質保証を実現します。

## 基本構造

### 完全フォーマット

```yaml
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
  - [YYYY-MM-DD]: [変更内容記述]
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

## フィールド詳細ガイド

<!-- markdownlint-disable no-duplicate-heading -->

### 1. header セクション

#### src フィールド

用途: ファイル名の明示的記録。

形式: `ファイル名.md`

```yaml
header:
  - src: README.md
  - src: 01-install.md
  - src: plugin-system.md
```

#### @(#) フィールド (プロジェクト固有)

用途: セクション名・機能概要の簡潔な表現。

形式: 英語またはカタカナで簡潔に。

記入例:

```yaml
# 入門・ガイド系
- @(#): Getting Started
- @(#): Quick Start Guide
- @(#): Installation Guide

# 技術リファレンス系
- @(#): Plugin System
- @(#): Type System Reference
- @(#): API Reference

# 開発ルール系
- @(#): Development Workflow
- @(#): Coding Standards
- @(#): Quality Assurance

# ドキュメント・メタ系
- @(#): Document Template
- @(#): Writing Guidelines
```

### 2. title フィールド

用途: ドキュメントのメインタイトル。

標準値: `agla-logger` (プロジェクト統一)

```yaml
title: agla-logger
```

例外ケース (特別な理由がある場合のみ):

```yaml
title: "agla-logger: [特別な副題]"
```

### 3. description フィールド

用途: ドキュメントの目的・対象読者・内容概要。

形式: 日本語で 1-2 文、具体的でわかりやすく。

#### 記入パターン

#### 入門ガイド系

```yaml
description: agla-logger を初めて利用する開発者のための入門ガイド
description: プラグインシステムを初めて使う開発者向けの導入手順
```

#### 技術リファレンス系

```yaml
description: TypeScript型システムの包括的リファレンス
description: プラグインシステムの設計と実装方法
description: AglaError フレームワークの技術仕様詳細
```

#### 開発ルール系

```yaml
description: BDD開発フローと実装手順の詳細ガイド
description: コーディング規約とベストプラクティス集
description: 多層品質保証システムの運用ルール
```

#### ドキュメント・メタ系

```yaml
description: ドキュメント作成用統一テンプレート
description: YAML フロントマター記入詳細ガイド
description: textlint 準拠の品質基準とルール
```

### 4. version フィールド

標準値: `1.0.0` (セマンティックバージョニング)

更新ルール:

- 1.x.y: メジャー変更 (構造・内容の大幅変更)
- x.1.y: マイナー変更 (セクション追加・大幅改訂)
- x.y.1: パッチ変更 (誤字修正・小幅改善)

```yaml
version: 1.0.0 # 初版
version: 1.1.0 # セクション追加
version: 1.0.1 # 誤字修正
version: 2.0.0 # 全面改訂
```

### 5. created フィールド

形式: `YYYY-MM-DD` (ISO 8601 準拠)

用途: ドキュメント初回作成日。

```yaml
created: 2025-09-19
```

### 6. authors フィールド

標準値: `atsushifx` (プロジェクト統一)

複数著者の場合:

```yaml
authors:
  - atsushifx
  - contributor1
```

### 7. changes フィールド

用途: 変更履歴の記録。

形式: `- YYYY-MM-DD: 変更内容記述`

#### 記録ルール

#### 初版作成

```yaml
changes:
  - 2025-09-19: 初版作成
```

#### 更新履歴

```yaml
changes:
  - 2025-09-19: 初版作成
  - 2025-09-20: API リファレンスセクション追加
  - 2025-09-21: 使用例とトラブルシューティング拡充
  - 2025-09-22: textlint 準拠のため表現修正
```

#### 変更内容記述例

#### 追加系

- `[セクション名]セクション追加`
- `API リファレンス詳細追加`
- `使用例とサンプルコード拡充`

#### 修正系

- `textlint 準拠のため表現修正`
- `markdownlint 対応のため形式統一`
- `リンク切れ修正と URL 更新`

#### 改善系

- `構造改善と可読性向上`
- `品質チェックポイント整理`
- `ガイドライン明確化`

### 8. copyright セクション

標準フォーマット (固定値):

```yaml
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
```

注意: 年度は作成時点で固定、後から変更不要。

## 文書種別フロントマター例

### 入門ガイド系

```yaml
---
header:
  - src: README.md
  - @(#): Getting Started
title: agla-logger
description: agla-logger を初めて利用する開発者のための入門ガイド
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
```

### 技術リファレンス系

```yaml
---
header:
  - src: plugin-system.md
  - @(#): Plugin System
title: agla-logger
description: プラグインシステムの設計と実装方法
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
```

### 開発ルール系

```yaml
---
header:
  - src: 01-development-workflow.md
  - @(#): Development Workflow
title: agla-logger
description: BDD開発フローと実装手順の詳細ガイド
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
```

<!-- markdownlint-enable -->

## 品質チェックポイント

### 必須確認項目

- [ ] YAML 構文正確性: インデント・コロン・ハイフン
- [ ] src フィールド: ファイル名との一致
- [ ] @(#) フィールド: 明確で具体的な機能概要表現
- [ ] description: 具体的でわかりやすい説明
- [ ] created: 正確な作成日 (YYYY-MM-DD 形式)
- [ ] copyright: 標準フォーマット使用

### よくある間違い

#### YAML 構文エラー

❌ 間違い:

```yaml
header:
  - src: README.md # インデント不足
  - @(#) Getting Started # コロン不足
```

**正しいパターン**:

```yaml
header:
  - src: README.md
  - @(#): Getting Started
```

#### description の問題

❌ 間違い:

```yaml
description: ドキュメント # 抽象的すぎる
description: agla-logger の説明です。 # 冗長
```

**正しいパターン**:

```yaml
description: agla-logger を初めて利用する開発者のための入門ガイド
```

#### changes の問題

❌ 間違い:

```yaml
changes:
  - 初版作成 # 日付なし
  - 2025/09/19: 更新 # 形式違い
```

**正しいパターン**:

```yaml
changes:
  - 2025-09-19: 初版作成
  - 2025-09-20: API リファレンスセクション追加
```

## ツール支援

### 自動チェック

```bash
# フロントマター形式チェック
pnpm run lint:docs          # プロジェクト固有チェック
pnpm run lint:markdown      # markdownlint チェック
```

### 手動チェック手順

1. **YAML パーサー確認**: オンライン YAML バリデーター使用
2. **フィールド完全性**: 必須フィールドの存在確認
3. **形式一貫性**: 他ドキュメントとの比較
4. **内容妥当性**: description とコンテンツの一致確認

---

### See Also

- [ドキュメントテンプレート](document-template.md): 基本構造とテンプレート
- [執筆ルール](writing-rules.md): Claude 向け執筆禁則事項

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
