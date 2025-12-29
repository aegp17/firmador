// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collaborative_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CollaborativeSession {
  String get sessionId => throw _privateConstructorUsedError;
  String get documentName => throw _privateConstructorUsedError;
  String get documentPath => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get ownerName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  List<Participant> get participants => throw _privateConstructorUsedError;
  List<Signature> get signatures => throw _privateConstructorUsedError;
  SessionStatus get status => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Create a copy of CollaborativeSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollaborativeSessionCopyWith<CollaborativeSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollaborativeSessionCopyWith<$Res> {
  factory $CollaborativeSessionCopyWith(
    CollaborativeSession value,
    $Res Function(CollaborativeSession) then,
  ) = _$CollaborativeSessionCopyWithImpl<$Res, CollaborativeSession>;
  @useResult
  $Res call({
    String sessionId,
    String documentName,
    String documentPath,
    String ownerId,
    String ownerName,
    DateTime createdAt,
    DateTime expiresAt,
    List<Participant> participants,
    List<Signature> signatures,
    SessionStatus status,
    String? description,
  });
}

/// @nodoc
class _$CollaborativeSessionCopyWithImpl<
  $Res,
  $Val extends CollaborativeSession
>
    implements $CollaborativeSessionCopyWith<$Res> {
  _$CollaborativeSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollaborativeSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? documentName = null,
    Object? documentPath = null,
    Object? ownerId = null,
    Object? ownerName = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? participants = null,
    Object? signatures = null,
    Object? status = null,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            documentName: null == documentName
                ? _value.documentName
                : documentName // ignore: cast_nullable_to_non_nullable
                      as String,
            documentPath: null == documentPath
                ? _value.documentPath
                : documentPath // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerName: null == ownerName
                ? _value.ownerName
                : ownerName // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            participants: null == participants
                ? _value.participants
                : participants // ignore: cast_nullable_to_non_nullable
                      as List<Participant>,
            signatures: null == signatures
                ? _value.signatures
                : signatures // ignore: cast_nullable_to_non_nullable
                      as List<Signature>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as SessionStatus,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollaborativeSessionImplCopyWith<$Res>
    implements $CollaborativeSessionCopyWith<$Res> {
  factory _$$CollaborativeSessionImplCopyWith(
    _$CollaborativeSessionImpl value,
    $Res Function(_$CollaborativeSessionImpl) then,
  ) = __$$CollaborativeSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sessionId,
    String documentName,
    String documentPath,
    String ownerId,
    String ownerName,
    DateTime createdAt,
    DateTime expiresAt,
    List<Participant> participants,
    List<Signature> signatures,
    SessionStatus status,
    String? description,
  });
}

