import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection/connection.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

/// Constantes de contexte local V1 (prêtes pour l'authentification multi-tenant V2 Supabase)
const kDefaultUserId = 'usr_architect_01';
const kDefaultWorkspaceId = 'wks_damelit_arch';

/// Table principale des éléments PrioStack (Tâches de Fond, Urgences, Déblocages Devs, Délégués)
/// Conçue en "V2-Ready" (UUID v4 + métadonnées de synchronisation et multi-workspace)
@DataClassName('PrioTask')
class PrioTasks extends Table {
  /// Clé primaire UUID v4 (text)
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  // --- Champs obligatoires V2-Ready ("Sync-Ready") ---
  TextColumn get userId => text().withDefault(const Constant(kDefaultUserId))();
  TextColumn get workspaceId => text().withDefault(const Constant(kDefaultWorkspaceId))();
  TextColumn get visibility => text().withDefault(const Constant('private'))(); // 'private' | 'team'
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();   // 'local' | 'synced' | 'pending'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // --- Champs métier PrioStack ---
  TextColumn get title => text()();
  TextColumn get type => text()(); // 'urgence' | 'dev_block' | 'deep_work' | 'delegated'
  TextColumn get status => text().withDefault(const Constant('backlog'))(); // 'backlog' | 'active_base' | 'pushed_pause' | 'active_top' | 'done'
  IntColumn get criticality => integer().withDefault(const Constant(2))(); // 1: Normal, 2: Haute, 3: Critique
  TextColumn get externalRef => text().nullable()(); // Ex: "AB#4821" ou URL Azure DevOps
  TextColumn get requesterOrAssignee => text().nullable()(); // Nom du Dev (Déblocage) ou du collaborateur (Délégué)

  // --- Mécanique Call Stack (PUSH / POP) ---
  /// Note de reprise obligatoire saisie lors d'un PUSH d'interruption ("Où en étais-tu exactement ?")
  TextColumn get resumeNote => text().nullable()();

  /// Position dans la pile active (0 = Tâche de fond à la base, 1..N = Urgences empilées au-dessus)
  IntColumn get stackOrder => integer().withDefault(const Constant(0))();

  /// Temps cumulé passé en focus (en secondes)
  IntColumn get elapsedSeconds => integer().withDefault(const Constant(0))();

