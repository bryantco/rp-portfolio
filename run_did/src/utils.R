# Bind together estimation results; one row per time period
#' Generates a cleaned df of the effects, placebos, and average treatment effect
#' from DIDmultiplegtDYN::did_multiplegt_dyn.
#'
#' @param did_results output of call to DIDmultiplegtDYN::did_multiplegt_dyn
#'
#' @return df with treatment effects by period (effects and placebos) and the average total effect.
#' @export
#'
#' @examples
generate_effects_and_placebos_df = function(did_results) {
  effects_and_placebos_df = rbind(
    did_results[["results"]][["Effects"]],
    did_results[["results"]][["Placebos"]],
    did_results[["results"]][["ATE"]]
  ) %>% 
    tibble::as_tibble(rownames = "effect_num_fac") %>% 
    dplyr::rename_with(
      .cols = everything(),
      .fn = ~snakecase::to_snake_case(.x)
    )  
}

#' Create a df of DID results to plot from estimation results cleaned up using
#' the generate_effects_and_placebos_df function.
#'
#' @param effects_and_placebos_df df output from the generate_effects_and_placebos_df
#'
#' @return df with only treatment effects by period to plot.
#' @export
#'
#' @examples
generate_plot_df = function(effects_and_placebos_df) {
  effects_and_placebos_plot_df = effects_and_placebos_df %>%
    filter(!grepl("Av_tot_eff", effect_num_fac)) %>% 
    mutate(
      effect_num = case_when(
        grepl("Effect_[0-9]+", effect_num_fac) ~ as.numeric(str_extract(effect_num_fac, "[0-9]+")),
        grepl("Placebo_[0-9]+", effect_num_fac) ~ as.numeric(str_extract(effect_num_fac, "[0-9]+")) * -1,
        TRUE ~ NA_real_
      )
    ) %>% 
    assertr::verify(all(is.numeric(effect_num)))
}

#' Title
#'
#' @param effects_and_placebos_plot_df df created from generate_plot_df function.
#' @param outcome_name_for_plot string; outcome to be used on the plot title.
#'
#' @return
#' @export
#'
#' @examples
plot_effects_and_placebos = function(
    effects_and_placebos_plot_df,
    outcome_name_for_plot 
) {
  p = ggplot(effects_and_placebos_plot_df) + 
    geom_point(
      aes(
        x = effect_num,
        y = estimate
      )
    ) + 
    geom_linerange(
      aes(
        x = effect_num,
        ymin = lb_ci,
        ymax = ub_ci
      )
    ) + 
    geom_ribbon(
      aes(
        x = effect_num,
        ymin = lb_ci,
        ymax = ub_ci,
      ),
      fill = "darkgray",
      alpha = 0.5
    ) + 
    scale_x_continuous(
      breaks = seq(
        min(effects_and_placebos_plot_df$effect_num), 
        max(effects_and_placebos_plot_df$effect_num), 
        by = 1
      )
    ) +
    geom_hline(yintercept = 0, lty = "dashed", color = "gray") + 
    labs(
      x = "Time relative to treatment change (t = 0)",
      y = "Estimate",
      title = paste("Effect of RP on", outcome_name_for_plot)
    ) + 
    theme_bw() + 
    theme(plot.title = element_text(size = 16, hjust = 0.5, face = "bold")) 
  
  return(p)
}

