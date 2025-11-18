library(nanoparquet)
library(data.table)
library(ggplot2)

scores <- setDT(read_parquet("committed_outputs/RIME_hazard_scores.parquet"))

scores <- scores[scenario%in%c("COMTD_SSP2_2C_AP",
                               "COMTD_SSP2_2C_ECPC",
                               "COMTD_SSP2_2C_PC",
                               "COMTD_SSP2_Curpol_D0",
                               "COMTD_SSP2_NDC_a03_LTS",
                               "COMTD_SSP2_NDC_a1_LTS",
                               "COMTD_SSP2_NDC_a3_LTS")]

sel_indicators <- c("Consecutive dry days",
                    "Water stress index",
                    "Heatwave intensity 95_7",
                    "Cooling degree days (26C)")

sel_regions <- c("India+ (R10)", "China+ (R10)", "Rest of Asia (R10)")

scores_selected <- scores[region%in%sel_regions & 
                          indicator_name%in%sel_indicators]

scores_selected <- scores_selected[, .(value=mean(value)), 
    by=c("indicator_name", "variable", "scenario", "region", "year")]

scores_selected <- rbind(scores_selected[, .(value=max(value), variable="max"), 
                          by=c("indicator_name", "scenario", "region")],
                         scores_selected[year==2020, .(value=value, variable="2020"), 
                          by=c("indicator_name", "scenario", "region")])

# change of selected indicators
for (this_region in sel_regions){
  ggplot(scores_selected[region==this_region]) + 
    geom_col(aes(x=scenario, y=value, fill=variable), position="identity") + 
    guides(x =  guide_axis(angle = 45)) +
    facet_wrap(~indicator_name) +
    ylim(0, 6) +
    theme(panel.margin = grid::unit(-1.25, "lines"))

  ggsave(paste0("figures/selected_", this_region, ".png"),
         width=12, height=8)
}

# total score
for (this_mod in unique(scores$model)){
  ggplot(scores[region=="India+ (R10)"&model==this_mod, 
          .(value=sum(value)), 
          by=c("scenario", "year")]) + 
    geom_line(aes(x=year, y=value, color=scenario)) + 
    labs(y="Combined hazard score", title=paste0("India+ (R10) - ", this_mod))

  ggsave(paste0("figures/totscore_", this_mod, ".png"))
}

# breakdown of total score for a single scenario
ggplot(scores[region=="India+ (R10)"&model=="WITCH 5.0"&scenario=="COMTD_SSP2_NDC_a3_LTS"]) + 
  geom_area(aes(x=year, y=value, fill=indicator_name))
ggsave(paste0("figures/breakdown.png"))