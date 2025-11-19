rm(list=ls())

library(data.table)
library(stringr)
library(stringi)
library(ggplot2)
library(nanoparquet)

result_folder <- "committed_outputs/"

indicator_name_map <- data.table(
  indicator = c("cdd", 
                "dri", 
                "dri_qtot",
                "hw", 
                "hwd", 
                "iavar", 
                "iavar_qtot",
                "pr_r10", 
                "pr_r20",
                "pr_r95p",
                "pr_r99p",
                "sdd_c_18p3", 
                "sdd_c_20p0",
                "sdd_c_24p0",
                "sdd_c",
                "sdii", 
                "seas", 
                "tr20", 
                "wsi"),
  indicator_name = c("Consecutive dry days",
                     "Drought intensity",
                     "Drought intensity (Runoff)",
                     "Heatwave intensity",
                     NA,
                     "Inter-annual variability",
                     "Inter-annual variability (Runoff)",
                     "Heavy precipitation days",
                     "Very heavy precipitation days",
                     "Wet days",
                     "Very wet days",
                     "Cooling degree days (18.3C)",
                     "Cooling degree days (20C)",
                     "Cooling degree days (24C)",
                     "Cooling degree days (26C)",
                     "Precipitation intensity index",
                     "Seasonality",
                     "Tropical nights",
                     "Water stress index"
                     )
)

for (f in setdiff(list.files(result_folder), c("RIME-committed.csv", 
                                               "RIME_hazard_scores.parquet",
                                               "RIME_detailed_scores.parquet"))){
  filename <- paste0(result_folder, f)
  cat(filename, "\n")
  if (exists("rimedata")){
    rimedata <- rbind(rimedata, fread(filename, header=TRUE))
  } else {
    rimedata <- fread(filename, header=TRUE)
  }
}

rimedata <- melt(rimedata, id.vars=c("model", "scenario", "region", "variable", "unit"),
                 variable.name="year", variable.factor=FALSE)
rimedata$year <- as.numeric(rimedata$year)
rimedata[, variable:=str_remove(variable, fixed("RIME|"))]
#rimedata[, c("indicator", "variable") := tstrsplit(variable, "|")]
rimedata[, c("indicator", "variable") := transpose(stri_split_fixed(variable, "|", n=2))]
rimedata[str_detect(indicator, "hw"), c("indicator", "spec") := transpose(stri_split_fixed(indicator, "_", n=2))]

rimedata <- merge(rimedata, indicator_name_map)

fwrite(rimedata, paste0(result_folder, "RIME-committed.csv"))

# select values for a composite indicator
# see Fig. SI 12 of Werning et al. 2024
indicator_sel <- data.table(
  indicator_name = c("Very heavy precipitation days",
                     "Very wet days",
                     "Consecutive dry days",
                     "Drought intensity (Runoff)",
                     "Seasonality", # TODO: CHECK supposed to be runoff
                     "Inter-annual variability (Runoff)",
                     "Water stress index",
                     "Heatwave intensity", # TODO: CHECK supposed to be heatwave events
                     "Heatwave intensity",
                     "Tropical nights",
                     "Cooling degree days (26C)"
                    ),
  spec = c(NA,
           NA,
           NA,
           NA,
           NA,
           NA,
           NA,
           "95_7",
           "99_3",
           NA,
           NA
        )
)

region_name_map <- data.table(
  region = c("Countries of Latin America and the Caribbean",
             "Countries of South Asia; primarily India",
             "Countries of Sub-Saharan Africa",
             "Countries of centrally-planned Asia; primarily China",
             "Countries of the Middle East; Iran, Iraq, Israel, Saudi Arabia, Qatar, etc.",
             "Eastern and Western Europe (i.e., the EU28)",
             "North America; primarily the United States of America and Canada",
             "Other countries of Asia",
             "Pacific OECD",
             "Reforming Economies of Eastern Europe and the Former Soviet Union; primarily Russia"
             ),
  r10_region = c("Latin America (R10)",
                 "India+ (R10)",
                 "Africa (R10)",
                 "China+ (R10)",
                 "Middle East (R10)",
                 "Europe (R10)",
                 "North America (R10)",
                 "Rest of Asia (R10)",
                 "Pacific OECD (R10)",
                 "Reforming Economies (R10)"
                  )
)

selected_indicators <- merge(rimedata, indicator_sel, by=c("indicator_name", "spec"))
selected_indicators[!is.na(spec), indicator_name:=paste(indicator_name, spec)]
selected_indicators <- merge(selected_indicators, region_name_map, by="region")
selected_indicators[, region:=NULL]
setnames(selected_indicators, "r10_region", "region")

detailed_indicators <- selected_indicators[
  indicator_name%in%c("Cooling degree days (26C)",
                      "Very heavy precipitation days",
                      "Water stress index")]

write_parquet(detailed_indicators, "committed_outputs/RIME_detailed_scores.parquet")

write_parquet(selected_indicators[variable == "Hazard|Hazard score|Population weighted"], 
  "committed_outputs/RIME_hazard_scores.parquet")

