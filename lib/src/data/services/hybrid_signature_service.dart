import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firmador/src/data/services/backend_signature_service.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';

/// Hybrid signature service that tries local signing first, then backend fallback
class HybridSignatureService {
  static const _platformChannel = MethodChannel('com.firmador/crypto');
  final BackendSignatureService _backendService = BackendSignatureService();

  /// Sign document with hybrid approach: try local first, then backend
  Future<HybridSignatureResult> signDocument({
    required File documentFile,
    required File certificateFile,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    required String certificatePassword,
    double signatureX = 100.0,
    double signatureY = 100.0,
    double signatureWidth = 150.0,
    double signatureHeight = 50.0,
    int signaturePage = 1,
    bool enableTimestamp = false,
    String timestampServerUrl = 'https://freetsa.org/tsr',
  }) async {
    debugPrint('🔄 HybridSignatureService: Starting hybrid signing process');

    // Try local signing first on Android
    if (Platform.isAndroid) {
      debugPrint('📱 Attempting local Android signing...');
      
      try {
        final localResult = await _signLocally(
          documentFile: documentFile,
          certificateFile: certificateFile,
          signerName: signerName,
          location: location,
          reason: reason,
          certificatePassword: certificatePassword,
          signatureX: signatureX,
          signatureY: signatureY,
          signatureWidth: signatureWidth,
          signatureHeight: signatureHeight,
          signaturePage: signaturePage,
          enableTimestamp: enableTimestamp,
          timestampServerUrl: timestampServerUrl,
        );

        if (localResult.success) {
          debugPrint('✅ Local Android signing successful!');
          return HybridSignatureResult(
            success: true,
            message: localResult.message,
            signedFilePath: localResult.signedFilePath!,
            timestampUsed: localResult.timestampUsed,
            timestampInfo: localResult.timestampInfo,
            signingMethod: SigningMethod.local,
            tsaServerUsed: localResult.tsaServerUsed,
            warning: localResult.warning,
          );
        } else {
          debugPrint('⚠️ Local Android signing failed: ${localResult.message}');
        }
      } catch (e) {
        debugPrint('❌ Local Android signing error: $e');
      }
    }

    // Fallback to backend signing
    debugPrint('🌐 Falling back to backend signing...');
    
    try {
      final backendResult = await _backendService.signDocument(
        documentFile: documentFile,
        certificateFile: certificateFile,
        signerName: signerName,
        signerId: signerId,
        location: location,
        reason: reason,
        certificatePassword: certificatePassword,
        signatureX: signatureX,
        signatureY: signatureY,
        signatureWidth: signatureWidth,
        signatureHeight: signatureHeight,
        signaturePage: signaturePage,
        enableTimestamp: enableTimestamp,
        timestampServerUrl: timestampServerUrl,
      );

      if (backendResult.success) {
        debugPrint('✅ Backend signing successful!');
        return HybridSignatureResult(
          success: true,
          message: backendResult.message,
          signedFilePath: backendResult.downloadUrl!,
          timestampUsed: enableTimestamp, // Backend handles timestamp
          signingMethod: SigningMethod.backend,
          backendInfo: BackendInfo(
            documentId: backendResult.documentId,
            filename: backendResult.filename,
            fileSize: backendResult.fileSize,
            signedAt: backendResult.signedAt,
          ),
        );
      } else {
        debugPrint('❌ Backend signing failed: ${backendResult.message}');
        return HybridSignatureResult(
          success: false,
          message: 'Both local and backend signing failed: ${backendResult.message}',
          signingMethod: SigningMethod.failed,
        );
      }
    } catch (e) {
      debugPrint('❌ Backend signing error: $e');
      return HybridSignatureResult(
        success: false,
        message: 'All signing methods failed. Local: Not available/failed, Backend: $e',
        signingMethod: SigningMethod.failed,
      );
    }
  }

