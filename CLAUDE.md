# CLAUDE.md — GSS Mode Effects Pipeline

This file is the authoritative reference for Claude Code working on this project.
Read it fully before making any changes.

---

## Project Overview

Academic paper: **"Mode Effects and Temporal Continuity in the General Social Survey:
Mode-Specific Weights for 2022 and 2024"**
Authors: Resty Fufunan, Jeremy Freese, Olivia Jin
Target venue: SocArXiv preprint

The pipeline constructs mode-specific post-stratification weights (`wtssps_f2fp`,
`wtssps_web`) for the face-to-face/phone and web subsamples of the 2022 and 2024 GSS,
and analyzes mode differences across attitudinal items relative to a 2016–2018
historical baseline.

---

## Repository Structure

```
gss-mode-weights/
├── CLAUDE.md                        # this file
├── README.md
├── LICENSE                          # MIT
├── .gitignore                       # must cover gss7224_r2.dta and all large data
├── renv.lock                        # run renv::init() + renv::snapshot() to generate
│
├── data/
│   ├── README.md
│   ├── analytic_core.csv            # authoritative variable registry (195 rows)
│   ├── gss20222024_modeweights.dta  # output of 02_weights.qmd
│   └── [gss7224_r2.dta]             # raw data — gitignored, never committed
│
├── outputs/
│   ├── figures/
│   │   ├── by_domain/               # per-domain forest plots
│   │   ├── fig01_sample_sizes.png
│   │   ├── fig02_demographic_composition.png
│   │   ├── fig03_mode_gaps_scatter.png
│   │   ├── fig05_domain_distances.png
│   │   ├── fig06_violin_baseline_distance.png
│   │   └── fig08_forest_racial_attitudes.png
│   ├── tables/
│   │   └── table01_logistic_shapley.png
│   └── data/
│       ├── mode_gaps_comparison.csv
│       ├── gss_glm_mode_bivariate_22_24.csv
│       ├── gss_glm_mode_with_controls_22_24.csv
│       ├── forest_plot_data.csv
│       ├── closeness_by_variable.csv
│       ├── exemplar_variables.csv
│       └── domain_variable_lookup.csv
│
├── 00_setup.R                       # sourced by all QMDs
├── 01_data_preparation.qmd          # recodes → gss_data_16to24_r2.rds
├── 02_weights.qmd                   # raking → gss20222024_modeweights.dta
├── 03_composition.qmd               # §1 figures (Fig 1, Fig 2)
├── 04_mode_gaps.qmd                 # §2 outputs (Table 1, Fig 3)
├── 05_persistence.qmd               # §4 outputs (Fig 5, Fig 6, Fig 8, Appendix)
├── appendix_forest_plots.qmd        # reads forest_plot_data.csv; may need creation
├── _quarto.yml                      # needs creation
└── run_all.R                        # needs creation (or Makefile)
```

---

## Render Order

Files must be rendered in this sequence — each depends on outputs from prior steps:

1. `01_data_preparation.qmd` → writes `data/gss_data_16to24_r2.rds`
2. `02_weights.qmd` → writes `data/gss20222024_modeweights.dta`
3. `03_composition.qmd` → reads `data/gss7224_r2.dta`
4. `04_mode_gaps.qmd` → reads `data/gss_data_16to24_r2.rds`
5. `05_persistence.qmd` → reads both RDS and weights DTA; writes `outputs/data/forest_plot_data.csv`
6. `appendix_forest_plots.qmd` → reads `outputs/data/forest_plot_data.csv`

---

## Key File: `00_setup.R`

Sourced at the top of every QMD. Defines:

- **Libraries**: `tidyverse`, `haven`, `survey`, `VIM`
- **Random seed**: `set.seed(94305)` — required for reproducibility of `hotdeck()` imputation in `02_weights.qmd`
- **File path constants**:
  - `GSS_DTA_PATH  <- "data/gss7224_r2.dta"`
  - `GSS_RDS_PATH  <- "data/gss_data_16to24_r2.rds"`
  - `WEIGHTS_PATH  <- "data/gss20222024_modeweights.dta"`
- **`recode_demographics(df)`**: canonical demographic recode function applied in `04`
  and `05`. Produces: `mode_fctr`, `agegrp`, `degree_cat`, `marital_cat`,
  `w_hisp_race`, `f_born`, `f_sex`, `f_region`
- **`ANALYTIC_CORE_VARS`**: reads `data/analytic_core.csv`, filters `analytic_core == 1`,
  returns vector of `c_`-prefixed variable names (137 items)
- **`MODE_COLORS`**: named color palette for plots

Never redefine these constants or re-source libraries in individual QMDs.

---

## Key File: `data/analytic_core.csv`

**The authoritative variable registry.** 195 rows, 6 columns:

| Column | Description |
|--------|-------------|
| `variable` | GSS variable name (uppercase, no `c_` prefix) |
| `domain` | One of 8 final domains (see below) |
| `source_topic` | Original GSS topic label |
| `analytic_core` | 1 = included, 0 = excluded |
| `exclusion_reason` | Reason code for excluded vars (blank if included) |
| `notes` | Additional context |

**137 core variables** (analytic_core == 1). **58 excluded** under 6 reason codes:

| Code | N | Meaning |
|------|---|---------|
| `not_fielded_all_years` | 39 | Absent from 2016, 2018, or both baseline years |
| `excluded_voting_items` | 6 | Electoral/voting variables |
| `excluded_not_attitude_item` | 4 | Internet/tech use — also mode-confounded |
| `wording_experiment_variant` | 4 | Split-ballot variant or wording discontinuity |
| `excluded_survey_quality` | 3 | Survey process indicators (svyid1/2, svyenjoy) |
| `conditionally_fielded` | 2 | hapmar, hapcohab — structural skip confounded with mode |

