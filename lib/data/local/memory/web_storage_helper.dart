import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../domain/models/calendar_event.dart';
import '../drift/app_database.dart';

// Conditionally import dart:html or stub
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_html.dart';

/// Helper de persistance local pour PrioStack Web / PWA
class WebStorageHelper {
  static const String _tasksKey = 'priostack_tasks_v1';
  static const String _milestonesKey = 'priostack_milestones_v1';
  static const String _checksKey = 'priostack_checks_v1';
  static const String _eventsKey = 'priostack_events_v1';
  static const String _initKey = 'priostack_initialized_v1';

  static bool isInitialized() {
    if (!kIsWeb) return false;
    return getStorageItem(_initKey) != null;
  }

  static void markInitialized() {
    if (!kIsWeb) return;
    setStorageItem(_initKey, 'true');
  }

  // --- Sauvegarde / Restauration (Export / Import JSON) ---

  static const String _backupFormat = 'priostack-backup';
  static const int _backupVersion = 1;

  /// Vrai juste après une restauration, tant que la page n'a pas été rechargée
  static bool _writesFrozen = false;

  /// Construit le contenu JSON de la sauvegarde à partir du stockage local courant.
  /// Retourne null s'il n'y a encore aucune donnée enregistrée.
  static String? buildBackupJson() {
    if (!kIsWeb) return null;
    final tasks = getStorageItem(_tasksKey);
    if (tasks == null || tasks.isEmpty) return null;

    List<dynamic> decodeOrEmpty(String? raw) {
      if (raw == null || raw.isEmpty) return const [];
      try {
        return jsonDecode(raw) as List;
      } catch (_) {
        return const [];
      }
    }

    final bundle = {
      'format': _backupFormat,
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': decodeOrEmpty(tasks),
      'milestones': decodeOrEmpty(getStorageItem(_milestonesKey)),
      'morningChecks': decodeOrEmpty(getStorageItem(_checksKey)),
      'calendarEvents': decodeOrEmpty(getStorageItem(_eventsKey)),
    };
    return const JsonEncoder.withIndent('  ').convert(bundle);
  }

  /// Nom de fichier horodaté pour la sauvegarde (ex: priostack-sauvegarde-2026-10-19.json)
  static String backupFileName() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'priostack-sauvegarde-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Valide puis restaure une sauvegarde. Retourne null si OK, sinon le message d'erreur.
  /// Les données actuelles ne sont écrasées qu'après validation complète du fichier.
  static String? restoreFromBackupJson(String raw) {
    if (!kIsWeb) return 'La restauration est disponible uniquement sur la version Web.';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['format'] != _backupFormat) {
        return 'Ce fichier n\'est pas une sauvegarde PrioStack valide.';
      }
      final version = decoded['version'];
      if (version is! int || version > _backupVersion) {
        return 'Version de sauvegarde non supportée ($version).';
      }

      final tasks = decoded['tasks'];
      final milestones = decoded['milestones'];
      final checks = decoded['morningChecks'];
      final events = decoded['calendarEvents'];
      if (tasks is! List || milestones is! List || checks is! List || events is! List) {
        return 'Sauvegarde incomplète ou corrompue.';
      }

      // Validation à blanc : on reconstruit chaque entité pour détecter toute erreur avant d'écraser.
      for (final t in tasks) {
        _mapToTask(Map<String, dynamic>.from(t as Map));
      }
      for (final m in milestones) {
        _mapToMilestone(Map<String, dynamic>.from(m as Map));
      }
      for (final c in checks) {
        _mapToCheck(Map<String, dynamic>.from(c as Map));
      }
      for (final e in events) {
        _mapToEvent(Map<String, dynamic>.from(e as Map));
      }

