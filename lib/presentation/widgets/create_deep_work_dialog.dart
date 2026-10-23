import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/milestone_input.dart';
import '../../domain/models/task_enums.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';

/// Boîte de dialogue pour créer une Tâche de Fond structurée avec ses micro-jalons,
/// orientée par défaut vers la mise en attente dans la pile (Backlog / Réserve).
Future<void> showCreateDeepWorkDialog(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onCreated,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _CreateDeepWorkDialog(onCreated: onCreated),
  );
}

class _CreateDeepWorkDialog extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;

  const _CreateDeepWorkDialog({this.onCreated});

  @override
  ConsumerState<_CreateDeepWorkDialog> createState() => _CreateDeepWorkDialogState();
}

class _CreateDeepWorkDialogState extends ConsumerState<_CreateDeepWorkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _externalRefController = TextEditingController();
  final _requesterController = TextEditingController();

  final _newMilestoneController = TextEditingController();
  int _newMilestoneDuration = 30;

  int _selectedCriticality = 2;
  TaskStackStatus _selectedDestination = TaskStackStatus.backlog;

  // Liste de jalons prévus
  final List<MilestoneInput> _milestones = [
    const MilestoneInput(title: 'Cadrage technique & analyse d\'impact', durationMinutes: 30),
    const MilestoneInput(title: 'Exécution du livrable principal', durationMinutes: 45),
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _externalRefController.dispose();
    _requesterController.dispose();
    _newMilestoneController.dispose();
    super.dispose();
  }

  void _addMilestone() {
    final text = _newMilestoneController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _milestones.add(
        MilestoneInput(
          title: text,
          durationMinutes: _newMilestoneDuration,
        ),
      );
      _newMilestoneController.clear();
      _newMilestoneDuration = 30;
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  int get _totalMilestonesMinutes =>
      _milestones.fold<int>(0, (sum, m) => sum + m.durationMinutes);

  String get _totalEstimatedTimeStr {
    final m = _totalMilestonesMinutes;
    if (m >= 60) {
      final h = m ~/ 60;
      final rem = m % 60;
      return rem > 0 ? '${h}h${rem.toString().padLeft(2, '0')}' : '${h}h';
    }
    return '$m min';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final title = _titleController.text.trim();
      final extRef = _externalRefController.text.trim();
      final requester = _requesterController.text.trim();

      await ref.read(taskRepositoryProvider).createDeepWorkTask(
            title: title,
            externalRef: extRef.isNotEmpty ? extRef : null,
            requesterOrAssignee: requester.isNotEmpty ? requester : null,
            criticality: _selectedCriticality,
            milestones: _milestones,
            status: _selectedDestination,
          );

      final isWaiting = _selectedDestination == TaskStackStatus.backlog;

      ref.read(appNotificationsProvider.notifier).pushNotification(
            title: isWaiting
                ? '⏳ Tâche de Fond ajoutée en attente'
                : '🚀 Tâche de Fond activée au sommet',
            body: '$title (${_milestones.length} jalons • $_totalEstimatedTimeStr)',
            type: AppNotificationType.taskCaptured,
          );

      widget.onCreated?.call();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création : $e'),
            backgroundColor: AppTheme.neonPink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppTheme.accentBlue.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.playlist_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouvelle Tâche de Fond',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Structuration avec jalons et mise en attente sans forcer l\'activation',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppTheme.textMuted,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Titre de la tâche
                Text(
                  '1. Intitulé de la Tâche de Fond *',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: AppTheme.neumorphicInset(radius: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: Spécification & implémentation passerelle Auth OIDC',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'L\'intitulé de la tâche est obligatoire.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Référence & Demandeur (Ligne double)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Référence (AZ#, Jira, Ticket)',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            decoration: AppTheme.neumorphicInset(radius: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              controller: _externalRefController,
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Optionnel (ex: AZ#7821)',
                                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demandeur / Assigné',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            decoration: AppTheme.neumorphicInset(radius: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              controller: _requesterController,
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Optionnel (ex: Équipe Data)',
                                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Niveau de Criticité
                Row(
                  children: [
                    Text(
                      'Criticité : ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(4, (i) {
                      final level = i + 1;
                      final isSelected = _selectedCriticality == level;
                      final labels = ['Normal', 'Important', 'Critique', 'Bloquant'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(labels[i]),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCriticality = level),
                          selectedColor: AppTheme.accentBlue.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Section Jalons de décomposition
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route_rounded, size: 15, color: AppTheme.accentBlue),
                          const SizedBox(width: 6),
                          Text(
                            'Jalons de décomposition (${_milestones.length})',
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (_milestones.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Text(
                                'Total : $_totalEstimatedTimeStr',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Liste des jalons existants
                      if (_milestones.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Aucun jalon défini. Vous pouvez en ajouter ci-dessous pour découper votre tâche.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _milestones.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final m = _milestones[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${m.durationMinutes}m',
                                      style: const TextStyle(
                                        color: AppTheme.accentBlue,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () => _removeMilestone(index),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 10),

                      // Ligne d'ajout d'un nouveau jalon
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: AppTheme.neumorphicInset(radius: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                controller: _newMilestoneController,
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                onSubmitted: (_) => _addMilestone(),
                                decoration: InputDecoration(
                                  hintText: 'Ajouter un jalon (ex: Validation recette)',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11.5,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sélecteur de durée rapide
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _newMilestoneDuration,
                                dropdownColor: AppTheme.surfaceCard,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: const Icon(Icons.arrow_drop_down, size: 16),
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text('15m')),
                                  DropdownMenuItem(value: 30, child: Text('30m')),
                                  DropdownMenuItem(value: 45, child: Text('45m')),
                                  DropdownMenuItem(value: 60, child: Text('1h')),
                                  DropdownMenuItem(value: 90, child: Text('1h30')),
                                  DropdownMenuItem(value: 120, child: Text('2h')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _newMilestoneDuration = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _addMilestone,
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accentBlue.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, size: 14, color: AppTheme.accentBlue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ajouter',
                                    style: TextStyle(
                                      color: AppTheme.accentBlue,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Statut / Destination de la tâche
                Text(
                  'Placement initial dans la Pile :',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selectedDestination = TaskStackStatus.backlog),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedDestination == TaskStackStatus.backlog
                          ? AppTheme.neonAmber.withValues(alpha: 0.12)
                          : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedDestination == TaskStackStatus.backlog
                            ? AppTheme.neonAmber.withValues(alpha: 0.5)
                            : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: _selectedDestination == TaskStackStatus.backlog
                              ? AppTheme.neonAmber
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⏳ En attente dans la pile / Réserve (Recommandé)',
                                style: TextStyle(
                                  color: _selectedDestination == TaskStackStatus.backlog
                                      ? AppTheme.neonAmber
                                      : AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'La tâche reste en attente et ne perturbe pas votre focus actuel.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedDestination == TaskStackStatus.backlog
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: _selectedDestination == TaskStackStatus.backlog
                              ? AppTheme.neonAmber
                              : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selectedDestination = TaskStackStatus.activeBase),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedDestination == TaskStackStatus.activeBase
                          ? AppTheme.accentBlue.withValues(alpha: 0.12)
                          : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedDestination == TaskStackStatus.activeBase
                            ? AppTheme.accentBlue.withValues(alpha: 0.5)
                            : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 16,
                          color: _selectedDestination == TaskStackStatus.activeBase
                              ? AppTheme.accentBlue
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚀 Activer immédiatement en Focus actif (WIP max 2)',
                                style: TextStyle(
                                  color: _selectedDestination == TaskStackStatus.activeBase
                                      ? AppTheme.accentBlue
                                      : AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Prend directement la place de tâche active à la base de la pile.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedDestination == TaskStackStatus.activeBase
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: _selectedDestination == TaskStackStatus.activeBase
                              ? AppTheme.accentBlue
                              : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Actions du bas
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isSubmitting ? null : _handleSubmit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSubmitting) ...[
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Text(
                              'Créer la Tâche de Fond',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
