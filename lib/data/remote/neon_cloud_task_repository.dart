import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/local/drift/app_database.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../local/memory/web_storage_stub.dart'
    if (dart.library.html) '../local/memory/web_storage_html.dart';

/// Implémentation Cloud du TaskRepository connectée directement à Neon.tech via l'API REST
class NeonCloudTaskRepository implements TaskRepository {
  final String baseUrl;
  final String Function() getToken;

  final _changeController = StreamController<void>.broadcast();
  Timer? _pollingTimer;
  StreamSubscription? _tabSyncSub;

  List<TaskWithMilestones>? _cachedTasks;
  DateTime? _lastTasksFetchTime;
  Future<List<TaskWithMilestones>>? _inFlightTasksFetch;

  List<MorningCheckItem>? _cachedChecks;
  DateTime? _lastChecksFetchTime;
  Future<List<MorningCheckItem>>? _inFlightChecksFetch;

  String? _lastKnownTaskVersion;
  String? _lastKnownCheckVersion;
  bool _isCheckingVersion = false;

  NeonCloudTaskRepository({
    required this.baseUrl,
    required this.getToken,
  }) {
    // 1. Écoute instantanée inter-onglets (BroadcastChannel Web)
    _tabSyncSub = onSyncEvent(() {
      _cachedTasks = null;
      _cachedChecks = null;
      _notifyLocal();
    });

    // 2. Polling intelligent optimisé toutes les 6s :
    // Vérifie un hash de version de 40 octets au lieu de re-télécharger toute la base
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _checkRemoteVersion();
    });
  }

  Future<void> _checkRemoteVersion() async {
    if (_isCheckingVersion) return;
    _isCheckingVersion = true;
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/sync/version'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final remoteTaskVer = data['taskVer'] as String? ?? '';
        final remoteCheckVer = data['checkVer'] as String? ?? '';

        final tasksChanged = _lastKnownTaskVersion != null && remoteTaskVer != _lastKnownTaskVersion;
        final checksChanged = _lastKnownCheckVersion != null && remoteCheckVer != _lastKnownCheckVersion;

        _lastKnownTaskVersion = remoteTaskVer;
        _lastKnownCheckVersion = remoteCheckVer;

        if (tasksChanged) {
          _cachedTasks = null;
        }
        if (checksChanged) {
          _cachedChecks = null;
        }
        if (tasksChanged || checksChanged) {
          _notifyLocal();
        }
      }
    } catch (_) {
      // Ignorer silencieusement les erreurs de connexion temporaires
    } finally {
      _isCheckingVersion = false;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _tabSyncSub?.cancel();
    _changeController.close();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${getToken()}',
      };

  void _notifyLocal() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  void _notify() {
    _cachedTasks = null;
    _cachedChecks = null;
    _notifyLocal();
    // Notifier immédiatement les autres onglets ouverts sur la même machine
    broadcastSyncEvent('mutation');
  }

  Stream<T> _reactiveStream<T>(Future<T> Function() fetcher) async* {
    yield await fetcher();
    await for (final _ in _changeController.stream) {
      yield await fetcher();
    }
  }

  // --- MORNING CHECKS ---
  @override
  Stream<List<MorningCheckItem>> watchMorningChecks() {
    return _reactiveStream(() async {
      if (_cachedChecks != null &&
          _lastChecksFetchTime != null &&
          DateTime.now().difference(_lastChecksFetchTime!).inSeconds < 30) {
        return _cachedChecks!;
      }
      if (_inFlightChecksFetch != null) {
        return await _inFlightChecksFetch!;
      }
      _inFlightChecksFetch = _rawFetchChecks();
      try {
        final res = await _inFlightChecksFetch!;
        _cachedChecks = res;
        _lastChecksFetchTime = DateTime.now();
        return res;
      } finally {
        _inFlightChecksFetch = null;
      }
    });
  }

  Future<List<MorningCheckItem>> _rawFetchChecks() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/morning-checks'), headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return MorningCheckItem(
            id: m['id'] as String,
            userId: m['user_id'] as String? ?? 'usr_01',
            workspaceId: 'wks_damelit_arch',
            visibility: 'private',
            syncStatus: 'synced',
            createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? '') ?? DateTime.now(),
            title: m['title'] as String,
            category: m['category'] as String? ?? 'Infra & Ops',
            isChecked: m['is_checked'] as bool? ?? false,
            sortOrder: m['sort_order'] as int? ?? 0,
            lastResetAt: m['last_reset_at'] != null ? DateTime.tryParse(m['last_reset_at'] as String) : null,
          );
        }).toList();
      }
    } catch (_) {}
    return <MorningCheckItem>[];
  }

  @override
  Future<void> toggleMorningCheck(String id, bool isChecked) async {
    if (_cachedChecks != null) {
      final idx = _cachedChecks!.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _cachedChecks![idx] = _cachedChecks![idx].copyWith(isChecked: isChecked);
        _notifyLocal();
      }
    }
    await http.patch(
      Uri.parse('$baseUrl/morning-checks/$id/toggle'),
      headers: _headers,
      body: jsonEncode({'isChecked': isChecked}),
    );
    broadcastSyncEvent('mutation');
  }

  @override
  Future<void> resetMorningChecklist() async {
    await http.post(Uri.parse('$baseUrl/morning-checks/reset'), headers: _headers);
    _notify();
  }

  @override
  Future<void> addMorningCheckItem(String title, String category) async {
    await http.post(
      Uri.parse('$baseUrl/morning-checks'),
      headers: _headers,
      body: jsonEncode({'title': title, 'category': category}),
    );
    _notify();
  }

  @override
  Future<void> deleteMorningCheckItem(String id) async {
    await http.delete(Uri.parse('$baseUrl/morning-checks/$id'), headers: _headers);
    _notify();
  }

  @override
  Future<void> reorderMorningChecks(List<String> orderedIds) async {
    _notify();
  }

  // --- TÂCHES & CALL STACK ---
  Future<List<TaskWithMilestones>> _fetchTasks({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedTasks != null &&
        _lastTasksFetchTime != null &&
        now.difference(_lastTasksFetchTime!).inMilliseconds < 1200) {
      return _cachedTasks!;
    }
    if (_inFlightTasksFetch != null) {
      return await _inFlightTasksFetch!;
    }
    _inFlightTasksFetch = _rawFetchTasks();
    try {
      final res = await _inFlightTasksFetch!;
      _cachedTasks = res;
      _lastTasksFetchTime = DateTime.now();
      return res;
    } finally {
      _inFlightTasksFetch = null;
    }
  }

  Future<List<TaskWithMilestones>> _rawFetchTasks() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/tasks'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list.map((item) {
          final t = item as Map<String, dynamic>;
          final rawMilestones = (t['milestones'] as List?) ?? [];

          final milestones = rawMilestones.map((m) {
            final mm = m as Map<String, dynamic>;
            return MicroMilestone(
              id: mm['id'] as String,
              taskId: mm['task_id'] as String,
              userId: mm['user_id'] as String? ?? 'usr_01',
              workspaceId: 'wks_damelit_arch',
              visibility: 'private',
              syncStatus: 'synced',
              createdAt: DateTime.tryParse(mm['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(mm['updated_at'] as String? ?? '') ?? DateTime.now(),
              title: mm['title'] as String,
              durationMinutes: mm['duration_minutes'] as int? ?? 30,
              isDone: mm['is_done'] as bool? ?? false,
              sortOrder: mm['sort_order'] as int? ?? 0,
            );
          }).toList();

          final task = PrioTask(
            id: t['id'] as String,
            userId: t['user_id'] as String? ?? 'usr_01',
            workspaceId: 'wks_damelit_arch',
            visibility: t['visibility'] as String? ?? 'private',
            syncStatus: 'synced',
            createdAt: DateTime.tryParse(t['created_at'] as String? ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(t['updated_at'] as String? ?? '') ?? DateTime.now(),
            title: t['title'] as String,
            type: t['type'] as String,
            status: t['status'] as String? ?? 'backlog',
            criticality: t['criticality'] as int? ?? 2,
            externalRef: t['external_ref'] as String?,
            requesterOrAssignee: t['requester_or_assignee'] as String?,
            resumeNote: t['resume_note'] as String?,
            stackOrder: t['stack_order'] as int? ?? 0,
            elapsedSeconds: t['elapsed_seconds'] as int? ?? 0,
            interruptionCount: t['interruption_count'] as int? ?? 0,
          );

          return TaskWithMilestones(task: task, milestones: milestones);
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Stream<List<TaskWithMilestones>> watchActiveStack() {
    return _reactiveStream(() async {
      final all = await _fetchTasks();
      final stack = all.where((t) =>
          t.task.status == TaskStackStatus.activeBase.dbValue ||
          t.task.status == TaskStackStatus.activeTop.dbValue ||
          t.task.status == TaskStackStatus.pushedPause.dbValue).toList();
      stack.sort((a, b) => b.task.stackOrder.compareTo(a.task.stackOrder));
      return stack;
    });
  }

  @override
  Stream<List<TaskWithMilestones>> watchTriageTasksByType(TaskType type) {
    return _reactiveStream(() async {
      final all = await _fetchTasks();
      final list = all.where((t) =>
          t.task.type == type.dbValue &&
          t.task.status != TaskStackStatus.activeTop.dbValue &&
          t.task.status != TaskStackStatus.activeBase.dbValue &&
          t.task.status != TaskStackStatus.pushedPause.dbValue &&
          t.task.status != TaskStackStatus.done.dbValue).toList();
      list.sort((a, b) => b.task.criticality.compareTo(a.task.criticality));
      return list;
    });
  }

  @override
  Stream<List<TaskWithMilestones>> watchBacklogDeepWork() {
    return _reactiveStream(() async {
      final all = await _fetchTasks();
      return all.where((t) =>
          t.task.type == TaskType.deepWork.dbValue &&
          t.task.status == TaskStackStatus.backlog.dbValue).toList();
    });
  }

  @override
  Stream<List<TaskWithMilestones>> watchCompletedTasks() {
    return _reactiveStream(() async {
      final all = await _fetchTasks();
      return all.where((t) => t.task.status == TaskStackStatus.done.dbValue).toList();
    });
  }

  @override
  Stream<StackMetrics> watchStackMetrics() {
    return _reactiveStream(() async {
      final all = await _fetchTasks();
      int deepWorkSec = 0;
      int interruptionSec = 0;
      int pushCount = 0;

      for (final item in all) {
        if (item.task.type == TaskType.deepWork.dbValue) {
          deepWorkSec += item.task.elapsedSeconds;
        } else {
          interruptionSec += item.task.elapsedSeconds;
        }
        pushCount += item.task.interruptionCount;
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
    final resp = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'type': type.dbValue,
        'criticality': criticality,
        'externalRef': externalRef,
        'requesterOrAssignee': requesterOrAssignee,
        'initialMilestones': initialMilestones,
      }),
    );
    _notify();
    if (resp.statusCode == 201) {
      final created = jsonDecode(resp.body) as Map<String, dynamic>;
      return created['id'] as String;
    }
    return '';
  }

  @override
  Future<void> pushInterruption({
    required String resumeNote,
    String? existingUrgencyTaskId,
    String? newUrgencyTitle,
    String? externalRef,
    int criticality = 3,
  }) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/tasks/push-interruption'),
      headers: _headers,
      body: jsonEncode({
        'resumeNote': resumeNote,
        'existingUrgencyTaskId': existingUrgencyTaskId,
        'newUrgencyTitle': newUrgencyTitle,
        'externalRef': externalRef,
      }),
    ).timeout(const Duration(seconds: 10));
    _notify();
    if (resp.statusCode >= 400) {
      throw Exception('Erreur serveur lors du PUSH (${resp.statusCode})');
    }
  }

  @override
  Future<void> popActiveTopTask(String topTaskId) async {
    await http.post(Uri.parse('$baseUrl/tasks/$topTaskId/pop'), headers: _headers);
    _notify();
  }

  @override
  Future<void> completeTask(String taskId) async {
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
      body: jsonEncode({'status': TaskStackStatus.done.dbValue}),
    );
    _notify();
  }

  @override
  Future<void> activateDeepWorkTask(String taskId) async {
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
      body: jsonEncode({'status': TaskStackStatus.activeBase.dbValue, 'stackOrder': 0}),
    );
    _notify();
  }

  @override
  Future<void> reactivateTask(String taskId, {bool placeInActiveStack = false}) async {
    final status = placeInActiveStack ? TaskStackStatus.activeBase.dbValue : TaskStackStatus.backlog.dbValue;
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    _notify();
  }

  @override
  Future<void> delegateTask(String taskId, String assigneeName) async {
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
      body: jsonEncode({
        'type': TaskType.delegated.dbValue,
        'requesterOrAssignee': assigneeName,
      }),
    );
    _notify();
  }

  @override
  Future<void> recordFocusTick(String taskId, int totalElapsedSeconds, {bool notify = false}) async {
    try {
      if (_cachedTasks != null) {
        final idx = _cachedTasks!.indexWhere((t) => t.task.id == taskId);
        if (idx != -1) {
          final old = _cachedTasks![idx];
          _cachedTasks![idx] = TaskWithMilestones(
            task: old.task.copyWith(elapsedSeconds: totalElapsedSeconds),
            milestones: old.milestones,
          );
        }
      }
      await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _headers,
        body: jsonEncode({'elapsedSeconds': totalElapsedSeconds}),
      ).timeout(const Duration(seconds: 5));
      if (notify) {
        _notify();
      }
    } catch (_) {}
  }

  @override
  Future<void> acknowledgeResumeNote(String taskId) async {
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _headers,
      body: jsonEncode({'resumeNote': ''}),
    );
    _notify();
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await http.delete(Uri.parse('$baseUrl/tasks/$taskId'), headers: _headers);
    _notify();
  }

  @override
  Future<void> reorderTasks(List<String> orderedTaskIds) async {
    _notify();
  }

  // --- MICRO-JALONS ---
  @override
  Future<void> addMicroMilestone(String taskId, String title, {int durationMinutes = 30}) async {
    await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/milestones'),
      headers: _headers,
      body: jsonEncode({'title': title, 'durationMinutes': durationMinutes}),
    );
    _notify();
  }

  @override
  Future<void> updateMicroMilestone(String milestoneId, {String? title, int? durationMinutes}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (durationMinutes != null) body['durationMinutes'] = durationMinutes;

    await http.patch(
      Uri.parse('$baseUrl/milestones/$milestoneId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _notify();
  }

  @override
  Future<void> toggleMicroMilestone(String milestoneId, bool isDone) async {
    // Mise à jour optimiste immédiate en mémoire
    if (_cachedTasks != null) {
      for (int i = 0; i < _cachedTasks!.length; i++) {
        final taskItem = _cachedTasks![i];
        final mIdx = taskItem.milestones.indexWhere((m) => m.id == milestoneId);
        if (mIdx != -1) {
          final updatedMilestones = List<MicroMilestone>.from(taskItem.milestones);
          updatedMilestones[mIdx] = updatedMilestones[mIdx].copyWith(isDone: isDone);
          _cachedTasks![i] = TaskWithMilestones(
            task: taskItem.task,
            milestones: updatedMilestones,
          );
          _notifyLocal();
          break;
        }
      }
    }
    await http.patch(
      Uri.parse('$baseUrl/milestones/$milestoneId'),
      headers: _headers,
      body: jsonEncode({'isDone': isDone}),
    );
    broadcastSyncEvent('mutation');
  }

  @override
  Future<void> deleteMicroMilestone(String milestoneId) async {
    await http.delete(Uri.parse('$baseUrl/milestones/$milestoneId'), headers: _headers);
    _notify();
  }

  @override
  Future<void> reorderMicroMilestones(String taskId, List<String> orderedMilestoneIds) async {
    _notify();
  }

  // --- CALENDRIER & AGENDA ---
  @override
  Stream<List<CalendarEventItem>> watchCalendarEvents() {
    return _reactiveStream(() async {
      try {
        final resp = await http.get(Uri.parse('$baseUrl/calendar-events'), headers: _headers);
        if (resp.statusCode == 200) {
          final list = jsonDecode(resp.body) as List;
          return list.map((item) {
            final e = item as Map<String, dynamic>;
            return CalendarEventItem(
              id: e['id'] as String,
              userId: e['user_id'] as String? ?? 'usr_01',
              workspaceId: 'wks_damelit_arch',
              visibility: e['visibility'] as String? ?? 'team',
              syncStatus: 'synced',
              createdAt: DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(e['updated_at'] as String? ?? '') ?? DateTime.now(),
              title: e['title'] as String,
              category: CalendarEventCategory.fromDb(e['category'] as String? ?? 'meeting'),
              startTime: DateTime.tryParse(e['start_time'] as String? ?? '') ?? DateTime.now(),
              endTime: DateTime.tryParse(e['end_time'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
              participantsOrLocation: e['participants_or_location'] as String?,
              externalRef: e['external_ref'] as String?,
              notes: e['notes'] as String?,
              isCompleted: e['is_completed'] as bool? ?? false,
              linkedTaskId: e['linked_task_id'] as String?,
            );
          }).toList();
        }
      } catch (_) {}
      return [];
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
    final resp = await http.post(
      Uri.parse('$baseUrl/calendar-events'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'category': category.dbValue,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'participantsOrLocation': participantsOrLocation,
        'externalRef': externalRef,
        'notes': notes,
      }),
    );
    _notify();
    if (resp.statusCode == 201) {
      final created = jsonDecode(resp.body) as Map<String, dynamic>;
      return created['id'] as String;
    }
    return '';
  }

  @override
  Future<void> updateCalendarEvent(CalendarEventItem event) async {
    _notify();
  }

  @override
  Future<void> toggleCalendarEventCompleted(String eventId, bool isCompleted) async {
    await http.patch(
      Uri.parse('$baseUrl/calendar-events/$eventId/toggle'),
      headers: _headers,
      body: jsonEncode({'isCompleted': isCompleted}),
    );
    _notify();
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    await http.delete(Uri.parse('$baseUrl/calendar-events/$eventId'), headers: _headers);
    _notify();
  }

  @override
  Future<void> pushCalendarEventToStack({
    required String eventId,
    required String resumeNote,
  }) async {
    await pushInterruption(
      resumeNote: resumeNote,
      newUrgencyTitle: 'Réunion prioritaire empilée',
    );
  }

  @override
  Future<List<CalendarEventItem>> autoCompletePastCalendarEvents([
    DateTime? nowOverride,
  ]) async {
    return [];
  }

  @override
  Future<String?> exportBackupJson() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/backup/export'), headers: _headers);
      if (resp.statusCode == 200) {
        return resp.body;
      }
    } catch (e) {
      // ignore error
    }
    return null;
  }

  @override
  Future<String?> importBackupJson(String rawJson) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/backup/import'),
        headers: _headers,
        body: rawJson,
      );
      if (resp.statusCode == 200) {
        _notify();
        return null;
      } else {
        try {
          final errBody = jsonDecode(resp.body);
          return errBody['error'] ?? 'Échec lors de l\'importation (${resp.statusCode})';
        } catch (_) {
          return 'Erreur serveur lors de l\'importation (${resp.statusCode})';
        }
      }
    } catch (e) {
      return 'Erreur de connexion lors de l\'importation : $e';
    }
  }
}
