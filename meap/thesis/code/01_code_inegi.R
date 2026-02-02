##### Dependencies #####

## Setup 
wd <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
setwd(wd)
set.seed(156940)
options(scipen=999)

## Downloading / Loading dependencies
list.of.packages <- c("data.table","dplyr","readxl")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages) 
lapply(list.of.packages, library, character.only = TRUE) 

##### Modifying INEGI Catalog #####

# Variables of interest
catalogo_inegi <- fread(paste0(wd, "/documents/Catalogo INEGI.csv"), encoding = "Latin-1")
catalogo_inegi <- 
  catalogo_inegi %>% 
  dplyr::select(CVE_ENT, NOM_ENT, 
                CVE_MUN, NOM_MUN) %>%
  dplyr::mutate(KEY = paste0(CVE_ENT,"_",CVE_MUN))

# Adding information related to electoral section. Key variables for joins: EDO-MUN or EDO-SECCION
archivos_secciones <- list.files(path = paste0(wd,"/documents/seccion_electoral"))
df_inegi <- c()
for (archivo in archivos_secciones) {
  aux <- read_excel(paste0(wd,"/documents/seccion_electoral/",archivo))
  df_inegi <- rbind(df_inegi, aux) 
}

df_inegi <- 
  df_inegi %>%
  dplyr::select(entidad, municipio, seccion) %>%
  dplyr::mutate(KEY = paste0(entidad,"_",municipio),
                KEY_seccion = paste0(entidad,"_",seccion)) %>%
  dplyr::arrange(entidad, municipio, seccion)

nombres_ent_mun <- catalogo_inegi %>% dplyr::select(KEY, NOM_ENT, NOM_MUN)

df_inegi <- 
  dplyr::left_join(df_inegi, nombres_ent_mun, by = "KEY") %>%
  dplyr::filter(., !is.na(NOM_ENT))

gc()