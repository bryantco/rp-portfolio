parse_make_args = function(arg_names = c(), interactive = FALSE, dir_prefix = '') {
  # arg_names = c('task_utils', 'general_utils', 'config', 'student_year_masterfiles')
  if (interactive == TRUE) {
    make = readLines(paste0(dir_prefix, 'makefile'))
    argsline = make[grepl(paste(paste0('^', arg_names), collapse = '|'), make)]
    arg_list = list(sapply(strsplit(argsline,'( )?=( )?'), '[[',1), sapply(strsplit(argsline,' = '), '[[',2))
    args = as.list(gsub('\\$\\(CURRENT_DIR\\)\\/', '', arg_list[[2]]))
    names(args) = arg_list[[1]]
  } else {
    parser = ArgumentParser()
    for (x in arg_names) {
      parser$add_argument(paste0('--', x))
    }
    args = parser$parse_args()
  }
  return(args)
}