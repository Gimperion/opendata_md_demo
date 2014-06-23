library(shiny)
library(googleVis)

## Data Loading
moldat <- read.csv("http://finances.worldbank.org/resource/kdui-wcs3.csv?borrower_country=Moldova")

if(nrow(moldat)==1000){
    # If data called exceeds 1000 lines, pull next chunk 1000 lines at a time.
    iter <- TRUE
    n <- 1
    while(iter==TRUE){
        .api_call <- sprintf("http://finances.worldbank.org/resource/kdui-wcs3.csv?borrower_country=Moldova&$offset=%d", n*1000)
        .add <- read.csv(.api_call)
        
        if(nrow(.add) < 1000){
            iter <- FALSE
        } else{
            n <- n + 1
        }
        moldat <- rbind(moldat, .add)
    }
}


## Data Transformations
names(moldat) <- gsub("\\.", "_", tolower(names(moldat)))
moldat$amount <- as.numeric(gsub("\\$", "", moldat$total_contract_amount__usd_))

## Data Cleaning
moldat <- subset(moldat, major_sector != "X")

shinyServer(function(input, output) {
    datasetInput <- reactive({
        .tmp <- subset(moldat, fiscal_year >= input$fiscal_year[1] & fiscal_year <= input$fiscal_year[2])
        
        aggregate(as.formula(sprintf("amount ~ %s", input$subset)), data=.tmp, sum)
        
    })
    
    output$view <- renderGvis({
        ds <- datasetInput()
        ds <- ds[order(-ds$amount),]
        doughnut <- gvisPieChart(ds, 
                                 options=list(
                                     width=1080,
                                     height=800,
                                     chartArea='{left:80,top:50,width:"75%", height:"60%"}',
                                     slices="{0: {offset: 0.1}}",
                                     title=sprintf('Proportion of Contract Dollars (%d - %d)', input$fiscal_year[1], input$fiscal_year[2]),
                                     legend="{position: 'bottom', textStyle: {fontSize: 12}}",
                                     pieSliceText=names(ds)[1],
                                     pieHole=0.6))
    })
})


