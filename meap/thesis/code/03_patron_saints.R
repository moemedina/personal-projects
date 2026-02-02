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

##### Patron Saint Data #####
# **NEED TO BE MODIFIED IF THERE ARE DATES OUTSIDE THE RANGE**
#  The calendar of patron saint holidays obtained by Montero & Yang.

# The dates of patron saint holidays that do not have a fixed date were manually coded. The following results are obtained:
# - Patron Saint Holidays: clear dates from Montero & Yang
# - National Holidays: dates entered manually because the date is not fixed
# - Important Holidays: adapted for MX (an attempt was made to see if adding national holidays would add explanation to this effect); it was rejected.

##### Data from Montero & Yang #####
fiestas_patronales <- read_dta(paste0(wd,"/documents/festmonth_muni_final.dta"))
fiestas_patronales <- 
  fiestas_patronales %>%
  dplyr::select(stateid, mun, saint, description, fest_month, datefest) %>%
  dplyr::mutate(KEY = paste0(stateid,"_",mun),
                fecha = as.Date(paste0(datefest,"-",fest_month), format = "%d-%m"),
                fecha_key = format(fecha, "%d-%m")) %>% 
  arrange(stateid,mun)

##### Manual inputation #####
# holidays without a clear date
sin_exito <- c("jesus de nazaret", "maria uicab", "orden de los franciscanos", "senor del sacromonte", "vida pasion y muerte de cristo")
fiestas_na <- # Obtaining from where 
  filter(fiestas_patronales, is.na(fecha)) %>%
  filter(., fest_month != ".") %>% left_join(., edo_mun, by = "KEY") %>%
  dplyr::select(saint, KEY, NOM_ENT, NOM_MUN) %>% arrange(saint) %>%
  dplyr::filter(!(saint %in% sin_exito))

fechas_anuales <- # One per year
  data.frame(
    fecha_anual = c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024) # TO MODIFY
  )

fiestas_na <- cross_join(fiestas_na, fechas_anuales) 

fiestas_patronales <- fiestas_patronales %>% dplyr::filter(!(is.na(fecha)))

