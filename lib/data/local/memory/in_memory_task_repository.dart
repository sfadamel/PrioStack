import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../domain/models/task_enums.dart';
import '../../../domain/repositories/task_repository.dart';
import '../drift/app_database.dart';

/// Implémentation réactive en mémoire du contrat TaskRepository.
/// Permet d'exécuter et tester immédiatement PrioStack dans Chrome/Edge (`flutter run -d chrome`)
/// sans nécessiter la chaîne de compilation C++ Visual Studio, tout en partageant exactement
/// le même contrat et le même jeu de données initial que DriftTaskRepository.
class InMemoryTaskRepository implements TaskRepository {
  final Uuid _uuid = const Uuid();
  final List<PrioTask> _tasks = [];
  final List<MicroMilestone> _milestones = [];
  final List<MorningCheckItem> _morningChecks = [];

  final _changeController = StreamController<void>.broadcast();

  InMemoryTaskRepository() {
    _seedInitialData();
  }

  Stream<T> _reactiveStream<T>(T Function() compute) async* {
    yield compute();
    await for (final _ in _changeController.stream) {
      yield compute();
    }
  }

  void _notify() {
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
  Future<void> recordFocusTick(String taskId, int deltaSeconds) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        elapsedSeconds: _tasks[idx].elapsedSeconds + deltaSeconds,
        updatedAt: DateTime.now(),
      );
      _notify();
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
            resumeNote: resumeNote.trim(),
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
}


