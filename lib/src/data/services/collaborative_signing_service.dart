import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firmador/src/domain/entities/collaborative_session.dart';
import 'package:uuid/uuid.dart';

/// Service for managing collaborative signing sessions
/// Uses local storage for session management (can be extended with backend)
class CollaborativeSigningService {
  static const _storage = FlutterSecureStorage();
  static const String _sessionsListKey = 'collaborative_sessions_list';
  static const String _sessionPrefix = 'session_';
  static const _uuid = Uuid();

  /// Create a new collaborative signing session
  Future<CollaborativeSession> createSession({
    required String documentPath,
    required String documentName,
    required String ownerId,
    required String ownerName,
    String? description,
    Duration? expirationDuration,
  }) async {
    try {
      final sessionId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(expirationDuration ?? const Duration(days: 7));

      final session = CollaborativeSession(
        sessionId: sessionId,
        documentName: documentName,
        documentPath: documentPath,
        ownerId: ownerId,
        ownerName: ownerName,
        createdAt: now,
        expiresAt: expiresAt,
        description: description,
        status: SessionStatus.pending,
        participants: [
          Participant(
            userId: ownerId,
            userName: ownerName,
            email: '', // Owner email can be added later
            role: ParticipantRole.owner,
            invitedAt: now,
            joinedAt: now,
            status: ParticipantStatus.joined,
          ),
        ],
      );

      await _saveSession(session);
      await _addToSessionsList(sessionId);

      return session;
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }

  /// Get a session by ID
  Future<CollaborativeSession?> getSession(String sessionId) async {
    try {
      final sessionJson = await _storage.read(
        key: '$_sessionPrefix$sessionId',
      );

      if (sessionJson == null) {
        return null;
      }

      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      return CollaborativeSession.fromMap(sessionMap);
    } catch (e) {
      throw Exception('Error retrieving session: $e');
    }
  }

  /// Get all sessions for a user
  Future<List<CollaborativeSession>> getUserSessions(String userId) async {
    try {
      final sessionsList = await _getSessionsList();
      final List<CollaborativeSession> userSessions = [];

      for (final sessionId in sessionsList) {
        final session = await getSession(sessionId);
        if (session != null) {
          // Include if user is owner or participant
          final isOwner = session.ownerId == userId;
          final isParticipant = session.participants
              .any((p) => p.userId == userId);

          if (isOwner || isParticipant) {
            userSessions.add(session);
          }
        }
      }

      // Sort by creation date (newest first)
      userSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return userSessions;
    } catch (e) {
      throw Exception('Error retrieving user sessions: $e');
    }
  }

  /// Add a participant to a session
  Future<CollaborativeSession> addParticipant({
    required String sessionId,
    required String userId,
    required String userName,
    required String email,
    ParticipantRole role = ParticipantRole.signer,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Check if participant already exists
      if (session.participants.any((p) => p.userId == userId)) {
        throw Exception('Participant already exists in session');
      }

      final newParticipant = Participant(
        userId: userId,
        userName: userName,
        email: email,
        role: role,
        invitedAt: DateTime.now(),
        status: ParticipantStatus.invited,
      );

      final updatedParticipants = [
        ...session.participants,
        newParticipant,
      ];

      final updatedSession = session.copyWith(
        participants: updatedParticipants,
        status: SessionStatus.active,
      );

      await _saveSession(updatedSession);

      return updatedSession;
    } catch (e) {
      throw Exception('Error adding participant: $e');
    }
  }

  /// Remove a participant from a session
  Future<CollaborativeSession> removeParticipant({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Cannot remove owner
      if (session.ownerId == userId) {
        throw Exception('Cannot remove session owner');
      }

      final updatedParticipants = session.participants
          .where((p) => p.userId != userId)
          .toList();

      final updatedSession = session.copyWith(
        participants: updatedParticipants,
      );

      await _saveSession(updatedSession);

      return updatedSession;
    } catch (e) {
      throw Exception('Error removing participant: $e');
    }
  }

  /// Join a session as a participant
  Future<CollaborativeSession> joinSession({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Check if session is expired
      if (session.expiresAt.isBefore(DateTime.now())) {
        throw Exception('Session has expired');
      }

      // Find participant
      final participantIndex = session.participants
          .indexWhere((p) => p.userId == userId);

      if (participantIndex == -1) {
        throw Exception('User is not a participant in this session');
      }

      final participant = session.participants[participantIndex];
      final updatedParticipant = participant.copyWith(
        joinedAt: DateTime.now(),
        status: ParticipantStatus.joined,
      );

      final updatedParticipants = List<Participant>.from(session.participants);
      updatedParticipants[participantIndex] = updatedParticipant;

      final updatedSession = session.copyWith(
        participants: updatedParticipants,
        status: SessionStatus.active,
      );

      await _saveSession(updatedSession);

      return updatedSession;
    } catch (e) {
      throw Exception('Error joining session: $e');
    }
  }

  /// Add a signature to a session
  Future<CollaborativeSession> addSignature({
    required String sessionId,
    required String participantId,
    required String participantName,
    required int page,
    required double x,
    required double y,
    String? certificateThumbprint,
    String? signatureImagePath,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      // Verify participant exists and has joined
      final participant = session.participants
          .firstWhere(
            (p) => p.userId == participantId,
            orElse: () => throw Exception('Participant not found'),
          );

      if (participant.status != ParticipantStatus.joined &&
          participant.status != ParticipantStatus.signed) {
        throw Exception('Participant must join session before signing');
      }

      // Create signature
      final signature = Signature(
        signatureId: _uuid.v4(),
        participantId: participantId,
        participantName: participantName,
        signedAt: DateTime.now(),
        page: page,
        x: x,
        y: y,
        certificateThumbprint: certificateThumbprint,
        signatureImagePath: signatureImagePath,
      );

      // Update participant status
      final participantIndex = session.participants
          .indexWhere((p) => p.userId == participantId);
      final updatedParticipant = participant.copyWith(
        signedAt: DateTime.now(),
        status: ParticipantStatus.signed,
      );

      final updatedParticipants = List<Participant>.from(session.participants);
      updatedParticipants[participantIndex] = updatedParticipant;

      // Add signature
      final updatedSignatures = [...session.signatures, signature];

      // Check if all signers have signed
      final allSignersSigned = session.participants
          .where((p) => p.role == ParticipantRole.signer)
          .every((p) => p.status == ParticipantStatus.signed);

      final updatedSession = session.copyWith(
        participants: updatedParticipants,
        signatures: updatedSignatures,
        status: allSignersSigned
            ? SessionStatus.completed
            : SessionStatus.active,
      );

      await _saveSession(updatedSession);

      return updatedSession;
    } catch (e) {
      throw Exception('Error adding signature: $e');
    }
  }

  /// Cancel a session
  Future<CollaborativeSession> cancelSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found');
      }

