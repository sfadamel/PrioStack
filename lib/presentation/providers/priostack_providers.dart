import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/drift/app_database.dart';
import '../../data/local/drift/drift_task_repository.dart';
import '../../data/local/memory/in_memory_task_repository.dart';
import '../../data/remote/neon_cloud_task_repository.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import 'auth_provider.dart';

/// Vue principale affichée sur l'écran (Cockpit 3 colonnes vs Calendrier vs Notes de Réunion)
enum CockpitMainView {
  cockpit,
  calendar,
  meetings,
}

/// Notifier pour basculer entre la vue Cockpit PrioStack et la vue Calendrier & Agenda
class CockpitMainViewNotifier extends Notifier<CockpitMainView> {
  @override
  CockpitMainView build() => CockpitMainView.cockpit;

  void toggleView() {
    state = state == CockpitMainView.cockpit
        ? CockpitMainView.calendar
        : CockpitMainView.cockpit;
  }

  void setView(CockpitMainView view) {
    state = view;
  }
}

final cockpitMainViewProvider =
    NotifierProvider<CockpitMainViewNotifier, CockpitMainView>(
  CockpitMainViewNotifier.new,
);

/// Date sélectionnée dans le Calendrier (par défaut : Aujourd'hui)
class SelectedCalendarDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDateNotifier, DateTime>(
  SelectedCalendarDateNotifier.new,
);

/// Instance singleton de la base SQLite locale Drift (Windows / Android / iOS)
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Injection du contrat abstrait TaskRepository :
/// - Si connecté avec un compte Neon Cloud : NeonCloudTaskRepository (Postgres Neon.tech)
/// - Sinon Web : InMemoryTaskRepository (localStorage)
/// - Sinon Desktop/Mobile hors-ligne : DriftTaskRepository (SQLite local)
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final authState = ref.watch(authProvider);
  final apiUrl = ref.watch(authApiUrlProvider);

  if (authState.isAuthenticated && authState.token != null) {
    return NeonCloudTaskRepository(
      baseUrl: apiUrl,
      getToken: () => authState.token!,
    );
  }

  if (kIsWeb) {
    return InMemoryTaskRepository();
  }
  final db = ref.watch(appDatabaseProvider);
  return DriftTaskRepository(db);
});

/// Flux réactif Zone 1 : Morning Check-list
final morningChecksProvider = StreamProvider<List<MorningCheckItem>>((ref) {
  return ref.watch(taskRepositoryProvider).watchMorningChecks();
});

/// Flux réactif du Calendrier & Agenda (Réunions, Points Équipe, Créneaux Architecture, Échéances)
final calendarEventsProvider = StreamProvider<List<CalendarEventItem>>((ref) {
  return ref.watch(taskRepositoryProvider).watchCalendarEvents();
});

/// Flux réactif Zone 2 : La Pile Active (Call Stack : Sommet -> Base)
final activeStackProvider = StreamProvider<List<TaskWithMilestones>>((ref) {
  return ref.watch(taskRepositoryProvider).watchActiveStack();
});

/// Flux réactif des Tâches de Fond en réserve (Backlog)
final backlogDeepWorkProvider = StreamProvider<List<TaskWithMilestones>>((ref) {
  return ref.watch(taskRepositoryProvider).watchBacklogDeepWork();
});

/// Flux réactif Zone 3 : Files de Triage par type (🔥 Urgence, 🧑‍💻 Assistance, 📤 Délégué)
final triageTasksByTypeProvider =
    StreamProvider.family<List<TaskWithMilestones>, TaskType>((ref, type) {
  return ref.watch(taskRepositoryProvider).watchTriageTasksByType(type);
});

/// Flux réactif du Backlog / Historique des tâches déjà terminées ('done')
final completedTasksProvider = StreamProvider<List<TaskWithMilestones>>((ref) {
  return ref.watch(taskRepositoryProvider).watchCompletedTasks();
});

/// Flux réactif Barre de Statut Inférieure : % Fond vs % Urgences + Compteur PUSH
final stackMetricsProvider = StreamProvider<StackMetrics>((ref) {
  return ref.watch(taskRepositoryProvider).watchStackMetrics();
});

/// État du Chronomètre Focus intégré à la Pile Active
class FocusTimerState {
  final bool isRunning;
  final String? activeTaskId;
  final int sessionSeconds;

  const FocusTimerState({
    this.isRunning = false,
    this.activeTaskId,
    this.sessionSeconds = 0,
  });

  FocusTimerState copyWith({
    bool? isRunning,
    String? activeTaskId,
    int? sessionSeconds,
  }) {
    return FocusTimerState(
      isRunning: isRunning ?? this.isRunning,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      sessionSeconds: sessionSeconds ?? this.sessionSeconds,
    );
  }
}

/// Notifier Riverpod 2 gérant le Chronomètre Focus et sa mise en pause automatique lors d'un PUSH
class FocusTimerNotifier extends Notifier<FocusTimerState> {
  Timer? _ticker;
  int _unsavedTicks = 0;

  @override
  FocusTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const FocusTimerState();
  }

  void toggleTimer(String taskId) {
    if (state.isRunning && state.activeTaskId == taskId) {
      pauseTimer();
    } else {
      startTimer(taskId);
    }
  }

  void startTimer(String taskId) {
    _ticker?.cancel();
    state = FocusTimerState(
      isRunning: true,
      activeTaskId: taskId,
      sessionSeconds: state.activeTaskId == taskId ? state.sessionSeconds : 0,
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(sessionSeconds: state.sessionSeconds + 1);
      _unsavedTicks++;
      // Persistance toutes les 5 secondes dans SQLite via Drift pour mettre à jour la jauge temps réel
      if (_unsavedTicks >= 5 && state.activeTaskId != null) {
        final toFlush = _unsavedTicks;
        _unsavedTicks = 0;
        ref.read(taskRepositoryProvider).recordFocusTick(state.activeTaskId!, toFlush);
      }
    });
  }

  Future<void> pauseTimer() async {
    _ticker?.cancel();
    if (_unsavedTicks > 0 && state.activeTaskId != null) {
      final toFlush = _unsavedTicks;
      _unsavedTicks = 0;
      await ref.read(taskRepositoryProvider).recordFocusTick(state.activeTaskId!, toFlush);
    }
    state = state.copyWith(isRunning: false);
  }
}

final focusTimerProvider = NotifierProvider<FocusTimerNotifier, FocusTimerState>(
  FocusTimerNotifier.new,
);

/// Notifier Riverpod 2 pour basculer entre le Mode Sombre (Dark Neumorphism) et le Mode Clair (Light Soft UI)
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    AppTheme.setDarkMode(true);
    return ThemeMode.dark;
  }

  void toggleTheme() {
    final nextIsDark = state != ThemeMode.dark;
    AppTheme.setDarkMode(nextIsDark);
    state = nextIsDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    AppTheme.setDarkMode(isDark);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
