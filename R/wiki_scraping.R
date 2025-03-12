# =====================================================================
# Exercice de web scraping - Sondages d'opinion pour les élections fédérales canadiennes
# =====================================================================

# 1 - CHARGEMENT DES BIBLIOTHÈQUES ----

library(tidyverse)  # Ensemble de packages pour la manipulation de données
library(lubridate)  # Package pour la gestion des dates
library(rvest)      # Package pour le scraping web
library(ggplot2)    # Package pour les visualisations
library(robotstxt)  # Package pour vérifier si le scraping est autorisé

# 2 - VÉRIFICATION ÉTHIQUE ----

# Vérification du fichier robots.txt pour s'assurer que le scraping est autorisé
# Cette étape est cruciale pour respecter les règles éthiques du scraping web
paths_allowed("https://en.wikipedia.org/wiki/Opinion_polling_for_the_45th_Canadian_federal_election")

# 3 - ASPIRER (RÉCUPÉRATION DES DONNÉES) ----

# Lecture de la page HTML
# read_html() télécharge la page web et la transforme en objet HTML
Polls_data <- read_html("https://en.wikipedia.org/wiki/Opinion_polling_for_the_45th_Canadian_federal_election")

# 4 - EXTRAIRE (DONNÉES BRUTES) ----

# Extraction des tableaux de la page
# html_elements() permet de cibler des éléments spécifiques de la page
# pluck(2) sélectionne le deuxième tableau (qui contient les sondages)
# html_table() convertit le tableau HTML en dataframe R

Polls_data_1 <- Polls_data |> 
  # Chercher tous les éléments "table" de la page
  html_elements("table") |> 
  # Sélectionner le deuxième tableau de la page (index 2)
  # Note: on utilise pluck() car c'est plus lisible que l'indexation [[2]]
  pluck(2) |>  
  # Conversion en dataframe avec fill=TRUE pour gérer les cellules vides/fusionnées
  html_table(fill = TRUE)

# 5 - NETTOYER (TRANSFORMATION DES DONNÉES) ----

# Nettoyage et transformation des données
# rename() pour donner des noms plus explicites aux colonnes
# filter() pour éliminer les lignes vides
# slice() pour retirer des lignes spécifiques
# select() pour choisir les colonnes à conserver
# mutate() pour transformer les colonnes

Polls_data_f <- Polls_data_1 |> 
  # Renommer les colonnes pour les rendre plus explicites et cohérentes
  rename(firm           = "Polling firm",           # Institut de sondage
         date           = "Last dateof polling[a]", # Date du sondage
         pred_cpc       = CPC,                      # Parti conservateur
         pred_lpc       = LPC,                      # Parti libéral
         pred_ndp       = NDP,                      # Nouveau parti démocratique
         pred_bq        = BQ,                       # Bloc québécois
         pred_ppc       = PPC,                      # Parti populaire
         pred_gpc       = GPC,                      # Parti vert
         error_margin   = "Marginof error[c]",      # Marge d'erreur
         sample_size    = "Samplesize[d]",          # Taille de l'échantillon
         poll_method    = "Polling method[e]",      # Méthode de sondage
         leading_margin = Lead) |>                  # Écart entre les deux premiers partis
  
  # Filtrer les lignes vides (souvent des séparateurs dans le tableau Wikipedia)
  filter(firm != "") |>   
  
  # Retirer les lignes spécifiques (en-têtes répétés ou notes de bas de page)
  # Les indices 1, 235 et 236 correspondent à des lignes non-pertinentes
  slice(-c(1, 235, 236)) |> 
  
  # Retirer les colonnes non utilisées pour notre analyse
  select(-c(Link, "Others[b]")) |>    
  
  # Transformation et nettoyage des données numériques et temporelles
  mutate(
    # Conversion des colonnes textuelles en numériques
    # str_squish() enlève les espaces supplémentaires
    # str_replace_all() enlève les symboles comme ±, pp, virgules, etc.
    across(c(error_margin, sample_size), 
           ~ as.numeric(str_squish(str_replace_all(.x, c("±" = "",
                                                      " pp" = "",
                                                      "[:punct:]1[:punct:]4[:punct:]" = "",
                                                      ","   = ""))))),
    # Conversion des colonnes de prédictions et écart en numériques
    across(c(pred_cpc:pred_gpc, leading_margin), ~as.numeric(.x)),
    # Conversion de la date en format Date (mdy = month-day-year)
    date = mdy(date))