      final updatedSession = session.copyWith(
        status: SessionStatus.cancelled,
      );

      await _saveSession(updatedSession);

      return updatedSession;
    } catch (e) {
      throw Exception('Error cancelling session: $e');
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _storage.delete(key: '$_sessionPrefix$sessionId');
      await _removeFromSessionsList(sessionId);
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }

  /// Save session to storage
  Future<void> _saveSession(CollaborativeSession session) async {
    final sessionMap = {
      'sessionId': session.sessionId,
      'documentName': session.documentName,
      'documentPath': session.documentPath,
      'ownerId': session.ownerId,
      'ownerName': session.ownerName,
      'createdAt': session.createdAt.toIso8601String(),
      'expiresAt': session.expiresAt.toIso8601String(),
      'participants': session.participants.map((p) => {
            'userId': p.userId,
            'userName': p.userName,
            'email': p.email,
            'role': p.role.toString().split('.').last,
            'invitedAt': p.invitedAt.toIso8601String(),
            'joinedAt': p.joinedAt?.toIso8601String(),
            'signedAt': p.signedAt?.toIso8601String(),
            'status': p.status.toString().split('.').last,
          }).toList(),
      'signatures': session.signatures.map((s) => {
            'signatureId': s.signatureId,
            'participantId': s.participantId,
            'participantName': s.participantName,
            'signedAt': s.signedAt.toIso8601String(),
            'page': s.page,
            'x': s.x,
            'y': s.y,
            'certificateThumbprint': s.certificateThumbprint,
            'signatureImagePath': s.signatureImagePath,
          }).toList(),
      'status': session.status.toString().split('.').last,
      'description': session.description,
    };

    await _storage.write(
      key: '$_sessionPrefix${session.sessionId}',
      value: jsonEncode(sessionMap),
    );
  }

  /// Get sessions list
  Future<List<String>> _getSessionsList() async {
    final listJson = await _storage.read(key: _sessionsListKey);
    if (listJson == null) {
      return [];
    }
    return List<String>.from(jsonDecode(listJson));
  }

  /// Add to sessions list
  Future<void> _addToSessionsList(String sessionId) async {
    final currentList = await _getSessionsList();
    if (!currentList.contains(sessionId)) {
      currentList.add(sessionId);
      await _storage.write(
        key: _sessionsListKey,
        value: jsonEncode(currentList),
      );
    }
  }

  /// Remove from sessions list
  Future<void> _removeFromSessionsList(String sessionId) async {
    final currentList = await _getSessionsList();
    currentList.remove(sessionId);
    await _storage.write(
      key: _sessionsListKey,
      value: jsonEncode(currentList),
    );
  }
}

