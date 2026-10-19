const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || 'priostack_super_secret_jwt_key_2026_neon';

const connectionString = process.env.DATABASE_URL || "postgresql://neondb_owner:npg_Hrk4Gsz5eAif@ep-round-mode-b4hydavv-pooler.c-6.us-east-2.aws.neon.tech/prio_stack?sslmode=require";

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

app.use(cors());
app.use(express.json());

// --- MIDDLEWARE D'AUTHENTIFICATION JWT ---
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token manquant ou format invalide' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload; // { id, email, role }
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Session expirée ou token invalide' });
  }
}

// --- 1. ROUTES D'AUTHENTIFICATION ---

// Login
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email et mot de passe requis' });
  }

  try {
    const userRes = await pool.query(
      'SELECT id, email, password_hash, full_name, role, is_active FROM users WHERE LOWER(email) = LOWER($1)',
      [email.trim()]
    );

    if (userRes.rows.length === 0) {
      return res.status(401).json({ error: 'Identifiants incorrects' });
    }

    const user = userRes.rows[0];
    if (!user.is_active) {
      return res.status(403).json({ error: 'Ce compte a été désactivé par un administrateur' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Identifiants incorrects' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role, name: user.full_name },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        role: user.role
      }
    });
  } catch (err) {
    console.error('Erreur login:', err);
    return res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Création de compte (Inscription ou création par admin)
app.post('/api/auth/register', async (req, res) => {
  const { email, password, fullName } = req.body;
  if (!email || !password || !fullName) {
    return res.status(400).json({ error: 'Tous les champs sont requis' });
  }

  try {
    const check = await pool.query('SELECT id FROM users WHERE LOWER(email) = LOWER($1)', [email.trim()]);
    if (check.rows.length > 0) {
      return res.status(409).json({ error: 'Un compte existe déjà avec cette adresse email' });
    }

    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);

    const insert = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role)
       VALUES ($1, $2, $3, 'user')
       RETURNING id, email, full_name, role`,
      [email.trim().toLowerCase(), hash, fullName.trim()]
    );

    const newUser = insert.rows[0];
    const token = jwt.sign(
      { id: newUser.id, email: newUser.email, role: newUser.role, name: newUser.full_name },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(201).json({
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.full_name,
        role: newUser.role
      }
    });
  } catch (err) {
    console.error('Erreur register:', err);
    return res.status(500).json({ error: 'Erreur lors de la création du compte' });
  }
});

// Profil courant
app.get('/api/auth/me', authMiddleware, async (req, res) => {
  try {
    const userRes = await pool.query(
      'SELECT id, email, full_name, role FROM users WHERE id = $1',
      [req.user.id]
    );
    if (userRes.rows.length === 0) return res.status(404).json({ error: 'Utilisateur introuvable' });
    const u = userRes.rows[0];
    res.json({
      id: u.id,
      email: u.email,
      fullName: u.full_name,
      role: u.role
    });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// --- 2. ROUTES TÂCHES (CALL STACK & FLUX) ---

// Lister toutes les tâches de l'utilisateur avec leurs micro-jalons
app.get('/api/tasks', authMiddleware, async (req, res) => {
  try {
    const tasksRes = await pool.query(
      `SELECT * FROM tasks WHERE user_id = $1 AND deleted_at IS NULL ORDER BY stack_order ASC, created_at DESC`,
      [req.user.id]
    );
    const milestonesRes = await pool.query(
      `SELECT * FROM micro_milestones WHERE user_id = $1 AND deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC`,
      [req.user.id]
    );

    // Regroupement par tâche
    const milestonesByTaskId = {};
    for (const m of milestonesRes.rows) {
      if (!milestonesByTaskId[m.task_id]) milestonesByTaskId[m.task_id] = [];
      milestonesByTaskId[m.task_id].push(m);
    }

    const payload = tasksRes.rows.map(t => ({
      ...t,
      milestones: milestonesByTaskId[t.id] || []
    }));

    res.json(payload);
  } catch (err) {
    console.error('Erreur get tasks:', err);
    res.status(500).json({ error: 'Erreur récupération tâches' });
  }
});

// Créer une nouvelle tâche
app.post('/api/tasks', authMiddleware, async (req, res) => {
  const { title, type, status, criticality, externalRef, requesterOrAssignee, initialMilestones } = req.body;
  if (!title || !type) return res.status(400).json({ error: 'Titre et type requis' });

  try {
    const taskInsert = await pool.query(
      `INSERT INTO tasks (user_id, title, type, status, criticality, external_ref, requester_or_assignee)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        req.user.id,
        title.trim(),
        type,
        status || 'backlog',
        criticality || 2,
        externalRef || null,
        requesterOrAssignee || null
      ]
    );

    const createdTask = taskInsert.rows[0];
    const createdMilestones = [];

    if (Array.isArray(initialMilestones) && initialMilestones.length > 0) {
      for (let i = 0; i < initialMilestones.length; i++) {
        const m = initialMilestones[i];
        const mRes = await pool.query(
          `INSERT INTO micro_milestones (task_id, user_id, title, duration_minutes, sort_order)
           VALUES ($1, $2, $3, 30, $4)
           RETURNING *`,
          [createdTask.id, req.user.id, m, i + 1]
        );
        createdMilestones.push(mRes.rows[0]);
      }
    }

    res.status(201).json({ ...createdTask, milestones: createdMilestones });
  } catch (err) {
    console.error('Erreur create task:', err);
    res.status(500).json({ error: 'Erreur création tâche' });
  }
});

