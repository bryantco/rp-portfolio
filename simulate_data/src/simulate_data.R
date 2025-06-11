if (interactive()) {
  setwd(gsub("src(.*)?", "", rstudioapi::getSourceEditorContext()$path)) 
} 

library(argparse)
library(tidytable)
library(tibble)
library(tictoc)
library(VGAM)
library(arrow)

source("../utils/utils.R")

# Parse args from makefile
makefile_args = parse_make_args(
  arg_names = c(
    'df_hs',
    'df_es',
    'output_dir'
  ),
  interactive = interactive()
)

set.seed(12345)

# Simulate school-level treatment df -------------------------------------------
# Simulate panel from 2009 to 2019 of 200 different high schools
# Randomly assign first treatment year as NA or 2014-2019
file_sy_range = 2009:2019
first_schl_ids = 1:200
first_rp_years = c(NA_real_, 2014:2019)
rp_treatment_probabilities = c(0.7, rep((1 - 0.7)/6, 6))

treatment_df_school_by_year = expand.grid(
  schlid = first_schl_ids,
  file_sy = file_sy_range
) %>%
  group_by(schlid) %>%
  mutate(
    first_rp_year = sample(
      first_rp_years, 
      size = 1, 
      replace = TRUE,
      prob = rp_treatment_probabilities
    )
  ) %>% 
  ungroup()

# Generate time-varying RP indicator = 1 if RP has been implemented
treatment_df_school_by_year = treatment_df_school_by_year %>% 
  mutate(
    hs_rp_any_ever = case_when(
      is.na(first_rp_year) ~ 0,
      !is.na(first_rp_year) & file_sy >= first_rp_year ~ 1,
      !is.na(first_rp_year) & file_sy  < first_rp_year ~ 0
    )
  ) %>% 
  group_by(schlid) %>% 
  arrange(schlid, file_sy) %>% 
  mutate(hs_rp_any_ever_cumulative = cumsum(hs_rp_any_ever))

# Simulate sid-level panel -----------------------------------------------------
# High school ----
# Simulate 250k students from 2009 to 2019 and assign them to the 200 schools. 
# Students stay in their assigned school for five years (one ES, four HS).
num_students_to_simulate_hs = 2.5e5

tic("Simulating student-year level dataset")

df_sid_year = tibble(
  sid = rep(1:num_students_to_simulate_hs, times = 5)
) %>% 
  group_by(sid) %>% 
  mutate(schlid = sample(first_schl_ids, size = 1, replace = TRUE)) %>% 
  # Generate an entry HS year for each student and follow them for 4 years
  mutate(
    first_hs_file_sy = sample(file_sy_range[1:(length(file_sy_range) - 4)], 1),
    file_sy = first_hs_file_sy:(first_hs_file_sy + 4)
  ) %>%
  select(-first_hs_file_sy) %>%
  ungroup() %>%
  arrange(sid, file_sy)

toc()

# Generate covariates ----------------------------------------------------------
tic("Generating covariates")

df_sid_year = df_sid_year %>%
  # Generate time-invariant covariates by student
  group_by(sid) %>%
  mutate(
    gender_female = rbinom(n = 1, size = 1, prob = 0.5),
    # all students are either Asian, white, Black, or Latinx
    race_asian = rbinom(n = 1, size = 1, prob = 0.05),
    race_white = rbinom(n = 1, size = 1, prob = 0.15),
    race_black = rbinom(n = 1, size = 1, prob = 0.4),
    race_hispanic = rbinom(n = 1, size = 1, prob = 0.4)
  ) %>% 
  # Generate time-varying covariates by student and year
  group_by(sid, file_sy) %>% 
  mutate(
    esl_indicator = rbinom(n = 1, size = 1, prob = 0.4),
    homeless_indicator = rbinom(n = 1, size = 1, prob = 0.1),
    frlunch_indicator = rbinom(n = 1, size = 1, prob = 0.4)
  ) %>% 
  ungroup()

toc()

# Generate outcomes ------------------------------------------------------------

tic("Generating outcomes")

