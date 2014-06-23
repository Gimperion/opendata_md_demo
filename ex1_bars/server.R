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
        if(input$subset=='no subset'){
            return(aggregate(amount~fiscal_year, data=moldat, sum))
        } else{
            fy_bar_dat <- aggregate(amount~fiscal_year, data=moldat, sum)
            subset <- input$subset
            categories <- sort(unique(moldat[,subset]))
            
            fiscal<- lapply(categories, function(x) {
                .ret <- c()
                for(i in 2000:max(moldat$fiscal_year)){
                    .ret <- c(.ret, sum(moldat$amount[moldat[,subset]==x & moldat$fiscal_year==i]))
                }
                names(.ret) <- 2000:max(moldat$fiscal_year)
                return(.ret)
            })
            
            for(i in 1:length(categories)){
                fy_bar_dat[categories[i]] <- fiscal[i]
            }
    
            return(fy_bar_dat)            
        }
        
    })
    
    output$view <- renderGvis({
        if(input$subset=='no subset'){
            gvisBarChart(datasetInput(), xvar="fiscal_year", yvar="amount", options=list(chartArea='{left:80,top:50,width:"75%", height:"60%"}',orientation='horizontal', title="Aggregated Contract Amount by Year", width=1080))
        } else{
            ds <- datasetInput()
            categories <- names(ds)[3:length(ds)]
            
            stacked <- gvisColumnChart(ds, xvar='fiscal_year', yvar=categories, options=list(isStacked=TRUE, chartArea='{left:80,top:50,width:"75%", height:"60%"}',orientation='horizontal', title="Contract Amount Subseted", width=1080))
        }
        
    })
})