# Manually adding known holidays that are not included! (Manually Search!!)
fiestas_na <- fiestas_na %>%
  dplyr::mutate(
    dia = 99, 
    mes = 12, 
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2011, 5, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2012, 20, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2014, 29, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2015, 14, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2017, 25, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2018, 10, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2020, 21, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2021, 13, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2023, 18, dia),
    dia = ifelse(saint == "ascension del senor" & fecha_anual == 2024, 9, dia),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2011, 6, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2012, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2014, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2015, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2017, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2018, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2020, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2021, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2023, 5, mes),
    mes = ifelse(saint == "ascension del senor" & fecha_anual == 2024, 5, mes),
    dia = ifelse(saint == "cinco senores", 23, dia),
    mes = ifelse(saint == "cinco senores", 10, mes),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2011, 23, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2012, 7, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2014, 19, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2015, 4, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2017, 15, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2018, 31, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2020, 11, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2021, 3, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2023, 8, dia),
    dia = ifelse(saint == "corpus cristi" & fecha_anual == 2024, 30, dia),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2011, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2012, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2014, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2015, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2017, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2018, 5, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2020, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2021, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2023, 6, mes),
    mes = ifelse(saint == "corpus cristi" & fecha_anual == 2024, 5, mes),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2011, 28, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2012, 12, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2014, 21, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2015, 6, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2017, 17, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2018, 2, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2020, 13, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2021, 5, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2023, 20, dia),
    dia = ifelse(saint == "cristo de la salud" & fecha_anual == 2024, 20, dia),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2011, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2012, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2014, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2015, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2017, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2018, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2020, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2021, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2023, 5, mes),
    mes = ifelse(saint == "cristo de la salud" & fecha_anual == 2024, 5, mes),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2011, 20, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2012, 25, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2014, 23, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2015, 21, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2017, 26, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2018, 25, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2020, 22, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2021, 21, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2023, 26, dia),
    dia = ifelse(saint == "cristo rey" & fecha_anual == 2024, 24, dia),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2011, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2012, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2014, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2015, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2017, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2018, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2020, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2021, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2023, 11, mes),
    mes = ifelse(saint == "cristo rey" & fecha_anual == 2024, 11, mes),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2011, 12, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2012, 27, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2014, 8, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2015, 24, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2017, 4, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2018, 20, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2020, 31, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2021, 23, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2023, 28, dia),
    dia = ifelse(saint == "espiritu santo" & fecha_anual == 2024, 19, dia),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2011, 6, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2012, 5, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2014, 6, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2015, 5, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2017, 6, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2018, 5, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2020, 5, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2021, 5, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2023, 5, mes),
    mes = ifelse(saint == "espiritu santo" & fecha_anual == 2024, 5, mes),
    dia = ifelse(saint == "jose de aura", 30, dia),
    mes = ifelse(saint == "jose de aura", 9, mes),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2011, 18, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2012, 2, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2014, 14, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2015, 30, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2017, 10, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2018, 26, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2020, 6, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2021, 29, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2023, 3, dia),
    dia = ifelse(saint == "lunes santo" & fecha_anual == 2024, 25, dia),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2012, 4, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2014, 4, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2017, 4, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2020, 4, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2023, 4, mes),
    mes = ifelse(saint == "lunes santo" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "padre jesus de petatlan en Petatlan", 6, dia),
    mes = ifelse(saint == "padre jesus de petatlan en Petatlan", 8, mes),
    dia = ifelse(saint == "preciosa sangre de cristo", 1, dia),
    mes = ifelse(saint == "preciosa sangre de cristo", 7, mes),
    dia = ifelse(saint == "sagrada familia", 30, dia),
    mes = ifelse(saint == "sagrada familia", 12, mes),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2011, 1, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2012, 15, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2014, 27, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2015, 17, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2017, 27, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2018, 8, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2020, 19, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2021, 11, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2023, 16, dia),
    dia = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2024, 7, dia),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2011, 7, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2012, 7, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2014, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2015, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2017, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2018, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2020, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2021, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2023, 6, mes),
    mes = ifelse(saint == "sagrado corazon de jesus" & fecha_anual == 2024, 6, mes),
    dia = ifelse(saint == "sagrado corazon de maria", 22, dia),
    mes = ifelse(saint == "sagrado corazon de maria", 22, mes),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2011, 19, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2012, 3, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2014, 15, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2015, 31, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2017, 11, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2018, 27, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2020, 7, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2021, 30, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2023, 30, dia),
    dia = ifelse(saint == "santisima trinidad" & fecha_anual == 2024, 30, dia),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2011, 6, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2012, 6, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2014, 6, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2015, 5, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2017, 6, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2018, 5, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2020, 6, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2021, 5, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2023, 5, mes),
    mes = ifelse(saint == "santisima trinidad" & fecha_anual == 2024, 5, mes),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2011, 17, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2012, 1, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2014, 13, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2015, 29, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2017, 9, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2018, 25, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2020, 5, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2021, 28, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2023, 5, dia),
    dia = ifelse(saint == "semana santa" & fecha_anual == 2024, 28, dia),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2012, 4, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2014, 4, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2017, 4, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2020, 4, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2023, 4, mes),
    mes = ifelse(saint == "semana santa" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2011, 20, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2012, 18, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2014, 16, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2015, 15, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2017, 19, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2018, 18, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2020, 15, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2021, 21, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2023, 19, dia),
    dia = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2024, 17, dia),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2011, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2012, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2014, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2015, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2017, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2018, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2020, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2021, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2023, 11, mes),
    mes = ifelse(saint == "senor crucificado de la capilla de tamazola" & fecha_anual == 2024, 11, mes),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2011, 1, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2012, 16, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2014, 21, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2015, 13, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2017, 24, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2018, 9, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2020, 13, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2021, 12, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2023, 17, dia),
    dia = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2024, 8, dia),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2012, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2014, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2017, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2020, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2023, 3, mes),
    mes = ifelse(saint == "senor crucificado de la capilla en Tezoatlan de Segura y Luna" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor de la columna en Santa Catarina Yosonotu", 25, dia),
    mes = ifelse(saint == "senor de la columna en Santa Catarina Yosonotu", 11, mes),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2011, 30, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2012, 28, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2014, 26, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2015, 25, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2017, 29, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2018, 28, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2020, 25, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2021, 25, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2023, 28, dia),
    dia = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2024, 28, dia),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2011, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2012, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2014, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2015, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2017, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2018, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2020, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2021, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2023, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Acultzingo" & fecha_anual == 2024, 7, mes),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2011, 30, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2012, 28, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2014, 26, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2015, 25, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2017, 29, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2018, 28, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2020, 25, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2021, 25, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2023, 29, dia),
    dia = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2024, 29, dia),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2011, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2012, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2014, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2015, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2017, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2018, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2020, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2021, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2023, 7, mes),
    mes = ifelse(saint == "senor de la expiracion en Guadalupe" & fecha_anual == 2024, 7, mes),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2011, 18, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2012, 2, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2014, 14, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2015, 27, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2017, 10, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2018, 23, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2020, 6, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2021, 26, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2023, 3, dia),
    dia = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2024, 23, dia),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2011, 3, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2012, 3, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2014, 3, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2015, 2, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2017, 3, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2018, 2, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2020, 3, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2021, 2, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2023, 3, mes),
    mes = ifelse(saint == "senor de la santa veracruz en Sultepec" & fecha_anual == 2024, 2, mes),
    dia = ifelse(saint == "senor de las angustias", 15, dia),
    mes = ifelse(saint == "senor de las angustias", 1, mes),
    dia = ifelse(saint == "senor de las tres caidas", 4, dia),
    mes = ifelse(saint == "senor de las tres caidas", 8, mes),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2011, 1, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2012, 6, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2014, 4, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2015, 3, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2017, 7, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2018, 6, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2020, 3, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2021, 2, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2023, 5, dia),
    dia = ifelse(saint == "senor de los milagros" & fecha_anual == 2024, 3, dia),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2011, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2012, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2014, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2015, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2017, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2018, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2020, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2021, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2023, 10, mes),
    mes = ifelse(saint == "senor de los milagros" & fecha_anual == 2024, 10, mes),
    dia = ifelse(saint == "senor de santa rosa", 30, dia),
    mes = ifelse(saint == "senor de santa rosa", 8, mes),
    dia = ifelse(saint == "senor de singuilucan en Singuilucan", 27, dia),
    mes = ifelse(saint == "senor de singuilucan en Singuilucan", 5, mes),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2011, 25, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2012, 9, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2014, 21, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2015, 4, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2017, 17, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2018, 30, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2020, 13, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2021, 3, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2023, 10, dia),
    dia = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2024, 1, dia),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2011, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2012, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2014, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2017, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2018, 2, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2020, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2023, 3, mes),
    mes = ifelse(saint == "senor de zacualpilla" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2011, 17, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2012, 1, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2014, 13, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2015, 29, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2017, 9, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2018, 25, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2020, 5, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2021, 28, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2023, 18, dia),
    dia = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2024, 28, dia),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2012, 4, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2014, 4, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2017, 4, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2020, 4, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2023, 4, mes),
    mes = ifelse(saint == "senor del entierro en Coahuitlan" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2011, 17, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2012, 1, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2014, 13, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2015, 29, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2017, 9, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2018, 25, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2020, 5, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2021, 28, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2023, 15, dia),
    dia = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2024, 15, dia),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2012, 4, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2014, 4, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2017, 4, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2020, 4, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2023, 3, mes),
    mes = ifelse(saint == "senor del entierro en Huauchinango" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2011, 17, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2012, 1, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2014, 13, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2015, 29, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2017, 9, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2018, 25, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2020, 5, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2021, 28, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2023, 5, dia),
    dia = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2024, 28, dia),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2012, 4, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2014, 4, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2017, 4, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2020, 4, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2023, 4, mes),
    mes = ifelse(saint == "senor del entierro en Hueypoxtla" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2011, 17, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2012, 1, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2014, 13, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2015, 29, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2017, 9, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2018, 25, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2020, 5, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2021, 28, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2023, 5, dia),
    dia = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2024, 28, dia),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2011, 4, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2012, 4, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2014, 4, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2015, 3, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2017, 4, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2018, 3, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2020, 4, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2021, 3, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2023, 4, mes),
    mes = ifelse(saint == "senor del entierro en Xalpatlahuac" & fecha_anual == 2024, 3, mes),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2011, 3, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2012, 1, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2014, 6, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2015, 5, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2017, 2, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2018, 1, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2020, 5, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2021, 4, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2023, 2, dia),
    dia = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2024, 2, dia),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2011, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2012, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2014, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2015, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2017, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2018, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2020, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2021, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2023, 7, mes),
    mes = ifelse(saint == "senor del monte en Jocotepec" & fecha_anual == 2024, 7, mes),
    dia = ifelse(saint == "senor del perdon en San Pedro y San Pablo Tequixtepec", 2, dia),
    mes = ifelse(saint == "senor del perdon en San Pedro y San Pablo Tequixtepec", 3, mes),
    dia = ifelse(saint == "senor del perdon en Tuxpan", 25, dia),
    mes = ifelse(saint == "senor del perdon en Tuxpan", 10, mes),
    dia = ifelse(saint == "senor del pozo", 11, dia),
    mes = ifelse(saint == "senor del pozo", 3, mes),
    dia = ifelse(saint == "senor del salitre", 13, dia),
    mes = ifelse(saint == "senor del salitre", 5, mes),
    dia = ifelse(saint == "senor grande de ameca", 15, dia),
    mes = ifelse(saint == "senor grande de ameca", 5, mes),
    dia = ifelse(saint == "virgen de el pueblito", 5, dia),
    mes = ifelse(saint == "virgen de el pueblito", 2, mes)
  )

