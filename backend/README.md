# PrioStack Backend API & Synchronisation Cloud Neon.tech

Ce backend Node.js / Express fait la passerelle entre l'application PrioStack (Web, Desktop, Mobile) et la base de données PostgreSQL serverless hébergée sur **Neon.tech**.

## 🚀 Démarrage Rapide

### 1. Prérequis
- Node.js v18+ installé

### 2. Installation des dépendances
```bash
cd backend
npm install
```

### 3. Initialiser / Réinitialiser la base de données Neon
Pour créer les tables (`users`, `tasks`, `micro_milestones`, `morning_checks`, `calendar_events`) et insérer le compte administrateur avec des données d'exemple :
```bash
node init-db.js
```

### 4. Démarrer le serveur API
```bash
node server.js
```
Le serveur s'exécute par défaut sur `http://localhost:4000`.

---

## 🔐 Identifiants par défaut du Compte Administrateur
- **Email** : `admin@priostack.local`
- **Mot de passe** : `AdminPrio2026!`
- **Rôle** : `admin`

*(Il est également possible de créer de nouveaux comptes utilisateur directement depuis l'écran de connexion de l'application via le bouton "Créer un compte").*

---

## 📡 Endpoints de l'API

### Authentification (`/api/auth`)
- `POST /api/auth/register` : Création de compte (email, mot de passe, nom).
- `POST /api/auth/login` : Connexion, retourne un JWT valide 30 jours et les infos de l'utilisateur.
- `GET /api/auth/me` : Récupération du profil connecté via le Bearer Token.

### Tâches & Sanctuaire (`/api/tasks`)
- `GET /api/tasks` : Liste de toutes les tâches de l'utilisateur avec leurs micro-jalons.
- `POST /api/tasks` : Création d'une tâche.
- `PUT /api/tasks/:id` : Mise à jour d'une tâche.
- `DELETE /api/tasks/:id` : Suppression d'une tâche.
- `POST /api/tasks/push-interruption` : Empilement LIFO prioritaire d'une urgence/interruption.
- `POST /api/tasks/:id/pop` : Dépilement LIFO au sommet du Sanctuaire.

### Checklist Matinale (`/api/morning-checks`)
- `GET /api/morning-checks` : Récupération des routines matinales de l'utilisateur.
- `POST /api/morning-checks` : Ajout d'une routine.
- `PUT /api/morning-checks/:id` : Mise à jour du libellé ou statut complété.
- `DELETE /api/morning-checks/:id` : Suppression.

### Événements Calendrier (`/api/calendar-events`)
- `GET /api/calendar-events` : Événements synchronisés avec l'agenda.
- `POST /api/calendar-events` : Création.
- `PUT /api/calendar-events/:id` : Mise à jour.
- `DELETE /api/calendar-events/:id` : Suppression.

---

## ☁️ Déploiement Cloud (Render, Railway, Fly.io, VPS)
Pour héberger ce backend en ligne 24/7 gratuitement ou à faible coût :
1. Déployez le dossier `backend` sur un service comme [Render.com](https://render.com) ou [Railway.app](https://railway.app).
2. Configurez les variables d'environnement suivantes :
   - `DATABASE_URL` = `postgresql://neondb_owner:npg_Hrk4Gsz5eAif@ep-round-mode-b4hydavv-pooler.c-6.us-east-2.aws.neon.tech/prio_stack?sslmode=require`
   - `JWT_SECRET` = Une clé secrète aléatoire et sécurisée
   - `PORT` = `4000` (ou fourni automatiquement par l'hébergeur)
3. Dans l'application PrioStack, si le backend est distant, il suffit d'ajuster l'URL de l'API (`authApiUrlProvider` ou lors du login) avec l'adresse HTTPS de votre hébergeur.
