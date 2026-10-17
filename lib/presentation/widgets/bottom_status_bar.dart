import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/priostack_providers.dart';

/// Barre de Statut Inférieure :
/// Jauge visuelle temps réel (% Temps Tâches de Fond vs % Temps Urgences / Support Devs)
/// + Compteur d'interruptions (PUSH).
class BottomStatusBar extends ConsumerWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final metricsAsync = ref.watch(stackMetricsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.surfaceCard,
        radius: 16,
      ),
      child: metricsAsync.when(
        data: (metrics) {
          return Row(
            children: [
              // Légende Tâches de Fond
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tâches de Fond : ${metrics.deepWorkPercent}%',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Jauge visuelle bi-colore temps réel
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(
                          flex: metrics.deepWorkPercent.clamp(5, 95),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: metrics.interruptionPercent.clamp(5, 95),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.urgencyGradient,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Légende Urgences & Support Devs
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.neonPink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Urgences / Assistance : ${metrics.interruptionPercent}%',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),

              // Compteur d'interruptions (PUSH)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 14, color: AppTheme.neonPink),
                    const SizedBox(width: 4),
                    Text(
                      'Interruptions (PUSH) : ${metrics.pushCountToday}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 24),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
