import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firmador/src/presentation/providers/backend_signature_provider.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:firmador/src/data/services/backend_signature_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class BackendSignatureScreen extends ConsumerStatefulWidget {
  const BackendSignatureScreen({super.key});

  @override
  ConsumerState<BackendSignatureScreen> createState() => _BackendSignatureScreenState();
}

class _BackendSignatureScreenState extends ConsumerState<BackendSignatureScreen> {
  File? _selectedDocument;
  File? _selectedCertificate;
  
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _signerNameController = TextEditingController();
  final _signerEmailController = TextEditingController();
  final _signerIdController = TextEditingController();
  final _locationController = TextEditingController(text: 'Ecuador');
  final _reasonController = TextEditingController(text: 'Firma digital');
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _signerNameController.dispose();
    _signerEmailController.dispose();
    _signerIdController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch backend health
    final backendHealthAsync = ref.watch(backendHealthProvider);
    
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
              _buildHeader(context, backendHealthAsync),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBackendStatusCard(backendHealthAsync),
                        const SizedBox(height: 20),
                        _buildDocumentSelectionCard(),
                        const SizedBox(height: 20),
                        _buildCertificateSelectionCard(),
                        const SizedBox(height: 20),
                        if (_selectedCertificate != null) ...[
                          _buildCertificatePasswordCard(),
                          const SizedBox(height: 20),
                          _buildSignerInfoCard(),
                          const SizedBox(height: 32),
                          _buildSignButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<bool> backendHealthAsync) {
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
                  'Firma Digital',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Backend status indicator
              backendHealthAsync.when(
                data: (isHealthy) => Icon(
                  isHealthy ? Icons.cloud_done : Icons.cloud_off,
                  color: isHealthy ? AppTheme.success : AppTheme.error,
                  size: 28,
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  ),
                ),
                error: (_, __) => const Icon(
                  Icons.error,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Firma documentos usando nuestro backend seguro',
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

  Widget _buildBackendStatusCard(AsyncValue<bool> backendHealthAsync) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            backendHealthAsync.when(
              data: (isHealthy) => Icon(
                isHealthy ? Icons.verified : Icons.error,
                color: isHealthy ? AppTheme.success : AppTheme.error,
                size: 24,
              ),
              loading: () => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Icon(
                Icons.error,
                color: AppTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado del Servidor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    backendHealthAsync.when(
                      data: (isHealthy) => isHealthy 
                          ? 'Servidor en línea y funcionando' 
                          : 'Servidor no disponible',
                      loading: () => 'Verificando servidor...',
                      error: (_, __) => 'Error al conectar con el servidor',
                    ),
                    style: TextStyle(
                      color: AppTheme.mediumGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref.refresh(backendHealthProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSelectionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Documento PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedDocument != null ? AppTheme.success : AppTheme.mediumGrey,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedDocument != null ? Icons.check_circle : Icons.description,
                    size: 40,
                    color: _selectedDocument != null ? AppTheme.success : AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedDocument?.path.split('/').last ?? 'Ningún documento seleccionado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: _selectedDocument != null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedDocument != null ? AppTheme.success : AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _selectDocument,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_selectedDocument != null ? 'Cambiar documento' : 'Seleccionar PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateSelectionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Certificado Digital',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedCertificate != null ? AppTheme.success : AppTheme.mediumGrey,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedCertificate != null ? Icons.verified : Icons.security,
                    size: 40,
                    color: _selectedCertificate != null ? AppTheme.success : AppTheme.mediumGrey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCertificate?.path.split('/').last ?? 'Ningún certificado seleccionado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: _selectedCertificate != null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedCertificate != null ? AppTheme.success : AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _selectCertificate,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_selectedCertificate != null ? 'Cambiar certificado' : 'Seleccionar .p12'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatePasswordCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Contraseña del Certificado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Ingresa la contraseña del certificado',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _validateCertificate,
              icon: const Icon(Icons.verified_user),
              label: const Text('Validar Certificado'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignerInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Información del Firmante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signerNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signerEmailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El correo es requerido';
                }
                if (!value.contains('@')) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signerIdController,
              decoration: const InputDecoration(
                labelText: 'Cédula/ID',
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La cédula/ID es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Razón de la firma',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _canSign() ? _signDocument : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryCyan,
          foregroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                ),
              )
            : const Icon(Icons.edit_document),
        label: Text(
          _isLoading ? 'Firmando documento...' : 'Firmar Documento',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _canSign() {
    return _selectedDocument != null &&
           _selectedCertificate != null &&
           _passwordController.text.isNotEmpty &&
           _signerNameController.text.isNotEmpty &&
           _signerEmailController.text.isNotEmpty &&
           _signerIdController.text.isNotEmpty &&
           !_isLoading;
  }

  Future<void> _selectDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedDocument = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12', 'pfx'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedCertificate = File(result.files.single.path!);
      });
    }
  }

  Future<void> _validateCertificate() async {
    if (_selectedCertificate == null || _passwordController.text.isEmpty) {
      _showSnackBar('Selecciona un certificado e ingresa la contraseña', AppTheme.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(backendSignatureServiceProvider);
      final result = await service.validateCertificate(
        certificateFile: _selectedCertificate!,
        password: _passwordController.text,
      );

      ref.read(lastCertificateValidationProvider.notifier).state = result;

      if (result.valid) {
        _showSnackBar('Certificado válido', AppTheme.success);
        
        // Also get certificate info
        final infoResult = await service.getCertificateInfo(
          certificateFile: _selectedCertificate!,
          password: _passwordController.text,
        );
        
        ref.read(lastCertificateInfoProvider.notifier).state = infoResult;
        
        if (infoResult.success && infoResult.certificateInfo != null) {
          _showCertificateInfoDialog(infoResult.certificateInfo!);
        }
      } else {
        _showSnackBar(result.message, AppTheme.error);
      }
    } catch (e) {
      _showSnackBar('Error al validar certificado: $e', AppTheme.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    ref.read(signingStatusProvider.notifier).state = 'Preparando firma...';

    try {
      final service = ref.read(backendSignatureServiceProvider);
      
      ref.read(signingStatusProvider.notifier).state = 'Enviando al servidor...';
      
      final result = await service.signDocument(
        documentFile: _selectedDocument!,
        certificateFile: _selectedCertificate!,
        signerName: _signerNameController.text,
        signerEmail: _signerEmailController.text,
        signerId: _signerIdController.text,
        location: _locationController.text,
        reason: _reasonController.text,
        certificatePassword: _passwordController.text,
      );

      ref.read(lastSignatureResultProvider.notifier).state = result;
      ref.read(signingStatusProvider.notifier).state = null;

      if (result.success) {
        _showSnackBar('Documento firmado exitosamente', AppTheme.success);
        _showSignatureResultDialog(result);
      } else {
        _showSnackBar(result.message, AppTheme.error);
      }
    } catch (e) {
      _showSnackBar('Error al firmar documento: $e', AppTheme.error);
      ref.read(signingStatusProvider.notifier).state = null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCertificateInfoDialog(dynamic certificateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Certificado'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Emisor', certificateInfo.issuer),
              _buildInfoRow('Titular', certificateInfo.subject),
              _buildInfoRow('Número de Serie', certificateInfo.serialNumber),
              _buildInfoRow('Válido desde', '${certificateInfo.validFrom}'),
              _buildInfoRow('Válido hasta', '${certificateInfo.validTo}'),
              _buildInfoRow('Confiable', certificateInfo.isTrusted ? 'Sí' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSignatureResultDialog(SignatureResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Firma Exitosa'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El documento ha sido firmado exitosamente.'),
            const SizedBox(height: 16),
            if (result.filename != null)
              _buildInfoRow('Archivo', result.filename!),
            if (result.fileSize != null)
              _buildInfoRow('Tamaño', '${(result.fileSize! / 1024).toStringAsFixed(1)} KB'),
            if (result.signedAt != null)
              _buildInfoRow('Firmado el', '${result.signedAt}'),
          ],
        ),
        actions: [
          if (result.downloadUrl != null)
            ElevatedButton.icon(
              onPressed: () => _downloadDocument(result.downloadUrl!),
              icon: const Icon(Icons.download),
              label: const Text('Descargar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: AppTheme.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDocument(String downloadUrl) async {
    try {
      // Create the full URL
      final fullUrl = 'http://localhost:8080$downloadUrl';
      final uri = Uri.parse(fullUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar('Descarga iniciada', AppTheme.success);
      } else {
        _showSnackBar('No se pudo abrir el enlace de descarga', AppTheme.error);
      }
    } catch (e) {
      _showSnackBar('Error al descargar: $e', AppTheme.error);
    }
  }
} 