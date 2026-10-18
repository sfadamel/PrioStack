import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/priostack_providers.dart';

/// Barre de Statut Inférieure ultra-fine (style IDE / Linear) :
/// Jauge visuelle temps réel (% Temps Tâches de Fond vs % Temps Urgences) + Compteur PUSH.
class BottomStatusBar extends ConsumerWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final metricsAsync = ref.watch(stackMetricsProvider);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgMain,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle),
        ),
      ),
      child: metricsAsync.when(
        data: (metrics) {
          return Row(
            children: [
              // Légende Tâches de Fond
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.accentBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Focus Fond ${metrics.deepWorkPercent}%',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),

              // Fine barre de progression bi-colore (4px)
              SizedBox(
                width: 140,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: metrics.deepWorkPercent.clamp(5, 95),
                        child: Container(color: AppTheme.accentBlue),
                      ),
                      Expanded(
                        flex: metrics.interruptionPercent.clamp(5, 95),
                        child: Container(color: AppTheme.neonPink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Légende Urgences & Assistance
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.neonPink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Sollicitations ${metrics.interruptionPercent}%',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),

              // Indicateur d'état local + Compteur PUSH
              Text(
                'SQLite Local • Sync-Ready',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 14),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 13, color: AppTheme.neonPink),
                  const SizedBox(width: 3),
                  Text(
                    '${metrics.pushCountToday} PUSH aujourd\'hui',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