      setStorageItem(_tasksKey, jsonEncode(tasks));
      setStorageItem(_milestonesKey, jsonEncode(milestones));
      setStorageItem(_checksKey, jsonEncode(checks));
      setStorageItem(_eventsKey, jsonEncode(events));
      markInitialized();
      // Gèle toute écriture ultérieure : la page va être rechargée avec les données importées.
      _writesFrozen = true;
      return null;
    } catch (e) {
      return 'Fichier illisible : $e';
    }
  }

  /// Déclenche le téléchargement de la sauvegarde. Retourne false s'il n'y a rien à exporter.
  static bool exportBackup() {
    final json = buildBackupJson();
    if (json == null) return false;
    downloadTextFile(backupFileName(), json);
    return true;
  }

  /// Ouvre le sélecteur de fichier, restaure la sauvegarde puis recharge la page.
  /// Retourne null si annulé ou OK (la page se recharge), sinon un message d'erreur.
  static Future<String?> importBackup() async {
    final raw = await pickTextFile();
    if (raw == null) return null;
    final error = restoreFromBackupJson(raw);
    if (error != null) return error;
    reloadPage();
    return null;
  }

  // --- Sauvegarde ---

  static void saveAll({
    required List<PrioTask> tasks,
    required List<MicroMilestone> milestones,
    required List<MorningCheckItem> morningChecks,
    required List<CalendarEventItem> calendarEvents,
  }) {
    if (!kIsWeb || _writesFrozen) return;
    try {
      final tasksJson = jsonEncode(tasks.map(_taskToMap).toList());
      final milestonesJson = jsonEncode(milestones.map(_milestoneToMap).toList());
      final checksJson = jsonEncode(morningChecks.map(_checkToMap).toList());
      final eventsJson = jsonEncode(calendarEvents.map(_eventToMap).toList());

      setStorageItem(_tasksKey, tasksJson);
      setStorageItem(_milestonesKey, milestonesJson);
      setStorageItem(_checksKey, checksJson);
      setStorageItem(_eventsKey, eventsJson);
      markInitialized();
    } catch (e) {
      debugPrint('Erreur WebStorageHelper.saveAll: $e');
    }
  }

  // --- Chargement ---

  static List<PrioTask>? loadTasks() {
    if (!kIsWeb) return null;
    final raw = getStorageItem(_tasksKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => _mapToTask(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Erreur loadTasks: $e');
      return null;
    }
  }

  static List<MicroMilestone>? loadMilestones() {
    if (!kIsWeb) return null;
    final raw = getStorageItem(_milestonesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => _mapToMilestone(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Erreur loadMilestones: $e');
      return null;
    }
  }

  static List<MorningCheckItem>? loadMorningChecks() {
    if (!kIsWeb) return null;
    final raw = getStorageItem(_checksKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => _mapToCheck(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Erreur loadMorningChecks: $e');
      return null;
    }
  }

  static List<CalendarEventItem>? loadCalendarEvents() {
    if (!kIsWeb) return null;
    final raw = getStorageItem(_eventsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => _mapToEvent(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Erreur loadCalendarEvents: $e');
      return null;
    }
  }

  // --- Mappers PrioTask ---

  static Map<String, dynamic> _taskToMap(PrioTask t) {
    return {
      'id': t.id,
      'userId': t.userId,
      'workspaceId': t.workspaceId,
      'visibility': t.visibility,
      'syncStatus': t.syncStatus,
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
      'deletedAt': t.deletedAt?.toIso8601String(),
      'title': t.title,
      'type': t.type,
      'status': t.status,
      'criticality': t.criticality,
      'externalRef': t.externalRef,
      'requesterOrAssignee': t.requesterOrAssignee,
      'resumeNote': t.resumeNote,
      'stackOrder': t.stackOrder,
      'elapsedSeconds': t.elapsedSeconds,
      'interruptionCount': t.interruptionCount,
    };
  }

  static PrioTask _mapToTask(Map<String, dynamic> m) {
    return PrioTask(
      id: m['id'] as String,
      userId: m['userId'] as String? ?? 'usr_architect_01',
      workspaceId: m['workspaceId'] as String? ?? 'wks_damelit_arch',
      visibility: m['visibility'] as String? ?? 'private',
      syncStatus: m['syncStatus'] as String? ?? 'local',
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deletedAt: m['deletedAt'] != null ? DateTime.tryParse(m['deletedAt'] as String) : null,
      title: m['title'] as String? ?? '',
      type: m['type'] as String? ?? 'deep_work',
      status: m['status'] as String? ?? 'backlog',
      criticality: m['criticality'] as int? ?? 2,
      externalRef: m['externalRef'] as String?,
      requesterOrAssignee: m['requesterOrAssignee'] as String?,
      resumeNote: m['resumeNote'] as String?,
      stackOrder: m['stackOrder'] as int? ?? 0,
      elapsedSeconds: m['elapsedSeconds'] as int? ?? 0,
      interruptionCount: m['interruptionCount'] as int? ?? 0,
    );
  }

  // --- Mappers MicroMilestone ---

  static Map<String, dynamic> _milestoneToMap(MicroMilestone m) {
    return {
      'id': m.id,
      'taskId': m.taskId,
      'userId': m.userId,
      'workspaceId': m.workspaceId,
      'visibility': m.visibility,
      'syncStatus': m.syncStatus,
      'createdAt': m.createdAt.toIso8601String(),
      'updatedAt': m.updatedAt.toIso8601String(),
      'deletedAt': m.deletedAt?.toIso8601String(),
      'title': m.title,
      'durationMinutes': m.durationMinutes,
      'isDone': m.isDone,
      'sortOrder': m.sortOrder,
    };
  }

  static MicroMilestone _mapToMilestone(Map<String, dynamic> m) {
    return MicroMilestone(
      id: m['id'] as String,
      taskId: m['taskId'] as String,
      userId: m['userId'] as String? ?? 'usr_architect_01',
      workspaceId: m['workspaceId'] as String? ?? 'wks_damelit_arch',
      visibility: m['visibility'] as String? ?? 'private',
      syncStatus: m['syncStatus'] as String? ?? 'local',
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deletedAt: m['deletedAt'] != null ? DateTime.tryParse(m['deletedAt'] as String) : null,
      title: m['title'] as String? ?? '',
      durationMinutes: m['durationMinutes'] as int? ?? 30,
      isDone: m['isDone'] as bool? ?? false,
      sortOrder: m['sortOrder'] as int? ?? 0,
    );
  }

  // --- Mappers MorningCheckItem ---

  static Map<String, dynamic> _checkToMap(MorningCheckItem c) {
    return {
      'id': c.id,
      'userId': c.userId,
      'workspaceId': c.workspaceId,
      'visibility': c.visibility,
      'syncStatus': c.syncStatus,
      'createdAt': c.createdAt.toIso8601String(),
      'updatedAt': c.updatedAt.toIso8601String(),
      'deletedAt': c.deletedAt?.toIso8601String(),
      'title': c.title,
      'category': c.category,
      'isChecked': c.isChecked,
      'sortOrder': c.sortOrder,
      'lastResetAt': c.lastResetAt?.toIso8601String(),
    };
  }

  static MorningCheckItem _mapToCheck(Map<String, dynamic> m) {
    return MorningCheckItem(
      id: m['id'] as String,
      userId: m['userId'] as String? ?? 'usr_architect_01',
      workspaceId: m['workspaceId'] as String? ?? 'wks_damelit_arch',
      visibility: m['visibility'] as String? ?? 'private',
      syncStatus: m['syncStatus'] as String? ?? 'local',
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deletedAt: m['deletedAt'] != null ? DateTime.tryParse(m['deletedAt'] as String) : null,
      title: m['title'] as String? ?? '',
      category: m['category'] as String? ?? 'Infra & Ops',
      isChecked: m['isChecked'] as bool? ?? false,
      sortOrder: m['sortOrder'] as int? ?? 0,
      lastResetAt: m['lastResetAt'] != null ? DateTime.tryParse(m['lastResetAt'] as String) : null,
    );
  }

  // --- Mappers CalendarEventItem ---

  static Map<String, dynamic> _eventToMap(CalendarEventItem e) {
    return {
      'id': e.id,
      'userId': e.userId,
      'workspaceId': e.workspaceId,
      'visibility': e.visibility,
      'syncStatus': e.syncStatus,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
      'deletedAt': e.deletedAt?.toIso8601String(),
      'title': e.title,
      'category': e.category.dbValue,
      'startTime': e.startTime.toIso8601String(),
      'endTime': e.endTime.toIso8601String(),
      'participantsOrLocation': e.participantsOrLocation,
      'externalRef': e.externalRef,
      'notes': e.notes,
      'isCompleted': e.isCompleted,
      'linkedTaskId': e.linkedTaskId,
    };
  }

  static CalendarEventItem _mapToEvent(Map<String, dynamic> m) {
    return CalendarEventItem(
      id: m['id'] as String,
      userId: m['userId'] as String? ?? 'usr_architect_01',
      workspaceId: m['workspaceId'] as String? ?? 'wks_damelit_arch',
      visibility: m['visibility'] as String? ?? 'team',
      syncStatus: m['syncStatus'] as String? ?? 'local',
      createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deletedAt: m['deletedAt'] != null ? DateTime.tryParse(m['deletedAt'] as String) : null,
      title: m['title'] as String? ?? '',
      category: CalendarEventCategory.fromDb(m['category'] as String? ?? 'meeting'),
      startTime: DateTime.tryParse(m['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(m['endTime'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      participantsOrLocation: m['participantsOrLocation'] as String?,
      externalRef: m['externalRef'] as String?,
      notes: m['notes'] as String?,
      isCompleted: m['isCompleted'] as bool? ?? false,
      linkedTaskId: m['linkedTaskId'] as String?,
    );
  }
}
