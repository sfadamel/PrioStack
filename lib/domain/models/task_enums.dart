import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Les 4 types d'éléments de la Barre de Capture Éclair PrioStack
enum TaskType {
  urgence('urgence', '🔥 Urgence', AppTheme.neonPink),
  devBlock('dev_block', '🧑‍💻 Assistance', AppTheme.neonGreen),
  deepWork('deep_work', '🏗️ Tâche de Fond', AppTheme.neonAmber),
  delegated('delegated', '📤 Délégué / Suivi', AppTheme.neonPurple);

  final String dbValue;
  final String label;
  final Color accentColor;
  const TaskType(this.dbValue, this.label, this.accentColor);

  static TaskType fromDb(String value) {
    return TaskType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => TaskType.deepWork,
    );
  }
}

/// Statut dans le cycle de vie de la Pile Active (Call Stack) ou du Triage
enum TaskStackStatus {
  backlog('backlog'),       // En file d'attente (Triage / Backlog)
  activeBase('active_base'), // Tâche de fond active à la base de la pile (WIP = 1)
  pushedPause('pushed_pause'), // Tâche de fond mise en pause suite à un PUSH d'urgence
  activeTop('active_top'),   // Urgence au sommet de la pile (en cours de résolution)
  done('done');              // Terminée / Dépilée (POP)

  final String dbValue;
  const TaskStackStatus(this.dbValue);

  static TaskStackStatus fromDb(String value) {
    return TaskStackStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => TaskStackStatus.backlog,
    );
  }
}

/// Visibilité V2-Ready ('private' | 'team')
enum VisibilityScope {
  privateScope('private'),
  team('team');

  final String dbValue;
  const VisibilityScope(this.dbValue);

  static VisibilityScope fromDb(String value) =>
      value == 'team' ? VisibilityScope.team : VisibilityScope.privateScope;
}

/// État de synchronisation V2-Ready ('local' | 'synced' | 'pending')
enum SyncStatus {
  local('local'),
  synced('synced'),
  pending('pending');

  final String dbValue;
  const SyncStatus(this.dbValue);

  static SyncStatus fromDb(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => SyncStatus.local,
    );
  }
}