# Elementary school ----
df_sid_year = df_sid_year %>%
  # Generate elementary school outcomes
  group_by(sid) %>% 
  mutate(
    # OSS days as a Poisson R.V. with mean 1
    oss_days_8thgrd = rpois(n = 1, lambda = 1),
    # arrests as a zero-inflated Poisson R.V. with P(arrests = 0) = 0.8 and 
    # Poisson(1) otherwise;
    arrests_n_8thgrd = VGAM::rzipois(n = 1, lambda = 1, pstr0 = 0.8),
    # GPA as a uniform R.V. between 0 and 4;
    gpa_8thgrd = runif(n = 1, min = 0, max = 4),
    # present days as a Poisson R.V. with mean 150 out of 180 days in the
    # school year
    present_days_8thgrd = rpois(n = 1, lambda = 150)
  ) %>% 
  ungroup()

# High school ----
# In 2013 and prior years, generate OSS days as the sum of 8th grade OSS days and 
# arrests plus some noise ~ Poisson(1)
# This will introduce some artificial correlation in the random forest
df_sid_year = df_sid_year %>%
  group_by(sid) %>% 
  mutate(oss_days_baseline = oss_days_8thgrd + arrests_n_8thgrd + rpois(n = 1, lambda = 1),
         hs_cohort_fac = as.character(min(file_sy) + 1)) %>% 
  ungroup()

# Generate artificial treatment effects by quartile ----
df_sid_year = df_sid_year %>% 
  left_join(treatment_df_school_by_year, by = c("schlid", "file_sy"))

oss_days_quartiles_school_level_df = df_sid_year %>% 
  group_by(schlid) %>%
  mutate(oss_days_schl_mean = mean(oss_days_baseline)) %>% 
  slice_head(n = 1) %>% 
  ungroup() %>% 
  mutate(oss_quartile_schl_level = dplyr::ntile(oss_days_baseline, 4)) %>%
  select(schlid, oss_days_schl_mean, oss_quartile_schl_level)

df_sid_year = df_sid_year %>% 
  left_join(oss_days_quartiles_school_level_df, by = "schlid")


df_sid_year = df_sid_year %>%
  group_by(schlid, file_sy) %>% 
  mutate(
    treatment_effect = case_when(
      oss_quartile_schl_level %in% 1:3 & hs_rp_any_ever_cumulative > 0 ~ rnorm(1, 0, .5),
      oss_quartile_schl_level == 4 & hs_rp_any_ever_cumulative %in% 1:2 ~ rnorm(1, -1, 1),
      oss_quartile_schl_level == 4 & hs_rp_any_ever_cumulative > 2 ~ rnorm(1, -2, 1),
      hs_rp_any_ever_cumulative == 0 ~ rnorm(1, 0, .5)
    )
  ) %>%
  arrange(sid, file_sy) %>%
  group_by(sid) %>% 
  mutate(treatment_effect_cumulative = cumsum(treatment_effect)) %>%
  ungroup() %>% 
  mutate(oss_days_plus_te = oss_days_baseline + treatment_effect_cumulative) %>%
  mutate(
    oss_days = case_when(
      oss_days_plus_te >= 0 ~ abs(floor(oss_days_plus_te)),
      oss_days_plus_te <  0 ~ 0
    )
  ) %>% 
  select(
    -oss_quartile_schl_level,
    -oss_days_plus_te,
    -treatment_effect_cumulative,
    -first_rp_year,
    -hs_rp_any_ever_cumulative
  )

toc()

# Split into HS and ES ---------------------------------------------------------\
df_es = df_sid_year %>%
  select(-oss_days) %>%
  arrange(sid, file_sy) %>% 
  group_by(sid) %>% 
  slice_head(n = 1) %>%
  rename_with(
    .cols = ends_with("_8thgrd"),
    .fn = ~ gsub("_8thgrd", "", .x)
  ) %>%
  mutate(annual_grade_num = 8) %>% 
  ungroup()

df_hs = df_sid_year %>% 
  group_by(sid) %>% 
  slice_tail(n = 4) %>% 
  select(-ends_with("_8thgrd")) %>%
  ungroup()

# Save
output_dir = makefile_args$output_dir
if (!dir.exists(output_dir)) { dir.create(output_dir) }

arrow::write_parquet(df_es, makefile_args$df_es)
arrow::write_parquet(df_hs, makefile_args$df_hs)