/// @nodoc
class __$$CollaborativeSessionImplCopyWithImpl<$Res>
    extends _$CollaborativeSessionCopyWithImpl<$Res, _$CollaborativeSessionImpl>
    implements _$$CollaborativeSessionImplCopyWith<$Res> {
  __$$CollaborativeSessionImplCopyWithImpl(
    _$CollaborativeSessionImpl _value,
    $Res Function(_$CollaborativeSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollaborativeSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? documentName = null,
    Object? documentPath = null,
    Object? ownerId = null,
    Object? ownerName = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? participants = null,
    Object? signatures = null,
    Object? status = null,
    Object? description = freezed,
  }) {
    return _then(
      _$CollaborativeSessionImpl(
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        documentName: null == documentName
            ? _value.documentName
            : documentName // ignore: cast_nullable_to_non_nullable
                  as String,
        documentPath: null == documentPath
            ? _value.documentPath
            : documentPath // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerName: null == ownerName
            ? _value.ownerName
            : ownerName // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        participants: null == participants
            ? _value._participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<Participant>,
        signatures: null == signatures
            ? _value._signatures
            : signatures // ignore: cast_nullable_to_non_nullable
                  as List<Signature>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SessionStatus,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$CollaborativeSessionImpl implements _CollaborativeSession {
  const _$CollaborativeSessionImpl({
    required this.sessionId,
    required this.documentName,
    required this.documentPath,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    required this.expiresAt,
    final List<Participant> participants = const [],
    final List<Signature> signatures = const [],
    this.status = SessionStatus.pending,
    this.description,
  }) : _participants = participants,
       _signatures = signatures;

  @override
  final String sessionId;
  @override
  final String documentName;
  @override
  final String documentPath;
  @override
  final String ownerId;
  @override
  final String ownerName;
  @override
  final DateTime createdAt;
  @override
  final DateTime expiresAt;
  final List<Participant> _participants;
  @override
  @JsonKey()
  List<Participant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  final List<Signature> _signatures;
  @override
  @JsonKey()
  List<Signature> get signatures {
    if (_signatures is EqualUnmodifiableListView) return _signatures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_signatures);
  }

  @override
  @JsonKey()
  final SessionStatus status;
  @override
  final String? description;

  @override
  String toString() {
    return 'CollaborativeSession(sessionId: $sessionId, documentName: $documentName, documentPath: $documentPath, ownerId: $ownerId, ownerName: $ownerName, createdAt: $createdAt, expiresAt: $expiresAt, participants: $participants, signatures: $signatures, status: $status, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollaborativeSessionImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.documentName, documentName) ||
                other.documentName == documentName) &&
            (identical(other.documentPath, documentPath) ||
                other.documentPath == documentPath) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.ownerName, ownerName) ||
                other.ownerName == ownerName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            const DeepCollectionEquality().equals(
              other._participants,
              _participants,
            ) &&
            const DeepCollectionEquality().equals(
              other._signatures,
              _signatures,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessionId,
    documentName,
    documentPath,
    ownerId,
    ownerName,
    createdAt,
    expiresAt,
    const DeepCollectionEquality().hash(_participants),
    const DeepCollectionEquality().hash(_signatures),
    status,
    description,
  );

  /// Create a copy of CollaborativeSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollaborativeSessionImplCopyWith<_$CollaborativeSessionImpl>
  get copyWith =>
      __$$CollaborativeSessionImplCopyWithImpl<_$CollaborativeSessionImpl>(
        this,
        _$identity,
      );
}

abstract class _CollaborativeSession implements CollaborativeSession {
  const factory _CollaborativeSession({
    required final String sessionId,
    required final String documentName,
    required final String documentPath,
    required final String ownerId,
    required final String ownerName,
    required final DateTime createdAt,
    required final DateTime expiresAt,
    final List<Participant> participants,
    final List<Signature> signatures,
    final SessionStatus status,
    final String? description,
  }) = _$CollaborativeSessionImpl;

  @override
  String get sessionId;
  @override
  String get documentName;
  @override
  String get documentPath;
  @override
  String get ownerId;
  @override
  String get ownerName;
  @override
  DateTime get createdAt;
  @override
  DateTime get expiresAt;
  @override
  List<Participant> get participants;
  @override
  List<Signature> get signatures;
  @override
  SessionStatus get status;
  @override
  String? get description;

  /// Create a copy of CollaborativeSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollaborativeSessionImplCopyWith<_$CollaborativeSessionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Participant {
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  ParticipantRole get role => throw _privateConstructorUsedError;
  DateTime get invitedAt => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get signedAt => throw _privateConstructorUsedError;
  ParticipantStatus get status => throw _privateConstructorUsedError;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParticipantCopyWith<Participant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParticipantCopyWith<$Res> {
  factory $ParticipantCopyWith(
    Participant value,
    $Res Function(Participant) then,
  ) = _$ParticipantCopyWithImpl<$Res, Participant>;
  @useResult
  $Res call({
    String userId,
    String userName,
    String email,
    ParticipantRole role,
    DateTime invitedAt,
    DateTime? joinedAt,
    DateTime? signedAt,
    ParticipantStatus status,
  });
}

/// @nodoc
class _$ParticipantCopyWithImpl<$Res, $Val extends Participant>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? email = null,
    Object? role = null,
    Object? invitedAt = null,
    Object? joinedAt = freezed,
    Object? signedAt = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as ParticipantRole,
            invitedAt: null == invitedAt
                ? _value.invitedAt
                : invitedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            joinedAt: freezed == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            signedAt: freezed == signedAt
                ? _value.signedAt
                : signedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ParticipantStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ParticipantImplCopyWith<$Res>
    implements $ParticipantCopyWith<$Res> {
  factory _$$ParticipantImplCopyWith(
    _$ParticipantImpl value,
    $Res Function(_$ParticipantImpl) then,
  ) = __$$ParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String userName,
    String email,
    ParticipantRole role,
    DateTime invitedAt,
    DateTime? joinedAt,
    DateTime? signedAt,
    ParticipantStatus status,
  });
}

/// @nodoc
class __$$ParticipantImplCopyWithImpl<$Res>
    extends _$ParticipantCopyWithImpl<$Res, _$ParticipantImpl>
    implements _$$ParticipantImplCopyWith<$Res> {
  __$$ParticipantImplCopyWithImpl(
    _$ParticipantImpl _value,
    $Res Function(_$ParticipantImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? email = null,
    Object? role = null,
    Object? invitedAt = null,
    Object? joinedAt = freezed,
    Object? signedAt = freezed,
    Object? status = null,
  }) {
    return _then(
      _$ParticipantImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as ParticipantRole,
        invitedAt: null == invitedAt
            ? _value.invitedAt
            : invitedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        joinedAt: freezed == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        signedAt: freezed == signedAt
            ? _value.signedAt
            : signedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ParticipantStatus,
      ),
    );
  }
}

