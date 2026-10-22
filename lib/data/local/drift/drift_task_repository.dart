import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/calendar_event.dart';
import '../../../domain/models/milestone_input.dart';
import '../../../domain/models/task_enums.dart';
import '../../../domain/repositories/task_repository.dart';
import 'app_database.dart';

class DriftTaskRepository implements TaskRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();
  final _calendarChangeController = StreamController<void>.broadcast();
  bool _calendarTableInitialized = false;

  DriftTaskRepository(this._db);

  @override
  Stream<List<MorningCheckItem>> watchMorningChecks() {
    final query = _db.select(_db.morningCheckItems)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ]);
    return query.watch();
  }

  @override
  Stream<List<TaskWithMilestones>> watchActiveStack() {
    final activeStatuses = [
      TaskStackStatus.activeTop.dbValue,
      TaskStackStatus.pushedPause.dbValue,
      TaskStackStatus.activeBase.dbValue,
    ];

    final tasksQuery = _db.select(_db.prioTasks)
      ..where((t) => t.deletedAt.isNull() & t.status.isIn(activeStatuses))
      ..orderBy([
        // Ordre décroissant pour que le sommet de la pile (active_top) soit en premier
        (t) => OrderingTerm(expression: t.stackOrder, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return tasksQuery.watch().asyncMap(_attachMilestones);
  }

  @override
  Stream<List<TaskWithMilestones>> watchTriageTasksByType(TaskType type) {
    final query = _db.select(_db.prioTasks)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.type.equals(type.dbValue) &
          t.status.equals(TaskStackStatus.backlog.dbValue))
      ..orderBy([
        (t) => OrderingTerm(expression: t.stackOrder, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.criticality, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(_attachMilestones);
  }

  @override
  Stream<List<TaskWithMilestones>> watchBacklogDeepWork() {
    final query = _db.select(_db.prioTasks)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.type.equals(TaskType.deepWork.dbValue) &
          t.status.equals(TaskStackStatus.backlog.dbValue))
      ..orderBy([
        (t) => OrderingTerm(expression: t.stackOrder, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.criticality, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(_attachMilestones);
  }

  @override
  Stream<StackMetrics> watchStackMetrics() {
    final query = _db.select(_db.prioTasks)
      ..where((t) => t.deletedAt.isNull());

    return query.watch().map((tasks) {
      int deepWorkSec = 0;
      int interruptionSec = 0;
      int pushCount = 0;

      for (final t in tasks) {
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

  Future<List<TaskWithMilestones>> _attachMilestones(List<PrioTask> tasks) async {
    if (tasks.isEmpty) return const [];
    final taskIds = tasks.map((t) => t.id).toList();

    final milestonesQuery = _db.select(_db.microMilestones)
      ..where((m) => m.deletedAt.isNull() & m.taskId.isIn(taskIds))
      ..orderBy([
        (m) => OrderingTerm(expression: m.sortOrder, mode: OrderingMode.asc),
        (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.asc),
      ]);

    final allMilestones = await milestonesQuery.get();
    final Map<String, List<MicroMilestone>> grouped = {};
    for (final m in allMilestones) {
      grouped.putIfAbsent(m.taskId, () => []).add(m);
    }

    return tasks
        .map((t) => TaskWithMilestones(
              task: t,
              milestones: grouped[t.id] ?? const [],
            ))
        .toList();
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

    await _db.transaction(() async {
      // Les nouvelles tâches sont créées par défaut en statut backlog (en attente),
      // afin de ne pas forcer l'activation immédiate ni rompre le focus en cours.
      const String initialStatus = 'backlog';

      await _db.into(_db.prioTasks).insert(
            PrioTasksCompanion.insert(
              id: Value(newId),
              title: title.trim(),
              type: type.dbValue,
              status: const Value(initialStatus),
              criticality: Value(criticality),
              externalRef: Value(
                externalRef != null && externalRef.trim().isNotEmpty
                    ? externalRef.trim()
                    : null,
              ),
              requesterOrAssignee: Value(
                requesterOrAssignee != null && requesterOrAssignee.trim().isNotEmpty
                    ? requesterOrAssignee.trim()
                    : null,
              ),
              visibility: Value(visibility.dbValue),
              syncStatus: Value(SyncStatus.pending.dbValue),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // Si c'est une tâche de fond sans jalons fournis, on génère 2 jalons de 30m par défaut
      final milestonesToCreate = initialMilestones.isNotEmpty
          ? initialMilestones
          : (type == TaskType.deepWork
              ? [
                  'Cadrage technique & revue d\'impact (30m)',
                  'Exécution / livrable principal (30m)',
                ]
              : <String>[]);

      for (int i = 0; i < milestonesToCreate.length; i++) {
        await _db.into(_db.microMilestones).insert(
              MicroMilestonesCompanion.insert(
                id: Value(_uuid.v4()),
                taskId: newId,
                title: milestonesToCreate[i],
                durationMinutes: const Value(30),
                sortOrder: Value(i + 1),
                syncStatus: Value(SyncStatus.pending.dbValue),
              ),
            );
      }
    });

    return newId;
  }

  @override
  Future<String> createDeepWorkTask({
    required String title,
    String? externalRef,
    String? requesterOrAssignee,
    int criticality = 2,
    VisibilityScope visibility = VisibilityScope.privateScope,
    List<MilestoneInput> milestones = const [],
    TaskStackStatus status = TaskStackStatus.backlog,
  }) async {
    final newId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.prioTasks).insert(
            PrioTasksCompanion.insert(
              id: Value(newId),
              title: title.trim(),
              type: TaskType.deepWork.dbValue,
              status: Value(status.dbValue),
              criticality: Value(criticality),
              externalRef: Value(
                externalRef != null && externalRef.trim().isNotEmpty
                    ? externalRef.trim()
                    : null,
              ),
              requesterOrAssignee: Value(
                requesterOrAssignee != null && requesterOrAssignee.trim().isNotEmpty
                    ? requesterOrAssignee.trim()
                    : null,
              ),
              visibility: Value(visibility.dbValue),
              syncStatus: Value(SyncStatus.pending.dbValue),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final milestonesToCreate = milestones.isNotEmpty
          ? milestones
          : const [
              MilestoneInput(title: 'Cadrage technique & analyse d\'impact', durationMinutes: 30),
              MilestoneInput(title: 'Exécution du livrable principal', durationMinutes: 30),
            ];

      for (int i = 0; i < milestonesToCreate.length; i++) {
        final m = milestonesToCreate[i];
        if (m.title.trim().isNotEmpty) {
          await _db.into(_db.microMilestones).insert(
                MicroMilestonesCompanion.insert(
                  id: Value(_uuid.v4()),
                  taskId: newId,
                  title: m.title.trim(),
                  durationMinutes: Value(m.durationMinutes),
                  sortOrder: Value(i + 1),
                  syncStatus: Value(SyncStatus.pending.dbValue),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }
      }
    });

    return newId;
  }

  @override
  Future<void> toggleMorningCheck(String id, bool isChecked) async {
    await (_db.update(_db.morningCheckItems)..where((t) => t.id.equals(id))).write(
      MorningCheckItemsCompanion(
        isChecked: Value(isChecked),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> resetMorningChecklist() async {
    final now = DateTime.now();
    await (_db.update(_db.morningCheckItems)..where((t) => t.deletedAt.isNull())).write(
      MorningCheckItemsCompanion(
        isChecked: const Value(false),
        lastResetAt: Value(now),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> addMorningCheckItem(String title, String category) async {
    final existing = await _db.select(_db.morningCheckItems).get();
    await _db.into(_db.morningCheckItems).insert(
          MorningCheckItemsCompanion.insert(
            id: Value(_uuid.v4()),
            title: title.trim(),
            category: Value(category.trim().isEmpty ? 'Routine' : category.trim()),
            sortOrder: Value(existing.length + 1),
            syncStatus: Value(SyncStatus.pending.dbValue),
          ),
        );
  }

  @override
  Future<void> activateDeepWorkTask(String taskId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      // Respect strict du WIP Limit = 1 sur la tâche de fond à la base de la pile :
      // Toute autre tâche de fond active_base ou pushed_pause retourne en backlog.
      await (_db.update(_db.prioTasks)
            ..where((t) =>
                t.type.equals(TaskType.deepWork.dbValue) &
                t.status.isIn([
                  TaskStackStatus.activeBase.dbValue,
                  TaskStackStatus.pushedPause.dbValue,
                ])))
          .write(
        PrioTasksCompanion(
          status: Value(TaskStackStatus.backlog.dbValue),
          stackOrder: const Value(0),
          syncStatus: Value(SyncStatus.pending.dbValue),
          updatedAt: Value(now),
        ),
      );

      // Si une urgence est actuellement au sommet de la pile, la tâche de fond entre en pushed_pause,
      // sinon elle prend directement le statut active_base.
      final activeUrgencies = await (_db.select(_db.prioTasks)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.status.equals(TaskStackStatus.activeTop.dbValue)))
          .get();

      final targetStatus = activeUrgencies.isNotEmpty
          ? TaskStackStatus.pushedPause.dbValue
          : TaskStackStatus.activeBase.dbValue;

      await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
        PrioTasksCompanion(
          status: Value(targetStatus),
          stackOrder: const Value(0),
          syncStatus: Value(SyncStatus.pending.dbValue),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> addMicroMilestone(String taskId, String title, {int durationMinutes = 30}) async {
    final existing = await (_db.select(_db.microMilestones)
          ..where((m) => m.taskId.equals(taskId) & m.deletedAt.isNull()))
        .get();

    await _db.into(_db.microMilestones).insert(
          MicroMilestonesCompanion.insert(
            id: Value(_uuid.v4()),
            taskId: taskId,
            title: title.trim(),
            durationMinutes: Value(durationMinutes),
            sortOrder: Value(existing.length + 1),
            syncStatus: Value(SyncStatus.pending.dbValue),
          ),
        );
  }

  @override
  Future<void> updateMicroMilestone(
    String milestoneId, {
    String? title,
    int? durationMinutes,
  }) async {
    await (_db.update(_db.microMilestones)..where((m) => m.id.equals(milestoneId))).write(
      MicroMilestonesCompanion(
        title: title != null ? Value(title.trim()) : const Value.absent(),
        durationMinutes: durationMinutes != null ? Value(durationMinutes) : const Value.absent(),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> toggleMicroMilestone(String milestoneId, bool isDone) async {
    await (_db.update(_db.microMilestones)..where((m) => m.id.equals(milestoneId))).write(
      MicroMilestonesCompanion(
        isDone: Value(isDone),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> recordFocusTick(String taskId, int totalElapsedSeconds, {bool notify = false}) async {
    final task = await (_db.select(_db.prioTasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (task == null) return;

    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        elapsedSeconds: Value(totalElapsedSeconds),
        updatedAt: Value(DateTime.now()),
      ),
    );
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

    await _db.transaction(() async {
      // 1. Récupérer tous les éléments actuellement dans la pile active
      final stackTasks = await (_db.select(_db.prioTasks)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.status.isIn([
                  TaskStackStatus.activeTop.dbValue,
                  TaskStackStatus.activeBase.dbValue,
                  TaskStackStatus.pushedPause.dbValue,
                ]))
            ..orderBy([
              (t) => OrderingTerm(expression: t.stackOrder, mode: OrderingMode.desc),
            ]))
          .get();

      int maxOrder = 0;
      for (final t in stackTasks) {
        if (t.stackOrder > maxOrder) maxOrder = t.stackOrder;
      }

      // 2. Sauvegarder la "Note de reprise" (optionnelle) sur la tâche qui était au premier plan
      //    et basculer tous les éléments de la pile en 'pushed_pause'
      if (stackTasks.isNotEmpty) {
        final currentTop = stackTasks.first;
        final trimmed = resumeNote.trim();
        await (_db.update(_db.prioTasks)..where((t) => t.id.equals(currentTop.id))).write(
          PrioTasksCompanion(
            status: Value(TaskStackStatus.pushedPause.dbValue),
            resumeNote: Value(trimmed.isEmpty ? null : trimmed),
            interruptionCount: Value(currentTop.interruptionCount + 1),
            syncStatus: Value(SyncStatus.pending.dbValue),
            updatedAt: Value(now),
          ),
        );

        for (final other in stackTasks.skip(1)) {
          await (_db.update(_db.prioTasks)..where((t) => t.id.equals(other.id))).write(
            PrioTasksCompanion(
              status: Value(TaskStackStatus.pushedPause.dbValue),
              syncStatus: Value(SyncStatus.pending.dbValue),
              updatedAt: Value(now),
            ),
          );
        }
      }

      // 3. Empiler (PUSH) l'urgence au sommet avec stackOrder = maxOrder + 1 et statut 'active_top'
      final nextStackOrder = maxOrder + 1;

      if (existingUrgencyTaskId != null) {
        await (_db.update(_db.prioTasks)..where((t) => t.id.equals(existingUrgencyTaskId))).write(
          PrioTasksCompanion(
            status: Value(TaskStackStatus.activeTop.dbValue),
            stackOrder: Value(nextStackOrder),
            syncStatus: Value(SyncStatus.pending.dbValue),
            updatedAt: Value(now),
          ),
        );
      } else if (newUrgencyTitle != null && newUrgencyTitle.trim().isNotEmpty) {
        await _db.into(_db.prioTasks).insert(
              PrioTasksCompanion.insert(
                id: Value(_uuid.v4()),
                title: newUrgencyTitle.trim(),
                type: TaskType.urgence.dbValue,
                status: Value(TaskStackStatus.activeTop.dbValue),
                criticality: Value(criticality),
                externalRef: Value(
                  externalRef != null && externalRef.trim().isNotEmpty
                      ? externalRef.trim()
                      : null,
                ),
                stackOrder: Value(nextStackOrder),
                interruptionCount: const Value(1),
                syncStatus: Value(SyncStatus.pending.dbValue),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  @override
  Future<void> popActiveTopTask(String topTaskId) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Marquer l'urgence au sommet comme résolue ('done')
      await (_db.update(_db.prioTasks)..where((t) => t.id.equals(topTaskId))).write(
        PrioTasksCompanion(
          status: Value(TaskStackStatus.done.dbValue),
          stackOrder: const Value(0),
          syncStatus: Value(SyncStatus.pending.dbValue),
          updatedAt: Value(now),
        ),
      );

      // 2. Récupérer les tâches restantes en pause dans la pile ('pushed_pause')
      final remainingPaused = await (_db.select(_db.prioTasks)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.status.equals(TaskStackStatus.pushedPause.dbValue))
            ..orderBy([
              (t) => OrderingTerm(expression: t.stackOrder, mode: OrderingMode.desc),
            ]))
          .get();

      if (remainingPaused.isNotEmpty) {
        final nextToResume = remainingPaused.first;
        final isBaseDeepWork = nextToResume.type == TaskType.deepWork.dbValue &&
            remainingPaused.length == 1;

        await (_db.update(_db.prioTasks)..where((t) => t.id.equals(nextToResume.id))).write(
          PrioTasksCompanion(
            status: Value(
              isBaseDeepWork
                  ? TaskStackStatus.activeBase.dbValue
                  : TaskStackStatus.activeTop.dbValue,
            ),
            syncStatus: Value(SyncStatus.pending.dbValue),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> acknowledgeResumeNote(String taskId) async {
    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        resumeNote: const Value(null),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delegateTask(String taskId, String assigneeName) async {
    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        type: Value(TaskType.delegated.dbValue),
        status: Value(TaskStackStatus.backlog.dbValue),
        requesterOrAssignee: Value(assigneeName.trim()),
        visibility: Value(VisibilityScope.team.dbValue),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<List<TaskWithMilestones>> watchCompletedTasks() {
    final query = _db.select(_db.prioTasks)
      ..where((t) =>
          t.deletedAt.isNull() & t.status.equals(TaskStackStatus.done.dbValue))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().asyncMap(_attachMilestones);
  }

  @override
  Future<void> completeTask(String taskId) async {
    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        status: Value(TaskStackStatus.done.dbValue),
        stackOrder: const Value(0),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> reactivateTask(String taskId, {bool placeInActiveStack = false}) async {
    final task = await (_db.select(_db.prioTasks)..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
    if (task == null) return;

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

    // Sinon on remet la tâche en statut 'backlog' (ou 'active_base' si c'est une tâche de fond et que la pile est vide)
    String targetStatus = TaskStackStatus.backlog.dbValue;
    if (task.type == TaskType.deepWork.dbValue) {
      final activeBase = await (_db.select(_db.prioTasks)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.status.isIn([
                  TaskStackStatus.activeBase.dbValue,
                  TaskStackStatus.pushedPause.dbValue,
                ])))
          .get();
      if (activeBase.isEmpty) {
        targetStatus = TaskStackStatus.activeBase.dbValue;
      }
    }

    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        status: Value(targetStatus),
        stackOrder: const Value(0),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateMorningCheckItem(String id, String title, String category) async {
    final now = DateTime.now();
    await (_db.update(_db.morningCheckItems)..where((t) => t.id.equals(id))).write(
      MorningCheckItemsCompanion(
        title: Value(title.trim()),
        category: Value(category.trim()),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteMorningCheckItem(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.morningCheckItems)..where((t) => t.id.equals(id))).write(
      MorningCheckItemsCompanion(
        deletedAt: Value(now),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteMicroMilestone(String milestoneId) async {
    final now = DateTime.now();
    await (_db.update(_db.microMilestones)..where((m) => m.id.equals(milestoneId))).write(
      MicroMilestonesCompanion(
        deletedAt: Value(now),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(now),
      ),
    );
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
    final now = DateTime.now();
    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        title: title != null ? Value(title.trim()) : const Value.absent(),
        externalRef: externalRef != null ? Value(externalRef.trim()) : const Value.absent(),
        requesterOrAssignee: requesterOrAssignee != null ? Value(requesterOrAssignee.trim()) : const Value.absent(),
        criticality: criticality != null ? Value(criticality) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final now = DateTime.now();
    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        deletedAt: Value(now),
        syncStatus: Value(SyncStatus.pending.dbValue),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> reorderMorningChecks(List<String> orderedIds) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.morningCheckItems)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(
          MorningCheckItemsCompanion(
            sortOrder: Value(i + 1),
            syncStatus: Value(SyncStatus.pending.dbValue),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> reorderMicroMilestones(
    String taskId,
    List<String> orderedMilestoneIds,
  ) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (int i = 0; i < orderedMilestoneIds.length; i++) {
        await (_db.update(_db.microMilestones)
              ..where((m) => m.id.equals(orderedMilestoneIds[i])))
            .write(
          MicroMilestonesCompanion(
            sortOrder: Value(i + 1),
            syncStatus: Value(SyncStatus.pending.dbValue),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> reorderTasks(List<String> orderedTaskIds) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (int i = 0; i < orderedTaskIds.length; i++) {
        await (_db.update(_db.prioTasks)
              ..where((t) => t.id.equals(orderedTaskIds[i])))
            .write(
          PrioTasksCompanion(
            stackOrder: Value(i + 1),
            syncStatus: Value(SyncStatus.pending.dbValue),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // --- CALENDRIER & AGENDA (Persistance SQLite V2-Ready) ---

  Future<void> _ensureCalendarTableAndSeed() async {
    if (_calendarTableInitialized) return;
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS calendar_events (
        id TEXT PRIMARY KEY NOT NULL,
        user_id TEXT NOT NULL,
        workspace_id TEXT NOT NULL,
        visibility TEXT NOT NULL DEFAULT 'team',
        sync_status TEXT NOT NULL DEFAULT 'local',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        participants_or_location TEXT NULL,
        external_ref TEXT NULL,
        notes TEXT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        linked_task_id TEXT NULL
      );
    ''');

    final countRows = await _db
        .customSelect('SELECT COUNT(*) AS cnt FROM calendar_events')
        .get();
    final cnt = countRows.isNotEmpty ? (countRows.first.read<int>('cnt')) : 0;

    if (cnt == 0) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final inTwoDays = today.add(const Duration(days: 2));
      final yesterday = today.subtract(const Duration(days: 1));
      final inFiveDays = today.add(const Duration(days: 5));

      final seeds = [
        (
          'Daily Standup & Triage Architecture',
          CalendarEventCategory.teamSync,
          today.add(const Duration(hours: 9, minutes: 30)),
          today.add(const Duration(hours: 10, minutes: 0)),
          'Teams • Équipe Core & Tech Leads',
          'AB#8400',
          'Point quotidien sur les blocages et priorités de la Pile Active.',
          true,
        ),
        (
          'Comité Architecture : Validation ADR-014 Sync V2',
          CalendarEventCategory.meeting,
          today.add(const Duration(hours: 11, minutes: 0)),
          today.add(const Duration(hours: 12, minutes: 0)),
          'Teams • CTO, SecOps, Lead Data',
          'AB#8412',
          'Arbitrage final sur le pattern Outbox SQLite -> Supabase PostgreSQL.',
          false,
        ),
        (
          'Sanctuaire Deep Work : Modélisation Contrat RPC V2',
          CalendarEventCategory.architecture,
          today.add(const Duration(hours: 14, minutes: 0)),
          today.add(const Duration(hours: 15, minutes: 30)),
          'Focus Individuel (Ne pas déranger)',
          'AB#8412',
          'Créneau protégé sans interruption pour avancer sur la Tâche de Fond.',
          false,
        ),
        (
          'Revue Hebdo Dette Technique & Deadlocks SQL',
          CalendarEventCategory.meeting,
          today.add(const Duration(hours: 16, minutes: 30)),
          today.add(const Duration(hours: 17, minutes: 15)),
          'Salle Atlas / Teams • Lucas M., Yassine B.',
          'AB#8904',
          'Analyse des plans d\'exécution PostgreSQL et verrous transactionnels.',
          false,
        ),
        (
          'Audit Sécurité : Rotation Certificats OAuth2 SSO Partenaires',
          CalendarEventCategory.meeting,
          tomorrow.add(const Duration(hours: 10, minutes: 0)),
          tomorrow.add(const Duration(hours: 11, minutes: 0)),
          'Teams • Équipe SecOps & IAM',
          'AB#8911',
          'Validation de la procédure de bascule sans coupure de service.',
          false,
        ),
        (
          'Go / No-Go Mise en Production Release 2.4',
          CalendarEventCategory.deadline,
          tomorrow.add(const Duration(hours: 15, minutes: 0)),
          tomorrow.add(const Duration(hours: 16, minutes: 0)),
          'Comité Release • Direction Technique',
          'AB#8950',
          'Vérification des résultats du benchmark k6 sur le cluster AKS.',
          false,
        ),
        (
          'Atelier Event-Driven Architecture (Kafka / EventHub)',
          CalendarEventCategory.architecture,
          inTwoDays.add(const Duration(hours: 14, minutes: 0)),
          inTwoDays.add(const Duration(hours: 16, minutes: 0)),
          'Salle Orion • Data Platform',
          'AB#8390',
          'Dimensionnement des partitions et gestion de la Dead-Letter Queue.',
          false,
        ),
        (
          'Point Mensuel FinOps & Coûts Cloud Azure',
          CalendarEventCategory.teamSync,
          yesterday.add(const Duration(hours: 11, minutes: 0)),
          yesterday.add(const Duration(hours: 12, minutes: 0)),
          'Teams • Thomas R. (DevOps)',
          'AB#8655',
          'Optimisation des réservations d\'instances AKS et stockage.',
          true,
        ),
        (
          'Livraison Contrat OpenAPI 3.1 Mobile',
          CalendarEventCategory.deadline,
          inFiveDays.add(const Duration(hours: 17, minutes: 0)),
          inFiveDays.add(const Duration(hours: 18, minutes: 0)),
          'Clara V. (Tech Lead Mobile)',
          'AB#8699',
          'Validation finale des schémas JSON et pagination.',
          false,
        ),
      ];

      for (final s in seeds) {
        await _db.customStatement(
          '''
          INSERT INTO calendar_events (
            id, user_id, workspace_id, visibility, sync_status,
            created_at, updated_at, deleted_at, title, category,
            start_time, end_time, participants_or_location, external_ref,
            notes, is_completed, linked_task_id
          ) VALUES (?, ?, ?, 'team', 'local', ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
          ''',
          [
            _uuid.v4(),
            kDefaultUserId,
            kDefaultWorkspaceId,
            now.millisecondsSinceEpoch,
            now.millisecondsSinceEpoch,
            s.$1,
            s.$2.dbValue,
            s.$3.millisecondsSinceEpoch,
            s.$4.millisecondsSinceEpoch,
            s.$5,
            s.$6,
            s.$7,
            s.$8 ? 1 : 0,
          ],
        );
      }
    }
    _calendarTableInitialized = true;
  }

  Future<List<CalendarEventItem>> _loadCalendarEventsFromDb() async {
    await _ensureCalendarTableAndSeed();
    final rows = await _db.customSelect(
      '''
      SELECT * FROM calendar_events
      WHERE deleted_at IS NULL
      ORDER BY start_time ASC
      ''',
    ).get();

    return rows.map((r) {
      final deletedMs = r.readNullable<int>('deleted_at');
      return CalendarEventItem(
        id: r.read<String>('id'),
        userId: r.read<String>('user_id'),
        workspaceId: r.read<String>('workspace_id'),
        visibility: r.read<String>('visibility'),
        syncStatus: r.read<String>('sync_status'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('created_at')),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('updated_at')),
        deletedAt: deletedMs != null
            ? DateTime.fromMillisecondsSinceEpoch(deletedMs)
            : null,
        title: r.read<String>('title'),
        category: CalendarEventCategory.fromDb(r.read<String>('category')),
        startTime: DateTime.fromMillisecondsSinceEpoch(r.read<int>('start_time')),
        endTime: DateTime.fromMillisecondsSinceEpoch(r.read<int>('end_time')),
        participantsOrLocation: r.readNullable<String>('participants_or_location'),
        externalRef: r.readNullable<String>('external_ref'),
        notes: r.readNullable<String>('notes'),
        isCompleted: r.read<int>('is_completed') == 1,
        linkedTaskId: r.readNullable<String>('linked_task_id'),
      );
    }).toList();
  }

  void _notifyCalendarChanged() {
    if (!_calendarChangeController.isClosed) {
      _calendarChangeController.add(null);
    }
  }

  @override
  Stream<List<CalendarEventItem>> watchCalendarEvents() async* {
    yield await _loadCalendarEventsFromDb();
    await for (final _ in _calendarChangeController.stream) {
      yield await _loadCalendarEventsFromDb();
    }
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
    await _ensureCalendarTableAndSeed();
    final now = DateTime.now();
    final id = _uuid.v4();
    final validEnd = endTime.isAfter(startTime)
        ? endTime
        : startTime.add(const Duration(minutes: 45));

    await _db.customStatement(
      '''
      INSERT INTO calendar_events (
        id, user_id, workspace_id, visibility, sync_status,
        created_at, updated_at, deleted_at, title, category,
        start_time, end_time, participants_or_location, external_ref,
        notes, is_completed, linked_task_id
      ) VALUES (?, ?, ?, 'team', 'pending', ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, 0, NULL)
      ''',
      [
        id,
        kDefaultUserId,
        kDefaultWorkspaceId,
        now.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
        title.trim(),
        category.dbValue,
        startTime.millisecondsSinceEpoch,
        validEnd.millisecondsSinceEpoch,
        participantsOrLocation != null && participantsOrLocation.trim().isNotEmpty
            ? participantsOrLocation.trim()
            : null,
        externalRef != null && externalRef.trim().isNotEmpty
            ? externalRef.trim()
            : null,
        notes != null && notes.trim().isNotEmpty ? notes.trim() : null,
      ],
    );
    _notifyCalendarChanged();
    return id;
  }

  @override
  Future<void> updateCalendarEvent(CalendarEventItem event) async {
    await _ensureCalendarTableAndSeed();
    final now = DateTime.now();
    await _db.customStatement(
      '''
      UPDATE calendar_events
      SET title = ?, category = ?, start_time = ?, end_time = ?,
          participants_or_location = ?, external_ref = ?, notes = ?,
          is_completed = ?, updated_at = ?, sync_status = 'pending'
      WHERE id = ?
      ''',
      [
        event.title.trim(),
        event.category.dbValue,
        event.startTime.millisecondsSinceEpoch,
        event.endTime.millisecondsSinceEpoch,
        event.participantsOrLocation,
        event.externalRef,
        event.notes,
        event.isCompleted ? 1 : 0,
        now.millisecondsSinceEpoch,
        event.id,
      ],
    );
    _notifyCalendarChanged();
  }

  @override
  Future<void> toggleCalendarEventCompleted(
      String eventId, bool isCompleted) async {
    await _ensureCalendarTableAndSeed();
    final now = DateTime.now();
    await _db.customStatement(
      '''
      UPDATE calendar_events
      SET is_completed = ?, updated_at = ?, sync_status = 'pending'
      WHERE id = ?
      ''',
      [
        isCompleted ? 1 : 0,
        now.millisecondsSinceEpoch,
        eventId,
      ],
    );
    _notifyCalendarChanged();
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    await _ensureCalendarTableAndSeed();
    final now = DateTime.now();
    await _db.customStatement(
      '''
      UPDATE calendar_events
      SET deleted_at = ?, updated_at = ?, sync_status = 'pending'
      WHERE id = ?
      ''',
      [
        now.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
        eventId,
      ],
    );
    _notifyCalendarChanged();
  }

  @override
  Future<void> pushCalendarEventToStack({
    required String eventId,
    required String resumeNote,
  }) async {
    final events = await _loadCalendarEventsFromDb();
    final ev = events.where((e) => e.id == eventId).firstOrNull;
    if (ev == null) return;

    await pushInterruption(
      resumeNote: resumeNote,
      newUrgencyTitle: '📅 [${ev.formattedTimeRange}] ${ev.title}',
      externalRef: ev.externalRef,
      criticality: 2,
    );

    await toggleCalendarEventCompleted(eventId, true);
  }

  @override
  Future<List<CalendarEventItem>> autoCompletePastCalendarEvents([
    DateTime? nowOverride,
  ]) async {
    final now = nowOverride ?? DateTime.now();
    final events = await _loadCalendarEventsFromDb();
    final pastUncompleted = events
        .where((e) => !e.isCompleted && e.endTime.isBefore(now))
        .toList();

    if (pastUncompleted.isEmpty) return const [];

    for (final ev in pastUncompleted) {
      await _db.customStatement(
        '''
        UPDATE calendar_events
        SET is_completed = 1, updated_at = ?, sync_status = 'pending'
        WHERE id = ?
        ''',
        [
          now.millisecondsSinceEpoch,
          ev.id,
        ],
      );
    }
    _notifyCalendarChanged();
    return pastUncompleted
        .map((e) => e.copyWith(isCompleted: true, updatedAt: now))
        .toList();
  }

  @override
  Future<String?> exportBackupJson() async => null;

  @override
  Future<String?> importBackupJson(String rawJson) async => null;
}


