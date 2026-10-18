import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';
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

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
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
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Note de reprise obligatoire : où en étais-tu exactement ?',
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
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Sauvegarde ton contexte mental en 1 phrase avant de basculer !';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Ex: Je vérifiais l\'index composite sur la table sync_outbox (ligne 142)...',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Annuler',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            if (!formKey.currentState!.validate()) return;
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
            ref.read(appNotificationsProvider.notifier).pushNotification(
                  title: '🚨 Interruption empilée (PUSH) : $pushedTitle',
                  body:
                      'Contexte sauvegardé : "${resumeNoteCtrl.text.trim()}"',
                  type: AppNotificationType.stackPush,
                );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: AppTheme.urgencyGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Sauvegarder Contexte & PUSH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ],
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
    final timerState = ref.watch(focusTimerProvider);

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
                      timerState,
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
    FocusTimerState timerState,
    int stackDepth,
  ) {
    final task = item.task;
    final isUrgencyTop = task.status == TaskStackStatus.activeTop.dbValue;
    final isTimerRunningOnThis =
        timerState.isRunning && timerState.activeTaskId == task.id;
    final totalSeconds = task.elapsedSeconds +
        (isTimerRunningOnThis ? (timerState.sessionSeconds % 5) : 0);
    final accent = isUrgencyTop ? AppTheme.neonPink : AppTheme.accentBlue;

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
          // Fine barre de progression au sommet de la carte (2px)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: LinearProgressIndicator(
              value: (item.completionPercent / 100).clamp(0.0, 1.0),
              minHeight: 3,
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
                    Text(
                      '${item.completionPercent}% complété',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Titre de la tâche active (Typographie claire et aérée)
                Text(
                  task.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
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
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () => ref
                            .read(focusTimerProvider.notifier)
                            .toggleTimer(task.id),
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

                // --- MICRO-JALONS DE 30 MINUTES (Liste épurée style Things 3 / Linear sans boîtes lourdes) ---
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JALONS DE 30 MINUTES (${item.milestones.where((m) => m.isDone).length}/${item.milestones.length})',
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
                      'Découpe cette tâche en sous-étapes de 30 minutes.',
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
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => ref
                            .read(taskRepositoryProvider)
                            .toggleMicroMilestone(m.id, !m.isDone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 7.5),
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
                              Container(
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
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
                              ),
                              Text(
                                '${m.durationMinutes}m',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () => ref
                                    .read(taskRepositoryProvider)
                                    .deleteMicroMilestone(m.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
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
          Text(
            task.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
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
                    'Réserve Tâches de Fond (${backlogDeepWork.length})',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
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
                        const SizedBox(width: 8),
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
              'Active une Tâche de Fond ci-dessous ou utilise la barre de commande (Ctrl+K).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text(
          'Nouveau Jalon (30 min)',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15.5),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Ex: Rédiger le schéma de séquence API',
          ),
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
              if (ctrl.text.trim().isNotEmpty) {
                await ref
                    .read(taskRepositoryProvider)
                    .addMicroMilestone(taskId, ctrl.text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
