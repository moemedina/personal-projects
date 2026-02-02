##### Dependencies #####

## Setup 
wd <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
setwd(wd)
set.seed(156940)
options(scipen=999)

## Downloading / Loading dependencies
list.of.packages <- c("data.table","dplyr","readxl","lubridate","zoo","haven",
                      "stringr")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages) 
lapply(list.of.packages, library, character.only = TRUE) 

### OBTAINING NEW POLARIZATION INDEX
calculo_polarizacion <- 
  df_encuestas %>% 
  dplyr::mutate(.,
                # classify by ideology. 
                izquierda = ifelse(ideologia_persona_centro == "IZQUIERDA",1,0),
                derecha = ifelse(ideologia_persona_centro == "DERECHA",1,0),
                centro = ifelse(ideologia_persona_centro == "CENTRO",1,0),
                izquierda_a = ifelse(ideologia_persona_centro == "IZQUIERDA" & percepcion_final == "APRUEBA",1,0),
                izquierda_d = ifelse(ideologia_persona_centro == "IZQUIERDA" & percepcion_final == "DESAPRUEBA",1,0),
                derecha_a = ifelse(ideologia_persona_centro == "DERECHA" & percepcion_final == "APRUEBA",1,0),
                derecha_d = ifelse(ideologia_persona_centro == "DERECHA" & percepcion_final == "DESAPRUEBA",1,0),
                centro_a = ifelse(ideologia_persona_centro == "CENTRO" & percepcion_final == "APRUEBA",1,0),
                centro_d = ifelse(ideologia_persona_centro == "CENTRO" & percepcion_final == "DESAPRUEBA",1,0)
  ) %>%
  group_by(., KEY, name, year, fecha_wo_year, ideologia_presidente_centro) %>%
  dplyr::summarise(
    # --- Contamos el total de encuestados por grupo ---
    n_L = sum(izquierda),
    n_R = sum(derecha),
    n_C = sum(centro),
    n_total_con_centro = n_L + n_R + n_C,
    n_total_sin_centro = n_L + n_R, 
    
    # --- Contamos aprobación/desaprobación (solo para L y R) ---
    n_L_approve = sum(izquierda_a),
    n_L_disapprove = sum(izquierda_d),
    n_R_approve = sum(derecha_a),
    n_R_disapprove = sum(derecha_d),
    
    # p_L y p_R: Proporción de cada grupo sobre el TOTAL 
    # (Manejamos división entre cero por si una encuesta no tiene encuestados)
    p_L_con_centro = ifelse(n_total_con_centro == 0, 0, n_L / n_total_con_centro),
    p_R_con_centro = ifelse(n_total_con_centro == 0, 0, n_R / n_total_con_centro),
    p_L_sin_centro = ifelse(n_total_sin_centro == 0, 0, n_L / n_total_sin_centro),
    p_R_sin_centro = ifelse(n_total_sin_centro == 0, 0, n_R / n_total_sin_centro),
    
    # A_L y A_R: Media de aprobación DENTRO de cada grupo
    # (Aprobados / (Aprobados + Desaprobados) de ese grupo)
    mean_A_L = n_L_approve / (n_L_approve + n_L_disapprove),
    mean_A_R = n_R_approve / (n_R_approve + n_R_disapprove),
    
    # --- Limpiamos NaN's ---
    # (Si un grupo no tiene opiniones (ej. n_L_approve + n_L_disapprove = 0), 
    # la media será NaN. La convertimos a 0 para el cálculo.)
    mean_A_L = ifelse(is.nan(mean_A_L), 0, mean_A_L),
    mean_A_R = ifelse(is.nan(mean_A_R), 0, mean_A_R),
    
    # --- 4. CÁLCULO FINAL DEL ÍNDICE  ---
    polarizacion_con_centro = 4 * p_L_con_centro * p_R_con_centro * (p_L_con_centro + p_R_con_centro) * (mean_A_L - mean_A_R)^2,
    polarizacion_sin_centro = 4 * p_L_sin_centro * p_R_sin_centro * (p_L_sin_centro + p_R_sin_centro) * (mean_A_L - mean_A_R)^2
    
  ) %>% 
  ungroup() %>%
  dplyr::select(KEY, name, year, fecha_wo_year, ideologia_presidente_centro, 
                polarizacion_con_centro, polarizacion_sin_centro)

##### FIX DISTANCE (can be reused)   #####
# Time is a circle; it can't be measured in just one direction. 
# Therefore, the distance between weeks and the survey must be accurately calculated.
# It is based only on weeks, not surveys, so it can be used to match any other event (e.g., soccer). 
polarizacion_presidente <- df_encuestas %>% group_by(nombre, ideologia_persona_centro, percepcion_final) %>% tally()
write.table(polarizacion_presidente, "clipboard-16342", sep = "\t")
polarizacion_anual <- df_encuestas %>% group_by(year, ideologia_persona_centro, percepcion_final) %>% tally() %>%
  tidyr::pivot_wider(., id_cols = c(year, ideologia_persona_centro), names_from = percepcion_final, values_from = n)
izquierda <- distinct(df_encuestas, year, partido_final_centro, ideologia_persona_centro)
encuestas <- distinct(df_encuestas, name)

daily_df_patronal <- 
  daily_df_patronal %>% 
  dplyr::mutate(semana_evento = case_when(
    time_to_event < 0 ~ n_week - time_to_event, 
    time_to_event >= 0 ~ n_week - time_to_event
  ))

semana_maxima <- 
  dplyr::distinct(daily_df_patronal, year, n_week) %>%
  dplyr::group_by(year) %>%
  dplyr::filter(n_week == max(n_week)) %>%
  dplyr::rename(semana_maxima = n_week)

daily_df_patronal <- 
  left_join(daily_df_patronal, semana_maxima, by = "year")

daily_df_patronal <- 
  daily_df_patronal %>%
  dplyr::mutate(distancia_adelante = case_when(
    n_week <= semana_evento ~ semana_evento-n_week,
    n_week > semana_evento ~ n_week-semana_evento
  ),
  distancia_atras = case_when(
    n_week <= semana_evento ~ semana_maxima-semana_evento+n_week,
    n_week > semana_evento ~ semana_maxima+semana_evento-n_week
  )) %>%
  dplyr::group_by(year, n_week, KEY) %>%
  dplyr::mutate(time_to_event = case_when(
    n_week <= semana_evento ~ -1*min(distancia_adelante, distancia_atras),
    n_week > semana_evento ~ min(distancia_adelante, distancia_atras)
  )) %>% ungroup()

gc()
