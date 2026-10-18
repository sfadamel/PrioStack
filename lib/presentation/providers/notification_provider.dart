import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import 'priostack_providers.dart';

/// Types de notifications globales dans toute l'application PrioStack
enum AppNotificationType {
  meetingAutoCompleted(
    '✅ Réunion clôturée (Auto)',
    AppTheme.neonGreen,
    Icons.event_available_rounded,
  ),
  meetingImminent(
    '⏰ Réunion imminente',
    AppTheme.neonAmber,
    Icons.notifications_active_rounded,
  ),
  meetingStarted(
    '🎥 Réunion en cours',
    AppTheme.accentBlue,
    Icons.videocam_rounded,
  ),
  stackPush(
    '🚨 Interruption (PUSH)',
    AppTheme.neonPink,
    Icons.call_received_rounded,
  ),
  stackPop(
    '🎯 Reprise Focus (POP)',
    AppTheme.neonGreen,
    Icons.layers_clear_rounded,
  ),
  taskCaptured(
    '⚡ Capture Éclair',
    AppTheme.accentBlue,
    Icons.bolt_rounded,
  ),
  delegation(
    '📤 Délégation Équipe',
    AppTheme.neonPurple,
    Icons.forward_to_inbox_rounded,
  );

  final String badgeLabel;
  final Color accentColor;
  final IconData icon;

  const AppNotificationType(this.badgeLabel, this.accentColor, this.icon);
}

/// Modèle d'une notification applicative PrioStack
class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedEventId;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedEventId,
  });

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  AppNotificationItem copyWith({
    bool? isRead,
  }) {
    return AppNotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      relatedEventId: relatedEventId,
    );
  }
}

/// État global du Centre de Notifications + Bannière Toast temps réel
class AppNotificationsState {
  final List<AppNotificationItem> notifications;
  final AppNotificationItem? activeBanner;

  const AppNotificationsState({
    this.notifications = const [],
    this.activeBanner,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  AppNotificationsState copyWith({
    List<AppNotificationItem>? notifications,
    AppNotificationItem? activeBanner,
    bool clearBanner = false,
  }) {
    return AppNotificationsState(
      notifications: notifications ?? this.notifications,
      activeBanner: clearBanner ? null : (activeBanner ?? this.activeBanner),
    );
  }
}

/// Moteur de surveillance temps réel :
/// 1. Termine automatiquement les réunions dont l'heure de fin (`endTime`) est dépassée
/// 2. Alerte automatiquement lorsqu'une réunion approche (<= 15 min) ou démarre
/// 3. Centralise toutes les notifications de l'application (PUSH, POP, Capture, Délégation, Calendrier)
class AppNotificationsNotifier extends Notifier<AppNotificationsState> {
  final _uuid = const Uuid();
  Timer? _watchdogTimer;
  Timer? _bannerDismissTimer;
  final Set<String> _notifiedUpcomingEventIds = {};
  final Set<String> _notifiedStartedEventIds = {};

  @override
  AppNotificationsState build() {
    ref.onDispose(() {
      _watchdogTimer?.cancel();
      _bannerDismissTimer?.cancel();
    });

    // Dès que la liste des événements du calendrier change, on vérifie immédiatement les réunions dépassées ou imminentes
    ref.listen(calendarEventsProvider, (_, __) {
      Future.microtask(_runCalendarAndAppChecks);
    });

    // Vérification initiale dès le démarrage + surveillance périodique toutes les 15 secondes
    Future.microtask(_runCalendarAndAppChecks);
    _watchdogTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _runCalendarAndAppChecks(),
    );

    return const AppNotificationsState();
  }

  Future<void> runImmediateCheck() => _runCalendarAndAppChecks();

  /// Exécute la clôture automatique des réunions dépassées et la détection des réunions imminentes
  Future<void> _runCalendarAndAppChecks() async {
    final repo = ref.read(taskRepositoryProvider);
    final now = DateTime.now();

    // 1. Clôturer automatiquement toutes les réunions dont l'heure de fin est dépassée
    final autoCompleted = await repo.autoCompletePastCalendarEvents(now);
    for (final ev in autoCompleted) {
      pushNotification(
        title: 'Réunion terminée automatiquement : ${ev.title}',
        body:
            'Créneau ${ev.formattedTimeRange} dépassé — marquée comme « Terminée ✓ » dans votre agenda.',
        type: AppNotificationType.meetingAutoCompleted,
        relatedEventId: ev.id,
      );
    }

    // 2. Vérifier les réunions imminentes (dans les 15 prochaines minutes) ou en cours
    final eventsAsync = ref.read(calendarEventsProvider);
    final allEvents = eventsAsync.valueOrNull ?? const [];

    for (final ev in allEvents) {
      if (ev.isCompleted || ev.deletedAt != null) continue;

      final diffToStartMinutes = ev.startTime.difference(now).inMinutes;
      final isOngoing =
          !now.isBefore(ev.startTime) && now.isBefore(ev.endTime);

      if (isOngoing && !_notifiedStartedEventIds.contains(ev.id)) {
        _notifiedStartedEventIds.add(ev.id);
        pushNotification(
          title: '🎥 Réunion en cours : ${ev.title}',
          body:
              '${ev.formattedTimeRange} • Cliquez pour rejoindre ou faire un PUSH dans la Pile Active.',
          type: AppNotificationType.meetingStarted,
          relatedEventId: ev.id,
        );
      } else if (diffToStartMinutes >= 0 &&
          diffToStartMinutes <= 15 &&
          !_notifiedUpcomingEventIds.contains(ev.id)) {
        _notifiedUpcomingEventIds.add(ev.id);
        final minLabel =
            diffToStartMinutes <= 1 ? 'moins d\'1 min' : '$diffToStartMinutes min';
        pushNotification(
          title: '⏰ Réunion dans $minLabel : ${ev.title}',
          body:
              '${ev.formattedTimeRange} (${ev.participantsOrLocation ?? "Agenda"}) — pensez à préparer votre Note de reprise.',
          type: AppNotificationType.meetingImminent,
          relatedEventId: ev.id,
        );
      }
    }
  }

  /// Publie une nouvelle notification dans toute l'application + affiche la bannière flottante
  void pushNotification({
    required String title,
    required String body,
    required AppNotificationType type,
    String? relatedEventId,
    bool showBanner = true,
  }) {
    final item = AppNotificationItem(
      id: _uuid.v4(),
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      relatedEventId: relatedEventId,
    );

    final updatedList = [item, ...state.notifications];

    _bannerDismissTimer?.cancel();
    state = state.copyWith(
      notifications: updatedList,
      activeBanner: showBanner ? item : state.activeBanner,
    );

    if (showBanner) {
      _bannerDismissTimer = Timer(const Duration(seconds: 7), () {
        dismissActiveBanner();
      });
    }
  }

  void dismissActiveBanner() {
    _bannerDismissTimer?.cancel();
    state = state.copyWith(clearBanner: true);
  }

  void markAsRead(String id) {
    final updated = state.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated, clearBanner: true);
  }

  void deleteNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    final clearToast = state.activeBanner?.id == id;
    state = state.copyWith(
      notifications: updated,
      clearBanner: clearToast,
    );
  }

  void clearAll() {
    _bannerDismissTimer?.cancel();
    state = const AppNotificationsState(notifications: [], activeBanner: null);
  }
}

final appNotificationsProvider =
    NotifierProvider<AppNotificationsNotifier, AppNotificationsState>(
  AppNotificationsNotifier.new,
);
