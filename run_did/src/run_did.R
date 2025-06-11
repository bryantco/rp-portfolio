if (interactive()) {
  setwd(gsub("src(.*)?", "", rstudioapi::getSourceEditorContext()$path)) 
} 

# Setup ------------------------------------------------------------------------

# as of time of writing, matlib 1.0.1 is broken and won't install due to a 
# syntax error; fetch the 0.9.8 version instead if not already installed
is_matlib_installed = require(matlib)

if (!is_matlib_installed) {
  matlib_0.9.8_url =  "https://cran.r-project.org/src/contrib/Archive/matlib/matlib_0.9.8.tar.gz"
  install.packages(
    matlib_0.9.8_url, 
    repos = NULL, 
    type = "source"
  )  
}

library(argparse)
library(arrow)
library(tidytable)
library(DIDmultiplegtDYN)
library(readr)
library(stringr)
library(assertr)
library(ggplot2)
library(purrr)
library(tibble)

source("../utils/utils.R")

# Parse args from makefile
makefile_args = parse_make_args(
  arg_names = c(
    'df_hs_predicted_oss',
    'config',
    'task_utils',
    'results_rds',
    'results_xlsx',
    'oss_days_q4',
    'output_dir'
  ),
  interactive = interactive()
)

source(makefile_args$task_utils)

df_hs_predicted_oss = read_parquet(makefile_args$df_hs_predicted_oss)

config = yaml::yaml.load_file(makefile_args$config)

# Bin students into quartiles in predicted suspension propensity
df_hs_predicted_oss = df_hs_predicted_oss %>%
  group_by(hs_cohort_fac, file_sy) %>% 
  mutate(oss_quartile_student_level = dplyr::ntile(oss_days_predicted, 4)) %>% 
  ungroup()

# Run DID model ----------------------------------------------------------------
outcomes = config$outcomes
did_settings = config$did_settings

# Add cohort fixed effects as controls
cohort_dummies = grep("hs_cohort_fac_", names(df_hs_predicted_oss), value = TRUE)

results = list()

for (outcome in outcomes) {
  for (q in 1:4) {
    print(paste("Running outcome", outcome, "for quartile", q))
    
    df_for_did = df_hs_predicted_oss %>% 
      filter(oss_quartile_student_level == q)
    
    model = DIDmultiplegtDYN::did_multiplegt_dyn(
      df = df_for_did,
      outcome = outcome,
      group = did_settings$group_var,
      time = did_settings$time_var,
      treatment = did_settings$treatment_var,
      effects = 5,
      placebo = 4,
      controls = c(config$did_controls_no_cohort, cohort_dummies)
    )
    
    # Bind together estimation results; one row per time period
    effects_and_placebos_df = generate_effects_and_placebos_df(model)
    
    # Add to list storing results; one row per outcome x quartile
    result_name = paste0(outcome, "_q", q)
    results[[result_name]] = effects_and_placebos_df
  }
}

output_dir = makefile_args$output_dir
if (!dir.exists(output_dir)) { dir.create(output_dir) }

saveRDS(results, makefile_args$results_rds)
writexl::write_xlsx(results, makefile_args$results_xlsx)

# Plot -------------------------------------------------------------------------
results_for_plot_df = map(
  .x = results,
  .f = ~generate_plot_df(.x)
) %>% 
  enframe(
    name = "outcome_and_quartile",
    value = "data"
  )

outcome_names_for_plot = config$outcome_names_for_plot

outcome_names_for_plot_df = tibble(
  outcome_name = names(outcome_names_for_plot),
  outcome_name_for_plot = unlist(outcome_names_for_plot)
)

# Generate grid with outcome names and quartiles; one row per outcome name x quartile
plot_grid = tibble(
  outcome_name = rep(outcomes, each = 4),
  quartile = rep(1:4, times = length(outcomes)),
  outcome_and_quartile = paste0(outcome_name, "_q", quartile),
  plot_name_to_output = paste0(outcome_name, "_q", quartile, ".png")
) %>% 
  left_join(outcome_names_for_plot_df, by = "outcome_name") %>% 
  left_join(results_for_plot_df, by = "outcome_and_quartile")
  
for (i in 1:nrow(plot_grid)) {
  outcome_name = plot_grid[i, ]$outcome_name
  q = plot_grid[i, ]$quartile
  
  print(paste("Plotting results for outcome", outcome_name, "for quartile", q))
  p = plot_effects_and_placebos(
    effects_and_placebos_plot_df = plot_grid[i, ]$data[[1]],
    outcome_name_for_plot = plot_grid[i, ]$outcome_name_for_plot
  )
  
  ggsave(
    plot = p, 
    filename = paste0("output/", plot_grid[i, ]$plot_name_to_output),
    width = 8,
    height = 6
  )
}


