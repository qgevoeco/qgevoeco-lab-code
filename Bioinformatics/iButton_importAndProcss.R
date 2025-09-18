rm(list = ls())



####		XXX			XXX			XXX

####				 WARNING				####

# Below assumes iButton data does not shift its clock when entering/exiting
# DAYLIGHT SAVINGS TIME and so does NOT incorporate the added/subtracted hour 
# for daylight savings adjustments



################################################################################
#TODO change values below


#XXX FIXME 
## set to your own working directory
setwd("~/Documents/Turtles/Methods/iButton")

#XXX FIXME
## Set whether slash separating directories is either:
## "\\" for Windows or back slash "/" for Mac/Linux
slsh <- "/"  #<-- either "/" or "\\"

 
#XXX FIXME
## Name of folder in working directory - contains just the iButton downloads 
ibdfold <- "ibdata"


##################################
#XXX Choose one of the following:
##################################
## set `trim` TRUE if files are raw files as downloaded from the iButton
## set `trim` FALSE if files have had header and unnecessary dates deleted by hand
trim <- FALSE


# ONLY if `trim` == TRUE
  #TODO XXX
  ## Set the minimum and maximum dates to include
  ### Use the format for date and time as below
  ### pay attention to the time to start and finish days
  if(trim){
    minDate <- strptime("2019-06-11 00:00:01", format = "%Y-%m-%d %T", tz = "")
    maxDate <- strptime("2019-08-15 23:59:59", format = "%Y-%m-%d %T", tz = "") 
  }
  
  
##XXX END area where necessary to change values
################################################################################
################################################################################




# Below will create vector with all file names in it
## In folder that is supposed to only contain iButton download files (`ibdfold`)
fnms <- list.files(ibdfold)
  ### go through and only keep ones with ".csv" suffixes
  fnms <- fnms[grepl(".csv", fnms, fixed = TRUE)]
  nfnms <- length(fnms)  #<-- how many files

# Go through each file, import data, then trim/process, then create summary
## First create empty list object in which to place the processed data
ibdlst <- ibdsmrylst <- vector("list", length = nfnms)

for(i in 1:nfnms){
 cat(fnms[i], "\n")
 
  ifile <- paste0(ibdfold, slsh, fnms[i])
  ifnm <- strsplit(fnms[i], split = ".", fixed = TRUE)[[1L]][1L]

# (1) if data have not been trimmed  
  if(trim){
    # grab Wire/iButton Registration Number
    iRegNumLn <- read.csv(ifile, header = FALSE, nrows = 1, skip = 1)
      iRegNum <- strsplit(as.character(iRegNumLn[1]), split = ": ")[[1L]][2L] 
    # grab just data and skip header with information about iButton program
    idf <- read.csv(ifile, header = TRUE, skip = 14)

  } else{
# (2) if data have been trimmed  
      # use file name as iButton identity
      iRegNum <- NA
      # grab data but do not skip any information 
      idf <- read.csv(ifile, header = TRUE)
    }

  # Double check that there are no dangling rows/columns full of NAs
  trimCol <- apply(idf, MARGIN = 2, FUN = function(x) all(is.na(x) | x == ""))
    if(any(trimCol)){
      idf <- idf[, !trimCol]    
    }
  trimRow <- apply(idf, MARGIN = 1, FUN = function(x) all(is.na(x) | x == ""))
    if(any(trimRow)){
      idf <- idf[!trimRow, ]    
    }
    
  # Now convert "Date.Time" column into R recognized Date format
  ## First do crude check if in 0-12 or 0-24 time format
  ihrs_tmp <- sapply(lapply(lapply(strsplit(idf$Date.Time, split = " "),
        FUN = "[[", i = 2),
      FUN = function(x){
      lapply(strsplit(x, split = ":", fixed = TRUE), FUN = "[[", i = 1)
    }),
    FUN = as.integer)
  if(max(ihrs_tmp) < 13){ 
    idf$date <- strptime(idf$Date.Time, format = "%m/%d/%y %r", tz = "")  
  } else{
      idf$date <- strptime(idf$Date.Time, format = "%m/%d/%y %R", tz = "") # equivalent %H:%M  
    }
    
    
# (2) Define minimum and maximum dates if data have already been trimmed    
  if(!trim){
    minDate <- min(idf$date)
    maxDate <- max(idf$date)
  }
  
  
  # Now add a separate column for julian day
  ## Set beginning as start of the year for the minimum date
  ## Specify GMT timezone so no funny business with daylight savings
  idf$julian <- julian(strptime(idf$date, "%Y-%m-%d", tz = "GMT"),
      origin = strptime(paste(format(minDate, "%Y"), "01", "01", sep = "-"),
        format = "%Y-%m-%d", tz = "GMT"))   
  
  # Now create Time of day column
  idf$time <- format(idf$date, "%T")
  # Create hour of the day in which time/temperature recorded
  idf$hour <- unlist(lapply(strsplit(idf$time, split = ":"), FUN = "[", i = 1))
      
  # Rename "Value"
  names(idf)[match("Value", names(idf))] <- "temp_C"
  
  # Add iButton names as columns
  idf$iRegNum <- iRegNum
  idf$ifnm <- ifnm
    
  # Add data to the list
  ## Drop original Date.Time and Unit columns, and re-order columns
  # trim data to include data between min and max dates
  ibdlst[[i]] <- idf[which(idf$date >= minDate & idf$date <= maxDate),
               c("iRegNum", "ifnm", "date", "julian", "time", "hour", "temp_C")]


  ####################
  # Create summaries
  ####################
  dailyMin <- aggregate(temp_C ~ as.character(strptime(date, "%Y-%m-%d",
                                                                   tz = "GMT")),
    data = ibdlst[[i]], FUN = min)  
  dailyMean <- aggregate(temp_C ~ as.character(strptime(date, "%Y-%m-%d",
                                                                   tz = "GMT")),
    data = ibdlst[[i]], FUN = mean)  
  dailyMax <- aggregate(temp_C ~ as.character(strptime(date, "%Y-%m-%d",
                                                                   tz = "GMT")),
    data = ibdlst[[i]], FUN = max)  

  ibdsmrylst[[i]] <- data.frame(iRegNum = iRegNum, ifnm = ifnm,
    date = as.Date(dailyMin[, 1], tz = "GMT"),
    julian = julian(strptime(as.Date(dailyMin[, 1]), "%Y-%m-%d", tz = "GMT"),
      origin = strptime(paste(format(minDate, "%Y"), "01", "01", sep = "-"),
        format = "%Y-%m-%d", tz = "GMT")),
    dailyMin_C = dailyMin[, 2],
    dailyMean_C = dailyMean[, 2],
    dailyMax_C = dailyMax[, 2])  
    
}  #<-- end of for loop               
  
