import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../domain/models/calendar_event.dart';
import '../../../domain/models/task_enums.dart';
import '../../../domain/repositories/task_repository.dart';
import '../drift/app_database.dart';

import 'web_storage_helper.dart';

/// Implémentation réactive en mémoire du contrat TaskRepository avec persistance localStorage pour le Web / PWA.
/// Permet d'exécuter PrioStack dans n'importe quel navigateur (Edge, Chrome, Citrix) avec persistance
/// locale intégrale sans serveur backend ni exécutable non signé.
class InMemoryTaskRepository implements TaskRepository {
  final Uuid _uuid = const Uuid();
  final List<PrioTask> _tasks = [];
  final List<MicroMilestone> _milestones = [];
  final List<MorningCheckItem> _morningChecks = [];
  final List<CalendarEventItem> _calendarEvents = [];

  final _changeController = StreamController<void>.broadcast();

  InMemoryTaskRepository() {
    _loadOrSeedData();
  }

  void _loadOrSeedData() {
    final savedTasks = WebStorageHelper.loadTasks();
    final savedMilestones = WebStorageHelper.loadMilestones();
    final savedChecks = WebStorageHelper.loadMorningChecks();
    final savedEvents = WebStorageHelper.loadCalendarEvents();

    if (savedTasks != null && savedTasks.isNotEmpty) {
      _tasks.addAll(savedTasks);
      if (savedMilestones != null) _milestones.addAll(savedMilestones);
      if (savedChecks != null) _morningChecks.addAll(savedChecks);
      if (savedEvents != null) _calendarEvents.addAll(savedEvents);
    } else {
      _seedInitialData();
      _saveToLocalStorage();
    }
  }

  void _saveToLocalStorage() {
    WebStorageHelper.saveAll(
      tasks: _tasks,
      milestones: _milestones,
      morningChecks: _morningChecks,
      calendarEvents: _calendarEvents,
    );
  }

  Stream<T> _reactiveStream<T>(T Function() compute) async* {
    yield compute();
    await for (final _ in _changeController.stream) {
      yield compute();
    }
  }

  void _notify() {
    _saveToLocalStorage();
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  void _seedInitialData() {
    final now = DateTime.now();

    // 1. Morning Check-list
    final checks = [
      ('Contrôler les synchros DB & réplicas nocturnes', 'Data & DB', true, 1),
      ('Vérifier les alertes des workers Python / ETL', 'Workers Python', true, 2),
      ('Vérifier l\'Uptime API Gateway & latence P99', 'Monitoring', false, 3),
      ('Scanner les PR bloquantes dans Azure DevOps', 'Engineering', false, 4),
      ('Verrouiller le créneau Sanctuaire Architecture (90 min)', 'Focus', false, 5),
    ];
    for (final (title, cat, checked, order) in checks) {
      _morningChecks.add(
        MorningCheckItem(
          id: _uuid.v4(),
          userId: kDefaultUserId,
          workspaceId: kDefaultWorkspaceId,
          visibility: 'private',
          syncStatus: 'local',
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          title: title,
          category: cat,
          isChecked: checked,
          sortOrder: order,
          lastResetAt: now,
        ),
      );
    }

    // 2. Tâche de Fond Active à la base de la Pile (WIP = 1)
    final activeDeepWorkId = _uuid.v4();
    _tasks.add(
      PrioTask(
        id: activeDeepWorkId,
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'team',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Architecture Sync Engine V2 (Outbox Pattern + Résolution Conflits UUID)',
        type: 'deep_work',
        status: 'active_base',
        criticality: 2,
        externalRef: 'AB#8412',
        requesterOrAssignee: 'Architecture Core',
        resumeNote:
            'Reprise après call prod : je finalisais le diagramme de séquence du trigger SQLite -> table sync_outbox (étape 3).',
        stackOrder: 0,
        elapsedSeconds: 3420,
        interruptionCount: 2,
      ),
    );

    final milestones = [
      ('Spécifier le schéma Drift V2-Ready (UUIDv4, syncStatus, deletedAt)', true, 1),
      ('Définir la stratégie Last-Write-Wins & horodatage logique', true, 2),
      ('Modéliser le contrat d\'API REST / Supabase RPC pour le batch push', false, 3),
      ('Rédiger l\'ADR-014 (Architecture Decision Record) & revue Sécurité', false, 4),
    ];
    for (final (title, isDone, order) in milestones) {
      _milestones.add(
        MicroMilestone(
          id: _uuid.v4(),
          taskId: activeDeepWorkId,
          userId: kDefaultUserId,
          workspaceId: kDefaultWorkspaceId,
          visibility: 'private',
          syncStatus: 'local',
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          title: title,
          durationMinutes: 30,
          isDone: isDone,
          sortOrder: order,
        ),
      );
    }

    // Seconde tâche de fond en réserve (Backlog)
    final backlogDeepWorkId = _uuid.v4();
    _tasks.add(
      PrioTask(
        id: backlogDeepWorkId,
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Audit de performance du pipeline d\'ingestion Kafka / EventHub',
        type: 'deep_work',
        status: 'backlog',
        criticality: 2,
        externalRef: 'AB#8390',
        requesterOrAssignee: 'Data Platform',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 900,
        interruptionCount: 0,
      ),
    );

    // 3. Urgences
    _tasks.addAll([
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Deadlock SQL sur le microservice Facturation en pré-prod',
        type: 'urgence',
        status: 'backlog',
        criticality: 3,
        externalRef: 'AB#8904',
        requesterOrAssignee: 'Alerte APM / SRE',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 600,
        interruptionCount: 1,
      ),
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Expiration certificat OAuth2 sur le tenant SSO Partenaires',
        type: 'urgence',
        status: 'backlog',
        criticality: 3,
        externalRef: 'AB#8911',
        requesterOrAssignee: 'SecOps',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 420,
        interruptionCount: 0,
      ),
    ]);

