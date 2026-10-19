import '../../data/local/drift/app_database.dart';
import '../models/calendar_event.dart';
import '../models/task_enums.dart';

/// Modèle enrichi d'une tâche avec ses micro-jalons de 30 minutes
class TaskWithMilestones {
  final PrioTask task;
  final List<MicroMilestone> milestones;

  const TaskWithMilestones({
    required this.task,
    required this.milestones,
  });

  double get completionRatio {
    if (task.status == TaskStackStatus.done.dbValue) return 1.0;
    if (milestones.isEmpty) return 0.0;

    final totalMinutes = milestones.fold<int>(0, (sum, m) => sum + m.durationMinutes);
    if (totalMinutes > 0) {
      final doneMinutes = milestones
          .where((m) => m.isDone)
          .fold<int>(0, (sum, m) => sum + m.durationMinutes);
      return (doneMinutes / totalMinutes).clamp(0.0, 1.0);
    }

    final doneCount = milestones.where((m) => m.isDone).length;
    return (doneCount / milestones.length).clamp(0.0, 1.0);
  }

  int get completionPercent => (completionRatio * 100).round();
}

/// Statistiques temps réel pour la barre de statut inférieure
class StackMetrics {
  final int deepWorkSeconds;
  final int interruptionSeconds;
  final int pushCountToday;

  const StackMetrics({
    required this.deepWorkSeconds,
    required this.interruptionSeconds,
    required this.pushCountToday,
  });

  int get totalSeconds => deepWorkSeconds + interruptionSeconds;

  double get deepWorkRatio {
    if (totalSeconds == 0) return 0.70; // Valeur par défaut à l'initialisation
    return deepWorkSeconds / totalSeconds;
  }

  int get deepWorkPercent => (deepWorkRatio * 100).round();
  int get interruptionPercent => 100 - deepWorkPercent;
}

/// Interface abstraite du Repository consommée par les Notifiers Riverpod.
/// En V2, une implémentation hybride Supabase + Drift pourra remplacer ou étendre ce contrat.
abstract class TaskRepository {
  /// Flux réactif de la Routine du matin (Zone 1)
  Stream<List<MorningCheckItem>> watchMorningChecks();

  /// Flux réactif de la Pile Active (Zone 2 : Tâche de fond + Urgences empilées au-dessus)
  Stream<List<TaskWithMilestones>> watchActiveStack();

  /// Flux réactif des files d'attente de Triage & Bouclier Manager (Zone 3)
  Stream<List<TaskWithMilestones>> watchTriageTasksByType(TaskType type);

  /// Flux réactif des tâches de fond disponibles en backlog (pour démarrer une nouvelle tâche de fond)
  Stream<List<TaskWithMilestones>> watchBacklogDeepWork();

  /// Flux réactif des métriques de la barre inférieure (% Fond vs % Urgences + compteur PUSH)
  Stream<StackMetrics> watchStackMetrics();

  /// Capture Éclair (Ctrl + K ou barre supérieure)
  Future<String> quickCaptureTask({
    required String title,
    required TaskType type,
    String? externalRef,
    String? requesterOrAssignee,
    int criticality = 2,
    VisibilityScope visibility = VisibilityScope.privateScope,
    List<String> initialMilestones = const [],
  });

  /// Basculer l'état d'un item de la Morning Check-list
  Future<void> toggleMorningCheck(String id, bool isChecked);

  /// Réinitialisation quotidienne de la Morning Check-list
  Future<void> resetMorningChecklist();

  /// Ajouter un item à la Morning Check-list
  Future<void> addMorningCheckItem(String title, String category);

  /// Supprimer un item de la Morning Check-list (Soft-delete V2-Ready via deletedAt)
  Future<void> deleteMorningCheckItem(String id);

  /// Définir une tâche de fond comme active à la base de la pile (WIP Limit strict = 1)
  Future<void> activateDeepWorkTask(String taskId);

  /// Ajouter un micro-jalon à une tâche avec sa durée (par défaut 30 min)
  Future<void> addMicroMilestone(String taskId, String title, {int durationMinutes = 30});

  /// Modifier un micro-jalon (libellé et/ou durée)
  Future<void> updateMicroMilestone(String milestoneId, {String? title, int? durationMinutes});

  /// Cocher / décocher un micro-jalon
  Future<void> toggleMicroMilestone(String milestoneId, bool isDone);

  /// Supprimer un micro-jalon
  Future<void> deleteMicroMilestone(String milestoneId);

