import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';
import 'active_stack_panel.dart';
import 'sync_reorderable_list.dart';

/// Zone 3 (Droite sur PC) : "Triage & Bouclier" épuré (4 Onglets segmentés)
/// - Urgences : Prendre (PUSH) ou Déléguer
/// - Assistance : Traitement par lots (Batch)
/// - Délégué : Suivi des livrables équipe
/// - Fait : Historique réactivable en 1 clic
class TriageShieldPanel extends ConsumerStatefulWidget {
  const TriageShieldPanel({super.key});

  @override
  ConsumerState<TriageShieldPanel> createState() => _TriageShieldPanelState();
}

class _TriageShieldPanelState extends ConsumerState<TriageShieldPanel> {
  int _selectedTabIndex = 0;

  static const _tabs = [
    (TaskType.urgence, 'Urgences'),
    (TaskType.devBlock, 'Assistance'),
    (TaskType.delegated, 'Délégué'),
    (null, 'Fait'),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final selectedTab = _tabs[_selectedTabIndex];
    final isCompletedBacklogTab = selectedTab.$1 == null;
    final activeType = selectedTab.$1;

    final tasksAsync = isCompletedBacklogTab
        ? ref.watch(completedTasksProvider)
        : ref.watch(triageTasksByTypeProvider(activeType!));

    return Container(
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.bgMain,
        radius: 16,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tête épuré sur 1 seule ligne ---
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppTheme.accentIndigo,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Triage & Flux',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Glisser ⠿ pour trier',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Sélecteur segmenté des 4 Onglets (Urgences | Assistance | Délégué | Fait) ---
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final (type, label) = _tabs[index];
                final isSelected = _selectedTabIndex == index;
                final countAsync = type == null
                    ? ref.watch(completedTasksProvider)
                    : ref.watch(triageTasksByTypeProvider(type));
                final count = countAsync.valueOrNull?.length ?? 0;
                final badgeColor = type?.accentColor ?? AppTheme.neonGreen;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.surfaceCard
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: AppTheme.borderHighlight, width: 1)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4.5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? badgeColor.withValues(alpha: 0.16)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected
                                      ? badgeColor
                                      : AppTheme.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // --- Liste des cartes de l'onglet sélectionné ---
          Expanded(
            child: tasksAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      isCompletedBacklogTab
                          ? 'Aucune tâche terminée.'
                          : 'Aucun élément dans ${_tabs[_selectedTabIndex].$2}.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  );
                }

                return SyncReorderableList<TaskWithMilestones>(
                  key: ValueKey('triage_tab_$_selectedTabIndex'),
                  items: items,
                  idOf: (item) => 'triage_${item.task.id}',
                  onReordered: (reordered) {
                    ref.read(taskRepositoryProvider).reorderTasks(
                          reordered.map((e) => e.task.id).toList(),
                        );
                  },
                  itemBuilder: (context, item, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: isCompletedBacklogTab
                          ? _buildCompletedBacklogCard(context, item, index)
                          : _buildTriageCard(
                              context, item, activeType!, index),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte épurée du Backlog des éléments déjà réalisés
  Widget _buildCompletedBacklogCard(
    BuildContext context,
    TaskWithMilestones item,
    int index,
  ) {
    final task = item.task;
    final taskType = TaskType.fromDb(task.type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 15,
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: taskType.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                taskType.label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (task.externalRef != null &&
                  task.externalRef!.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${task.externalRef!}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () =>
                    ref.read(taskRepositoryProvider).deleteTask(task.id),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSubtleActionBtn(
                label: 'Remettre en file',
                icon: Icons.restore_rounded,
                color: AppTheme.textSecondary,
                onTap: () => ref
                    .read(taskRepositoryProvider)
                    .reactivateTask(task.id, placeInActiveStack: false),
              ),
              const SizedBox(width: 6),
              _buildSubtleActionBtn(
                label: 'Activer dans la Pile',
                icon: Icons.layers_rounded,
                color: AppTheme.accentBlue,
                isPrimaryTint: true,
                onTap: () => ref
                    .read(taskRepositoryProvider)
                    .reactivateTask(task.id, placeInActiveStack: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriageCard(
    BuildContext context,
    TaskWithMilestones item,
    TaskType activeType,
    int index,
  ) {
    final task = item.task;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Drag + Pastille initiale + Interlocuteur + Réf AzDO + Supprimer
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 15,
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: activeType.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(task.requesterOrAssignee ?? 'P'),
                  style: TextStyle(
                    color: activeType.accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  task.requesterOrAssignee ?? 'Non assigné',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.externalRef != null &&
                  task.externalRef!.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    task.externalRef!,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () =>
                    ref.read(taskRepositoryProvider).deleteTask(task.id),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // Sujet / Titre
          Text(
            task.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Actions épurées alignées à droite
          if (activeType == TaskType.urgence)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSubtleActionBtn(
                  label: 'Déléguer',
                  icon: Icons.outbox_rounded,
                  color: AppTheme.textSecondary,
                  onTap: () => _showDelegateDialog(context, task.id),
                ),
                const SizedBox(width: 6),
                _buildSubtleActionBtn(
                  label: 'Prendre (PUSH)',
                  icon: Icons.bolt_rounded,
                  color: AppTheme.neonPink,
                  isPrimaryTint: true,
                  onTap: () => showPushInterruptionDialog(
                    context,
                    ref,
                    existingUrgencyTaskId: task.id,
                    existingUrgencyTitle: task.title,
                  ),
                ),
              ],
            )
          else if (activeType == TaskType.devBlock)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSubtleActionBtn(
                  label: 'PUSH',
                  icon: Icons.bolt_rounded,
                  color: AppTheme.neonPink,
                  onTap: () => showPushInterruptionDialog(
                    context,
                    ref,
                    existingUrgencyTaskId: task.id,
                    existingUrgencyTitle: task.title,
                  ),
                ),
                const SizedBox(width: 6),
                _buildSubtleActionBtn(
                  label: 'Traité (Batch)',
                  icon: Icons.check_rounded,
                  color: AppTheme.neonGreen,
                  isPrimaryTint: true,
                  onTap: () =>
                      ref.read(taskRepositoryProvider).completeTask(task.id),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Équipe (${task.visibility.toUpperCase()})',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildSubtleActionBtn(
                  label: 'Reçu ✓',
                  icon: Icons.check_rounded,
                  color: AppTheme.neonGreen,
                  isPrimaryTint: true,
                  onTap: () =>
                      ref.read(taskRepositoryProvider).completeTask(task.id),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSubtleActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimaryTint = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isPrimaryTint
              ? color.withValues(alpha: 0.14)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isPrimaryTint
                ? color.withValues(alpha: 0.4)
                : AppTheme.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDelegateDialog(BuildContext context, String taskId) async {
    final assigneeCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text(
          'Déléguer à un membre de l\'équipe',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15.5),
        ),
        content: TextField(
          controller: assigneeCtrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Collaborateur / Tech Lead',
            hintText: 'Ex: Thomas R. (DevOps)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentIndigo),
            onPressed: () async {
              if (assigneeCtrl.text.trim().isNotEmpty) {
                await ref
                    .read(taskRepositoryProvider)
                    .delegateTask(taskId, assigneeCtrl.text);
                ref.read(appNotificationsProvider.notifier).pushNotification(
                      title: '📤 Tâche déléguée à ${assigneeCtrl.text.trim()}',
                      body:
                          'Déplacée dans l\'onglet « Délégué » avec visibilité Équipe (TEAM).',
                      type: AppNotificationType.delegation,
                    );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('Déléguer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }
}
