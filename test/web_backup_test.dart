@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:priostack/data/local/memory/in_memory_task_repository.dart';
import 'package:priostack/data/local/memory/web_storage_helper.dart';
import 'package:priostack/data/local/memory/web_storage_html.dart';

void main() {
  setUp(() {
    for (final k in [
      'priostack_tasks_v1',
      'priostack_milestones_v1',
      'priostack_checks_v1',
      'priostack_events_v1',
      'priostack_initialized_v1',
    ]) {
      removeStorageItem(k);
    }
  });

  test('export contient les données puis import les restaure à l\'identique', () {
    // Premier lancement : jeu de démo écrit dans le localStorage
    InMemoryTaskRepository();
    final json = WebStorageHelper.buildBackupJson();
    expect(json, isNotNull);

    final bundle = jsonDecode(json!) as Map<String, dynamic>;
    expect(bundle['format'], 'priostack-backup');
    expect((bundle['tasks'] as List), isNotEmpty);
    expect((bundle['calendarEvents'] as List), isNotEmpty);

    // On efface puis on restaure
    removeStorageItem('priostack_tasks_v1');
    expect(WebStorageHelper.loadTasks(), isNull);

    final error = WebStorageHelper.restoreFromBackupJson(json);
    expect(error, isNull);
    expect(WebStorageHelper.loadTasks()!.length, (bundle['tasks'] as List).length);
    expect(WebStorageHelper.loadMorningChecks()!.length,
        (bundle['morningChecks'] as List).length);
  });

  test('un fichier invalide est refusé sans écraser les données', () {
    InMemoryTaskRepository();
    final before = WebStorageHelper.loadTasks()!.length;

    expect(WebStorageHelper.restoreFromBackupJson('pas du json'), isNotNull);
    expect(WebStorageHelper.restoreFromBackupJson('{"format":"autre"}'), isNotNull);
    expect(
      WebStorageHelper.restoreFromBackupJson(
          '{"format":"priostack-backup","version":1,"tasks":[{"id":1}],"milestones":[],"morningChecks":[],"calendarEvents":[]}'),
      isNotNull,
    );

    expect(WebStorageHelper.loadTasks()!.length, before);
  });
}
