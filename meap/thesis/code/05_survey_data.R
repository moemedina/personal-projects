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

##### SURVEYS DATA (ALL PREPROCCES WAS DONE MANUAL, GO TO DOCUMENTS FOR RAW INFORMATION) #####
# The useful surveys are those which data related to ideology (politics) and perspective of the current government
# All the survey data is in the raw file, but in our final database we only kept the data from our interest. 
load(paste0(wd, "/documents/surveys/processed/encuestas_11_12.RData"))
load(paste0(wd, "/documents/surveys/processed/encuestas_14_15.RData"))
load(paste0(wd, "/documents/surveys/processed/encuestas_17_18.RData"))
load(paste0(wd, "/documents/surveys/processed/encuestas_20_21.RData"))
load(paste0(wd, "/documents/surveys/processed/encuestas_23_24.RData"))
load(paste0(wd, "/documents/surveys/processed/encuestas_23_24_round2.RData"))

# JUNTAMOS TODAS LAS ENCUESTAS 
df_encuestas <- rbind(encuestas_11_12, 
                      encuestas_14_15, 
                      encuestas_17_18, 
                      encuestas_20_21,
                      encuestas_23_24,
                      encuestas_23_24_round2)

df_encuestas <- 
  df_encuestas %>% 
  dplyr::mutate(
    percepcion = str_trim(toupper(percepcion)), 
    ideologia = str_trim(toupper(ideologia))
  )

df_encuestas <- df_encuestas[complete.cases(df_encuestas), ] 

# AÑADIMOS PERCEPCION GUBERNAMENTAL
percepcion_razones <- distinct(df_encuestas, percepcion)
write.table(percepcion_razones, "clipboard-16342", sep = "\t")
df_percepcion <- fread(paste0(wd, "/documents/percepcion_final.csv"), encoding = "Latin-1") %>%
  dplyr::mutate(
    percepcion = str_trim(percepcion), 
    percepcion_final = str_trim(percepcion_final)
  ) %>% distinct(percepcion, percepcion_final)
df_percepcion <- df_percepcion[complete.cases(df_percepcion), ]

df_encuestas <- left_join(df_encuestas, df_percepcion, by = "percepcion")

# AÑADIMOS IDEOLOGIA PERSONAL (PUEDE O NO INCLUIR A CENTRO) - 1RO PEGAMOS PARTIDO POLITICO
ideologia_casos <- distinct(df_encuestas, ideologia)
# write.table(ideologia_casos, "clipboard-16342", sep = "\t")
df_partidopol <- fread(paste0(wd, "/documents/partidopolitico_final.csv"), encoding = "Latin-1") %>%
  dplyr::mutate(
    ideologia = str_trim(ideologia), 
    partido_final = str_trim(partido_final),
    partido_final_centro = str_trim(partido_final_centro)
  ) %>% distinct(ideologia, partido_final, partido_final_centro)
df_partidopol <- df_partidopol[complete.cases(df_partidopol), ]
casos_fuera <- data.frame(
  ideologia = c('JAIME RODRÍGUEZ "EL BRONCO", INDEPENDIENTE',
                'PAN "RICARDO ANAYA CORTÉS"',
                'CANDIDATO INDEPENDIENTE "JAIME RODRÍGUEZ CALDERON "EL BRONCO""',
                'PRD "RICARDO ANAYA CORTÉS"',
                'PRI "JOSÉ ANTONIO MEADE KURIBREÑA"',
                'PT "ANDRÉS MANUEL LÓPEZ OBRADOR"',
                'PVEM "JOSÉ ANTONIO MEADE KURIBREÑA"',
                'PANAL "JOSÉ ANTONIO MEADE KURIBREÑA"',
                'MORENA "ANDRÉS MANUEL LÓPEZ OBRADOR"',
                'PES "ANDRÉS MANUEL LÓPEZ OBRADOR"',
                'MC "RICARDO ANAYA CORTÉS"', 
                'CANDIDATA INDEPENDIENTE "MARGARITA ZAVALA GÒMEZ DEL CAMPO"',
                'NUEVA ALIANZA "JOSÉ ANTONIO MEADE KURIBREÑA"',
                'MOVIMIENTO CIUDADANO "RICARDO ANAYA CORTÉS"',
                'PARTIDO ENCUENTRO SOCIAL "ANDRÉS MANUEL LÓPEZ OBRADOR"'
  ),
  partido_final = c('QUITAR',
                    'PAN',
                    'QUITAR',
                    'PRD',
                    'PRI',
                    'PT',
                    'PVEM',
                    'PANAL',
                    'MORENA',
                    'PES',
                    'MC',
                    'PAN','PANAL','MC','PES'),
  partido_final_centro = c('CENTRO',
                           'PAN',
                           'CENTRO',
                           'PRD',
                           'PRI',
                           'PT',
                           'PVEM',
                           'PANAL',
                           'MORENA',
                           'PES',
                           'MC',
                           'PAN','PANAL','MC','PES')
)
df_partidopol <- rbind(df_partidopol, casos_fuera)
df_partidopol <- dplyr::distinct(df_partidopol, ideologia, partido_final, partido_final_centro)

df_encuestas <- left_join(df_encuestas, df_partidopol, by = "ideologia")

# 2DO PASO: PEGAR IDEOLOGIA DE ACUERDO AL PARTIDO POLITICO 
ideologia_df <- dplyr::mutate(ideologia_df, 
                              ideologia_persona = toupper(ideologia_persona),
                              ideologia_persona_centro = toupper(ideologia_persona_centro))

# AÑADIMOS IDEOLOGIA DEL GOBIERNO (PUEDE O NO CONSIDERAR 'CENTRO')
presidente <- dplyr::mutate(presidente, 
                            ideologia_presidente = toupper(ideologia_presidente),
                            ideologia_presidente_centro = toupper(ideologia_presidente_centro)) 

df_encuestas <- 
  left_join(df_encuestas, select(ideologia_df, partido, ideologia_persona, year),
            by = c("partido_final"="partido", "year"="year")) %>%
  left_join(., select(ideologia_df, partido, ideologia_persona_centro, year),
            by = c("partido_final_centro"="partido", "year"="year")) %>%
  dplyr::mutate(.,
                ideologia_persona = ifelse(is.na(ideologia_persona) & partido_final == 'PANAL', 'DERECHA',ideologia_persona),
                ideologia_persona_centro = ifelse(is.na(ideologia_persona_centro) & partido_final_centro == 'PANAL', 'DERECHA',ideologia_persona_centro),
                ideologia_persona = ifelse(is.na(ideologia_persona) & partido_final == 'QUITAR', 'QUITAR',ideologia_persona),
                ideologia_persona_centro = ifelse(is.na(ideologia_persona_centro) & partido_final_centro == 'CENTRO', 'CENTRO',ideologia_persona_centro)) %>%
  left_join(., presidente, by = c("year"="year", "month"="month")) %>%
  dplyr::select(-presidente_dates)

df_encuestas <- dplyr::filter(df_encuestas, percepcion_final != "QUITAR")
df_encuestas <- dplyr::filter(df_encuestas, KEY != "NA_NA")
df_corregir <- df_encuestas[!complete.cases(df_encuestas), ]

gc()