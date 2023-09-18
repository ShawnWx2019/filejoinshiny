# Check Dependencies ----------------------------------------------------------
options("repos" = c(CRAN="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
if (!require("DT")) install.packages('DT');
if (!require("bruceR")) install.packages('bruceR');
if (!require("shiny")) install.packages('shiny');
if (!require("dplyr")) install.packages('dplyr');
if (!require("shinydashboard")) install.packages('shinydashboard');
library(shiny)
library(DT)
library(bruceR)
library(dplyr)
library(shinydashboard)
# Set File Size Limit ----------------------------------------------------------
options(shiny.maxRequestSize = 300*1024^2)
# Frontend Code ----------------------------------------------------------------
ui <- dashboardPage(
  dashboardHeader(title = "Data Merging Tool"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Data Merging", tabName = "merge", icon = icon("database")),
      menuItem("Join Method Explanation", tabName = "explanation", icon = icon("info-circle"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "merge",
              fluidRow(
                box(title = "File Upload & Settings", width = 3,
                    fileInput("file1", "Select the first file", accept = c(".csv", ".txt", ".xlsx"), multiple = FALSE),
                    fileInput("file2", "Select the second file", accept = c(".csv", ".txt", ".xlsx"), multiple = FALSE),
                    selectInput("select1", "Select a column from the first file", ""),
                    selectInput("select2", "Select a column from the second file", ""),
                    selectInput("joinType", "Select join method", choices = c("left", "right", "inner", "full", "anti", "semi"), selected = "left"),
                    actionButton("mergeBtn", "Merge Data")
                ),
                box(title = "Merged Results", width = 9,
                    dataTableOutput("table"),
                    downloadButton("downloadData", "Download Merged Data")
                )
              )
      ),
      tabItem(tabName = "explanation",
              fluidRow(
                box(title = "Join Method Visualization", width = 12,
                    tags$div(tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/inner-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/left-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/right-join.gif", width = "30%")
                    ),
                    tags$div(tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/full-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/semi-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/anti-join.gif", width = "30%")
                    ),
                    tags$div(style = "margin-top: 20px; text-align: center;", 
                             "Images sourced from: ", tags$a(href = "https://github.com/gadenbuie/tidyexplain", target = "_blank", "tidyexplain GitHub Project")
                    )
                )
              )
      )
    )
  )
)
# backend code --------------------------------------------------------------------
server <- function(input, output, session) {
  data1 <- reactive({
    req(input$file1)
    import(input$file1$datapath)
  })
  
  data2 <- reactive({
    req(input$file2)
    import(input$file2$datapath)
  })
  
  observe({
    updateSelectInput(session, "select1", choices = names(data1()))
  })
  
  observe({
    updateSelectInput(session, "select2", choices = names(data2()))
  })
  
  merged_data <- eventReactive(input$mergeBtn, {
    req(input$select1, input$select2, input$joinType)
    switch(input$joinType,
           "left" = left_join(data1(), data2(), by = setNames(input$select2, input$select1)),
           "right" = right_join(data1(), data2(), by = setNames(input$select2, input$select1)),
           "inner" = inner_join(data1(), data2(), by = setNames(input$select2, input$select1)),
           "full" = full_join(data1(), data2(), by = setNames(input$select2, input$select1)),
           "anti" = anti_join(data1(), data2(), by = setNames(input$select2, input$select1)),
           "semi" = semi_join(data1(), data2(), by = setNames(input$select2, input$select1))
    )
  })
  
  output$table <- renderDataTable({
    req(merged_data())
    merged_data()
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("merged_data.csv")
    },
    content = function(file) {
      write.csv(merged_data(), file = file,row.names = F)
    }
  )
}
shinyApp(ui = ui, server = server,options = list(launch.browser = TRUE))
