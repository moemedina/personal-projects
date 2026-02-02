##### Dependencies #####
gc()
## Setup 
wd <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
setwd(wd)
set.seed(156940)
options(scipen=999)

## Downloading / Loading dependencies
list.of.packages <- c("data.table","dplyr","readxl","lubridate","zoo","haven",
                      "stringr", "dplyr", "tidyr", "ggplot2", "ggpubr", "gdata", "patchwork",
                      "fixest", "lfe", "stargazer")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages) 
lapply(list.of.packages, library, character.only = TRUE) 

rm(daily_a_weekly, daily_df, daily_df_patronal)

##### STACKED DiD #####

# Extract the exact day of the event. 
calendario_events <- calendario %>%
  # Filter to the exact day of the celebration
  dplyr::filter(festividad_patronal == 1) %>%
  
  # Create a full date column for the event, which is essential for Step 2
  dplyr::mutate(
    # Combine the year and the month-day string to create a full date object
    event_date = as.Date(paste(year, day_wo_year, sep = "-"), format = "%Y-%d-%m"),
    
    # Create the unique event identifier (critical for Stacked DiD)
    event_id = paste0(KEY, "_", year),
    
    # Keep the week number as well, as it might be useful for time fixed effects
    event_week = n_week
  ) %>%
  
  # Select only the essential columns needed for the cross-join in Step 2
  dplyr::select(event_id, KEY, year_event = year, event_date, event_week)

# Align our polarization index. 
# Prepare your survey data
polarizacion_data <- calculo_polarizacion_filtrada %>%
  dplyr::rename(Survey_Year = year, KEY_survey_id = name) %>%
  dplyr::mutate(
    # Convert the survey date (DD-MM format) into a full date object
    survey_date = as.Date(paste(Survey_Year, fecha_wo_year, sep = "-"), format = "%Y-%d-%m")
  ) 

polarizacion_data2 <- calculo_polarizacion_filtrada2 %>%
  dplyr::rename(Survey_Year = year, KEY_survey_id = name) %>%
  dplyr::mutate(
    # Convert the survey date (DD-MM format) into a full date object
    survey_date = as.Date(paste(Survey_Year, fecha_wo_year, sep = "-"), format = "%Y-%d-%m")
  ) %>% dplyr::select(KEY_survey_id, polarizacion1)

polarizacion_data <- left_join(polarizacion_data, polarizacion_data2, by = "KEY_survey_id")

##### CROSS JOIN NEW ##### --------------------------------------------
# Renombra las columnas de KEY para diferenciarlas después del join
polarizacion_data <- polarizacion_data %>%
  dplyr::rename(KEY_survey = KEY)

calendario_events <- calendario_events %>%
  dplyr::rename(KEY_event = KEY)

# 1. CROSS JOIN (Combinar cada survey con cada event)
# Utilizamos tidyr::crossing() para crear el producto cartesiano
stacked_data <- tidyr::crossing(polarizacion_data, calendario_events)

# 2. CALCULAR TIEMPO RELATIVO (Ahora tenemos todas las combinaciones)
stacked_data <- stacked_data %>%
  dplyr::mutate(
    # Diferencia de tiempo en días
    relative_time_days = as.numeric(survey_date - event_date),
    
    # NUEVO: Indicador de si el evento y la encuesta coinciden en ubicación
    is_treated_municipality = ifelse(KEY_survey == KEY_event, 1, 0),
    
    # 3. Filtrar la ventana de interés (Ej: -60 a +30 días)
    # Importante: Este filtro solo debe aplicarse a las observaciones
    # donde KEY_survey == KEY_event, o se aplica a todas para reducir el tamaño
    # En el Stacked DiD, tradicionalmente filtras el tiempo relativo solo para las 
    # unidades tratadas (KEY_survey == KEY_event), pero para simplificar, 
    # mantendremos el filtro de -60 a +30 en todas las observaciones si el tiempo
    # relativo está cerca de CERO.
    
    # Para ser estrictos y evitar que el dataset se dispare en tamaño:
    # 4. Asignamos la variable KEY final para el clustering
    KEY = KEY_survey
  ) %>%
  
  # 5. Creamos la variable de tratamiento final (Treated * Post)
  dplyr::mutate(
    treated_final = ifelse(is_treated_municipality == 1 & relative_time_days >= 0 & relative_time_days <= 21, 1, 0)
  )

