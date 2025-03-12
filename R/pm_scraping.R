# =====================================================================
# Exercice de web scraping - Premiers ministres du Canada
# Question de recherche: Est-ce que se faire élire jeune est un avantage 
# pour rester premier ministre longtemps?
# =====================================================================

# Chargement des bibliothèques nécessaires
library(httr)         # Pour les requêtes HTTP
library(jsonlite)     # Pour le traitement des données JSON
library(stringr)      # Pour les manipulations de chaînes de caractères
library(ggplot2)      # Pour les visualisations
library(robotstxt)    # Pour vérifier si le scraping est autorisé

# ------------------------------------------------------------------------
# 0. VÉRIFICATION ÉTHIQUE
# ------------------------------------------------------------------------

# Vérification du fichier robots.txt pour s'assurer que le scraping est autorisé
# Cette étape est cruciale pour respecter les règles éthiques du scraping web
paths_allowed("https://lop.parl.ca/ParlinfoWebAPI/Person/SearchAndRefine?&refiners=5-1,&projectionId=5&callback=jQuery3600941572194102592_1741730322226&_=1741730322227")

# ------------------------------------------------------------------------
# 1. NAVIGUER
# ------------------------------------------------------------------------
# Cette étape est faite dans le navigateur web
# Identification de la source de données: API du Parlement du Canada
# Note: Les APIs sont généralement plus stables et éthiques à utiliser que le scraping HTML direct

# ------------------------------------------------------------------------
# 2. ASPIRER (Récupération des données brutes)
# ------------------------------------------------------------------------

# Définition de l'URL de l'API pour obtenir les données des premiers ministres
# Cette URL a été identifiée en analysant les requêtes réseau dans les outils de développement du navigateur
api_url <- "https://lop.parl.ca/ParlinfoWebAPI/Person/SearchAndRefine?&refiners=5-1,&projectionId=5&callback=jQuery3600941572194102592_1741730322226&_=1741730322227"

# Envoi de la requête HTTP à l'API
# GET est une méthode HTTP pour récupérer des données d'une source
response <- httr::GET(api_url)

# Extraction du contenu textuel de la réponse
# La fonction content() convertit la réponse HTTP en texte
content <- httr::content(response, "text", encoding = "UTF-8")

# ------------------------------------------------------------------------
# 3. EXTRAIRE (Traitement des données brutes en données structurées)
# ------------------------------------------------------------------------

# Nettoyage de la réponse pour extraire uniquement la partie JSON
# (suppression de l'enveloppe jQuery callback)
# L'API renvoie les données dans un format jQuery callback, nous devons extraire seulement le JSON
json_data <- stringr::str_extract(content, "\\[\\{.+\\}\\]")

# Conversion du JSON en objet R
# fromJSON transforme une chaîne JSON en liste/dataframe R
pm_data <- jsonlite::fromJSON(json_data)

# Création d'un dataframe avec les informations principales
# Nous sélectionnons les colonnes qui nous intéressent pour notre analyse
df_pm <- data.frame(
  name = paste(pm_data$UsedFirstName, pm_data$LastName),  # Nom complet du PM
  yob = pm_data$DateOfBirth,                              # Date de naissance
  Party = pm_data$PartyEn,                                # Parti politique
  occupation = pm_data$ProfessionsEn,                     # Profession
  province = pm_data$ProvinceOfBirthEn,                   # Province de naissance
  stringsAsFactors = FALSE                                # Évite la conversion automatique en facteurs
)

# Initialisation des vecteurs pour stocker les dates
start_date <- c()  # Date de début de mandat
end_date <- c()    # Date de fin de mandat

# Parcourir chaque premier ministre
# Cette boucle extrait les dates de début et fin de mandat pour chaque PM
for (i in 1:nrow(pm_data)) {
  # Récupérer tous les rôles politiques de la personne
  # Chaque PM peut avoir plusieurs rôles politiques dans sa carrière
  roles <- pm_data$Roles[[i]]
  
  # Parcourir chaque rôle politique
  for (j in 1:nrow(roles)) {
    # Récupérer les titres (en français) associés au rôle
    # Nous utilisons les titres en français car ils sont plus précis pour identifier le PM
    titles <- roles$NameFr 
    
    # Parcourir chaque titre pour trouver "Premier ministre"
    for (k in 1:length(titles)) {
      if (titles[k] == "Premier ministre") {
        # Si le titre est "Premier ministre", enregistrer les dates de début et fin
        # Nous ne gardons que les dates correspondant au rôle de PM
        start_date[i] <- roles$StartDate[k]
        end_date[i] <- roles$EndDate[k]
      }
    }
  }
}