/// @nodoc

class _$ParticipantImpl implements _Participant {
  const _$ParticipantImpl({
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
    required this.invitedAt,
    this.joinedAt,
    this.signedAt,
    this.status = ParticipantStatus.invited,
  });

  @override
  final String userId;
  @override
  final String userName;
  @override
  final String email;
  @override
  final ParticipantRole role;
  @override
  final DateTime invitedAt;
  @override
  final DateTime? joinedAt;
  @override
  final DateTime? signedAt;
  @override
  @JsonKey()
  final ParticipantStatus status;

  @override
  String toString() {
    return 'Participant(userId: $userId, userName: $userName, email: $email, role: $role, invitedAt: $invitedAt, joinedAt: $joinedAt, signedAt: $signedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParticipantImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.invitedAt, invitedAt) ||
                other.invitedAt == invitedAt) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.signedAt, signedAt) ||
                other.signedAt == signedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    userName,
    email,
    role,
    invitedAt,
    joinedAt,
    signedAt,
    status,
  );

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      __$$ParticipantImplCopyWithImpl<_$ParticipantImpl>(this, _$identity);
}

abstract class _Participant implements Participant {
  const factory _Participant({
    required final String userId,
    required final String userName,
    required final String email,
    required final ParticipantRole role,
    required final DateTime invitedAt,
    final DateTime? joinedAt,
    final DateTime? signedAt,
    final ParticipantStatus status,
  }) = _$ParticipantImpl;

