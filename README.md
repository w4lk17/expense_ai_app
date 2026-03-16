# Expense AI 💸

Application mobile de gestion de dépenses personnelles intelligente, basée sur une architecture "Offline First" et propulsée par l'IA.

## Table des matières

- [🚀 Fonctionnalités (MVP v0.1.0)](#-fonctionnalités-mvp-v010)
- [🏗️ Architecture & Stack Technique](#️-architecture--stack-technique)
- [🛠️ Installation](#️-installation)
- [📅 Roadmap](#-roadmap)
- [👤 Auteur](#-auteur)

## 🚀 Fonctionnalités (MVP v0.1.0)

- **Gestion des Dépenses** : Création, modification, suppression et liste des dépenses.
- **Catégories** : Organisation par catégories avec icônes et couleurs.
- **Tableau de Bord** : Visualisation des dépenses du mois et répartition par catégorie (Graphique Camembert).
- **Authentification** : Inscription et connexion via Supabase (Email/Password).
- **Mode Offline First** : Fonctionne intégralement sans connexion internet. Les données sont stockées localement sur l'appareil.
- **Synchronisation Cloud** : Synchronisation automatique des données locales vers Supabase dès que la connexion est rétablie.
- **Dépenses Récurrentes** : Gestion des charges fixes (Loyer, Abonnements) avec génération automatique mensuelle.
- **Indicateur de Sync** : Badge visuel indiquant si une dépense est sauvegardée en local ou synchronisée dans le cloud.

## 🏗️ Architecture & Stack Technique

Ce projet suit les principes de la Clean Architecture pour une maintenabilité maximale.

### Stack Technique

| Composant              | Technologie                          |
|------------------------|--------------------------------------|
| Framework              | Flutter (Cross-platform)             |
| Langage                | Dart                                 |
| State Management       | Riverpod 2.0+                        |
| Base de Données Locale | Drift (SQLite) (Offline First)       |
| Backend (BaaS)         | Supabase (Auth, DB Postgres)         |
| Graphiques             | FL Chart                             |

### Structure des dossiers

```Text
lib/
├── core/          # Couche transverse (Themes, Constants, DB connection)
├── features/
│   ├── auth/      # Fonctionnalité Authentification
│   │   ├── data/      # Repositories Impl, Datasources
│   │   ├── domain/    # Entités, Repository Contracts
│   │   └── presentation/  # Providers, Pages, Widgets
│   ├── expense/   # Fonctionnalité Dépenses (CRUD, Dashboard)
│   └── ai_advisor/  # (Phase 3) Fonctionnalité IA
└── main.dart
```

## 🛠️ Installation

1. **Cloner le repo**

   ```bash
   git clone <url-du-repo>
   cd expense_ai_app
   ```

2. **Installer les dépendances**

   ```bash
   flutter pub get
   ```

3. **Générer le code Drift (SQLite)**

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configuration Supabase**
   - Créer un projet sur [Supabase](https://supabase.com/).
   - Exécuter le script SQL fourni dans la documentation pour créer les tables `expenses` et activer RLS.
   - Renseigner vos clés dans `lib/core/constants/supabase_constants.dart`.

5. **Lancer l'application**

   ```bash
   flutter run
   ```

## 📅 Roadmap

- [x] Phase 1 : Architecture & Setup
- [x] Phase 2 : MVP Fonctionnel (CRUD, Dashboard, Auth, Sync, Récurrents)
- [ ] Phase 3 : Intégration IA (Catégorisation automatique, Chatbot Conseiller)
- [ ] Phase 4 : Polish & Release (Dark Mode, Anims, Stores)

## 👤 Auteur

Projet développé en autonomie avec l'assistance d'une IA Chef de Projet.