fiestas_na <- 
  fiestas_na %>%
  dplyr::mutate(
    fecha = as.Date(paste0(dia,"-",mes), format = "%d-%m"),
    fecha_key = format(fecha, "%d-%m"))

semana_santa_fechas <- filter(fiestas_na, saint == "semana santa") %>% distinct(saint, fecha_anual, dia, mes, fecha, fecha_key)

cristo_rey_fechas <- filter(fiestas_na, saint == "cristo rey") %>% distinct(saint, fecha_anual, dia, mes, fecha, fecha_key)

navidad_fechas <- data.frame(
  saint = "navidad", 
  fecha_anual = c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024),
  dia = 24,
  mes = 12)

navidad_fechas <- navidad_fechas %>% dplyr::mutate(
  fecha = as.Date(paste0(dia,"-",mes), format = "%d-%m"),
  fecha_key = format(fecha, "%d-%m")
)

dia_independencia <- data.frame(
  saint = "independencia", 
  fecha_anual = c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024),
  dia = 16,
  mes = 9)

dia_independencia <- dia_independencia %>% dplyr::mutate(
  fecha = as.Date(paste0(dia,"-",mes), format = "%d-%m"),
  fecha_key = format(fecha, "%d-%m")
)

dia_muertos <- data.frame(
  saint = "dia de muertos", 
  fecha_anual = c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024),
  dia = 1,
  mes = 11)

