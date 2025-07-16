import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../providers/repository_providers.dart';
import '../widgets/pdf_preview_widget.dart';
import '../../domain/entities/certificate_info.dart';
import '../../data/repositories/windows_hybrid_signature_service.dart';

class WindowsSignatureScreen extends ConsumerStatefulWidget {
  const WindowsSignatureScreen({super.key});

  @override
  ConsumerState<WindowsSignatureScreen> createState() => _WindowsSignatureScreenState();
}

class _WindowsSignatureScreenState extends ConsumerState<WindowsSignatureScreen> {
  File? _selectedPdf;
  CertificateInfo? _selectedCertificate;
  String? _certificatePath;
  String? _password;
  PdfPosition? _signaturePosition;
  bool _includeTimestamp = true;
  bool _isLoading = false;
  bool _forceBackend = false;
  List<CertificateInfo> _availableCertificates = [];
  Map<String, dynamic>? _localCapabilities;
  List<Map<String, dynamic>> _tsaServers = [];

  @override
  void initState() {
    super.initState();
    _loadWindowsCapabilities();
  }

  Future<void> _loadWindowsCapabilities() async {
    try {
      final service = ref.read(windowsHybridSignatureServiceProvider);
      final capabilities = await service.testLocalCapabilities();
      final certificates = await service.getAvailableCertificates();
      
      setState(() {
        _localCapabilities = capabilities;
        _availableCertificates = certificates;
      });
    } catch (e) {
      print('Error loading Windows capabilities: $e');
    }
  }

