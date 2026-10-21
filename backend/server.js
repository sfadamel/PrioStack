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
  ssl: { rejectUnauthorized: false },
  max: 15,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
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
      'SELECT id, email, password_hash, full_name, role, is_active, is_approved FROM users WHERE LOWER(email) = LOWER($1)',
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

    // Vérification de la validation par l'administrateur
    if (user.role !== 'admin' && !user.is_approved) {
      return res.status(403).json({
        error: 'Votre compte est en attente de validation par un administrateur avant de pouvoir vous connecter.'
      });
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

// Création de compte (Inscription soumise à validation administrateur)
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
      `INSERT INTO users (email, password_hash, full_name, role, is_approved)
       VALUES ($1, $2, $3, 'user', FALSE)
       RETURNING id, email, full_name, role, is_approved`,
      [email.trim().toLowerCase(), hash, fullName.trim()]
    );

    const newUser = insert.rows[0];
    return res.status(201).json({
      message: 'Inscription enregistrée ! Votre compte doit être validé par un administrateur avant votre première connexion.',
      pendingApproval: true,
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.full_name,
        role: newUser.role,
        isApproved: false
      }
    });
  } catch (err) {
    console.error('Erreur register:', err);
    return res.status(500).json({ error: 'Erreur lors de la création du compte' });
  }
});

// --- ROUTES D'ADMINISTRATION (Validation des utilisateurs) ---

// Lister les utilisateurs
app.get('/api/admin/users', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Accès réservé aux administrateurs' });
  }
  try {
    const result = await pool.query(
      'SELECT id, email, full_name, role, is_active, is_approved, created_at FROM users ORDER BY created_at DESC'
    );
    res.json({ users: result.rows });
  } catch (err) {
    console.error('Erreur get admin users:', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des utilisateurs' });
  }
});

// Valider un utilisateur
app.post('/api/admin/users/:id/approve', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Accès réservé aux administrateurs' });
  }
  try {
    const updateRes = await pool.query(
      'UPDATE users SET is_approved = TRUE, updated_at = NOW() WHERE id = $1 RETURNING id, email, full_name, role, is_approved',
      [req.params.id]
    );
    if (updateRes.rows.length === 0) return res.status(404).json({ error: 'Utilisateur introuvable' });
    res.json({ success: true, user: updateRes.rows[0] });
  } catch (err) {
    console.error('Erreur approve user:', err);
    res.status(500).json({ error: 'Erreur lors de l\'approbation de l\'utilisateur' });
  }
});

// Supprimer ou révoquer un utilisateur
app.delete('/api/admin/users/:id', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Accès réservé aux administrateurs' });
  }
  try {
    const delRes = await pool.query(
      'DELETE FROM users WHERE id = $1 AND role != \'admin\' RETURNING id, email',
      [req.params.id]
    );
    if (delRes.rows.length === 0) {
      return res.status(400).json({ error: 'Impossible de supprimer cet utilisateur (introuvable ou compte administrateur)' });
    }
    res.json({ success: true, deletedId: req.params.id });
  } catch (err) {
    console.error('Erreur delete user:', err);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'utilisateur' });
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

