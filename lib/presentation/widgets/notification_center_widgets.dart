import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';

/// Bouton Cloche de Notifications (🔔) avec compteur temps réel dans la barre supérieure
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final notifState = ref.watch(appNotificationsProvider);
    final unread = notifState.unreadCount;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => showNotificationCenterDialog(context, ref),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: unread > 0
              ? AppTheme.neonAmber.withValues(alpha: 0.14)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: unread > 0
                ? AppTheme.neonAmber.withValues(alpha: 0.65)
                : AppTheme.borderHighlight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unread > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 16,
              color: unread > 0 ? AppTheme.neonAmber : AppTheme.textSecondary,
            ),
            if (unread > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.neonPink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bannière de Notification Flottante Globale visible sur toute l'application (Cockpit + Calendrier)
class GlobalNotificationBanner extends ConsumerWidget {
  const GlobalNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final notifState = ref.watch(appNotificationsProvider);
    final banner = notifState.activeBanner;

    if (banner == null) return const SizedBox.shrink();

    final accent = banner.type.accentColor;
    final isCalendarRelated =
        banner.type == AppNotificationType.meetingAutoCompleted ||
            banner.type == AppNotificationType.meetingImminent ||
            banner.type == AppNotificationType.meetingStarted;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(banner.type.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.type.badgeLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        banner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  banner.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isCalendarRelated)
            InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                ref
                    .read(appNotificationsProvider.notifier)
                    .markAsRead(banner.id);
                ref
                    .read(appNotificationsProvider.notifier)
                    .dismissActiveBanner();
                ref
                    .read(cockpitMainViewProvider.notifier)
                    .setView(CockpitMainView.calendar);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Voir Agenda',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showNotificationCenterDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Centre (${notifState.unreadCount})',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ref
                .read(appNotificationsProvider.notifier)
                .dismissActiveBanner(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 17,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fenêtre modale du Centre de Notifications Global PrioStack
Future<void> showNotificationCenterDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return Consumer(
        builder: (ctx, cRef, _) {
          final notifState = cRef.watch(appNotificationsProvider);
          final items = notifState.notifications;

          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.borderHighlight),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonAmber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppTheme.neonAmber,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centre de Notifications PrioStack',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Alertes réunions, clôtures automatiques, PUSH & POP de la pile',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => cRef
                        .read(appNotificationsProvider.notifier)
                        .markAllAsRead(),
                    icon: const Icon(Icons.done_all_rounded, size: 15),
                    label: const Text(
                      'Tout lire',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        cRef.read(appNotificationsProvider.notifier).clearAll(),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                    label: const Text(
                      'Vider',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            content: SizedBox(
              width: 560,
              height: 420,
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 42,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aucune notification pour le moment.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final n = items[index];
                        final accent = n.type.accentColor;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () {
                              cRef
                                  .read(appNotificationsProvider.notifier)
                                  .markAsRead(n.id);
                              if (n.relatedEventId != null) {
                                Navigator.pop(ctx);
                                cRef
                                    .read(cockpitMainViewProvider.notifier)
                                    .setView(CockpitMainView.calendar);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: n.isRead
                                    ? AppTheme.bgMain.withValues(alpha: 0.6)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: n.isRead
                                      ? AppTheme.borderSubtle
                                      : accent.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      n.type.icon,
                                      size: 16,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: accent
                                                    .withValues(alpha: 0.16),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                n.type.badgeLabel,
                                                style: TextStyle(
                                                  color: accent,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              n.formattedTime,
                                              style: TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          n.title,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: n.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          n.body,
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => cRef
                                        .read(appNotificationsProvider.notifier)
                                        .deleteNotification(n.id),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    },
  );
}
