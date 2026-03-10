# gss-mode-weights

Replication code for:

> Fufunan, R., Freese, J., & Jin, O. "Mode Effects and Temporal Continuity in the General Social Survey: Mode-Specific Weights for 2022 and 2024." SocArXiv. [link forthcoming]

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
2. Place the `.dta` file in the `data/` directory and name it `gss7224_r2.dta`.
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

| Step | File | Output |
|------|------|--------|
| 1 | `01_data_preparation.qmd` | `data/gss_data_16to24_r2.rds` |
| 2 | `02_weights.qmd` | `data/gss20222024_modeweights.dta` |
| 3 | `03_composition.qmd` | Sample sizes and demographic composition plots |
| 4 | `04_mode_gaps.qmd` | Mode gaps regression table and scatter plot |
| 5 | `05_persistence.qmd` | Forest plots and distance distribution analyses |
| 6 | `appendix_forest_plots.qmd` | Appendix figures (reads CSVs from step 5) |

All files source `00_setup.R` and depend on outputs from prior steps.

## Key Methodological Notes

- **Mode-specific weights** are constructed by raking each mode subsample independently to the full-sample `wtssps`-weighted marginals on seven demographic dimensions: age, sex, education, marital status, nativity, region, and race/ethnicity (8-category Hispanic + Census race classification).
- **Regression controls** use the same 8-category race/ethnicity variable (`w_hisp_race`) as the raking procedure, ensuring consistency between the weighting and modeling stages.
- **Outcome variables**: 137 binarized attitudinal items spanning 8 thematic domains (Religion; Race & Inequality; Civil Liberties & Government; Crime, Punishment & Firearms; Political & Economic Orientations; Social Attitudes & Morality; Institutional Confidence; Well-being & Life Orientations). Items are selected from a universe of 195 candidates in `data/analytic_core.csv` and must meet four criteria: (1) fielded in all four analysis years (2016, 2018, 2022, 2024); (2) substantive attitude items, excluding internet/technology use variables that are themselves mode-confounded; (3) no wording discontinuities or split-ballot variants across the study period; and (4) not conditionally fielded via skip patterns confounded with mode. Binarization and recoding are performed in `01_data_preparation.qmd`.
- **Multiple comparison correction**: Holm-Bonferroni correction is applied to mode effect p-values across all outcome variables.

## Citation

If you use these weights or replication code, please cite the paper above and this repository:

> Fufunan, R., Freese, J., & Jin O. (2026). gss-mode-weights [Software]. GitHub. https://github.com/restyfufunan/gss-mode-weights

## License

Code: [MIT License](LICENSE)  
Paper: CC-BY 4.0
