import 'package:flutter/services.dart';
import '../../domain/entities/certificate_info.dart';
import '../../domain/repositories/crypto_repository.dart';
import 'dart:io';

/// Repository implementation for Windows platform using native Windows crypto APIs
class WindowsCryptoRepository implements CryptoRepository {
  static const MethodChannel _channel = MethodChannel('com.example.firmador/native_crypto');

  @override
  Future<CertificateInfo> getCertificateInfo({
    required String p12Path,
    required String password,
  }) async {
    try {
      final result = await _channel.invokeMethod('getCertificateInfo', {
        'certificatePath': p12Path,
        'password': password,
      });
      
      if (result != null) {
        return CertificateInfo.fromJson(Map<String, dynamic>.from(result));
      }
      throw Exception('Failed to load certificate information');
    } on PlatformException catch (e) {
      throw Exception('Error loading certificate: ${e.message}');
    }
  }

  @override
  Future<File> signPdf({
    required String pdfPath,
    required String p12Path,
    required String password,
    required int page,
    required double x,
    required double y,
  }) async {
    try {
      final outputPath = pdfPath.replaceAll('.pdf', '_signed.pdf');
      
      final result = await _channel.invokeMethod('signPdf', {
        'pdfPath': pdfPath,
        'outputPath': outputPath,
        'certificatePath': p12Path,
        'password': password,
        'position': {
          'x': x,
          'y': y,
          'pageNumber': page,
          'width': 200.0,
          'height': 50.0,
        },
        'includeTimestamp': true,
      });

      if (result != null && result['success'] == true) {
        final signedPath = result['signedPdfPath'] as String;
        return File(signedPath);
      } else {
        throw Exception(result?['errorMessage'] ?? 'Signing failed');
      }
    } on PlatformException catch (e) {
      throw Exception('Error signing PDF: ${e.message}');
    }
  }

  // Windows-specific methods (not part of the interface but used by Windows hybrid service)
  
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

  Future<String?> signPdfWithOptions({
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

      if (thumbprint != null) {
        arguments['thumbprint'] = thumbprint;
      } else if (certificatePath != null && password != null) {
        arguments['certificatePath'] = certificatePath;
        arguments['password'] = password;
      } else {
        throw ArgumentError('Either thumbprint or certificatePath+password must be provided');
      }

      if (position != null) {
        arguments['position'] = position;
      }

      final result = await _channel.invokeMethod('signPdf', arguments);
      
      if (result != null && result['success'] == true) {
        return result['signedPdfPath'] as String?;
      } else {
        throw Exception(result?['errorMessage'] ?? 'Signing failed');
      }
    } on PlatformException catch (e) {
      print('Error signing PDF: ${e.message}');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> testTSAConnectivity() async {
    try {
      final result = await _channel.invokeMethod('testTSAConnectivity');
      if (result != null && result['servers'] != null) {
        return List<Map<String, dynamic>>.from(result['servers']);
      }
      return [];
    } on PlatformException catch (e) {
      print('Error testing TSA connectivity: ${e.message}');
      return [];
    }
  }

  Future<bool> validatePdf(String pdfPath) async {
    try {
      final result = await _channel.invokeMethod('validatePdf', {
        'pdfPath': pdfPath,
      });
      return result?['isValid'] ?? false;
    } on PlatformException catch (e) {
      print('Error validating PDF: ${e.message}');
      return false;
    }
  }
} 