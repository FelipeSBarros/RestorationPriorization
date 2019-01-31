# Functions

preAnalysis <- function(forest = forest_t,
                        appt = appt,
                        car = carList[[1]],
                        restYears = 10) {
  if (!require("rgdal")) {
    install.packages("rgdal")
    library("rgdal")
  }
  if (!require("raster")) {
    install.packages("raster")
    library("raster")
  }
  if (!require("rgeos")) {
    install.packages("rgeos")
    library("rgeos")
  }
  
  message("Starting function \n")
  cat(car@data$ID, "\n\n")
  
  status <- NULL
  
  status$Car_ID <- car@data$ID
  status <- as.data.frame(status)
  status$Car_modulo_fiscal <- car@data$Modu_Fisc
  
  compareRaster(forest, appt)
  
  # Transforming CAR area to raster
  r.car <- rasterize(car, forest, field=1)
  #r.car <- crop(r.car, car) # To speed up
  # Few Objects to facilitate 
  
  # creating app inside car object
  car.app <- r.car * appt
  #plot(car.app, ext=v.car[a,])
  
  #Creating a forest inside CAR object (to facilitate)
  F.car <- r.car * forest
  #plot(F.car, ext = v.car[a,])
  
  # testing if it was rasterized ie.: if the car values are NA
  if ( is.na( maxValue(r.car) ) ) {
    
    ## As te property has no size to be rasterizes, all values of status will be zero
    status$car.area <- 0
    status$f.total <- 0
    status$app.area <- 0
    status$debt.app <- 0
    status$rl.area <- 0
    status$debt.rl <- 0
    status$credit.rl <- 0
    status$TotalToRestore <- 0
    status$ToRestore2years <- 0
    status$obs <- "Property not rasterized"
    
  } else {
    
    # Estimating CAR total area 
    status$car.area <- zonal(r.car, r.car, fun = 'count')[1,2]
    
    if (is.na(maxValue(F.car))) {# Testing if CAR in consolidated area
      
      status$f.total <- 0
      status$app.area <- 0 #might insert app area if any
      status$debt.app <- 0 #same as previous
      status$rl.area <- 0
      status$debt.rl <- 0
      status$credit.rl <- 0
      status$TotalToRestore <- 0
      status$ToRestore2years <- 0
      status$obs <- "Property on consolidated area (NA)"
      cat("CAR ID: ", car@data$ID, "On consolidated area! \n\n")
      
    } else {
      
      # testing if property has unforested area:
      if (minValue(F.car) == 1) {
        
        # it does NOT have deforested areas, so
        status$debt.app <- 0
        status$debt.rl <- 0
        status$TotalToRestore <- 0
        status$ToRestore2years <-0
        
        # But it might have credit ----
        status$f.total <- zonal(r.car, F.car, fun = 'count')[1,2]
        
        # testing if CAR has APP (1) or not (0):
        if (maxValue(car.app) == 0) {
          # car doesn't have APP
          status$app.area <- 0
          status$debt.app <- 0
          status$rl.area <- abs((status$car.area * 0.2))
          status$credit.rl <- status$car.area - (status$car.area * 0.2)
          status$obs <- "Property all forested but without app area"
        } else {
          
          # if it has APP, it's all forested, debt =0
          if (minValue(r.car*car.app)==1) {
            # Property is completely coverred by app
            status$app.area <- zonal(r.car, car.app, fun = 'count')[1,2]
            status$debt.app <- 0
            status$rl.area <- 0
            status$credit.rl <- 0
            status$obs <- "Property all forested completely covered by app"
          } else {
            # Property has app area and rl
            status$app.area <- zonal(r.car, car.app, fun = 'count')[2,2]
            status$debt.app <- 0
            status$rl.area <- abs(status$app.area - (status$car.area * 0.2))
            status$credit.rl <- status$car.area - (status$car.area * 0.2)
            status$obs <- "Property all forested"
          }
          
        }
        
      }
      
      # Testing if Property is completetly deforested
      if (maxValue(F.car) == 0) {
        
        # there is no forest in the property, so:
        status$f.total <- 0
        
        # testing if CAR has APP (1) or not (0):
        if (maxValue(car.app) == 0) {
          
          # If it doesn't have APP
          status$app.area <- 0
          status$debt.app <- 0
          status$obs <- "Property all deforested"
          if( car@data$Modu_Fisc <= 4) {
            status$obs <- "Property all deforested without APP"
          }
          
          status$rl.area <- abs(status$app.area - (status$car.area * 0.2))
          # As the property is all deforested, debt.rl = rl.area and credit == 0
          status$debt.rl <-  status$rl.area
          status$credit.rl <- 0
          status$TotalToRestore <- trunc(status$debt.rl + status$debt.app)
        } else {
          
          # if it has APP, it's all deforested, so debt.app = app area
          status$app.area <- zonal(r.car, car.app, fun = 'count')[1,1]
          status$debt.app <- status$app.area
          status$obs <- "Property all deforested"
          
          status$rl.area <- 0
          # As the property is all deforested and without rl:
          status$debt.rl <-  0
          status$credit.rl <- 0
          status$TotalToRestore <- status$debt.app
          
        }
        
        # if ToRestore is less than 10 (number of total iterations to restore), then ToRestore2Years will be 1
        
        if( (status$TotalToRestore > 0) & (status$TotalToRestore < 10) ) {
          status$ToRestore2years <- 1 
        } else {
          
          # To restore in 2 years: 1/ restYears (10) each 2 years
          status$ToRestore2years <- trunc( status$TotalToRestore / restYears ) #n pixel to be restored each year
        }
      }
      
      # CAR with both forest and non forest areas
      if ( (maxValue( F.car ) == 1) & ( minValue( F.car ) == 0) ) {
        
        # Estimating total forested area inside CAR
        status$f.total <- zonal(r.car, F.car, fun = 'count')[2,2]
        
        # testing if CAR has APP (1) or not (0):
        if ( maxValue(car.app) == 0 | is.na(maxValue(car.app))) {
          
          # If hasn't APP
          status$app.area <- 0
          status$debt.app <- 0
          #status$obs <- "Property without app"
          
        } else {
          
          # Estimating total APP area inside CAR
          status$app.area <- zonal(r.car, appt, fun = 'count')[2,2]
          # plot((car.app), ext=extent(v.car[a,]))
          Def.app <- car.app*(F.car!=1) # non forest in APP
          
          # testing if it does NOT have non forest areas in APP (0)
          # i.e: property is all forested
          if ( maxValue(Def.app) == 0 ) {
            
            ## No debt inside APP 
            status$debt.app <- 0
            status$obs <- "Property with app forested"
            
          } else {
            
            # calculate forest debt in APP
            status$debt.app <- zonal(r.car, Def.app, fun = 'count')[2,2]
            status$obs <- "Property with app deforested"
          }
        }
        
        if (car@data$Modu_Fisc<=4){
          status$rl.area <- 0
          status$debt.rl <- 0
          status$credit.rl <- 0
          #status$obs
          status$TotalToRestore <- status$debt.app
        }else{
        # Calculate debt in app - 20% area of car
        # Defyning Legal Reserve area: %APP-20% area CAR
        status$rl.area <- abs( status$app.area - (status$car.area * 0.2) )
        
        # Identify forested area outside APP 
        F.rl <- (car.app != 1) * forest
        
        # Identifying if there are credit or debt in RL
        if ( maxValue(F.rl) == 0 ) {
          
          #There is no forest, debt = area of RL
          status$debt.rl <- status$rl.area
          status$credit.rl <- 0
          status$obs <- "Property deforested RL"
        } else {
          
          if ( ( zonal(r.car, F.rl, fun = 'count') [2,2]) - status$rl.area >= 0) {
            
            # If forest area in RL - 20%*CAR is >= 0, property has credit (i.e. does not have debt) 
            status$debt.rl <- 0
            status$credit.rl <- zonal(r.car, F.rl, fun = 'count')[2,2] - status$rl.area
            status$obs <- "Property with RL credit"
          } else {
            
            # if not, calculate debt:
            status$debt.rl <- abs( zonal( r.car, F.rl, fun = 'count')[2,2] - status$rl.area)
            status$credit.rl <- 0
            status$obs <- "Property RL debit"
          }
        }
      
        # total to be restored
        
        status$TotalToRestore <- trunc(status$debt.rl + status$debt.app)
        }
        #if ToRestore is less than 10 (number of iterations to restore), than ToRestore2Years will be 1 
        if ( (status$TotalToRestore > 0) & (status$TotalToRestore < restYears) ) {
          
          status$ToRestore2years <- 1
        } else {
          
          # To restore in 2 years: 1/10 each 2 years
          status$ToRestore2years <- trunc(status$TotalToRestore / restYears) #n pixel to be restored
        }
      }
      
    }
    
  }
  return(status)
}

