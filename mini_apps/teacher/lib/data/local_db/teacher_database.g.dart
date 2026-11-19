// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_database.dart';

// ignore_for_file: type=lint
class $OutboxMutationsTable extends OutboxMutations
    with TableInfo<$OutboxMutationsTable, OutboxMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientMutationIdMeta = const VerificationMeta(
    'clientMutationId',
  );
  @override
  late final GeneratedColumn<String> clientMutationId = GeneratedColumn<String>(
    'client_mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchKeyMeta = const VerificationMeta(
    'batchKey',
  );
  @override
  late final GeneratedColumn<String> batchKey = GeneratedColumn<String>(
    'batch_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchDeviceTimeMeta = const VerificationMeta(
    'batchDeviceTime',
  );
  @override
  late final GeneratedColumn<DateTime> batchDeviceTime =
      GeneratedColumn<DateTime>(
        'batch_device_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientMutationId,
    entity,
    payload,
    clientUpdatedAt,
    attemptCount,
    lastError,
    sessionId,
    studentId,
    batchKey,
    batchDeviceTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_mutation_id')) {
      context.handle(
        _clientMutationIdMeta,
        clientMutationId.isAcceptableOrUnknown(
          data['client_mutation_id']!,
          _clientMutationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMutationIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('batch_key')) {
      context.handle(
        _batchKeyMeta,
        batchKey.isAcceptableOrUnknown(data['batch_key']!, _batchKeyMeta),
      );
    }
    if (data.containsKey('batch_device_time')) {
      context.handle(
        _batchDeviceTimeMeta,
        batchDeviceTime.isAcceptableOrUnknown(
          data['batch_device_time']!,
          _batchDeviceTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxMutation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_mutation_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      batchKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_key'],
      ),
      batchDeviceTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}batch_device_time'],
      ),
    );
  }

  @override
  $OutboxMutationsTable createAlias(String alias) {
    return $OutboxMutationsTable(attachedDatabase, alias);
  }
}

class OutboxMutation extends DataClass implements Insertable<OutboxMutation> {
  final int id;

  /// UUID do app sinh; API áp dụng mỗi mutation đúng một lần.
  final String clientMutationId;
  final String entity;

  /// JSON của thay đổi.
  final String payload;
  final DateTime clientUpdatedAt;

  /// v2: số lần SyncEngine đã gửi thất bại (để giãn thời gian thử lại).
  final int attemptCount;

  /// v2: mã lỗi lần gửi gần nhất (không lưu body/PII).
  final String? lastError;

  /// v3: buổi và học viên của mutation (null ở dòng cũ của bản spike v2 —
  /// SyncEngine bỏ qua dòng đó). Mỗi lô gửi lên server là một buổi.
  final String? sessionId;
  final String? studentId;

  /// v3: `Idempotency-Key` và `deviceTime` của lô đã gom các dòng này. Lưu lại để
  /// gửi lại sau khi mất phản hồi (kể cả sau khi app bị kill) vẫn đúng khóa và
  /// đúng thân request, server mới nhận ra là cùng lô.
  final String? batchKey;
  final DateTime? batchDeviceTime;
  const OutboxMutation({
    required this.id,
    required this.clientMutationId,
    required this.entity,
    required this.payload,
    required this.clientUpdatedAt,
    required this.attemptCount,
    this.lastError,
    this.sessionId,
    this.studentId,
    this.batchKey,
    this.batchDeviceTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_mutation_id'] = Variable<String>(clientMutationId);
    map['entity'] = Variable<String>(entity);
    map['payload'] = Variable<String>(payload);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    if (!nullToAbsent || batchKey != null) {
      map['batch_key'] = Variable<String>(batchKey);
    }
    if (!nullToAbsent || batchDeviceTime != null) {
      map['batch_device_time'] = Variable<DateTime>(batchDeviceTime);
    }
    return map;
  }

  OutboxMutationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxMutationsCompanion(
      id: Value(id),
      clientMutationId: Value(clientMutationId),
      entity: Value(entity),
      payload: Value(payload),
      clientUpdatedAt: Value(clientUpdatedAt),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      batchKey: batchKey == null && nullToAbsent
          ? const Value.absent()
          : Value(batchKey),
      batchDeviceTime: batchDeviceTime == null && nullToAbsent
          ? const Value.absent()
          : Value(batchDeviceTime),
    );
  }

