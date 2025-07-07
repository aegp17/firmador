import 'package:firmador/src/presentation/providers/certificate_provider.dart';
import 'package:firmador/src/presentation/screens/pdf_selection_screen.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CertificateUploadScreen extends ConsumerWidget {
  const CertificateUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(certificateUploadProvider);
    final notifier = ref.read(certificateUploadProvider.notifier);

    // Listen for errors and show a snackbar
    ref.listen<CertificateUploadState>(certificateUploadProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryNavy,
              AppTheme.lightGrey,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // File Selection Card
                      _buildFileSelectionCard(state, notifier),
                      const SizedBox(height: 24),

                      // Certificate Info Card
                      if (state.certificateInfo != null)
                        _buildCertificateInfoCard(state.certificateInfo!),
                      
                      // Password Input Card
                      if (state.certificateInfo == null && state.file != null)
                        _buildPasswordCard(state, notifier),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      _buildActionButtons(context, state, notifier),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.white,
                ),
              ),
              const Expanded(
                child: Text(
                  'Cargar Certificado',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sube tu certificado digital (.p12) para comenzar',
            style: TextStyle(
              color: AppTheme.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionCard(CertificateUploadState state, CertificateUploadNotifier notifier) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Seleccionar Certificado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.file != null ? AppTheme.primaryCyan : AppTheme.mediumGrey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    state.file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                    size: 48,
                    color: state.file != null ? AppTheme.success : AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.file?.name ?? 'No se ha seleccionado ningún archivo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: state.file != null ? FontWeight.w600 : FontWeight.normal,
                      color: state.file != null ? AppTheme.success : AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isLoading ? null : notifier.pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: Text(state.file != null ? 'Cambiar archivo' : 'Seleccionar archivo .p12'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(CertificateUploadState state, CertificateUploadNotifier notifier) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Contraseña del Certificado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: notifier.updatePassword,
              obscureText: true,
              enabled: !state.isLoading,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Ingresa la contraseña de tu certificado',
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateInfoCard(dynamic certificateInfo) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Información del Certificado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
                if (certificateInfo.isTrusted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppTheme.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Validado',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            _CertificateInfoTile(
              icon: Icons.person,
              title: 'Nombre Común',
              value: certificateInfo.commonName.isNotEmpty 
                  ? certificateInfo.commonName 
                  : 'N/A',
            ),
            _CertificateInfoTile(
              icon: Icons.account_circle,
              title: 'Emitido para',
              value: certificateInfo.subject,
            ),
            _CertificateInfoTile(
              icon: Icons.business,
              title: 'Emitido por',
              value: certificateInfo.issuer,
            ),
            _CertificateInfoTile(
              icon: Icons.numbers,
              title: 'Número de Serie',
              value: certificateInfo.serialNumber.isNotEmpty 
                  ? certificateInfo.serialNumber 
                  : 'N/A',
            ),
            _CertificateInfoTile(
              icon: Icons.calendar_today,
              title: 'Válido desde',
              value: DateFormat('dd/MM/yyyy HH:mm').format(certificateInfo.validFrom),
            ),
            _CertificateInfoTile(
              icon: Icons.event,
              title: 'Válido hasta',
              value: DateFormat('dd/MM/yyyy HH:mm').format(certificateInfo.validTo),
            ),
            if (certificateInfo.keyUsages.isNotEmpty)
              _CertificateInfoTile(
                icon: Icons.key,
                title: 'Usos de Clave',
                value: certificateInfo.keyUsages.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CertificateUploadState state, CertificateUploadNotifier notifier) {
    if (state.certificateInfo != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PdfSelectionScreen(),
              ),
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Continuar'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isLoading || state.file == null
            ? null
            : () => notifier.loadCertificate(context),
        icon: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.white,
                ),
              )
            : const Icon(Icons.security),
        label: Text(state.isLoading ? 'Cargando...' : 'Cargar Certificado'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _CertificateInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CertificateInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryCyan.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryCyan,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 