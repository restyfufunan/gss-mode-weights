# =============================================================================
# 00_setup.R
# Central setup file — sourced at the top of every analysis QMD file.
# Defines shared libraries, constants, file paths, the demographic recode
# function, the analytic core variable set, and the color palette.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Libraries (universally shared only)
# -----------------------------------------------------------------------------
library(tidyverse)
library(haven)
library(survey)
library(VIM)

# -----------------------------------------------------------------------------
# 2. Random seed
#
# Required for reproducibility of hotdeck imputation (VIM::hotdeck) in 02_weights.qmd.
# --------------------------------------------------------------------------
set.seed(94305)

# -----------------------------------------------------------------------------
# 3. File paths
# -----------------------------------------------------------------------------
GSS_DTA_PATH  <- "data/gss7224_r2.dta"
GSS_RDS_PATH  <- "data/gss_data_16to24_r2.rds"
WEIGHTS_PATH  <- "data/gss20222024_modeweights.dta"

# -----------------------------------------------------------------------------
# 4. Demographic recode function
#
# Canonical recode for all analysis files. Call recode_demographics(df) after
# loading/filtering data.
#
# NOTE ON RACE/ETHNICITY:
#   A single 8-category factor variable (w_hisp_race) is used for both
#   regression controls and raking. Uses `hispanic`, `racecen1`, `racecen2`.
#   GSS codes: hispanic == 1 -> Not Hispanic; hispanic %in% 2:5 -> Hispanic.
# -----------------------------------------------------------------------------
recode_demographics <- function(df) {
  df %>%
    mutate(
      # --- Survey mode ---
      # "f2fp" (face-to-face or phone) is the reference level for regression.
      mode_fctr = factor(
        case_when(
          mode %in% c(1, 2) ~ "f2fp",
          mode == 4         ~ "web",
          TRUE              ~ NA_character_
        ),
        levels = c("f2fp", "web")
      ),

      # --- Age (5 categories) ---
      agegrp = factor(
        case_when(
          age %in% 18:29 ~ "18-29",
          age %in% 30:39 ~ "30-39",
          age %in% 40:49 ~ "40-49",
          age %in% 50:64 ~ "50-64",
          age >= 65       ~ "65+",
          TRUE            ~ NA_character_
        ),
        levels = c("18-29", "30-39", "40-49", "50-64", "65+")
      ),

      # --- Education (3 categories) ---
      degree_cat = factor(
        case_when(
          degree %in% 0:2 ~ "Less than BA",
          degree == 3     ~ "BA",
          degree == 4     ~ "Graduate",
          TRUE            ~ NA_character_
        ),
        levels = c("Less than BA", "BA", "Graduate")
      ),

      # --- Marital status (2 categories) ---
      marital_cat = factor(
        case_when(
          marital == 1      ~ "Married",
          marital %in% 2:5  ~ "Not Married",
          TRUE              ~ NA_character_
        ),
        levels = c("Not Married", "Married")
      ),

      # --- Race / Ethnicity -- 8 categories (regression control and raking) ---
      # Uses `hispanic`, `racecen1`, and `racecen2`.
      # GSS codes: hispanic == 1 -> Not Hispanic; hispanic %in% 2:5 -> Hispanic.
      w_hisp_race = factor(
        case_when(
          hispanic %in% c(2:5)                             ~ "Hispanic",
          hispanic == 1 & racecen1 == 1 & is.na(racecen2) ~ "White (NH)",
          hispanic == 1 & racecen1 == 2 & is.na(racecen2) ~ "Black (NH)",
          hispanic == 1 & racecen1 == 3 & is.na(racecen2) ~ "AI/AN",
          hispanic == 1 & racecen1 == 4 & is.na(racecen2) ~ "Asian",
          hispanic == 1 & racecen1 == 5 & is.na(racecen2) ~ "NH/PI",
          hispanic == 1 & racecen1 == 6 & is.na(racecen2) ~ "Other",
          hispanic == 1 & !is.na(racecen2)                 ~ "Multiple",
          TRUE                                              ~ NA_character_
        ),
        levels = c("White (NH)", "Black (NH)", "Hispanic",
                   "AI/AN", "Asian", "NH/PI", "Other", "Multiple")
      ),

      # --- Nativity (2 categories) ---
      f_born = factor(
        case_when(
          born == 1 ~ "Born in US",
          born == 2 ~ "Born Elsewhere",
          TRUE      ~ NA_character_
        ),
        levels = c("Born in US", "Born Elsewhere")
      ),

      # --- Sex (2 categories) ---
      f_sex = factor(
        case_when(
          sex == 1 ~ "Male",
          sex == 2 ~ "Female",
          TRUE     ~ NA_character_
        ),
        levels = c("Male", "Female")
      ),

      # --- Region (4 categories) ---
      f_region = factor(
        case_when(
          region == 1 ~ "Northeast",
          region == 2 ~ "Midwest",
          region == 3 ~ "South",
          region == 4 ~ "West",
          TRUE        ~ NA_character_
        ),
        levels = c("Northeast", "Midwest", "South", "West")
      )
    )
}

# -----------------------------------------------------------------------------
# 5. Analytic core variable set
#
# Reads data/analytic_core.csv (the authoritative variable registry) and
# constructs the vector of c_-prefixed outcome variable names for use in
# 04_mode_gaps.qmd and 05_persistence.qmd.
#
# Inclusion criteria (analytic_core == 1):
#   * Binary attitude item fielded in all four analysis years (2016, 2018,
#     2022, 2024)
#   * Not a survey process/quality indicator
#   * Not a voting/electoral item
#   * Not conditionally fielded (structural skip patterns confounded with mode)
#   * No wording discontinuity across the analysis window
# -----------------------------------------------------------------------------
ANALYTIC_CORE_VARS <- readr::read_csv(
  "data/analytic_core.csv",
  show_col_types = FALSE
) |>
  dplyr::filter(analytic_core == 1) |>
  dplyr::pull(variable) |>
  tolower() |>
  (\(x) paste0("c_", x))()

# -----------------------------------------------------------------------------
# 6. Color palette
# -----------------------------------------------------------------------------
MODE_COLORS <- c(
  "FTF/Phone"  = "#D95F02",
  "f2fp"       = "#D95F02",
  "Web"        = "#1B9E77",
  "web"        = "#1B9E77",
  "Population" = "#000000",
  "2016-2018"  = "#A9A9A9"
)
