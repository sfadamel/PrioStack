import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../providers/priostack_providers.dart';
import 'active_stack_panel.dart';
import 'sync_reorderable_list.dart';

/// Zone 3 (Droite sur PC) : "Triage, Bouclier Manager & Backlog Réalisé" (4 Onglets)
/// - Onglet 🔥 Urgences : File triée par criticité avec "Prendre maintenant (PUSH)" ou "Déléguer"
/// - Onglet 🧑‍💻 Assistance : Demandes d'assistance à traiter par lots (Batch)
/// - Onglet 📤 Délégué : Suivi des tâches confiées à l'équipe
/// - Onglet ✅ Backlog (Fait) : Historique de tout ce qui a été réalisé avec possibilité de rendre de nouveau actif
class TriageShieldPanel extends ConsumerStatefulWidget {
  const TriageShieldPanel({super.key});

  @override
  ConsumerState<TriageShieldPanel> createState() => _TriageShieldPanelState();
}

class _TriageShieldPanelState extends ConsumerState<TriageShieldPanel> {
  int _selectedTabIndex = 0;

  static const _tabs = [
    (TaskType.urgence, '🔥 Urgences'),
    (TaskType.devBlock, '🧑‍💻 Assistance'),
    (TaskType.delegated, '📤 Délégué'),
    (null, '✅ Backlog'),
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
        radius: 24,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tête Bouclier Manager ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bouclier & Backlog',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Triage, Assistance & Historique réactivable',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AppTheme.neumorphicCard(
                  color: AppTheme.surfaceElevated,
                  radius: 12,
                  isElevated: false,
                ),
                child: const Icon(
                  Icons.shield_moon_rounded,
                  color: AppTheme.accentIndigo,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // --- Sélecteur des 4 Onglets (Urgences | Assistance | Délégué | ✅ Backlog) ---
          Container(
            padding: const EdgeInsets.all(4),
            decoration: AppTheme.neumorphicInset(radius: 14),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final (type, label) = _tabs[index];
                final isSelected = _selectedTabIndex == index;
                final countAsync = type == null
                    ? ref.watch(completedTasksProvider)
                    : ref.watch(triageTasksByTypeProvider(type));
                final count = countAsync.valueOrNull?.length ?? 0;
                final badgeColor = type?.accentColor ?? AppTheme.accentBlue;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentBlue.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
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
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? Colors.white : badgeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // --- Sous-titre contextuel selon l'onglet actif ---
          _buildTabBanner(activeType),
          const SizedBox(height: 10),

          // --- Liste des cartes de l'onglet sélectionné ---
          Expanded(
            child: tasksAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      isCompletedBacklogTab
                          ? 'Aucune tâche terminée dans le Backlog pour le moment.'
                          : 'Aucun élément dans ${_tabs[_selectedTabIndex].$2}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: isCompletedBacklogTab
                          ? _buildCompletedBacklogCard(context, item, index)
                          : _buildTriageCard(context, item, activeType!, index),
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

  Widget _buildTabBanner(TaskType? type) {
    String text;
    IconData icon;
    Color color;

    if (type == null) {
      text = 'Glisser ⠿ pour ordonner • Réactivables en 1 clic vers la File ou la Pile';
      icon = Icons.history_rounded;
      color = AppTheme.accentBlue;
    } else {
      color = type.accentColor;
      switch (type) {
        case TaskType.urgence:
          text = 'Glisser ⠿ pour ordonner • PUSH sur la pile ou Déléguer';
          icon = Icons.local_fire_department_rounded;
          break;
        case TaskType.devBlock:
          text = 'Glisser ⠿ pour ordonner • Traite ces sollicitations par lots';
          icon = Icons.terminal_rounded;
          break;
        case TaskType.delegated:
          text = 'Glisser ⠿ pour ordonner • Suivi des livrables confiés à l\'équipe';
          icon = Icons.outbox_rounded;
          break;
        case TaskType.deepWork:
          text = '';
          icon = Icons.work_rounded;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte du Backlog des éléments déjà réalisés avec actions de réactivation
  Widget _buildCompletedBacklogCard(
    BuildContext context,
    TaskWithMilestones item,
    int index,
  ) {
    final task = item.task;
    final taskType = TaskType.fromDb(task.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.surfaceCard,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Poignée Drag + Badge Type d'origine + Réf AzDO + Statut Terminé + Supprimer
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
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: taskType.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: taskType.accentColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  taskType.label,
                  style: TextStyle(
                    color: taskType.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (task.externalRef != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.externalRef!,
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AppTheme.neonGreen),
              const SizedBox(width: 4),
              const Text(
                'FAIT',
                style: TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => ref.read(taskRepositoryProvider).deleteTask(task.id),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Titre de la tâche terminée
          Text(
            task.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (task.requesterOrAssignee != null) ...[
            const SizedBox(height: 4),
            Text(
              'Contexte / Source : ${task.requesterOrAssignee}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Actions pour rendre de nouveau actif
          Row(
            children: [
              // Action 1 : Remettre dans sa file active (ou réserve)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => ref
                      .read(taskRepositoryProvider)
                      .reactivateTask(task.id, placeInActiveStack: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderHighlight),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restore_rounded,
                            size: 14, color: AppTheme.textPrimary),
                        const SizedBox(width: 5),
                        Text(
                          'Rendre actif (File)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Action 2 : Remettre directement dans la Pile Active (Focus immédiat)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => ref
                      .read(taskRepositoryProvider)
                      .reactivateTask(task.id, placeInActiveStack: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Activer dans la Pile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.surfaceCard,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de carte : Poignée Drag + Interlocuteur + Ticket Azure DevOps + Supprimer
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
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: activeType.accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: activeType.accentColor.withValues(alpha: 0.6)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(task.requesterOrAssignee ?? 'P'),
                  style: TextStyle(
                    color: activeType.accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.requesterOrAssignee ?? 'Non assigné',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.externalRef != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.externalRef!,
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => ref.read(taskRepositoryProvider).deleteTask(task.id),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Sujet / Titre
          Text(
            task.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Barre d'actions selon l'onglet
          if (activeType == TaskType.urgence)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => showPushInterruptionDialog(
                      context,
                      ref,
                      existingUrgencyTaskId: task.id,
                      existingUrgencyTitle: task.title,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.urgencyGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '🚨 Prendre (PUSH)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showDelegateDialog(context, task.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderHighlight),
                    ),
                    child: Text(
                      '📤 Déléguer',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (activeType == TaskType.devBlock)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        ref.read(taskRepositoryProvider).completeTask(task.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.6)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✓ Traité (Batch)',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => showPushInterruptionDialog(
                    context,
                    ref,
                    existingUrgencyTaskId: task.id,
                    existingUrgencyTitle: task.title,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'PUSH',
                      style: TextStyle(
                        color: AppTheme.neonPink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Onglet 📤 Délégué / En attente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_rounded,
                        size: 13, color: AppTheme.neonPurple),
                    const SizedBox(width: 4),
                    Text(
                      'Visibilité : ${task.visibility.toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.neonPurple,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () =>
                      ref.read(taskRepositoryProvider).completeTask(task.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppTheme.borderHighlight),
                    ),
                    child: const Text(
                      ' Validé / Reçu ✓',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
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
          '📤 Déléguer à un membre de l\'équipe',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentIndigo),
            onPressed: () async {
              if (assigneeCtrl.text.trim().isNotEmpty) {
                await ref
                    .read(taskRepositoryProvider)
                    .delegateTask(taskId, assigneeCtrl.text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Déléguer', style: TextStyle(color: Colors.white)),
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