  factory OutboxMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxMutation(
      id: serializer.fromJson<int>(json['id']),
      clientMutationId: serializer.fromJson<String>(json['clientMutationId']),
      entity: serializer.fromJson<String>(json['entity']),
      payload: serializer.fromJson<String>(json['payload']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      batchKey: serializer.fromJson<String?>(json['batchKey']),
      batchDeviceTime: serializer.fromJson<DateTime?>(json['batchDeviceTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientMutationId': serializer.toJson<String>(clientMutationId),
      'entity': serializer.toJson<String>(entity),
      'payload': serializer.toJson<String>(payload),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'sessionId': serializer.toJson<String?>(sessionId),
      'studentId': serializer.toJson<String?>(studentId),
      'batchKey': serializer.toJson<String?>(batchKey),
      'batchDeviceTime': serializer.toJson<DateTime?>(batchDeviceTime),
    };
  }

  OutboxMutation copyWith({
    int? id,
    String? clientMutationId,
    String? entity,
    String? payload,
    DateTime? clientUpdatedAt,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    Value<String?> studentId = const Value.absent(),
    Value<String?> batchKey = const Value.absent(),
    Value<DateTime?> batchDeviceTime = const Value.absent(),
  }) => OutboxMutation(
    id: id ?? this.id,
    clientMutationId: clientMutationId ?? this.clientMutationId,
    entity: entity ?? this.entity,
    payload: payload ?? this.payload,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    studentId: studentId.present ? studentId.value : this.studentId,
    batchKey: batchKey.present ? batchKey.value : this.batchKey,
    batchDeviceTime: batchDeviceTime.present
        ? batchDeviceTime.value
        : this.batchDeviceTime,
  );
  OutboxMutation copyWithCompanion(OutboxMutationsCompanion data) {
    return OutboxMutation(
      id: data.id.present ? data.id.value : this.id,
      clientMutationId: data.clientMutationId.present
          ? data.clientMutationId.value
          : this.clientMutationId,
      entity: data.entity.present ? data.entity.value : this.entity,
      payload: data.payload.present ? data.payload.value : this.payload,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      batchKey: data.batchKey.present ? data.batchKey.value : this.batchKey,
      batchDeviceTime: data.batchDeviceTime.present
          ? data.batchDeviceTime.value
          : this.batchDeviceTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxMutation(')
          ..write('id: $id, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('entity: $entity, ')
          ..write('payload: $payload, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('batchKey: $batchKey, ')
          ..write('batchDeviceTime: $batchDeviceTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientMutationId,
    entity,
    payload,
    clientUpdatedAt,
    attemptCount,
    lastError,
    sessionId,
    studentId,
    batchKey,
    batchDeviceTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxMutation &&
          other.id == this.id &&
          other.clientMutationId == this.clientMutationId &&
          other.entity == this.entity &&
          other.payload == this.payload &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.sessionId == this.sessionId &&
          other.studentId == this.studentId &&
          other.batchKey == this.batchKey &&
          other.batchDeviceTime == this.batchDeviceTime);
}

class OutboxMutationsCompanion extends UpdateCompanion<OutboxMutation> {
  final Value<int> id;
  final Value<String> clientMutationId;
  final Value<String> entity;
  final Value<String> payload;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<String?> sessionId;
  final Value<String?> studentId;
  final Value<String?> batchKey;
  final Value<DateTime?> batchDeviceTime;
  const OutboxMutationsCompanion({
    this.id = const Value.absent(),
    this.clientMutationId = const Value.absent(),
    this.entity = const Value.absent(),
    this.payload = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.batchKey = const Value.absent(),
    this.batchDeviceTime = const Value.absent(),
  });
  OutboxMutationsCompanion.insert({
    this.id = const Value.absent(),
    required String clientMutationId,
    required String entity,
    required String payload,
    required DateTime clientUpdatedAt,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.batchKey = const Value.absent(),
    this.batchDeviceTime = const Value.absent(),
  }) : clientMutationId = Value(clientMutationId),
       entity = Value(entity),
       payload = Value(payload),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<OutboxMutation> custom({
    Expression<int>? id,
    Expression<String>? clientMutationId,
    Expression<String>? entity,
    Expression<String>? payload,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<String>? sessionId,
    Expression<String>? studentId,
    Expression<String>? batchKey,
    Expression<DateTime>? batchDeviceTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientMutationId != null) 'client_mutation_id': clientMutationId,
      if (entity != null) 'entity': entity,
      if (payload != null) 'payload': payload,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (sessionId != null) 'session_id': sessionId,
      if (studentId != null) 'student_id': studentId,
      if (batchKey != null) 'batch_key': batchKey,
      if (batchDeviceTime != null) 'batch_device_time': batchDeviceTime,
    });
  }

  OutboxMutationsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientMutationId,
    Value<String>? entity,
    Value<String>? payload,
    Value<DateTime>? clientUpdatedAt,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<String?>? sessionId,
    Value<String?>? studentId,
    Value<String?>? batchKey,
    Value<DateTime?>? batchDeviceTime,
  }) {
    return OutboxMutationsCompanion(
      id: id ?? this.id,
      clientMutationId: clientMutationId ?? this.clientMutationId,
      entity: entity ?? this.entity,
      payload: payload ?? this.payload,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      batchKey: batchKey ?? this.batchKey,
      batchDeviceTime: batchDeviceTime ?? this.batchDeviceTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientMutationId.present) {
      map['client_mutation_id'] = Variable<String>(clientMutationId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (batchKey.present) {
      map['batch_key'] = Variable<String>(batchKey.value);
    }
    if (batchDeviceTime.present) {
      map['batch_device_time'] = Variable<DateTime>(batchDeviceTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxMutationsCompanion(')
          ..write('id: $id, ')
          ..write('clientMutationId: $clientMutationId, ')
          ..write('entity: $entity, ')
          ..write('payload: $payload, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('batchKey: $batchKey, ')
          ..write('batchDeviceTime: $batchDeviceTime')
          ..write(')'))
        .toString();
  }
}

class $CachedSessionsTable extends CachedSessions
    with TableInfo<$CachedSessionsTable, CachedSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classIdMeta = const VerificationMeta(
    'classId',
  );
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
    'class_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classNameMeta = const VerificationMeta(
    'className',
  );
  @override
  late final GeneratedColumn<String> className = GeneratedColumn<String>(
    'class_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionDateMeta = const VerificationMeta(
    'sessionDate',
  );
  @override
  late final GeneratedColumn<String> sessionDate = GeneratedColumn<String>(
    'session_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isMakeupMeta = const VerificationMeta(
    'isMakeup',
  );
  @override
  late final GeneratedColumn<bool> isMakeup = GeneratedColumn<bool>(
    'is_makeup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_makeup" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canEditMeta = const VerificationMeta(
    'canEdit',
  );
  @override
  late final GeneratedColumn<bool> canEdit = GeneratedColumn<bool>(
    'can_edit',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_edit" IN (0, 1))',
    ),
  );
  static const VerificationMeta _editableUntilMeta = const VerificationMeta(
    'editableUntil',
  );
  @override
  late final GeneratedColumn<DateTime> editableUntil =
      GeneratedColumn<DateTime>(
        'editable_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rosterFetchedAtMeta = const VerificationMeta(
    'rosterFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> rosterFetchedAt =
      GeneratedColumn<DateTime>(
        'roster_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    classId,
    className,
    sessionDate,
    startsAt,
    endsAt,
    status,
    isMakeup,
    canEdit,
    editableUntil,
    rosterFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(
        _classIdMeta,
        classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta),
      );
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('class_name')) {
      context.handle(
        _classNameMeta,
        className.isAcceptableOrUnknown(data['class_name']!, _classNameMeta),
      );
    } else if (isInserting) {
      context.missing(_classNameMeta);
    }
    if (data.containsKey('session_date')) {
      context.handle(
        _sessionDateMeta,
        sessionDate.isAcceptableOrUnknown(
          data['session_date']!,
          _sessionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionDateMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_makeup')) {
      context.handle(
        _isMakeupMeta,
        isMakeup.isAcceptableOrUnknown(data['is_makeup']!, _isMakeupMeta),
      );
    } else if (isInserting) {
      context.missing(_isMakeupMeta);
    }
    if (data.containsKey('can_edit')) {
      context.handle(
        _canEditMeta,
        canEdit.isAcceptableOrUnknown(data['can_edit']!, _canEditMeta),
      );
    }
    if (data.containsKey('editable_until')) {
      context.handle(
        _editableUntilMeta,
        editableUntil.isAcceptableOrUnknown(
          data['editable_until']!,
          _editableUntilMeta,
        ),
      );
    }
    if (data.containsKey('roster_fetched_at')) {
      context.handle(
        _rosterFetchedAtMeta,
        rosterFetchedAt.isAcceptableOrUnknown(
          data['roster_fetched_at']!,
          _rosterFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      classId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_id'],
      )!,
      className: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_name'],
      )!,
      sessionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_date'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isMakeup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_makeup'],
      )!,
      canEdit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_edit'],
      ),
      editableUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}editable_until'],
      ),
      rosterFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}roster_fetched_at'],
      ),
    );
  }

  @override
  $CachedSessionsTable createAlias(String alias) {
    return $CachedSessionsTable(attachedDatabase, alias);
  }
}