**The 8 final domains** (used in `05_persistence.qmd` as `domain_order`):
```r
domain_order <- c(
  "Religion",
  "Race & Inequality",
  "Civil Liberties & Government",
  "Crime, Punishment & Firearms",
  "Political & Economic Orientations",
  "Social Attitudes & Morality",
  "Institutional Confidence",
  "Well-being & Life Orientations"
)
```

`domain_order` must be defined in `05_persistence.qmd` **before** it is used in the
topic-mapping chunk. It was previously inside the `domain_remap` tribble block that
was deleted — verify it is still present and placed correctly.

---

## Variable Naming Conventions

- Raw GSS variables: lowercase (e.g., `natspac`, `racdif1`)
- Binary recoded variables: `c_` prefix (e.g., `c_natspac`, `c_racdif1`)
- Raking/demographic variables in `02`: `w_` prefix (e.g., `w_hisp_race`, `w_agegroup`)
- Survey mode: `mode_fctr` (factor, levels `c("f2fp", "web")`); `mode_bin` (0/1 integer)

**"FTF/Phone"** — always written as "FTF/Phone" in prose and labels, never "FTF" alone.

---

## Race/Ethnicity Variable

`w_hisp_race` is an 8-category factor used consistently across all regression
controls and raking:

```
Hispanic | White (NH) | Black (NH) | AI/AN | Asian | NH/PI | Other | Multiple
```

Built from `hispanic` (1=Not Hispanic, 2–5=Hispanic), `racecen1`, and `racecen2`.
Defined identically in `recode_demographics()` (`00_setup.R`), `02_weights.qmd`
(numeric codes 1–8 for raking), and `03_composition.qmd` (labeled strings for plots).

---

## Survey Weights

| Weight | Used in | Purpose |
|--------|---------|---------|
| `wtssps` | `03`, `04`, `05` (baseline + full sample) | Standard GSS post-stratification weight |
| `wtssps_f2fp` | `05` (FTF/Phone subsample only) | Mode-specific weight from `02_weights.qmd` |
| `wtssps_web` | `05` (Web subsample only) | Mode-specific weight from `02_weights.qmd` |

**Important**: In `04_mode_gaps.qmd` Section 1 (logistic predicting mode), the model
is intentionally **unweighted**. Weighting by `wtssps` when mode is the outcome
variable is circular. This is correct behavior — add a comment if one is missing.

---

## Output Format Rules

This project uses Quarto with a specific rendering philosophy:

- **Never use `cat()`, `sprintf()`, or `print()` to generate rendered output** in QMD
  chunks unless the chunk has `#| results: 'asis'`. These are side-effect functions
  and will not render correctly in Quarto's engine-aware mode.
- **Return objects directly**: data frames, ggplot objects, gt tables.
- **Use `knitr::kable()` or `gt()`** for tabular output.
- **Diagnostic summaries** (counts, proportions) should be `kable()` tables,
  not `cat()`/`sprintf()` strings.
- Each QMD sources `00_setup.R` and then loads only file-specific libraries not
  already covered by setup (e.g., `broom`, `gt`, `dominanceanalysis`).
- No redundant `library(tidyverse)` or `library(haven)` calls in individual QMDs.

---

## Known Issues / Pending Tasks

### Must fix before render
- [ ] Verify `domain_order` is defined in `05_persistence.qmd` before the
  topic-mapping chunk uses it (likely missing after refactor)
- [ ] Audit all six QMDs for remaining `cat()`/`print()`/`sprintf()` calls
  not inside `results: 'asis'` chunks
- [ ] Check for any remaining hardcoded file paths (should use `GSS_DTA_PATH`,
  `GSS_RDS_PATH`, `WEIGHTS_PATH` from `00_setup.R`)

### Needs creation
- [ ] `_quarto.yml` — project file defining render order and shared HTML format defaults
- [ ] `run_all.R` or `Makefile` — machine-enforced render order
- [ ] `appendix_forest_plots.qmd` — verify exists and reads from
  `outputs/data/forest_plot_data.csv`; create if missing

### Repository
- [ ] `renv::init()` + `renv::snapshot()` — run after all files render cleanly
- [ ] Confirm `.gitignore` covers `gss7224_r2.dta`, `*.dta`, `gss_data_16to24_r2.rds`
- [ ] Uniform YAML front matter across all QMDs (no author field in any of them)

### Replication deposit (SocArXiv)
- [ ] Finalize and validate four-CSV schema for deposit
- [ ] Generate deposit CSVs from pipeline outputs

---

## What NOT to Do

- Do not modify `data/analytic_core.csv` without updating the notes in this file.
- Do not add variables back to the analytic core without confirming they are fielded
  in all four analysis years (2016, 2018, 2022, 2024).
- Do not add `c_racdif5`, `c_hapmar`, `c_hapcohab`, `c_marsame`, `c_svyid1/2`,
  `c_svyenjoy`, or any voting item to `ANALYTIC_CORE_VARS` — all have documented
  exclusion reasons in `analytic_core.csv`.
- Do not reintroduce `EXCLUDED_VARS` — it has been fully replaced by `analytic_core.csv`.
- Do not use `str_subset("^c_") %>% setdiff(EXCLUDED_VARS)` anywhere — use
  `ANALYTIC_CORE_VARS` from `00_setup.R`.
- Do not commit `gss7224_r2.dta` or `gss_data_16to24_r2.rds` to the repository.
