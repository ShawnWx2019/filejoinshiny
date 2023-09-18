# 检查依赖 --------------------------------------------------------------------
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

# 设置输入文件大小限制 --------------------------------------------------------------
options(shiny.maxRequestSize = 300*1024^2)

# 前端代码 --------------------------------------------------------------------
ui <- dashboardPage(
  dashboardHeader(title = "数据合并工具"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("数据合并", tabName = "merge", icon = icon("database")),
      menuItem("合并方式说明", tabName = "explanation", icon = icon("info-circle"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "merge",
              fluidRow(
                box(title = "文件上传与设置", width = 3,
                    fileInput("file1", "选择第一个文件", accept = c(".csv", ".txt", ".xlsx"), multiple = FALSE),
                    fileInput("file2", "选择第二个文件", accept = c(".csv", ".txt", ".xlsx"), multiple = FALSE),
                    selectInput("select1", "选择第一个文件的列", ""),
                    selectInput("select2", "选择第二个文件的列", ""),
                    selectInput("joinType", "选择合并方式", choices = c("left", "right", "inner", "full", "anti","semi"), selected = "left"),
                    actionButton("mergeBtn", "合并数据")
                ),
                box(title = "合并结果", width = 9,
                    dataTableOutput("table"),
                    downloadButton("downloadData", "下载合并的数据")
                )
              )
      ),
      tabItem(tabName = "explanation",
              fluidRow(
                box(title = "连接方式图解", width = 12,
                    tags$div(tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/inner-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/left-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/right-join.gif", width = "30%")
                    ),
                    tags$div(tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/full-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/semi-join.gif", width = "30%"),
                             tags$img(src = "https://raw.githubusercontent.com/gadenbuie/tidyexplain/main/images/anti-join.gif", width = "30%")
                    ),
                    tags$div(style = "margin-top: 20px; text-align: center;", 
                             "图片来源：", tags$a(href = "https://github.com/gadenbuie/tidyexplain", target = "_blank", "tidyexplain GitHub项目")
                    )
                )
              )
      )
    )
  )
)



# 后端代码 --------------------------------------------------------------------
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
