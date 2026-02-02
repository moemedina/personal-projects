#Running scripts
my_path <- "C:/Users/mario/OneDrive/GitHub/personal-projects/meap/thesis"
gc()


# 1. INEGI Catalog
source(paste0(my_path, "/code/01_code_inegi.R"))

# 2. Calendar by municipality
source(paste0(my_path, "/code/02_code_calendar.R"))

# 3. Patron saints data
source(paste0(my_path, "/code/03_patron_saints.R"))

# 4. Ideology
source(paste0(my_path, "/code/04_code_governmental.R"))

# 5. Survey Data
source(paste0(my_path, "/code/05_survey_data.R"))

# 6. Survey Data
source(paste0(my_path, "/code/06_polarization_and_fixdistance.R")) # OLD METRIC
source(paste0(my_path, "/code/06v2_new_polarization_fixdistance.R")) # NEW METRIC - PDF 

# 7. Preliminary results (TWFE)
source(paste0(my_path, "/code/07_event_studies_prelim.R"))

# 8. Results (TWFE) considering if there is variance within the surveys. 
source(paste0(my_path, "/code/08_event_studies_compl.R"))

# 9. Preliminary (Stacked)  
source(paste0(my_path, "/code/09_stacked_did_prelim.R"))
gc()
