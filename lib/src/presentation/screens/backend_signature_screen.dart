import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firmador/src/presentation/providers/backend_signature_provider.dart';
import 'package:firmador/src/presentation/theme/app_theme.dart';
import 'package:firmador/src/data/services/backend_signature_service.dart';
import 'package:firmador/src/data/services/user_preferences_service.dart';
import 'package:firmador/src/presentation/screens/pdf_preview_screen.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';
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
  CertificateInfo? _certificateInfo;
  
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _signerNameController = TextEditingController();
  final _signerIdController = TextEditingController();
  final _locationController = TextEditingController(text: 'Ecuador');
  final _reasonController = TextEditingController(text: 'Firma digital');
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberData = false;
  bool _isValidatingCertificate = false;
  bool _isCertificateValid = false;
  Timer? _healthCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _startHealthCheckTimer();
    _addFieldListeners();
  }

  void _addFieldListeners() {
    // Add listeners to required fields to update button state
    _locationController.addListener(_updateButtonState);
    _reasonController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild and update the button state
    });
  }

  bool _validateRequiredFields() {
    // Required fields validation (without form validation)
    return _locationController.text.trim().isNotEmpty &&
           _reasonController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _locationController.removeListener(_updateButtonState);
    _reasonController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    
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
                          if (_isCertificateValid && _certificateInfo != null) ...[
                            _buildCertificateInfoCard(),
                            const SizedBox(height: 20),
                          ],
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
                        loading: () => AppTheme.mediumGrey,
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
              ElevatedButton.icon(
                onPressed: () => _selectSignaturePosition(),
                icon: Icon(_signaturePosition != null ? Icons.check_circle : Icons.touch_app),
                label: Text(_signaturePosition != null 
                    ? 'Posición Seleccionada' 
                    : 'Seleccionar Posición de Firma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _signaturePosition != null 
                      ? AppTheme.success 
                      : AppTheme.primaryNavy,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _selectDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar Documento PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isValidatingCertificate)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_isCertificateValid)
                      const Icon(Icons.check_circle, color: AppTheme.success)
                    else if (_passwordController.text.isNotEmpty)
                      const Icon(Icons.error, color: AppTheme.error),
                    IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ],
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty && _selectedCertificate != null) {
                  // Validate certificate after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_passwordController.text == value) {
                      _validateCertificate();
                    }
                  });
                }
                // Update button state immediately when password changes
                _updateButtonState();
              },
              validator: (value) {
                // Solo validar campo vacío cuando se valide el formulario completo
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la contraseña del certificado';
                }
                // No mostrar mensaje de contraseña incorrecta aquí - solo usar indicador visual
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateInfoCard() {
    if (_certificateInfo == null) return Container();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: AppTheme.success),
                const SizedBox(width: 8),
                const Text(
                  'Información del Certificado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Titular', _certificateInfo!.commonName),
            _buildInfoRow('Emisor', _certificateInfo!.issuer),
            _buildInfoRow('Válido desde', _formatDate(_certificateInfo!.validFrom)),
            _buildInfoRow('Válido hasta', _formatDate(_certificateInfo!.validTo)),
            _buildInfoRow('Número de serie', _certificateInfo!.serialNumber),
            if (_certificateInfo!.keyUsages.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Usos del certificado:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _certificateInfo!.keyUsages.map((usage) => 
                  Chip(
                    label: Text(usage, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.primaryCyan.withValues(alpha: 0.1),
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
              'Información de la Firma',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signerIdController,
              decoration: const InputDecoration(
                labelText: 'Cédula/RUC (opcional)',
                border: OutlineInputBorder(),
              ),
              // Campo opcional - sin validator
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

    final canSign = !_isLoading && 
                    _selectedDocument != null && 
                    _selectedCertificate != null && 
                    _signaturePosition != null &&
                    _isCertificateValid &&
                    _passwordController.text.isNotEmpty &&
                    _validateRequiredFields() &&
                    isBackendHealthy;

    return ElevatedButton(
      onPressed: canSign ? _signDocument : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canSign ? AppTheme.primaryCyan : AppTheme.mediumGrey,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 0),
        elevation: canSign ? 2 : 0,
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
        _certificateInfo = null;
        _isCertificateValid = false;
      });
    }
  }

  Future<void> _validateCertificate() async {
    if (_selectedCertificate == null || _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isValidatingCertificate = true;
    });

    try {
      final backendService = BackendSignatureService();
      final result = await backendService.getCertificateInfo(
        certificateFile: _selectedCertificate!,
        password: _passwordController.text,
      );

      setState(() {
        _isValidatingCertificate = false;
        _isCertificateValid = result.success;
        _certificateInfo = result.certificateInfo;
        
        // Auto-fill signer name and ID if available
        if (result.success && result.certificateInfo != null) {
          _signerNameController.text = result.certificateInfo!.commonName;
          // Extract email from subject if available
          final subject = result.certificateInfo!.subject;
          final emailMatch = RegExp(r'emailAddress=([^,]+)').firstMatch(subject);
          if (emailMatch != null) {
            // Could be used for email field if needed
          }
        }
      });

      if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar certificado: ${result.message}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isValidatingCertificate = false;
        _isCertificateValid = false;
        _certificateInfo = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar certificado: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
    
    // Update button state after certificate validation
    _updateButtonState();
  }

  Future<void> _selectSignaturePosition() async {
    if (_selectedDocument == null) return;

    final position = await Navigator.push<SignaturePosition>(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfFile: _selectedDocument!,
        ),
      ),
    );

    if (position != null) {
      setState(() {
        _signaturePosition = position;
      });
      // Update button state after position selection
      _updateButtonState();
      
      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posición de firma seleccionada en página ${position.pageNumber}'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _signDocument() async {
    // Validate all conditions before signing
    if (!_validateRequiredFields()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor complete todos los campos obligatorios'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }
    
    if (_selectedDocument == null || _selectedCertificate == null) return;
    if (_signaturePosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione la posición de la firma'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    if (!_isCertificateValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El certificado no es válido o la contraseña es incorrecta'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
        signerName: _certificateInfo?.commonName ?? 'Firmante',
        signerId: _signerIdController.text,
        location: _locationController.text,
        reason: _reasonController.text,
        certificatePassword: _passwordController.text,
        signatureX: _signaturePosition!.x,
        signatureY: _signaturePosition!.y,
        signatureWidth: _signaturePosition!.signatureWidth,
        signatureHeight: _signaturePosition!.signatureHeight,
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
            Text('Tamaño: ${result.fileSize != null ? (result.fileSize! / 1024 / 1024).toStringAsFixed(2) : 'N/A'} MB'),
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
                backgroundColor: AppTheme.primaryCyan,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
} 