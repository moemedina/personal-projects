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

##### Weekly STACKED DiD #####

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

# Renombra las columnas de KEY para diferenciarlas después del join
polarizacion_data <- polarizacion_data %>%
  dplyr::rename(KEY_survey = KEY)

calendario_events <- calendario_events %>%
  dplyr::rename(KEY_event = KEY)

library(purrr) # Para map_dfr, que es muy útil aquí

library(dplyr)

# Definimos el umbral de tiempo para filtrar (ej. +/- 60 días)
WINDOW_MAX_DAYS <- 60

# Función que busca encuestas para UN evento específico
procesar_evento <- function(id_evento, fecha_evento, key_evento) {
  
  # 1. Definimos las fechas límite para este evento
  fecha_inicio <- fecha_evento - WINDOW_MAX_DAYS
  fecha_fin    <- fecha_evento + WINDOW_MAX_DAYS
  
  # 2. Filtramos la base GRANDE de polarización
  # Buscamos encuestas que estén en la ventana de tiempo
  # IMPORTANTE: Aquí NO filtramos por KEY todavía (Cross Join completo dentro de la ventana)
  encuestas_cercanas <- polarizacion_data %>%
    dplyr::filter(survey_date >= fecha_inicio & survey_date <= fecha_fin)
  
  # 3. Si encontramos encuestas, les pegamos la info del evento
  if(nrow(encuestas_cercanas) > 0) {
    resultado <- encuestas_cercanas %>% 
      dplyr::mutate(
        event_id = id_evento,
        event_date = fecha_evento,
        KEY_event = key_evento, # Guardamos la KEY del evento para comparar luego
        relative_time_days = as.numeric(survey_date - fecha_evento)
      )
    return(resultado)
  } else {
    return(NULL)
  }
}

# Inicializamos una lista vacía para guardar los resultados
lista_resultados <- list()

# Obtenemos el número total de eventos
n_eventos <- nrow(calendario_events)

# Iniciamos el ciclo
for(i in 1:n_eventos) {
  
  # A. Extraemos los datos de la fila 'i' explícitamente
  # (Asegúrate que 'calendario_events' tenga estas columnas. 
  # Si tu columna de municipio se llama 'KEY', cambia 'KEY_event' por 'KEY' abajo)
  
  fila_actual <- calendario_events[i, ]
  
  mi_id    <- fila_actual$event_id
  mi_fecha <- fila_actual$event_date
  mi_key   <- fila_actual$KEY  # <--- OJO AQUÍ: Usa el nombre real de tu columna en calendario (KEY o KEY_event)
  
  # B. Llamamos a la función y guardamos el resultado en la lista
  lista_resultados[[i]] <- procesar_evento(mi_id, mi_fecha, mi_key)
  
  # Opcional: Imprimir progreso cada 10 eventos para que veas que avanza
  if(i %% 10 == 0) cat("Procesando evento", i, "de", n_eventos, "\n")
}

# C. Unimos todos los pedacitos en un solo Data Frame
stacked_data_efficient <- dplyr::bind_rows(lista_resultados)

cat("¡Listo! Base creada con", nrow(stacked_data_efficient), "filas.")

# ================== data.table way

# Convertimos a data.table (no te preocupes, es compatible con lo demás)
setDT(polarizacion_data)
setDT(calendario_events)

# Definimos la ventana en el calendario para hacer el match
calendario_events[, `:=`(start_window = event_date - 60, 
                         end_window = event_date + 60)]

# Hacemos el JOIN por rango (esto es magia pura en eficiencia)
# Unimos donde: survey_date >= start_window  Y  survey_date <= end_window
stacked_data_dt <- polarizacion_data[calendario_events, 
                                     on = .(survey_date >= start_window, 
                                            survey_date <= end_window),
                                     nomatch = NULL, # Elimina los que no hacen match
                                     allow.cartesian = TRUE] # Permite matches múltiples si es necesario

# Regresamos a formato tibble/dplyr si lo prefieres
stacked_data <- as_tibble(stacked_data_dt)

# ================ OLD WAY ==================

# 1. CROSS JOIN (Combinar cada survey con cada event)
# Utilizamos tidyr::crossing() para crear el producto cartesiano
# stacked_data <- tidyr::crossing(polarizacion_data, calendario_events)

# ================ OLD WAY ==================

# 2. CALCULAR VARIABLES (Adaptado a Semanal)
stacked_data <- stacked_data_efficient %>%
  dplyr::mutate(
    # A. Distancia en días (Igual que antes)
    relative_time_days = as.numeric(survey_date - event_date),
    
    # B. NUEVO: Convertir a Semanas (El "Binning")
    # floor divide entre 7 y redondea hacia abajo.
    # Ej: 5 días -> 0 semanas.  15 días -> 2 semanas.
    relative_time_weeks = floor(relative_time_days / 7),
    
    # C. Tratamiento (Ubicación)
    is_treated_municipality = ifelse(KEY_survey == KEY_event, 1, 0),
    KEY = KEY_survey,
    
    # D. NUEVO: Identificadores para Efectos Fijos Semanales
    # Extraemos la semana calendario de la encuesta (Ej: Semana 45 del 2023)
    survey_week_num = isoweek(survey_date),
    survey_year = isoyear(survey_date),
    survey_week_id = paste0(survey_year, "-", survey_week_num)
  ) %>%
  
  # 3. Variable de Tratamiento Final (Basada en SEMANAS)
  # Aquí definimos el impacto por semanas completas (Ej: de la semana 0 a la 3)
  dplyr::mutate(
    treated_final = ifelse(is_treated_municipality == 1 & 
                             relative_time_weeks >= 0 & 
                             relative_time_weeks <= 3, 1, 0) # Ventana de 3 semanas
  )


