import 'package:freezed_annotation/freezed_annotation.dart';

part 'collaborative_session.freezed.dart';

/// Represents a collaborative signing session
@freezed
class CollaborativeSession with _$CollaborativeSession {
  const factory CollaborativeSession({
    required String sessionId,
    required String documentName,
    required String documentPath,
    required String ownerId,
    required String ownerName,
    required DateTime createdAt,
    required DateTime expiresAt,
    @Default([]) List<Participant> participants,
    @Default([]) List<Signature> signatures,
    @Default(SessionStatus.pending) SessionStatus status,
    String? description,
  }) = _CollaborativeSession;

  factory CollaborativeSession.fromMap(Map<String, dynamic> map) {
    return CollaborativeSession(
      sessionId: map['sessionId'] as String,
      documentName: map['documentName'] as String,
      documentPath: map['documentPath'] as String,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      participants: (map['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      signatures: (map['signatures'] as List<dynamic>?)
              ?.map((s) => Signature.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${map['status']}',
        orElse: () => SessionStatus.pending,
      ),
      description: map['description'] as String?,
    );
  }
}

/// Represents a participant in a collaborative session
@freezed
class Participant with _$Participant {
  const factory Participant({
    required String userId,
    required String userName,
    required String email,
    required ParticipantRole role,
    required DateTime invitedAt,
    DateTime? joinedAt,
    DateTime? signedAt,
    @Default(ParticipantStatus.invited) ParticipantStatus status,
  }) = _Participant;

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      email: map['email'] as String,
      role: ParticipantRole.values.firstWhere(
        (e) => e.toString() == 'ParticipantRole.${map['role']}',
        orElse: () => ParticipantRole.signer,
      ),
      invitedAt: DateTime.parse(map['invitedAt'] as String),
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'] as String)
          : null,
      signedAt: map['signedAt'] != null
          ? DateTime.parse(map['signedAt'] as String)
          : null,
      status: ParticipantStatus.values.firstWhere(
        (e) => e.toString() == 'ParticipantStatus.${map['status']}',
        orElse: () => ParticipantStatus.invited,
      ),
    );
  }
}

/// Represents a signature in a collaborative session
@freezed
class Signature with _$Signature {
  const factory Signature({
    required String signatureId,
    required String participantId,
    required String participantName,
    required DateTime signedAt,
    required int page,
    required double x,
    required double y,
    String? certificateThumbprint,
    String? signatureImagePath,
  }) = _Signature;

  factory Signature.fromMap(Map<String, dynamic> map) {
    return Signature(
      signatureId: map['signatureId'] as String,
      participantId: map['participantId'] as String,
      participantName: map['participantName'] as String,
      signedAt: DateTime.parse(map['signedAt'] as String),
      page: map['page'] as int,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      certificateThumbprint: map['certificateThumbprint'] as String?,
      signatureImagePath: map['signatureImagePath'] as String?,
    );
  }
}

/// Session status
enum SessionStatus {
  pending,
  active,
  completed,
  cancelled,
  expired,
}

/// Participant role
enum ParticipantRole {
  owner,
  signer,
  viewer,
}

/// Participant status
enum ParticipantStatus {
  invited,
  joined,
  signed,
  declined,
}

