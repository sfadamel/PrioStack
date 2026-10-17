import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/repositories/task_repository.dart';
import '../providers/priostack_providers.dart';
import 'sync_reorderable_list.dart';

/// Boîte de dialogue réutilisable pour déclencher un PUSH d'interruption
/// (depuis le bouton central "🚨 Interruption (PUSH Urgence)" ou depuis l'onglet Urgences).
Future<void> showPushInterruptionDialog(
  BuildContext context,
  WidgetRef ref, {
  String? existingUrgencyTaskId,
  String? existingUrgencyTitle,
}) async {
  // 1. Pause immédiate du Chronomètre Focus
  await ref.read(focusTimerProvider.notifier).pauseTimer();

  final resumeNoteCtrl = TextEditingController();
  final urgencyTitleCtrl = TextEditingController(text: existingUrgencyTitle ?? '');
  final extRefCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppTheme.neonPink.withValues(alpha: 0.65), width: 1.4),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.urgencyGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 PUSH Interruption sur la Pile',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Le chronomètre Focus a été mis en pause automatiquement.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ obligatoire : Note de reprise mentale
              const Text(
                '1. Note de reprise obligatoire : où en étais-tu exactement ?',
                style: TextStyle(
                  color: AppTheme.neonAmber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: AppTheme.neumorphicInset(radius: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Détails de l'urgence à placer au sommet de la pile
              Text(
                '2. Urgence à empiler au sommet (ACTIVE TOP)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: AppTheme.neumorphicInset(radius: 12),
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
                    hintText: 'Ex: Incident P1 — Timeout API Passerelle Paiement',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (existingUrgencyTaskId == null) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: AppTheme.neumorphicInset(radius: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: extRefCtrl,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Ticket Azure DevOps (optionnel, ex: AB#9012)',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
          borderRadius: BorderRadius.circular(12),
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
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppTheme.urgencyGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPink.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Sauvegarder Contexte & PUSH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Zone 2 (Centre sur PC) : "La Pile Active (The Stack)" — Sanctuaire & Gestion des Interruptions
class ActiveStackPanel extends ConsumerWidget {
  const ActiveStackPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final stackAsync = ref.watch(activeStackProvider);
    final backlogAsync = ref.watch(backlogDeepWorkProvider);
    final completedAsync = ref.watch(completedTasksProvider);
    final timerState = ref.watch(focusTimerProvider);

    return Container(
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.bgMain,
        radius: 24,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tête de la colonne centrale (Inspiré de "Task Manager" sur la maquette) ---
          _buildHeader(context, ref, stackAsync.valueOrNull ?? const []),
          const SizedBox(height: 16),

          // --- Corps de la Pile Active avec ligne verticale lumineuse (Call Stack) ---
          Expanded(
            child: stackAsync.when(
              data: (stackItems) {
                if (stackItems.isEmpty) {
                  return _buildEmptyStackState(
                    context,
                    ref,
                    backlogAsync.valueOrNull ?? [],
                    completedAsync.valueOrNull ?? [],
                  );
                }

                // Le premier élément (stackOrder le plus élevé) est au SOMMET de la pile
                final topItem = stackItems.first;
                final pausedItems = stackItems.skip(1).toList();

                return Stack(
                  children: [
                    // Fil vertical lumineux bleu au centre (comme la timeline 13:30 de la maquette)
                    Positioned(
                      left: 26,
                      top: 12,
                      bottom: 12,
                      child: Container(
                        width: 2.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentBlue,
                              AppTheme.accentIndigo.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentBlue.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cartes empilées de la Call Stack
                    ListView(
                      padding: const EdgeInsets.only(right: 4),
                      children: [
                        // Badge indicateur de profondeur de pile (Call Stack Pointer)
                        _buildStackPointerPill(stackItems.length, topItem),
                        const SizedBox(height: 12),

                        // 1. CARTE AU SOMMET DE LA PILE (Urgence active OU Tâche de fond active)
                        _buildTopActiveCard(context, ref, topItem, timerState),

                        // 2. CARTES EN PAUSE SOUS LE SOMMET (Tâche de fond mise en sommeil par PUSH)
                        if (pausedItems.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.only(left: 48, bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.layers_clear_rounded,
                                    size: 15, color: AppTheme.neonAmber),
                                const SizedBox(width: 6),
                                Text(
                                  'CONTEXTE EN SOMMEIL DANS LA PILE (${pausedItems.length})',
                                  style: const TextStyle(
                                    color: AppTheme.neonAmber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...pausedItems.map(
                            (paused) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildPausedStackCard(context, ref, paused),
                            ),
                          ),
                        ],

                        // 3. Tâches de fond en réserve (Backlog) pour permuter si besoin (WIP Limit = 1)
                        const SizedBox(height: 12),
                        _buildBacklogSwitcher(
                          context,
                          ref,
                          backlogAsync.valueOrNull ?? const [],
                        ),

                        // 4. Backlog des tâches déjà faites avec possibilité de les rendre de nouveau actives
                        const SizedBox(height: 12),
                        _buildCompletedHistorySection(
                          context,
                          ref,
                          completedAsync.valueOrNull ?? const [],
                        ),
                      ],
                    ),
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
  ) {
    final baseDeepWork = stackItems
        .where((i) => i.task.type == TaskType.deepWork.dbValue)
        .firstOrNull;
    final completion = baseDeepWork?.completionPercent ?? 0;

    return Row(
      children: [
        // Icône sanctuaire avec relief
        Container(
          width: 46,
          height: 46,
          decoration: AppTheme.neumorphicCard(
            color: AppTheme.surfaceElevated,
            radius: 15,
            glowColor: AppTheme.accentBlue,
          ),
          child: const Icon(
            Icons.stacked_bar_chart_rounded,
            color: AppTheme.accentBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La Pile Active (The Stack)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 13, color: AppTheme.neonAmber),
                  const SizedBox(width: 5),
                  Text(
                    'WIP Limit : 1 Tâche de Fond',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderHighlight),
                    ),
                    child: Text(
                      '$completion%',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bouton maître : 🚨 Interruption (PUSH Urgence)
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showPushInterruptionDialog(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppTheme.urgencyGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonPink.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.priority_high_rounded, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  '🚨 Interruption (PUSH)',
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
    );
  }

  Widget _buildStackPointerPill(int depth, TaskWithMilestones topItem) {
    final isUrgencyOnTop = topItem.task.status == TaskStackStatus.activeTop.dbValue;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isUrgencyOnTop ? AppTheme.neonPink : AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isUrgencyOnTop ? AppTheme.neonPink : AppTheme.accentBlue)
                    .withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            isUrgencyOnTop ? 'STACK DEPTH : $depth (URGENCE ACTIVE)' : 'STACK BASE : FOCUS ACTIF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
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
  ) {
    final task = item.task;
    final taskType = TaskType.fromDb(task.type);
    final isUrgencyTop = task.status == TaskStackStatus.activeTop.dbValue;
    final isTimerRunningOnThis =
        timerState.isRunning && timerState.activeTaskId == task.id;
    final totalSeconds = task.elapsedSeconds +
        (isTimerRunningOnThis ? (timerState.sessionSeconds % 5) : 0);

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        decoration: AppTheme.neumorphicCard(
          color: AppTheme.surfaceCard,
          radius: 22,
          glowColor: isUrgencyTop ? AppTheme.neonPink : AppTheme.accentBlue,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Barre latérale néon verticale (signature visuelle de la maquette Dribbble)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: isUrgencyTop ? AppTheme.neonPink : taskType.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isUrgencyTop ? AppTheme.neonPink : taskType.accentColor)
                            .withValues(alpha: 0.8),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne supérieure : Badge Type + Ticket Azure DevOps + % de complétion
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isUrgencyTop ? AppTheme.neonPink : taskType.accentColor)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (isUrgencyTop ? AppTheme.neonPink : taskType.accentColor)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            isUrgencyTop
                                ? '🔥 SOMMET DE PILE (INTERRUPTION EN COURS)'
                                : '🏗️ SANCTUAIRE — TÂCHE DE FOND DU JOUR',
                            style: TextStyle(
                              color: isUrgencyTop ? AppTheme.neonPink : taskType.accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (task.externalRef != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderHighlight),
                            ),
                            child: Text(
                              task.externalRef!,
                              style: const TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.completionPercent}%',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Titre de la tâche active
                    Text(
                      task.title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),

                    // --- BANNIÈRE DE NOTE DE REPRISE (Affichée en évidence après un POP !) ---
                    if (task.resumeNote != null && task.resumeNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neonAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.neonAmber.withValues(alpha: 0.75),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.bookmark_added_rounded,
                                color: AppTheme.neonAmber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NOTE DE REPRISE MENTALE (SAUVEGARDÉE AVANT L\'INTERRUPTION) :',
                                    style: TextStyle(
                                      color: AppTheme.neonAmber,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.resumeNote!,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(taskRepositoryProvider)
                                  .acknowledgeResumeNote(task.id),
                              child: const Text(
                                'J\'ai repris le fil ✓',
                                style: TextStyle(
                                  color: AppTheme.neonAmber,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // --- BARRE CHRONOMÈTRE FOCUS + BOUTON POP (si urgence) ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: AppTheme.neumorphicInset(radius: 14),
                      child: Row(
                        children: [
                          Icon(
                            isTimerRunningOnThis
                                ? Icons.timer_rounded
                                : Icons.timer_outlined,
                            color: isTimerRunningOnThis
                                ? AppTheme.neonGreen
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(totalSeconds),
                            style: TextStyle(
                              color: isTimerRunningOnThis
                                  ? AppTheme.neonGreen
                                  : AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => ref
                                .read(focusTimerProvider.notifier)
                                .toggleTimer(task.id),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isTimerRunningOnThis
                                    ? AppTheme.neonAmber.withValues(alpha: 0.2)
                                    : AppTheme.accentBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isTimerRunningOnThis
                                      ? AppTheme.neonAmber
                                      : AppTheme.accentBlue,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isTimerRunningOnThis
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 16,
                                    color: isTimerRunningOnThis
                                        ? AppTheme.neonAmber
                                        : AppTheme.accentBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTimerRunningOnThis
                                        ? 'Pause Focus'
                                        : 'Démarrer Focus',
                                    style: TextStyle(
                                      color: isTimerRunningOnThis
                                          ? AppTheme.neonAmber
                                          : AppTheme.accentBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Si c'est une Urgence au sommet : Bouton "✅ Résoudre & Dépiler (POP)"
                          if (isUrgencyTop)
                            InkWell(
                              borderRadius: BorderRadius.circular(11),
                              onTap: () async {
                                await ref.read(focusTimerProvider.notifier).pauseTimer();
                                await ref
                                    .read(taskRepositoryProvider)
                                    .popActiveTopTask(task.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen,
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.neonGreen.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 16, color: Colors.black),
                                    SizedBox(width: 6),
                                    Text(
                                      '✅ Résoudre & Dépiler (POP)',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            // Sinon bouton pour terminer la tâche de fond du jour
                            TextButton.icon(
                              onPressed: () async {
                                await ref.read(focusTimerProvider.notifier).pauseTimer();
                                await ref
                                    .read(taskRepositoryProvider)
                                    .completeTask(task.id);
                              },
                              icon: const Icon(Icons.task_alt_rounded,
                                  size: 16, color: AppTheme.neonGreen),
                              label: const Text(
                                'Clôturer Tâche de Fond',
                                style: TextStyle(
                                  color: AppTheme.neonGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // --- MICRO-JALONS DE 30 MINUTES (Sous-tâches cochables) ---
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MICRO-JALONS DE 30 MINUTES',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showAddMilestoneDialog(context, ref, task.id),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 15, color: AppTheme.accentBlue),
                                SizedBox(width: 3),
                                Text(
                                  'Ajouter jalon 30m',
                                  style: TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (item.milestones.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Aucun micro-jalon défini. Découpe cette tâche en blocs de 30 min.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(11),
                              onTap: () => ref
                                  .read(taskRepositoryProvider)
                                  .toggleMicroMilestone(m.id, !m.isDone),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 9),
                                decoration: BoxDecoration(
                                  color: m.isDone
                                      ? AppTheme.bgDeep.withValues(alpha: 0.55)
                                      : AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: m.isDone
                                        ? AppTheme.neonGreen.withValues(alpha: 0.35)
                                        : AppTheme.borderSubtle,
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
                                            size: 16,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      m.isDone
                                          ? Icons.check_box_rounded
                                          : Icons.check_box_outline_blank_rounded,
                                      size: 18,
                                      color: m.isDone
                                          ? AppTheme.neonGreen
                                          : AppTheme.textSecondary,
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
                                          decoration: m.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceInput,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${m.durationMinutes}m',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () => ref
                                          .read(taskRepositoryProvider)
                                          .deleteMicroMilestone(m.id),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 15,
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
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte d'une tâche mise en sommeil dans la pile suite à un PUSH d'urgence
  Widget _buildPausedStackCard(
    BuildContext context,
    WidgetRef ref,
    TaskWithMilestones pausedItem,
  ) {
    final task = pausedItem.task;
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Opacity(
        opacity: 0.85,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.neumorphicCard(
            color: AppTheme.surfaceCard,
            radius: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.neonAmber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⏸️ EN PAUSE DANS LA PILE (ATTENTE POP)',
                      style: TextStyle(
                        color: AppTheme.neonAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (task.externalRef != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      task.externalRef!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${pausedItem.completionPercent}% • ${_formatDuration(task.elapsedSeconds)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (task.resumeNote != null && task.resumeNote!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.neonAmber.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded,
                          size: 16, color: AppTheme.neonAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note de reprise verrouillée : "${task.resumeNote}"',
                          style: const TextStyle(
                            color: AppTheme.neonAmber,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBacklogSwitcher(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithMilestones> backlogDeepWork,
  ) {
    if (backlogDeepWork.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.neumorphicCard(
          color: AppTheme.surfaceCard.withValues(alpha: 0.7),
          radius: 16,
          isElevated: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RÉSERVE TÂCHES DE FOND (SWITCH WIP = 1 • GLISSER ⠿ POUR ORDONNER)',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 8),
            SyncReorderableList(
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
                  padding: const EdgeInsets.only(bottom: 6),
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
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.architecture_rounded,
                          size: 16, color: AppTheme.neonAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.task.title,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(taskRepositoryProvider)
                            .activateDeepWorkTask(item.task.id),
                        child: const Text(
                          'Placer à la base',
                          style: TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => ref
                            .read(taskRepositoryProvider)
                            .deleteTask(item.task.id),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: AppTheme.textMuted,
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
    );
  }

  Widget _buildCompletedHistorySection(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithMilestones> completedItems,
  ) {
    if (completedItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.neumorphicCard(
          color: AppTheme.surfaceCard.withValues(alpha: 0.7),
          radius: 16,
          isElevated: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 15, color: AppTheme.neonGreen),
                const SizedBox(width: 6),
                Text(
                  'BACKLOG RÉALISÉ / DÉJÀ FAIT (${completedItems.length})',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...completedItems.map((item) {
              final taskType = TaskType.fromDb(item.task.type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 15, color: taskType.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.task.title,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => ref
                          .read(taskRepositoryProvider)
                          .reactivateTask(item.task.id, placeInActiveStack: true),
                      icon: const Icon(Icons.restore_rounded,
                          size: 14, color: AppTheme.accentBlue),
                      label: const Text(
                        'Rendre actif',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.neumorphicCard(radius: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_outlined, size: 42, color: AppTheme.accentBlue),
            const SizedBox(height: 12),
            Text(
              'La Pile Active est vide',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sélectionne ta Tâche de Fond du Jour (WIP = 1), réactive une tâche déjà faite, ou capture une nouvelle tâche en haut.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
            ),
            if (backlog.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...backlog.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceElevated,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    onPressed: () => ref
                        .read(taskRepositoryProvider)
                        .activateDeepWorkTask(b.task.id),
                    icon: const Icon(Icons.play_circle_fill_rounded,
                        color: AppTheme.accentBlue),
                    label: Text(
                      'Activer : ${b.task.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...completed.take(3).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(taskRepositoryProvider)
                        .reactivateTask(c.task.id, placeInActiveStack: true),
                    icon: const Icon(Icons.restore_rounded,
                        size: 16, color: AppTheme.neonGreen),
                    label: Text(
                      'Réactiver : ${c.task.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
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
          'Nouveau Micro-Jalon (30 min)',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
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
