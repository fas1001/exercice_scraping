# Exercice de Web Scraping en Sciences Sociales

Ce dépôt contient des exemples pratiques de web scraping pour l'analyse de données en sciences sociales, utilisant le langage R.

## Objectif

L'objectif de ces exercices est de vous familiariser avec les techniques de collecte de données en ligne (web scraping) et leur application dans le contexte des sciences sociales. Vous apprendrez à:

1. Extraire des données à partir de différentes sources web
2. Nettoyer et structurer les données brutes
3. Analyser et visualiser les résultats
4. Pratiquer le web scraping de manière éthique et responsable

## Contenu du dépôt

Le dépôt contient deux exemples d'application:

1. **Analyse des Premiers Ministres du Canada** (`R/pm_scraping.R`)
   - Question de recherche: L'âge d'entrée en fonction influence-t-il la durée du mandat?
   - Source: API du Parlement du Canada
   - Méthodes: Extraction JSON, analyse statistique, visualisation

2. **Analyse des Sondages Électoraux** (`R/wiki_scraping.R`)
   - Objectif: Suivre l'évolution des intentions de vote aux élections fédérales
   - Source: Tables Wikipedia
   - Méthodes: Extraction HTML, nettoyage de données, visualisation temporelle

## Aspects éthiques du web scraping

Ces scripts intègrent des vérifications éthiques importantes:

- Vérification du fichier `robots.txt` pour s'assurer que le scraping est autorisé
- Respect des conditions d'utilisation des sites web
- Documentation des sources de données

## Guide méthodologique du web scraping

Le processus de web scraping suit généralement ces étapes:

### 1. Naviguer
- Identifier et explorer la source de données
- Comprendre la structure de la page/API
- Examiner les conditions d'utilisation

### 2. Aspirer
- Télécharger les données brutes (HTML, JSON, etc.)
- Utiliser des fonctions comme `read_html()` ou `GET()`
- Gérer les erreurs potentielles

### 3. Extraire
- Isoler les éléments pertinents à l'aide de sélecteurs
- Parcourir les structures de données complexes
- Transformer les données brutes en format structuré

### 4. Nettoyer
- Standardiser les formats (dates, nombres, etc.)
- Traiter les valeurs manquantes
- Corriger les erreurs ou incohérences

### 5. Visualiser
- Créer des représentations graphiques pertinentes
- Mettre en évidence les tendances et motifs
- Communiquer efficacement les résultats

### 6. Analyser
- Appliquer des méthodes statistiques appropriées
- Interpréter les résultats dans leur contexte
- Répondre à la question de recherche initiale

## Installation et utilisation

### Prérequis
- R version 4.0.0 ou supérieure
- RStudio (recommandé)

### Bibliothèques nécessaires
```r
# Installation des packages requis
install.packages(c("tidyverse", "rvest", "httr", "jsonlite", "robotstxt", "lubridate"))
```

### Exécution des scripts
1. Clonez ce dépôt sur votre machine locale
2. Ouvrez les scripts dans RStudio
3. Exécutez les scripts section par section pour comprendre chaque étape
4. Modifiez les paramètres ou ajoutez vos propres analyses

## Conseils pour l'apprentissage

- Analysez chaque section des scripts avec les commentaires explicatifs
- Modifiez les visualisations pour explorer différentes représentations
- Essayez d'appliquer ces techniques à d'autres sources de données
- Vérifiez toujours les aspects éthiques avant de scraper un site

## Défis

1. Adaptez le script des premiers ministres pour comparer d'autres variables (éducation, origine géographique, etc.)
2. Modifiez le script des sondages pour inclure d'autres élections ou d'autres pays
3. Créez un nouveau script pour extraire des données d'une autre source pertinente en sciences sociales
4. Améliorez les visualisations existantes ou créez-en de nouvelles

## Structure du projet
```
fas1001_exercice_scraping/
├── R/
│   ├── pm_scraping.R           # Analyse des premiers ministres
│   └── wiki_scraping.R         # Analyse des sondages électoraux
├── results/
│   └── graphs/                 # Dossier contenant les visualisations générées
└── README.md                   # Documentation du projet
```

*Ce matériel est destiné à des fins éducatives dans le cadre du cours sur les mégadonnées en sciences sociales.*
