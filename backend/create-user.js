// Script CLI pour ajouter un utilisateur dans Neon.tech avec mot de passe chiffré Bcrypt
// Usage: node create-user.js <email> <password> "<nom complet>" [admin|user]
// Exemple: node create-user.js dev@mondomaine.com SecretPass123! "Alice Dupont" user

const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const connectionString = process.env.DATABASE_URL || "postgresql://neondb_owner:npg_Hrk4Gsz5eAif@ep-round-mode-b4hydavv-pooler.c-6.us-east-2.aws.neon.tech/prio_stack?sslmode=require";

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 3) {
    console.log('❌ Paramètres manquants.');
    console.log('Usage: node create-user.js <email> <mot_de_passe> "<Nom Complet>" [role: admin|user]');
    console.log('Exemple: node create-user.js bob@acme.com P@ssword123 "Bob Martin" user');
    process.exit(1);
  }

  const email = args[0].trim().toLowerCase();
  const password = args[1];
  const fullName = args[2].trim();
  const role = (args[3] || 'user').toLowerCase();

  if (!['admin', 'user'].includes(role)) {
    console.error('❌ Le rôle doit être "admin" ou "user".');
    process.exit(1);
  }

  try {
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      console.error(`❌ Un utilisateur avec l'email "${email}" existe déjà.`);
      process.exit(1);
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const res = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, email, full_name, role, created_at`,
      [email, passwordHash, fullName, role]
    );

    const newUser = res.rows[0];
    console.log('✅ Nouvel utilisateur créé avec succès dans Neon.tech !');
    console.log('----------------------------------------------------');
    console.log(`ID          : ${newUser.id}`);
    console.log(`Email       : ${newUser.email}`);
    console.log(`Nom Complet : ${newUser.full_name}`);
    console.log(`Rôle        : ${newUser.role}`);
    console.log(`Créé le     : ${newUser.created_at}`);
    console.log('----------------------------------------------------');
  } catch (err) {
    console.error('❌ Erreur lors de la création :', err.message);
  } finally {
    await pool.end();
  }
}

main();
