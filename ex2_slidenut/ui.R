library(shiny)

# Define UI for application that plots random distributions 
shinyUI(pageWithSidebar(
    headerPanel("Major Contract Awards"),
    
    sidebarPanel(    
        tags$head(
            tags$style(type="text/css", "select { max-width: 205px; }"),
            tags$style(type="text/css", "textarea { max-width: 120px; }"),
            tags$style(type="text/css", ".jslider { max-width: 140px; }"),
            tags$style(type='text/css', ".well { max-width: 220px; }"),
            tags$style(type='text/css', ".span4 { max-width: 220px; }")
        ),
        
        selectInput("subset", "Subsets Available:", 
                    choices = c("major_sector", "procurement_category", "procurement_method", "product_line","project_name", "supplier_country")
        ),
        
        sliderInput("fiscal_year", "Fiscal Year Range:",
                    min = 2000, max = 2014, value = c(2008,2013))
    ),
    
    mainPanel(
        htmlOutput("view")
    )
))