##### MINIMUM DISTANCE ##### --------------------------------------------

# 1. Filtramos solo donde el evento y la encuesta coinciden (Choque temporal)
min_distance_df <- stacked_data %>%
  dplyr::filter(KEY_survey == KEY_event) %>%
  
  # 2. Agrupamos por evento único
  dplyr::group_by(event_id) %>%
  
  # 3. Calculamos la mínima distancia ABSOLUTA de la encuesta al evento.
  # Usamos abs(relative_time_weeks) para ver qué tan cerca estuvo la encuesta más cercana.
  dplyr::summarise(
    min_abs_distance_weeks = min(abs(relative_time_weeks), na.rm = F),
    .groups = 'drop' # Quitar la agrupación después de resumir
  )

##### WHAT EVENTS TO MAINTAIN ##### --------------------------------------------

# Definimos el umbral (Threshold)
THRESHOLD_WEEKS <- 3

# 1. Creamos una lista de los event_id que son válidos
valid_event_ids <- min_distance_df %>%
  dplyr::filter(min_abs_distance_weeks <= THRESHOLD_WEEKS) %>%
  dplyr::pull(event_id)

# 2. Resumen de cuántos eventos se eliminan
total_events <- length(unique(stacked_data$event_id))
events_to_keep <- length(valid_event_ids)
events_to_remove <- total_events - events_to_keep

cat(paste0("Total de eventos (event_id) en el dataset inicial: ", total_events, "\n"))
cat(paste0("Eventos Válidos (Choque Temporal <= ", THRESHOLD_WEEKS, " semanas): ", events_to_keep, " - ", round((events_to_keep/total_events)*100,2),"%","\n"))
cat(paste0("Eventos Eliminados por falta de encuestas cercanas: ", events_to_remove, "\n"))

##### CLEAN DATA SET ##### --------------------------------------------

# 1. Unimos la distancia mínima de vuelta al dataset original
stacked_data_reg <- stacked_data %>%
  dplyr::filter(event_id %in% valid_event_ids) %>%
  dplyr::filter(relative_time_weeks >= -THRESHOLD_WEEKS & relative_time_weeks <= THRESHOLD_WEEKS) %>%
  dplyr::mutate(
    treated_final = ifelse(KEY_survey == KEY_event & relative_time_weeks >= 0 & relative_time_weeks <= 3, 1, 0)
  )

# Estimation
# Convert event_id to factor for fixed effects
stacked_data_reg$event_id_f <- as.factor(stacked_data_reg$event_id)

total_treated <- sum(stacked_data_reg$treated_final)
cat(paste0("Total de treated records (EDO-MUN Survey = EDO-MUN Festivity) & time_weeks <= ", THRESHOLD_WEEKS,": ", total_treated, "\n"))

wo_treated <- as.vector(t((stacked_data_reg %>% 
                             group_by(event_id_f) %>% 
                             summarise(suma = sum(treated_final)) %>% 
                             filter(suma == 0) %>% 
                             select(event_id_f))))

stacked_data_reg <- stacked_data_reg %>% filter(!(event_id_f %in% wo_treated))

stacked_data_reg <- stacked_data_reg %>%
  dplyr::mutate(fix_effect_mun = paste0(event_id_f, "_", KEY),
                fix_effect_time = paste0(event_id_f, "_", survey_week_id))

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

# The regression
# Outcome: Polarization (y)
# Treatment: treated_final
# Fixed Effects: event_id_f (Event FE), survey_date (Time FE)
# Cluster: KEY (Municipality/Treatment Group)

stacked_new_cc <- felm(polarizacion_con_centro ~ treated_final | 
                         as.factor(fix_effect_mun) + as.factor(fix_effect_time) | # EVENT ID + EVENT ID*DATE + EVENT*KEY
                         0 | # IV
                         KEY, # CLUSTER 
                       data = stacked_data_reg)

mean7 <- round(mean(stacked_data_reg$polarizacion_con_centro, na.rm = T),2)

stacked_old <- felm(polarizacion1 ~ treated_final | 
                      as.factor(fix_effect_mun) + as.factor(fix_effect_time) | 
                      0 | 
                      KEY, 
                    data = stacked_data_reg)

mean8 <- round(mean(stacked_data_reg$polarizacion1, na.rm = T),2)

tabldedd <- stargazer(stacked_new_cc, stacked_old,
                      header = FALSE,
                      font.size = "scriptsize",
                      dep.var.labels.include = FALSE,
                      table.placement = "H",
                      column.labels = c("||Stacked new pol w c||",
                                        "||Stacked old pol||"),
                      covariate.labels = c("Festividad (0 a 21 days)"),
                      omit.stat = c("f", "ser","adj.rsq"),
                      add.lines = list(c("Efectos fijos evento-mun", "Sí", "Sí"),
                                       c("Efectos fijos evento-tiempo", "Si", "Si"),
                                       c("Limitado a 'x' dias", "Si", "Si"),
                                       c("Nivel medio de polarizacion", mean7, mean8),
                                       c("Efecto vs. nivel medio", 0.05, 0.04)),
                      title = "Efectos fijos: Evento y tiempo",
                      type = "text")

stacked_time_to_event <- feols(polarizacion_con_centro ~ i(relative_time_days, ref = -1) | 
                                 as.factor(fix_effect_mun) + as.factor(fix_effect_time), 
                               cluster = "KEY",
                               data = stacked_data_reg)

ip <- iplot(stacked_time_to_event)