  @override
  String get userId;
  @override
  String get userName;
  @override
  String get email;
  @override
  ParticipantRole get role;
  @override
  DateTime get invitedAt;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get signedAt;
  @override
  ParticipantStatus get status;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Signature {
  String get signatureId => throw _privateConstructorUsedError;
  String get participantId => throw _privateConstructorUsedError;
  String get participantName => throw _privateConstructorUsedError;
  DateTime get signedAt => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;
  String? get certificateThumbprint => throw _privateConstructorUsedError;
  String? get signatureImagePath => throw _privateConstructorUsedError;

  /// Create a copy of Signature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SignatureCopyWith<Signature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignatureCopyWith<$Res> {
  factory $SignatureCopyWith(Signature value, $Res Function(Signature) then) =
      _$SignatureCopyWithImpl<$Res, Signature>;
  @useResult
  $Res call({
    String signatureId,
    String participantId,
    String participantName,
    DateTime signedAt,
    int page,
    double x,
    double y,
    String? certificateThumbprint,
    String? signatureImagePath,
  });
}

/// @nodoc
class _$SignatureCopyWithImpl<$Res, $Val extends Signature>
    implements $SignatureCopyWith<$Res> {
  _$SignatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Signature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signatureId = null,
    Object? participantId = null,
    Object? participantName = null,
    Object? signedAt = null,
    Object? page = null,
    Object? x = null,
    Object? y = null,
    Object? certificateThumbprint = freezed,
    Object? signatureImagePath = freezed,
  }) {
    return _then(
      _value.copyWith(
            signatureId: null == signatureId
                ? _value.signatureId
                : signatureId // ignore: cast_nullable_to_non_nullable
                      as String,
            participantId: null == participantId
                ? _value.participantId
                : participantId // ignore: cast_nullable_to_non_nullable
                      as String,
            participantName: null == participantName
                ? _value.participantName
                : participantName // ignore: cast_nullable_to_non_nullable
                      as String,
            signedAt: null == signedAt
                ? _value.signedAt
                : signedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
            certificateThumbprint: freezed == certificateThumbprint
                ? _value.certificateThumbprint
                : certificateThumbprint // ignore: cast_nullable_to_non_nullable
                      as String?,
            signatureImagePath: freezed == signatureImagePath
                ? _value.signatureImagePath
                : signatureImagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SignatureImplCopyWith<$Res>
    implements $SignatureCopyWith<$Res> {
  factory _$$SignatureImplCopyWith(
    _$SignatureImpl value,
    $Res Function(_$SignatureImpl) then,
  ) = __$$SignatureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String signatureId,
    String participantId,
    String participantName,
    DateTime signedAt,
    int page,
    double x,
    double y,
    String? certificateThumbprint,
    String? signatureImagePath,
  });
}

/// @nodoc
class __$$SignatureImplCopyWithImpl<$Res>
    extends _$SignatureCopyWithImpl<$Res, _$SignatureImpl>
    implements _$$SignatureImplCopyWith<$Res> {
  __$$SignatureImplCopyWithImpl(
    _$SignatureImpl _value,
    $Res Function(_$SignatureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Signature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signatureId = null,
    Object? participantId = null,
    Object? participantName = null,
    Object? signedAt = null,
    Object? page = null,
    Object? x = null,
    Object? y = null,
    Object? certificateThumbprint = freezed,
    Object? signatureImagePath = freezed,
  }) {
    return _then(
      _$SignatureImpl(
        signatureId: null == signatureId
            ? _value.signatureId
            : signatureId // ignore: cast_nullable_to_non_nullable
                  as String,
        participantId: null == participantId
            ? _value.participantId
            : participantId // ignore: cast_nullable_to_non_nullable
                  as String,
        participantName: null == participantName
            ? _value.participantName
            : participantName // ignore: cast_nullable_to_non_nullable
                  as String,
        signedAt: null == signedAt
            ? _value.signedAt
            : signedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
        certificateThumbprint: freezed == certificateThumbprint
            ? _value.certificateThumbprint
            : certificateThumbprint // ignore: cast_nullable_to_non_nullable
                  as String?,
        signatureImagePath: freezed == signatureImagePath
            ? _value.signatureImagePath
            : signatureImagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SignatureImpl implements _Signature {
  const _$SignatureImpl({
    required this.signatureId,
    required this.participantId,
    required this.participantName,
    required this.signedAt,
    required this.page,
    required this.x,
    required this.y,
    this.certificateThumbprint,
    this.signatureImagePath,
  });

  @override
  final String signatureId;
  @override
  final String participantId;
  @override
  final String participantName;
  @override
  final DateTime signedAt;
  @override
  final int page;
  @override
  final double x;
  @override
  final double y;
  @override
  final String? certificateThumbprint;
  @override
  final String? signatureImagePath;

  @override
  String toString() {
    return 'Signature(signatureId: $signatureId, participantId: $participantId, participantName: $participantName, signedAt: $signedAt, page: $page, x: $x, y: $y, certificateThumbprint: $certificateThumbprint, signatureImagePath: $signatureImagePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignatureImpl &&
            (identical(other.signatureId, signatureId) ||
                other.signatureId == signatureId) &&
            (identical(other.participantId, participantId) ||
                other.participantId == participantId) &&
            (identical(other.participantName, participantName) ||
                other.participantName == participantName) &&
            (identical(other.signedAt, signedAt) ||
                other.signedAt == signedAt) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.certificateThumbprint, certificateThumbprint) ||
                other.certificateThumbprint == certificateThumbprint) &&
            (identical(other.signatureImagePath, signatureImagePath) ||
                other.signatureImagePath == signatureImagePath));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    signatureId,
    participantId,
    participantName,
    signedAt,
    page,
    x,
    y,
    certificateThumbprint,
    signatureImagePath,
  );

  /// Create a copy of Signature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignatureImplCopyWith<_$SignatureImpl> get copyWith =>
      __$$SignatureImplCopyWithImpl<_$SignatureImpl>(this, _$identity);
}

abstract class _Signature implements Signature {
  const factory _Signature({
    required final String signatureId,
    required final String participantId,
    required final String participantName,
    required final DateTime signedAt,
    required final int page,
    required final double x,
    required final double y,
    final String? certificateThumbprint,
    final String? signatureImagePath,
  }) = _$SignatureImpl;

  @override
  String get signatureId;
  @override
  String get participantId;
  @override
  String get participantName;
  @override
  DateTime get signedAt;
  @override
  int get page;
  @override
  double get x;
  @override
  double get y;
  @override
  String? get certificateThumbprint;
  @override
  String? get signatureImagePath;

  /// Create a copy of Signature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignatureImplCopyWith<_$SignatureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
