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

##### Cleaning Surveys: identify those were he have volatility (not only one survey) #####
df_encuestas_volatil <- 
  df_encuestas %>% 
  dplyr::group_by(., name, ideologia_persona_centro) %>%
  tally() %>% ungroup() %>%
  dplyr::mutate(hay = ifelse(n>=1,1,0)) %>%
  tidyr::pivot_wider(., id_cols = name, names_from = ideologia_persona_centro, values_from = hay) %>%
  replace(is.na(.),0) %>%
  dplyr::mutate(mas_de_una = ifelse(CENTRO+DERECHA+IZQUIERDA>1,1,0),
                der_y_izq = ifelse(DERECHA+IZQUIERDA>1,1,0)) %>%
  dplyr::select(., name, mas_de_una, der_y_izq)

# New index
calculo_polarizacion_filtrada <- 
  left_join(calculo_polarizacion, df_encuestas_volatil, by = "name")

# Old index
calculo_polarizacion_filtrada2 <- 
  left_join(calculo_polarizacion2, df_encuestas_volatil, by = "name")

# Daily calendar with time-to-event defined in number of weeks from the saint festivity. 
calendario <- 
  daily_df_patronal %>%
  dplyr::select(KEY, year, day_wo_year, n_week, festividad_patronal, time_to_event, treatment)

# Join each of my election surveys with the time-to-event variable
# 8,959 surveys from 2012 to 2024
base_event_study <- 
  calculo_polarizacion_filtrada %>% 
  left_join(., calendario, by = c("KEY"="KEY","year"="year","fecha_wo_year"="day_wo_year"))

base_event_study2 <- 
  calculo_polarizacion_filtrada2 %>% 
  left_join(., calendario, by = c("KEY"="KEY","year"="year","fecha_wo_year"="day_wo_year")) %>%
  dplyr::select("KEY", "name","year","fecha_wo_year","polarizacion1")

base_event_study <- 
  base_event_study %>% 
  left_join(., base_event_study2, by = c("KEY", "name","year","fecha_wo_year"))


# 8959 -> 8534 (por mal ubicacion y sin "polarizacion" completa: -7%) 
base_event_study <- base_event_study[complete.cases(base_event_study), ]

# Creating some fixed effects columns: 
base_event_study2 <- base_event_study %>%
  # Week number + Year (Fixed effect)
  dplyr::mutate(nweek_year = paste0(n_week,"_",year)) %>%
  separate(., name, into = c("encuesta","fecha","edo","mun"), sep = "_") %>%
  # CASA ENCUESTADORA
  dplyr::mutate(encuesta_fechayear = toupper(encuesta),
                encuesta_fechayear = ifelse(encuesta_fechayear == "MERCAI","MERCAEI",encuesta_fechayear),
                encuesta_fechayear = ifelse(encuesta_fechayear == "VALERA","VARELA",encuesta_fechayear),
                encuesta_fechayear = ifelse(encuesta_fechayear == "ZACATECASIMAGEN",
                                            "ZACATECAS",encuesta_fechayear)) %>%
  #dplyr::mutate(encuesta_fechayear = paste0(encuesta,"_",fecha_wo_year,"_",year)) %>%
  separate(., KEY, into = c("EDO","MUN"), sep = "_") %>%
  dplyr::mutate(KEY = paste0(EDO,"_",MUN),
                EDOYEAR = paste0(EDO,"_",year))

# Input or Filter records without diversity 
base_event_study_f <- 
  base_event_study2 %>% 
  dplyr::mutate(polarizacion1 = ifelse(mas_de_una == 0, 0, polarizacion1),
                polarizacion_sin_centro = ifelse(mas_de_una == 0, 0, polarizacion_sin_centro),
                polarizacion_con_centro = ifelse(mas_de_una == 0, 0, polarizacion_con_centro),
                post_amlo = ifelse(year %in% c("2020","2021","2022","2023","2024"),1,0)) %>%
  # IF WE WANT TO KEEP ONLY THOSE WHERE WE HAVE VOLATILITY 
  #dplyr::filter(mas_de_una == 1) %>%
  dplyr::select(KEY, 
                encuesta_fechayear, 
                nweek_year, 
                EDOYEAR,
                EDO,
                ideologia_presidente_centro,
                polarizacion1,
                polarizacion_con_centro, 
                polarizacion_sin_centro, 
                time_to_event,
                treatment,
                year,
                post_amlo,
                mas_de_una) %>%
  # we have a saint festivity defined for that EDO-MUN
  dplyr::filter(treatment==1)

## BOX PLOT INDEX DISTRIBUTION
boxplot_plot1 <- ggplot(base_event_study_f, aes(x = factor(year), y = polarizacion_con_centro)) +
  geom_boxplot() +
  labs(x = "Año", y = "Opción 1 (0 a 1) con centro en el denominador",
       caption = "0 Nivel mínimo // +1 Nivel máximo") + theme_pubclean(base_size = 12) 

boxplot_plot2 <- ggplot(base_event_study_f, aes(x = factor(year), y = polarizacion_sin_centro)) +
  geom_boxplot() +
  labs(x = "Año", y = "Opción 2 (0 a 1) sin centro en el denominador",
       caption = "0 Nivel mínimo // +1 Nivel máximo") + theme_pubclean(base_size = 12) 

boxplot_plot3 <- ggplot(base_event_study_f, aes(x = factor(year), y = polarizacion1)) +
  geom_boxplot() +
  labs(x = "Año", y = "Opción anterior (-1 a 1)",
       caption = "-1 Nivel mínimo // +1 Nivel máximo") + theme_pubclean(base_size = 12) 