# Aperçu de la structure des données nettoyées
# glimpse() affiche un résumé compact du dataframe

glimpse(Polls_data_f)

# 6 - PRÉPARER POUR VISUALISATION ----

# Préparation des données pour la visualisation
# pivot_longer() transforme les données du format large au format long
# mutate() pour renommer les partis de manière plus lisible
# fct_relevel() pour définir l'ordre d'affichage des partis

poll_data_g <- Polls_data_f |> 
  # Sélection des colonnes pertinentes pour le graphique (date et prédictions par parti)
  select(date, pred_cpc:pred_bq, pred_gpc) |> 
  
  # Transformation du format large au format long
  # Cela crée deux colonnes: 'party' (nom du parti) et 'prop' (pourcentage)
  pivot_longer(!date, names_to = "party", values_to = "prop") |> 
  
  # Renommage des partis pour plus de lisibilité dans le graphique
  mutate(party = case_when(party == "pred_cpc" ~ "Conservateur",
                           party == "pred_lpc" ~ "Libéral",
                           party == "pred_ndp" ~ "NPD",
                           party == "pred_bq"  ~ "Bloc Québécois",
                           party == "pred_gpc" ~ "Verts"),
         # Définition de l'ordre d'affichage des partis
         party = fct_relevel(party, c("Conservateur",
                                     "Libéral",
                                     "NPD",
                                     "Bloc Québécois",
                                     "Verts")))

# 7 - VISUALISER ----

# Création d'un graphique des tendances des sondages

p <- ggplot(poll_data_g, aes(x = date, y = prop, color = party, group = party)) + 
      # Définition des limites de l'axe Y (0-50%)
      expand_limits(y=0:50) +
      # Lignes de tendance avec une épaisseur de 1.5 
      geom_line(linewidth = 1.5) + 
      # Couleurs personnalisées pour chaque parti politique canadien
      # Ces couleurs sont généralement associées à ces partis
      scale_color_manual("", values = c("Conservateur"   = "#6495ED", # Bleu conservateur
                                        "Libéral"        = "#EA6D6A", # Rouge libéral
                                        "NPD"            = "#F4A460", # Orange NPD
                                        "Bloc Québécois" = "#87CEFA", # Bleu clair BQ
                                        "Verts"          = "#99C955")) + # Vert pour les Verts
      # Titres et étiquettes des axes
      labs(title = "Appui des partis canadiens dans les sondages",
           x     = "\nDate",
           y     = "(%)\n") +
      # Thème de base avec une taille de police de 20
      theme_bw(base_size = 20) +
      # Augmentation de la taille des éléments de légende pour meilleure lisibilité
      theme(legend.key.size = unit(2.5, 'cm'))

# Affichage du graphique
print(p)

# Création du dossier de résultats s'il n'existe pas
if (!dir.exists("results/graphs")) {
  dir.create("results/graphs", recursive = TRUE)
}

# Sauvegarde du graphique en haute résolution
ggsave("results/graphs/tendances_sondages_partis.png", p, width = 12, height = 8, dpi = 300, bg = "white")

# 8 - DISCUSSION ET INTERPRÉTATION ----

# 1. Quelles sont les tendances générales pour chaque parti?
# 2. Y a-t-il des événements particuliers qui semblent avoir influencé les sondages?
# 3. Comment les différentes méthodes de sondage pourraient-elles affecter les résultats?