  /// Nombre de fois où cette tâche a subi un PUSH ou a été poussée
  IntColumn get interruptionCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des Micro-Jalons de 30 minutes rattachés à une Tâche de Fond (ou d'Urgence)
@DataClassName('MicroMilestone')
class MicroMilestones extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get taskId => text().references(PrioTasks, #id, onDelete: KeyAction.cascade)();

  // --- Champs obligatoires V2-Ready ---
  TextColumn get userId => text().withDefault(const Constant(kDefaultUserId))();
  TextColumn get workspaceId => text().withDefault(const Constant(kDefaultWorkspaceId))();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // --- Champs métier ---
  TextColumn get title => text()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(30))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table de la "Morning Check-list" (Zone 1 : Routine quotidienne de l'Architecte/Manager)
@DataClassName('MorningCheckItem')
class MorningCheckItems extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  // --- Champs obligatoires V2-Ready ---
  TextColumn get userId => text().withDefault(const Constant(kDefaultUserId))();
  TextColumn get workspaceId => text().withDefault(const Constant(kDefaultWorkspaceId))();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // --- Champs métier ---
  TextColumn get title => text()();
  TextColumn get category => text().withDefault(const Constant('Infra & Ops'))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastResetAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [PrioTasks, MicroMilestones, MorningCheckItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await seedRealisticInitialData();
        },
      );

  /// Jeu de données initial réaliste pour un Architecte Solution / Manager
  /// Permet de tester immédiatement tout le flux (Morning Check-list, Pile Active avec jalons 30m,
  /// Urgences critiques, Batch Déblocage Devs et Suivi Délégué).
  Future<void> seedRealisticInitialData() async {
    final now = DateTime.now();

    // 1. Seed de la Morning Check-list (Zone 1)
    final morningChecks = [
      MorningCheckItemsCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Contrôler les synchros DB & réplicas nocturnes',
        category: const Value('Data & DB'),
        isChecked: const Value(true),
        sortOrder: const Value(1),
        lastResetAt: Value(now),
      ),
      MorningCheckItemsCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Vérifier les alertes des workers Python / ETL',
        category: const Value('Workers Python'),
        isChecked: const Value(true),
        sortOrder: const Value(2),
        lastResetAt: Value(now),
      ),
      MorningCheckItemsCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Vérifier l\'Uptime API Gateway & latence P99',
        category: const Value('Monitoring'),
        isChecked: const Value(false),
        sortOrder: const Value(3),
        lastResetAt: Value(now),
      ),
      MorningCheckItemsCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Scanner les PR bloquantes dans Azure DevOps',
        category: const Value('Engineering'),
        isChecked: const Value(false),
        sortOrder: const Value(4),
        lastResetAt: Value(now),
      ),
      MorningCheckItemsCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Verrouiller le créneau Sanctuaire Architecture (90 min)',
        category: const Value('Focus'),
        isChecked: const Value(false),
        sortOrder: const Value(5),
        lastResetAt: Value(now),
      ),
    ];

    for (final check in morningChecks) {
      await into(morningCheckItems).insert(check);
    }

    // 2. Seed de la Tâche de Fond Active à la base de la Pile (Zone 2 - WIP = 1)
    final activeDeepWorkId = _uuid.v4();
    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(activeDeepWorkId),
        title: 'Architecture Sync Engine V2 (Outbox Pattern + Résolution Conflits UUID)',
        type: 'deep_work',
        status: const Value('active_base'),
        criticality: const Value(2),
        externalRef: const Value('AB#8412'),
        requesterOrAssignee: const Value('Architecture Core'),
        resumeNote: const Value(
          'Reprise après call prod : je finalisais le diagramme de séquence du trigger SQLite -> table sync_outbox (étape 3).',
        ),
        stackOrder: const Value(0),
        elapsedSeconds: const Value(3420), // 57 min déjà investies
        interruptionCount: const Value(2),
        visibility: const Value('team'),
        syncStatus: const Value('local'),
      ),
    );

    // Micro-jalons de 30 min pour la Tâche de Fond Active
    final milestones = [
      ('Spécifier le schéma Drift V2-Ready (UUIDv4, syncStatus, deletedAt)', true, 1),
      ('Définir la stratégie Last-Write-Wins & horodatage logique', true, 2),
      ('Modéliser le contrat d\'API REST / Supabase RPC pour le batch push', false, 3),
      ('Rédiger l\'ADR-014 (Architecture Decision Record) & revue Sécurité', false, 4),
    ];

    for (final (title, isDone, order) in milestones) {
      await into(microMilestones).insert(
        MicroMilestonesCompanion.insert(
          id: Value(_uuid.v4()),
          taskId: activeDeepWorkId,
          title: title,
          durationMinutes: const Value(30),
          isDone: Value(isDone),
          sortOrder: Value(order),
        ),
      );
    }

    // Une seconde tâche de fond en réserve (Backlog) pour tester le changement de tâche de fond
    final backlogDeepWorkId = _uuid.v4();
    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(backlogDeepWorkId),
        title: 'Audit de performance du pipeline d\'ingestion Kafka / EventHub',
        type: 'deep_work',
        status: const Value('backlog'),
        criticality: const Value(2),
        externalRef: const Value('AB#8390'),
        requesterOrAssignee: const Value('Data Platform'),
        elapsedSeconds: const Value(900),
      ),
    );
    await into(microMilestones).insert(
      MicroMilestonesCompanion.insert(
        id: Value(_uuid.v4()),
        taskId: backlogDeepWorkId,
        title: 'Analyser les métriques de consumer lag sur les 7 derniers jours',
        durationMinutes: const Value(30),
        isDone: const Value(false),
        sortOrder: const Value(1),
      ),
    );

    // 3. Seed des Urgences (Zone 3 - Onglet 🔥 Urgences)
    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Deadlock SQL sur le microservice Facturation en pré-prod',
        type: 'urgence',
        status: const Value('backlog'),
        criticality: const Value(3),
        externalRef: const Value('AB#8904'),
        requesterOrAssignee: const Value('Alerte APM / SRE'),
        elapsedSeconds: const Value(600),
        interruptionCount: const Value(1),
      ),
    );

    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Expiration certificat OAuth2 sur le tenant SSO Partenaires',
        type: 'urgence',
        status: const Value('backlog'),
        criticality: const Value(3),
        externalRef: const Value('AB#8911'),
        requesterOrAssignee: const Value('SecOps'),
        elapsedSeconds: const Value(420),
      ),
    );

    // 4. Seed du Batch Déblocage Devs (Zone 3 - Onglet 🧑‍💻 Déblocage Devs)
    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Validation du découpage DTO entre Domain et Infrastructure',
        type: 'dev_block',
        status: const Value('backlog'),
        criticality: const Value(2),
        externalRef: const Value('AB#8740'),
        requesterOrAssignee: const Value('Lucas M. (Senior Backend)'),
        elapsedSeconds: const Value(300),
      ),
    );

    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Question sur la politique de retry idempotent du webhook Stripe',
        type: 'dev_block',
        status: const Value('backlog'),
        criticality: const Value(2),
        externalRef: const Value('AB#8792'),
        requesterOrAssignee: const Value('Sarah K. (Fullstack)'),
      ),
    );

    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Arbitrage d\'index composite PostgreSQL sur la table audit_logs',
        type: 'dev_block',
        status: const Value('backlog'),
        criticality: const Value(1),
        externalRef: const Value('AB#8801'),
        requesterOrAssignee: const Value('Yassine B. (Data Eng)'),
      ),
    );

    // 5. Seed des tâches Déléguées / En attente (Zone 3 - Onglet 📤 Délégué)
    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Benchmark de charge k6 sur le nouveau cluster AKS',
        type: 'delegated',
        status: const Value('backlog'),
        criticality: const Value(2),
        externalRef: const Value('AB#8655'),
        requesterOrAssignee: const Value('Thomas R. (DevOps)'),
        visibility: const Value('team'),
      ),
    );

    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Mise à jour du contrat OpenAPI 3.1 pour l\'équipe Mobile',
        type: 'delegated',
        status: const Value('backlog'),
        criticality: const Value(1),
        externalRef: const Value('AB#8699'),
        requesterOrAssignee: const Value('Clara V. (Tech Lead)'),
        visibility: const Value('team'),
      ),
    );

    // 6. Seed d'éléments déjà terminés (Historique / Backlog Fait)
    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Migration du pool de connexions PgBouncer en mode Transaction',
        type: 'deep_work',
        status: const Value('done'),
        criticality: const Value(2),
        externalRef: const Value('AB#8210'),
        requesterOrAssignee: const Value('Architecture Core'),
        elapsedSeconds: const Value(2700),
      ),
    );

    await into(prioTasks).insert(
      PrioTasksCompanion.insert(
        id: Value(_uuid.v4()),
        title: 'Hotfix timeout Redis sur le cache de session Auth',
        type: 'urgence',
        status: const Value('done'),
        criticality: const Value(3),
        externalRef: const Value('AB#8890'),
        requesterOrAssignee: const Value('Alerte SRE'),
        elapsedSeconds: const Value(900),
        interruptionCount: const Value(1),
      ),
    );
  }
}

QueryExecutor _openConnection() => openDriftConnection();
