Code related to the project

- **00_main.R**: This script runs everything else (by script). Read script and output descriptions for a better understanding

- **01_code_inegi.R**: Basic manipulation/transformation for INEGI catalog. The main output is an ideal catalog for future joins with survey data

- **02_code_calendar.R:** Creation of a daily calendar from 2021-2025 for future joins between surveys and patron saint festivals.

- **03_patron_saints.R**: Reading Montero & Yang data, manual data for new festivals, and calculations between weeks and holidays (Time difference in weeks) 

- **04_code_governmental.R**: Create ideology; this helps for creating an auxiliary table for polarization numbers in the future

- **05_survey_data.R**: Aggregate all survey data. Compute ideology, perspective of the current government, ideology of the current government. (df_encuestas is the final data frame) 
  - *OUTPUT*: 
    - df_encuestas ==> Contains all information related to perspective and ideology from the usable surveys (interviewee level). Also characteristic of the government at that time. (Ready to left join more data about other variables)

- **06_polarization_and_fixdistance.R** *(takes a little more than the others)*: polarization calculation and fixed distance calculation (this last one can be reused for any type of event) 
  - *OUTPUT*: 
    - calculo_polarizacion2: polarization information from the usable survey (Survey level) 
   
- **06v2_new_polarization_and_fixdistance.R** *(takes a little more than the others)*: new polarization metric. The definitions is in the PDF located in: ../documents/new_polarization_metric.pdf (this last one can be reused for any type of event) 
  - *OUTPUT*: 
    - calculo_polarizacion2: polarization information from the usable survey (Survey level) 
    - daily_df_patronal: A daily calendar from 2011 to 2025 with the distance in weeks from each week to the patron saint festival, ready to be joined to other events, not only patron saint festivals.
   
- **07_event_studies_prelim.R** TWFE analysis, with all our data base. (Boxplots, Event studes, and Stargazer tables with TWFE estimators)

- **08_event_studies_compl.R** TWFE analysis, filtering out records of municipalities where there is no at least one person per ideology.
  
- **09_stacked_did_prelim.R** *(takes a little more than the others due to cross joins)* Stacked DID approach.

- **10_event_study_plots.R** If you need event study plots with colors :p

- **11_coefficient_plots.R** Visual comparison between methodologies (Main coefficient) 
 

