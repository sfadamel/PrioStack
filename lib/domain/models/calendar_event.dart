import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Catégories d'événements du Calendrier PrioStack (Réunions, Points Équipe, Créneaux Architecture, Échéances)
enum CalendarEventCategory {
  meeting(
    'meeting',
    '🤝 Réunion',
    'Réunion',
    AppTheme.accentBlue,
    Icons.videocam_rounded,
  ),
  teamSync(
    'team_sync',
    '👥 Point Équipe',
    'Point Équipe',
    AppTheme.neonPurple,
    Icons.groups_rounded,
  ),
  architecture(
    'architecture',
    '🏛️ Créneau Architecture',
    'Architecture',
    AppTheme.neonAmber,
    Icons.architecture_rounded,
  ),
  deadline(
    'deadline',
    '⏰ Échéance / Livrable',
    'Échéance',
    AppTheme.neonPink,
    Icons.flag_rounded,
  );

  final String dbValue;
  final String label;
  final String shortLabel;
  final Color accentColor;
  final IconData icon;

  const CalendarEventCategory(
    this.dbValue,
    this.label,
    this.shortLabel,
    this.accentColor,
    this.icon,
  );

  static CalendarEventCategory fromDb(String value) {
    return CalendarEventCategory.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => CalendarEventCategory.meeting,
    );
  }
}

/// Types de périodicité / récurrence pour les réunions et événements
enum EventRecurrence {
  none('none', 'Ponctuel (aucune)'),
  daily('daily', 'Tous les jours'),
  weekdays('weekdays', 'Jours ouvrés (Lun - Ven)'),
  weekly('weekly', 'Toutes les semaines'),
  biweekly('biweekly', 'Toutes les 2 semaines'),
  monthly('monthly', 'Tous les mois');

  final String dbValue;
  final String label;
  const EventRecurrence(this.dbValue, this.label);

  static EventRecurrence fromDb(String? value) {
    if (value == null) return EventRecurrence.none;
    return EventRecurrence.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => EventRecurrence.none,
    );
  }

  /// Génère la liste des plages [start, end] pour le nombre d'occurrences demandé
  List<({DateTime start, DateTime end})> generateOccurrences({
    required DateTime startTime,
    required DateTime endTime,
    int count = 1,
  }) {
    if (this == EventRecurrence.none || count <= 1) {
      return [(start: startTime, end: endTime)];
    }

    final duration = endTime.difference(startTime);
    final results = <({DateTime start, DateTime end})>[];

    switch (this) {
      case EventRecurrence.none:
        results.add((start: startTime, end: endTime));
        break;

      case EventRecurrence.daily:
        for (int i = 0; i < count; i++) {
          final s = startTime.add(Duration(days: i));
          results.add((start: s, end: s.add(duration)));
        }
        break;

      case EventRecurrence.weekdays:
        DateTime curr = startTime;
        while (results.length < count) {
          if (curr.weekday != DateTime.saturday && curr.weekday != DateTime.sunday) {
            results.add((start: curr, end: curr.add(duration)));
          }
          curr = curr.add(const Duration(days: 1));
        }
        break;

      case EventRecurrence.weekly:
        for (int i = 0; i < count; i++) {
          final s = DateTime(
            startTime.year,
            startTime.month,
            startTime.day + (7 * i),
            startTime.hour,
            startTime.minute,
          );
          results.add((start: s, end: s.add(duration)));
        }
        break;

      case EventRecurrence.biweekly:
        for (int i = 0; i < count; i++) {
          final s = DateTime(
            startTime.year,
            startTime.month,
            startTime.day + (14 * i),
            startTime.hour,
            startTime.minute,
          );
          results.add((start: s, end: s.add(duration)));
        }
        break;

      case EventRecurrence.monthly:
        for (int i = 0; i < count; i++) {
          final s = DateTime(
            startTime.year,
            startTime.month + i,
            startTime.day,
            startTime.hour,
            startTime.minute,
          );
          results.add((start: s, end: s.add(duration)));
        }
        break;
    }

    return results;
  }
}

/// Entité V2-Ready ("Sync-Ready") représentant un événement daté du Calendrier (Réunion, Échéance, Créneau Focus)
class CalendarEventItem {
  final String id;
  final String userId;
  final String workspaceId;
  final String visibility; // 'private' | 'team'
  final String syncStatus; // 'local' | 'synced' | 'pending'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final String title;
  final CalendarEventCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final String? participantsOrLocation;
  final String? externalRef;
  final String? notes;
  final bool isCompleted;
  final String? linkedTaskId;
  final String? recurrenceRule; // 'daily', 'weekdays', 'weekly', 'biweekly', 'monthly'
  final String? recurrenceGroupId; // UUID regroupant toutes les occurrences d'une série

  const CalendarEventItem({
    required this.id,
    required this.userId,
    required this.workspaceId,
    this.visibility = 'team',
    this.syncStatus = 'local',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.participantsOrLocation,
    this.externalRef,
    this.notes,
    this.isCompleted = false,
    this.linkedTaskId,
    this.recurrenceRule,
    this.recurrenceGroupId,
  });

  bool get isRecurring =>
      recurrenceRule != null &&
      recurrenceRule!.isNotEmpty &&
      recurrenceRule != 'none';

  String get recurrenceLabel {
    switch (recurrenceRule) {
      case 'daily':
        return 'Quotidien';
      case 'weekdays':
        return 'Jours ouvrés';
      case 'weekly':
        return 'Hebdo';
      case 'biweekly':
        return 'Bi-hebdo';
      case 'monthly':
        return 'Mensuel';
      default:
        return 'Récurrent';
    }
  }

  int get durationMinutes =>
      endTime.difference(startTime).inMinutes.clamp(15, 720);

  String get formattedTimeRange {
    final sh = startTime.hour.toString().padLeft(2, '0');
    final sm = startTime.minute.toString().padLeft(2, '0');
    final eh = endTime.hour.toString().padLeft(2, '0');
    final em = endTime.minute.toString().padLeft(2, '0');
    return '$sh:$sm — $eh:$em';
  }

  String get formattedStartTime {
    final sh = startTime.hour.toString().padLeft(2, '0');
    final sm = startTime.minute.toString().padLeft(2, '0');
    return '$sh:$sm';
  }

  String get formattedDuration {
    final mins = durationMinutes;
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  bool isSameDay(DateTime date) {
    return startTime.year == date.year &&
        startTime.month == date.month &&
        startTime.day == date.day;
  }

  CalendarEventItem copyWith({
    String? id,
    String? userId,
    String? workspaceId,
    String? visibility,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? title,
    CalendarEventCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    String? participantsOrLocation,
    String? externalRef,
    String? notes,
    bool? isCompleted,
    String? linkedTaskId,
    String? recurrenceRule,
    String? recurrenceGroupId,
  }) {
    return CalendarEventItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workspaceId: workspaceId ?? this.workspaceId,
      visibility: visibility ?? this.visibility,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participantsOrLocation:
          participantsOrLocation ?? this.participantsOrLocation,
      externalRef: externalRef ?? this.externalRef,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
    );
  }
}