class CachedSession extends DataClass implements Insertable<CachedSession> {
  final String id;
  final String classId;
  final String className;

  /// Ngày buổi học theo múi giờ tenant, `yyyy-MM-dd`.
  final String sessionDate;
  final DateTime startsAt;
  final DateTime endsAt;

  /// `planned` | `taught` | `cancelled`.
  final String status;
  final bool isMakeup;

  /// Chỉ có sau khi tải điểm danh của buổi; null = chưa tải danh sách.
  final bool? canEdit;
  final DateTime? editableUntil;
  final DateTime? rosterFetchedAt;
  const CachedSession({
    required this.id,
    required this.classId,
    required this.className,
    required this.sessionDate,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.isMakeup,
    this.canEdit,
    this.editableUntil,
    this.rosterFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['class_id'] = Variable<String>(classId);
    map['class_name'] = Variable<String>(className);
    map['session_date'] = Variable<String>(sessionDate);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    map['status'] = Variable<String>(status);
    map['is_makeup'] = Variable<bool>(isMakeup);
    if (!nullToAbsent || canEdit != null) {
      map['can_edit'] = Variable<bool>(canEdit);
    }
    if (!nullToAbsent || editableUntil != null) {
      map['editable_until'] = Variable<DateTime>(editableUntil);
    }
    if (!nullToAbsent || rosterFetchedAt != null) {
      map['roster_fetched_at'] = Variable<DateTime>(rosterFetchedAt);
    }
    return map;
  }

  CachedSessionsCompanion toCompanion(bool nullToAbsent) {
    return CachedSessionsCompanion(
      id: Value(id),
      classId: Value(classId),
      className: Value(className),
      sessionDate: Value(sessionDate),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      status: Value(status),
      isMakeup: Value(isMakeup),
      canEdit: canEdit == null && nullToAbsent
          ? const Value.absent()
          : Value(canEdit),
      editableUntil: editableUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(editableUntil),
      rosterFetchedAt: rosterFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rosterFetchedAt),
    );
  }

