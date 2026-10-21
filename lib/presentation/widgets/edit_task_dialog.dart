import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/drift/app_database.dart';
import '../providers/priostack_providers.dart';

/// Boîte de dialogue universelle pour modifier n'importe quelle action / tâche dans PrioStack
Future<void> showEditTaskDialog(
  BuildContext context,
  WidgetRef ref,
  PrioTask task,
) async {
  final titleCtrl = TextEditingController(text: task.title);
  final externalRefCtrl = TextEditingController(text: task.externalRef ?? '');
  final requesterCtrl = TextEditingController(text: task.requesterOrAssignee ?? '');
  int selectedCriticality = task.criticality;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderHighlight),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppTheme.accentBlue, size: 22),
            const SizedBox(width: 8),
            Text(
              "Modifier l'action / la tâche",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  "Intitulé de l'action / tâche *",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Description de l'action...",
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.bgDeep,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.accentBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Ligne Réf Externe + Demandeur
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Réf. Externe",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: externalRefCtrl,
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Ex: AB#1234",
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              filled: true,
                              fillColor: AppTheme.bgDeep,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.borderSubtle),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Demandeur / Responsable",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: requesterCtrl,
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Ex: @Client",
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              filled: true,
                              fillColor: AppTheme.bgDeep,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.borderSubtle),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Niveau de priorité / criticité
                Text(
                  "Criticité & Priorité",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityChoice(
                      label: "Normal",
                      level: 1,
                      color: AppTheme.accentBlue,
                      isSelected: selectedCriticality == 1,
                      onTap: () => setState(() => selectedCriticality = 1),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityChoice(
                      label: "Haute",
                      level: 2,
                      color: AppTheme.neonAmber,
                      isSelected: selectedCriticality == 2,
                      onTap: () => setState(() => selectedCriticality = 2),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityChoice(
                      label: "Critique",
                      level: 3,
                      color: AppTheme.neonPink,
                      isSelected: selectedCriticality == 3,
                      onTap: () => setState(() => selectedCriticality = 3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newTitle = titleCtrl.text.trim();
              if (newTitle.isNotEmpty) {
                await ref.read(taskRepositoryProvider).updateTask(
                      task.id,
                      title: newTitle,
                      externalRef: externalRefCtrl.text.trim(),
                      requesterOrAssignee: requesterCtrl.text.trim(),
                      criticality: selectedCriticality,
                    );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPriorityChoice({
  required String label,
  required int level,
  required Color color,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.bgDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
