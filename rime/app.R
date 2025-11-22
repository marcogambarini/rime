# Climate Impacts Analysis Shiny App

library(shiny)
library(shinydashboard)
library(DT)
library(data.table)
library(ggplot2)
library(nanoparquet)
library(plotly)
library(stringr)
library(stringi)

# Instructions for deployment
# rsconnect::deployApp('.', 
#   appFiles=c('app.R', 'results-shiny-format.parquet'), 
#   appName='COMMITTED-Climate-impacts-dashboard')

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Climate Impacts Analysis Dashboard"),
  
  dashboardSidebar(disable = TRUE),  # Disable sidebar since we only have one tab
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
      "))
    ),
    
    fluidRow(
      box(
        title = "Indicator", status = "primary", solidHeader = TRUE, width = 12,
        selectInput("indicator", "Choose indicator:",
                    choices = NULL, selected = NULL)
      )
    ),

    fluidRow(
      box(
        title = "Variable selection", status = "primary", solidHeader = TRUE, width = 4,
        selectInput("spec", "Select indicator specification:",
                    choices = NULL, selected = NULL),
        selectInput("variable", "Select variable:",
                    choices = NULL, selected = NULL),
        selectInput("region", "Select region:",
                    choices = NULL, selected = NULL),
        checkboxGroupInput("scenario", "Select scenarios:",
                    choices = NULL, selected = NULL),
        checkboxGroupInput("model", "Select models:",
                    choices = NULL, selected = NULL)
      ),
      box(
        title = "RIME results", status = "primary", solidHeader = TRUE, width = 8,
        plotlyOutput("main_plot", height = "500px")
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
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


  rimedata <- setDT(read_parquet('results-shiny-format.parquet'))

  # Handle heatwave indicators with specifications
  rimedata[str_detect(indicator, "hw"), c("perc", "days") := transpose(stri_split_fixed(spec, "_", n=2))]
  rimedata[str_detect(indicator, "hw"), spec:=paste0(days, " days over ", perc, "p")]
  rimedata[, days:=NULL]
  rimedata[, perc:=NULL]

  # Clean scenario names
  rimedata[scenario %in% c("COMTD_SSP2_CP_DM", "COMTD_SSP2_CurPol_D0"), scenario := "COMTD_SSP2_CurPol"]
  rimedata$scenario <- str_remove(rimedata$scenario, "COMTD_SSP2_")

  # Select only relevant scenarios
  scenarios <- c("NDC_a03_LTS", "NDC_a1_LTS", "NDC_a3_LTS", "2C_PC", "2C_AP", "2C_ECPC", "CurPol")
  rimedata <- rimedata[scenario%in%scenarios]


    # Define scenario colors
  scenario_colors <- c(
    "CurPol" = "#C71C2C",  
    "NDC" = "#7D7D7D",
    "NDC_a03_LTS" = "#BDBDBD",
    "NDC_a1_LTS" = "#9D9D9D",
    "NDC_a3_LTS" = "#5D5D5D",
    "2C_PC" = "#228B22",   
    "2C_AP" = "#7FF57E", 
    "2C_ECPC" = "#C0F4BF",
    "1.5C_PC" = "#006DCC",
    "1.5C_AP" = "#4DA6F5",
    "1.5C_ECPC" = "#94C2EB"
  )

  # Update UI choices when server starts
  observe({
    req(rimedata)
    
    # Update indicator choices
    available_indicators <- unique(rimedata$indicator)
    indicator_choices <- indicator_name_map[indicator %in% available_indicators]
    
    updateSelectInput(session, "indicator",
                      choices = setNames(indicator_choices$indicator, indicator_choices$indicator_name),
                      selected = "hw")

    updateSelectInput(session, "region",
                      choices = unique(rimedata$region),
                      selected = unique(rimedata$region)[2])

    updateCheckboxGroupInput(session, "scenario", 
                      choices = unique(rimedata$scenario),
                      selected = unique(rimedata$scenario))
    
    updateCheckboxGroupInput(session, "model", 
                      choices = unique(rimedata$model),
                      selected = unique(rimedata$model))
  })
  
  # Update available variables based on selected indicator
  observeEvent(input$indicator, {
    req(rimedata, input$indicator)
    
    indicator_variables <- unique(rimedata[indicator == input$indicator & !is.na(variable)]$variable)
    
    updateSelectInput(session, "variable",
                     choices = indicator_variables,
                     selected = indicator_variables[9])

    indicator_specifications <- unique(rimedata[indicator == input$indicator & !is.na(spec)]$spec)

    updateSelectInput(session, "spec",
                     choices = indicator_specifications,
                     selected = indicator_specifications[1])
  })
  
  # Main plot
  output$main_plot <- renderPlotly({
    req(rimedata, input$indicator, input$variable, input$model, input$scenario, input$region, input$spec)
    
    plot_data <- rimedata[indicator == input$indicator &
                         variable == input$variable &
                         model %in% input$model &
                         scenario %in% input$scenario &
                         region == input$region &
                         !is.na(value)]
    
    cat("spec = ", input$spec, "\n")
    cat("ind = ", input$indicator, "\n")
    if (input$indicator%in%c("hw", "hwd")){
      cat("specdone")
      plot_data <- plot_data[spec == input$spec]
    }
    
    if (nrow(plot_data) == 0) {
      p <- ggplot() + 
        annotate("text", x = 0.5, y = 0.5, label = "No data available for selected combination", size = 6) +
        theme_void()
    } else {
      # Convert year to numeric
      plot_data[, year := as.numeric(year)]
      
      p <- ggplot(plot_data, aes(x = year, y = value, color = scenario, linetype = model)) +
        geom_line(linewidth = 1) +
        geom_point(size = 2) +
        scale_color_manual(values = scenario_colors)
        labs(x = "Year", 
             y = paste(input$variable, unique(plot_data$unit)[1]), 
             title = paste(indicator_name_map[indicator == input$indicator]$indicator_name, "-", input$region)) +
        theme_light() +
        theme(legend.position = "bottom")
    }
    
    ggplotly(p)
  })
}

# Run the application
shinyApp(ui = ui, server = server)