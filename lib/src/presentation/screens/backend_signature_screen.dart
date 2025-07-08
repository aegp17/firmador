import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firmador/src/presentation/providers/backend_signature_provider.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:firmador/src/data/services/backend_signature_service.dart';
import 'package:firmador/src/data/services/user_preferences_service.dart';
import 'package:firmador/src/presentation/screens/pdf_preview_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

class BackendSignatureScreen extends ConsumerStatefulWidget {
  const BackendSignatureScreen({super.key});

  @override
  ConsumerState<BackendSignatureScreen> createState() => _BackendSignatureScreenState();
}

class _BackendSignatureScreenState extends ConsumerState<BackendSignatureScreen> {
  File? _selectedDocument;
  File? _selectedCertificate;
  SignaturePosition? _signaturePosition;
  
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _signerNameController = TextEditingController();
  final _signerIdController = TextEditingController();
  final _locationController = TextEditingController(text: 'Ecuador');
  final _reasonController = TextEditingController(text: 'Firma digital');
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberData = false;
  Timer? _healthCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _startHealthCheckTimer();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _signerNameController.dispose();
    _signerIdController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    _healthCheckTimer?.cancel();
    super.dispose();
  }

  void _startHealthCheckTimer() {
    // Update server status every 2 minutes
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      ref.invalidate(backendHealthProvider);
    });
  }

  Future<void> _loadUserPreferences() async {
    final remember = await UserPreferencesService.getRememberData();
    if (remember) {
      final userData = await UserPreferencesService.getUserData();
      setState(() {
        _rememberData = remember;
        _signerNameController.text = userData['signerName'] ?? '';
        _signerIdController.text = userData['signerId'] ?? '';
        _locationController.text = userData['location'] ?? 'Ecuador';
        _reasonController.text = userData['reason'] ?? 'Firma digital';
      });
    }
  }

  Future<void> _saveUserPreferences() async {
    await UserPreferencesService.setRememberData(_rememberData);
    if (_rememberData) {
      await UserPreferencesService.saveUserData(
        signerName: _signerNameController.text,
        signerId: _signerIdController.text,
        location: _locationController.text,
        reason: _reasonController.text,
      );
    } else {
      await UserPreferencesService.clearUserData();
    }
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
                          const SizedBox(height: 20),
                          _buildRememberDataCard(),
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
                      loading: () => 'Verificando estado...',
                      error: (_, __) => 'Error al verificar servidor',
                    ),
                    style: TextStyle(
                      color: backendHealthAsync.when(
                        data: (isHealthy) => isHealthy 
                            ? AppTheme.success 
                            : AppTheme.error,
                        loading: () => AppTheme.textSecondary,
                        error: (_, __) => AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ref.invalidate(backendHealthProvider);
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar estado',
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documento a Firmar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedDocument != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDocument!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDocument = null;
                          _signaturePosition = null;
                        });
                      },
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _previewDocument(),
                      icon: const Icon(Icons.preview),
                      label: const Text('Previsualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectSignaturePosition(),
                      icon: const Icon(Icons.touch_app),
                      label: Text(_signaturePosition != null 
                          ? 'Posición OK' 
                          : 'Seleccionar Posición'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _signaturePosition != null 
                            ? AppTheme.success 
                            : AppTheme.primaryNavy,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _selectDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar Documento PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateSelectionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificado Digital',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedCertificate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCertificate!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedCertificate = null;
                          _passwordController.clear();
                        });
                      },
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _selectCertificate,
                icon: const Icon(Icons.security),
                label: const Text('Seleccionar Certificado (.p12)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatePasswordCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contraseña del Certificado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la contraseña del certificado';
                }
                return null;
              },
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Firmante',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signerNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre del firmante';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signerIdController,
              decoration: const InputDecoration(
                labelText: 'Cédula/RUC',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la cédula o RUC';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la ubicación';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Razón de la Firma',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la razón de la firma';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberDataCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Checkbox(
              value: _rememberData,
              onChanged: (bool? value) {
                setState(() {
                  _rememberData = value ?? false;
                });
              },
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Recordar mis datos para próximas firmas',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignButton() {
    final backendHealthAsync = ref.watch(backendHealthProvider);
    final isBackendHealthy = backendHealthAsync.maybeWhen(
      data: (isHealthy) => isHealthy,
      orElse: () => false,
    );

    return ElevatedButton(
      onPressed: (!_isLoading && 
                  _selectedDocument != null && 
                  _selectedCertificate != null && 
                  _signaturePosition != null &&
                  isBackendHealthy) ? _signDocument : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Firmando documento...'),
              ],
            )
          : const Text(
              'Firmar Documento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _selectDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedDocument = File(result.files.single.path!);
        _signaturePosition = null; // Reset signature position
      });
    }
  }

  Future<void> _selectCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12', 'pfx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedCertificate = File(result.files.single.path!);
        _passwordController.clear();
      });
    }
  }

  Future<void> _previewDocument() async {
    if (_selectedDocument == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfFile: _selectedDocument!,
          onPositionSelected: (position) {
            // This is just for preview, don't set position
          },
        ),
      ),
    );
  }

  Future<void> _selectSignaturePosition() async {
    if (_selectedDocument == null) return;

    final position = await Navigator.push<SignaturePosition>(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfFile: _selectedDocument!,
          onPositionSelected: (position) => position,
        ),
      ),
    );

    if (position != null) {
      setState(() {
        _signaturePosition = position;
      });
    }
  }

  Future<void> _signDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDocument == null || _selectedCertificate == null) return;
    if (_signaturePosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione la posición de la firma'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _saveUserPreferences();

      final backendService = BackendSignatureService();
      final result = await backendService.signDocument(
        documentFile: _selectedDocument!,
        certificateFile: _selectedCertificate!,
        signerName: _signerNameController.text,
        signerId: _signerIdController.text,
        location: _locationController.text,
        reason: _reasonController.text,
        certificatePassword: _passwordController.text,
        signatureX: _signaturePosition!.x.toInt(),
        signatureY: _signaturePosition!.y.toInt(),
        signatureWidth: 200,
        signatureHeight: 80,
        signaturePage: _signaturePosition!.pageNumber,
      );

      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(SignatureResult result) {
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El documento ha sido firmado exitosamente.'),
            const SizedBox(height: 8),
            Text('Archivo: ${result.filename}'),
            Text('Tamaño: ${(result.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
            Text('Firmado: ${result.signedAt.toString().split('.')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (result.downloadUrl != null)
            ElevatedButton(
              onPressed: () => _downloadDocument(result.downloadUrl!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Descargar PDF'),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDocument(String downloadUrl) async {
    try {
      final fullUrl = 'http://localhost:8080$downloadUrl';
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('No se pudo abrir el enlace de descarga');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
} 