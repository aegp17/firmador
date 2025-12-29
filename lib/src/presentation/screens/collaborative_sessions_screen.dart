import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firmador/src/presentation/providers/collaborative_signing_provider.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:firmador/src/presentation/screens/collaborative_session_detail_screen.dart';
import 'package:firmador/src/domain/entities/collaborative_session.dart';

/// Screen to display and manage collaborative signing sessions
class CollaborativeSessionsScreen extends ConsumerWidget {
  const CollaborativeSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(collaborativeSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Colaborativa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(collaborativeSessionsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay sesiones de firma colaborativa',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una nueva sesión para comenzar',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(collaborativeSessionsProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionCard(session: session);
              },
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
                'Error al cargar sesiones',
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
                  ref.read(collaborativeSessionsProvider.notifier).refresh();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create session screen
          // TODO: Implement create session screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad de crear sesión próximamente'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Sesión'),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CollaborativeSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isExpired = session.expiresAt.isBefore(DateTime.now());
    final isCompleted = session.status == SessionStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CollaborativeSessionDetailScreen(
                sessionId: session.sessionId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.documentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusChip(
                    status: session.status,
                    isExpired: isExpired,
                    isCompleted: isCompleted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (session.description != null && session.description!.isNotEmpty)
                Text(
                  session.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
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
                    Icons.people,
                    size: 16,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.participants.length} participante(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.mediumGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.signatures.length} firma(s)',
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
                    'Creada: ${dateFormat.format(session.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
              if (isExpired)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Expira: ${dateFormat.format(session.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SessionStatus status;
  final bool isExpired;
  final bool isCompleted;

  const _StatusChip({
    required this.status,
    required this.isExpired,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (isExpired) {
      color = AppTheme.error;
      text = 'Expirada';
    } else if (isCompleted) {
      color = AppTheme.success;
      text = 'Completada';
    } else if (status == SessionStatus.active) {
      color = AppTheme.primaryCyan;
      text = 'Activa';
    } else if (status == SessionStatus.cancelled) {
      color = AppTheme.warning;
      text = 'Cancelada';
    } else {
      color = AppTheme.mediumGrey;
      text = 'Pendiente';
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

