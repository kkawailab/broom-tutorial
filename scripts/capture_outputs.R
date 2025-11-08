suppressPackageStartupMessages({
  library(broom)
  library(tidyverse)
  library(tidymodels)
})

dir_create <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
}

dir_create("outputs")

# 3. Linear model outputs
model_lm <- lm(mpg ~ wt + cyl, data = mtcars)
tidy_lm <- tidy(model_lm)
glance_lm <- glance(model_lm)
augment_lm <- augment(model_lm)

write_csv(tidy_lm, "outputs/lm_tidy.csv")
write_csv(glance_lm, "outputs/lm_glance.csv")

plot_resid <- augment_lm %>%
  ggplot(aes(x = .fitted, y = .resid)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = 2) +
  labs(
    title = "残差 vs 予測値",
    x = "予測値 (.fitted)",
    y = "残差 (.resid)"
  )

ggsave(
  filename = "outputs/lm_residual_plot.png",
  plot = plot_resid,
  width = 5,
  height = 4,
  dpi = 300
)

# 5. Logistic regression output
mtcars_vs <- mtcars %>%
  mutate(am = factor(am, labels = c("auto", "manual")))

model_glm <- glm(am ~ mpg + hp, data = mtcars_vs, family = binomial())
tidy_glm <- tidy(model_glm, exponentiate = TRUE, conf.int = TRUE)
write_csv(tidy_glm, "outputs/glm_tidy.csv")

# 6. Grouped models
models_by_cyl <- mtcars %>%
  group_by(cyl) %>%
  nest() %>%
  mutate(
    model = map(data, ~ lm(mpg ~ wt, data = .x)),
    tidied = map(model, tidy),
    glanced = map(model, glance)
  )

grouped_tidied <- models_by_cyl %>%
  select(cyl, tidied) %>%
  unnest(tidied)

write_csv(grouped_tidied, "outputs/grouped_lm_tidy.csv")

# 7. tidymodels example
linear_spec <- linear_reg() %>%
  set_engine("lm")

linear_fit <- linear_spec %>%
  fit(mpg ~ wt + cyl, data = mtcars)

tidy_parsnip <- tidy(linear_fit)
write_csv(tidy_parsnip, "outputs/tidymodels_linear_tidy.csv")

augment_parsnip <- augment(linear_fit, new_data = head(mtcars, 5))
write_csv(augment_parsnip, "outputs/tidymodels_linear_augment_head.csv")

message("Outputs saved to the outputs/ directory.")
