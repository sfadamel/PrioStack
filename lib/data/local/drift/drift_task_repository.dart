import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/task_enums.dart';
import '../../../domain/repositories/task_repository.dart';
import 'app_database.dart';

class DriftTaskRepository implements TaskRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

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
      // Si c'est une Tâche de Fond et qu'aucune tâche de fond n'est dans la pile active,
      // on l'active directement à la base de la pile (WIP = 1).
      String initialStatus = TaskStackStatus.backlog.dbValue;
      if (type == TaskType.deepWork) {
        final activeBaseCount = await (_db.select(_db.prioTasks)
              ..where((t) =>
                  t.deletedAt.isNull() &
                  t.status.isIn([
                    TaskStackStatus.activeBase.dbValue,
                    TaskStackStatus.pushedPause.dbValue,
                  ])))
            .get();
        if (activeBaseCount.isEmpty) {
          initialStatus = TaskStackStatus.activeBase.dbValue;
        }
      }

      await _db.into(_db.prioTasks).insert(
            PrioTasksCompanion.insert(
              id: Value(newId),
              title: title.trim(),
              type: type.dbValue,
              status: Value(initialStatus),
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
  Future<void> recordFocusTick(String taskId, int deltaSeconds) async {
    final task = await (_db.select(_db.prioTasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (task == null) return;

    await (_db.update(_db.prioTasks)..where((t) => t.id.equals(taskId))).write(
      PrioTasksCompanion(
        elapsedSeconds: Value(task.elapsedSeconds + deltaSeconds),
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

      // 2. Sauvegarder la "Note de reprise" obligatoire sur la tâche qui était au premier plan
      //    et basculer tous les éléments de la pile en 'pushed_pause'
      if (stackTasks.isNotEmpty) {
        final currentTop = stackTasks.first;
        await (_db.update(_db.prioTasks)..where((t) => t.id.equals(currentTop.id))).write(
          PrioTasksCompanion(
            status: Value(TaskStackStatus.pushedPause.dbValue),
            resumeNote: Value(resumeNote.trim()),
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
}


