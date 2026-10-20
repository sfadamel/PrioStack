import 'dart:convert';

/// Modèle représentant une note de réunion complète avec sauvegarde automatique et actions clés
class MeetingNote {
  final String id;
  final String title;
  final DateTime meetingDate;
  final String participants;
  final String content;
  final List<String> actionItems;
  final String? calendarEventId;
  final String? calendarEventTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingNote({
    required this.id,
    required this.title,
    required this.meetingDate,
    this.participants = '',
    this.content = '',
    this.actionItems = const [],
    this.calendarEventId,
    this.calendarEventTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  MeetingNote copyWith({
    String? id,
    String? title,
    DateTime? meetingDate,
    String? participants,
    String? content,
    List<String>? actionItems,
    String? calendarEventId,
    bool clearCalendarEventId = false,
    String? calendarEventTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingNote(
      id: id ?? this.id,
      title: title ?? this.title,
      meetingDate: meetingDate ?? this.meetingDate,
      participants: participants ?? this.participants,
      content: content ?? this.content,
      actionItems: actionItems ?? this.actionItems,
      calendarEventId:
          clearCalendarEventId ? null : (calendarEventId ?? this.calendarEventId),
      calendarEventTitle: clearCalendarEventId
          ? null
          : (calendarEventTitle ?? this.calendarEventTitle),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MeetingNote.fromJson(Map<String, dynamic> json) {
    List<String> parseActionItems(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return MeetingNote(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Réunion sans titre',
      meetingDate: json['meeting_date'] != null
          ? DateTime.tryParse(json['meeting_date'].toString()) ?? DateTime.now()
          : (json['meetingDate'] != null
              ? DateTime.tryParse(json['meetingDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      participants: json['participants']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      actionItems: parseActionItems(json['action_items'] ?? json['actionItems']),
      calendarEventId: json['calendar_event_id']?.toString() ??
          json['calendarEventId']?.toString(),
      calendarEventTitle: json['calendar_event_title']?.toString() ??
          json['calendarEventTitle']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'meetingDate': meetingDate.toIso8601String(),
      'participants': participants,
      'content': content,
      'actionItems': actionItems,
      'calendarEventId': calendarEventId,
      'calendarEventTitle': calendarEventTitle,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
