import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/priostack_providers.dart';
import 'sync_reorderable_list.dart';

/// Zone 1 (Gauche sur PC) : Profil Architecte/Manager + "Morning Check-list" + Carte d'action rapide
/// Reprend fidèlement l'esthétique de la colonne gauche de la maquette Neumorphism (Sombre & Clair).
class MorningChecklistPanel extends ConsumerWidget {
  final VoidCallback onQuickCreatePressed;

  const MorningChecklistPanel({
    super.key,
    required this.onQuickCreatePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final checksAsync = ref.watch(morningChecksProvider);

    return Container(
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.bgMain,
        radius: 24,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tête Profil Manager (inspiré de "Vitaliy D. • Online" sur la maquette) ---
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Architecte & Manager',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.neonGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'SQLite Local • V2 Sync-Ready',
                          style: TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // --- Pilule active bleue électrique (comme "My project task" sur la maquette) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentBlue.withValues(alpha: 0.42),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rtl_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Morning Check-list',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                checksAsync.when(
                  data: (items) {
                    final done = items.where((i) => i.isChecked).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$done/${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --- En-tête de section + Boutons "+ Ajouter" & "Reset Jour" ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROUTINE QUOTIDIENNE',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  Tooltip(
                    message: 'Ajouter un point de contrôle dans la routine du matin',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showAddCheckDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded,
                                size: 13, color: AppTheme.accentBlue),
                            SizedBox(width: 3),
                            Text(
                              'Ajouter',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Réinitialiser la check-list pour une nouvelle journée',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => ref.read(taskRepositoryProvider).resetMorningChecklist(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderHighlight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.refresh_rounded,
                                size: 13, color: AppTheme.accentBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Reset Jour',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
          const SizedBox(height: 10),

          // --- Liste des vérifications récurrentes dans une carte Neumorphique ---
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.neumorphicCard(
                color: AppTheme.surfaceCard,
                radius: 18,
              ),
              child: checksAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aucune routine configurée.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddCheckDialog(context, ref),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Ajouter un contrôle'),
                          ),
                        ],
                      ),
                    );
                  }
                  return SyncReorderableList(
                    items: items,
                    idOf: (item) => 'morning_${item.id}',
                    onReordered: (reordered) {
                      ref.read(taskRepositoryProvider).reorderMorningChecks(
                            reordered.map((e) => e.id).toList(),
                          );
                    },
                    itemBuilder: (context, item, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => ref
                              .read(taskRepositoryProvider)
                              .toggleMorningCheck(item.id, !item.isChecked),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
                            decoration: BoxDecoration(
                              color: item.isChecked
                                  ? AppTheme.bgMain.withValues(alpha: 0.6)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isChecked
                                    ? AppTheme.neonGreen.withValues(alpha: 0.35)
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6, top: 1),
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        size: 17,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  width: 19,
                                  height: 19,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: item.isChecked
                                        ? AppTheme.neonGreen
                                        : AppTheme.surfaceInput,
                                    border: Border.all(
                                      color: item.isChecked
                                          ? AppTheme.neonGreen
                                          : AppTheme.borderHighlight,
                                    ),
                                  ),
                                  child: item.isChecked
                                      ? const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.black)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: item.isChecked
                                              ? AppTheme.textMuted
                                              : AppTheme.textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          decoration: item.isChecked
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgDeep,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => ref
                                      .read(taskRepositoryProvider)
                                      .deleteMorningCheckItem(item.id),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppTheme.textMuted,
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
              ),
            ),
          ),
          const SizedBox(height: 14),

          // --- Carte inférieure "Create new task" avec bouton '+' lumineux bleu ---
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onQuickCreatePressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: AppTheme.neumorphicCard(
                color: AppTheme.surfaceCard,
                radius: 18,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withValues(alpha: 0.55),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture Éclair (Ctrl + K)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Urgence, Assistance ou Fond',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(18),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
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
