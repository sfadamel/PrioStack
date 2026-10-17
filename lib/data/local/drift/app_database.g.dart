// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PrioTasksTable extends PrioTasks
    with TableInfo<$PrioTasksTable, PrioTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrioTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultUserId));
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultWorkspaceId));
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('backlog'));
  static const VerificationMeta _criticalityMeta =
      const VerificationMeta('criticality');
  @override
  late final GeneratedColumn<int> criticality = GeneratedColumn<int>(
      'criticality', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _externalRefMeta =
      const VerificationMeta('externalRef');
  @override
  late final GeneratedColumn<String> externalRef = GeneratedColumn<String>(
      'external_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requesterOrAssigneeMeta =
      const VerificationMeta('requesterOrAssignee');
  @override
  late final GeneratedColumn<String> requesterOrAssignee =
      GeneratedColumn<String>('requester_or_assignee', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _resumeNoteMeta =
      const VerificationMeta('resumeNote');
  @override
  late final GeneratedColumn<String> resumeNote = GeneratedColumn<String>(
      'resume_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stackOrderMeta =
      const VerificationMeta('stackOrder');
  @override
  late final GeneratedColumn<int> stackOrder = GeneratedColumn<int>(
      'stack_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _elapsedSecondsMeta =
      const VerificationMeta('elapsedSeconds');
  @override
  late final GeneratedColumn<int> elapsedSeconds = GeneratedColumn<int>(
      'elapsed_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _interruptionCountMeta =
      const VerificationMeta('interruptionCount');
  @override
  late final GeneratedColumn<int> interruptionCount = GeneratedColumn<int>(
      'interruption_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        workspaceId,
        visibility,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt,
        title,
        type,
        status,
        criticality,
        externalRef,
        requesterOrAssignee,
        resumeNote,
        stackOrder,
        elapsedSeconds,
        interruptionCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prio_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<PrioTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('criticality')) {
      context.handle(
          _criticalityMeta,
          criticality.isAcceptableOrUnknown(
              data['criticality']!, _criticalityMeta));
    }
    if (data.containsKey('external_ref')) {
      context.handle(
          _externalRefMeta,
          externalRef.isAcceptableOrUnknown(
              data['external_ref']!, _externalRefMeta));
    }
    if (data.containsKey('requester_or_assignee')) {
      context.handle(
          _requesterOrAssigneeMeta,
          requesterOrAssignee.isAcceptableOrUnknown(
              data['requester_or_assignee']!, _requesterOrAssigneeMeta));
    }
    if (data.containsKey('resume_note')) {
      context.handle(
          _resumeNoteMeta,
          resumeNote.isAcceptableOrUnknown(
              data['resume_note']!, _resumeNoteMeta));
    }
    if (data.containsKey('stack_order')) {
      context.handle(
          _stackOrderMeta,
          stackOrder.isAcceptableOrUnknown(
              data['stack_order']!, _stackOrderMeta));
    }
    if (data.containsKey('elapsed_seconds')) {
      context.handle(
          _elapsedSecondsMeta,
          elapsedSeconds.isAcceptableOrUnknown(
              data['elapsed_seconds']!, _elapsedSecondsMeta));
    }
    if (data.containsKey('interruption_count')) {
      context.handle(
          _interruptionCountMeta,
          interruptionCount.isAcceptableOrUnknown(
              data['interruption_count']!, _interruptionCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrioTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrioTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      criticality: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}criticality'])!,
      externalRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_ref']),
      requesterOrAssignee: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}requester_or_assignee']),
      resumeNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resume_note']),
      stackOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stack_order'])!,
      elapsedSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_seconds'])!,
      interruptionCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}interruption_count'])!,
    );
  }

  @override
  $PrioTasksTable createAlias(String alias) {
    return $PrioTasksTable(attachedDatabase, alias);
  }
}

class PrioTask extends DataClass implements Insertable<PrioTask> {
  /// Clé primaire UUID v4 (text)
  final String id;
  final String userId;
  final String workspaceId;
  final String visibility;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String title;
  final String type;
  final String status;
  final int criticality;
  final String? externalRef;
  final String? requesterOrAssignee;

  /// Note de reprise obligatoire saisie lors d'un PUSH d'interruption ("Où en étais-tu exactement ?")
  final String? resumeNote;

  /// Position dans la pile active (0 = Tâche de fond à la base, 1..N = Urgences empilées au-dessus)
  final int stackOrder;

  /// Temps cumulé passé en focus (en secondes)
  final int elapsedSeconds;

  /// Nombre de fois où cette tâche a subi un PUSH ou a été poussée
  final int interruptionCount;
  const PrioTask(
      {required this.id,
      required this.userId,
      required this.workspaceId,
      required this.visibility,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.title,
      required this.type,
      required this.status,
      required this.criticality,
      this.externalRef,
      this.requesterOrAssignee,
      this.resumeNote,
      required this.stackOrder,
      required this.elapsedSeconds,
      required this.interruptionCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['visibility'] = Variable<String>(visibility);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    map['criticality'] = Variable<int>(criticality);
    if (!nullToAbsent || externalRef != null) {
      map['external_ref'] = Variable<String>(externalRef);
    }
    if (!nullToAbsent || requesterOrAssignee != null) {
      map['requester_or_assignee'] = Variable<String>(requesterOrAssignee);
    }
    if (!nullToAbsent || resumeNote != null) {
      map['resume_note'] = Variable<String>(resumeNote);
    }
    map['stack_order'] = Variable<int>(stackOrder);
    map['elapsed_seconds'] = Variable<int>(elapsedSeconds);
    map['interruption_count'] = Variable<int>(interruptionCount);
    return map;
  }

  PrioTasksCompanion toCompanion(bool nullToAbsent) {
    return PrioTasksCompanion(
      id: Value(id),
      userId: Value(userId),
      workspaceId: Value(workspaceId),
      visibility: Value(visibility),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      type: Value(type),
      status: Value(status),
      criticality: Value(criticality),
      externalRef: externalRef == null && nullToAbsent
          ? const Value.absent()
          : Value(externalRef),
      requesterOrAssignee: requesterOrAssignee == null && nullToAbsent
          ? const Value.absent()
          : Value(requesterOrAssignee),
      resumeNote: resumeNote == null && nullToAbsent
          ? const Value.absent()
          : Value(resumeNote),
      stackOrder: Value(stackOrder),
      elapsedSeconds: Value(elapsedSeconds),
      interruptionCount: Value(interruptionCount),
    );
  }

  factory PrioTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrioTask(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      visibility: serializer.fromJson<String>(json['visibility']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      criticality: serializer.fromJson<int>(json['criticality']),
      externalRef: serializer.fromJson<String?>(json['externalRef']),
      requesterOrAssignee:
          serializer.fromJson<String?>(json['requesterOrAssignee']),
      resumeNote: serializer.fromJson<String?>(json['resumeNote']),
      stackOrder: serializer.fromJson<int>(json['stackOrder']),
      elapsedSeconds: serializer.fromJson<int>(json['elapsedSeconds']),
      interruptionCount: serializer.fromJson<int>(json['interruptionCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'visibility': serializer.toJson<String>(visibility),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'criticality': serializer.toJson<int>(criticality),
      'externalRef': serializer.toJson<String?>(externalRef),
      'requesterOrAssignee': serializer.toJson<String?>(requesterOrAssignee),
      'resumeNote': serializer.toJson<String?>(resumeNote),
      'stackOrder': serializer.toJson<int>(stackOrder),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'interruptionCount': serializer.toJson<int>(interruptionCount),
    };
  }

  PrioTask copyWith(
          {String? id,
          String? userId,
          String? workspaceId,
          String? visibility,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? title,
          String? type,
          String? status,
          int? criticality,
          Value<String?> externalRef = const Value.absent(),
          Value<String?> requesterOrAssignee = const Value.absent(),
          Value<String?> resumeNote = const Value.absent(),
          int? stackOrder,
          int? elapsedSeconds,
          int? interruptionCount}) =>
      PrioTask(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        workspaceId: workspaceId ?? this.workspaceId,
        visibility: visibility ?? this.visibility,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        title: title ?? this.title,
        type: type ?? this.type,
        status: status ?? this.status,
        criticality: criticality ?? this.criticality,
        externalRef: externalRef.present ? externalRef.value : this.externalRef,
        requesterOrAssignee: requesterOrAssignee.present
            ? requesterOrAssignee.value
            : this.requesterOrAssignee,
        resumeNote: resumeNote.present ? resumeNote.value : this.resumeNote,
        stackOrder: stackOrder ?? this.stackOrder,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        interruptionCount: interruptionCount ?? this.interruptionCount,
      );
  PrioTask copyWithCompanion(PrioTasksCompanion data) {
    return PrioTask(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      criticality:
          data.criticality.present ? data.criticality.value : this.criticality,
      externalRef:
          data.externalRef.present ? data.externalRef.value : this.externalRef,
      requesterOrAssignee: data.requesterOrAssignee.present
          ? data.requesterOrAssignee.value
          : this.requesterOrAssignee,
      resumeNote:
          data.resumeNote.present ? data.resumeNote.value : this.resumeNote,
      stackOrder:
          data.stackOrder.present ? data.stackOrder.value : this.stackOrder,
      elapsedSeconds: data.elapsedSeconds.present
          ? data.elapsedSeconds.value
          : this.elapsedSeconds,
      interruptionCount: data.interruptionCount.present
          ? data.interruptionCount.value
          : this.interruptionCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrioTask(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('visibility: $visibility, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('criticality: $criticality, ')
          ..write('externalRef: $externalRef, ')
          ..write('requesterOrAssignee: $requesterOrAssignee, ')
          ..write('resumeNote: $resumeNote, ')
          ..write('stackOrder: $stackOrder, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('interruptionCount: $interruptionCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      workspaceId,
      visibility,
      syncStatus,
      createdAt,
      updatedAt,
      deletedAt,
      title,
      type,
      status,
      criticality,
      externalRef,
      requesterOrAssignee,
      resumeNote,
      stackOrder,
      elapsedSeconds,
      interruptionCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrioTask &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.workspaceId == this.workspaceId &&
          other.visibility == this.visibility &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.type == this.type &&
          other.status == this.status &&
          other.criticality == this.criticality &&
          other.externalRef == this.externalRef &&
          other.requesterOrAssignee == this.requesterOrAssignee &&
          other.resumeNote == this.resumeNote &&
          other.stackOrder == this.stackOrder &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.interruptionCount == this.interruptionCount);
}

class PrioTasksCompanion extends UpdateCompanion<PrioTask> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> workspaceId;
  final Value<String> visibility;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> title;
  final Value<String> type;
  final Value<String> status;
  final Value<int> criticality;
  final Value<String?> externalRef;
  final Value<String?> requesterOrAssignee;
  final Value<String?> resumeNote;
  final Value<int> stackOrder;
  final Value<int> elapsedSeconds;
  final Value<int> interruptionCount;
  final Value<int> rowid;
  const PrioTasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.criticality = const Value.absent(),
    this.externalRef = const Value.absent(),
    this.requesterOrAssignee = const Value.absent(),
    this.resumeNote = const Value.absent(),
    this.stackOrder = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.interruptionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrioTasksCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String title,
    required String type,
    this.status = const Value.absent(),
    this.criticality = const Value.absent(),
    this.externalRef = const Value.absent(),
    this.requesterOrAssignee = const Value.absent(),
    this.resumeNote = const Value.absent(),
    this.stackOrder = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.interruptionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : title = Value(title),
        type = Value(type);
  static Insertable<PrioTask> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? workspaceId,
    Expression<String>? visibility,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? status,
    Expression<int>? criticality,
    Expression<String>? externalRef,
    Expression<String>? requesterOrAssignee,
    Expression<String>? resumeNote,
    Expression<int>? stackOrder,
    Expression<int>? elapsedSeconds,
    Expression<int>? interruptionCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (visibility != null) 'visibility': visibility,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (criticality != null) 'criticality': criticality,
      if (externalRef != null) 'external_ref': externalRef,
      if (requesterOrAssignee != null)
        'requester_or_assignee': requesterOrAssignee,
      if (resumeNote != null) 'resume_note': resumeNote,
      if (stackOrder != null) 'stack_order': stackOrder,
      if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      if (interruptionCount != null) 'interruption_count': interruptionCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrioTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? workspaceId,
      Value<String>? visibility,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? title,
      Value<String>? type,
      Value<String>? status,
      Value<int>? criticality,
      Value<String?>? externalRef,
      Value<String?>? requesterOrAssignee,
      Value<String?>? resumeNote,
      Value<int>? stackOrder,
      Value<int>? elapsedSeconds,
      Value<int>? interruptionCount,
      Value<int>? rowid}) {
    return PrioTasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workspaceId: workspaceId ?? this.workspaceId,
      visibility: visibility ?? this.visibility,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      criticality: criticality ?? this.criticality,
      externalRef: externalRef ?? this.externalRef,
      requesterOrAssignee: requesterOrAssignee ?? this.requesterOrAssignee,
      resumeNote: resumeNote ?? this.resumeNote,
      stackOrder: stackOrder ?? this.stackOrder,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (criticality.present) {
      map['criticality'] = Variable<int>(criticality.value);
    }
    if (externalRef.present) {
      map['external_ref'] = Variable<String>(externalRef.value);
    }
    if (requesterOrAssignee.present) {
      map['requester_or_assignee'] =
          Variable<String>(requesterOrAssignee.value);
    }
    if (resumeNote.present) {
      map['resume_note'] = Variable<String>(resumeNote.value);
    }
    if (stackOrder.present) {
      map['stack_order'] = Variable<int>(stackOrder.value);
    }
    if (elapsedSeconds.present) {
      map['elapsed_seconds'] = Variable<int>(elapsedSeconds.value);
    }
    if (interruptionCount.present) {
      map['interruption_count'] = Variable<int>(interruptionCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrioTasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('visibility: $visibility, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('criticality: $criticality, ')
          ..write('externalRef: $externalRef, ')
          ..write('requesterOrAssignee: $requesterOrAssignee, ')
          ..write('resumeNote: $resumeNote, ')
          ..write('stackOrder: $stackOrder, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('interruptionCount: $interruptionCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MicroMilestonesTable extends MicroMilestones
    with TableInfo<$MicroMilestonesTable, MicroMilestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MicroMilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES prio_tasks (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultUserId));
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultWorkspaceId));
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        taskId,
        userId,
        workspaceId,
        visibility,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt,
        title,
        durationMinutes,
        isDone,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'micro_milestones';
  @override
  VerificationContext validateIntegrity(Insertable<MicroMilestone> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MicroMilestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MicroMilestone(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $MicroMilestonesTable createAlias(String alias) {
    return $MicroMilestonesTable(attachedDatabase, alias);
  }
}

class MicroMilestone extends DataClass implements Insertable<MicroMilestone> {
  final String id;
  final String taskId;
  final String userId;
  final String workspaceId;
  final String visibility;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String title;
  final int durationMinutes;
  final bool isDone;
  final int sortOrder;
  const MicroMilestone(
      {required this.id,
      required this.taskId,
      required this.userId,
      required this.workspaceId,
      required this.visibility,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.title,
      required this.durationMinutes,
      required this.isDone,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['user_id'] = Variable<String>(userId);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['visibility'] = Variable<String>(visibility);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['is_done'] = Variable<bool>(isDone);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MicroMilestonesCompanion toCompanion(bool nullToAbsent) {
    return MicroMilestonesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      userId: Value(userId),
      workspaceId: Value(workspaceId),
      visibility: Value(visibility),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      durationMinutes: Value(durationMinutes),
      isDone: Value(isDone),
      sortOrder: Value(sortOrder),
    );
  }

  factory MicroMilestone.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MicroMilestone(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      userId: serializer.fromJson<String>(json['userId']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      visibility: serializer.fromJson<String>(json['visibility']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'userId': serializer.toJson<String>(userId),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'visibility': serializer.toJson<String>(visibility),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'isDone': serializer.toJson<bool>(isDone),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MicroMilestone copyWith(
          {String? id,
          String? taskId,
          String? userId,
          String? workspaceId,
          String? visibility,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? title,
          int? durationMinutes,
          bool? isDone,
          int? sortOrder}) =>
      MicroMilestone(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        userId: userId ?? this.userId,
        workspaceId: workspaceId ?? this.workspaceId,
        visibility: visibility ?? this.visibility,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        title: title ?? this.title,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isDone: isDone ?? this.isDone,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  MicroMilestone copyWithCompanion(MicroMilestonesCompanion data) {
    return MicroMilestone(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      userId: data.userId.present ? data.userId.value : this.userId,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MicroMilestone(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('visibility: $visibility, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      taskId,
      userId,
      workspaceId,
      visibility,
      syncStatus,
      createdAt,
      updatedAt,
      deletedAt,
      title,
      durationMinutes,
      isDone,
      sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MicroMilestone &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.userId == this.userId &&
          other.workspaceId == this.workspaceId &&
          other.visibility == this.visibility &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.durationMinutes == this.durationMinutes &&
          other.isDone == this.isDone &&
          other.sortOrder == this.sortOrder);
}

class MicroMilestonesCompanion extends UpdateCompanion<MicroMilestone> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> userId;
  final Value<String> workspaceId;
  final Value<String> visibility;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> title;
  final Value<int> durationMinutes;
  final Value<bool> isDone;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MicroMilestonesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MicroMilestonesCompanion.insert({
    this.id = const Value.absent(),
    required String taskId,
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String title,
    this.durationMinutes = const Value.absent(),
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : taskId = Value(taskId),
        title = Value(title);
  static Insertable<MicroMilestone> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? userId,
    Expression<String>? workspaceId,
    Expression<String>? visibility,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? title,
    Expression<int>? durationMinutes,
    Expression<bool>? isDone,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (userId != null) 'user_id': userId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (visibility != null) 'visibility': visibility,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (isDone != null) 'is_done': isDone,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MicroMilestonesCompanion copyWith(
      {Value<String>? id,
      Value<String>? taskId,
      Value<String>? userId,
      Value<String>? workspaceId,
      Value<String>? visibility,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? title,
      Value<int>? durationMinutes,
      Value<bool>? isDone,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return MicroMilestonesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      workspaceId: workspaceId ?? this.workspaceId,
      visibility: visibility ?? this.visibility,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MicroMilestonesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('visibility: $visibility, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MorningCheckItemsTable extends MorningCheckItems
    with TableInfo<$MorningCheckItemsTable, MorningCheckItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MorningCheckItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => _uuid.v4());
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultUserId));
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(kDefaultWorkspaceId));
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Infra & Ops'));
  static const VerificationMeta _isCheckedMeta =
      const VerificationMeta('isChecked');
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
      'is_checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastResetAtMeta =
      const VerificationMeta('lastResetAt');
  @override
  late final GeneratedColumn<DateTime> lastResetAt = GeneratedColumn<DateTime>(
      'last_reset_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        workspaceId,
        visibility,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt,
        title,
        category,
        isChecked,
        sortOrder,
        lastResetAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'morning_check_items';
  @override
  VerificationContext validateIntegrity(Insertable<MorningCheckItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('is_checked')) {
      context.handle(_isCheckedMeta,
          isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('last_reset_at')) {
      context.handle(
          _lastResetAtMeta,
          lastResetAt.isAcceptableOrUnknown(
              data['last_reset_at']!, _lastResetAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MorningCheckItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MorningCheckItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      isChecked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_checked'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      lastResetAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_reset_at']),
    );
  }

  @override
  $MorningCheckItemsTable createAlias(String alias) {
    return $MorningCheckItemsTable(attachedDatabase, alias);
  }
}

class MorningCheckItem extends DataClass
    implements Insertable<MorningCheckItem> {
  final String id;
  final String userId;
  final String workspaceId;
  final String visibility;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String title;
  final String category;
  final bool isChecked;
  final int sortOrder;
  final DateTime? lastResetAt;
  const MorningCheckItem(
      {required this.id,
      required this.userId,
      required this.workspaceId,
      required this.visibility,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.title,
      required this.category,
      required this.isChecked,
      required this.sortOrder,
      this.lastResetAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['visibility'] = Variable<String>(visibility);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['is_checked'] = Variable<bool>(isChecked);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || lastResetAt != null) {
      map['last_reset_at'] = Variable<DateTime>(lastResetAt);
    }
    return map;
  }

  MorningCheckItemsCompanion toCompanion(bool nullToAbsent) {
    return MorningCheckItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      workspaceId: Value(workspaceId),
      visibility: Value(visibility),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      category: Value(category),
      isChecked: Value(isChecked),
      sortOrder: Value(sortOrder),
      lastResetAt: lastResetAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResetAt),
    );
  }

  factory MorningCheckItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MorningCheckItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      visibility: serializer.fromJson<String>(json['visibility']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastResetAt: serializer.fromJson<DateTime?>(json['lastResetAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'visibility': serializer.toJson<String>(visibility),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'isChecked': serializer.toJson<bool>(isChecked),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastResetAt': serializer.toJson<DateTime?>(lastResetAt),
    };
  }

  MorningCheckItem copyWith(
          {String? id,
          String? userId,
          String? workspaceId,
          String? visibility,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? title,
          String? category,
          bool? isChecked,
          int? sortOrder,
          Value<DateTime?> lastResetAt = const Value.absent()}) =>
      MorningCheckItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        workspaceId: workspaceId ?? this.workspaceId,
        visibility: visibility ?? this.visibility,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        title: title ?? this.title,
        category: category ?? this.category,
        isChecked: isChecked ?? this.isChecked,
        sortOrder: sortOrder ?? this.sortOrder,
        lastResetAt: lastResetAt.present ? lastResetAt.value : this.lastResetAt,
      );
  MorningCheckItem copyWithCompanion(MorningCheckItemsCompanion data) {
    return MorningCheckItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastResetAt:
          data.lastResetAt.present ? data.lastResetAt.value : this.lastResetAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MorningCheckItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('visibility: $visibility, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('isChecked: $isChecked, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastResetAt: $lastResetAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      workspaceId,
      visibility,
      syncStatus,
      createdAt,
      updatedAt,
      deletedAt,
      title,
      category,
      isChecked,
      sortOrder,
      lastResetAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MorningCheckItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.workspaceId == this.workspaceId &&
          other.visibility == this.visibility &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.category == this.category &&
          other.isChecked == this.isChecked &&
          other.sortOrder == this.sortOrder &&
          other.lastResetAt == this.lastResetAt);
}

class MorningCheckItemsCompanion extends UpdateCompanion<MorningCheckItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> workspaceId;
  final Value<String> visibility;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> title;
  final Value<String> category;
  final Value<bool> isChecked;
  final Value<int> sortOrder;
  final Value<DateTime?> lastResetAt;
  final Value<int> rowid;
  const MorningCheckItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastResetAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MorningCheckItemsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String title,
    this.category = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastResetAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title);
  static Insertable<MorningCheckItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? workspaceId,
    Expression<String>? visibility,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? title,
    Expression<String>? category,
    Expression<bool>? isChecked,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastResetAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (visibility != null) 'visibility': visibility,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (isChecked != null) 'is_checked': isChecked,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastResetAt != null) 'last_reset_at': lastResetAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MorningCheckItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? workspaceId,
      Value<String>? visibility,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? title,
      Value<String>? category,
      Value<bool>? isChecked,
      Value<int>? sortOrder,
      Value<DateTime?>? lastResetAt,
      Value<int>? rowid}) {
    return MorningCheckItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workspaceId: workspaceId ?? this.workspaceId,
      visibility: visibility ?? this.visibility,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      sortOrder: sortOrder ?? this.sortOrder,
      lastResetAt: lastResetAt ?? this.lastResetAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastResetAt.present) {
      map['last_reset_at'] = Variable<DateTime>(lastResetAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MorningCheckItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('visibility: $visibility, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('isChecked: $isChecked, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastResetAt: $lastResetAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PrioTasksTable prioTasks = $PrioTasksTable(this);
  late final $MicroMilestonesTable microMilestones =
      $MicroMilestonesTable(this);
  late final $MorningCheckItemsTable morningCheckItems =
      $MorningCheckItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [prioTasks, microMilestones, morningCheckItems];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('prio_tasks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('micro_milestones', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$PrioTasksTableCreateCompanionBuilder = PrioTasksCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> workspaceId,
  Value<String> visibility,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String title,
  required String type,
  Value<String> status,
  Value<int> criticality,
  Value<String?> externalRef,
  Value<String?> requesterOrAssignee,
  Value<String?> resumeNote,
  Value<int> stackOrder,
  Value<int> elapsedSeconds,
  Value<int> interruptionCount,
  Value<int> rowid,
});
typedef $$PrioTasksTableUpdateCompanionBuilder = PrioTasksCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> workspaceId,
  Value<String> visibility,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> title,
  Value<String> type,
  Value<String> status,
  Value<int> criticality,
  Value<String?> externalRef,
  Value<String?> requesterOrAssignee,
  Value<String?> resumeNote,
  Value<int> stackOrder,
  Value<int> elapsedSeconds,
  Value<int> interruptionCount,
  Value<int> rowid,
});

final class $$PrioTasksTableReferences
    extends BaseReferences<_$AppDatabase, $PrioTasksTable, PrioTask> {
  $$PrioTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MicroMilestonesTable, List<MicroMilestone>>
      _microMilestonesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.microMilestones,
              aliasName: 'prio_tasks__id__micro_milestones__task_id');

  $$MicroMilestonesTableProcessedTableManager get microMilestonesRefs {
    final manager =
        $$MicroMilestonesTableTableManager($_db, $_db.microMilestones)
            .filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_microMilestonesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PrioTasksTableFilterComposer
    extends Composer<_$AppDatabase, $PrioTasksTable> {
  $$PrioTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get criticality => $composableBuilder(
      column: $table.criticality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalRef => $composableBuilder(
      column: $table.externalRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requesterOrAssignee => $composableBuilder(
      column: $table.requesterOrAssignee,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resumeNote => $composableBuilder(
      column: $table.resumeNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stackOrder => $composableBuilder(
      column: $table.stackOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interruptionCount => $composableBuilder(
      column: $table.interruptionCount,
      builder: (column) => ColumnFilters(column));

  Expression<bool> microMilestonesRefs(
      Expression<bool> Function($$MicroMilestonesTableFilterComposer f) f) {
    final $$MicroMilestonesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.microMilestones,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MicroMilestonesTableFilterComposer(
              $db: $db,
              $table: $db.microMilestones,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PrioTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $PrioTasksTable> {
  $$PrioTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get criticality => $composableBuilder(
      column: $table.criticality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalRef => $composableBuilder(
      column: $table.externalRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requesterOrAssignee => $composableBuilder(
      column: $table.requesterOrAssignee,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resumeNote => $composableBuilder(
      column: $table.resumeNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stackOrder => $composableBuilder(
      column: $table.stackOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interruptionCount => $composableBuilder(
      column: $table.interruptionCount,
      builder: (column) => ColumnOrderings(column));
}

class $$PrioTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrioTasksTable> {
  $$PrioTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get criticality => $composableBuilder(
      column: $table.criticality, builder: (column) => column);

  GeneratedColumn<String> get externalRef => $composableBuilder(
      column: $table.externalRef, builder: (column) => column);

  GeneratedColumn<String> get requesterOrAssignee => $composableBuilder(
      column: $table.requesterOrAssignee, builder: (column) => column);

  GeneratedColumn<String> get resumeNote => $composableBuilder(
      column: $table.resumeNote, builder: (column) => column);

  GeneratedColumn<int> get stackOrder => $composableBuilder(
      column: $table.stackOrder, builder: (column) => column);

  GeneratedColumn<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds, builder: (column) => column);

  GeneratedColumn<int> get interruptionCount => $composableBuilder(
      column: $table.interruptionCount, builder: (column) => column);

  Expression<T> microMilestonesRefs<T extends Object>(
      Expression<T> Function($$MicroMilestonesTableAnnotationComposer a) f) {
    final $$MicroMilestonesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.microMilestones,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MicroMilestonesTableAnnotationComposer(
              $db: $db,
              $table: $db.microMilestones,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PrioTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrioTasksTable,
    PrioTask,
    $$PrioTasksTableFilterComposer,
    $$PrioTasksTableOrderingComposer,
    $$PrioTasksTableAnnotationComposer,
    $$PrioTasksTableCreateCompanionBuilder,
    $$PrioTasksTableUpdateCompanionBuilder,
    (PrioTask, $$PrioTasksTableReferences),
    PrioTask,
    PrefetchHooks Function({bool microMilestonesRefs})> {
  $$PrioTasksTableTableManager(_$AppDatabase db, $PrioTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrioTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrioTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrioTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> criticality = const Value.absent(),
            Value<String?> externalRef = const Value.absent(),
            Value<String?> requesterOrAssignee = const Value.absent(),
            Value<String?> resumeNote = const Value.absent(),
            Value<int> stackOrder = const Value.absent(),
            Value<int> elapsedSeconds = const Value.absent(),
            Value<int> interruptionCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrioTasksCompanion(
            id: id,
            userId: userId,
            workspaceId: workspaceId,
            visibility: visibility,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            title: title,
            type: type,
            status: status,
            criticality: criticality,
            externalRef: externalRef,
            requesterOrAssignee: requesterOrAssignee,
            resumeNote: resumeNote,
            stackOrder: stackOrder,
            elapsedSeconds: elapsedSeconds,
            interruptionCount: interruptionCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String title,
            required String type,
            Value<String> status = const Value.absent(),
            Value<int> criticality = const Value.absent(),
            Value<String?> externalRef = const Value.absent(),
            Value<String?> requesterOrAssignee = const Value.absent(),
            Value<String?> resumeNote = const Value.absent(),
            Value<int> stackOrder = const Value.absent(),
            Value<int> elapsedSeconds = const Value.absent(),
            Value<int> interruptionCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrioTasksCompanion.insert(
            id: id,
            userId: userId,
            workspaceId: workspaceId,
            visibility: visibility,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            title: title,
            type: type,
            status: status,
            criticality: criticality,
            externalRef: externalRef,
            requesterOrAssignee: requesterOrAssignee,
            resumeNote: resumeNote,
            stackOrder: stackOrder,
            elapsedSeconds: elapsedSeconds,
            interruptionCount: interruptionCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PrioTasksTable, PrioTask>(table),
                    $$PrioTasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({microMilestonesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (microMilestonesRefs) db.microMilestones
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (microMilestonesRefs)
                    await $_getPrefetchedData<PrioTask, $PrioTasksTable,
                            MicroMilestone>(
                        currentTable: table,
                        referencedTable: $$PrioTasksTableReferences
                            ._microMilestonesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PrioTasksTableReferences(db, table, p0)
                                .microMilestonesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.taskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PrioTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrioTasksTable,
    PrioTask,
    $$PrioTasksTableFilterComposer,
    $$PrioTasksTableOrderingComposer,
    $$PrioTasksTableAnnotationComposer,
    $$PrioTasksTableCreateCompanionBuilder,
    $$PrioTasksTableUpdateCompanionBuilder,
    (PrioTask, $$PrioTasksTableReferences),
    PrioTask,
    PrefetchHooks Function({bool microMilestonesRefs})>;
typedef $$MicroMilestonesTableCreateCompanionBuilder = MicroMilestonesCompanion
    Function({
  Value<String> id,
  required String taskId,
  Value<String> userId,
  Value<String> workspaceId,
  Value<String> visibility,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String title,
  Value<int> durationMinutes,
  Value<bool> isDone,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$MicroMilestonesTableUpdateCompanionBuilder = MicroMilestonesCompanion
    Function({
  Value<String> id,
  Value<String> taskId,
  Value<String> userId,
  Value<String> workspaceId,
  Value<String> visibility,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> title,
  Value<int> durationMinutes,
  Value<bool> isDone,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$MicroMilestonesTableReferences extends BaseReferences<
    _$AppDatabase, $MicroMilestonesTable, MicroMilestone> {
  $$MicroMilestonesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PrioTasksTable _taskIdTable(_$AppDatabase db) =>
      db.prioTasks.createAlias('micro_milestones__task_id__prio_tasks__id');

  $$PrioTasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$PrioTasksTableTableManager($_db, $_db.prioTasks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MicroMilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $MicroMilestonesTable> {
  $$MicroMilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$PrioTasksTableFilterComposer get taskId {
    final $$PrioTasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.prioTasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrioTasksTableFilterComposer(
              $db: $db,
              $table: $db.prioTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MicroMilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $MicroMilestonesTable> {
  $$MicroMilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$PrioTasksTableOrderingComposer get taskId {
    final $$PrioTasksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.prioTasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrioTasksTableOrderingComposer(
              $db: $db,
              $table: $db.prioTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MicroMilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MicroMilestonesTable> {
  $$MicroMilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$PrioTasksTableAnnotationComposer get taskId {
    final $$PrioTasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.prioTasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrioTasksTableAnnotationComposer(
              $db: $db,
              $table: $db.prioTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MicroMilestonesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MicroMilestonesTable,
    MicroMilestone,
    $$MicroMilestonesTableFilterComposer,
    $$MicroMilestonesTableOrderingComposer,
    $$MicroMilestonesTableAnnotationComposer,
    $$MicroMilestonesTableCreateCompanionBuilder,
    $$MicroMilestonesTableUpdateCompanionBuilder,
    (MicroMilestone, $$MicroMilestonesTableReferences),
    MicroMilestone,
    PrefetchHooks Function({bool taskId})> {
  $$MicroMilestonesTableTableManager(
      _$AppDatabase db, $MicroMilestonesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MicroMilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MicroMilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MicroMilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MicroMilestonesCompanion(
            id: id,
            taskId: taskId,
            userId: userId,
            workspaceId: workspaceId,
            visibility: visibility,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            title: title,
            durationMinutes: durationMinutes,
            isDone: isDone,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String taskId,
            Value<String> userId = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String title,
            Value<int> durationMinutes = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MicroMilestonesCompanion.insert(
            id: id,
            taskId: taskId,
            userId: userId,
            workspaceId: workspaceId,
            visibility: visibility,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            title: title,
            durationMinutes: durationMinutes,
            isDone: isDone,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MicroMilestonesTable, MicroMilestone>(table),
                    $$MicroMilestonesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (taskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.taskId,
                    referencedTable:
                        $$MicroMilestonesTableReferences._taskIdTable(db),
                    referencedColumn:
                        $$MicroMilestonesTableReferences._taskIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MicroMilestonesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MicroMilestonesTable,
    MicroMilestone,
    $$MicroMilestonesTableFilterComposer,
    $$MicroMilestonesTableOrderingComposer,
    $$MicroMilestonesTableAnnotationComposer,
    $$MicroMilestonesTableCreateCompanionBuilder,
    $$MicroMilestonesTableUpdateCompanionBuilder,
    (MicroMilestone, $$MicroMilestonesTableReferences),
    MicroMilestone,
    PrefetchHooks Function({bool taskId})>;
typedef $$MorningCheckItemsTableCreateCompanionBuilder
    = MorningCheckItemsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> workspaceId,
  Value<String> visibility,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String title,
  Value<String> category,
  Value<bool> isChecked,
  Value<int> sortOrder,
  Value<DateTime?> lastResetAt,
  Value<int> rowid,
});
typedef $$MorningCheckItemsTableUpdateCompanionBuilder
    = MorningCheckItemsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> workspaceId,
  Value<String> visibility,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> title,
  Value<String> category,
  Value<bool> isChecked,
  Value<int> sortOrder,
  Value<DateTime?> lastResetAt,
  Value<int> rowid,
});

class $$MorningCheckItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MorningCheckItemsTable> {
  $$MorningCheckItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastResetAt => $composableBuilder(
      column: $table.lastResetAt, builder: (column) => ColumnFilters(column));
}

class $$MorningCheckItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MorningCheckItemsTable> {
  $$MorningCheckItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastResetAt => $composableBuilder(
      column: $table.lastResetAt, builder: (column) => ColumnOrderings(column));
}

class $$MorningCheckItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MorningCheckItemsTable> {
  $$MorningCheckItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastResetAt => $composableBuilder(
      column: $table.lastResetAt, builder: (column) => column);
}

class $$MorningCheckItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MorningCheckItemsTable,
    MorningCheckItem,
    $$MorningCheckItemsTableFilterComposer,
    $$MorningCheckItemsTableOrderingComposer,
    $$MorningCheckItemsTableAnnotationComposer,
    $$MorningCheckItemsTableCreateCompanionBuilder,
    $$MorningCheckItemsTableUpdateCompanionBuilder,
    (
      MorningCheckItem,
      BaseReferences<_$AppDatabase, $MorningCheckItemsTable, MorningCheckItem>
    ),
    MorningCheckItem,
    PrefetchHooks Function()> {
  $$MorningCheckItemsTableTableManager(
      _$AppDatabase db, $MorningCheckItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MorningCheckItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MorningCheckItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MorningCheckItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<bool> isChecked = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> lastResetAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MorningCheckItemsCompanion(
            id: id,
            userId: userId,
            workspaceId: workspaceId,
            visibility: visibility,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            title: title,
            category: category,
            isChecked: isChecked,
            sortOrder: sortOrder,
            lastResetAt: lastResetAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String title,
            Value<String> category = const Value.absent(),
            Value<bool> isChecked = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> lastResetAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MorningCheckItemsCompanion.insert(
            id: id,
            userId: userId,
            workspaceId: workspaceId,
            visibility: visibility,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            title: title,
            category: category,
            isChecked: isChecked,
            sortOrder: sortOrder,
            lastResetAt: lastResetAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MorningCheckItemsTable, MorningCheckItem>(
                        table),
                    BaseReferences<_$AppDatabase, $MorningCheckItemsTable,
                        MorningCheckItem>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MorningCheckItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MorningCheckItemsTable,
    MorningCheckItem,
    $$MorningCheckItemsTableFilterComposer,
    $$MorningCheckItemsTableOrderingComposer,
    $$MorningCheckItemsTableAnnotationComposer,
    $$MorningCheckItemsTableCreateCompanionBuilder,
    $$MorningCheckItemsTableUpdateCompanionBuilder,
    (
      MorningCheckItem,
      BaseReferences<_$AppDatabase, $MorningCheckItemsTable, MorningCheckItem>
    ),
    MorningCheckItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PrioTasksTableTableManager get prioTasks =>
      $$PrioTasksTableTableManager(_db, _db.prioTasks);
  $$MicroMilestonesTableTableManager get microMilestones =>
      $$MicroMilestonesTableTableManager(_db, _db.microMilestones);
  $$MorningCheckItemsTableTableManager get morningCheckItems =>
      $$MorningCheckItemsTableTableManager(_db, _db.morningCheckItems);
}
