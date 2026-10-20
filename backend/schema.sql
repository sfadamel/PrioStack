-- ========================================================================
-- SCHEMA INITIAL PRIOSTACK POSTGRESQL (NEON.TECH)
-- Support Multi-utilisateurs, Rôles (Admin / User), Call Stack, Routines & Agenda
-- ========================================================================

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. TABLE UTILISATEURS & AUTHENTIFICATION
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user', -- 'admin' ou 'user'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index pour recherche rapide à l'authentification
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 2. TABLE TÂCHES (CALL STACK, URGENCES, DEEP WORK, ASSISTANCE, DÉLÉGUÉ)
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'deep_work', 'urgence', 'dev_block', 'delegated'
    status VARCHAR(50) NOT NULL DEFAULT 'backlog', -- 'backlog', 'active_base', 'pushed_pause', 'active_top', 'done'
    criticality INTEGER NOT NULL DEFAULT 2, -- 1: Normal, 2: Haute, 3: Critique
    external_ref VARCHAR(100), -- Ex: AB#1234
    requester_or_assignee VARCHAR(255),
    resume_note TEXT, -- Note de reprise mentale obligatoire
    stack_order INTEGER NOT NULL DEFAULT 0,
    elapsed_seconds INTEGER NOT NULL DEFAULT 0,
    interruption_count INTEGER NOT NULL DEFAULT 0,
    visibility VARCHAR(50) NOT NULL DEFAULT 'private',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_user_type ON tasks(user_id, type);

-- 3. TABLE MICRO-JALONS (30 MINUTES)
CREATE TABLE IF NOT EXISTS micro_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 30,
    is_done BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_milestones_task ON micro_milestones(task_id);

-- 4. TABLE MORNING CHECK-LIST (ROUTINE QUOTIDIENNE)
CREATE TABLE IF NOT EXISTS morning_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'Infra & Ops',
    is_checked BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    last_reset_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_checks_user ON morning_checks(user_id);

-- 5. TABLE ÉVÉNEMENTS DU CALENDRIER (RÉUNIONS, POINTS, CRÉNEAUX)
CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'meeting', 'team_sync', 'architecture', 'deadline'
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    participants_or_location TEXT,
    external_ref VARCHAR(100),
    notes TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    linked_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    visibility VARCHAR(50) NOT NULL DEFAULT 'team',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_events_user_date ON calendar_events(user_id, start_time);

-- 6. TABLE NOTES DE RÉUNION (AUTO-SAVE, ACTIONS & CONSULTATION)
CREATE TABLE IF NOT EXISTS meeting_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    meeting_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    participants TEXT DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    action_items JSONB DEFAULT '[]',
    calendar_event_id UUID REFERENCES calendar_events(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_meeting_notes_user ON meeting_notes(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_meeting_notes_calendar_event ON meeting_notes(calendar_event_id);
