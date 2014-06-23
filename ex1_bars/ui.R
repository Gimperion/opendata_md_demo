library(shiny)

# Define UI for application that plots random distributions 
shinyUI(pageWithSidebar(
    headerPanel("Major Contract Awards"),
    
    sidebarPanel(    
        selectInput("subset", "Subsets Available:", 
                    choices = c("no subset", "major_sector", "procurement_category", "supplier_country")
        )
    ),
    
    mainPanel(
        htmlOutput("view")
    )
))