print(boxplot_plot1)
print(boxplot_plot2)
print(boxplot_plot3)

## TIME TO EVENT PLOTS 

dd_plot_reg1 <- feols(polarizacion_con_centro ~ i(time_to_event, treatment, ref = -1) | 
                        encuesta_fechayear + nweek_year + EDO, 
                      cluster = "KEY",
                      data = base_event_study_f)

ip <- iplot(dd_plot_reg1)

dd_plot_reg2 <- feols(polarizacion_sin_centro ~ i(time_to_event, treatment, ref = -1) | 
                        encuesta_fechayear + nweek_year + EDO, 
                      cluster = "KEY",
                      data = base_event_study_f)

ip <- iplot(dd_plot_reg2)

dd_plot_reg3 <- feols(polarizacion1 ~ i(time_to_event, treatment, ref = -1) | 
                        encuesta_fechayear + nweek_year + EDO, 
                      cluster = "KEY",
                      data = base_event_study_f)

ip <- iplot(dd_plot_reg3)

## TWFE
base_event_study_f <- 
  dplyr::mutate(base_event_study_f, 
                treatment_dummy = ifelse(time_to_event %in% c(0,1,2,3),1,0),
                #year=substr(EDOYEAR,nchar(EDOYEAR)-3,nchar(EDOYEAR)),
                post_amlo = ifelse(year %in% c("2020","2021","2022","2023","2024"),1,0),
                treatment_dummy_post = treatment_dummy*post_amlo) %>%
  dplyr::select(-year)

r1_new_sc <- felm(polarizacion_sin_centro ~ treatment_dummy |
                    nweek_year + KEY | # efectos fijos
                    0 |                                     # IV
                    KEY,                                    # cluster
                  data = base_event_study_f)

mean1 <- round(mean(base_event_study_f$polarizacion_sin_centro),2)
median1 <- median(base_event_study_f$polarizacion_sin_centro)


r1_new_sc_lim <- felm(polarizacion_sin_centro ~ treatment_dummy |
                        nweek_year + KEY | # efectos fijos
                        0 |                                     # IV
                        KEY,                                    # cluster
                      data = base_event_study_f %>%
                        dplyr::filter(time_to_event %in% -7:7))

mean2 <- round(mean((base_event_study_f %>% dplyr::filter(time_to_event %in% -7:7))$polarizacion_sin_centro),2)
median2 <- median((base_event_study_f %>% dplyr::filter(time_to_event %in% -7:7))$polarizacion_sin_centro)

r1_new_cc <- felm(polarizacion_con_centro ~ treatment_dummy |
                    nweek_year + KEY | # efectos fijos
                    0 |                                     # IV
                    KEY,                                    # cluster
                  data = base_event_study_f)

mean3 <- round(mean(base_event_study_f$polarizacion_con_centro),2)
median3 <- median(base_event_study_f$polarizacion_con_centro)

r1_new_cc_lim <- felm(polarizacion_con_centro ~ treatment_dummy |
                        nweek_year + KEY | # efectos fijos
                        0 |                                     # IV
                        KEY,                                    # cluster
                      data = base_event_study_f %>%
                        dplyr::filter(time_to_event %in% -7:7))

mean4 <- round(mean((base_event_study_f %>% dplyr::filter(time_to_event %in% -7:7))$polarizacion_con_centro),2)
median4 <- median((base_event_study_f %>% dplyr::filter(time_to_event %in% -7:7))$polarizacion_con_centro)


a <- felm(polarizacion1 ~ treatment_dummy |
            nweek_year + KEY | # efectos fijos
            0 |                                     # IV
            KEY,                                    # cluster
          data = base_event_study_f)

mean5 <- round(mean(base_event_study_f$polarizacion1),2)
median5 <- median(base_event_study_f$polarizacion1)

b <- felm(polarizacion1 ~ treatment_dummy |
            nweek_year + KEY | # efectos fijos
            0 |                                     # IV
            KEY,                                    # cluster
          data = base_event_study_f %>%
            dplyr::filter(time_to_event %in% -7:7))

mean6 <- round(mean((base_event_study_f %>% dplyr::filter(time_to_event %in% -7:7))$polarizacion1),2)
median6 <- median((base_event_study_f %>% dplyr::filter(time_to_event %in% -7:7))$polarizacion1)

tabldedd <- stargazer(r1_new_cc, r1_new_cc_lim, a, b,
                      header = FALSE,
                      font.size = "scriptsize",
                      dep.var.labels.include = FALSE,
                      table.placement = "H",
                      column.labels = c("|| All cc new ||",
                                        "|| Lim -7:7 cc new ||",
                                        "|| All old ||",
                                        "|| Lim -7:7 old|| "),
                      covariate.labels = c("Festividad (0 a 3)"),
                      omit.stat = c("f", "ser","adj.rsq"),
                      add.lines = list(c("Efectos fijos estado-mun", "Sí", "Sí","Sí", "Sí"),
                                       c("Efectos fijos semana-año", "Sí", "Sí","Sí", "Sí"),
                                       c("Efectos fijos por casa encuestadora", "No", "No","No", "No"),
                                       c("Nivel medio de polarizacion", mean1, mean2, mean3, mean4, mean5, mean6),
                                       c("Efecto vs. nivel medio", 0.22, 0.25, 0.20, 0.24)),
                      title = "Efectos fijos: Estado, Semana, Encuesta",
                      type = "text")

gc()

twfe_time_to_event <- feols(polarizacion_con_centro ~ i(time_to_event, ref = -1) | 
                      nweek_year + KEY, 
                      cluster = "KEY",
                      data = base_event_study_f)

ip <- iplot(twfe_time_to_event, main = "Time to event: All - new polarization metric")