  /// Get certificate information (tries local first, then backend)
  Future<HybridCertificateResult> getCertificateInfo({
    required File certificateFile,
    required String password,
  }) async {
    debugPrint('🔄 HybridSignatureService: Getting certificate info');

    // Try local extraction first on Android
    if (Platform.isAndroid) {
      debugPrint('📱 Attempting local certificate extraction...');
      
      try {
        final result = await _platformChannel.invokeMapMethod<String, dynamic>(
          'getCertificateInfo',
          {
            'p12Path': certificateFile.path,
            'password': password,
          },
        );

        if (result != null) {
          debugPrint('✅ Local certificate extraction successful!');
          
          final certificateInfo = CertificateInfo.fromMap(result);
          return HybridCertificateResult(
            success: true,
            certificateInfo: certificateInfo,
            extractionMethod: ExtractionMethod.local,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Local certificate extraction failed: $e');
      }
    }

    // Fallback to backend extraction
    debugPrint('🌐 Falling back to backend certificate extraction...');
    
    try {
      final backendResult = await _backendService.getCertificateInfo(
        certificateFile: certificateFile,
        password: password,
      );

      if (backendResult.success && backendResult.certificateInfo != null) {
        debugPrint('✅ Backend certificate extraction successful!');
        return HybridCertificateResult(
          success: true,
          certificateInfo: backendResult.certificateInfo!,
          extractionMethod: ExtractionMethod.backend,
          message: backendResult.message,
        );
      } else {
        return HybridCertificateResult(
          success: false,
          message: 'Certificate extraction failed: ${backendResult.message}',
          extractionMethod: ExtractionMethod.failed,
        );
      }
    } catch (e) {
      debugPrint('❌ Backend certificate extraction error: $e');
      return HybridCertificateResult(
        success: false,
        message: 'All certificate extraction methods failed: $e',
        extractionMethod: ExtractionMethod.failed,
      );
    }
  }

  /// Check service health (local capabilities + backend health)
  Future<HybridHealthResult> checkHealth() async {
    final results = <String, bool>{};
    
    // Check local capabilities on Android
    if (Platform.isAndroid) {
      try {
        // Try a simple method call to test local capabilities
        await _platformChannel.invokeMethod('getCertificateInfo', {
          'p12Path': '/non/existent/path.p12',
          'password': 'test',
        });
        results['local_android'] = false; // Should fail but not crash
      } catch (e) {
        // Expected to fail, but should be a controlled failure
        results['local_android'] = e is PlatformException;
      }
    } else {
      results['local_android'] = false;
    }

    // Check backend health
    try {
      final backendHealth = await _backendService.checkHealth();
      results['backend'] = backendHealth;
    } catch (e) {
      results['backend'] = false;
    }

    final hasAnyMethod = results.values.any((health) => health);
    
    return HybridHealthResult(
      overallHealth: hasAnyMethod,
      localHealth: results['local_android'] ?? false,
      backendHealth: results['backend'] ?? false,
      details: results,
    );
  }

  /// Internal method for local Android signing
  Future<LocalSignatureResult> _signLocally({
    required File documentFile,
    required File certificateFile,
    required String signerName,
    required String location,
    required String reason,
    required String certificatePassword,
    required double signatureX,
    required double signatureY,
    required double signatureWidth,
    required double signatureHeight,
    required int signaturePage,
    required bool enableTimestamp,
    required String timestampServerUrl,
  }) async {
    try {
      final result = await _platformChannel.invokeMapMethod<String, dynamic>(
        'signPdf',
        {
          'pdfPath': documentFile.path,
          'p12Path': certificateFile.path,
          'password': certificatePassword,
          'page': signaturePage - 1, // Android uses 0-based indexing
          'x': signatureX,
          'y': signatureY,
          'width': signatureWidth,
          'height': signatureHeight,
          'signerName': signerName,
          'location': location,
          'reason': reason,
          'enableTimestamp': enableTimestamp,
          'timestampServerUrl': timestampServerUrl,
        },
      );

      if (result != null && result['success'] == true) {
        return LocalSignatureResult(
          success: true,
          message: result['message'] ?? 'Signed successfully',
          signedFilePath: result['signedFilePath'],
          timestampUsed: result['timestampUsed'] ?? false,
          timestampInfo: result['timestampInfo'],
          tsaServerUsed: result['tsaServerUsed'],
          warning: result['warning'],
        );
      } else {
        return LocalSignatureResult(
          success: false,
          message: result?['message'] ?? 'Local signing failed',
        );
      }
    } on PlatformException catch (e) {
      return LocalSignatureResult(
        success: false,
        message: e.message ?? 'Platform error during local signing',
      );
    }
  }
}

/// Enumeration of signing methods
enum SigningMethod { local, backend, failed }

/// Enumeration of certificate extraction methods
enum ExtractionMethod { local, backend, failed }

/// Result of hybrid signature operation
class HybridSignatureResult {
  final bool success;
  final String message;
  final String? signedFilePath;
  final bool timestampUsed;
  final String? timestampInfo;
  final SigningMethod signingMethod;
  final String? tsaServerUsed;
  final String? warning;
  final BackendInfo? backendInfo;

  HybridSignatureResult({
    required this.success,
    required this.message,
    this.signedFilePath,
    this.timestampUsed = false,
    this.timestampInfo,
    required this.signingMethod,
    this.tsaServerUsed,
    this.warning,
    this.backendInfo,
  });
}

/// Result of local signature operation
class LocalSignatureResult {
  final bool success;
  final String message;
  final String? signedFilePath;
  final bool timestampUsed;
  final String? timestampInfo;
  final String? tsaServerUsed;
  final String? warning;

  LocalSignatureResult({
    required this.success,
    required this.message,
    this.signedFilePath,
    this.timestampUsed = false,
    this.timestampInfo,
    this.tsaServerUsed,
    this.warning,
  });
}

/// Result of hybrid certificate operation
class HybridCertificateResult {
  final bool success;
  final String? message;
  final CertificateInfo? certificateInfo;
  final ExtractionMethod extractionMethod;

  HybridCertificateResult({
    required this.success,
    this.message,
    this.certificateInfo,
    required this.extractionMethod,
  });
}

/// Backend-specific information
class BackendInfo {
  final String? documentId;
  final String? filename;
  final int? fileSize;
  final DateTime? signedAt;

  BackendInfo({
    this.documentId,
    this.filename,
    this.fileSize,
    this.signedAt,
  });
}

/// Result of hybrid health check
class HybridHealthResult {
  final bool overallHealth;
  final bool localHealth;
  final bool backendHealth;
  final Map<String, bool> details;

  HybridHealthResult({
    required this.overallHealth,
    required this.localHealth,
    required this.backendHealth,
    required this.details,
  });
} 