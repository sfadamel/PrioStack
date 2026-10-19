const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL || "postgresql://neondb_owner:npg_Hrk4Gsz5eAif@ep-round-mode-b4hydavv-pooler.c-6.us-east-2.aws.neon.tech/prio_stack?sslmode=require";

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function runMigration() {
  console.log('--- Migration Neon DB (Approbation Utilisateurs & Prise de notes Réunion) ---');
  const client = await pool.connect();
  try {
    // 1. Champ is_approved sur users
    console.log('1. Ajout de la colonne is_approved sur users...');
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS is_approved BOOLEAN NOT NULL DEFAULT FALSE;
    `);

    // Valider tous les admins
    await client.query(`
      UPDATE users 
      SET is_approved = TRUE 
      WHERE role = 'admin' OR email = 'admin@priostack.local';
    `);

    // 2. Table meeting_notes
    console.log('2. Création de la table meeting_notes...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS meeting_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        meeting_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        participants TEXT DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        action_items JSONB DEFAULT '[]',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_meeting_notes_user ON meeting_notes(user_id, updated_at DESC);
    `);

    console.log('✔ Migration Neon terminée avec succès !');
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(err => {
  console.error('Erreur migration:', err);
  process.exit(1);
});