##### MINIMUM DISTANCE ##### --------------------------------------------

# 1. Filtramos solo donde el evento y la encuesta coinciden (Choque temporal)
min_distance_df <- stacked_data %>%
  dplyr::filter(KEY_survey == KEY_event) %>%
  
  # 2. Agrupamos por evento único
  dplyr::group_by(event_id) %>%
  
  # 3. Calculamos la mínima distancia ABSOLUTA de la encuesta al evento.
  # Usamos abs(relative_time_days) para ver qué tan cerca estuvo la encuesta más cercana.
  dplyr::summarise(
    min_abs_distance_days = min(abs(relative_time_days), na.rm = F),
    .groups = 'drop' # Quitar la agrupación después de resumir
  )

##### WHAT EVENTS TO MAINTAIN ##### --------------------------------------------

# Definimos el umbral (Threshold)
THRESHOLD_DAYS <- 28

# 1. Creamos una lista de los event_id que son válidos
valid_event_ids <- min_distance_df %>%
  dplyr::filter(min_abs_distance_days <= THRESHOLD_DAYS) %>%
  dplyr::pull(event_id)

# 2. Resumen de cuántos eventos se eliminan
total_events <- length(unique(stacked_data$event_id))
events_to_keep <- length(valid_event_ids)
events_to_remove <- total_events - events_to_keep

cat(paste0("Total de eventos (event_id) en el dataset inicial: ", total_events, "\n"))
cat(paste0("Eventos Válidos (Choque Temporal <= ", THRESHOLD_DAYS, " días): ", events_to_keep, " - ", round((events_to_keep/total_events)*100,2),"%","\n"))
cat(paste0("Eventos Eliminados por falta de encuestas cercanas: ", events_to_remove, "\n"))

##### CLEAN DATA SET ##### --------------------------------------------

# 1. Unimos la distancia mínima de vuelta al dataset original
stacked_data_reg <- stacked_data %>%
  dplyr::filter(event_id %in% valid_event_ids) %>%
  dplyr::filter(relative_time_days >= -THRESHOLD_DAYS & relative_time_days <= THRESHOLD_DAYS) %>%
  dplyr::mutate(
    treated_final = ifelse(KEY_survey == KEY_event & relative_time_days >= 0 & relative_time_days <= 21, 1, 0)
  )

# Estimation
# Convert event_id to factor for fixed effects
stacked_data_reg$event_id_f <- as.factor(stacked_data_reg$event_id)

total_treated <- sum(stacked_data_reg$treated_final)
cat(paste0("Total de treated records (EDO-MUN Survey = EDO-MUN Festivity) & time_days <= ", THRESHOLD_DAYS,": ", total_treated, "\n"))

wo_treated <- as.vector(t((stacked_data_reg %>% 
  group_by(event_id_f) %>% 
  summarise(suma = sum(treated_final)) %>% 
  filter(suma == 0) %>% 
  select(event_id_f))))

stacked_data_reg <- stacked_data_reg %>% filter(!(event_id_f %in% wo_treated))

stacked_data_reg <- stacked_data_reg %>%
  dplyr::mutate(fix_effect_mun = paste0(event_id_f, "_", KEY),
                fix_effect_time = paste0(event_id_f, "_", survey_date))

### NEW VARIABLES
stacked_data_reg <- 
  stacked_data_reg  %>%
  separate(., KEY_survey_id, into = c("encuesta","fecha","edo","mun"), sep = "_") %>%
  # CASA ENCUESTADORA
  dplyr::mutate(encuesta = toupper(encuesta),
                encuesta = ifelse(encuesta == "MERCAI","MERCAEI",encuesta),
                encuesta = ifelse(encuesta == "VALERA","VARELA",encuesta),
                encuesta = ifelse(encuesta == "ZACATECASIMAGEN",
                                            "ZACATECAS",encuesta))
stacked_data_reg <- 
  stacked_data_reg  %>%
  dplyr::mutate(fix_effect_encuesta = paste0(event_id_f, "_", encuesta))

