import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/drift/app_database.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';
import 'create_deep_work_dialog.dart';
import 'edit_task_dialog.dart';
import 'sync_reorderable_list.dart';

/// Boîte de dialogue réutilisable pour déclencher un PUSH d'interruption
/// (depuis le bouton central "Interruption (PUSH)" ou depuis l'onglet Urgences).
Future<void> showPushInterruptionDialog(
  BuildContext context,
  WidgetRef ref, {
  String? existingUrgencyTaskId,
  String? existingUrgencyTitle,
}) async {
  // 1. Pause immédiate du Chronomètre Focus
  await ref.read(focusTimerProvider.notifier).pauseTimer();

  final resumeNoteCtrl = TextEditingController();
  final urgencyTitleCtrl =
      TextEditingController(text: existingUrgencyTitle ?? '');
  final extRefCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppTheme.neonPink.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.urgencyGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PUSH Interruption sur la Pile',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Chronomètre Focus mis en pause automatiquement.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Note de reprise mentale (optionnelle) : où en étais-tu ?',
                    style: TextStyle(
                      color: AppTheme.neonAmber,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: AppTheme.neumorphicInset(radius: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextFormField(
                      controller: resumeNoteCtrl,
                      autofocus: true,
                      maxLines: 2,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Optionnel : sauvegarde en 1 phrase ton point d\'arrêt pour reprendre sans effort...',
                        hintStyle:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '2. Urgence à empiler au sommet (ACTIVE TOP)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: AppTheme.neumorphicInset(radius: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: urgencyTitleCtrl,
                      enabled: existingUrgencyTaskId == null,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      validator: (val) {
                        if (existingUrgencyTaskId == null &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Indique l\'intitulé de l\'urgence.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Ex: Incident P1 — Timeout API Passerelle Paiement',
                        hintStyle:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (existingUrgencyTaskId == null) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.neumorphicInset(radius: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        controller: extRefCtrl,
                        style:
                            TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Ticket Azure DevOps (optionnel, ex: AB#9012)',
                          hintStyle:
                              TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isSubmitting
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSubmitting = true);
                    try {
                      await ref.read(taskRepositoryProvider).pushInterruption(
                            resumeNote: resumeNoteCtrl.text,
                            existingUrgencyTaskId: existingUrgencyTaskId,
                            newUrgencyTitle: existingUrgencyTaskId == null
                                ? urgencyTitleCtrl.text
                                : null,
                            externalRef: extRefCtrl.text,
                          );
                      final pushedTitle =
                          existingUrgencyTitle ?? urgencyTitleCtrl.text.trim();
                      final noteTrimmed = resumeNoteCtrl.text.trim();
                      ref.read(appNotificationsProvider.notifier).pushNotification(
                            title: '🚨 Interruption empilée (PUSH) : $pushedTitle',
                            body: noteTrimmed.isNotEmpty
                                ? 'Contexte sauvegardé : "$noteTrimmed"'
                                : 'Tâche précédente mise en pause dans la pile.',
                            type: AppNotificationType.stackPush,
                          );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }

                      // Bascule automatique vers le Cockpit / Sanctuaire de focus
                      ref
                          .read(cockpitMainViewProvider.notifier)
                          .setView(CockpitMainView.cockpit);

                      // Si une tâche existante est poussée, démarrer automatiquement le chrono
                      if (existingUrgencyTaskId != null) {
                        ref
                            .read(focusTimerProvider.notifier)
                            .startTimer(existingUrgencyTaskId, initialElapsed: 0);
                      }
                    } catch (err) {
                      if (ctx.mounted) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur PUSH: $err'),
                            backgroundColor: AppTheme.neonPink,
                          ),
                        );
                      }
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: AppTheme.urgencyGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSubmitting) ...[
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
                  Text(
                    isSubmitting
                        ? 'Empilement en cours...'
                        : 'Sauvegarder Contexte & PUSH',
                    style: const TextStyle(
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
    ),
  );
}

/// Zone 2 (Centre sur PC) : "La Pile Active" — Sanctuaire de Focus épuré (style Linear / Things 3)
class ActiveStackPanel extends ConsumerStatefulWidget {
  const ActiveStackPanel({super.key});

  @override
  ConsumerState<ActiveStackPanel> createState() => _ActiveStackPanelState();
}

class _ActiveStackPanelState extends ConsumerState<ActiveStackPanel> {
  bool _showReserveDrawer = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final stackAsync = ref.watch(activeStackProvider);
    final backlogAsync = ref.watch(backlogDeepWorkProvider);
    final completedAsync = ref.watch(completedTasksProvider);

    final backlogList = backlogAsync.valueOrNull ?? const [];

    return Container(
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.bgMain,
        radius: 16,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tête épuré ---
          _buildHeader(
            context,
            ref,
            stackAsync.valueOrNull ?? const [],
            backlogList.length,
          ),
          const SizedBox(height: 14),

          // --- Corps de la Pile Active (100% largeur, sans ligne latérale encombrante) ---
          Expanded(
            child: stackAsync.when(
              data: (stackItems) {
                if (stackItems.isEmpty) {
                  return _buildEmptyStackState(
                    context,
                    ref,
                    backlogList,
                    completedAsync.valueOrNull ?? const [],
                  );
                }

                final topItem = stackItems.first;
                final pausedItems = stackItems.skip(1).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 1. CARTE FOCUS AU SOMMET DE LA PILE
                    _buildTopActiveCard(
                      context,
                      ref,
                      topItem,
                      stackItems.length,
                    ),

                    // 2. CARTES EN SOMMEIL SOUS LE SOMMET (si PUSH actif)
                    if (pausedItems.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.layers_outlined,
                                size: 14, color: AppTheme.neonAmber),
                            const SizedBox(width: 6),
                            Text(
                              'EN SOMMEIL DANS LA PILE (${pausedItems.length})',
                              style: const TextStyle(
                                color: AppTheme.neonAmber,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...pausedItems.map(
                        (paused) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildPausedStackCard(context, ref, paused),
                        ),
                      ),
                    ],

                    // 3. RÉSERVE TÂCHES DE FOND (Tiroir repliable discret)
                    if (backlogList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildCollapsibleBacklogSwitcher(
                        context,
                        ref,
                        backlogList,
                      ),
                    ],
                  ],
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

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithMilestones> stackItems,
    int reserveCount,
  ) {
    final isUrgencyOnTop = stackItems.isNotEmpty &&
        stackItems.first.task.status == TaskStackStatus.activeTop.dbValue;

    return Row(
      children: [
        Icon(
          Icons.layers_rounded,
          color: isUrgencyOnTop ? AppTheme.neonPink : AppTheme.accentBlue,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          'Pile Active',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Text(
            'WIP 1/1',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isUrgencyOnTop) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.neonPink.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.45)),
            ),
            child: Text(
              'Profondeur : ${stackItems.length}',
              style: const TextStyle(
                color: AppTheme.neonPink,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),

        // Bouton : + Tâche de Fond (avec jalons)
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => showCreateDeepWorkDialog(
            context,
            ref,
            onCreated: () => setState(() => _showReserveDrawer = true),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppTheme.accentBlue.withValues(alpha: 0.45),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.playlist_add_rounded, size: 16, color: AppTheme.accentBlue),
                SizedBox(width: 5),
                Text(
                  '+ Tâche de Fond',
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Bouton d'action sobre : Interruption (PUSH)
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => showPushInterruptionDialog(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
            decoration: BoxDecoration(
              color: AppTheme.neonPink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppTheme.neonPink.withValues(alpha: 0.45),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: AppTheme.neonPink),
                SizedBox(width: 4),
                Text(
                  'Interruption (PUSH)',
                  style: TextStyle(
                    color: AppTheme.neonPink,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActiveCard(
    BuildContext context,
    WidgetRef ref,
    TaskWithMilestones item,
    int stackDepth,
  ) {
    final task = item.task;
    final isUrgencyTop = task.status == TaskStackStatus.activeTop.dbValue;
    final accent = isUrgencyTop ? AppTheme.neonPink : AppTheme.accentBlue;
    final totalMilestonesMinutes = item.milestones.fold<int>(0, (sum, m) => sum + m.durationMinutes);
    final totalHoursStr = totalMilestonesMinutes >= 60
        ? '${totalMilestonesMinutes ~/ 60}h${(totalMilestonesMinutes % 60 > 0 ? (totalMilestonesMinutes % 60).toString().padLeft(2, '0') : '')}'
        : '${totalMilestonesMinutes}m';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgencyTop
              ? AppTheme.neonPink.withValues(alpha: 0.45)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fine barre de progression au sommet de la carte (proportionnelle à la durée des jalons)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: LinearProgressIndicator(
              value: item.completionRatio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne supérieure : Statut + Réf AzDO + %
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isUrgencyTop
                          ? 'INTERRUPTION AU SOMMET'
                          : 'FOCUS DU JOUR • TÂCHE DE FOND',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (task.externalRef != null &&
                        task.externalRef!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          task.externalRef!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Mini-barre de progression proportionnelle
                    SizedBox(
                      width: 54,
                      height: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: item.completionRatio.clamp(0.0, 1.0),
                          backgroundColor: AppTheme.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.completionPercent == 100
                                ? AppTheme.neonGreen
                                : accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.completionPercent}% complété',
                      style: TextStyle(
                        color: item.completionPercent == 100
                            ? AppTheme.neonGreen
                            : AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Titre de la tâche active (Typographie claire et aérée) + Bouton Modifier
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: "Modifier l'action / tâche",
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      color: AppTheme.textMuted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => showEditTaskDialog(context, ref, task),
                    ),
                  ],
                ),

                // --- Note de reprise mentale (sobre citation à bordure gauche ambre) ---
                if (task.resumeNote != null &&
                    task.resumeNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.neonAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: AppTheme.neonAmber, width: 3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Note de reprise mentale',
                                style: TextStyle(
                                  color: AppTheme.neonAmber,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task.resumeNote!,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => ref
                              .read(taskRepositoryProvider)
                              .acknowledgeResumeNote(task.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.neonAmber.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Repris ✓',
                              style: TextStyle(
                                color: AppTheme.neonAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // --- Barre Chronomètre Focus + Action de clôture/POP ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      // Isolation Consumer : Seul ce mini-widget se reconstruit chaque seconde,
                      // épargnant ainsi 100% du reste de l'écran et des listes de cartes.
                      Consumer(
                        builder: (context, ref, _) {
                          final timerState = ref.watch(focusTimerProvider);
                          final isTimerRunningOnThis =
                              timerState.isRunning && timerState.activeTaskId == task.id;
                          final totalSeconds = isTimerRunningOnThis
                              ? timerState.currentTotalSeconds
                              : task.elapsedSeconds;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTimerRunningOnThis
                                    ? Icons.timer_rounded
                                    : Icons.timer_outlined,
                                color: isTimerRunningOnThis
                                    ? AppTheme.neonGreen
                                    : AppTheme.textMuted,
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Tooltip(
                                message: 'Cliquer pour ajuster manuellement le temps',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _showEditChronoDialog(context, ref, task, totalSeconds),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatDuration(totalSeconds),
                                          style: TextStyle(
                                            color: isTimerRunningOnThis
                                                ? AppTheme.neonGreen
                                                : AppTheme.textPrimary,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 13,
                                          color: isTimerRunningOnThis
                                              ? AppTheme.neonGreen.withValues(alpha: 0.7)
                                              : AppTheme.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                borderRadius: BorderRadius.circular(7),
                                onTap: () => ref
                                    .read(focusTimerProvider.notifier)
                                    .toggleTimer(task.id, initialElapsed: task.elapsedSeconds),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isTimerRunningOnThis
                                        ? AppTheme.neonAmber.withValues(alpha: 0.15)
                                        : AppTheme.accentBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isTimerRunningOnThis
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 14,
                                        color: isTimerRunningOnThis
                                            ? AppTheme.neonAmber
                                            : AppTheme.accentBlue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isTimerRunningOnThis ? 'Pause' : 'Focus',
                                        style: TextStyle(
                                          color: isTimerRunningOnThis
                                              ? AppTheme.neonAmber
                                              : AppTheme.accentBlue,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Spacer(),
                      if (isUrgencyTop)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            await ref
                                .read(focusTimerProvider.notifier)
                                .pauseTimer();
                            await ref
                                .read(taskRepositoryProvider)
                                .popActiveTopTask(task.id);
                            ref
                                .read(appNotificationsProvider.notifier)
                                .pushNotification(
                                  title:
                                      '🎯 Urgence dépilée (POP) : ${task.title}',
                                  body:
                                      'Votre Tâche de Fond est de retour au premier plan avec sa Note de reprise.',
                                  type: AppNotificationType.stackPop,
                                );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 14, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  'Résoudre & POP',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () async {
                            await ref
                                .read(focusTimerProvider.notifier)
                                .pauseTimer();
                            await ref
                                .read(taskRepositoryProvider)
                                .completeTask(task.id);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 15, color: AppTheme.neonGreen),
                                SizedBox(width: 5),
                                Text(
                                  'Terminer',
                                  style: TextStyle(
                                    color: AppTheme.neonGreen,
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
                ),

                // --- MICRO-JALONS FLEXIBLES (Durée personnalisable & édition) ---
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MICRO-JALONS (${item.milestones.where((m) => m.isDone).length}/${item.milestones.length})${totalMilestonesMinutes > 0 ? " • $totalHoursStr total" : ""}',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () =>
                          _showAddMilestoneDialog(context, ref, task.id),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded,
                                size: 14, color: AppTheme.accentBlue),
                            SizedBox(width: 2),
                            Text(
                              'Ajouter jalon',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (item.milestones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Découpe cette tâche en étapes clés et choisis leur durée.',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                    ),
                  )
                else
                  SyncReorderableList(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    items: item.milestones,
                    idOf: (m) => 'milestone_${m.id}',
                    onReordered: (reordered) {
                      ref
                          .read(taskRepositoryProvider)
                          .reorderMicroMilestones(
                            task.id,
                            reordered.map((e) => e.id).toList(),
                          );
                    },
                    itemBuilder: (context, m, mIndex) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6.5),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.borderSubtle
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: mIndex,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    size: 14,
                                    color: AppTheme.textMuted
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                            // Case à cocher
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => ref
                                  .read(taskRepositoryProvider)
                                  .toggleMicroMilestone(m.id, !m.isDone),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: m.isDone
                                      ? AppTheme.neonGreen
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: m.isDone
                                        ? AppTheme.neonGreen
                                        : AppTheme.borderHighlight,
                                    width: 1.3,
                                  ),
                                ),
                                child: m.isDone
                                    ? const Icon(Icons.check_rounded,
                                        size: 11, color: Colors.black)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Libellé cliquable pour modifier
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () => _showEditMilestoneDialog(context, ref, m),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m.title,
                                        style: TextStyle(
                                          color: m.isDone
                                              ? AppTheme.textMuted
                                              : AppTheme.textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: m.isDone
                                              ? FontWeight.w400
                                              : FontWeight.w500,
                                          decoration: m.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      if (m.isDone) ...[
                                        const SizedBox(height: 1.5),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 10,
                                              color: AppTheme.neonGreen,
                                            ),
                                            const SizedBox(width: 3.5),
                                            Text(
                                              'Fait ${_formatCompletionDateTime(m.updatedAt)}',
                                              style: const TextStyle(
                                                color: AppTheme.neonGreen,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Pastille Durée interactive (clic pour modifier)
                            InkWell(
                              borderRadius: BorderRadius.circular(5),
                              onTap: () => _showEditMilestoneDialog(context, ref, m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: AppTheme.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 10.5,
                                      color: m.isDone ? AppTheme.textMuted : AppTheme.accentBlue,
                                    ),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      '${m.durationMinutes}m',
                                      style: TextStyle(
                                        color: m.isDone
                                            ? AppTheme.textMuted
                                            : AppTheme.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Bouton Édition (crayon)
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _showEditMilestoneDialog(context, ref, m),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            // Bouton Supprimer
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => ref
                                  .read(taskRepositoryProvider)
                                  .deleteMicroMilestone(m.id),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 13.5,
                                  color: AppTheme.textMuted
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte compacte d'une tâche mise en sommeil dans la pile suite à un PUSH d'urgence
  Widget _buildPausedStackCard(
    BuildContext context,
    WidgetRef ref,
    TaskWithMilestones pausedItem,
  ) {
    final task = pausedItem.task;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pause_circle_filled_rounded,
                  size: 14, color: AppTheme.neonAmber),
              const SizedBox(width: 6),
              const Text(
                'EN PAUSE (ATTENTE POP)',
                style: TextStyle(
                  color: AppTheme.neonAmber,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${pausedItem.completionPercent}% • ${_formatDuration(task.elapsedSeconds)}',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Modifier l'action / tâche",
                icon: const Icon(Icons.edit_outlined, size: 14),
                color: AppTheme.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => showEditTaskDialog(context, ref, task),
              ),
            ],
          ),
          if (task.resumeNote != null && task.resumeNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '↳ "${task.resumeNote}"',
              style: const TextStyle(
                color: AppTheme.neonAmber,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tiroir repliable sobre pour permuter avec les tâches de fond en réserve
  Widget _buildCollapsibleBacklogSwitcher(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithMilestones> backlogDeepWork,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                setState(() => _showReserveDrawer = !_showReserveDrawer),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _showReserveDrawer
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tâches de Fond en attente (${backlogDeepWork.length})',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => showCreateDeepWorkDialog(
                      context,
                      ref,
                      onCreated: () => setState(() => _showReserveDrawer = true),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 13, color: AppTheme.accentBlue),
                          SizedBox(width: 3),
                          Text(
                            'Nouvelle tâche',
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
                  const SizedBox(width: 8),
                  Text(
                    _showReserveDrawer ? 'Masquer' : 'Permuter Focus',
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showReserveDrawer) ...[
            Divider(height: 1, color: AppTheme.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: SyncReorderableList(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                items: backlogDeepWork,
                idOf: (item) => 'reserve_${item.task.id}',
                onReordered: (reordered) {
                  ref.read(taskRepositoryProvider).reorderTasks(
                        reordered.map((e) => e.task.id).toList(),
                      );
                },
                itemBuilder: (context, item, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.task.title,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.milestones.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Text(
                              '${item.milestones.length} jalons',
                              style: const TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        IconButton(
                          tooltip: "Modifier l'action / tâche",
                          icon: const Icon(Icons.edit_outlined, size: 13),
                          color: AppTheme.textMuted,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () => showEditTaskDialog(context, ref, item.task),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => ref
                              .read(taskRepositoryProvider)
                              .activateDeepWorkTask(item.task.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentBlue.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Activer',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => ref
                              .read(taskRepositoryProvider)
                              .deleteTask(item.task.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStackState(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithMilestones> backlog,
    List<TaskWithMilestones> completed,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_outlined,
                size: 36, color: AppTheme.accentBlue),
            const SizedBox(height: 10),
            Text(
              'La Pile Active est libre',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Active une Tâche de Fond ci-dessous ou crée-en une nouvelle avec ses jalons.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
              onPressed: () => showCreateDeepWorkDialog(context, ref),
              icon: const Icon(Icons.playlist_add_rounded, size: 16),
              label: const Text(
                'Créer une Tâche de Fond (Jalons)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            if (backlog.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...backlog.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(taskRepositoryProvider)
                        .activateDeepWorkTask(b.task.id),
                    icon: const Icon(Icons.play_arrow_rounded,
                        size: 16, color: AppTheme.accentBlue),
                    label: Text(
                      b.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMilestoneDialog(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    await _showMilestoneDialog(
      context: context,
      ref: ref,
      dialogTitle: 'Nouveau Jalon',
      confirmButtonLabel: 'Ajouter',
      initialTitle: '',
      initialDuration: 30,
      onConfirm: (title, durationMinutes) async {
        await ref
            .read(taskRepositoryProvider)
            .addMicroMilestone(taskId, title, durationMinutes: durationMinutes);
      },
    );
  }

  Future<void> _showEditMilestoneDialog(
    BuildContext context,
    WidgetRef ref,
    MicroMilestone milestone,
  ) async {
    await _showMilestoneDialog(
      context: context,
      ref: ref,
      dialogTitle: 'Modifier le Jalon',
      confirmButtonLabel: 'Enregistrer',
      initialTitle: milestone.title,
      initialDuration: milestone.durationMinutes,
      onConfirm: (title, durationMinutes) async {
        await ref
            .read(taskRepositoryProvider)
            .updateMicroMilestone(
              milestone.id,
              title: title,
              durationMinutes: durationMinutes,
            );
      },
    );
  }

  Future<void> _showMilestoneDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String dialogTitle,
    required String confirmButtonLabel,
    String initialTitle = '',
    int initialDuration = 30,
    required Future<void> Function(String title, int durationMinutes) onConfirm,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final durationCtrl = TextEditingController(text: initialDuration.toString());
    int selectedDuration = initialDuration;
    final presets = [15, 30, 45, 60, 90, 120, 180, 240];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderHighlight),
          ),
          title: Text(
            dialogTitle,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Libellé du jalon',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: Déploiement des conteneurs Docker',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Durée estimée',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$selectedDuration min (${selectedDuration >= 60 ? "${selectedDuration ~/ 60}h${(selectedDuration % 60 > 0 ? (selectedDuration % 60).toString().padLeft(2, '0') : '')}" : "${selectedDuration}m"})',
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets.map((p) {
                      final isSelected = selectedDuration == p;
                      final label = p < 60
                          ? '${p}m'
                          : (p % 60 == 0 ? '${p ~/ 60}h' : '${p ~/ 60}h${p % 60}');
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            selectedDuration = p;
                            durationCtrl.text = p.toString();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentBlue : AppTheme.bgDeep,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppTheme.accentBlue : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Durée personnalisée :',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        height: 32,
                        child: TextField(
                          controller: durationCtrl,
                          keyboardType: TextInputType.text,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'ex: 1h30',
                            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            suffixText: 'min',
                            suffixStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            filled: true,
                            fillColor: AppTheme.bgDeep,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppTheme.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppTheme.accentBlue),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = _parseDurationInput(val);
                            if (parsed != null && parsed > 0) {
                              setState(() {
                                selectedDuration = parsed;
                              });
                            }
                          },
                        ),
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
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final trimmed = titleCtrl.text.trim();
                if (trimmed.isNotEmpty) {
                  await onConfirm(trimmed, selectedDuration);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(confirmButtonLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  /// Boîte de dialogue permettant à l'utilisateur d'ajuster manuellement le chronomètre
  Future<void> _showEditChronoDialog(
    BuildContext context,
    WidgetRef ref,
    PrioTask task,
    int currentSeconds,
  ) async {
    final currentHours = currentSeconds ~/ 3600;
    final currentMinutes = (currentSeconds % 3600) ~/ 60;
    final hoursCtrl = TextEditingController(text: currentHours.toString());
    final minutesCtrl = TextEditingController(text: currentMinutes.toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final h = int.tryParse(hoursCtrl.text) ?? 0;
          final m = int.tryParse(minutesCtrl.text) ?? 0;
          final previewTotal = (h * 3600) + (m * 60);

          void updateValues(int newHours, int newMinutes) {
            setState(() {
              hoursCtrl.text = newHours.toString();
              minutesCtrl.text = newMinutes.toString();
            });
          }

          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.borderHighlight),
            ),
            title: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.accentBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ajuster le chronomètre',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      // Champ Heures
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Heures',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: hoursCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                suffixText: 'h',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: AppTheme.bgDeep,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppTheme.borderSubtle),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Champ Minutes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minutes',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: minutesCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                suffixText: 'min',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: AppTheme.bgDeep,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppTheme.borderSubtle),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Raccourcis rapides
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickAdjustChip('+15m', () {
                        final curH = int.tryParse(hoursCtrl.text) ?? 0;
                        final curM = int.tryParse(minutesCtrl.text) ?? 0;
                        final totalM = (curH * 60) + curM + 15;
                        updateValues(totalM ~/ 60, totalM % 60);
                      }),
                      _buildQuickAdjustChip('+30m', () {
                        final curH = int.tryParse(hoursCtrl.text) ?? 0;
                        final curM = int.tryParse(minutesCtrl.text) ?? 0;
                        final totalM = (curH * 60) + curM + 30;
                        updateValues(totalM ~/ 60, totalM % 60);
                      }),
                      _buildQuickAdjustChip('+1h', () {
                        final curH = int.tryParse(hoursCtrl.text) ?? 0;
                        final curM = int.tryParse(minutesCtrl.text) ?? 0;
                        updateValues(curH + 1, curM);
                      }),
                      _buildQuickAdjustChip('+2h', () {
                        final curH = int.tryParse(hoursCtrl.text) ?? 0;
                        final curM = int.tryParse(minutesCtrl.text) ?? 0;
                        updateValues(curH + 2, curM);
                      }),
                      _buildQuickAdjustChip('Reset (0s)', () {
                        updateValues(0, 0);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nouveau temps total :',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(previewTotal),
                          style: const TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final h = int.tryParse(hoursCtrl.text) ?? 0;
                  final m = int.tryParse(minutesCtrl.text) ?? 0;
                  final totalSecs = (h * 3600) + (m * 60);
                  await ref.read(focusTimerProvider.notifier).setManualElapsedSeconds(task.id, totalSecs);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAdjustChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  int? _parseDurationInput(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('h')) {
      final parts = trimmed.split('h');
      final hours = double.tryParse(parts[0].trim().replaceAll(',', '.'));
      if (hours != null) {
        int extraMinutes = 0;
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          extraMinutes = int.tryParse(parts[1].trim().replaceAll('min', '').replaceAll('m', '')) ?? 0;
        }
        return (hours * 60).round() + extraMinutes;
      }
    }
    return int.tryParse(trimmed.replaceAll('min', '').replaceAll('m', ''));
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatCompletionDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) {
      return "Aujourd'hui à $timeStr";
    } else if (isYesterday) {
      return "Hier à $timeStr";
    } else {
      final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      return '$dateStr à $timeStr';
    }
  }
}