# ------------------------------------------------------------------------
# 4. NETTOYER (Transformation et préparation des données pour l'analyse)
# ------------------------------------------------------------------------

# Conversion des dates en format Date de R (en extrayant seulement les 10 premiers caractères)
# Le format de date de l'API inclut l'heure, nous n'avons besoin que de la date
df_pm$start_date <- as.Date(substr(start_date, 1, 10))
df_pm$end_date <- as.Date(substr(end_date, 1, 10))
df_pm$yob <- as.Date(substr(df_pm$yob, 1, 10))

# Correction manuelle de certaines dates problématiques
# Parfois, les données de l'API peuvent être incomplètes ou incorrectes
df_pm$start_date[df_pm$name == "A. Kim Campbell"] <- as.Date("1993-06-25")
df_pm$end_date[df_pm$name == "A. Kim Campbell"] <- as.Date("1993-11-03")
df_pm$end_date[df_pm$name == "Justin Trudeau"] <- as.Date("2025-03-10")  # Date hypothétique future

# Calcul de la durée du mandat en années
# difftime calcule la différence entre deux dates, puis nous convertissons en années
df_pm$duration <- as.numeric(difftime(df_pm$end_date, df_pm$start_date, units = "days"))/365.25

# Calcul de l'âge au début du mandat
# C'est notre variable indépendante pour l'analyse
df_pm$age_at_start <- as.numeric(difftime(df_pm$start_date, df_pm$yob, units = "days"))/365.25

# ------------------------------------------------------------------------
# 5. VISUALISER (Représentation graphique des données)
# ------------------------------------------------------------------------

# Création d'un histogramme professionnel et élégant pour visualiser l'âge des premiers ministres
canada_palette <- c("#FF0000", "#9E1B32", "#F0F0F0", "#DC143C", "#B22222")

# Identification du plus jeune et du plus vieux premier ministre
# Ces informations seront mises en évidence dans le graphique
youngest_pm <- df_pm[which.min(df_pm$age_at_start), ]
oldest_pm <- df_pm[which.max(df_pm$age_at_start), ]

