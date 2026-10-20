import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../data/local/memory/web_storage_stub.dart'
    if (dart.library.html) '../../data/local/memory/web_storage_html.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/meeting_note.dart';
import '../../domain/models/task_enums.dart';
import 'auth_provider.dart';
import 'priostack_providers.dart';

class MeetingNotesState {
  final List<MeetingNote> meetings;
  final MeetingNote? activeMeeting;
  final bool isLoading;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String? error;

  const MeetingNotesState({
    this.meetings = const [],
    this.activeMeeting,
    this.isLoading = false,
    this.isSaving = false,
    this.lastSavedAt,
    this.error,
  });

  MeetingNotesState copyWith({
    List<MeetingNote>? meetings,
    MeetingNote? activeMeeting,
    bool clearActive = false,
    bool? isLoading,
    bool? isSaving,
    DateTime? lastSavedAt,
    String? error,
  }) {
    return MeetingNotesState(
      meetings: meetings ?? this.meetings,
      activeMeeting: clearActive ? null : (activeMeeting ?? this.activeMeeting),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      error: error,
    );
  }
}

class MeetingNotesNotifier extends StateNotifier<MeetingNotesState> {
  final Ref ref;
  Timer? _debounceTimer;

  MeetingNotesNotifier(this.ref) : super(const MeetingNotesState()) {
    fetchMeetings();
  }

  String get _apiUrl => ref.read(authApiUrlProvider);
  String? get _token => ref.read(authProvider).token;

  static const String _kLocalDraftPrefix = 'priostack_draft_meeting_';