// PUSH Interruption
app.post('/api/tasks/push-interruption', authMiddleware, async (req, res) => {
  const { resumeNote, existingUrgencyTaskId, newUrgencyTitle, externalRef } = req.body;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Mettre les tâches actuellement au sommet en pause
    await client.query(
      `UPDATE tasks SET status = 'pushed_pause', updated_at = NOW()
       WHERE user_id = $1 AND status IN ('active_base', 'active_top')`,
      [req.user.id]
    );

    // Enregistrer la note de reprise sur la tâche de fond de base
    if (resumeNote) {
      await client.query(
        `UPDATE tasks SET resume_note = $1, updated_at = NOW()
         WHERE user_id = $2 AND status = 'pushed_pause' AND type = 'deep_work'`,
        [resumeNote, req.user.id]
      );
    }

    // Trouver le plus haut stack_order
    const orderRes = await client.query(
      `SELECT COALESCE(MAX(stack_order), 0) as max_order FROM tasks WHERE user_id = $1`,
      [req.user.id]
    );
    const nextOrder = parseInt(orderRes.rows[0].max_order) + 1;

    let activeTopTask;
    if (existingUrgencyTaskId) {
      const upRes = await client.query(
        `UPDATE tasks SET status = 'active_top', stack_order = $1, updated_at = NOW()
         WHERE id = $2 AND user_id = $3
         RETURNING *`,
        [nextOrder, existingUrgencyTaskId, req.user.id]
      );
      activeTopTask = upRes.rows[0];
    } else if (newUrgencyTitle) {
      const insRes = await client.query(
        `INSERT INTO tasks (user_id, title, type, status, criticality, external_ref, stack_order)
         VALUES ($1, $2, 'urgence', 'active_top', 3, $3, $4)
         RETURNING *`,
        [req.user.id, newUrgencyTitle.trim(), externalRef || null, nextOrder]
      );
      activeTopTask = insRes.rows[0];
    }

    await client.query('COMMIT');
    res.json({ message: 'PUSH réussi', task: activeTopTask });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erreur PUSH:', err);
    res.status(500).json({ error: 'Erreur PUSH' });
  } finally {
    client.release();
  }
});

// POP Interruption
app.post('/api/tasks/:id/pop', authMiddleware, async (req, res) => {
  const taskId = req.params.id;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Clôturer l'urgence
    await client.query(
      `UPDATE tasks SET status = 'done', updated_at = NOW() WHERE id = $1 AND user_id = $2`,
      [taskId, req.user.id]
    );

    // 2. Trouver la tâche paused avec le plus grand stack_order
    const nextRes = await client.query(
      `SELECT id, type FROM tasks
       WHERE user_id = $1 AND status = 'pushed_pause'
       ORDER BY stack_order DESC LIMIT 1`,
      [req.user.id]
    );

    if (nextRes.rows.length > 0) {
      const nextTask = nextRes.rows[0];
      const newStatus = nextTask.type === 'deep_work' ? 'active_base' : 'active_top';
      await client.query(
        `UPDATE tasks SET status = $1, updated_at = NOW() WHERE id = $2`,
        [newStatus, nextTask.id]
      );
    }

    await client.query('COMMIT');
    res.json({ message: 'POP réussi' });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: 'Erreur POP' });
  } finally {
    client.release();
  }
});

