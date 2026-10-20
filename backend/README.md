# 📡 PrioStack Backend API & Synchronisation Cloud Neon.tech

Ce backend Node.js / Express fait la passerelle sécurisée entre l'application PrioStack (Web SPA, Windows Portable, Mobile) et la base de données PostgreSQL serverless hébergée sur **Neon.tech**.

---

## 🚀 Démarrage Rapide

### 1. Prérequis
* Node.js v18+ installé

### 2. Installation des dépendances
```bash
cd backend
npm install
```

### 3. Initialiser / Réinitialiser la base de données Neon
Pour créer les tables (`users`, `tasks`, `micro_milestones`, `morning_checks`, `calendar_events`, `meeting_notes`) et insérer le compte administrateur initial :
```bash
node init-db.js
```

### 4. Démarrer le serveur API en local
```bash
$env:PORT="4000"
node server.js
```
Le serveur s'exécute sur `http://localhost:4000`.

---

## 🔐 Compte Administrateur par défaut
* **Email** : `admin@priostack.local`
* **Mot de passe** : `AdminPrio2026!`
* **Rôle** : `admin` (approuvé par défaut)

> **Important** : Pour toute nouvelle inscription via le formulaire public, le compte est créé avec `is_approved = false`. L'utilisateur ne peut pas se connecter tant que l'administrateur n'a pas validé son compte depuis l'interface d'administration.

---

## 🌐 Serveur Cloud de Production
L'API officielle en production est déployée et active 24/7 sur Render :
👉 **`https://priostack-api.onrender.com`**

---

## 📡 Endpoints de l'API

### 1. Authentification (`/api/auth`)
* `POST /api/auth/register` : Inscription d'un nouvel utilisateur (nom, email, mot de passe). Compte en attente de validation administrateur.
* `POST /api/auth/login` : Connexion (vérifie que le compte est approuvé) et délivre un token JWT valide 30 jours.
* `GET /api/auth/me` : Récupère les données du profil connecté via le Bearer Token.

### 2. Administration & Validation des Comptes (`/api/admin`)
* `GET /api/admin/users` : Liste complète des comptes inscrits (nécessite rôle `admin`).
* `POST /api/admin/users/:id/approve` : Approuve l'accès d'un compte utilisateur.
* `POST /api/admin/users/:id/reject` : Désactive ou supprime l'accès d'un compte.

### 3. Tâches & Sanctuaire de Focus (`/api/tasks`)
* `GET /api/tasks` : Récupère toutes les tâches de l'utilisateur avec leurs micro-jalons.
* `POST /api/tasks` : Création d'une tâche (Fond, Urgence, Assistance, Délégué).
* `PATCH /api/tasks/:id` : Mise à jour partielle (statut, titre, elapsedSeconds, note de reprise).
* `DELETE /api/tasks/:id` : Suppression (soft delete).
* `POST /api/tasks/push-interruption` : Empilement prioritaire au sommet de la pile avec note de reprise mentale obligatoire.
* `POST /api/tasks/:id/pop` : Résolution & dépilement (POP) avec réactivation de la tâche de fond précédente.

### 4. Micro-Jalons (`/api/tasks/:id/milestones`)
* `POST /api/tasks/:id/milestones` : Ajoute un jalon avec durée personnalisée (15m, 30m, 45m...).
* `PATCH /api/milestones/:id` : Modifie le libellé, la durée ou coche l'état terminé.
* `DELETE /api/milestones/:id` : Supprime un micro-jalon.

### 5. Prise de Notes de Réunion (`/api/meeting-notes`)
* `GET /api/meeting-notes` : Récupère la liste de toutes les notes de réunion.
* `POST /api/meeting-notes` : Crée ou sauvegarde automatiquement une note de réunion en Markdown.
* `PATCH /api/meeting-notes/:id` : Mise à jour en temps réel des notes écrites.
* `DELETE /api/meeting-notes/:id` : Supprime une note.

### 6. Checklist Matinale (`/api/morning-checks`)
* `GET /api/morning-checks` : Récupère les vérifications matinales.
* `POST /api/morning-checks` : Ajoute une routine.
* `PATCH /api/morning-checks/:id/toggle` : Coche / décoche une routine.
* `POST /api/morning-checks/reset` : Réinitialise la checklist du jour.

### 7. Événements Calendrier (`/api/calendar-events`)
* `GET /api/calendar-events` : Événements synchronisés avec l'agenda.
* `POST /api/calendar-events` : Création d'un événement / réunion.
* `PATCH /api/calendar-events/:id` : Mise à jour d'un événement.
* `DELETE /api/calendar-events/:id` : Suppression.

---

## 🔒 Variables d'Environnement
* `DATABASE_URL` : Chaîne de connexion PostgreSQL avec SSL (`neon.tech`).
* `JWT_SECRET` : Clé secrète de signature des tokens.
* `PORT` : Port d'écoute du serveur HTTP (défaut `4000`).