  Future<void> fetchMeetings() async {
    if (_token == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await http.get(
        Uri.parse('$_apiUrl/meetings'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['meetings'] as List)
            .map((m) => MeetingNote.fromJson(m))
            .toList();

        // Si aucune active, on sélectionne la première s'il y en a une, sinon on en crée une
        MeetingNote? active = state.activeMeeting;
        if (active == null && list.isNotEmpty) {
          active = list.first;
        }

        state = state.copyWith(
          meetings: list,
          activeMeeting: active,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Erreur chargement réunions');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectMeeting(MeetingNote meeting) {
    _debounceTimer?.cancel();
    state = state.copyWith(activeMeeting: meeting);
  }

  /// Récupère la note liée à un rendez-vous du calendrier ou en crée une nouvelle automatiquement
  Future<MeetingNote> getOrCreateNoteForCalendarEvent(CalendarEventItem event) async {
    // 1. Chercher si une note existante est déjà liée à cet événement
    final existing = state.meetings
        .cast<MeetingNote?>()
        .firstWhere((m) => m?.calendarEventId == event.id, orElse: () => null);

    if (existing != null) {
      selectMeeting(existing);
      return existing;
    }

    // 2. Créer une nouvelle note pré-remplie et associée à ce rendez-vous
    final startStr =
        '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${event.startTime.day.toString().padLeft(2, '0')}/${event.startTime.month.toString().padLeft(2, '0')}/${event.startTime.year}';

    final buffer = StringBuffer();
    buffer.writeln('### 🗓️ Rendez-vous : ${event.title}');
    buffer.writeln('⏰ **Date & Horaire** : $dateStr de $startStr à $endStr');
    if (event.participantsOrLocation != null &&
        event.participantsOrLocation!.trim().isNotEmpty) {
      buffer.writeln('📍 **Participants / Lieu** : ${event.participantsOrLocation}');
    }
    if (event.notes != null && event.notes!.trim().isNotEmpty) {
      buffer.writeln('\n📋 **Ordre du jour / Contexte initial** :');
      buffer.writeln(event.notes);
    }
    buffer.writeln('\n---\n');
    buffer.writeln('#### ✍️ Discussions & Prises de notes :\n');
    buffer.writeln('- \n');
    buffer.writeln('#### 🎯 Décisions & Points clés :\n');
    buffer.writeln('- \n');

    final newNote = await createNewMeeting(
      title: event.title,
      template: buffer.toString(),
      participants: event.participantsOrLocation ?? '',
      calendarEventId: event.id,
      calendarEventTitle: event.title,
      meetingDate: event.startTime,
    );

    return newNote;
  }

  Future<MeetingNote> createNewMeeting({
    String title = 'Nouvelle Réunion',
    String template = '',
    String participants = '',
    String? calendarEventId,
    String? calendarEventTitle,
    DateTime? meetingDate,
  }) async {
    _debounceTimer?.cancel();
    final newId = const Uuid().v4();
    final now = DateTime.now();

    final note = MeetingNote(
      id: newId,
      title: title,
      meetingDate: meetingDate ?? now,
      participants: participants,
      content: template,
      actionItems: const [],
      calendarEventId: calendarEventId,
      calendarEventTitle: calendarEventTitle,
      createdAt: now,
      updatedAt: now,
    );

    // Sauvegarde locale immédiate (loss-proof)
    _saveToLocalStorage(note);

    state = state.copyWith(
      meetings: [note, ...state.meetings],
      activeMeeting: note,
      lastSavedAt: now,
    );

    // Synchro Cloud
    if (_token != null) {
      try {
        final res = await http.post(
          Uri.parse('$_apiUrl/meetings'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(note.toJson()),
        );
        if (res.statusCode == 201) {
          final created = MeetingNote.fromJson(jsonDecode(res.body)['meeting']);
          state = state.copyWith(
            meetings: state.meetings.map((m) => m.id == newId ? created : m).toList(),
            activeMeeting:
                state.activeMeeting?.id == newId ? created : state.activeMeeting,
            lastSavedAt: DateTime.now(),
          );
          return created;
        }
      } catch (_) {}
    }

    return note;
  }

  /// Modification avec Auto-Save instantané en local + debounce vers Neon Cloud
  void updateActiveMeeting({
    String? title,
    DateTime? meetingDate,
    String? participants,
    String? content,
    List<String>? actionItems,
    String? calendarEventId,
    bool clearCalendarEventId = false,
    String? calendarEventTitle,
  }) {
    final current = state.activeMeeting;
    if (current == null) return;

    final updated = current.copyWith(
      title: title,
      meetingDate: meetingDate,
      participants: participants,
      content: content,
      actionItems: actionItems,
      calendarEventId: calendarEventId,
      clearCalendarEventId: clearCalendarEventId,
      calendarEventTitle: calendarEventTitle,
      updatedAt: DateTime.now(),
    );

    // 1. Sauvegarde locale instantanée (protection immédiate contre reload / F5)
    _saveToLocalStorage(updated);

    // Mise à jour de l'état local
    final updatedList =
        state.meetings.map((m) => m.id == updated.id ? updated : m).toList();
    state = state.copyWith(
      activeMeeting: updated,
      meetings: updatedList,
      isSaving: true,
    );

    // 2. Debounce Cloud Save (600ms)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _syncToCloud(updated);
    });
  }

  void unlinkCalendarEvent() {
    updateActiveMeeting(clearCalendarEventId: true);
  }

  void _saveToLocalStorage(MeetingNote note) {
    try {
      setStorageItem('$_kLocalDraftPrefix${note.id}', jsonEncode(note.toJson()));
    } catch (_) {}
  }

  Future<void> _syncToCloud(MeetingNote note) async {
    if (_token == null) {
      state = state.copyWith(isSaving: false, lastSavedAt: DateTime.now());
      return;
    }

    try {
      final res = await http.put(
        Uri.parse('$_apiUrl/meetings/${note.id}'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(note.toJson()),
      );

      if (res.statusCode == 200) {
        state = state.copyWith(
          isSaving: false,
          lastSavedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(isSaving: false);
      }
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    _debounceTimer?.cancel();
    final updatedList = state.meetings.where((m) => m.id != meetingId).toList();
    MeetingNote? newActive = state.activeMeeting?.id == meetingId
        ? (updatedList.isNotEmpty ? updatedList.first : null)
        : state.activeMeeting;

    state = state.copyWith(
      meetings: updatedList,
      activeMeeting: newActive,
      clearActive: newActive == null,
    );

    if (_token != null) {
      try {
        await http.delete(
          Uri.parse('$_apiUrl/meetings/$meetingId'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      } catch (_) {}
    }
  }

  /// Transformer un point d'action ou une décision en tâche active PrioStack
  Future<void> convertActionItemToTask(String actionText) async {
    if (actionText.trim().isEmpty) return;
    final repo = ref.read(taskRepositoryProvider);
    await repo.quickCaptureTask(
      title: actionText.trim(),
      type: TaskType.urgence,
      criticality: 3,
      externalRef: 'REUNION',
      requesterOrAssignee: state.activeMeeting?.title,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final meetingNotesProvider =
    StateNotifierProvider<MeetingNotesNotifier, MeetingNotesState>((ref) {
  return MeetingNotesNotifier(ref);
});