dia_muertos <- dia_muertos %>% dplyr::mutate(
  fecha = as.Date(paste0(dia,"-",mes), format = "%d-%m"),
  fecha_key = format(fecha, "%d-%m")
)

dia_reyes <- data.frame(
  saint = "reyes", 
  fecha_anual = c(2011,2012,2014,2015,2017,2018,2020,2021,2023,2024),
  dia = 6,
  mes = 1)

dia_reyes <- dia_reyes %>% dplyr::mutate(
  fecha = as.Date(paste0(dia,"-",mes), format = "%d-%m"),
  fecha_key = format(fecha, "%d-%m")
)

important_dates <- rbind(semana_santa_fechas, cristo_rey_fechas)
important_dates <- rbind(important_dates, navidad_fechas)
important_dates <- rbind(important_dates, dia_independencia)
important_dates <- rbind(important_dates, dia_muertos)
important_dates <- rbind(important_dates, dia_reyes)

all_KEY <- distinct(daily_df, KEY)

important_dates <- cross_join(all_KEY, important_dates)

fiestas_patronales <- 
  fiestas_patronales %>%
  dplyr::select(KEY, fecha_key) %>%
  dplyr::mutate(fiesta_patronal = 1)

fiestas_na <- 
  fiestas_na %>% 
  dplyr::select(KEY, fecha_anual, fecha_key) %>%
  dplyr::mutate(fiesta_patronal_na = 1)

