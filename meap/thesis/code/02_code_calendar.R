##### Dependencies #####

## Setup 
wd <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
setwd(wd)
set.seed(156940)
options(scipen=999)

## Downloading / Loading dependencies
list.of.packages <- c("data.table","dplyr","readxl","lubridate","zoo")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages) 
lapply(list.of.packages, library, character.only = TRUE) 

##### Creating Calendar ##### 
# **NEED TO MODIFY IF THERE ARE DATES OUTSIDE THE RANGE**
#  I create a daily and weekly calendar, given a start and end year, so I can count the weeks that passed between different events (I have the information at a daily level; first, I know what week it is, and then I can combine it with the weekly one, which is my time unit). Observations:
#  - I only keep the years in which federal surveys are conducted (INEGI).
#- The way  I created the weekly DF is not fully automated; the variable *n_week* must be added each time an additional year is added to the DF.

start_date <- as.Date("2011-01-01")  # Adjust the start date as needed
end_date <- as.Date("2025-12-31")    # Adjust the end date as needed

# Generate a sequence of dates representing each week
week_dates <- seq(start_date, end_date, by = "1 week")
daily_dates <- seq(start_date, end_date, by = "1 day")

# Create a data frame with a 'week' column
weekly_df <- data.frame(Week = week_dates)
daily_df <- data.frame(Day = daily_dates)

weekly_df <- 
  weekly_df %>% 
  dplyr::mutate(., 
                first_day = Week, 
                last_day = dplyr::lead(Week)-1,
                year = year(Week),
                month = month(Week),
                day = day(Week),
                n_week = c(seq(1,53,1),seq(1,52,1),seq(1,52,1),seq(1,52,1),seq(1,52,1),
                           seq(1,53,1),seq(1,52,1),seq(1,52,1),seq(1,52,1),seq(1,52,1),seq(1,52,1),
                           seq(1,53,1),seq(1,52,1),seq(1,52,1),seq(1,52,1))) %>%
  dplyr::filter(., year %in% c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024))

daily_df <- 
  daily_df %>%
  dplyr::left_join(., weekly_df, by = c("Day" = "Week")) %>%
  dplyr::mutate(., 
                year = year(Day), 
                month = month(Day), 
                day = day(Day), 
                day_wo_year = format(Day, "%d-%m")) %>%
  dplyr::filter(., year %in% c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024))

daily_df$first_day <- na.locf(daily_df$first_day)
daily_df$last_day <- na.locf(daily_df$last_day)
daily_df$n_week <- na.locf(daily_df$n_week)

# semana para cada uno de las combinaciones de "KEY (edo-mun)" 
edo_mun <- distinct(df_inegi, KEY, NOM_ENT, NOM_MUN)

daily_df <- cross_join(daily_df, edo_mun) %>% arrange(NOM_ENT, NOM_MUN, Day)

gc()