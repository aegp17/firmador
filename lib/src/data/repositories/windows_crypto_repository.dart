import 'dart:io';
import 'package:flutter/services.dart';
import '../../domain/entities/certificate_info.dart';
import '../../domain/repositories/crypto_repository.dart';

/// Repository implementation for Windows platform using native Windows crypto APIs
class WindowsCryptoRepository implements CryptoRepository {
  static const MethodChannel _channel = MethodChannel('com.example.firmador/native_crypto');

  @override
  Future<CertificateInfo?> loadCertificate({
    String? certificatePath,
    String? password,
    String? thumbprint,
  }) async {
    try {
      Map<String, dynamic> arguments = {};
      
      if (thumbprint != null) {
        arguments['thumbprint'] = thumbprint;
      } else if (certificatePath != null && password != null) {
        arguments['certificatePath'] = certificatePath;
        arguments['password'] = password;
      } else {
        throw ArgumentError('Either thumbprint or certificatePath+password must be provided');
      }

      final result = await _channel.invokeMethod('getCertificateInfo', arguments);
      if (result != null) {
        return CertificateInfo.fromJson(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      print('Error loading certificate: ${e.message}');
      return null;
    }
  }

  @override
  Future<List<CertificateInfo>> getAvailableCertificates() async {
    try {
      final result = await _channel.invokeMethod('getAvailableCertificates');
      if (result != null) {
        final List<dynamic> certificateList = result;
        return certificateList
            .map((cert) => CertificateInfo.fromJson(Map<String, dynamic>.from(cert)))
            .toList();
      }
      return [];
    } on PlatformException catch (e) {
      print('Error getting available certificates: ${e.message}');
      return [];
    }
  }

  @override
  Future<String?> signPdf({
    required String pdfPath,
    required String outputPath,
    String? certificatePath,
    String? password,
    String? thumbprint,
    Map<String, dynamic>? position,
    bool includeTimestamp = true,
  }) async {
    try {
      Map<String, dynamic> arguments = {
        'pdfPath': pdfPath,
        'outputPath': outputPath,
        'includeTimestamp': includeTimestamp,
      };

      if (position != null) {
        arguments['position'] = position;
      }

      if (thumbprint != null) {
        arguments['thumbprint'] = thumbprint;
      } else if (certificatePath != null && password != null) {
        arguments['certificatePath'] = certificatePath;
        arguments['password'] = password;
      } else {
        throw ArgumentError('Either thumbprint or certificatePath+password must be provided');
      }

      final result = await _channel.invokeMethod('signPdf', arguments);
      if (result != null && result['success'] == true) {
        return result['signedPdfPath'];
      }
      return null;
    } on PlatformException catch (e) {
      print('Error signing PDF: ${e.message}');
      return null;
    }
  }

  @override
  Future<bool> validatePdf(String pdfPath) async {
    try {
      final result = await _channel.invokeMethod('validatePdf', {'pdfPath': pdfPath});
      return result?['isValid'] ?? false;
    } on PlatformException catch (e) {
      print('Error validating PDF: ${e.message}');
      return false;
    }
  }

  /// Test TSA server connectivity
  Future<List<Map<String, dynamic>>> testTSAConnectivity() async {
    try {
      final result = await _channel.invokeMethod('testTSAConnectivity');
      if (result != null) {
        return List<Map<String, dynamic>>.from(
          result.map((server) => Map<String, dynamic>.from(server))
        );
      }
      return [];
    } on PlatformException catch (e) {
      print('Error testing TSA connectivity: ${e.message}');
      return [];
    }
  }
} 