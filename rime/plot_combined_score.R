library(nanoparquet)
library(data.table)
library(ggplot2)
library(stringr)

figfmt <- "pdf"

if (figfmt=="pdf") {
  figdevice <- cairo_pdf
} else {
  figdevice <- NULL
}

scores <- setDT(read_parquet("committed_outputs/RIME_hazard_scores.parquet"))

scores[scenario%in%c("COMTD_SSP2_CP_DM", "COMTD_SSP2_CurPol_D0"),
         scenario:="COMTD_SSP2_CurPol"]

scores <- scores[scenario%in%c("COMTD_SSP2_2C_AP",
                               "COMTD_SSP2_2C_ECPC",
                               "COMTD_SSP2_2C_PC",
                               "COMTD_SSP2_CurPol",
                               "COMTD_SSP2_NDC_a03_LTS",
                               "COMTD_SSP2_NDC_a1_LTS",
                               "COMTD_SSP2_NDC_a3_LTS")]

scores$scenario <- str_remove(scores$scenario, "COMTD_SSP2_")

sel_indicators <- c("Very heavy precipitation days",
                    "Water stress index",
                    "Cooling degree days (26C)")

sel_regions <- c("India+ (R10)", "China+ (R10)", "Rest of Asia (R10)")

scores_ranked <- scores[region%in%sel_regions]
scores_ranked[, max_value_over_time:=max(value), 
  by=c("indicator_name", "scenario", "region", "model")]
scores_ranked <- scores_ranked[, .(max_value_over_indicators=max(max_value_over_time),
                                   indicator_name, max_value_over_time),
  by=c("scenario", "region", "model")]
scores_ranked <- scores_ranked[max_value_over_time==max_value_over_indicators]

cat('Highest ranking indicators = ', unique(scores_ranked$indicator_name), "\n")

scores_ranked_diff <- scores[region%in%sel_regions]
scores_ranked_diff <- merge(scores_ranked_diff[, .(valmax=max(value)), 
                          by=c("indicator_name", "scenario", "region", "model")],
                         scores_ranked_diff[year==2020, .(val2020=value), 
                          by=c("indicator_name", "scenario", "region", "model")])
scores_ranked_diff <- scores_ranked_diff[, .(scorediff=valmax-val2020),
                          by=c("indicator_name", "scenario", "region", "model")]
scores_ranked_diff <- scores_ranked_diff[, .(maxdiff=max(scorediff), indicator_name, scorediff), 
                          by=c("scenario", "region", "model")]
scores_ranked_diff <- scores_ranked_diff[maxdiff==scorediff]

cat('Indicators with highest variation = ', unique(scores_ranked_diff$indicator_name), "\n")

scores_selected <- scores[region%in%sel_regions & 
                          indicator_name%in%sel_indicators]

scores_selected <- scores_selected[, .(value=mean(value)), 
    by=c("indicator_name", "variable", "scenario", "region", "year")]

scores_selected <- rbind(scores_selected[, .(value=max(value), variable="max"), 
                          by=c("indicator_name", "scenario", "region")],
                         scores_selected[year==2020, .(value=value, variable="2020"), 
                          by=c("indicator_name", "scenario", "region")])

# change of selected indicators
ggplot(scores_selected) + 
  geom_col(aes(x=scenario, y=value, fill=variable), position="identity") + 
  guides(x =  guide_axis(angle = 45)) +
  facet_grid(rows=vars(region), cols=vars(indicator_name)) +
  labs(y="Population-weighted hazard score", fill="data") +
  theme_minimal() +
  ylim(0, 6) 

ggsave(paste0("figures/selected_indicators.", figfmt),
        width=20, height=18, units="cm")


# total score
for (this_mod in unique(scores$model)){
  ggplot(scores[region=="India+ (R10)"&model==this_mod, 
          .(value=sum(value)), 
          by=c("scenario", "year")]) + 
    geom_line(aes(x=year, y=value, color=scenario)) + 
    labs(y="Combined hazard score", title=paste0("India+ (R10) - ", this_mod))

  ggsave(paste0("figures/totscore_", this_mod, ".", figfmt))
}

# breakdown of total score for a single scenario
ggplot(scores[region=="India+ (R10)"&model=="WITCH 5.0"&scenario=="COMTD_SSP2_NDC_a3_LTS"]) + 
  geom_area(aes(x=year, y=value, fill=indicator_name))
ggsave(paste0("figures/breakdown.", figfmt))