  /// Supprimer une tâche (Soft-delete V2-Ready via deletedAt)
  Future<void> deleteTask(String taskId);

  /// Incrémenter le temps passé sur la tâche active (Chronomètre Focus)
  Future<void> recordFocusTick(String taskId, int deltaSeconds);

  /// 🚨 MÉCANIQUE PUSH :
  /// 1. Sauvegarde la "Note de reprise" obligatoire sur la tâche interrompue
  /// 2. Met la tâche de fond en statut 'pushed_pause'
  /// 3. Place l'urgence (existante ou nouvellement créée) au sommet de la pile ('active_top')
  /// 4. Incrémente le compteur d'interruptions (stackDepth / pushCount)
  Future<void> pushInterruption({
    required String resumeNote,
    String? existingUrgencyTaskId,
    String? newUrgencyTitle,
    String? externalRef,
    int criticality = 3,
  });

  /// ✅ MÉCANIQUE POP :
  /// 1. Clôt l'urgence au sommet de la pile ('done')
  /// 2. Restaure l'élément immédiatement inférieur (ou la tâche de fond) à l'état actif
  /// 3. Conserve la Note de reprise bien en évidence pour reprendre sans perte de contexte
  Future<void> popActiveTopTask(String topTaskId);

  /// Effacer la note de reprise une fois que l'utilisateur a repris son flux mental
  Future<void> acknowledgeResumeNote(String taskId);

  /// Flux réactif des tâches terminées (Historique / Backlog des éléments déjà faits)
  Stream<List<TaskWithMilestones>> watchCompletedTasks();

  /// Déléguer une urgence ou une tâche à un membre de l'équipe (bascule dans l'onglet Délégué)
  Future<void> delegateTask(String taskId, String assigneeName);

  /// Marquer une tâche (Fond, Triage, Assistance ou Délégué) comme résolue ('done')
  Future<void> completeTask(String taskId);

  /// Rendre de nouveau active une tâche déjà terminée ('done' -> 'backlog' ou directement dans la Pile Active)
  Future<void> reactivateTask(String taskId, {bool placeInActiveStack = false});

  /// Réordonner par glisser-déposer les éléments de la Morning Check-list
  Future<void> reorderMorningChecks(List<String> orderedIds);

  /// Réordonner par glisser-déposer les micro-jalons de 30 minutes d'une tâche
  Future<void> reorderMicroMilestones(String taskId, List<String> orderedMilestoneIds);

  /// Réordonner par glisser-déposer une liste de tâches (Files de Triage, Réserve Fond, etc.)
  Future<void> reorderTasks(List<String> orderedTaskIds);

  // --- CALENDRIER & AGENDA (Réunions, Points Équipe, Créneaux Architecture, Échéances) ---

  /// Flux réactif des événements du calendrier triés par heure de début
  Stream<List<CalendarEventItem>> watchCalendarEvents();

  /// Planifier un nouvel événement / réunion dans le calendrier
  Future<String> addCalendarEvent({
    required String title,
    required CalendarEventCategory category,
    required DateTime startTime,
    required DateTime endTime,
    String? participantsOrLocation,
    String? externalRef,
    String? notes,
  });

  /// Mettre à jour un événement du calendrier
  Future<void> updateCalendarEvent(CalendarEventItem event);

  /// Basculer l'état terminé / honoré d'un événement du calendrier
  Future<void> toggleCalendarEventCompleted(String eventId, bool isCompleted);

  /// Supprimer un événement du calendrier (Soft-delete V2-Ready via deletedAt)
  Future<void> deleteCalendarEvent(String eventId);

  /// 🚨 PUSH Réunion dans la Pile Active :
  /// Met en pause la Tâche de Fond en cours avec Note de reprise obligatoire et place la réunion au sommet de la pile
  Future<void> pushCalendarEventToStack({
    required String eventId,
    required String resumeNote,
  });

  /// Clôture automatiquement toutes les réunions / événements dont l'heure de fin est dépassée
  /// et retourne la liste des événements qui viennent d'être marqués comme terminés.
  Future<List<CalendarEventItem>> autoCompletePastCalendarEvents([
    DateTime? nowOverride,
  ]);

  /// Exporte l'intégralité des données en format JSON de sauvegarde standard PrioStack.
  /// Retourne la chaîne JSON ou null si aucune donnée.
  Future<String?> exportBackupJson() async => null;

  /// Importe et restaure les données depuis une chaîne JSON.
  /// Retourne null si succès, sinon le message d'erreur.
  Future<String?> importBackupJson(String rawJson) async => null;
}

