import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firmador/src/data/services/collaborative_signing_service.dart';
import 'package:firmador/src/domain/entities/collaborative_session.dart';
import 'package:firmador/src/presentation/providers/user_provider.dart';

final collaborativeSigningServiceProvider =
    Provider<CollaborativeSigningService>((ref) {
  return CollaborativeSigningService();
});

final collaborativeSessionsProvider =
    StateNotifierProvider<CollaborativeSessionsNotifier, AsyncValue<List<CollaborativeSession>>>(
  (ref) {
    final service = ref.watch(collaborativeSigningServiceProvider);
    final notifier = CollaborativeSessionsNotifier(service);
    
    // Set user ID when available
    ref.watch(userIdProvider).whenData((userId) {
      notifier.setUserId(userId);
    });
    
    return notifier;
  },
);

class CollaborativeSessionsNotifier
    extends StateNotifier<AsyncValue<List<CollaborativeSession>>> {
  final CollaborativeSigningService _service;
  String? _currentUserId;

  CollaborativeSessionsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadSessions();
  }

  void setUserId(String userId) {
    _currentUserId = userId;
    loadSessions();
  }

  Future<void> loadSessions() async {
    if (_currentUserId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final sessions = await _service.getUserSessions(_currentUserId!);
      state = AsyncValue.data(sessions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<CollaborativeSession> createSession({
    required String documentPath,
    required String documentName,
    required String ownerName,
    String? description,
    Duration? expirationDuration,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }

    final session = await _service.createSession(
      documentPath: documentPath,
      documentName: documentName,
      ownerId: _currentUserId!,
      ownerName: ownerName,
      description: description,
      expirationDuration: expirationDuration,
    );

    await loadSessions();
    return session;
  }

  Future<void> refresh() async {
    await loadSessions();
  }
}

final currentSessionProvider =
    StateNotifierProvider.family<CurrentSessionNotifier, AsyncValue<CollaborativeSession?>, String>(
  (ref, sessionId) {
    final service = ref.watch(collaborativeSigningServiceProvider);
    return CurrentSessionNotifier(service, sessionId);
  },
);

class CurrentSessionNotifier
    extends StateNotifier<AsyncValue<CollaborativeSession?>> {
  final CollaborativeSigningService _service;
  final String _sessionId;

  CurrentSessionNotifier(this._service, this._sessionId)
      : super(const AsyncValue.loading()) {
    loadSession();
  }

  Future<void> loadSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _service.getSession(_sessionId);
      state = AsyncValue.data(session);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addParticipant({
    required String userId,
    required String userName,
    required String email,
    ParticipantRole role = ParticipantRole.signer,
  }) async {
    try {
      await _service.addParticipant(
        sessionId: _sessionId,
        userId: userId,
        userName: userName,
        email: email,
        role: role,
      );
      await loadSession();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> joinSession(String userId) async {
    try {
      await _service.joinSession(
        sessionId: _sessionId,
        userId: userId,
      );
      await loadSession();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addSignature({
    required String participantId,
    required String participantName,
    required int page,
    required double x,
    required double y,
    String? certificateThumbprint,
    String? signatureImagePath,
  }) async {
    try {
      await _service.addSignature(
        sessionId: _sessionId,
        participantId: participantId,
        participantName: participantName,
        page: page,
        x: x,
        y: y,
        certificateThumbprint: certificateThumbprint,
        signatureImagePath: signatureImagePath,
      );
      await loadSession();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await loadSession();
  }
}