  Future<void> _selectPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectCertificateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12', 'pfx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _certificatePath = result.files.single.path!;
        _selectedCertificate = null; // Clear store certificate selection
      });
      await _loadCertificateInfo();
    }
  }

  Future<void> _loadCertificateInfo() async {
    if (_certificatePath == null || _password == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(windowsHybridSignatureServiceProvider);
      final certificateInfo = await service.loadCertificate(
        certificatePath: _certificatePath,
        password: _password,
      );

      setState(() {
        _selectedCertificate = certificateInfo;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading certificate: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signPdf() async {
    if (_selectedPdf == null || _selectedCertificate == null || _signaturePosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select PDF, certificate, and signature position')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final outputPath = path.join(
        path.dirname(_selectedPdf!.path),
        '${path.basenameWithoutExtension(_selectedPdf!.path)}_signed.pdf',
      );

      final service = ref.read(windowsHybridSignatureServiceProvider);
      
      final result = await service.signPdf(
        pdfPath: _selectedPdf!.path,
        outputPath: outputPath,
        certificatePath: _certificatePath,
        password: _password,
        thumbprint: _selectedCertificate?.thumbprint,
        position: _signaturePosition!.toMap(),
        includeTimestamp: _includeTimestamp,
        forceBackend: _forceBackend,
      );

      if (result.success && result.signedPdfPath != null) {
        if (mounted) {
          _showSuccessDialog(result);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signing failed: ${result.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during signing: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(WindowsSigningResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 PDF Signed Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Method: ${result.method == WindowsSigningMethod.local ? '🔧 Windows Local' : '🌐 Backend'}'),
            if (result.timestampServer != null)
              Text('TSA: ${result.timestampServer}'),
            if (result.duration != null)
              Text('Duration: ${result.duration!.inMilliseconds}ms'),
            const SizedBox(height: 16),
            Text('Signed PDF saved to:\n${result.signedPdfPath}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪟 Windows Digital Signature'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCapabilitiesDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCapabilityStatusCard(),
                    const SizedBox(height: 16),
                    _buildPdfSelectionCard(),
                    const SizedBox(height: 16),
                    _buildCertificateSelectionCard(),
                    const SizedBox(height: 16),
                    if (_selectedPdf != null) _buildPdfPreviewCard(),
                    const SizedBox(height: 16),
                    _buildSigningOptionsCard(),
                    const SizedBox(height: 24),
                    _buildSignButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCapabilityStatusCard() {
    final isAvailable = _localCapabilities?['available'] ?? false;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.error,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Windows Crypto Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isAvailable) ...[
              Text('✅ Local signing available'),
              Text('📜 Certificates: ${_localCapabilities?['certificateCount'] ?? 0}'),
              Text('🕐 TSA servers: ${_localCapabilities?['tsaServers'] ?? 0}'),
            ] else ...[
              Text('⚠️ Local signing unavailable'),
              if (_localCapabilities?['error'] != null)
                Text('Error: ${_localCapabilities!['error']}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📄 Select PDF Document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Choose PDF'),
            ),
            if (_selectedPdf != null) ...[
              const SizedBox(height: 8),
              Text('Selected: ${path.basename(_selectedPdf!.path)}'),
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
            Text(
              '🔐 Certificate Selection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Windows Certificate Store
            if (_availableCertificates.isNotEmpty) ...[
              Text('Windows Certificate Store:', 
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CertificateInfo>(
                decoration: const InputDecoration(
                  labelText: 'Select from Store',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCertificate,
                items: _availableCertificates.map((cert) {
                  return DropdownMenuItem(
                    value: cert,
                    child: Text(cert.subject ?? 'Unknown Certificate'),
                  );
                }).toList(),
                onChanged: (cert) {
                  setState(() {
                    _selectedCertificate = cert;
                    _certificatePath = null; // Clear file selection
                  });
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // PKCS#12 File
            Text('PKCS#12 File:', 
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _selectCertificateFile,
              icon: const Icon(Icons.security),
              label: const Text('Choose Certificate File'),
            ),
            if (_certificatePath != null) ...[
              const SizedBox(height: 8),
              Text('Selected: ${path.basename(_certificatePath!)}'),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) {
                  _password = value;
                  if (value.isNotEmpty) {
                    _loadCertificateInfo();
                  }
                },
              ),
            ],
            
            if (_selectedCertificate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certificate Info:', style: Theme.of(context).textTheme.bodySmall),
                    Text('Subject: ${_selectedCertificate!.subject}'),
                    Text('Valid: ${_selectedCertificate!.validFrom} - ${_selectedCertificate!.validTo}'),
                    if (_selectedCertificate!.keyUsage.isNotEmpty)
                      Text('Usage: ${_selectedCertificate!.keyUsage.join(', ')}'),
                  ],
                ),
              ),
            ],
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
            Text(
              '👁️ PDF Preview & Signature Position',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: PdfPreviewWidget(
                pdfFile: _selectedPdf!,
                onPositionSelected: (position) {
                  setState(() {
                    _signaturePosition = position;
                  });
                },
                selectedPosition: _signaturePosition,
              ),
            ),
            if (_signaturePosition != null) ...[
              const SizedBox(height: 8),
              Text('Signature position: ${_signaturePosition.toString()}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSigningOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ Signing Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include Timestamp'),
              subtitle: const Text('Add RFC 3161 timestamp to signature'),
              value: _includeTimestamp,
              onChanged: (value) {
                setState(() {
                  _includeTimestamp = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Force Backend Mode'),
              subtitle: const Text('Skip local signing, use backend only'),
              value: _forceBackend,
              onChanged: (value) {
                setState(() {
                  _forceBackend = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignButton() {
    final canSign = _selectedPdf != null && 
                   _selectedCertificate != null && 
                   _signaturePosition != null;

    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: canSign ? _signPdf : null,
        icon: const Icon(Icons.edit_document),
        label: Text(_forceBackend ? 'Sign with Backend' : 'Sign PDF (Hybrid)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _forceBackend ? Colors.orange : Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showCapabilitiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Windows Capabilities'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_localCapabilities != null) ...[
              Text('Local Signing: ${_localCapabilities!['available'] ? '✅ Available' : '❌ Unavailable'}'),
              Text('Certificates: ${_localCapabilities!['certificateCount'] ?? 0}'),
              Text('TSA Servers: ${_localCapabilities!['tsaServers'] ?? 0}'),
              if (_localCapabilities!['error'] != null)
                Text('Error: ${_localCapabilities!['error']}'),
            ] else ...[
              const Text('Loading capabilities...'),
            ],
            const SizedBox(height: 16),
            const Text('Features:'),
            const Text('• Windows Certificate Store integration'),
            const Text('• Local PDF signing with timestamps'),
            const Text('• Automatic backend fallback'),
            const Text('• Multiple TSA server support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

extension PdfPositionExtension on PdfPosition {
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'pageNumber': pageNumber,
      'width': 200.0,
      'height': 50.0,
    };
  }
} 