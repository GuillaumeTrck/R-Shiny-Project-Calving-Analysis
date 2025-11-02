setwd("C:/Users/guill/OneDrive/Documents/1 Master LDT/Programmation R/Projet R")

# Load the DBI package
library(DBI)
library(tidyverse)
library(magrittr)
library(dplyr)
# Function to extract SQL commands from text files
read.sql <- function(file){
  lines <- readLines(file) # Get all lines
  merged_lines <- paste(lines, sep = "", collapse = "") # Merge for simplicity
  sql_lines <- strsplit(merged_lines, ";") # Split according to ";" corresponding to sql line separator
  vec_lines <- unlist(sql_lines) # List -> Vector
  return(vec_lines)
}


# Create a RSQLite file called db.sqlite
con <- dbConnect(RSQLite::SQLite(), dbname = "db.sqlite")

# Read the SQL instructions in table_scheme.sql
# This file *should* be build from the project description
table_queries <- read.sql("table_scheme_exemple.sql")
for(query in table_queries){
  #Creates the tables
  dbExecute(con, query)
}

# List the tables in the database
tables.names <- dbListTables(con)
### Tables are valid

files<-list.files(path="sql-data",full.names = TRUE)
sqlcomand<-lapply(files, FUN = readLines)%>%unlist()
lapply(sqlcomand, \(sql) dbSendQuery(con,sql))



# Store all tables in dataframes
tables <- sapply(tables.names, dbReadTable, conn=con)
tables$velages
View(tables)

# Selectionne les id des parents
velages<-tables$velages
animaux_velages<-tables$animaux_velages
mere_ids<-velages$mere_id
pere_ids<-velages$pere_id
enfant_id<-animaux_velages$animal_id
animaux_types<-tables$animaux_types
animaux<-tables$animaux
#Check le type des parents en fonction de leurs id
mere_correspondance <- animaux_types %>%
  filter(animal_id %in% mere_ids) %>%
  select(animal_id, type_id)

pere_correspondance <- animaux_types %>%
  filter(animal_id %in% pere_ids) %>%
  select(animal_id, type_id)

# Affichage des correspondances
view(mere_correspondance)
view(pere_correspondance)


# Joindre les tables animaux_velages et animaux_types pour obtenir les types de la mère et du père et l'id de l'enfant
merged_data <- velages %>%
  left_join(animaux_types, by = c("mere_id" = "animal_id"), suffix = c("_mere", "_mere")) %>%
  left_join(animaux_types, by = c("pere_id" = "animal_id"), suffix = c("_mere", "_pere")) %>%
  left_join(animaux_velages, by = c("id" = "velage_id"))%>%
  mutate(date = NULL)

# Création de nouvelles colonnes pour les types et les pourcentages de l'enfant

merged_data$type_id_enfant <- paste(merged_data$type_id_mere,merged_data$type_id_pere,sep="_")


merged_data$pourcentage_type1 <- ifelse(merged_data$type_id_mere == merged_data$type_id_pere,
                                           100, 50)

merged_data$pourcentage_type2 <- ifelse(merged_data$type_id_mere == merged_data$type_id_pere,
                                           100, 50)

#Creation de nouvelles liste afin de pouvoir les rbind avec animaux type
sang_pures <- merged_data %>%
  filter(type_id_enfant %in% c("1_1", "2_2", "3_3")) %>%
  select(animal_id,type_id_enfant)%>%
  mutate(type_id_enfant = if_else(type_id_enfant %in% c("1_1", "2_2", "3_3"),
                                substr(type_id_enfant, 1, 1),type_id_enfant))%>%
  mutate(pourcentage = 100)%>%
  rename(type_id = type_id_enfant)



sang_de_bourbe <- merged_data %>%
  filter(!(type_id_enfant %in% c("1_1", "2_2", "3_3"))) %>%
  select(animal_id,type_id_enfant)%>%
  separate_rows(type_id_enfant, sep = "_")%>%
  mutate(pourcentage = 50)%>%
  rename(type_id = type_id_enfant)

#sanity check
view(sang_pures)
view(sang_de_bourbe)
head(sang_de_bourbe)


#rbin animaux_types avec sang_pures et sang_de_bourbe

animaux_types <- rbind(animaux_types,sang_pures)
animaux_types <- rbind(animaux_types,sang_de_bourbe)
view(animaux_types)


#--------------Vieu code pour graphique qui utilisait le dataframe load sur la ram----------------#

# 1. vêlages par jour sur une période
# -------------------------
library(shiny)
library(ggplot2)
velages$date<-as.Date(velages$date,format="%d/%m/%Y") #transforme la date du dataframe dans le bon format pour éviter prob
ui <- fluidPage(
  titlePanel("Nombre de vêlages par jour"),
  sidebarLayout(
    sidebarPanel(
      # Sélecteur de date pour définir la période
      dateRangeInput('dateRange', 
                     label = 'Sélectionnez la période',
                     start = min(velages$date), 
                     end   = max(velages$date)),
      # Sélecteur pour choisir une famille (facultatif)
      selectInput('famille', 
                  label = 'Choisissez une famille (optionnel)', 
                  choices = c("All",velages$mere_id), #Chaque mere_id distinct pour éviter les répétitions 
                  selected = "All")
    ),
    mainPanel(
      plotOutput("velagesPlot")
    )
  )
)

