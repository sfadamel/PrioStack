const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const connectionString = process.env.DATABASE_URL || "postgresql://neondb_owner:npg_Hrk4Gsz5eAif@ep-round-mode-b4hydavv-pooler.c-6.us-east-2.aws.neon.tech/prio_stack?sslmode=require";

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function initDb() {
  console.log('Connexion à Neon.tech en cours...');
  const client = await pool.connect();
  try {
    console.log('1. Exécution du schéma SQL...');
    const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await client.query(schemaSql);
    console.log('✔ Schéma appliqué avec succès.');

    console.log('2. Vérification/Création du compte Administrateur...');
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@priostack.local';
    const adminPass = process.env.ADMIN_PASSWORD || 'AdminPrio2026!';
    const adminName = 'Architecte & Manager (Admin)';

    const existingAdmin = await client.query('SELECT id FROM users WHERE email = $1', [adminEmail]);
    let adminUserId;

    if (existingAdmin.rows.length === 0) {
      const salt = await bcrypt.genSalt(10);
      const hash = await bcrypt.hash(adminPass, salt);
      const insertRes = await client.query(
        `INSERT INTO users (email, password_hash, full_name, role)
         VALUES ($1, $2, $3, 'admin')
         RETURNING id`,
        [adminEmail, hash, adminName]
      );
      adminUserId = insertRes.rows[0].id;
      console.log(`✔ Compte Administrateur créé :`);
      console.log(`   Email : ${adminEmail}`);
      console.log(`   Mot de passe : ${adminPass}`);
    } else {
      adminUserId = existingAdmin.rows[0].id;
      console.log(`ℹ Le compte Administrateur existe déjà (id: ${adminUserId})`);
    }

    // 3. Seed initial de démo pour l'admin si la table tasks est vide
    const taskCount = await client.query('SELECT count(*) FROM tasks WHERE user_id = $1', [adminUserId]);
    if (parseInt(taskCount.rows[0].count) === 0) {
      console.log('3. Initialisation des tâches et routines initiales pour l\'admin...');

      // Routine
      const checks = [
        ['Contrôler les synchros DB & réplicas nocturnes', 'Data & DB', true, 1],
        ['Vérifier les alertes des workers Python / ETL', 'Workers Python', true, 2],
        ['Vérifier l\'Uptime API Gateway & latence P99', 'Monitoring', false, 3],
        ['Scanner les PR bloquantes dans Azure DevOps', 'Engineering', false, 4],
        ['Verrouiller le créneau Sanctuaire Architecture (90 min)', 'Focus', false, 5]
      ];
      for (const [title, cat, checked, order] of checks) {
        await client.query(
          `INSERT INTO morning_checks (user_id, title, category, is_checked, sort_order)
           VALUES ($1, $2, $3, $4, $5)`,
          [adminUserId, title, cat, checked, order]
        );
      }

      // Tâche de Fond du Jour (active_base)
      const deepWorkRes = await client.query(
        `INSERT INTO tasks (user_id, title, type, status, criticality, external_ref, stack_order)
         VALUES ($1, 'Refonte Pipeline Ingestion Événements Kafka -> Snowflake', 'deep_work', 'active_base', 3, 'AB#7421', 0)
         RETURNING id`,
        [adminUserId]
      );
      const deepWorkId = deepWorkRes.rows[0].id;

      // Micro-jalons
      const milestones = [
        ['Rédiger les schémas Avro et contrats d\'interface', 30, true, 1],
        ['Configurer le Dead Letter Queue (DLQ) Kafka', 30, true, 2],
        ['Optimiser le batch flushing vers le staging S3', 30, false, 3],
        ['Valider les benchmarks de débits et latence P95', 30, false, 4]
      ];
      for (const [mTitle, dur, done, mOrder] of milestones) {
        await client.query(
          `INSERT INTO micro_milestones (task_id, user_id, title, duration_minutes, is_done, sort_order)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [deepWorkId, adminUserId, mTitle, dur, done, mOrder]
        );
      }

      // Réserve et Urgences
      await client.query(
        `INSERT INTO tasks (user_id, title, type, status, criticality, external_ref, stack_order)
         VALUES ($1, 'Documentation Stratégie Résilience Multi-Région AWS', 'deep_work', 'backlog', 2, 'AB#7800', 0)`,
        [adminUserId]
      );
      await client.query(
        `INSERT INTO tasks (user_id, title, type, status, criticality, external_ref, requester_or_assignee)
         VALUES ($1, 'Incident P1 : Fuite mémoire OOM sur Gateway Prod', 'urgence', 'backlog', 3, 'AB#9012', 'SRE Lead')`,
        [adminUserId]
      );
      await client.query(
        `INSERT INTO tasks (user_id, title, type, status, criticality, requester_or_assignee)
         VALUES ($1, 'Blocage Dev : Crash transactionnel Distributed Lock Redis', 'dev_block', 'backlog', 2, 'Julien B. (Backend)')`,
        [adminUserId]
      );

      // Événements d'agenda
      const now = new Date();
      const inOneHour = new Date(now.getTime() + 60 * 60 * 1000);
      const inTwoHours = new Date(now.getTime() + 120 * 60 * 1000);

      await client.query(
        `INSERT INTO calendar_events (user_id, title, category, start_time, end_time, participants_or_location, external_ref)
         VALUES ($1, 'Comité Architecture & Arbitrages Techniques', 'architecture', $2, $3, 'Salle Conseil & Teams', 'AB#7421')`,
        [adminUserId, inOneHour.toISOString(), inTwoHours.toISOString()]
      );

      console.log('✔ Tâches et calendrier initialisés pour l\'admin.');
    }

    console.log('=== Base Neon.tech configurée avec succès ! ===');
  } catch (err) {
    console.error('Erreur lors de l\'initialisation :', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

initDb();