### ====== Weekly data
stacked_data_reg <- 
  stacked_data_reg %>%
  dplyr::mutate(
    relative_time_weeks = floor(relative_time_days / 7),
    survey_week_num = isoweek(survey_date),
    survey_year = isoyear(survey_date),
    survey_week_id = paste0(survey_year, "-", survey_week_num),
    fix_effect_week = paste0(event_id_f, "_", survey_week_id),
    fix_effect_week_edo = paste0(event_id_f, "_", survey_week_id, "_", edo),
    fix_effect_week_edo_mun = paste0(event_id_f, "_", survey_week_id, "_", edo, "_", mun),
    treated_from_0_final = ifelse(KEY_survey == KEY_event & relative_time_weeks >= 0 & relative_time_weeks <= 3, 1, 0),
    treated_from_minus1_final = ifelse(KEY_survey == KEY_event & relative_time_weeks >= -1 & relative_time_weeks <= 3, 1, 0)
  ) #%>%
  #dplyr::filter(relative_time_weeks >= -4 & relative_time_weeks <= 4)

stacked_data_reg_post <- 
  stacked_data_reg %>%
  dplyr::filter(relative_time_days >= 0 & relative_time_days <= THRESHOLD_DAYS)

# The regression
# Outcome: Polarization (y)
# Treatment: treated_final
# Fixed Effects: event_id_f (Event FE), survey_date (Time FE)
# Cluster: KEY (Municipality/Treatment Group)

st0 <- felm(polarizacion_con_centro ~ treated_from_0_final | 
                  as.factor(fix_effect_mun) + as.factor(fix_effect_week) | # as.factor(fix_effect_time) | # EVENT ID + EVENT ID*DATE + EVENT*KEY
                  0 | # IV
                  KEY, # CLUSTER 
                  data = stacked_data_reg)

mean7 <- round(mean(stacked_data_reg$polarizacion_con_centro, na.rm = T),2)

st0_edo <- felm(polarizacion_con_centro ~ treated_from_0_final | 
               as.factor(fix_effect_mun) + as.factor(fix_effect_week_edo) | #
               0 | 
               KEY, 
               data = stacked_data_reg)

mean8 <- round(mean(stacked_data_reg$polarizacion_con_centro, na.rm = T),2)

st0_edomun <- felm(polarizacion_con_centro ~ treated_from_0_final | 
                   as.factor(fix_effect_mun) + as.factor(fix_effect_week_edo_mun) | #
                   0 | 
                   KEY, 
                   data = stacked_data_reg)

mean9 <- round(mean(stacked_data_reg$polarizacion_con_centro, na.rm = T),2)

st1 <- felm(polarizacion_con_centro ~ treated_from_minus1_final | 
              as.factor(fix_effect_mun) + as.factor(fix_effect_week) | # as.factor(fix_effect_time) | # EVENT ID + EVENT ID*DATE + EVENT*KEY
              0 | # IV
              KEY, # CLUSTER 
            data = stacked_data_reg)

mean10 <- round(mean(stacked_data_reg$polarizacion_con_centro, na.rm = T),2)

tabldedd <- stargazer(st0, st1,
                      header = FALSE,
                      font.size = "scriptsize",
                      dep.var.labels.include = FALSE,
                      table.placement = "H",
                      column.labels = c("||Stacked from 0||",
                                        "||Stacked from -1||"),
                      covariate.labels = c("Festividad (0 to 3 weeks)","Festividad (-1 to 3 weeks)"),
                      omit.stat = c("f", "ser","adj.rsq"),
                      add.lines = list(c("Efectos fijos evento-mun", "Sí", "Sí"),
                                       c("Efectos fijos evento-tiempo", "Si", "Sí"),
                                       c("Limitado a +/- 4 semanas", "Si", "Sí"),
                                       c("Nivel medio de polarizacion", mean7, mean8, mean9, mean10),
                                       c("Efecto vs. nivel medio")),
                      title = "Stacked approach",
                      type = "text")

# Event study 
stacked_time_to_event <- feols(polarizacion1 ~ i(relative_time_weeks, ref = -2) | 
                                 as.factor(fix_effect_mun) + as.factor(fix_effect_week), 
                               cluster = "KEY",
                               data = stacked_data_reg)

ip <- iplot(stacked_time_to_event)

# Event study 
stacked_time_to_event <- feols(polarizacion1 ~ i(relative_time_weeks, ref = -1) | 
                                 as.factor(fix_effect_mun) + as.factor(fix_effect_week), 
                               cluster = "KEY",
                               data = stacked_data_reg)

ip <- iplot(stacked_time_to_event)
