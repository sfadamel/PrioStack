# ⚡ PrioStack — Call Stack & Workflow Execution Sanctuary

> **Application multi-plateforme de gestion du flux de travail et des interruptions (modèle Call Stack LIFO) conçue pour les Architectes Solution, Tech Leads et Managers.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%20(Neon.tech)-336791?logo=postgresql&logoColor=white)](https://neon.tech)
[![Node.js](https://img.shields.io/badge/Backend-Node.js%20%2F%20Express-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Windows%20%7C%20Mobile-blue)]()
[![License](https://img.shields.io/badge/License-Proprietary%20%2F%20Damel%20IT-green)]()

---

## 🎯 Le Problème : Le Coût Cognitif du Changement de Contexte

En tant qu'**Architecte Solution** ou **Manager technique**, votre journée est un tiraillement permanent entre :
* **La réflexion profonde (Deep Work)** : Spécifications, ADR, modélisation de données, revues d'architecture de sécurité.
* **Les interruptions imprévues** : Pannes de production, questions bloquantes des développeurs, réunions d'urgence.

Le problème n'est pas l'interruption en soi, mais le **temps de recouvrement mental (Context Switching)** : après 20 minutes passées à résoudre une urgence, il faut souvent 15 à 20 minutes supplémentaires pour retrouver où l'on en était dans sa tâche de fond.

---

## 💡 La Solution PrioStack : La Pile d'Exécution Mentale (Call Stack LIFO)

PrioStack applique le concept informatique d'une **Pile d'Exécution (Call Stack — Last-In, First-Out)** au flux de travail humain :

```text
 ┌────────────────────────────────────────────────────────┐
 │ 🚨 INTERRUPTION AU SOMMET (Active Top)                │  <- En cours de traitement immédiat
 ├────────────────────────────────────────────────────────┤
 │ ⏸️ TÂCHE DE FOND EN PAUSE (Pushed Pause)               │
 │    🏷️ Note de reprise mentale obligatoire attachée     │  <- Contexte mental sauvegardé
 ├────────────────────────────────────────────────────────┤
 │ 🏗️ BASE DE LA PILE : TÂCHE DE FOND (WIP Limit = 1)     │  <- Sanctuaire de focus du jour
 └────────────────────────────────────────────────────────┘
```

1. **WIP Limit = 1** : Une seule tâche de fond active à la fois.
2. **`🚨 PUSH` (Empilement d'interruption)** : Met immédiatement en pause le chronomètre Focus et exige la saisie d'une **Note de reprise mentale en une phrase** (*« Où en étais-je exactement ? »*). L'urgence est empilée au sommet.
3. **`✅ POP` (Dépilement)** : Dès que l'urgence est résolue, un clic sur **Résoudre & POP** la clôture. La tâche de fond revient instantanément au premier plan avec sa note de reprise affichée en grand. Reprise en moins de 5 secondes !
4. **`🛡️ BATCH` (Bouclier Assistance)** : Les sollicitations des développeurs sont capturées dans une file dédiée pour un traitement groupé par lots sans interruption du flux de fond.

---

## ✨ Fonctionnalités Clés

### 1. Sanctuaire de Focus & Chronomètre Continu
* Chronomètre de concentration fluide sans saccade ni blocage, incrémenté en continu.
* Découpage en **Micro-jalons personnalisables** (15 min, 30 min, 45 min, 1h, etc.) avec jauge de progression proportionnelle.
* Sauvegarde automatique périodique toutes les 10 secondes et sur mise en pause.

### 2. Calendrier & Agenda Intelligent
* Double vue : **Vue Agenda du Jour** détaillée et **Vue Mensuelle** interactive.
* Interaction directe : bouton **« Rejoindre (PUSH dans la Pile) »** qui capture le contexte mental et empile la réunion au sommet de la pile d'exécution.
* Association directe des réunions au module de prise de notes.

### 3. Module de Prise de Notes de Réunions
* Éditeur de notes Markdown complet avec titre, ordre du jour, participants et plan d'action.
* **Sauvegarde automatique en continu** dans le Cloud (Neon PostgreSQL) et secours local (localStorage / SQLite) pour prévenir toute perte de données en cas de rechargement.
* Accès instantané depuis le calendrier ou depuis l'onglet Notes du Cockpit.

### 4. Bouclier de Triage (3 files protégées)
* **🔥 Urgences** : Traitement immédiat via PUSH dans la pile.
* **🧑‍💻 Assistance Développeurs** : Questions techniques pour traitement groupé (*Batching*).
* **📤 Délégué / Suivi** : Tâches confiées à des collaborateurs avec statut de suivi.

### 5. Morning Check-list (Routine d'Initialisation)
* Liste des vérifications quotidiennes matinales (monitoring, pipeline CI/CD, sauvegardes, alertes sécurité).
* Catégorisation par domaine (*Infra & Ops*, *Code & Qualité*, *Organisation*).
* Réinitialisation quotidienne en un clic ou automatique.

### 6. Synchronisation Temps Réel Multi-Écrans
* **Cross-tab instantané (< 10 ms)** via l'API Web `BroadcastChannel`.
* **Polling intelligent d'arrière-plan (3,5 s)** vers Neon Cloud avec fusion des requêtes (*in-flight coalescing*) pour synchroniser automatiquement PC, mobile et collègues connectés sur le même compte.

### 7. Interface Responsive Adaptative (Desktop, Tablette, Mobile)
* **Desktop (>= 960px)** : Cockpit complet à 3 colonnes, barre de capture éclair Raycast/Linear, barre de statut analytique.
* **Mobile (< 960px)** : Navigation tactile épurée en 5 onglets (`Morning`, `Pile`, `Triage`, `Agenda`, `Notes`), barre de saisie sur 2 rangées, bannière de notification responsive.

### 8. Sécurité & Contrôle d'Accès
* Authentification JWT avec hachage sécurisé des mots de passe via `bcryptjs`.
* **Workflow d'approbation administrateur** : Toute nouvelle inscription doit être validée par un administrateur avant de pouvoir accéder à l'application.

---

## 🏗️ Architecture Technique

```text
┌────────────────────────────────────────────────────────┐
│                   PrioStack Clients                    │
│   Flutter Web SPA   │   Windows Portable   │  Mobile   │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST API + JWT
                            ▼
┌────────────────────────────────────────────────────────┐
│               Backend Node.js / Express                │
│             Hébergé sur Render.com 24/7                │
│         https://priostack-api.onrender.com             │
└───────────────────────────┬────────────────────────────┘
                            │ SSL / Connection Pool
                            ▼
┌────────────────────────────────────────────────────────┐
│             PostgreSQL Cloud Serverless                │
│                   sur Neon.tech                        │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Démarrage & Installation

### 1. Prérequis
* [Flutter SDK](https://flutter.dev) (version 3.24+ / 3.41+)
* [Node.js](https://nodejs.org) (v18+)

### 2. Lancement en Local (Web)
```powershell
# Cloner le dépôt
git clone https://github.com/sfadamel/PrioStack.git
cd PrioStack

# Installer les dépendances Flutter
flutter pub get

# Lancer le serveur web local sur le port 8090
powershell -ExecutionPolicy Bypass -File .\run_priostack.ps1
```
L'application s'ouvre à l'adresse : `http://localhost:8090`.

### 3. Lancement du Backend Local
```powershell
cd backend
npm install
$env:PORT="4000"
node server.js
```

---

## 📦 Packaging & Déploiement

### Déploiement Web sur Hébergement Apache / Plesk (`damel-it.com`)
Pour générer le package de production configuré pour `https://www.damel-it.com/priostack/` :
```powershell
powershell -ExecutionPolicy Bypass -File .\package_damel_it.ps1
```
Ce script :
1. Compile Flutter Web en mode release avec `--base-href "/priostack/"`.
2. Génère le fichier `.htaccess` pour le routage SPA sur Apache/Plesk.
3. Produit l'archive ZIP prête à l'emploi : `dist/damel-it/priostack_damel_it.zip`.
4. Uploadez et extrayez cette archive dans le répertoire `/priostack/` de votre serveur.

---

## 📄 Licence & Crédits
Développé avec passion pour l'excellence opérationnelle par **Damel IT**.  
Tous droits réservés © 2026 Damel IT.
