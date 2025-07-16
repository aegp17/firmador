import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firmador/src/data/services/hybrid_signature_service.dart';
import 'package:firmador/src/data/services/user_preferences_service.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';
import 'package:firmador/src/presentation/widgets/pdf_preview_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Android-specific signature screen with hybrid local/backend signing
class AndroidSignatureScreen extends StatefulWidget {
  const AndroidSignatureScreen({Key? key}) : super(key: key);

  @override
  State<AndroidSignatureScreen> createState() => _AndroidSignatureScreenState();
}

class _AndroidSignatureScreenState extends State<AndroidSignatureScreen> {
  final HybridSignatureService _hybridService = HybridSignatureService();
  
  // Form controllers
  final _signerNameController = TextEditingController();
  final _signerIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State variables
  File? _selectedDocument;
  File? _selectedCertificate;
  CertificateInfo? _certificateInfo;
  PdfPosition? _signaturePosition;
  bool _isLoading = false;
  bool _enableTimestamp = true;
  bool _rememberData = false;
  String _selectedTsaServer = 'https://freetsa.org/tsr';
  SigningMethod? _lastUsedMethod;
  HybridHealthResult? _healthStatus;
  
  // TSA server options
  final Map<String, String> _tsaServers = {
    'https://freetsa.org/tsr': 'FreeTSA (Gratis)',
    'http://timestamp.digicert.com': 'DigiCert',
    'http://timestamp.apple.com/ts01': 'Apple',
    'http://timestamp.sectigo.com': 'Sectigo',
    'http://timestamp.entrust.net/TSS/RFC3161sha2TS': 'Entrust',
  };

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _checkServiceHealth();
  }

  @override
  void dispose() {
    _signerNameController.dispose();
    _signerIdController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    _rememberData = await UserPreferencesService.getRememberData();
    
    if (_rememberData) {
      final userData = await UserPreferencesService.getUserData();
      setState(() {
        _signerNameController.text = userData['signerName'] ?? '';
        _signerIdController.text = userData['signerId'] ?? '';
        _locationController.text = userData['location'] ?? 'Ecuador';
        _reasonController.text = userData['reason'] ?? 'Firma digital';
        _enableTimestamp = (userData['enableTimestamp'] ?? 'true') == 'true';
        _selectedTsaServer = userData['tsaServer'] ?? 'https://freetsa.org/tsr';
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
        enableTimestamp: _enableTimestamp.toString(),
        tsaServer: _selectedTsaServer,
      );
    }
  }

  Future<void> _checkServiceHealth() async {
    try {
      final health = await _hybridService.checkHealth();
      setState(() {
        _healthStatus = health;
      });
    } catch (e) {
      debugPrint('Error checking service health: $e');
    }
  }

  Future<void> _selectDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedDocument = File(result.files.first.path!);
          _signaturePosition = null; // Reset signature position
        });
      }
    } catch (e) {
      _showErrorDialog('Error al seleccionar documento: $e');
    }
  }

  Future<void> _selectCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedCertificate = File(result.files.first.path!);
          _certificateInfo = null; // Reset certificate info
        });
      }
    } catch (e) {
      _showErrorDialog('Error al seleccionar certificado: $e');
    }
  }

  Future<void> _loadCertificateInfo() async {
    if (_selectedCertificate == null || _passwordController.text.isEmpty) {
      _showErrorDialog('Selecciona un certificado e ingresa la contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _hybridService.getCertificateInfo(
        certificateFile: _selectedCertificate!,
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result.success && result.certificateInfo != null) {
        setState(() {
          _certificateInfo = result.certificateInfo;
          _signerNameController.text = result.certificateInfo!.commonName;
        });

        _showCertificateDialog(result.certificateInfo!, result.extractionMethod);
      } else {
        _showErrorDialog(result.message ?? 'Error al cargar el certificado');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error inesperado: $e');
    }
  }

  void _showCertificateDialog(CertificateInfo info, ExtractionMethod method) {
    final methodText = method == ExtractionMethod.local 
        ? 'Procesado localmente en Android' 
        : 'Procesado mediante backend';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              method == ExtractionMethod.local ? Icons.phone_android : Icons.cloud,
              color: method == ExtractionMethod.local ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text('Certificado Válido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método: $methodText', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Titular: ${info.commonName}'),
            Text('Emisor: ${info.issuer}'),
            Text('Válido desde: ${_formatDate(info.validFrom)}'),
            Text('Válido hasta: ${_formatDate(info.validTo)}'),
            Text('Usos: ${info.keyUsages.join(', ')}'),
          ],
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

  void _onSignaturePositionSelected(PdfPosition position) {
    setState(() {
      _signaturePosition = position;
    });
  }

  Future<void> _signDocument() async {
    if (_selectedDocument == null ||
        _selectedCertificate == null ||
        _certificateInfo == null ||
        _signaturePosition == null ||
        _passwordController.text.isEmpty) {
      _showErrorDialog('Completa todos los campos requeridos.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _saveUserPreferences();

      final pdfPosition = _signaturePosition!.toPdfCoordinates();
      
      debugPrint('Signing with position: ${_signaturePosition.toString()}');
      debugPrint('PDF coordinates: ${pdfPosition.toString()}');

      final result = await _hybridService.signDocument(
        documentFile: _selectedDocument!,
        certificateFile: _selectedCertificate!,
        signerName: _certificateInfo?.commonName ?? 'Firmante',
        signerId: _signerIdController.text,
        location: _locationController.text,
        reason: _reasonController.text,
        certificatePassword: _passwordController.text,
        signatureX: pdfPosition.x,
        signatureY: pdfPosition.y,
        signatureWidth: pdfPosition.signatureWidth,
        signatureHeight: pdfPosition.signatureHeight,
        signaturePage: pdfPosition.pageNumber,
        enableTimestamp: _enableTimestamp,
        timestampServerUrl: _selectedTsaServer,
      );

      setState(() {
        _isLoading = false;
        _lastUsedMethod = result.signingMethod;
      });

      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error signing document: $e');
      _showErrorDialog('Error inesperado: $e');
    }
  }

  void _showSuccessDialog(HybridSignatureResult result) {
    final methodText = result.signingMethod == SigningMethod.local 
        ? 'Firmado localmente en Android' 
        : 'Firmado mediante backend';
    
    final methodIcon = result.signingMethod == SigningMethod.local 
        ? Icons.phone_android 
        : Icons.cloud;
    
    final methodColor = result.signingMethod == SigningMethod.local 
        ? Colors.green 
        : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Firma Exitosa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(methodIcon, color: methodColor, size: 20),
                const SizedBox(width: 8),
                Text(methodText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Archivo: ${result.signedFilePath?.split('/').last ?? 'N/A'}'),
            if (result.timestampUsed) ...[
              const SizedBox(height: 8),
              Text('Sellado de tiempo: ${result.timestampInfo ?? 'Incluido'}'),
              if (result.tsaServerUsed != null)
                Text('Servidor TSA: ${_getTsaServerDisplayName(result.tsaServerUsed!)}'),
            ],
            if (result.warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Advertencia: ${result.warning}',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            ],
            if (result.backendInfo != null) ...[
              const SizedBox(height: 8),
              Text('ID: ${result.backendInfo!.documentId ?? 'N/A'}'),
              if (result.backendInfo!.fileSize != null)
                Text('Tamaño: ${_formatFileSize(result.backendInfo!.fileSize!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (result.signedFilePath != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareSignedDocument(result.signedFilePath!);
              },
              child: const Text('Compartir'),
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
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSignedDocument(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Documento firmado digitalmente');
    } catch (e) {
      _showErrorDialog('Error al compartir documento: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getTsaServerDisplayName(String url) {
    return _tsaServers[url] ?? 'Custom TSA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmador Android'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_healthStatus != null)
            IconButton(
              icon: Icon(
                _healthStatus!.overallHealth ? Icons.health_and_safety : Icons.warning,
                color: _healthStatus!.overallHealth ? Colors.green : Colors.orange,
              ),
              onPressed: _showHealthDialog,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service Status Card
              if (_healthStatus != null) _buildServiceStatusCard(),
              
              const SizedBox(height: 16),
              
              // Document Selection Card
              _buildDocumentSelectionCard(),
              
              const SizedBox(height: 16),
              
              // Certificate Selection Card  
              _buildCertificateSelectionCard(),
              
              const SizedBox(height: 16),
              
              // Signature Details Card
              _buildSignatureDetailsCard(),
              
              const SizedBox(height: 16),
              
              // PDF Preview (if document selected)
              if (_selectedDocument != null) _buildPdfPreviewCard(),
              
              const SizedBox(height: 24),
              
              // Sign Button
              _buildSignButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del Servicio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _healthStatus!.localHealth ? Icons.phone_android : Icons.phone_android_outlined,
                  color: _healthStatus!.localHealth ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Local Android: ${_healthStatus!.localHealth ? 'Disponible' : 'No disponible'}',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _healthStatus!.backendHealth ? Icons.cloud : Icons.cloud_off,
                  color: _healthStatus!.backendHealth ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Backend: ${_healthStatus!.backendHealth ? 'Disponible' : 'No disponible'}',
                ),
              ],
            ),
            if (_lastUsedMethod != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _lastUsedMethod == SigningMethod.local ? Colors.green.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Última firma: ${_lastUsedMethod == SigningMethod.local ? 'Local' : 'Backend'}',
                  style: TextStyle(
                    color: _lastUsedMethod == SigningMethod.local ? Colors.green.shade800 : Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Seleccionar Documento PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedDocument != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDocument!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedDocument = null),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _selectDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. Seleccionar Certificado Digital',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedCertificate != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCertificate!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _selectedCertificate = null;
                        _certificateInfo = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña del certificado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                onChanged: (value) => setState(() => _certificateInfo = null),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadCertificateInfo,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.info),
                label: Text(_isLoading ? 'Validando...' : 'Validar Certificado'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _selectCertificate,
                icon: const Icon(Icons.security),
                label: const Text('Seleccionar Certificado (.p12/.pfx)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. Detalles de la Firma',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _signerNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del firmante',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _signerIdController,
              decoration: const InputDecoration(
                labelText: 'Cédula/ID del firmante',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Razón de la firma',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Incluir sellado de tiempo (TSA)'),
              subtitle: Text(
                _enableTimestamp 
                    ? 'El documento incluirá un timestamp verificable'
                    : 'No se incluirá timestamp',
              ),
              value: _enableTimestamp,
              onChanged: (value) => setState(() => _enableTimestamp = value),
            ),
            if (_enableTimestamp) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTsaServer,
                decoration: const InputDecoration(
                  labelText: 'Servidor de sellado de tiempo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: _tsaServers.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedTsaServer = value!),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Recordar datos para próximas firmas'),
              subtitle: const Text('Los datos se guardan localmente en el dispositivo'),
              value: _rememberData,
              onChanged: (value) => setState(() => _rememberData = value ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4. Posición de la Firma',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca en el documento donde quieres colocar la firma:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PdfPreviewWidget(
                pdfFile: _selectedDocument!,
                onPositionSelected: _onSignaturePositionSelected,
                selectedPosition: _signaturePosition,
              ),
            ),
            if (_signaturePosition != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Firma en página ${_signaturePosition!.page}, posición (${_signaturePosition!.position.dx.toInt()}, ${_signaturePosition!.position.dy.toInt()})',
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignButton() {
    final canSign = _selectedDocument != null &&
        _selectedCertificate != null &&
        _certificateInfo != null &&
        _signaturePosition != null &&
        _passwordController.text.isNotEmpty &&
        _signerNameController.text.isNotEmpty;

    return ElevatedButton.icon(
      onPressed: canSign && !_isLoading ? _signDocument : null,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.edit),
      label: Text(_isLoading ? 'Firmando documento...' : 'Firmar Documento'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showHealthDialog() {
    if (_healthStatus == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estado del Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthItem('Firma Local Android', _healthStatus!.localHealth),
            _buildHealthItem('Backend', _healthStatus!.backendHealth),
            const SizedBox(height: 16),
            Text(
              'Estado general: ${_healthStatus!.overallHealth ? 'Operativo' : 'Limitado'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _healthStatus!.overallHealth ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkServiceHealth();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String name, bool isHealthy) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text('$name: ${isHealthy ? 'Disponible' : 'No disponible'}'),
      ],
    );
  }
} 