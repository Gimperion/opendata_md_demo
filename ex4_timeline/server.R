library(shiny)
library(googleVis)
library(plyr)

## Full Dataset at: https://finances.worldbank.org/Procurement/Major-Contract-Awards/kdui-wcs3
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
moldat$contract_signing_date <- as.Date(moldat$contract_signing_date, "%m/%d/%Y")

shinyServer(function(input, output) {
    datasetInput <- reactive({
        
        .tmp <- subset(moldat, fiscal_year >= input$fiscal_year[1] & fiscal_year <= input$fiscal_year[2])
        
        project_times <- lapply(split(.tmp, .tmp$project_id), function(x){
            data.frame(
                project_id = x$project_id[1],
                project_name = x$project_name[1],
                amount = sum(x$amount),
                contracts = nrow(x),
                start_date = min(x$contract_signing_date),
                last_date = max(x$contract_signing_date))
            
        })
        
        project_times <- do.call("rbind", project_times)
        project_times <- subset(project_times, !is.na(start_date))
        
        
        project_times <- project_times[order(project_times$start_date),]
        project_times$color <- rgb(0, sqrt(project_times$amount/max(project_times$amount)), 0.5)
        
        return(project_times)
    })
    
    output$view <- renderGvis({
        ds <- datasetInput()
        
        gvisTimeline(ds, rowlabel="project_id", barlabel="project_name", start="start_date", end="last_date", options=list(width=1080, height=2000, colors=sprintf("['%s']", paste(ds$color, collapse="','"))))
    })
})


