import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firmador/src/presentation/providers/collaborative_signing_provider.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:firmador/src/domain/entities/collaborative_session.dart';

/// Screen to view and manage a specific collaborative session
class CollaborativeSessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const CollaborativeSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(currentSessionProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Sesión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(currentSessionProvider(sessionId).notifier).refresh();
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(
              child: Text('Sesión no encontrada'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.documentName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (session.description != null &&
                            session.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            session.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: AppTheme.mediumGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Propietario: ${session.ownerName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.mediumGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Creada: ${DateFormat('dd/MM/yyyy HH:mm').format(session.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.mediumGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expira: ${DateFormat('dd/MM/yyyy HH:mm').format(session.expiresAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: session.expiresAt.isBefore(DateTime.now())
                                    ? AppTheme.error
                                    : AppTheme.mediumGrey,
                                fontWeight: session.expiresAt.isBefore(DateTime.now())
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Participants Section
                Text(
                  'Participantes',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.participants.length,
                    itemBuilder: (context, index) {
                      final participant = session.participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryCyan,
                          child: Text(
                            participant.userName[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.white),
                          ),
                        ),
                        title: Text(participant.userName),
                        subtitle: Text(participant.email),
                        trailing: _ParticipantStatusChip(
                          status: participant.status,
                          role: participant.role,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Signatures Section
                Text(
                  'Firmas',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (session.signatures.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No hay firmas aún',
                          style: TextStyle(
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: session.signatures.length,
                      itemBuilder: (context, index) {
                        final signature = session.signatures[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.verified,
                            color: AppTheme.success,
                          ),
                          title: Text(signature.participantName),
                          subtitle: Text(
                            'Página ${signature.page} - ${DateFormat('dd/MM/yyyy HH:mm').format(signature.signedAt)}',
                          ),
                          trailing: Text(
                            '(${signature.x.toStringAsFixed(0)}, ${signature.y.toStringAsFixed(0)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar sesión',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(currentSessionProvider(sessionId).notifier).refresh();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantStatusChip extends StatelessWidget {
  final ParticipantStatus status;
  final ParticipantRole role;

  const _ParticipantStatusChip({
    required this.status,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (status == ParticipantStatus.signed) {
      color = AppTheme.success;
      text = 'Firmado';
    } else if (status == ParticipantStatus.joined) {
      color = AppTheme.primaryCyan;
      text = 'Unido';
    } else if (status == ParticipantStatus.declined) {
      color = AppTheme.error;
      text = 'Rechazado';
    } else {
      color = AppTheme.mediumGrey;
      text = 'Invitado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