// Route ultra-légère pour vérifier si des données ont changé (Sync Check sans overhead)
app.get('/api/sync/version', authMiddleware, async (req, res) => {
  try {
    const taskVer = await pool.query(
      `SELECT MAX(updated_at) as v FROM tasks WHERE user_id = $1`,
      [req.user.id]
    );
    const checkVer = await pool.query(
      `SELECT MAX(updated_at) as v FROM morning_checks WHERE user_id = $1`,
      [req.user.id]
    );
    res.json({
      taskVer: taskVer.rows[0]?.v ? new Date(taskVer.rows[0].v).toISOString() : '',
      checkVer: checkVer.rows[0]?.v ? new Date(checkVer.rows[0].v).toISOString() : '',
    });
  } catch (err) {
    res.status(500).json({ error: 'Sync check failed' });
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
  const { isDone, title, durationMinutes } = req.body;
  try {
    const result = await pool.query(
      `UPDATE micro_milestones
       SET is_done = COALESCE($1, is_done),
           title = COALESCE($2, title),
           duration_minutes = COALESCE($3, duration_minutes),
           updated_at = NOW()
       WHERE id = $4 AND user_id = $5 RETURNING *`,
      [isDone, title, durationMinutes, req.params.id, req.user.id]
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

// --- 5. ROUTES SAUVEGARDE & RESTAURATION JSON (EXPORT / IMPORT) ---

// Exporter les données de l'utilisateur au format standard PrioStack
app.get('/api/backup/export', authMiddleware, async (req, res) => {
  try {
    const tasksRes = await pool.query(
      `SELECT * FROM tasks WHERE user_id = $1 AND deleted_at IS NULL ORDER BY stack_order ASC, created_at ASC`,
      [req.user.id]
    );
    const milestonesRes = await pool.query(
      `SELECT * FROM micro_milestones WHERE user_id = $1 AND deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC`,
      [req.user.id]
    );
    const checksRes = await pool.query(
      `SELECT * FROM morning_checks WHERE user_id = $1 AND deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC`,
      [req.user.id]
    );
    const eventsRes = await pool.query(
      `SELECT * FROM calendar_events WHERE user_id = $1 AND deleted_at IS NULL ORDER BY start_time ASC`,
      [req.user.id]
    );

    const tasks = tasksRes.rows.map(t => ({
      id: t.id,
      userId: t.user_id,
      workspaceId: 'wks_damelit_arch',
      visibility: t.visibility || 'private',
      syncStatus: 'synced',
      createdAt: t.created_at ? new Date(t.created_at).toISOString() : new Date().toISOString(),
      updatedAt: t.updated_at ? new Date(t.updated_at).toISOString() : new Date().toISOString(),
      deletedAt: t.deleted_at ? new Date(t.deleted_at).toISOString() : null,
      title: t.title,
      type: t.type,
      status: t.status,
      criticality: t.criticality,
      externalRef: t.external_ref,
      requesterOrAssignee: t.requester_or_assignee,
      resumeNote: t.resume_note,
      stackOrder: t.stack_order,
      elapsedSeconds: t.elapsed_seconds,
      interruptionCount: t.interruption_count,
    }));

    const milestones = milestonesRes.rows.map(m => ({
      id: m.id,
      taskId: m.task_id,
      userId: m.user_id,
      workspaceId: 'wks_damelit_arch',
      visibility: 'private',
      syncStatus: 'synced',
      createdAt: m.created_at ? new Date(m.created_at).toISOString() : new Date().toISOString(),
      updatedAt: m.updated_at ? new Date(m.updated_at).toISOString() : new Date().toISOString(),
      deletedAt: m.deleted_at ? new Date(m.deleted_at).toISOString() : null,
      title: m.title,
      durationMinutes: m.duration_minutes,
      isDone: m.is_done,
      sortOrder: m.sort_order,
    }));

    const morningChecks = checksRes.rows.map(c => ({
      id: c.id,
      userId: c.user_id,
      workspaceId: 'wks_damelit_arch',
      visibility: 'private',
      syncStatus: 'synced',
      createdAt: c.created_at ? new Date(c.created_at).toISOString() : new Date().toISOString(),
      updatedAt: c.updated_at ? new Date(c.updated_at).toISOString() : new Date().toISOString(),
      deletedAt: c.deleted_at ? new Date(c.deleted_at).toISOString() : null,
      title: c.title,
      category: c.category,
      isChecked: c.is_checked,
      sortOrder: c.sort_order,
      lastResetAt: c.last_reset_at ? new Date(c.last_reset_at).toISOString() : null,
    }));

    const calendarEvents = eventsRes.rows.map(e => ({
      id: e.id,
      userId: e.user_id,
      workspaceId: 'wks_damelit_arch',
      visibility: e.visibility || 'team',
      syncStatus: 'synced',
      createdAt: e.created_at ? new Date(e.created_at).toISOString() : new Date().toISOString(),
      updatedAt: e.updated_at ? new Date(e.updated_at).toISOString() : new Date().toISOString(),
      deletedAt: e.deleted_at ? new Date(e.deleted_at).toISOString() : null,
      title: e.title,
      category: e.category,
      startTime: e.start_time ? new Date(e.start_time).toISOString() : new Date().toISOString(),
      endTime: e.end_time ? new Date(e.end_time).toISOString() : new Date().toISOString(),
      participantsOrLocation: e.participants_or_location,
      externalRef: e.external_ref,
      notes: e.notes,
      isCompleted: e.is_completed,
      linkedTaskId: e.linked_task_id,
    }));

    const backup = {
      format: 'priostack-backup',
      version: 1,
      exportedAt: new Date().toISOString(),
      tasks,
      milestones,
      morningChecks,
      calendarEvents,
    };

    res.json(backup);
  } catch (err) {
    console.error('Erreur export backup:', err);
    res.status(500).json({ error: 'Erreur lors de l\'exportation de la sauvegarde' });
  }
});

// Importer et restaurer les données dans l'espace Neon de l'utilisateur
app.post('/api/backup/import', authMiddleware, async (req, res) => {
  const payload = req.body;
  if (!payload || typeof payload !== 'object') {
    return res.status(400).json({ error: 'Fichier ou corps de requête invalide.' });
  }

  const tasks = Array.isArray(payload.tasks) ? payload.tasks : [];
  const milestones = Array.isArray(payload.milestones) ? payload.milestones : [];
  const morningChecks = Array.isArray(payload.morningChecks) ? payload.morningChecks : (Array.isArray(payload.morning_checks) ? payload.morning_checks : []);
  const calendarEvents = Array.isArray(payload.calendarEvents) ? payload.calendarEvents : (Array.isArray(payload.calendar_events) ? payload.calendar_events : []);

  const client = await pool.connect();
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const crypto = require('crypto');

  try {
    await client.query('BEGIN');

    // Nettoyage préalable des données existantes de l'utilisateur
    await client.query('DELETE FROM micro_milestones WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM calendar_events WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM tasks WHERE user_id = $1', [req.user.id]);
    await client.query('DELETE FROM morning_checks WHERE user_id = $1', [req.user.id]);

    const taskIdMap = {};

    // 1. Tâches
    for (const t of tasks) {
      const origId = t.id || t.taskId;
      const targetId = (origId && uuidRegex.test(origId)) ? origId : crypto.randomUUID();
      if (origId) taskIdMap[origId] = targetId;

      await client.query(
        `INSERT INTO tasks (id, user_id, title, type, status, criticality, external_ref, requester_or_assignee, resume_note, stack_order, elapsed_seconds, interruption_count, visibility)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           type = EXCLUDED.type,
           status = EXCLUDED.status,
           criticality = EXCLUDED.criticality,
           external_ref = EXCLUDED.external_ref,
           requester_or_assignee = EXCLUDED.requester_or_assignee,
           resume_note = EXCLUDED.resume_note,
           stack_order = EXCLUDED.stack_order,
           elapsed_seconds = EXCLUDED.elapsed_seconds,
           interruption_count = EXCLUDED.interruption_count,
           visibility = EXCLUDED.visibility,
           deleted_at = NULL,
           updated_at = NOW()`,
        [
          targetId,
          req.user.id,
          t.title || 'Sans titre',
          t.type || 'deep_work',
          t.status || 'backlog',
          t.criticality ?? 2,
          t.externalRef || t.external_ref || null,
          t.requesterOrAssignee || t.requester_or_assignee || null,
          t.resumeNote || t.resume_note || null,
          t.stackOrder ?? t.stack_order ?? 0,
          t.elapsedSeconds ?? t.elapsed_seconds ?? 0,
          t.interruptionCount ?? t.interruption_count ?? 0,
          t.visibility || 'private'
        ]
      );
    }

    // 2. Micro-jalons
    for (const m of milestones) {
      const origTaskId = m.taskId || m.task_id;
      const mappedTaskId = taskIdMap[origTaskId] || (origTaskId && uuidRegex.test(origTaskId) ? origTaskId : null);
      if (!mappedTaskId) continue;

      const mId = (m.id && uuidRegex.test(m.id)) ? m.id : crypto.randomUUID();
      await client.query(
        `INSERT INTO micro_milestones (id, task_id, user_id, title, duration_minutes, is_done, sort_order)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           duration_minutes = EXCLUDED.duration_minutes,
           is_done = EXCLUDED.is_done,
           sort_order = EXCLUDED.sort_order,
           deleted_at = NULL,
           updated_at = NOW()`,
        [
          mId,
          mappedTaskId,
          req.user.id,
          m.title || 'Micro-jalon',
          m.durationMinutes ?? m.duration_minutes ?? 30,
          Boolean(m.isDone ?? m.is_done),
          m.sortOrder ?? m.sort_order ?? 0
        ]
      );
    }

    // 3. Routines Morning Checks
    for (const c of morningChecks) {
      const cId = (c.id && uuidRegex.test(c.id)) ? c.id : crypto.randomUUID();
      await client.query(
        `INSERT INTO morning_checks (id, user_id, title, category, is_checked, sort_order)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           category = EXCLUDED.category,
           is_checked = EXCLUDED.is_checked,
           sort_order = EXCLUDED.sort_order,
           deleted_at = NULL,
           updated_at = NOW()`,
        [
          cId,
          req.user.id,
          c.title || 'Routine',
          c.category || 'Infra & Ops',
          Boolean(c.isChecked ?? c.is_checked),
          c.sortOrder ?? c.sort_order ?? 0
        ]
      );
    }

    // 4. Événements Calendrier
    for (const e of calendarEvents) {
      const eId = (e.id && uuidRegex.test(e.id)) ? e.id : crypto.randomUUID();
      const linkedTaskId = e.linkedTaskId || e.linked_task_id;
      const mappedLinkedTaskId = taskIdMap[linkedTaskId] || (linkedTaskId && uuidRegex.test(linkedTaskId) ? linkedTaskId : null);

      await client.query(
        `INSERT INTO calendar_events (id, user_id, title, category, start_time, end_time, participants_or_location, external_ref, notes, is_completed, linked_task_id, visibility)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           category = EXCLUDED.category,
           start_time = EXCLUDED.start_time,
           end_time = EXCLUDED.end_time,
           participants_or_location = EXCLUDED.participants_or_location,
           external_ref = EXCLUDED.external_ref,
           notes = EXCLUDED.notes,
           is_completed = EXCLUDED.is_completed,
           linked_task_id = EXCLUDED.linked_task_id,
           visibility = EXCLUDED.visibility,
           deleted_at = NULL,
           updated_at = NOW()`,
        [
          eId,
          req.user.id,
          e.title || 'Événement',
          e.category || 'meeting',
          e.startTime || e.start_time || new Date().toISOString(),
          e.endTime || e.end_time || new Date(Date.now() + 3600000).toISOString(),
          e.participantsOrLocation || e.participants_or_location || null,
          e.externalRef || e.external_ref || null,
          e.notes || null,
          Boolean(e.isCompleted ?? e.is_completed),
          mappedLinkedTaskId,
          e.visibility || 'team'
        ]
      );
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      imported: {
        tasks: tasks.length,
        milestones: milestones.length,
        morningChecks: morningChecks.length,
        calendarEvents: calendarEvents.length
      }
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erreur import backup:', err);
    res.status(500).json({ error: 'Erreur lors de l\'importation : ' + err.message });
  } finally {
    client.release();
  }
});

// --- 5. ROUTES NOTES DE RÉUNION (AUTO-SAVE & HISTORIQUE) ---

// Récupérer toutes les réunions de l'utilisateur
app.get('/api/meetings', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT m.id, m.title, m.meeting_date, m.participants, m.content, m.action_items,
              m.calendar_event_id, m.created_at, m.updated_at,
              ce.title AS calendar_event_title, ce.start_time AS calendar_event_start
       FROM meeting_notes m
       LEFT JOIN calendar_events ce ON m.calendar_event_id = ce.id
       WHERE m.user_id = $1
       ORDER BY m.updated_at DESC`,
      [req.user.id]
    );
    res.json({ meetings: result.rows });
  } catch (err) {
    console.error('Erreur get meetings:', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des réunions' });
  }
});

// Créer ou enregistrer une nouvelle réunion
app.post('/api/meetings', authMiddleware, async (req, res) => {
  const { id, title, meetingDate, participants, content, actionItems, calendarEventId } = req.body;
  const isValidUuid = (str) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);
  const safeId = isValidUuid(id) ? id : null;
  const safeEventId = isValidUuid(calendarEventId) ? calendarEventId : null;

  try {
    const insert = await pool.query(
      `INSERT INTO meeting_notes (id, user_id, title, meeting_date, participants, content, action_items, calendar_event_id)
       VALUES (COALESCE($1, gen_random_uuid()), $2, $3, COALESCE($4, NOW()), $5, $6, $7, $8)
       RETURNING id, title, meeting_date, participants, content, action_items, calendar_event_id, created_at, updated_at`,
      [
        safeId,
        req.user.id,
        title || 'Nouvelle Réunion',
        meetingDate || new Date(),
        participants || '',
        content || '',
        JSON.stringify(actionItems || []),
        safeEventId
      ]
    );
    res.status(201).json({ meeting: insert.rows[0] });
  } catch (err) {
    console.error('Erreur create meeting:', err);
    res.status(500).json({ error: 'Erreur lors de la création de la réunion' });
  }
});

// Mettre à jour / Sauvegarde automatique d'une réunion
app.put('/api/meetings/:id', authMiddleware, async (req, res) => {
  const { title, meetingDate, participants, content, actionItems, calendarEventId } = req.body;
  const isValidUuid = (str) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);
  const targetId = isValidUuid(req.params.id) ? req.params.id : null;
  if (!targetId) {
    return res.status(400).json({ error: 'ID de réunion invalide' });
  }
  const safeEventId = isValidUuid(calendarEventId) ? calendarEventId : null;

  try {
    const update = await pool.query(
      `INSERT INTO meeting_notes (id, user_id, title, meeting_date, participants, content, action_items, calendar_event_id, updated_at)
       VALUES ($1, $2, $3, COALESCE($4, NOW()), $5, $6, $7, $8, NOW())
       ON CONFLICT (id) DO UPDATE SET
         title = EXCLUDED.title,
         meeting_date = EXCLUDED.meeting_date,
         participants = EXCLUDED.participants,
         content = EXCLUDED.content,
         action_items = EXCLUDED.action_items,
         calendar_event_id = EXCLUDED.calendar_event_id,
         updated_at = NOW()
       WHERE meeting_notes.user_id = $2
       RETURNING id, title, meeting_date, participants, content, action_items, calendar_event_id, created_at, updated_at`,
      [
        targetId,
        req.user.id,
        title || 'Réunion sans titre',
        meetingDate || new Date(),
        participants || '',
        content || '',
        JSON.stringify(actionItems || []),
        safeEventId
      ]
    );

    if (update.rows.length === 0) {
      return res.status(404).json({ error: 'Réunion introuvable' });
    }

    res.json({ meeting: update.rows[0] });
  } catch (err) {
    console.error('Erreur update meeting:', err);
    res.status(500).json({ error: 'Erreur lors de la sauvegarde de la réunion' });
  }
});

// Supprimer une réunion
app.delete('/api/meetings/:id', authMiddleware, async (req, res) => {
  try {
    const del = await pool.query(
      'DELETE FROM meeting_notes WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );
    if (del.rows.length === 0) {
      return res.status(404).json({ error: 'Réunion introuvable' });
    }
    res.json({ success: true, deletedId: req.params.id });
  } catch (err) {
    console.error('Erreur delete meeting:', err);
    res.status(500).json({ error: 'Erreur suppression réunion' });
  }
});

// Santé & Ping
app.get('/', (req, res) => {
  res.send('PrioStack Backend API is running');
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'PrioStack Neon Cloud API', time: new Date() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Serveur API PrioStack en écoute sur 0.0.0.0:${PORT}`);
});
