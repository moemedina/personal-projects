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

##### POLARIZATION INDEX (Srry for the code XD) #####
calculo_polarizacion2 <- 
  df_encuestas %>% 
  dplyr::mutate(.,
                izquierda = ifelse(ideologia_persona_centro == "IZQUIERDA",1,0),
                derecha = ifelse(ideologia_persona_centro == "DERECHA",1,0),
                centro = ifelse(ideologia_persona_centro == "CENTRO",1,0),
                izquierda_a = ifelse(ideologia_persona_centro == "IZQUIERDA" & percepcion_final == "APRUEBA",1,0),
                izquierda_d = ifelse(ideologia_persona_centro == "IZQUIERDA" & percepcion_final == "DESAPRUEBA",1,0),
                derecha_a = ifelse(ideologia_persona_centro == "DERECHA" & percepcion_final == "APRUEBA",1,0),
                derecha_d = ifelse(ideologia_persona_centro == "DERECHA" & percepcion_final == "DESAPRUEBA",1,0),
                centro_a = ifelse(ideologia_persona_centro == "CENTRO" & percepcion_final == "APRUEBA",1,0),
                centro_d = ifelse(ideologia_persona_centro == "CENTRO" & percepcion_final == "DESAPRUEBA",1,0),
                izquierda_sinc = ifelse(ideologia_persona == "IZQUIERDA",1,0),
                derecha_sinc = ifelse(ideologia_persona == "DERECHA",1,0),
                izquierda_a_sinc = ifelse(ideologia_persona == "IZQUIERDA" & percepcion_final == "APRUEBA",1,0),
                izquierda_d_sinc = ifelse(ideologia_persona == "IZQUIERDA" & percepcion_final == "DESAPRUEBA",1,0),
                derecha_a_sinc = ifelse(ideologia_persona == "DERECHA" & percepcion_final == "APRUEBA",1,0),
                derecha_d_sinc = ifelse(ideologia_persona == "DERECHA" & percepcion_final == "DESAPRUEBA",1,0)
  ) %>%
  group_by(., KEY, name, year, fecha_wo_year, ideologia_presidente_centro) %>%
  dplyr::summarise(
    prop_centro1 = sum(centro)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_izquierda1 = sum(izquierda)/(sum(derecha)+sum(izquierda)),
    prop_derecha1 = sum(derecha)/(sum(derecha)+sum(izquierda)),
    prop_centro2 = sum(centro)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_izquierda2 = sum(izquierda)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_derecha2 = sum(derecha)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_centro3 = sum(centro)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_izquierda3 = sum(izquierda)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_derecha3 = sum(derecha)/(sum(centro)+sum(derecha)+sum(izquierda)),
    prop_izquierda4 = sum(izquierda_sinc)/(sum(derecha_sinc)+sum(izquierda_sinc)),
    prop_derecha4 = sum(derecha_sinc)/(sum(derecha_sinc)+sum(izquierda_sinc)),
    aprobacion_c = (sum(centro_a)/(sum(centro_a)+sum(centro_d)))-(sum(centro_d)/(sum(centro_a)+sum(centro_d))),
    aprobacion_d = (sum(derecha_a)/(sum(derecha_a)+sum(derecha_d)))-(sum(derecha_d)/(sum(derecha_a)+sum(derecha_d))),
    aprobacion_l = (sum(izquierda_a)/(sum(izquierda_a)+sum(izquierda_d)))-(sum(izquierda_d)/(sum(izquierda_a)+sum(izquierda_d))),
    aprobacion_dsinc = (sum(derecha_a_sinc)/(sum(derecha_a_sinc)+sum(derecha_d_sinc)))-(sum(derecha_d_sinc)/(sum(derecha_a_sinc)+sum(derecha_d_sinc))),
    aprobacion_lsinc = (sum(izquierda_a_sinc)/(sum(izquierda_a_sinc)+sum(izquierda_d_sinc)))-(sum(izquierda_d_sinc)/(sum(izquierda_a_sinc)+sum(izquierda_d_sinc))),
    desaprobacion_dsinc = (sum(derecha_d_sinc)/(sum(derecha_a_sinc)+sum(derecha_d_sinc)))-(sum(derecha_a_sinc)/(sum(derecha_a_sinc)+sum(derecha_d_sinc))),
    desaprobacion_lsinc = (sum(izquierda_d_sinc)/(sum(izquierda_a_sinc)+sum(izquierda_d_sinc)))-(sum(izquierda_a_sinc)/(sum(izquierda_a_sinc)+sum(izquierda_d_sinc))),
    desaprobacion_c = (sum(centro_d)/(sum(centro_a)+sum(centro_d)))-(sum(centro_a)/(sum(centro_a)+sum(centro_d))),
    desaprobacion_d = (sum(derecha_d)/(sum(derecha_a)+sum(derecha_d)))-(sum(derecha_a)/(sum(derecha_a)+sum(derecha_d))),
    desaprobacion_l = (sum(izquierda_d)/(sum(izquierda_a)+sum(izquierda_d)))-(sum(izquierda_a)/(sum(izquierda_a)+sum(izquierda_d)))
  ) %>% ungroup() %>%
  dplyr::mutate(
    aprobacion_c = ifelse(is.nan(aprobacion_c), 0, aprobacion_c),
    aprobacion_d = ifelse(is.nan(aprobacion_d), 0, aprobacion_d),
    aprobacion_l = ifelse(is.nan(aprobacion_l), 0, aprobacion_l),
    aprobacion_dsinc = ifelse(is.nan(aprobacion_dsinc), 0, aprobacion_dsinc),
    aprobacion_lsinc = ifelse(is.nan(aprobacion_lsinc), 0, aprobacion_lsinc),
    desaprobacion_c = ifelse(is.nan(desaprobacion_c), 0, desaprobacion_c),
    desaprobacion_d = ifelse(is.nan(desaprobacion_d), 0, desaprobacion_d),
    desaprobacion_l = ifelse(is.nan(desaprobacion_l), 0, desaprobacion_l),
    desaprobacion_dsinc = ifelse(is.nan(desaprobacion_dsinc), 0, desaprobacion_dsinc),
    desaprobacion_lsinc = ifelse(is.nan(desaprobacion_lsinc), 0, desaprobacion_lsinc),
    # OPCION 1 DE HORACIO 
    polarizacion1 = case_when(
      ideologia_presidente_centro == "CENTRO" ~ prop_centro2*aprobacion_c + prop_derecha2*desaprobacion_d + prop_izquierda2*desaprobacion_l,
      ideologia_presidente_centro == "DERECHA" ~ prop_derecha1*aprobacion_d + prop_izquierda1*desaprobacion_l,
      ideologia_presidente_centro == "IZQUIERDA" ~ prop_izquierda1*aprobacion_l + prop_derecha1*desaprobacion_d
    ),
    # OPCION 2 DE HORACIO
    polarizacion2 = case_when(
      ideologia_presidente_centro == "CENTRO" ~ prop_centro2*aprobacion_c + prop_derecha2*desaprobacion_d + prop_izquierda2*desaprobacion_l,
      ideologia_presidente_centro == "DERECHA" ~ prop_derecha2*aprobacion_d + prop_izquierda2*desaprobacion_l,
      ideologia_presidente_centro == "IZQUIERDA" ~ prop_izquierda2*aprobacion_l + prop_derecha2*desaprobacion_d
    ),
    # CONSIDERO DESACUARDO EN LOS CENTROS (MARIO)
    # polarizacion3 = case_when(
    #   ideologia_presidente_centro == "CENTRO" ~ prop_centro3*aprobacion_c + prop_derecha3*desaprobacion_d + prop_izquierda3*desaprobacion_l,
    #   ideologia_presidente_centro == "DERECHA" ~ prop_derecha3*aprobacion_d + prop_centro3*desaprobacion_c + prop_izquierda3*desaprobacion_l,
    #   ideologia_presidente_centro == "IZQUIERDA" ~ prop_izquierda3*aprobacion_l + prop_centro3*desaprobacion_c + prop_derecha3*desaprobacion_d
    # ),
    # SIN QUE HAYA IDEOLOGIA CENTRO 
    polarizacion3 = case_when(
      ideologia_presidente_centro == "CENTRO" | ideologia_presidente_centro == "DERECHA" ~ prop_derecha4*aprobacion_dsinc + prop_izquierda4*desaprobacion_lsinc,
      ideologia_presidente_centro == "IZQUIERDA" ~ prop_izquierda4*aprobacion_lsinc + prop_derecha4*desaprobacion_dsinc)
  ) %>%
  dplyr::select(KEY, name, year, fecha_wo_year, ideologia_presidente_centro, 
                polarizacion1)

gc()