# Construction du graphique avec ggplot2
p <- ggplot2::ggplot(df_pm, ggplot2::aes(x = age_at_start)) +
     # Fond subtil avec gradient
     ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf,
                     fill = "#F8F8F8", alpha = 0.5) +
     
     # Histogramme avec couleurs raffinées
     # Binwidth=5 signifie que nous regroupons les âges par tranches de 5 ans
     ggplot2::geom_histogram(binwidth = 5, 
                            ggplot2::aes(fill = ..count..), 
                            color = "#3A3A3A", 
                            alpha = 0.9) + 
     
     # Palette de couleurs canadienne raffinée
     # Dégradé de couleurs rouges, du plus clair au plus foncé
     ggplot2::scale_fill_gradientn(
       colors = c("#F8D3D7", "#E5A3AA", "#D27983", "#B84A55", "#9D2C35", "#8B0000"),
       name = "Fréquence") +
     
     # Échelles et breaks plus propres
     # Définition précise des graduations sur l'axe X
     ggplot2::scale_x_continuous(breaks = seq(35, 75, by = 5),
                               expand = ggplot2::expansion(mult = c(0.02, 0.02))) +
     ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.1))) +
     
     # Libellés améliorés
     ggplot2::labs(
       title = "Âge des premiers ministres canadiens à leur entrée en fonction",
       subtitle = "Distribution par tranches d'âge de 5 ans (1867-2025)",
       x = "Âge au début du mandat (années)",
       y = "Fréquence",
       caption = "Source: API du Parlement du Canada | Analyse: Mars 2025"
     ) +
     
     # Moyenne avec annotation améliorée
     # Ligne verticale indiquant l'âge moyen
     ggplot2::annotate("segment", 
                     x = mean(df_pm$age_at_start, na.rm = TRUE), 
                     xend = mean(df_pm$age_at_start, na.rm = TRUE),
                     y = 0, 
                     yend = 5.5,
                     color = "#3A3A3A", 
                     size = 0.8, 
                     linetype = "dashed") +
     # Étiquette indiquant la valeur moyenne
     ggplot2::annotate("label", 
                     x = mean(df_pm$age_at_start, na.rm = TRUE), 
                     y = 5.8,
                     label = paste("Moyenne:", round(mean(df_pm$age_at_start, na.rm = TRUE), 1), "ans"), 
                     color = "#3A3A3A", 
                     fill = "#FFFFFF",
                     alpha = 0.9,
                     size = 4, 
                     fontface = "bold",
                     label.padding = ggplot2::unit(0.5, "lines")) +
     
     # Annotations pour plus jeune et plus vieux, repositionnées et stylisées
     ggplot2::annotate("label",
                     x = youngest_pm$age_at_start,
                     y = 1.5,
                     label = paste("Plus jeune:\n", youngest_pm$name, "\n", 
                                 round(youngest_pm$age_at_start, 1), "ans"),
                     color = "#FFFFFF",
                     fill = "#CF0E20",
                     alpha = 0.9,
                     size = 3.5,
                     fontface = "bold",
                     label.padding = ggplot2::unit(0.5, "lines")) +
     ggplot2::annotate("segment",
                     x = youngest_pm$age_at_start,
                     xend = youngest_pm$age_at_start,
                     y = 0,
                     yend = 1.1,
                     color = "#CF0E20",
                     size = 1.2,
                     linetype = "dotted") +
     ggplot2::annotate("label",
                     x = oldest_pm$age_at_start,
                     y = 1.5,
                     label = paste("Plus vieux:\n", oldest_pm$name, "\n", 
                                 round(oldest_pm$age_at_start, 1), "ans"),
                     color = "#FFFFFF",
                     fill = "#CF0E20",
                     alpha = 0.9,
                     size = 3.5,
                     fontface = "bold",
                     label.padding = ggplot2::unit(0.5, "lines")) +
     ggplot2::annotate("segment",
                     x = oldest_pm$age_at_start,
                     xend = oldest_pm$age_at_start,
                     y = 0,
                     yend = 1.1,
                     color = "#CF0E20",
                     size = 1.2,
                     linetype = "dotted") +
     
     ggplot2::theme_minimal(base_family = "Palatino") +
     ggplot2::theme(
       text = ggplot2::element_text(family = "Palatino"),
       plot.title = ggplot2::element_text(face = "bold", size = 18, hjust = 0.5, color = "#252525",
                                        margin = ggplot2::margin(b = 15)),
       plot.subtitle = ggplot2::element_text(size = 13, hjust = 0.5, color = "#4F4F4F",
                                        margin = ggplot2::margin(b = 20)),
       plot.caption = ggplot2::element_text(size = 9, color = "#757575", hjust = 1,
                                          margin = ggplot2::margin(t = 15)),
       axis.title.x = ggplot2::element_text(face = "bold", size = 13, color = "#252525",
                                        margin = ggplot2::margin(t = 10)),
       axis.title.y = ggplot2::element_text(face = "bold", size = 13, color = "#252525",
                                        margin = ggplot2::margin(r = 10)),
       axis.text = ggplot2::element_text(size = 11, color = "#4F4F4F"),
       panel.grid.major = ggplot2::element_line(color = "#E0E0E0", size = 0.4),
       panel.grid.minor = ggplot2::element_blank(),
       legend.position = "none",
       plot.background = ggplot2::element_rect(fill = "#FFFFFF", color = NA),
       panel.background = ggplot2::element_rect(fill = "#FFFFFF", color = NA),
       plot.margin = ggplot2::unit(c(1.5, 1.5, 1.5, 1.5), "cm"),
       panel.border = ggplot2::element_rect(color = "#E0E0E0", fill = NA, size = 1)
     )

# Affichage du graphique
print(p)

# Création du dossier de résultats s'il n'existe pas
if (!dir.exists("results/graphs")) {
  dir.create("results/graphs", recursive = TRUE)
}

# Sauvegarde du graphique en haute résolution
ggplot2::ggsave("results/graphs/age_premiers_ministres_ameliore.png", p, width = 10, height = 7, dpi = 300, bg = "white")

# ------------------------------------------------------------------------
# 6. ANALYSER (Analyse statistique des données)
# ------------------------------------------------------------------------

# Régression linéaire pour tester la relation entre l'âge au début du mandat et sa durée
# Nous cherchons à répondre à notre question de recherche:
# "Est-ce que se faire élire jeune est un avantage pour rester premier ministre longtemps?"
m <- lm(duration ~ age_at_start, data = df_pm)

# Affichage des résultats de la régression
# Le coefficient de age_at_start nous indiquera si l'âge a un impact sur la durée du mandat
# Un coefficient négatif significatif indiquerait qu'un jeune âge est associé à des mandats plus longs
summary(m)

# Interprétation des résultats (à faire par les étudiants)
# Questions à considérer:
# 1. Le coefficient de age_at_start est-il statistiquement significatif?
# 2. Quel est le signe du coefficient (positif ou négatif)?
# 3. Quelle est la taille de l'effet (pour chaque année supplémentaire, quelle est la différence de durée du mandat)?
