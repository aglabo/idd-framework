---
header:
  - src: template-method.md
  - @(#): Method Template
title: メソッドリファレンス統一テンプレート
description: APIドキュメント用メソッド記述形式テンプレート
version: 1.0.0
created: 2025-01-26
authors:
  - atsushifx
changes:
  - 2025-01-26: 初版作成 - docs/api-reference/01-core-api.md の記述形式を標準化
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## メソッドリファレンス統一テンプレート

このテンプレートは、ag-logger プロジェクトの API ドキュメントでメソッドを記述する際の統一形式です。

## テンプレート形式

### 1. メソッド名 (見出しレベル 4)

```markdown
#### ClassName.methodName()
```

### 2. 概要説明

メソッドの目的と動作を 1-2行で簡潔に説明する。

### 3. シグネチャ情報

```markdown
- シグネチャ: `methodSignature`
  - パラメーター
    `parameter: Type` - パラメーター説明
    `optional?: Type` - オプションパラメーター説明 (省略可)
  - 戻り値
    `ReturnType` - 戻り値の説明
```

### 4. サンプルコード

```markdown
- サンプルコード:

  '''typescript
  // コメント付きのサンプルコード
  const result = instance.methodName(parameter);
  '''
```

## 具体例

### 通常のメソッド

```markdown
#### AgLogger.info()

情報レベルのログを出力する。

- シグネチャ: `(...args: Unknown[]): void`
  - パラメーター
    `...args: Unknown[]` - ログ出力する任意の引数
  - 戻り値
    `void`

- サンプルコード:

  '''typescript
  // 基本的なログ出力
  logger.info('ユーザーがログインしました');

  // 構造化ログ
  logger.info('処理完了', { userId: 123, duration: '2.3s' });
  '''
```

### Getter/Setter プロパティ

```markdown
#### AgLogger.logLevel

現在のログレベルを取得または設定する。

- シグネチャ (Getter): `get logLevel(): AgLogLevel`
  - パラメーター: なし
  - 戻り値
    `AgLogLevel` - 現在のログレベル

- シグネチャ (Setter): `set logLevel(level: AgLogLevel)`
  - パラメーター
    `level: AgLogLevel` - 設定するログレベル
  - 戻り値
    `void`

- サンプルコード:

  '''typescript
  // ログレベル設定
  logger.logLevel = AG_LOGLEVEL.DEBUG;

  // 現在のログレベル確認
  console.log(`Current level: ${logger.logLevel}`);
  '''
```

### 静的メソッド

```markdown
#### ClassName.staticMethod()

静的メソッドの説明。

- シグネチャ: `(parameter: Type): ReturnType`
  - パラメーター
    `parameter: Type` - パラメーター説明
  - 戻り値
    `ReturnType` - 戻り値説明

- サンプルコード:

  '''typescript
  const result = ClassName.staticMethod(value);
  '''
```

## 記述ルール

### 必須要素

1. **メソッド名**: `#### ClassName.methodName()` 形式
2. **概要説明**: 1-2行の簡潔な説明
3. **シグネチャ情報**: パラメーター・戻り値を含む完全なシグネチャ
4. **サンプルコード**: 実用的な使用例

### パラメーター記述

- 必須パラメーター: `paramName: Type - 説明`
- オプションパラメーター: `paramName?: Type - 説明 (省略可)`
- 可変長パラメーター: `...args: Type[]`
- パラメーターなし: `なし`

### 戻り値記述

- 戻り値あり: `ReturnType - 戻り値の説明`
- 戻り値なし: `void`

### サンプルコード

- TypeScript 形式で記述
- 実用的な例を含める
- 曖昧な部分、追加の記述が必要な部分などにコメントを追加
- 複数パターンがある場合は複数例を提示

### 特殊ケース

#### オーバーロードメソッド

```markdown
#### ClassName.overloadedMethod()

オーバーロードされたメソッドの説明。

- シグネチャ1: `(param1: Type1): ReturnType1`
- シグネチャ2: `(param1: Type1, param2: Type2): ReturnType2`
  - パラメーター
    `param1: Type1` - 共通パラメーター
    `param2?: Type2` - オプションパラメーター (シグネチャ2のみ)
  - 戻り値
    `ReturnType1 | ReturnType2` - 使用したシグネチャに応じた戻り値
```

#### プロパティ (読み取り専用)

```markdown
#### ClassName.readonlyProperty

読み取り専用プロパティの説明。

- シグネチャ: `get readonlyProperty(): PropertyType`
  - パラメーター: なし
  - 戻り値
    `PropertyType` - プロパティの説明
```

## 参考例

完全な記述例は [docs/api-reference/01-core-api.md](../api-reference/01-core-api.md) を参照してください。

## See Also

- [ドキュメントテンプレート](document-template.md): 基本構造とテンプレート
- [執筆ルール](writing-rules.md): Claude 向け執筆禁則事項
- [フロントマターガイド](frontmatter-guide.md): フロントマター詳細ルール

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
