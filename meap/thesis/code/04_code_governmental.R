##### Dependencies #####

## Setup 
wd <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
setwd(wd)
set.seed(156940)
options(scipen=999)

## Downloading / Loading dependencies
list.of.packages <- c("data.table","dplyr","readxl","lubridate","zoo","haven")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages) 
lapply(list.of.packages, library, character.only = TRUE) 

##### governmental dataset #####
# Two alternatives: Izquierda y Derecha ||| Izquierda, Derecha y Centro. 
# If you add temporality, you have to add the ideological component according to the current government's alliances!
start_date <- as.Date("2011-01-01")  # Adjust the start date as needed
end_date <- as.Date("2025-01-01")    # Adjust the end date as needed

# Generate a sequence of dates representing each week
presidente_dates <- seq(start_date, end_date, by = "1 month")
presidente <- data.frame(presidente_dates)

presidente <- 
  presidente %>%
  dplyr::mutate(
    year = year(presidente_dates),
    month = month(presidente_dates),
    nombre = "", 
    nombre = 
      case_when(
        year == 2011 ~ "FCH", 
        year == 2012 & month < 12 ~ "EPN", 
        year == 2012 & month == 12 ~ "EPN", 
        year %in% c(2014,2015,2017) ~ "EPN", 
        year == 2018 & month < 12 ~ "EPN", 
        year == 2018 & month == 12 ~ "AMLO",
        year %in% c(2020,2021,2023,2024) ~ "AMLO"
      ),
    ideologia_presidente = 
      case_when(
        nombre == "FCH" | nombre == "EPN" ~ "Derecha", 
        nombre == "AMLO" ~ "Izquierda"
      ),
    ideologia_presidente_centro = 
      case_when(
        nombre == "FCH" ~ "Derecha", 
        nombre == "AMLO" ~ "Izquierda",
        nombre == "EPN" ~ "Centro",
      )
  ) %>% 
  dplyr::filter(year %in% c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024))

## IDEOLOGIA 
ideologia_df <- 
  data.frame(
    partido = c(rep(c("PAN","PRI","PRD","PVEM","PT","MC","PANAL",
                      "PRI-PVEM","PRD-PT-MC","PRD-PT","PRD-MC","PT-MC"),2),
                rep(c("PAN","PRI","PRD","PVEM","PT","MC","PANAL","MORENA","PH","PES","PRI-PVEM","PRD-PT"),2),
                rep(c("PAN","PRI","PRD","PVEM","PT","MC","MORENA","PES",
                      "PAN-PRD-MC","PRI-PVEM-PANAL","PT-MORENA-PES"),2),
                rep(c("PAN","PRI","PRD","PVEM","PT","MC","MORENA","PES","RSP","FXM",
                      "PAN-PRI-PRD","PVEM-PT-MORENA"),4)),
    ideologia_persona = c(rep(c("Derecha","Derecha","Izquierda","Derecha","Izquierda","Izquierda","Derecha",
                                "Derecha","Izquierda","Izquierda","Izquierda","Izquierda"),2),
                          rep(c("Derecha","Derecha","Izquierda","Derecha","Izquierda","Izquierda","Derecha",
                                "Izquierda","Derecha","Derecha","Derecha","Izquierda"),2),
                          rep(c("Derecha","Derecha","Derecha","Derecha","Izquierda","Derecha","Izquierda",
                                "Izquierda","Derecha","Derecha","Izquierda"),2),
                          rep(c("Derecha","Derecha","Derecha","Izquierda","Izquierda","Derecha",
                                "Izquierda","Izquierda","Izquierda","Izquierda","Derecha","Izquierda"),4)),
    ideologia_persona_centro = c(rep(c("Derecha","Centro","Izquierda","Centro","Izquierda","Izquierda","Derecha",
                                       "Centro","Izquierda","Izquierda","Izquierda","Izquierda"),2),
                                 rep(c("Derecha","Centro","Izquierda","Centro","Izquierda","Izquierda","Derecha",
                                       "Izquierda","Derecha","Derecha","Centro","Izquierda"),2),
                                 rep(c("Derecha","Centro","Derecha","Centro","Izquierda","Derecha","Izquierda",
                                       "Izquierda","Derecha","Centro","Izquierda"),2),
                                 rep(c("Derecha","Derecha","Derecha","Izquierda","Izquierda","Derecha",
                                       "Izquierda","Izquierda","Izquierda","Izquierda","Derecha","Izquierda"),4)),
    year = c(rep(2011,12), rep(2012,12), rep(2014,12), rep(2015,12), rep(2017,11), rep(2018,11),
             rep(2020,12), rep(2021,12), rep(2023,12), rep(2024,12))
    
  )

gc()