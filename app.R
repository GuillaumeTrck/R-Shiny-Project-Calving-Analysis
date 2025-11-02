setwd("C:/Users/guill/OneDrive/Documents/1 Master LDT/Programmation R/Projet R")
library(DBI)
library(tidyverse)
library(magrittr)
library(dplyr)
library(shiny)
library(lunar) 
library(ggplot2)

con <- dbConnect(RSQLite::SQLite(), dbname = "db.sqlite")

famille <- dbGetQuery(con,"SELECT nom FROM familles")
date <- dbGetQuery(con,"SELECT date FROM velages")%>%
  mutate(date=as.Date(date,format="%d/%m/%Y"))
# Define UI for application that draws a histogram
ui <- fluidPage(
  titlePanel("Analyse de vêlages"),
  
  tabsetPanel(
    tabPanel("Vêlages par année et famille", 
             sidebarLayout(
               sidebarPanel(
                 dateRangeInput('dateRange',
                                label = 'Sélectionnez la période',
                                start = "1990-10-03",
                                end   = Sys.Date()),
                 selectInput('select_famille', 
                             label = 'Choisissez une famille', 
                             choices = famille)
               ),
               mainPanel(
                 plotOutput("velagesPlot")
               )
             )
    ),
    tabPanel("Vêlages par phase lunaire",
             sidebarLayout(
               sidebarPanel(
                 sliderInput('yearRange',
                             label = 'Sélectionnez la période en année',
                             min = 1990,
                             max = 2020, value=2000)
               ),
               mainPanel(
                 plotOutput("velages_par_phase")
               )
             )
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  output$velagesPlot <- renderPlot({
    dbSendQuery(con, 'SELECT velages.date,familles.nom FROM velages
      JOIN animaux_velages ON (velages.id == animaux_velages.velage_id)
      LEFT JOIN animaux  ON (animaux_velages.animal_id == animaux.id)
      LEFT JOIN familles ON (animaux.famille_id == familles.id) WHERE familles.nom = ?')%>%
      dbBind(c(input$select_famille[1]))%>% 
      dbFetch()%>% 
      mutate(date=as.Date(date,format="%d/%m/%Y"))%>%
      group_by(date) %>%
      #Calcul du nombre de velage pour chaque date
      summarise(velages = n())%>%
      
      #Filter permet de lier entrée utlisateur et les données
      filter(date>=input$dateRange[1] & date<=input$dateRange[2])%>%
      
      #Plot du nombre de velage par année et par famille
      ggplot(aes(x=date, y=velages)) +
      geom_bar(stat="identity", fill="blue") +
      theme_minimal() +
      labs(title="Nombre de velages par année", x="Date", y="Nombre de vêlages")+
      geom_text(aes(label=date), vjust=-0.3, color="black", size=3) +
      scale_x_date(date_labels = "%Y", date_breaks = "1 year")
  })
  
  output$velages_par_phase <- renderPlot({
          dbSendQuery(con, 'SELECT velages.date FROM velages')%>%
      dbFetch()%>% 
          mutate(date=as.Date(date,format="%d/%m/%Y"))%>%
          filter(year(date) == input$yearRange)%>%
          #Lunar.phase permet de calculer la phase de la lune (voir doc fonction)
          mutate(lunar_phase=lunar.phase(date))%>%
          group_by(lunar_phase) %>%
          mutate(nombre_velages=1)%>%
          summarise(nombre_velages = n())%>%
          
          # Pourcentage de velages pour chaque phase lunaire (pas utilisé au final)
          mutate(pourcentage = ((nombre_velages / nrow(.)) * 100))%>%
      
          # Bar chart montrant le pourcentage de velages par phase lunaire
          ggplot(aes(x=lunar_phase, y=nombre_velages, fill=lunar_phase)) +
          geom_bar(stat="identity", alpha=0.7) +
          scale_x_continuous(breaks = c(0, pi/2, pi, 3*pi/2, 2*pi),
                             labels = c("Nouvelle Lune", "Premier Quartier", "Pleine Lune", "Dernier Quartier", "Nouvelle lune")) +
          scale_fill_gradient(low="blue", high="red") +
          labs(title="Nombre de velages par phase lunaire", x="Phase Lunaire", y="Nombre de velages") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1),
                legend.position = "bottom",
                plot.title = element_text(size = 14),
                axis.title = element_text(size = 12),
                axis.text = element_text(size = 10))

      })
}

# Run the application 
shinyApp(ui = ui, server = server)