  factory CachedSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSession(
      id: serializer.fromJson<String>(json['id']),
      classId: serializer.fromJson<String>(json['classId']),
      className: serializer.fromJson<String>(json['className']),
      sessionDate: serializer.fromJson<String>(json['sessionDate']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      status: serializer.fromJson<String>(json['status']),
      isMakeup: serializer.fromJson<bool>(json['isMakeup']),
      canEdit: serializer.fromJson<bool?>(json['canEdit']),
      editableUntil: serializer.fromJson<DateTime?>(json['editableUntil']),
      rosterFetchedAt: serializer.fromJson<DateTime?>(json['rosterFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classId': serializer.toJson<String>(classId),
      'className': serializer.toJson<String>(className),
      'sessionDate': serializer.toJson<String>(sessionDate),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'status': serializer.toJson<String>(status),
      'isMakeup': serializer.toJson<bool>(isMakeup),
      'canEdit': serializer.toJson<bool?>(canEdit),
      'editableUntil': serializer.toJson<DateTime?>(editableUntil),
      'rosterFetchedAt': serializer.toJson<DateTime?>(rosterFetchedAt),
    };
  }

  CachedSession copyWith({
    String? id,
    String? classId,
    String? className,
    String? sessionDate,
    DateTime? startsAt,
    DateTime? endsAt,
    String? status,
    bool? isMakeup,
    Value<bool?> canEdit = const Value.absent(),
    Value<DateTime?> editableUntil = const Value.absent(),
    Value<DateTime?> rosterFetchedAt = const Value.absent(),
  }) => CachedSession(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    className: className ?? this.className,
    sessionDate: sessionDate ?? this.sessionDate,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    status: status ?? this.status,
    isMakeup: isMakeup ?? this.isMakeup,
    canEdit: canEdit.present ? canEdit.value : this.canEdit,
    editableUntil: editableUntil.present
        ? editableUntil.value
        : this.editableUntil,
    rosterFetchedAt: rosterFetchedAt.present
        ? rosterFetchedAt.value
        : this.rosterFetchedAt,
  );
  CachedSession copyWithCompanion(CachedSessionsCompanion data) {
    return CachedSession(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      className: data.className.present ? data.className.value : this.className,
      sessionDate: data.sessionDate.present
          ? data.sessionDate.value
          : this.sessionDate,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      status: data.status.present ? data.status.value : this.status,
      isMakeup: data.isMakeup.present ? data.isMakeup.value : this.isMakeup,
      canEdit: data.canEdit.present ? data.canEdit.value : this.canEdit,
      editableUntil: data.editableUntil.present
          ? data.editableUntil.value
          : this.editableUntil,
      rosterFetchedAt: data.rosterFetchedAt.present
          ? data.rosterFetchedAt.value
          : this.rosterFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSession(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('className: $className, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('status: $status, ')
          ..write('isMakeup: $isMakeup, ')
          ..write('canEdit: $canEdit, ')
          ..write('editableUntil: $editableUntil, ')
          ..write('rosterFetchedAt: $rosterFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classId,
    className,
    sessionDate,
    startsAt,
    endsAt,
    status,
    isMakeup,
    canEdit,
    editableUntil,
    rosterFetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSession &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.className == this.className &&
          other.sessionDate == this.sessionDate &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.status == this.status &&
          other.isMakeup == this.isMakeup &&
          other.canEdit == this.canEdit &&
          other.editableUntil == this.editableUntil &&
          other.rosterFetchedAt == this.rosterFetchedAt);
}

class CachedSessionsCompanion extends UpdateCompanion<CachedSession> {
  final Value<String> id;
  final Value<String> classId;
  final Value<String> className;
  final Value<String> sessionDate;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<String> status;
  final Value<bool> isMakeup;
  final Value<bool?> canEdit;
  final Value<DateTime?> editableUntil;
  final Value<DateTime?> rosterFetchedAt;
  final Value<int> rowid;
  const CachedSessionsCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.className = const Value.absent(),
    this.sessionDate = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.status = const Value.absent(),
    this.isMakeup = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.editableUntil = const Value.absent(),
    this.rosterFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSessionsCompanion.insert({
    required String id,
    required String classId,
    required String className,
    required String sessionDate,
    required DateTime startsAt,
    required DateTime endsAt,
    required String status,
    required bool isMakeup,
    this.canEdit = const Value.absent(),
    this.editableUntil = const Value.absent(),
    this.rosterFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       classId = Value(classId),
       className = Value(className),
       sessionDate = Value(sessionDate),
       startsAt = Value(startsAt),
       endsAt = Value(endsAt),
       status = Value(status),
       isMakeup = Value(isMakeup);
  static Insertable<CachedSession> custom({
    Expression<String>? id,
    Expression<String>? classId,
    Expression<String>? className,
    Expression<String>? sessionDate,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? status,
    Expression<bool>? isMakeup,
    Expression<bool>? canEdit,
    Expression<DateTime>? editableUntil,
    Expression<DateTime>? rosterFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (className != null) 'class_name': className,
      if (sessionDate != null) 'session_date': sessionDate,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (status != null) 'status': status,
      if (isMakeup != null) 'is_makeup': isMakeup,
      if (canEdit != null) 'can_edit': canEdit,
      if (editableUntil != null) 'editable_until': editableUntil,
      if (rosterFetchedAt != null) 'roster_fetched_at': rosterFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? classId,
    Value<String>? className,
    Value<String>? sessionDate,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<String>? status,
    Value<bool>? isMakeup,
    Value<bool?>? canEdit,
    Value<DateTime?>? editableUntil,
    Value<DateTime?>? rosterFetchedAt,
    Value<int>? rowid,
  }) {
    return CachedSessionsCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sessionDate: sessionDate ?? this.sessionDate,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
      isMakeup: isMakeup ?? this.isMakeup,
      canEdit: canEdit ?? this.canEdit,
      editableUntil: editableUntil ?? this.editableUntil,
      rosterFetchedAt: rosterFetchedAt ?? this.rosterFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (className.present) {
      map['class_name'] = Variable<String>(className.value);
    }
    if (sessionDate.present) {
      map['session_date'] = Variable<String>(sessionDate.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isMakeup.present) {
      map['is_makeup'] = Variable<bool>(isMakeup.value);
    }
    if (canEdit.present) {
      map['can_edit'] = Variable<bool>(canEdit.value);
    }
    if (editableUntil.present) {
      map['editable_until'] = Variable<DateTime>(editableUntil.value);
    }
    if (rosterFetchedAt.present) {
      map['roster_fetched_at'] = Variable<DateTime>(rosterFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSessionsCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('className: $className, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('status: $status, ')
          ..write('isMakeup: $isMakeup, ')
          ..write('canEdit: $canEdit, ')
          ..write('editableUntil: $editableUntil, ')
          ..write('rosterFetchedAt: $rosterFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAttendancesTable extends CachedAttendances
    with TableInfo<$CachedAttendancesTable, CachedAttendance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAttendancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    studentId,
    fullName,
    status,
    note,
    clientUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_attendances';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAttendance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, studentId};
  @override
  CachedAttendance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAttendance(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      ),
    );
  }

  @override
  $CachedAttendancesTable createAlias(String alias) {
    return $CachedAttendancesTable(attachedDatabase, alias);
  }
}

class CachedAttendance extends DataClass
    implements Insertable<CachedAttendance> {
  final String sessionId;
  final String studentId;
  final String fullName;

  /// `present` | `late` | `excused` | `unexcused`; null = chưa điểm danh.
  final String? status;
  final String? note;
  final DateTime? clientUpdatedAt;
  const CachedAttendance({
    required this.sessionId,
    required this.studentId,
    required this.fullName,
    this.status,
    this.note,
    this.clientUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['student_id'] = Variable<String>(studentId);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || clientUpdatedAt != null) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    }
    return map;
  }

  CachedAttendancesCompanion toCompanion(bool nullToAbsent) {
    return CachedAttendancesCompanion(
      sessionId: Value(sessionId),
      studentId: Value(studentId),
      fullName: Value(fullName),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientUpdatedAt: clientUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(clientUpdatedAt),
    );
  }

  factory CachedAttendance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAttendance(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      status: serializer.fromJson<String?>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
      clientUpdatedAt: serializer.fromJson<DateTime?>(json['clientUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'studentId': serializer.toJson<String>(studentId),
      'fullName': serializer.toJson<String>(fullName),
      'status': serializer.toJson<String?>(status),
      'note': serializer.toJson<String?>(note),
      'clientUpdatedAt': serializer.toJson<DateTime?>(clientUpdatedAt),
    };
  }

  CachedAttendance copyWith({
    String? sessionId,
    String? studentId,
    String? fullName,
    Value<String?> status = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<DateTime?> clientUpdatedAt = const Value.absent(),
  }) => CachedAttendance(
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    fullName: fullName ?? this.fullName,
    status: status.present ? status.value : this.status,
    note: note.present ? note.value : this.note,
    clientUpdatedAt: clientUpdatedAt.present
        ? clientUpdatedAt.value
        : this.clientUpdatedAt,
  );
  CachedAttendance copyWithCompanion(CachedAttendancesCompanion data) {
    return CachedAttendance(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAttendance(')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('fullName: $fullName, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    studentId,
    fullName,
    status,
    note,
    clientUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAttendance &&
          other.sessionId == this.sessionId &&
          other.studentId == this.studentId &&
          other.fullName == this.fullName &&
          other.status == this.status &&
          other.note == this.note &&
          other.clientUpdatedAt == this.clientUpdatedAt);
}

class CachedAttendancesCompanion extends UpdateCompanion<CachedAttendance> {
  final Value<String> sessionId;
  final Value<String> studentId;
  final Value<String> fullName;
  final Value<String?> status;
  final Value<String?> note;
  final Value<DateTime?> clientUpdatedAt;
  final Value<int> rowid;
  const CachedAttendancesCompanion({
    this.sessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAttendancesCompanion.insert({
    required String sessionId,
    required String studentId,
    required String fullName,
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       studentId = Value(studentId),
       fullName = Value(fullName);
  static Insertable<CachedAttendance> custom({
    Expression<String>? sessionId,
    Expression<String>? studentId,
    Expression<String>? fullName,
    Expression<String>? status,
    Expression<String>? note,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (studentId != null) 'student_id': studentId,
      if (fullName != null) 'full_name': fullName,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAttendancesCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? studentId,
    Value<String>? fullName,
    Value<String?>? status,
    Value<String?>? note,
    Value<DateTime?>? clientUpdatedAt,
    Value<int>? rowid,
  }) {
    return CachedAttendancesCompanion(
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      status: status ?? this.status,
      note: note ?? this.note,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAttendancesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('fullName: $fullName, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TeacherDatabase extends GeneratedDatabase {
  _$TeacherDatabase(QueryExecutor e) : super(e);
  $TeacherDatabaseManager get managers => $TeacherDatabaseManager(this);
  late final $OutboxMutationsTable outboxMutations = $OutboxMutationsTable(
    this,
  );
  late final $CachedSessionsTable cachedSessions = $CachedSessionsTable(this);
  late final $CachedAttendancesTable cachedAttendances =
      $CachedAttendancesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxMutations,
    cachedSessions,
    cachedAttendances,
  ];
}

typedef $$OutboxMutationsTableCreateCompanionBuilder =
    OutboxMutationsCompanion Function({
      Value<int> id,
      required String clientMutationId,
      required String entity,
      required String payload,
      required DateTime clientUpdatedAt,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<String?> sessionId,
      Value<String?> studentId,
      Value<String?> batchKey,
      Value<DateTime?> batchDeviceTime,
    });
typedef $$OutboxMutationsTableUpdateCompanionBuilder =
    OutboxMutationsCompanion Function({
      Value<int> id,
      Value<String> clientMutationId,
      Value<String> entity,
      Value<String> payload,
      Value<DateTime> clientUpdatedAt,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<String?> sessionId,
      Value<String?> studentId,
      Value<String?> batchKey,
      Value<DateTime?> batchDeviceTime,
    });

class $$OutboxMutationsTableFilterComposer
    extends Composer<_$TeacherDatabase, $OutboxMutationsTable> {
  $$OutboxMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchKey => $composableBuilder(
    column: $table.batchKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get batchDeviceTime => $composableBuilder(
    column: $table.batchDeviceTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxMutationsTableOrderingComposer
    extends Composer<_$TeacherDatabase, $OutboxMutationsTable> {
  $$OutboxMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchKey => $composableBuilder(
    column: $table.batchKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get batchDeviceTime => $composableBuilder(
    column: $table.batchDeviceTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxMutationsTableAnnotationComposer
    extends Composer<_$TeacherDatabase, $OutboxMutationsTable> {
  $$OutboxMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get batchKey =>
      $composableBuilder(column: $table.batchKey, builder: (column) => column);

  GeneratedColumn<DateTime> get batchDeviceTime => $composableBuilder(
    column: $table.batchDeviceTime,
    builder: (column) => column,
  );
}

class $$OutboxMutationsTableTableManager
    extends
        RootTableManager<
          _$TeacherDatabase,
          $OutboxMutationsTable,
          OutboxMutation,
          $$OutboxMutationsTableFilterComposer,
          $$OutboxMutationsTableOrderingComposer,
          $$OutboxMutationsTableAnnotationComposer,
          $$OutboxMutationsTableCreateCompanionBuilder,
          $$OutboxMutationsTableUpdateCompanionBuilder,
          (
            OutboxMutation,
            BaseReferences<
              _$TeacherDatabase,
              $OutboxMutationsTable,
              OutboxMutation
            >,
          ),
          OutboxMutation,
          PrefetchHooks Function()
        > {
  $$OutboxMutationsTableTableManager(
    _$TeacherDatabase db,
    $OutboxMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientMutationId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> batchKey = const Value.absent(),
                Value<DateTime?> batchDeviceTime = const Value.absent(),
              }) => OutboxMutationsCompanion(
                id: id,
                clientMutationId: clientMutationId,
                entity: entity,
                payload: payload,
                clientUpdatedAt: clientUpdatedAt,
                attemptCount: attemptCount,
                lastError: lastError,
                sessionId: sessionId,
                studentId: studentId,
                batchKey: batchKey,
                batchDeviceTime: batchDeviceTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientMutationId,
                required String entity,
                required String payload,
                required DateTime clientUpdatedAt,
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> batchKey = const Value.absent(),
                Value<DateTime?> batchDeviceTime = const Value.absent(),
              }) => OutboxMutationsCompanion.insert(
                id: id,
                clientMutationId: clientMutationId,
                entity: entity,
                payload: payload,
                clientUpdatedAt: clientUpdatedAt,
                attemptCount: attemptCount,
                lastError: lastError,
                sessionId: sessionId,
                studentId: studentId,
                batchKey: batchKey,
                batchDeviceTime: batchDeviceTime,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxMutationsTable, OutboxMutation>(table),
                  BaseReferences<
                    _$TeacherDatabase,
                    $OutboxMutationsTable,
                    OutboxMutation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$TeacherDatabase,
      $OutboxMutationsTable,
      OutboxMutation,
      $$OutboxMutationsTableFilterComposer,
      $$OutboxMutationsTableOrderingComposer,
      $$OutboxMutationsTableAnnotationComposer,
      $$OutboxMutationsTableCreateCompanionBuilder,
      $$OutboxMutationsTableUpdateCompanionBuilder,
      (
        OutboxMutation,
        BaseReferences<
          _$TeacherDatabase,
          $OutboxMutationsTable,
          OutboxMutation
        >,
      ),
      OutboxMutation,
      PrefetchHooks Function()
    >;
typedef $$CachedSessionsTableCreateCompanionBuilder =
    CachedSessionsCompanion Function({
      required String id,
      required String classId,
      required String className,
      required String sessionDate,
      required DateTime startsAt,
      required DateTime endsAt,
      required String status,
      required bool isMakeup,
      Value<bool?> canEdit,
      Value<DateTime?> editableUntil,
      Value<DateTime?> rosterFetchedAt,
      Value<int> rowid,
    });
typedef $$CachedSessionsTableUpdateCompanionBuilder =
    CachedSessionsCompanion Function({
      Value<String> id,
      Value<String> classId,
      Value<String> className,
      Value<String> sessionDate,
      Value<DateTime> startsAt,
      Value<DateTime> endsAt,
      Value<String> status,
      Value<bool> isMakeup,
      Value<bool?> canEdit,
      Value<DateTime?> editableUntil,
      Value<DateTime?> rosterFetchedAt,
      Value<int> rowid,
    });

class $$CachedSessionsTableFilterComposer
    extends Composer<_$TeacherDatabase, $CachedSessionsTable> {
  $$CachedSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classId => $composableBuilder(
    column: $table.classId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get className => $composableBuilder(
    column: $table.className,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMakeup => $composableBuilder(
    column: $table.isMakeup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editableUntil => $composableBuilder(
    column: $table.editableUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rosterFetchedAt => $composableBuilder(
    column: $table.rosterFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSessionsTableOrderingComposer
    extends Composer<_$TeacherDatabase, $CachedSessionsTable> {
  $$CachedSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classId => $composableBuilder(
    column: $table.classId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get className => $composableBuilder(
    column: $table.className,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMakeup => $composableBuilder(
    column: $table.isMakeup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editableUntil => $composableBuilder(
    column: $table.editableUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rosterFetchedAt => $composableBuilder(
    column: $table.rosterFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSessionsTableAnnotationComposer
    extends Composer<_$TeacherDatabase, $CachedSessionsTable> {
  $$CachedSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<String> get className =>
      $composableBuilder(column: $table.className, builder: (column) => column);

  GeneratedColumn<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isMakeup =>
      $composableBuilder(column: $table.isMakeup, builder: (column) => column);

  GeneratedColumn<bool> get canEdit =>
      $composableBuilder(column: $table.canEdit, builder: (column) => column);

  GeneratedColumn<DateTime> get editableUntil => $composableBuilder(
    column: $table.editableUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rosterFetchedAt => $composableBuilder(
    column: $table.rosterFetchedAt,
    builder: (column) => column,
  );
}

class $$CachedSessionsTableTableManager
    extends
        RootTableManager<
          _$TeacherDatabase,
          $CachedSessionsTable,
          CachedSession,
          $$CachedSessionsTableFilterComposer,
          $$CachedSessionsTableOrderingComposer,
          $$CachedSessionsTableAnnotationComposer,
          $$CachedSessionsTableCreateCompanionBuilder,
          $$CachedSessionsTableUpdateCompanionBuilder,
          (
            CachedSession,
            BaseReferences<
              _$TeacherDatabase,
              $CachedSessionsTable,
              CachedSession
            >,
          ),
          CachedSession,
          PrefetchHooks Function()
        > {
  $$CachedSessionsTableTableManager(
    _$TeacherDatabase db,
    $CachedSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> classId = const Value.absent(),
                Value<String> className = const Value.absent(),
                Value<String> sessionDate = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime> endsAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isMakeup = const Value.absent(),
                Value<bool?> canEdit = const Value.absent(),
                Value<DateTime?> editableUntil = const Value.absent(),
                Value<DateTime?> rosterFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSessionsCompanion(
                id: id,
                classId: classId,
                className: className,
                sessionDate: sessionDate,
                startsAt: startsAt,
                endsAt: endsAt,
                status: status,
                isMakeup: isMakeup,
                canEdit: canEdit,
                editableUntil: editableUntil,
                rosterFetchedAt: rosterFetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String classId,
                required String className,
                required String sessionDate,
                required DateTime startsAt,
                required DateTime endsAt,
                required String status,
                required bool isMakeup,
                Value<bool?> canEdit = const Value.absent(),
                Value<DateTime?> editableUntil = const Value.absent(),
                Value<DateTime?> rosterFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSessionsCompanion.insert(
                id: id,
                classId: classId,
                className: className,
                sessionDate: sessionDate,
                startsAt: startsAt,
                endsAt: endsAt,
                status: status,
                isMakeup: isMakeup,
                canEdit: canEdit,
                editableUntil: editableUntil,
                rosterFetchedAt: rosterFetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedSessionsTable, CachedSession>(table),
                  BaseReferences<
                    _$TeacherDatabase,
                    $CachedSessionsTable,
                    CachedSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$TeacherDatabase,
      $CachedSessionsTable,
      CachedSession,
      $$CachedSessionsTableFilterComposer,
      $$CachedSessionsTableOrderingComposer,
      $$CachedSessionsTableAnnotationComposer,
      $$CachedSessionsTableCreateCompanionBuilder,
      $$CachedSessionsTableUpdateCompanionBuilder,
      (
        CachedSession,
        BaseReferences<_$TeacherDatabase, $CachedSessionsTable, CachedSession>,
      ),
      CachedSession,
      PrefetchHooks Function()
    >;
typedef $$CachedAttendancesTableCreateCompanionBuilder =
    CachedAttendancesCompanion Function({
      required String sessionId,
      required String studentId,
      required String fullName,
      Value<String?> status,
      Value<String?> note,
      Value<DateTime?> clientUpdatedAt,
      Value<int> rowid,
    });
typedef $$CachedAttendancesTableUpdateCompanionBuilder =
    CachedAttendancesCompanion Function({
      Value<String> sessionId,
      Value<String> studentId,
      Value<String> fullName,
      Value<String?> status,
      Value<String?> note,
      Value<DateTime?> clientUpdatedAt,
      Value<int> rowid,
    });

class $$CachedAttendancesTableFilterComposer
    extends Composer<_$TeacherDatabase, $CachedAttendancesTable> {
  $$CachedAttendancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAttendancesTableOrderingComposer
    extends Composer<_$TeacherDatabase, $CachedAttendancesTable> {
  $$CachedAttendancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAttendancesTableAnnotationComposer
    extends Composer<_$TeacherDatabase, $CachedAttendancesTable> {
  $$CachedAttendancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );
}

class $$CachedAttendancesTableTableManager
    extends
        RootTableManager<
          _$TeacherDatabase,
          $CachedAttendancesTable,
          CachedAttendance,
          $$CachedAttendancesTableFilterComposer,
          $$CachedAttendancesTableOrderingComposer,
          $$CachedAttendancesTableAnnotationComposer,
          $$CachedAttendancesTableCreateCompanionBuilder,
          $$CachedAttendancesTableUpdateCompanionBuilder,
          (
            CachedAttendance,
            BaseReferences<
              _$TeacherDatabase,
              $CachedAttendancesTable,
              CachedAttendance
            >,
          ),
          CachedAttendance,
          PrefetchHooks Function()
        > {
  $$CachedAttendancesTableTableManager(
    _$TeacherDatabase db,
    $CachedAttendancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAttendancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAttendancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAttendancesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAttendancesCompanion(
                sessionId: sessionId,
                studentId: studentId,
                fullName: fullName,
                status: status,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String studentId,
                required String fullName,
                Value<String?> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> clientUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAttendancesCompanion.insert(
                sessionId: sessionId,
                studentId: studentId,
                fullName: fullName,
                status: status,
                note: note,
                clientUpdatedAt: clientUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedAttendancesTable, CachedAttendance>(table),
                  BaseReferences<
                    _$TeacherDatabase,
                    $CachedAttendancesTable,
                    CachedAttendance
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAttendancesTableProcessedTableManager =
    ProcessedTableManager<
      _$TeacherDatabase,
      $CachedAttendancesTable,
      CachedAttendance,
      $$CachedAttendancesTableFilterComposer,
      $$CachedAttendancesTableOrderingComposer,
      $$CachedAttendancesTableAnnotationComposer,
      $$CachedAttendancesTableCreateCompanionBuilder,
      $$CachedAttendancesTableUpdateCompanionBuilder,
      (
        CachedAttendance,
        BaseReferences<
          _$TeacherDatabase,
          $CachedAttendancesTable,
          CachedAttendance
        >,
      ),
      CachedAttendance,
      PrefetchHooks Function()
    >;

class $TeacherDatabaseManager {
  final _$TeacherDatabase _db;
  $TeacherDatabaseManager(this._db);
  $$OutboxMutationsTableTableManager get outboxMutations =>
      $$OutboxMutationsTableTableManager(_db, _db.outboxMutations);
  $$CachedSessionsTableTableManager get cachedSessions =>
      $$CachedSessionsTableTableManager(_db, _db.cachedSessions);
  $$CachedAttendancesTableTableManager get cachedAttendances =>
      $$CachedAttendancesTableTableManager(_db, _db.cachedAttendances);
}
