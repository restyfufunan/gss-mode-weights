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
GSS_DTA_PATH  <- "data/gss7224_r3.dta"
GSS_RDS_PATH  <- "data/gss_data_16to24_r3.rds"
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
      # Note: GSS top-codes age at 89, so "65+" captures all 65+ respondents
      agegrp = factor(
        case_when(
          age %in% 18:29 ~ "18-29",
          age %in% 30:39 ~ "30-39",
          age %in% 40:49 ~ "40-49",
          age %in% 50:64 ~ "50-64",
          age %in% 65:89 ~ "65+",
          TRUE            ~ NA_character_
        ),
        levels = c("18-29", "30-39", "40-49", "50-64", "65+")
      ),

      # --- Education (3 categories) ---
      degree_cat = factor(
        case_when(
          degree == 0     ~ "Less than High School",
          degree %in% 1:2 ~ "High School",
          degree %in% 3:4 ~ "Bachelor's or More",
          TRUE            ~ NA_character_
        ),
        levels = c("Less than High School", "High School", "Bachelor's or More")
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
      # racecen2 is NA for single-race respondents; !is.na(racecen2) for multiracial.
      w_hisp_race = factor(
        case_when(
          hispanic %in% c(2:5)                                    ~ "Hispanic",
          hispanic == 1 & racecen1 == 1 & is.na(racecen2)        ~ "Non-Hispanic White Alone",
          hispanic == 1 & racecen1 == 2 & is.na(racecen2)        ~ "Non-Hispanic Black Alone",
          hispanic == 1 & racecen1 == 3 & is.na(racecen2)        ~ "Non-Hispanic AIAN Alone",
          hispanic == 1 & racecen1 %in% c(4:10) & is.na(racecen2) ~ "Non-Hispanic Asian Alone",
          hispanic == 1 & racecen1 == 14 & is.na(racecen2)       ~ "Non-Hispanic NHPI Alone",
          hispanic == 1 & racecen1 %in% c(15, 16) & is.na(racecen2) ~ "Non-Hispanic Other Race Alone",
          hispanic == 1 & !is.na(racecen2)                        ~ "Non-Hispanic Multiple Races",
          TRUE                                                     ~ NA_character_
        ),
        levels = c("Non-Hispanic White Alone", "Non-Hispanic Black Alone", "Non-Hispanic AIAN Alone",
                   "Non-Hispanic Asian Alone", "Non-Hispanic NHPI Alone", "Non-Hispanic Other Race Alone",
                   "Non-Hispanic Multiple Races", "Hispanic")
      ),

      # --- Nativity (2 categories) ---
      f_born = factor(
        case_when(
          born == 1 ~ "Born in US",
          born == 2 ~ "Born Outside the US",
          TRUE      ~ NA_character_
        ),
        levels = c("Born in US", "Born Outside the US")
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

# Short-label lookup vectors for figures (full form stored in factor levels above)
RACE_LABELS_SHORT <- c(
  "Non-Hispanic White Alone"      = "White (NH)",
  "Non-Hispanic Black Alone"      = "Black (NH)",
  "Non-Hispanic AIAN Alone"       = "AIAN (NH)",
  "Non-Hispanic Asian Alone"      = "Asian (NH)",
  "Non-Hispanic NHPI Alone"       = "NHPI (NH)",
  "Non-Hispanic Other Race Alone" = "Other (NH)",
  "Non-Hispanic Multiple Races"   = "Multiple (NH)",
  "Hispanic"                      = "Hispanic"
)

EDUCATION_LABELS_SHORT <- c(
  "Less than High School" = "< HS",
  "High School"           = "HS",
  "Bachelor's or More"    = "BA+"
)

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
  "data/gss24_attitudes_opinions.csv",
  show_col_types = FALSE
) |>
  dplyr::filter(analytic_core == 1) |>
  dplyr::pull(var) |>
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