# Convert list to data.frame
ibdf <- do.call("rbind", ibdlst)
ibdsmry <- do.call("rbind", ibdsmrylst)


#XXX SAVE as an R object so the classes are PRESERVED (e.g., "Date" format)
save("ibdlst", "ibdf", "ibdsmrylst", "ibdsmry",
  file = paste0(ibdfold, slsh, "ibutton_Robjs.rdata"))
  # To get this back into R then all you need to do is:
  ## `load(file = paste0(ibdfold, slsh, "ibutton_Robjs.rdata"))`
################################################################################







################################################################################

# EXAMPLE code to use with "ibutton_Robjs.rdata" just created above

 
# get average hourly temperature by iButton (using registration number)
## (could use file name, `ifnm`, instead of registration number)
avgHourTempByID <- aggregate(temp_C ~ hour + iRegNum, data = ibdf, FUN = mean)

# get average hourly temperature across iButton averages
avgHrlyTemp <- aggregate(temp_C ~ hour, data = avgHourTempByID, FUN = mean)
 
 
################################
# Plot, taking advantage of R's Date format and date axis plotting     
## For example, plot daily average temperature for all ibuttons

# find unique ibuttons in data
uib <- unique(ibdsmry$ifnm)
# creat a bunch of different combos of line types & colors - one for each ibutton
uclrs <- c("blue1", "blue4", "brown1", "brown4", "coral1", "coral4",
  "darkorange1", "darkorange4", "gold1", "gold4", "gray40", "gray90",
  "green1", "green4", "lightblue2", "lightblue3", "purple1", "purple4")
clrs <- rep(uclrs, each = ceiling(length(uib) / length(uclrs)))[1:length(uib)]
ltys <- rep(c("solid", "dotted", "dashed"), length(uclrs))[1:length(uib)]


plot(dailyMean_C ~ date, data = ibdsmry, axes = FALSE, type = "n")
  # add lines one by one
  for(i in 1:length(uib)){
    lines(dailyMean_C ~ date, data = ibdsmry, subset = ifnm == uib[i],
      col = clrs[i], lty = ltys[i], lwd = 2)
  }

  # "date" axis
  axis.Date(1, seq(min(ibdsmry$date), max(ibdsmry$date), by = "months"))
  axis(2, seq(22, 36, 2))  #<-- regular plotting y-axis