    // 4. Batch Déblocage Devs
    _tasks.addAll([
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Validation du découpage DTO entre Domain et Infrastructure',
        type: 'dev_block',
        status: 'backlog',
        criticality: 2,
        externalRef: 'AB#8740',
        requesterOrAssignee: 'Lucas M. (Senior Backend)',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 300,
        interruptionCount: 0,
      ),
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Question sur la politique de retry idempotent du webhook Stripe',
        type: 'dev_block',
        status: 'backlog',
        criticality: 2,
        externalRef: 'AB#8792',
        requesterOrAssignee: 'Sarah K. (Fullstack)',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 0,
        interruptionCount: 0,
      ),
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Arbitrage d\'index composite PostgreSQL sur la table audit_logs',
        type: 'dev_block',
        status: 'backlog',
        criticality: 1,
        externalRef: 'AB#8801',
        requesterOrAssignee: 'Yassine B. (Data Eng)',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 0,
        interruptionCount: 0,
      ),
    ]);

    // 5. Délégué / Suivi
    _tasks.addAll([
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'team',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Benchmark de charge k6 sur le nouveau cluster AKS',
        type: 'delegated',
        status: 'backlog',
        criticality: 2,
        externalRef: 'AB#8655',
        requesterOrAssignee: 'Thomas R. (DevOps)',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 0,
        interruptionCount: 0,
      ),
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'team',
        syncStatus: 'local',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: 'Mise à jour du contrat OpenAPI 3.1 pour l\'équipe Mobile',
        type: 'delegated',
        status: 'backlog',
        criticality: 1,
        externalRef: 'AB#8699',
        requesterOrAssignee: 'Clara V. (Tech Lead)',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 0,
        interruptionCount: 0,
      ),
    ]);

    // 6. Éléments déjà terminés (Historique / Backlog Fait)
    _tasks.addAll([
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'team',
        syncStatus: 'local',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        deletedAt: null,
        title: 'Migration du pool de connexions PgBouncer en mode Transaction',
        type: 'deep_work',
        status: 'done',
        criticality: 2,
        externalRef: 'AB#8210',
        requesterOrAssignee: 'Architecture Core',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 2700,
        interruptionCount: 0,
      ),
      PrioTask(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: 'local',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        deletedAt: null,
        title: 'Hotfix timeout Redis sur le cache de session Auth',
        type: 'urgence',
        status: 'done',
        criticality: 3,
        externalRef: 'AB#8890',
        requesterOrAssignee: 'Alerte SRE',
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 900,
        interruptionCount: 1,
      ),
    ]);

    // 7. Événements du Calendrier & Réunions (Aujourd'hui + Semaine / Mois)
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final inTwoDays = today.add(const Duration(days: 2));
    final yesterday = today.subtract(const Duration(days: 1));
    final inFiveDays = today.add(const Duration(days: 5));

    // Créneau tout juste dépassé (fin il y a 10 min) pour démontrer la clôture automatique + notification
    final justEndedStart = now.subtract(const Duration(minutes: 55));
    final justEndedEnd = now.subtract(const Duration(minutes: 10));

    // Prochaine réunion imminente (début dans 10 min) pour démontrer l'alerte de réunion imminente
    final nextMeetingStart = now.add(const Duration(minutes: 10));
    final nextMeetingEnd = now.add(const Duration(minutes: 55));

    // Second créneau à venir aujourd'hui (début dans 1h15)
    final laterStart = now.add(const Duration(minutes: 75));
    final laterEnd = now.add(const Duration(minutes: 135));

    _calendarEvents.addAll([
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Daily Standup & Triage Architecture',
        category: CalendarEventCategory.teamSync,
        startTime: today.add(const Duration(hours: 9, minutes: 30)),
        endTime: today.add(const Duration(hours: 10, minutes: 0)),
        participantsOrLocation: 'Teams • Équipe Core & Tech Leads',
        externalRef: 'AB#8400',
        notes: 'Point quotidien sur les blocages et priorités de la Pile Active.',
        isCompleted: true,
      ),
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Revue Hebdo Dette Technique & Deadlocks SQL',
        category: CalendarEventCategory.meeting,
        startTime: justEndedStart,
        endTime: justEndedEnd,
        participantsOrLocation: 'Salle Atlas / Teams • Lucas M., Yassine B.',
        externalRef: 'AB#8904',
        notes: 'Analyse des plans d\'exécution PostgreSQL et verrous transactionnels.',
        isCompleted: false, // Sera clôturée automatiquement car l'heure de fin est dépassée !
      ),
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Comité Architecture : Validation ADR-014 Sync V2',
        category: CalendarEventCategory.meeting,
        startTime: nextMeetingStart,
        endTime: nextMeetingEnd,
        participantsOrLocation: 'Teams • CTO, SecOps, Lead Data',
        externalRef: 'AB#8412',
        notes: 'Arbitrage final sur le pattern Outbox SQLite -> Supabase PostgreSQL.',
        isCompleted: false,
      ),
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Sanctuaire Deep Work : Modélisation Contrat RPC V2',
        category: CalendarEventCategory.architecture,
        startTime: laterStart,
        endTime: laterEnd,
        participantsOrLocation: 'Focus Individuel (Ne pas déranger)',
        externalRef: 'AB#8412',
        notes: 'Créneau protégé sans interruption pour avancer sur la Tâche de Fond.',
        isCompleted: false,
      ),
      // Demain
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Audit Sécurité : Rotation Certificats OAuth2 SSO Partenaires',
        category: CalendarEventCategory.meeting,
        startTime: tomorrow.add(const Duration(hours: 10, minutes: 0)),
        endTime: tomorrow.add(const Duration(hours: 11, minutes: 0)),
        participantsOrLocation: 'Teams • Équipe SecOps & IAM',
        externalRef: 'AB#8911',
        notes: 'Validation de la procédure de bascule sans coupure de service.',
        isCompleted: false,
      ),
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Go / No-Go Mise en Production Release 2.4',
        category: CalendarEventCategory.deadline,
        startTime: tomorrow.add(const Duration(hours: 15, minutes: 0)),
        endTime: tomorrow.add(const Duration(hours: 16, minutes: 0)),
        participantsOrLocation: 'Comité Release • Direction Technique',
        externalRef: 'AB#8950',
        notes: 'Vérification des résultats du benchmark k6 sur le cluster AKS.',
        isCompleted: false,
      ),
      // Autres jours du mois
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Atelier Event-Driven Architecture (Kafka / EventHub)',
        category: CalendarEventCategory.architecture,
        startTime: inTwoDays.add(const Duration(hours: 14, minutes: 0)),
        endTime: inTwoDays.add(const Duration(hours: 16, minutes: 0)),
        participantsOrLocation: 'Salle Orion • Data Platform',
        externalRef: 'AB#8390',
        notes: 'Dimensionnement des partitions et gestion de la Dead-Letter Queue.',
        isCompleted: false,
      ),
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Point Mensuel FinOps & Coûts Cloud Azure',
        category: CalendarEventCategory.teamSync,
        startTime: yesterday.add(const Duration(hours: 11, minutes: 0)),
        endTime: yesterday.add(const Duration(hours: 12, minutes: 0)),
        participantsOrLocation: 'Teams • Thomas R. (DevOps)',
        externalRef: 'AB#8655',
        notes: 'Optimisation des réservations d\'instances AKS et stockage.',
        isCompleted: true,
      ),
      CalendarEventItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        createdAt: now,
        updatedAt: now,
        title: 'Livraison Contrat OpenAPI 3.1 Mobile',
        category: CalendarEventCategory.deadline,
        startTime: inFiveDays.add(const Duration(hours: 17, minutes: 0)),
        endTime: inFiveDays.add(const Duration(hours: 18, minutes: 0)),
        participantsOrLocation: 'Clara V. (Tech Lead Mobile)',
        externalRef: 'AB#8699',
        notes: 'Validation finale des schémas JSON et pagination.',
        isCompleted: false,
      ),
    ]);
  }

  List<TaskWithMilestones> _withMilestones(List<PrioTask> list) {
    return list.map((t) {
      final m = _milestones
          .where((ms) => ms.deletedAt == null && ms.taskId == t.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return TaskWithMilestones(task: t, milestones: m);
    }).toList();
  }

  @override
  Stream<List<MorningCheckItem>> watchMorningChecks() {
    return _reactiveStream(() {
      final list = _morningChecks.where((c) => c.deletedAt == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  @override
  Stream<List<TaskWithMilestones>> watchActiveStack() {
    return _reactiveStream(() {
      final activeStatuses = {
        TaskStackStatus.activeTop.dbValue,
        TaskStackStatus.pushedPause.dbValue,
        TaskStackStatus.activeBase.dbValue,
      };
      final list = _tasks
          .where((t) => t.deletedAt == null && activeStatuses.contains(t.status))
          .toList()
        ..sort((a, b) => b.stackOrder.compareTo(a.stackOrder));
      return _withMilestones(list);
    });
  }

  @override
  Stream<List<TaskWithMilestones>> watchTriageTasksByType(TaskType type) {
    return _reactiveStream(() {
      final list = _tasks
          .where((t) =>
              t.deletedAt == null &&
              t.type == type.dbValue &&
              t.status == TaskStackStatus.backlog.dbValue)
          .toList()
        ..sort((a, b) {
          final orderCmp = a.stackOrder.compareTo(b.stackOrder);
          if (orderCmp != 0) return orderCmp;
          return b.criticality.compareTo(a.criticality);
        });
      return _withMilestones(list);
    });
  }

  @override
  Stream<List<TaskWithMilestones>> watchBacklogDeepWork() {
    return _reactiveStream(() {
      final list = _tasks
          .where((t) =>
              t.deletedAt == null &&
              t.type == TaskType.deepWork.dbValue &&
              t.status == TaskStackStatus.backlog.dbValue)
          .toList()
        ..sort((a, b) {
          final orderCmp = a.stackOrder.compareTo(b.stackOrder);
          if (orderCmp != 0) return orderCmp;
          return b.criticality.compareTo(a.criticality);
        });
      return _withMilestones(list);
    });
  }

  @override
  Stream<StackMetrics> watchStackMetrics() {
    return _reactiveStream(() {
      int deepWorkSec = 0;
      int interruptionSec = 0;
      int pushCount = 0;
      for (final t in _tasks.where((t) => t.deletedAt == null)) {
        pushCount += t.interruptionCount;
        if (t.type == TaskType.deepWork.dbValue) {
          deepWorkSec += t.elapsedSeconds;
        } else {
          interruptionSec += t.elapsedSeconds;
        }
      }
      return StackMetrics(
        deepWorkSeconds: deepWorkSec,
        interruptionSeconds: interruptionSec,
        pushCountToday: pushCount,
      );
    });
  }

  @override
  Future<String> quickCaptureTask({
    required String title,
    required TaskType type,
    String? externalRef,
    String? requesterOrAssignee,
    int criticality = 2,
    VisibilityScope visibility = VisibilityScope.privateScope,
    List<String> initialMilestones = const [],
  }) async {
    final newId = _uuid.v4();
    final now = DateTime.now();

    String initialStatus = TaskStackStatus.backlog.dbValue;
    if (type == TaskType.deepWork) {
      final hasActiveBase = _tasks.any((t) =>
          t.deletedAt == null &&
          (t.status == TaskStackStatus.activeBase.dbValue ||
              t.status == TaskStackStatus.pushedPause.dbValue));
      if (!hasActiveBase) {
        initialStatus = TaskStackStatus.activeBase.dbValue;
      }
    }

    _tasks.insert(
      0,
      PrioTask(
        id: newId,
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: visibility.dbValue,
        syncStatus: SyncStatus.pending.dbValue,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: title.trim(),
        type: type.dbValue,
        status: initialStatus,
        criticality: criticality,
        externalRef: externalRef != null && externalRef.trim().isNotEmpty
            ? externalRef.trim()
            : null,
        requesterOrAssignee:
            requesterOrAssignee != null && requesterOrAssignee.trim().isNotEmpty
                ? requesterOrAssignee.trim()
                : null,
        resumeNote: null,
        stackOrder: 0,
        elapsedSeconds: 0,
        interruptionCount: 0,
      ),
    );

    final milestonesToCreate = initialMilestones.isNotEmpty
        ? initialMilestones
        : (type == TaskType.deepWork
            ? [
                'Cadrage technique & revue d\'impact (30m)',
                'Exécution / livrable principal (30m)',
              ]
            : <String>[]);

    for (int i = 0; i < milestonesToCreate.length; i++) {
      _milestones.add(
        MicroMilestone(
          id: _uuid.v4(),
          taskId: newId,
          userId: kDefaultUserId,
          workspaceId: kDefaultWorkspaceId,
          visibility: 'private',
          syncStatus: SyncStatus.pending.dbValue,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          title: milestonesToCreate[i],
          durationMinutes: 30,
          isDone: false,
          sortOrder: i + 1,
        ),
      );
    }

    _notify();
    return newId;
  }

  @override
  Future<void> toggleMorningCheck(String id, bool isChecked) async {
    final idx = _morningChecks.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _morningChecks[idx] = _morningChecks[idx].copyWith(
        isChecked: isChecked,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> resetMorningChecklist() async {
    final now = DateTime.now();
    for (int i = 0; i < _morningChecks.length; i++) {
      _morningChecks[i] = _morningChecks[i].copyWith(
        isChecked: false,
        updatedAt: now,
      );
    }
    _notify();
  }

  @override
  Future<void> addMorningCheckItem(String title, String category) async {
    final now = DateTime.now();
    _morningChecks.add(
      MorningCheckItem(
        id: _uuid.v4(),
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: SyncStatus.pending.dbValue,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: title.trim(),
        category: category.trim().isEmpty ? 'Routine' : category.trim(),
        isChecked: false,
        sortOrder: _morningChecks.length + 1,
        lastResetAt: now,
      ),
    );
    _notify();
  }

  @override
  Future<void> activateDeepWorkTask(String taskId) async {
    final now = DateTime.now();
    final hasActiveUrgency = _tasks.any(
        (t) => t.deletedAt == null && t.status == TaskStackStatus.activeTop.dbValue);

    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.type == TaskType.deepWork.dbValue &&
          (t.status == TaskStackStatus.activeBase.dbValue ||
              t.status == TaskStackStatus.pushedPause.dbValue)) {
        _tasks[i] = t.copyWith(
          status: TaskStackStatus.backlog.dbValue,
          stackOrder: 0,
          updatedAt: now,
        );
      }
    }

    final targetIdx = _tasks.indexWhere((t) => t.id == taskId);
    if (targetIdx != -1) {
      _tasks[targetIdx] = _tasks[targetIdx].copyWith(
        status: hasActiveUrgency
            ? TaskStackStatus.pushedPause.dbValue
            : TaskStackStatus.activeBase.dbValue,
        stackOrder: 0,
        updatedAt: now,
      );
    }
    _notify();
  }

  @override
  Future<void> addMicroMilestone(String taskId, String title,
      {int durationMinutes = 30}) async {
    final now = DateTime.now();
    final count = _milestones.where((m) => m.taskId == taskId).length;
    _milestones.add(
      MicroMilestone(
        id: _uuid.v4(),
        taskId: taskId,
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'private',
        syncStatus: SyncStatus.pending.dbValue,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        title: title.trim(),
        durationMinutes: durationMinutes,
        isDone: false,
        sortOrder: count + 1,
      ),
    );
    _notify();
  }

  @override
  Future<void> updateMicroMilestone(
    String milestoneId, {
    String? title,
    int? durationMinutes,
  }) async {
    final idx = _milestones.indexWhere((m) => m.id == milestoneId);
    if (idx != -1) {
      _milestones[idx] = _milestones[idx].copyWith(
        title: title?.trim() ?? _milestones[idx].title,
        durationMinutes: durationMinutes ?? _milestones[idx].durationMinutes,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> toggleMicroMilestone(String milestoneId, bool isDone) async {
    final idx = _milestones.indexWhere((m) => m.id == milestoneId);
    if (idx != -1) {
      _milestones[idx] = _milestones[idx].copyWith(
        isDone: isDone,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> recordFocusTick(String taskId, int totalElapsedSeconds, {bool notify = false}) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        elapsedSeconds: totalElapsedSeconds,
        updatedAt: DateTime.now(),
      );
      if (notify) {
        _notify();
      }
    }
  }

  @override
  Future<void> pushInterruption({
    required String resumeNote,
    String? existingUrgencyTaskId,
    String? newUrgencyTitle,
    String? externalRef,
    int criticality = 3,
  }) async {
    final now = DateTime.now();
    final activeStatuses = {
      TaskStackStatus.activeTop.dbValue,
      TaskStackStatus.activeBase.dbValue,
      TaskStackStatus.pushedPause.dbValue,
    };

    final stackTasks = _tasks
        .where((t) => t.deletedAt == null && activeStatuses.contains(t.status))
        .toList()
      ..sort((a, b) => b.stackOrder.compareTo(a.stackOrder));

    int maxOrder = 0;
    for (final t in stackTasks) {
      if (t.stackOrder > maxOrder) maxOrder = t.stackOrder;
    }

    if (stackTasks.isNotEmpty) {
      final topId = stackTasks.first.id;
      final trimmedResume = resumeNote.trim();
      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].id == topId) {
          _tasks[i] = PrioTask(
            id: _tasks[i].id,
            userId: _tasks[i].userId,
            workspaceId: _tasks[i].workspaceId,
            visibility: _tasks[i].visibility,
            syncStatus: SyncStatus.pending.dbValue,
            createdAt: _tasks[i].createdAt,
            updatedAt: now,
            deletedAt: _tasks[i].deletedAt,
            title: _tasks[i].title,
            type: _tasks[i].type,
            status: TaskStackStatus.pushedPause.dbValue,
            criticality: _tasks[i].criticality,
            externalRef: _tasks[i].externalRef,
            requesterOrAssignee: _tasks[i].requesterOrAssignee,
            resumeNote: trimmedResume.isEmpty ? null : trimmedResume,
            stackOrder: _tasks[i].stackOrder,
            elapsedSeconds: _tasks[i].elapsedSeconds,
            interruptionCount: _tasks[i].interruptionCount + 1,
          );
        } else if (activeStatuses.contains(_tasks[i].status)) {
          _tasks[i] = _tasks[i].copyWith(
            status: TaskStackStatus.pushedPause.dbValue,
            updatedAt: now,
          );
        }
      }
    }

    final nextOrder = maxOrder + 1;
    if (existingUrgencyTaskId != null) {
      final idx = _tasks.indexWhere((t) => t.id == existingUrgencyTaskId);
      if (idx != -1) {
        _tasks[idx] = _tasks[idx].copyWith(
          status: TaskStackStatus.activeTop.dbValue,
          stackOrder: nextOrder,
          updatedAt: now,
        );
      }
    } else if (newUrgencyTitle != null && newUrgencyTitle.trim().isNotEmpty) {
      _tasks.add(
        PrioTask(
          id: _uuid.v4(),
          userId: kDefaultUserId,
          workspaceId: kDefaultWorkspaceId,
          visibility: 'private',
          syncStatus: SyncStatus.pending.dbValue,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          title: newUrgencyTitle.trim(),
          type: TaskType.urgence.dbValue,
          status: TaskStackStatus.activeTop.dbValue,
          criticality: criticality,
          externalRef: externalRef != null && externalRef.trim().isNotEmpty
              ? externalRef.trim()
              : null,
          requesterOrAssignee: 'Urgence Directe',
          resumeNote: null,
          stackOrder: nextOrder,
          elapsedSeconds: 0,
          interruptionCount: 1,
        ),
      );
    }
    _notify();
  }

  @override
  Future<void> popActiveTopTask(String topTaskId) async {
    final now = DateTime.now();
    final idx = _tasks.indexWhere((t) => t.id == topTaskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        status: TaskStackStatus.done.dbValue,
        stackOrder: 0,
        updatedAt: now,
      );
    }

    final paused = _tasks
        .where((t) =>
            t.deletedAt == null &&
            t.status == TaskStackStatus.pushedPause.dbValue)
        .toList()
      ..sort((a, b) => b.stackOrder.compareTo(a.stackOrder));

    if (paused.isNotEmpty) {
      final next = paused.first;
      final isBaseDeepWork =
          next.type == TaskType.deepWork.dbValue && paused.length == 1;
      final resumeIdx = _tasks.indexWhere((t) => t.id == next.id);
      if (resumeIdx != -1) {
        _tasks[resumeIdx] = _tasks[resumeIdx].copyWith(
          status: isBaseDeepWork
              ? TaskStackStatus.activeBase.dbValue
              : TaskStackStatus.activeTop.dbValue,
          updatedAt: now,
        );
      }
    }
    _notify();
  }

  @override
  Future<void> acknowledgeResumeNote(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final t = _tasks[idx];
      _tasks[idx] = PrioTask(
        id: t.id,
        userId: t.userId,
        workspaceId: t.workspaceId,
        visibility: t.visibility,
        syncStatus: SyncStatus.pending.dbValue,
        createdAt: t.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: t.deletedAt,
        title: t.title,
        type: t.type,
        status: t.status,
        criticality: t.criticality,
        externalRef: t.externalRef,
        requesterOrAssignee: t.requesterOrAssignee,
        resumeNote: null,
        stackOrder: t.stackOrder,
        elapsedSeconds: t.elapsedSeconds,
        interruptionCount: t.interruptionCount,
      );
      _notify();
    }
  }

  @override
  Future<void> delegateTask(String taskId, String assigneeName) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final t = _tasks[idx];
      _tasks[idx] = PrioTask(
        id: t.id,
        userId: t.userId,
        workspaceId: t.workspaceId,
        visibility: VisibilityScope.team.dbValue,
        syncStatus: SyncStatus.pending.dbValue,
        createdAt: t.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: t.deletedAt,
        title: t.title,
        type: TaskType.delegated.dbValue,
        status: TaskStackStatus.backlog.dbValue,
        criticality: t.criticality,
        externalRef: t.externalRef,
        requesterOrAssignee: assigneeName.trim(),
        resumeNote: t.resumeNote,
        stackOrder: t.stackOrder,
        elapsedSeconds: t.elapsedSeconds,
        interruptionCount: t.interruptionCount,
      );
      _notify();
    }
  }

  @override
  Stream<List<TaskWithMilestones>> watchCompletedTasks() {
    return _reactiveStream(() {
      final list = _tasks
          .where((t) =>
              t.deletedAt == null && t.status == TaskStackStatus.done.dbValue)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return _withMilestones(list);
    });
  }

  @override
  Future<void> completeTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        status: TaskStackStatus.done.dbValue,
        stackOrder: 0,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> reactivateTask(String taskId, {bool placeInActiveStack = false}) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];

    if (placeInActiveStack) {
      if (task.type == TaskType.deepWork.dbValue) {
        await activateDeepWorkTask(taskId);
        return;
      } else {
        await pushInterruption(
          resumeNote: 'Réactivation directe depuis le Backlog des tâches terminées.',
          existingUrgencyTaskId: taskId,
        );
        return;
      }
    }

    String targetStatus = TaskStackStatus.backlog.dbValue;
    if (task.type == TaskType.deepWork.dbValue) {
      final hasActiveBase = _tasks.any((t) =>
          t.deletedAt == null &&
          (t.status == TaskStackStatus.activeBase.dbValue ||
              t.status == TaskStackStatus.pushedPause.dbValue));
      if (!hasActiveBase) {
        targetStatus = TaskStackStatus.activeBase.dbValue;
      }
    }

    _tasks[idx] = task.copyWith(
      status: targetStatus,
      stackOrder: 0,
      updatedAt: DateTime.now(),
    );
    _notify();
  }

  @override
  Future<void> updateMorningCheckItem(String id, String title, String category) async {
    final idx = _morningChecks.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _morningChecks[idx] = _morningChecks[idx].copyWith(
        title: title.trim(),
        category: category.trim(),
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteMorningCheckItem(String id) async {
    _morningChecks.removeWhere((c) => c.id == id);
    _notify();
  }

  @override
  Future<void> deleteMicroMilestone(String milestoneId) async {
    _milestones.removeWhere((m) => m.id == milestoneId);
    _notify();
  }

  @override
  Future<void> updateTask(
    String taskId, {
    String? title,
    String? externalRef,
    String? requesterOrAssignee,
    int? criticality,
    String? type,
  }) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        title: title != null ? title.trim() : _tasks[idx].title,
        externalRef: externalRef != null ? Value(externalRef.trim()) : Value(_tasks[idx].externalRef),
        requesterOrAssignee: requesterOrAssignee != null ? Value(requesterOrAssignee.trim()) : Value(_tasks[idx].requesterOrAssignee),
        criticality: criticality ?? _tasks[idx].criticality,
        type: type ?? _tasks[idx].type,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    _milestones.removeWhere((m) => m.taskId == taskId);
    _notify();
  }

  @override
  Future<void> reorderMorningChecks(List<String> orderedIds) async {
    final now = DateTime.now();
    for (int i = 0; i < orderedIds.length; i++) {
      final idx = _morningChecks.indexWhere((c) => c.id == orderedIds[i]);
      if (idx != -1) {
        _morningChecks[idx] = _morningChecks[idx].copyWith(
          sortOrder: i + 1,
          updatedAt: now,
        );
      }
    }
    _notify();
  }

  @override
  Future<void> reorderMicroMilestones(
    String taskId,
    List<String> orderedMilestoneIds,
  ) async {
    final now = DateTime.now();
    for (int i = 0; i < orderedMilestoneIds.length; i++) {
      final idx = _milestones.indexWhere((m) => m.id == orderedMilestoneIds[i]);
      if (idx != -1) {
        _milestones[idx] = _milestones[idx].copyWith(
          sortOrder: i + 1,
          updatedAt: now,
        );
      }
    }
    _notify();
  }

  @override
  Future<void> reorderTasks(List<String> orderedTaskIds) async {
    final now = DateTime.now();
    for (int i = 0; i < orderedTaskIds.length; i++) {
      final idx = _tasks.indexWhere((t) => t.id == orderedTaskIds[i]);
      if (idx != -1) {
        _tasks[idx] = _tasks[idx].copyWith(
          stackOrder: i + 1,
          updatedAt: now,
        );
      }
    }
    _notify();
  }

  // --- CALENDRIER & AGENDA ---

  @override
  Stream<List<CalendarEventItem>> watchCalendarEvents() {
    return _reactiveStream(() {
      final list = _calendarEvents
          .where((e) => e.deletedAt == null)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  @override
  Future<String> addCalendarEvent({
    required String title,
    required CalendarEventCategory category,
    required DateTime startTime,
    required DateTime endTime,
    String? participantsOrLocation,
    String? externalRef,
    String? notes,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final validEnd = endTime.isAfter(startTime)
        ? endTime
        : startTime.add(const Duration(minutes: 45));

    _calendarEvents.add(
      CalendarEventItem(
        id: id,
        userId: kDefaultUserId,
        workspaceId: kDefaultWorkspaceId,
        visibility: 'team',
        syncStatus: SyncStatus.pending.dbValue,
        createdAt: now,
        updatedAt: now,
        title: title.trim(),
        category: category,
        startTime: startTime,
        endTime: validEnd,
        participantsOrLocation:
            participantsOrLocation != null && participantsOrLocation.trim().isNotEmpty
                ? participantsOrLocation.trim()
                : null,
        externalRef: externalRef != null && externalRef.trim().isNotEmpty
            ? externalRef.trim()
            : null,
        notes: notes != null && notes.trim().isNotEmpty ? notes.trim() : null,
        isCompleted: false,
      ),
    );
    _notify();
    return id;
  }

  @override
  Future<void> updateCalendarEvent(CalendarEventItem event) async {
    final idx = _calendarEvents.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      _calendarEvents[idx] = event.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending.dbValue,
      );
      _notify();
    }
  }

  @override
  Future<void> toggleCalendarEventCompleted(String eventId, bool isCompleted) async {
    final idx = _calendarEvents.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _calendarEvents[idx] = _calendarEvents[idx].copyWith(
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending.dbValue,
      );
      _notify();
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    _calendarEvents.removeWhere((e) => e.id == eventId);
    _notify();
  }

  @override
  Future<void> pushCalendarEventToStack({
    required String eventId,
    required String resumeNote,
  }) async {
    final idx = _calendarEvents.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final ev = _calendarEvents[idx];

    await pushInterruption(
      resumeNote: resumeNote,
      newUrgencyTitle: '📅 [${ev.formattedTimeRange}] ${ev.title}',
      externalRef: ev.externalRef,
      criticality: 2,
    );

    _calendarEvents[idx] = ev.copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
    );
    _notify();
  }

  @override
  Future<List<CalendarEventItem>> autoCompletePastCalendarEvents([
    DateTime? nowOverride,
  ]) async {
    final now = nowOverride ?? DateTime.now();
    final newlyCompleted = <CalendarEventItem>[];

    for (int i = 0; i < _calendarEvents.length; i++) {
      final ev = _calendarEvents[i];
      if (ev.deletedAt == null && !ev.isCompleted && ev.endTime.isBefore(now)) {
        final updated = ev.copyWith(
          isCompleted: true,
          updatedAt: now,
          syncStatus: SyncStatus.pending.dbValue,
        );
        _calendarEvents[i] = updated;
        newlyCompleted.add(updated);
      }
    }

    if (newlyCompleted.isNotEmpty) {
      _notify();
    }
    return newlyCompleted;
  }

  @override
  Future<String?> exportBackupJson() async {
    return WebStorageHelper.buildBackupJson();
  }

  @override
  Future<String?> importBackupJson(String rawJson) async {
    final err = WebStorageHelper.restoreFromBackupJson(rawJson);
    if (err != null) return err;

    _tasks.clear();
    _milestones.clear();
    _morningChecks.clear();
    _calendarEvents.clear();

    final savedTasks = WebStorageHelper.loadTasks();
    final savedMilestones = WebStorageHelper.loadMilestones();
    final savedChecks = WebStorageHelper.loadMorningChecks();
    final savedEvents = WebStorageHelper.loadCalendarEvents();

    if (savedTasks != null) _tasks.addAll(savedTasks);
    if (savedMilestones != null) _milestones.addAll(savedMilestones);
    if (savedChecks != null) _morningChecks.addAll(savedChecks);
    if (savedEvents != null) _calendarEvents.addAll(savedEvents);

    _notify();
    return null;
  }
}


