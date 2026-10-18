import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/priostack_providers.dart';
import 'calendar_panel.dart';
import 'sync_reorderable_list.dart';

/// Zone 1 (Gauche sur PC) : Colonne épurée "Routine & Agenda du jour"
/// Utilise un sélecteur segmenté (☀️ Routine | 📅 Agenda) pour offrir 100% de la hauteur
/// disponible à chaque liste sans écrasement vertical ni boîtes redondantes.
class MorningChecklistPanel extends ConsumerStatefulWidget {
  final VoidCallback onQuickCreatePressed;

  const MorningChecklistPanel({
    super.key,
    required this.onQuickCreatePressed,
  });

  @override
  ConsumerState<MorningChecklistPanel> createState() =>
      _MorningChecklistPanelState();
}

class _MorningChecklistPanelState extends ConsumerState<MorningChecklistPanel> {
  int _selectedSubView = 0; // 0 = Routine Matinale, 1 = Agenda du Jour

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final checksAsync = ref.watch(morningChecksProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final now = DateTime.now();

    final checksList = checksAsync.valueOrNull ?? const [];
    final doneChecks = checksList.where((c) => c.isChecked).length;

    final todayEvents = (eventsAsync.valueOrNull ?? const [])
        .where((e) => e.isSameDay(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.bgMain,
        radius: 16,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tête épuré + Sélecteur segmenté (Routine | Agenda) ---
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentTab(
                    index: 0,
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Routine',
                    badgeText: '$doneChecks/${checksList.length}',
                  ),
                ),
                Expanded(
                  child: _buildSegmentTab(
                    index: 1,
                    icon: Icons.calendar_today_rounded,
                    label: 'Agenda',
                    badgeText: '${todayEvents.length}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --- Barre d'actions contextuelle fine ---
          if (_selectedSubView == 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'POINTS DE CONTRÔLE',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                Row(
                  children: [
                    _buildHeaderActionButton(
                      icon: Icons.add_rounded,
                      label: 'Ajouter',
                      color: AppTheme.accentBlue,
                      onTap: () => _showAddCheckDialog(context, ref),
                    ),
                    const SizedBox(width: 6),
                    _buildHeaderActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      color: AppTheme.textSecondary,
                      onTap: () => ref
                          .read(taskRepositoryProvider)
                          .resetMorningChecklist(),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PLANNING DU JOUR',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                Row(
                  children: [
                    _buildHeaderActionButton(
                      icon: Icons.add_rounded,
                      label: 'Réunion',
                      color: AppTheme.accentBlue,
                      onTap: () => showAddOrEditCalendarEventDialog(
                        context,
                        ref,
                        initialDate: now,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildHeaderActionButton(
                      icon: Icons.open_in_new_rounded,
                      label: 'Mois',
                      color: AppTheme.textSecondary,
                      onTap: () => ref
                          .read(cockpitMainViewProvider.notifier)
                          .setView(CockpitMainView.calendar),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 10),

          // --- Corps principal occupant 100% de la hauteur restante ---
          Expanded(
            child: _selectedSubView == 0
                ? _buildRoutineList(context, checksAsync)
                : _buildAgendaList(context, todayEvents),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required IconData icon,
    required String label,
    required String badgeText,
  }) {
    final isSelected = _selectedSubView == index;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedSubView = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppTheme.borderHighlight, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.accentBlue : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentBlue.withValues(alpha: 0.14)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.accentBlue : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12.5, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineList(
    BuildContext context,
    AsyncValue<List<dynamic>> checksAsync,
  ) {
    return checksAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Aucune routine configurée.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          );
        }

        return SyncReorderableList(
          items: items,
          idOf: (item) => 'morning_${item.id}',
          onReordered: (reordered) {
            ref.read(taskRepositoryProvider).reorderMorningChecks(
                  reordered.map<String>((e) => e.id as String).toList(),
                );
          },
          itemBuilder: (context, item, index) {
            final bool isChecked = item.isChecked as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => ref
                    .read(taskRepositoryProvider)
                    .toggleMorningCheck(item.id as String, !isChecked),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppTheme.surfaceCard.withValues(alpha: 0.45)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked
                          ? AppTheme.borderSubtle.withValues(alpha: 0.5)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Row(
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
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: isChecked
                              ? AppTheme.neonGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: isChecked
                                ? AppTheme.neonGreen
                                : AppTheme.borderHighlight,
                            width: 1.3,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(Icons.check_rounded,
                                size: 12, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isChecked
                                    ? AppTheme.textMuted
                                    : AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.category as String,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => ref
                            .read(taskRepositoryProvider)
                            .deleteMorningCheckItem(item.id as String),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildAgendaList(BuildContext context, List<dynamic> todayEvents) {
    if (todayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 28,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune réunion prévue aujourd\'hui.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: todayEvents.length,
      itemBuilder: (ctx, idx) {
        final ev = todayEvents[idx];
        final Color accent = ev.category.accentColor as Color;
        final bool isCompleted = ev.isCompleted as bool;

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              ref
                  .read(selectedCalendarDateProvider.notifier)
                  .selectDate(ev.startTime as DateTime);
              ref
                  .read(cockpitMainViewProvider.notifier)
                  .setView(CockpitMainView.calendar);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.surfaceCard.withValues(alpha: 0.45)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.textMuted : accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev.formattedTimeRange as String,
                          style: TextStyle(
                            color: isCompleted ? AppTheme.textMuted : accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ev.title as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCompleted
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => ref
                        .read(taskRepositoryProvider)
                        .toggleCalendarEventCompleted(
                            ev.id as String, !isCompleted),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isCompleted
                          ? AppTheme.neonGreen
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddCheckDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Infra & Ops');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderHighlight),
        ),
        title: Text(
          'Nouveau contrôle matinal',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Vérification à effectuer',
                hintText: 'Ex: Vérifier le lag des consumers Kafka',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                hintText: 'Ex: Monitoring / DB / Sécurité',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await ref
                    .read(taskRepositoryProvider)
                    .addMorningCheckItem(titleCtrl.text, catCtrl.text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