important_dates <- 
  important_dates %>%
  dplyr::select(KEY, fecha_anual, fecha_key) %>% 
  dplyr::mutate(important_date = 1)

##### Joins with calendar #####
# The calendar with the dates of the patron saint festivals of Montero and Yang is pasted. 
# And for the Variable Dates! A dummy is created to determine if there is a patron saint festival on that day.
# Identifying Days in the year with a Holiday of interest!! 
daily_df_patronal <- 
  daily_df %>%
  left_join(., fiestas_patronales, by = c("KEY"="KEY", "day_wo_year"="fecha_key"))
daily_df_patronal[is.na(daily_df_patronal)]<-0 

daily_df_patronal <- 
  daily_df_patronal %>%
  left_join(., fiestas_na, by = c("KEY"="KEY", "day_wo_year"="fecha_key", "year"="fecha_anual"))
daily_df_patronal[is.na(daily_df_patronal)]<-0

daily_df_patronal <- 
  daily_df_patronal %>%
  dplyr::mutate(festividad_patronal = ifelse(fiesta_patronal+fiesta_patronal_na>0,1,0)) %>%
  dplyr::select(-c(fiesta_patronal, fiesta_patronal_na))

##### Time distance (in weeks) between a week and a holiday #####
# The time dummy between the week and the holiday is calculated. And the structure for the DiD is prepared.
# Solo hay 1 festividad máximo por municipio - desde la data de montero y yang -> no habrá problema de calcular tiempo del tratamiento. 
daily_a_weekly <-
  daily_df_patronal %>% 
  dplyr::group_by(KEY, NOM_ENT, NOM_MUN, year, n_week) %>%
  dplyr::summarise(festividad = max(festividad_patronal)) %>% ungroup()

## group by año y municipio. time = n_week y post es la semana de mi festividad. 
daily_a_weekly <- 
  daily_a_weekly %>% 
  dplyr::group_by(KEY, NOM_ENT, NOM_MUN, year) %>%
  dplyr::mutate(event_time = n_week[festividad > 0][1]) %>% ungroup() %>%
  dplyr::arrange(NOM_ENT, NOM_MUN, year)

# Mi treatment es haber recibido festividad (si no tuvieron entonces event study = NA)
daily_a_weekly$event_time[is.na(daily_a_weekly$event_time)] <- 0

# Creamos variable de tiempo a tratamiento (=1 si festividad -> event)
daily_a_weekly <- 
  daily_a_weekly %>%
  dplyr::mutate(treatment = ifelse(event_time == 0 & festividad == 0, 0, 1))

# Creamos variable de tiempo a tratamiento 
daily_a_weekly <- 
  daily_a_weekly %>% 
  dplyr::group_by(KEY, NOM_ENT, NOM_MUN, year) %>% 
  dplyr::mutate(time_to_event = ifelse(treatment == 1, n_week - event_time, 0)) %>% ungroup() %>%
  dplyr::select(KEY, n_week, year, time_to_event, treatment)

daily_df_patronal <- 
  daily_df_patronal %>%
  dplyr::left_join(., daily_a_weekly, by = c("KEY", "n_week", "year"))

gc()