// Mettre à jour une tâche
app.patch('/api/tasks/:id', authMiddleware, async (req, res) => {
  const { title, status, elapsedSeconds, resumeNote, requesterOrAssignee, criticality } = req.body;
  try {
    const fields = [];
    const values = [];
    let idx = 1;

    if (title !== undefined) { fields.push(`title = $${idx++}`); values.push(title); }
    if (status !== undefined) { fields.push(`status = $${idx++}`); values.push(status); }
    if (elapsedSeconds !== undefined) { fields.push(`elapsed_seconds = $${idx++}`); values.push(elapsedSeconds); }
    if (resumeNote !== undefined) { fields.push(`resume_note = $${idx++}`); values.push(resumeNote); }
    if (requesterOrAssignee !== undefined) { fields.push(`requester_or_assignee = $${idx++}`); values.push(requesterOrAssignee); }
    if (criticality !== undefined) { fields.push(`criticality = $${idx++}`); values.push(criticality); }

    if (fields.length === 0) return res.json({ message: 'Aucun changement' });

    fields.push(`updated_at = NOW()`);
    values.push(req.params.id, req.user.id);

    const query = `UPDATE tasks SET ${fields.join(', ')} WHERE id = $${idx++} AND user_id = $${idx} RETURNING *`;
    const result = await pool.query(query, values);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur mise à jour tâche' });
  }
});

// Supprimer une tâche (soft-delete)
app.delete('/api/tasks/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `UPDATE tasks SET deleted_at = NOW() WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );
    res.json({ message: 'Tâche supprimée' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur suppression tâche' });
  }
});

// --- 3. ROUTES MICRO-JALONS ---
app.post('/api/tasks/:id/milestones', authMiddleware, async (req, res) => {
  const { title, durationMinutes } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO micro_milestones (task_id, user_id, title, duration_minutes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.params.id, req.user.id, title, durationMinutes || 30]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur création micro-jalon' });
  }
});

app.patch('/api/milestones/:id', authMiddleware, async (req, res) => {
  const { isDone, title } = req.body;
  try {
    const result = await pool.query(
      `UPDATE micro_milestones SET is_done = COALESCE($1, is_done), title = COALESCE($2, title), updated_at = NOW()
       WHERE id = $3 AND user_id = $4 RETURNING *`,
      [isDone, title, req.params.id, req.user.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur jalon' });
  }
});

app.delete('/api/milestones/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `UPDATE micro_milestones SET deleted_at = NOW() WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );
    res.json({ message: 'Jalon supprimé' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur suppression jalon' });
  }
});

// --- 4. ROUTES MORNING CHECK-LIST ---
app.get('/api/morning-checks', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM morning_checks WHERE user_id = $1 AND deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Erreur morning checks' });
  }
});

app.post('/api/morning-checks', authMiddleware, async (req, res) => {
  const { title, category } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO morning_checks (user_id, title, category)
       VALUES ($1, $2, $3) RETURNING *`,
      [req.user.id, title, category || 'Infra & Ops']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur création routine' });
  }
});

app.patch('/api/morning-checks/:id/toggle', authMiddleware, async (req, res) => {
  const { isChecked } = req.body;
  try {
    const result = await pool.query(
      `UPDATE morning_checks SET is_checked = $1, updated_at = NOW() WHERE id = $2 AND user_id = $3 RETURNING *`,
      [isChecked, req.params.id, req.user.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur toggle' });
  }
});

app.post('/api/morning-checks/reset', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `UPDATE morning_checks SET is_checked = FALSE, last_reset_at = NOW(), updated_at = NOW() WHERE user_id = $1`,
      [req.user.id]
    );
    res.json({ message: 'Routine réinitialisée' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur reset' });
  }
});

app.delete('/api/morning-checks/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `UPDATE morning_checks SET deleted_at = NOW() WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );
    res.json({ message: 'Point supprimé' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur delete routine' });
  }
});

// --- 5. ROUTES CALENDRIER & AGENDA ---
app.get('/api/calendar-events', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM calendar_events WHERE user_id = $1 AND deleted_at IS NULL ORDER BY start_time ASC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Erreur agenda' });
  }
});

app.post('/api/calendar-events', authMiddleware, async (req, res) => {
  const { title, category, startTime, endTime, participantsOrLocation, externalRef, notes } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO calendar_events (user_id, title, category, start_time, end_time, participants_or_location, external_ref, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [req.user.id, title, category || 'meeting', startTime, endTime, participantsOrLocation, externalRef, notes]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur création événement' });
  }
});

app.patch('/api/calendar-events/:id/toggle', authMiddleware, async (req, res) => {
  const { isCompleted } = req.body;
  try {
    const result = await pool.query(
      `UPDATE calendar_events SET is_completed = $1, updated_at = NOW() WHERE id = $2 AND user_id = $3 RETURNING *`,
      [isCompleted, req.params.id, req.user.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Erreur toggle calendar' });
  }
});

app.delete('/api/calendar-events/:id', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `UPDATE calendar_events SET deleted_at = NOW() WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );
    res.json({ message: 'Événement supprimé' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur delete calendar' });
  }
});

// Santé & Ping
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'PrioStack Neon Cloud API', time: new Date() });
});

app.listen(PORT, () => {
  console.log(`🚀 Serveur API PrioStack en écoute sur le port ${PORT}`);
});
