# 初心者向け broom チュートリアル

[broom.tidymodels.org](https://broom.tidymodels.org/) を参考に、R で統計モデルの結果を「整然（tidy）データ」に変換し、分析パイプラインへスムーズに流し込むための入門チュートリアルです。R と tidyverse の基本操作を把握している読者を想定しています。

## 1. broom とは？

- **目的**: モデルオブジェクトを tibble 形式へ変換し、`dplyr` や `ggplot2` など tidyverse ツールと自然に連携させる。
- **3 つの動詞**
  - `tidy(model)`: 係数や検定結果を 1 行 1 パラメータで返す。
  - `augment(model, data = ...)`: 元データに予測値や残差を付け足す。
  - `glance(model)`: モデル全体の指標（R²、AIC など）を 1 行で返す。
- **対応範囲**: base R の `lm`, `glm` から `parsnip`, `rstanarm`, `survival` まで幅広い。詳細は公式サイトの Model list を参照。

## 2. 事前準備

```r
install.packages(c("broom", "tidyverse", "tidymodels"))
```

```r
library(broom)
library(tidyverse)
library(tidymodels)
```

- チュートリアルでは組み込みデータ `mtcars` を利用します（`?mtcars` で説明を参照）。

## 3. 基本フロー：線形回帰モデル

```r
model_lm <- lm(mpg ~ wt + cyl, data = mtcars)

tidy(model_lm)
```

- 返り値の主な列
  - `term`: 変数名（切片は `(Intercept)`）
  - `estimate`: 推定係数
  - `std.error`, `statistic`, `p.value`: 検定統計量

```r
augment(model_lm)
```

- 元データ（32 行）に `fitted`, `resid`, `hat`, `.cooksd` などが追加される。
- `augment(model_lm, newdata = tibble(wt = 3, cyl = 6))` のように新データで予測も可能。

```r
glance(model_lm)
```

- `r.squared`, `adj.r.squared`, `sigma`, `AIC`, `BIC` などモデルサマリが 1 行で得られる。

## 4. 可視化との連携

```r
augment(model_lm) %>%
  ggplot(aes(x = fitted, y = resid)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = 2) +
  labs(title = "残差 vs 予測値", x = "予測値", y = "残差")
```

- `augment()` の出力は tidy データなので `ggplot2` でそのまま可視化できる。

## 5. ロジスティック回帰の例

```r
mtcars_vs <- mtcars %>%
  mutate(am = factor(am, labels = c("auto", "manual")))

model_glm <- glm(am ~ mpg + hp, data = mtcars_vs, family = binomial())

tidy(model_glm, exponentiate = TRUE, conf.int = TRUE)
```

- `exponentiate = TRUE` でオッズ比、`conf.int = TRUE` で信頼区間を同時に計算。
- ロジスティック回帰などリンク関数つきモデルは、このオプションが便利。

## 6. グループ別モデルを一括処理

```r
models_by_cyl <-
  mtcars %>%
  group_by(cyl) %>%
  nest() %>%
  mutate(
    model = map(data, ~ lm(mpg ~ wt, data = .x)),
    tidied = map(model, tidy),
    glanced = map(model, glance)
  )

models_by_cyl %>%
  select(cyl, tidied) %>%
  unnest(tidied)
```

- `nest()` + `map()` + `tidy()` で複数モデルを同じフォーマットに揃えられる。
- `unnest(glanced)` でシリンダー別の R²・AIC を比較する表が得られる。

## 7. tidymodels との組み合わせ

tidymodels パッケージ群で作成した `parsnip` モデルにも broom メソッドが用意されています。

```r
linear_spec <- linear_reg() %>%
  set_engine("lm")

linear_fit <- linear_spec %>%
  fit(mpg ~ wt + cyl, data = mtcars)

tidy(linear_fit)
augment(linear_fit, new_data = head(mtcars, 5))
```

- `fit()` の戻り値にも `tidy/augment/glance` を直接適用できる。
- レシピやワークフローで前処理を施していても、最終モデルから tidy な結果を取得可能。

## 8. よくある落とし穴とヒント

- **サポート状況確認**: 一部の新しいモデルは未対応のことがある。公式サイトの「Model list」で確認し、未対応の場合は `broom.helpers` など拡張パッケージを検討。
- **巨大モデ ルの出力**: `augment()` は元データと同じ行数を返すため、大規模データでは `sample_n()` や `head()` で絞って確認する。
- **再現性**: `augment()` で予測を保存するときは、使用したモデル・データ・パラメータを同じスクリプト内にまとめて記録しておく。

## 9. サンプル出力の取得

チュートリアル中の主要コードブロックを実行し、代表的な出力を `outputs/` ディレクトリに保存するスクリプトを用意しました。

```bash
Rscript scripts/capture_outputs.R
```

- 保存されるファイル例:
  - `outputs/lm_tidy.csv`: 線形回帰 `tidy()` の結果
  - `outputs/lm_glance.csv`: `glance()` のモデルサマリ
  - `outputs/lm_residual_plot.png`: `augment()` から作成した残差 vs 予測値プロット
  - `outputs/glm_tidy.csv`: ロジスティック回帰のオッズ比と信頼区間
  - `outputs/grouped_lm_tidy.csv`: シリンダー別線形モデルの係数一覧
  - `outputs/tidymodels_linear_tidy.csv`: `parsnip` モデルに対する `tidy()` 出力

ロジスティック回帰では `mtcars` の小標本ゆえに「fitted probabilities numerically 0 or 1 occurred」という警告が出ますが、サンプル出力の内容には影響ありません。

## 10. 次のステップ

1. 手持ちデータで別の回帰・分類モデルを作成し、`tidy/augment/glance` の出力を比較する。
2. `broom.mixed`, `broom.helpers` など関連パッケージで混合効果モデルや複雑な出力を扱う。
3. 公式サイトの「Get started」セクションを読み、ここで触れなかったメソッド（`augment_columns()` など）も試してみる。

---

さらに詳しい情報は公式ドキュメント [broom.tidymodels.org](https://broom.tidymodels.org/) を参照してください。
