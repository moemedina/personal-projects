##### Dependencies #####

## Setup 
wd <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
setwd(wd)
set.seed(156940)
options(scipen=999)

## Downloading / Loading dependencies
list.of.packages <- c("data.table","dplyr","readxl","lubridate","zoo","haven",
                      "stringr", "tidyr", "ggplot2", "ggpubr", "gdata", "patchwork",
                      "fixest", "lfe", "stargazer")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages) 
lapply(list.of.packages, library, character.only = TRUE) 

##### Creating evento de estudio #####

# Daily calendar with time-to-event defined in number of weeks from the saint festivity. 
calendario <- 
  daily_df_patronal %>%
  dplyr::select(KEY, year, day_wo_year, n_week, festividad_patronal, time_to_event, treatment)

# Join each of my election surveys with the time-to-event variable
# 8,959 surveys from 2012 to 2024
base_event_study <- 
  calculo_polarizacion %>% 
  left_join(., calendario, by = c("KEY"="KEY","year"="year","fecha_wo_year"="day_wo_year"))

base_event_study2 <- 
  calculo_polarizacion2 %>% 
  left_join(., calendario, by = c("KEY"="KEY","year"="year","fecha_wo_year"="day_wo_year")) %>%
  dplyr::select("KEY", "name","year","fecha_wo_year","polarizacion1")

base_event_study <- 
  base_event_study %>% 
  left_join(., base_event_study2, by = c("KEY", "name","year","fecha_wo_year"))

# Clean cases with NaN: Wrong entity, or municipality, or any NaN 
# 8,959 to 8,551
base_event_study <- base_event_study[complete.cases(base_event_study), ]

# Creating some fixed effects columns: 
base_event_study <- base_event_study %>% 
  # Week number + Year (Fixed effect)
  dplyr::mutate(nweek_year = paste0(n_week,"_",year)) %>%
  tidyr::separate(., name, into = c("encuesta","fecha","edo","mun"), sep = "_") %>%
  # CASA ENCUESTADORA
  dplyr::mutate(encuesta_fechayear = toupper(encuesta),
                encuesta_fechayear = ifelse(encuesta_fechayear == "MERCAI","MERCAEI",encuesta_fechayear),
                encuesta_fechayear = ifelse(encuesta_fechayear == "VALERA","VARELA",encuesta_fechayear),
                encuesta_fechayear = ifelse(encuesta_fechayear == "ZACATECASIMAGEN",
                                            "ZACATECAS",encuesta_fechayear)) %>%
  #dplyr::mutate(encuesta_fechayear = paste0(encuesta,"_",fecha_wo_year,"_",year)) %>%
  tidyr::separate(., KEY, into = c("EDO","MUN"), sep = "_") %>%
  dplyr::mutate(KEY = paste0(EDO,"_",MUN),
                EDOYEAR = paste0(EDO,"_",year))

## Filtering out those EDO-MUN Where we don't have any saint festivity to compare with. 
# Base KEY, encuesta_fechayear, nweek_year, ideologia_presidente, polarizacion, time_to_event, treatment
base_event_study_f <- 
  base_event_study %>% 
  dplyr::select(KEY, 
                encuesta_fechayear, 
                nweek_year, 
                EDOYEAR, 
                EDO, 
                ideologia_presidente_centro, 
                polarizacion_con_centro, 
                polarizacion_sin_centro,
                polarizacion1,
                time_to_event,
                treatment) %>% 
  # Filter out those EDO-MUN where we don't have any saint festivity to compare with. 
  dplyr::filter(treatment==1) %>%
  dplyr::mutate(
    year=substr(nweek_year,
                nchar(nweek_year)-4,
                nchar(nweek_year)
          )
  )

##### First results: only filtering NaN and non saint festivity to compare with #####

## BOX PLOT INDEX DISTRIBUTION
boxplot_plot1 <- ggplot(base_event_study_f, aes(x = factor(year), y = polarizacion_con_centro)) +
  geom_boxplot() +
  labs(x = "Año", y = "Opción 1 (0 a 1) con centro en el denominador",
       caption = "0 Nivel mínimo // +1 Nivel máximo") + theme_pubclean(base_size = 12) 

print(boxplot_plot1)

## TIME TO EVENT PLOTS 
dd_plot_reg1 <- feols(polarizacion_con_centro ~ i(time_to_event, treatment, ref = -1) | 
                       encuesta_fechayear + nweek_year + EDO, 
                     cluster = "KEY",
                     data = base_event_study_f)

ip <- iplot(dd_plot_reg1)

## TWFE (CLASSIC ESTIMATION)
base_event_study_f <- 
  dplyr::mutate(base_event_study_f, 
                treatment_dummy = ifelse(time_to_event %in% c(0,1,2,3),1,0), # treated
                year=substr(encuesta_fechayear,
                            nchar(encuesta_fechayear)-3,
                            nchar(encuesta_fechayear)),
                post_amlo = ifelse(year %in% c("2020","2021","2022","2023","2024"),1,0),  # post-amlo
                treatment_dummy_post = treatment_dummy*post_amlo) %>%       # interaccion
  dplyr::select(-year)

r1_new_sc <- felm(polarizacion_sin_centro ~ treatment_dummy |
                  nweek_year + EDO | # efectos fijos
                  0 |                                     # IV
                  KEY,                                    # cluster
                  data = base_event_study_f)



r1_new_sc_lim <- felm(polarizacion_sin_centro ~ treatment_dummy |
                      nweek_year + EDO | # efectos fijos
                      0 |                                     # IV
                      KEY,                                    # cluster
                      data = base_event_study_f %>%
                      dplyr::filter(time_to_event %in% -7:7))

r1_new_cc <- felm(polarizacion_con_centro ~ treatment_dummy |
                  nweek_year + EDO | # efectos fijos
                  0 |                                     # IV
                  KEY,                                    # cluster
                  data = base_event_study_f)

r1_new_cc_lim <- felm(polarizacion_con_centro ~ treatment_dummy |
                      nweek_year + EDO | # efectos fijos
                      0 |                                     # IV
                      KEY,                                    # cluster
                      data = base_event_study_f %>%
                      dplyr::filter(time_to_event %in% -7:7))

a <- felm(polarizacion1 ~ treatment_dummy |
          nweek_year + EDO | # efectos fijos
          0 |                                     # IV
          KEY,                                    # cluster
          data = base_event_study_f)



b <- felm(polarizacion1 ~ treatment_dummy |
          nweek_year + EDO | # efectos fijos
          0 |                                     # IV
          KEY,                                    # cluster
          data = base_event_study_f %>%
          dplyr::filter(time_to_event %in% -7:7))



tabldedd <- stargazer(r1_new_sc, r1_new_sc_lim, r1_new_cc, r1_new_cc_lim, a, b,
                      header = FALSE,
                      font.size = "scriptsize",
                      dep.var.labels.include = FALSE,
                      table.placement = "H",
                      column.labels = c("All sc new",
                                        "Lim sc new",
                                        "All cc new",
                                        "Lim cc new",
                                        "All old",
                                        "Lim old"),
                      covariate.labels = c("Festividad (0 a 3)"),
                      omit.stat = c("f", "ser","adj.rsq"),
                      add.lines = list(c("Efectos fijos Estado", "Sí", "Sí", "Sí", "Sí","Sí", "Sí"),
                                       c("Efectos fijos semana-año", "Si", "Si", "Sí", "Sí","Sí", "Sí"),
                                       c("Efectos fijos por casa encuestadora", "No", "No", "No", "No","No", "No")),
                      title = "Efectos fijos: Estado, Semana, Encuesta",
                      type = "text")

gc()