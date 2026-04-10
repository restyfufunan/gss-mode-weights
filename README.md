# gss-mode-weights

Replication code for:

> Fufunan, R., Jin, O., & Freese, J. "Mode Effects and Temporal Continuity in the General Social Survey: Mode-Specific Weights for 2022 and 2024." SocArXiv. [link forthcoming]

## Overview

The GSS transitioned to multimode data collection in 2022, combining face-to-face/phone (FTF/Phone) and web administration. This repository provides code to:

1. Construct **mode-specific post-stratification weights** for the 2022 and 2024 GSS waves, enabling researchers to analyze FTF/Phone and web respondents separately.
2. Document **demographic composition differences** between modes.
3. Estimate **mode gaps** in substantive survey responses before and after demographic adjustment.
4. Assess **temporal continuity** — how closely mode-specific estimates track the 2016–2018 pre-multimode baseline.

## Repository Structure

```
gss-mode-weights/
├── 00_setup.R                    # Shared constants, file paths, demographic recode function
├── 01_data_preparation.qmd       # Variable binarization and recode; exports analysis RDS
├── 02_weights.qmd                # Mode-specific post-stratification weights via raking
├── 03_composition.qmd            # Demographic composition by mode
├── 04_mode_gaps.qmd              # Bivariate and adjusted mode gaps
├── 05_persistence.qmd            # Comparison to 2016–2018 baseline
├── appendix_forest_plots.qmd     # Standalone appendix forest plot regeneration
├── data/
│   └── README.md                 # Data download instructions
└── outputs/
    ├── figures/                  # Generated figures (.png)
    ├── tables/                   # Generated tables (.png)
    └── data/                     # Intermediate data files (.csv)
```

## Data

This repository does not include GSS data files, which cannot be redistributed. To replicate the analysis:

1. Download the **GSS Cumulative Data File (1972–2024), Release 2** from the NORC GSS website:  
   [https://gss.norc.org/get-the-data/stata](https://gss.norc.org/get-the-data/stata)
2. Place the `.dta` file in the `data/` directory and name it `gss7224_r3.dta`.
3. The file path is defined in `00_setup.R` as `GSS_DTA_PATH`.

## Requirements

All analysis is conducted in **R** using **Quarto** (`.qmd`) documents.

### R Packages

```r
install.packages(c(
  "tidyverse",
  "haven",
  "survey",
  "VIM",
  "broom",
  "gt",
  "dominanceanalysis",
  "scales"
))
```

### Software

- R ≥ 4.3.0
- Quarto ≥ 1.4
- RStudio (recommended) or VS Code with Quarto extension

## Replication

To replicate the analysis, run all files in order via Quarto:

```bash
quarto render
```

This will execute files in the sequence defined in `_quarto.yml`:

| Step | File | Input | Output |
|------|------|-------|--------|
| 1 | `01_data_preparation.qmd` | `gss7224_r3.dta` | `data/gss_data_16to24_r3.rds` |
| 2 | `02_weights.qmd` | RDS (01) | `data/gss20222024_modeweights.dta` |
| 3 | `03_composition.qmd` | RDS (01) | Sample sizes and demographic composition plots |
| 4 | `04_mode_gaps.qmd` | RDS (01), weights (02) | Mode gaps regression table and scatter plot |
| 5 | `05_persistence.qmd` | RDS (01), weights (02) | Forest plots and distance distribution analyses |
| 6 | `appendix_forest_plots.qmd` | CSVs (05) | Appendix figures |

**Data dependency note**: Only `01_data_preparation.qmd` requires the raw `.dta` file. All downstream files read the RDS output from step 1, making the pipeline efficient and avoiding repeated loading of the large GSS file.

## Key Methodological Notes

### Demographic Recoding & Raking Variables

All demographic variables are canonically recoded in `00_setup.R` via the `recode_demographics()` function, which produces standardized factor variables used throughout the pipeline (04_mode_gaps.qmd, 05_persistence.qmd). The recoding scheme is as follows:

| Variable | Categories | R Codes |
|----------|-----------|---------|
| **Age** (`agegrp`) | 5-level | 18–29, 30–39, 40–49, 50–64, 65+ (top-coded at 89) |
| **Education** (`degree_cat`) | 3-level | Less than High School (0), High School (1–2), Bachelor's or More (3–4) |
| **Sex** (`f_sex`) | 2-level | Male (1), Female (2) |
| **Marital Status** (`marital_cat`) | 2-level | Married (1), Not Married (2–5: widowed, divorced, separated, never married) |
| **Nativity** (`f_born`) | 2-level | Born in US (1), Born Outside the US (2) |
| **Region** (`f_region`) | 4-level | Northeast (1), Midwest (2), South (3), West (4) |
| **Race/Ethnicity** (`w_hisp_race`) | 8-level | Hispanic (`hispanic %in% 2:5`); Non-Hispanic White Alone (`racecen1==1`); Non-Hispanic Black Alone (`racecen1==2`); Non-Hispanic AIAN Alone (`racecen1==3`); Non-Hispanic Asian Alone (`racecen1 %in% 4–10`); Non-Hispanic NHPI Alone (`racecen1==14`); Non-Hispanic Other Race Alone (`racecen1 %in% 15–16`); Non-Hispanic Multiple Races (`!is.na(racecen2)`) |

For **raking** (IPF) in `02_weights.qmd`, numeric codes are used instead of factor labels: binary variables (0/1), 3-level education (1–3), 4-level age (1–5 for the age bins), 4-level region, and 8-level race (1–8 ordered as above). The numeric cutpoints are identical to the canonical recoding to ensure consistency between raking margins and regression controls.

### Mode-Specific Weights & Regression Controls

- **Mode-specific weights** are constructed by raking each mode subsample independently to the full-sample `wtssps`-weighted marginals on these seven demographic dimensions.
- **Regression controls** use the same canonical demographic variables as the raking procedure, ensuring consistency between the weighting and modeling stages.
- **Outcome variables**: 143 binarized attitudinal items spanning 8 thematic domains (Religion; Race & Inequality; Civil Liberties & Government; Crime, Punishment & Firearms; Political & Economic Orientations; Social Attitudes & Morality; Institutional Confidence; Well-being & Life Orientations). Items are selected in `data/gss24_attitudes_opinions.csv` and must meet three criteria: (1) fielded in all four analysis years (2016, 2018, 2022, 2024); (2) substantive attitude items, excluding internet/technology use variables that are themselves mode-confounded; and (3) not conditionally fielded via skip patterns confounded with mode. Binarization and recoding are performed in `01_data_preparation.qmd`.
- **Multiple comparison correction**: Holm-Bonferroni correction is applied to mode effect p-values across all outcome variables.

## Citation

If you use these weights or replication code, please cite the paper above and this repository:

> Fufunan, R., Jin, O., & Freese, J. (2026). gss-mode-weights [Software]. GitHub. https://github.com/restyfufunan/gss-mode-weights

## License

Code: [MIT License](LICENSE)  
Paper: CC-BY 4.0
