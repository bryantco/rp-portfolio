if (interactive()) {
  setwd(gsub("src(.*)?", "", rstudioapi::getSourceEditorContext()$path)) 
} 

library(argparse)
library(quarto)

source("../utils/utils.R")

# Parse args from makefile
makefile_args = parse_make_args(
  arg_names = c('report_qmd'),
  interactive = interactive()
)

quarto::quarto_render(makefile_args$report_qmd)