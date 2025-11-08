# Repository Guidelines

## Project Structure & Module Organization
Keep the repo flat and readable: `README.md` documents the tutorial narrative, `scripts/` stores reproducible helpers such as `capture_outputs.R`, and `outputs/` is reserved for generated CSVs and plots. Add new datasets under `outputs/` only when they can be regenerated from code; otherwise document the source inline or in `README.md`. When expanding the tutorial, prefer new R scripts or notebooks inside `scripts/` so learners can discover runnable examples in one place.

## Build, Test, and Development Commands
- `Rscript scripts/capture_outputs.R`: recreates all example model summaries and saves them under `outputs/`. Run after any change that affects the walkthrough to keep artifacts fresh.
- `Rscript -e "styler::style_dir()"`: optional formatting pass before opening a PR.
- `Rscript -e "devtools::load_all()"`: quick sanity check that added functions (if any) compile without attaching a package.

## Coding Style & Naming Conventions
Follow tidyverse style: two-space indentation, `<-` for assignment, and snake_case for objects (`model_glm`, `tidy_parsnip`). Keep lines under ~100 chars and favor pipelines over deeply nested function calls. When committing literate examples, show runnable chunks (no pseudocode) and annotate intent with concise comments. Use `styler` or `lintr` locally if you touch more than a handful of lines.

## Testing Guidelines
The tutorial currently relies on deterministic scripts rather than automated tests. If you add logic that benefits from regression coverage, scaffold `tests/testthat/` and add files named `test-<topic>.R`. Run them with `Rscript -e "testthat::test_dir('tests/testthat')"` and include expected fixture data in `outputs/` only when necessary. Document any non-determinism (e.g., random seeds) near the test.

## Commit & Pull Request Guidelines
Match the existing imperative style (`Add broom tutorial and sample outputs`). Keep commits scoped to one idea and mention the affected area up front (e.g., “Update capture script for glm example”). PRs should summarize the learner-facing impact, list testing commands you ran, reference related issues, and include screenshots or sample CSV diffs when visual or tabular outputs change.

## Outputs & Reproducibility
Never edit files under `outputs/` by hand; regenerate them via scripts so reviewers can rerun the exact command. If you add new artifacts, note their purpose in `README.md` and ensure they remain lightweight (≤1 MB) to keep the repo accessible to newcomers cloning over slow connections.
