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
moldat <- subset(moldat, major_sector != "X")

moldat$contract_signing_date <- as.Date(moldat$contract_signing_date, "%m/%d/%Y")
moldat$mo <- strftime(moldat$contract_signing_date, "%m")
moldat$yr <- strftime(moldat$contract_signing_date, "%Y")


quarterly <- c('01'='01', '02'='01','03'='01','04'='04','05'='04','06'='04','07'='07','08'='07','09'='07','10'='10','11'='10','12'='10')

biannual <- c('01'='01', '02'='01','03'='01','04'='01','05'='01','06'='01','07'='07','08'='07','09'='07','10'='07','11'='07','12'='07')

yearly <- c('01'='01', '02'='01','03'='01','04'='01','05'='01','06'='01','07'='01','08'='01','09'='01','10'='01','11'='01','12'='01')


shinyServer(function(input, output) {
    datasetInput <- reactive({
        
        map <- switch(input$segment,
                    "quarterly"=quarterly,
                    "biannual"=biannual,
                    "yearly"=yearly)
        
        moldat$mo <- map[moldat$mo]
        country <- ddply(moldat, .(mo, yr, supplier_country), summarize,
                         amount=sum(amount), contracts= length(unique(wb_contract_number)))
        
        country$date <- as.Date(paste(country$yr, country$mo, "01", sep="-"))
        
        country$mo <- NULL
        country$yr <- NULL
        
        country <- subset(country, !is.na(date))
        return(country)        
    })
    
    output$view <- renderGvis({
        ds <- datasetInput()
        
        motion <- gvisMotionChart(ds, idvar="supplier_country", timevar="date", options=list(chartArea='{left:80,top:50,width:"75%", height:"60%"}', width=1080))
    })
})


