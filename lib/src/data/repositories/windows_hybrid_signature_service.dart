import 'dart:io';
import '../../domain/entities/certificate_info.dart';
import 'windows_crypto_repository.dart';
import 'platform_crypto_repository.dart';

enum WindowsSigningMethod { local, backend }

class WindowsSigningResult {
  final bool success;
  final String? signedPdfPath;
  final String? errorMessage;
  final WindowsSigningMethod method;
  final String? timestampServer;
  final Duration? duration;

  WindowsSigningResult({
    required this.success,
    this.signedPdfPath,
    this.errorMessage,
    required this.method,
    this.timestampServer,
    this.duration,
  });
}

/// Hybrid signature service for Windows: try local first, fallback to backend
class WindowsHybridSignatureService {
  final WindowsCryptoRepository _windowsRepository = WindowsCryptoRepository();
  final PlatformCryptoRepository _backendRepository = PlatformCryptoRepository();

  /// Sign PDF using hybrid approach: Windows local first, backend fallback
  Future<WindowsSigningResult> signPdf({
    required String pdfPath,
    required String outputPath,
    String? certificatePath,
    String? password,
    String? thumbprint,
    Map<String, dynamic>? position,
    bool includeTimestamp = true,
    bool forceBackend = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Force backend mode if requested
    if (forceBackend) {
      return _signWithBackend(
        pdfPath: pdfPath,
        outputPath: outputPath,
        certificatePath: certificatePath,
        password: password,
        position: position,
        includeTimestamp: includeTimestamp,
        stopwatch: stopwatch,
      );
    }

    // Try Windows local signing first
    try {
      print('🔧 Attempting Windows local signing...');
      
      final result = await _windowsRepository.signPdfWithOptions(
        pdfPath: pdfPath,
        outputPath: outputPath,
        certificatePath: certificatePath,
        password: password,
        thumbprint: thumbprint,
        position: position,
        includeTimestamp: includeTimestamp,
      );

      if (result != null && File(result).existsSync()) {
        stopwatch.stop();
        print('✅ Windows local signing successful in ${stopwatch.elapsedMilliseconds}ms');
        
        return WindowsSigningResult(
          success: true,
          signedPdfPath: result,
          method: WindowsSigningMethod.local,
          timestampServer: 'Local TSA Client',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      print('⚠️ Windows local signing failed: $e');
    }

    // Fallback to backend
    print('🌐 Falling back to backend signing...');
    return _signWithBackend(
      pdfPath: pdfPath,
      outputPath: outputPath,
      certificatePath: certificatePath,
      password: password,
      position: position,
      includeTimestamp: includeTimestamp,
      stopwatch: stopwatch,
    );
  }

  Future<WindowsSigningResult> _signWithBackend({
    required String pdfPath,
    required String outputPath,
    String? certificatePath,
    String? password,
    Map<String, dynamic>? position,
    bool includeTimestamp = true,
    required Stopwatch stopwatch,
  }) async {
    try {
      if (certificatePath == null || password == null) {
        return WindowsSigningResult(
          success: false,
          errorMessage: 'Certificate path and password required for backend signing',
          method: WindowsSigningMethod.backend,
          duration: stopwatch.elapsed,
        );
      }

      // Convert position for backend API
      double x = 100.0, y = 100.0;
      int page = 1;
      
      if (position != null) {
        x = (position['x'] as num?)?.toDouble() ?? 100.0;
        y = (position['y'] as num?)?.toDouble() ?? 100.0;
        page = (position['pageNumber'] as int?) ?? 1;
      }

      final result = await _backendRepository.signPdf(
        pdfPath: pdfPath,
        p12Path: certificatePath,
        password: password,
        page: page,
        x: x,
        y: y,
      );

      stopwatch.stop();

      if (result.existsSync()) {
        print('✅ Backend signing successful in ${stopwatch.elapsedMilliseconds}ms');
        
        return WindowsSigningResult(
          success: true,
          signedPdfPath: result.path,
          method: WindowsSigningMethod.backend,
          timestampServer: 'Backend TSA',
          duration: stopwatch.elapsed,
        );
      } else {
        return WindowsSigningResult(
          success: false,
          errorMessage: 'Backend signing failed: no output file',
          method: WindowsSigningMethod.backend,
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return WindowsSigningResult(
        success: false,
        errorMessage: 'Backend signing failed: $e',
        method: WindowsSigningMethod.backend,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Load certificate using Windows Certificate Store or PKCS#12 file
  Future<CertificateInfo?> loadCertificate({
    String? certificatePath,
    String? password,
    String? thumbprint,
  }) async {
    try {
      // Try Windows local first
      final localResult = await _windowsRepository.loadCertificate(
        certificatePath: certificatePath,
        password: password,
        thumbprint: thumbprint,
      );
      
      if (localResult != null) {
        return localResult;
      }
    } catch (e) {
      print('Windows certificate loading failed: $e');
    }

    // Fallback to backend if needed
    if (certificatePath != null && password != null) {
      try {
        return await _backendRepository.getCertificateInfo(
          p12Path: certificatePath,
          password: password,
        );
      } catch (e) {
        print('Backend certificate loading failed: $e');
      }
    }

    return null;
  }

  /// Get available certificates from Windows Certificate Store
  Future<List<CertificateInfo>> getAvailableCertificates() async {
    try {
      return await _windowsRepository.getAvailableCertificates();
    } catch (e) {
      print('Error getting Windows certificates: $e');
      return [];
    }
  }

  /// Test Windows local crypto capabilities
  Future<Map<String, dynamic>> testLocalCapabilities() async {
    try {
      final certificates = await _windowsRepository.getAvailableCertificates();
      final tsaServers = await _windowsRepository.testTSAConnectivity();
      
      return {
        'available': true,
        'certificateCount': certificates.length,
        'tsaServers': tsaServers.length,
        'tsaDetails': tsaServers,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  /// Validate PDF
  Future<bool> validatePdf(String pdfPath) async {
    try {
      // Try Windows local validation first
      final localResult = await _windowsRepository.validatePdf(pdfPath);
      if (localResult) return true;
    } catch (e) {
      print('Windows PDF validation failed: $e');
    }

    // Currently no backend validation available
    print('Backend PDF validation not implemented');
    return false;
  }
} 