server <- function(input, output) {
  filteredData <- reactive({
    # Filtre les données en fonction de la période sélectionnée
    data <- velages %>% filter(date >= input$dateRange[1] & date <= input$dateRange[2])
    
    # Filtre supplémentaire si une famille est sélectionnée
    if(input$famille != "All") {
      data <- data %>% filter(mere_id == input$famille | pere_id == input$famille)
    }
    data
  })
  
  output$velagesPlot <- renderPlot({
    # Prépare les données pour le graphique
    data_to_plot <- filteredData()%>%
      group_by(date) %>%
      #Calcul du nombre de velage pour chaque date
      summarise(nombre_velages = n())
    
    # Crée le graphique
    ggplot(data_to_plot, aes(x=date, y=nombre_velages)) + 
      geom_bar(stat="identity", fill="blue") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) + # Étiquettes inclinées
      labs(title="Nombre de vêlages par jour", x="Date", y="Nombre de vêlages")+
      scale_x_date(date_breaks = "1 day", date_labels = "%Y-%m-%d") # Ajustement des dates
  })
}

shinyApp(ui, server)







#2. Naissance pleine lune
#------------------


library(lunar) #Ce package va nous permettre de déterminer la phase de la lune en fonction de la date donnée
library(ggplot2)
velages$date<-as.Date(velages$date,format="%d/%m/%Y")
#Permet de savoir la phase de lune dans une nouvelle colonne (Pi correspond a une full moon, on met une marge d'erreur)
velages$lunar_phase <- lunar.phase(velages$date)
full_moon_lower_bound <- pi - 0.1
full_moon_upper_bound <- pi + 0.1
# Ajoute une nouvelle colonne qui indique si c'est la pleine lune.
velages$is_full_moon <- with(velages, lunar_phase >= full_moon_lower_bound & lunar_phase <= full_moon_upper_bound)



# Regroupe les données par phase lunaire et compte le nombre de velages
velages_par_phase <- velages %>%
  group_by(lunar_phase) %>%
  summarise(nombre_velages = n(), .groups = 'drop')

# Pourcentage de velages pour chaque phase lunaire
total_velages <- sum(velages_par_phase$nombre_velages)
velages_par_phase$pourcentage <- (velages_par_phase$nombre_velages / total_velages) * 100

# Bar chart montrant le pourcentage de vêlages par phase lunaire
ggplot(velages_par_phase, aes(x=lunar_phase, y=pourcentage, fill=lunar_phase)) +
  geom_bar(stat="identity") +
  scale_x_continuous(breaks = c(0, pi/2, pi, 3*pi/2, 2*pi), labels = c("Nouvelle Lune", "Premier Quartier", "Pleine Lune"  , "Dernier Quartier","Nouvelle lune")) +
  scale_fill_gradient(low="blue", high="red") +
  labs(title="Pourcentage de vêlages par phase lunaire", x="Phase Lunaire", y="Pourcentage de velages") +
  theme_minimal()


#Code test permettant d'avoir le nb de velage aux différentes phases de la lune

# con <- dbConnect(RSQLite::SQLite(), dbname = "db.sqlite")
# 
# df <- dbSendQuery(con, 'SELECT velages.date FROM velages')%>%
#   dbFetch()%>%
#   mutate(date=as.Date(date,format="%d/%m/%Y"))%>%
#   mutate(lunar_phase = case_when(
#     lunar.phase(date) <= 0.1 ~ 1 ,
#     lunar.phase(date) >= (pi/2 - 0.1) & lunar.phase(date) <= (pi/2 + 0.1) ~ 2,
#     lunar.phase(date) >= (pi - 0.1) & lunar.phase(date) <= (pi + 0.1) ~ 3,
#     lunar.phase(date) >= ((3*pi)/2 - 0.1) & lunar.phase(date) <= ((3*pi)/2 + 0.1) ~ 4,
#     lunar.phase(date) >= ((2*pi) - 0.1) ~ 5,
#     TRUE ~ 6 # Le cas par défaut si aucune des conditions ci-dessus n'est vraie
#   ))%>%
#   
# 
#   
#   mutate(lunar.phase(date))%>%
#   group_by(lunar_phase) %>%
#   mutate(nombre_velages=1)%>%
#   summarise(nombre_velages = n())%>%
#   
#   
#   # Pourcentage de velages pour chaque phase lunaire
#   mutate(pourcentage = ((nombre_velages / nrow(.)) * 100))
  
