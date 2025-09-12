rm(list=ls())

library(data.table)
library(stringr)
library(stringi)
library(ggplot2)

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

for (f in list.files(result_folder)){
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
rimedata[, variable:=str_remove(variable, fixed("RIME|"))]
#rimedata[, c("indicator", "variable") := tstrsplit(variable, "|")]
rimedata[, c("indicator", "variable") := transpose(stri_split_fixed(variable, "|", n=2))]
rimedata[str_detect(indicator, "hw"), c("indicator", "spec") := transpose(stri_split_fixed(indicator, "_", n=2))]

rimedata <- merge(rimedata, indicator_name_map)

fwrite(rimedata, paste0(result_folder, "RIME-committed.csv"))

ggplot(data=rimedata[region=="Countries of South Asia; primarily India"&indicator_name=="Drought intensity"&
                       year==2060&variable=="Exposure|Population|%"&model=="IMAGE 3.3"]) + 
  geom_col(mapping=aes(x=scenario, y=value)) + 
  scale_x_discrete(guide = guide_axis(angle = 90)) + 
  labs(y = "Drought intensity|Exposure|Population|%")
