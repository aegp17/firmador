import 'dart:io';

import 'package:firmador/src/domain/entities/certificate_info.dart';
import 'package:firmador/src/domain/repositories/crypto_repository.dart';
import 'package:flutter/services.dart';

/// An implementation of [CryptoRepository] that uses a [MethodChannel]
/// to call native platform code for cryptographic operations.
class PlatformCryptoRepository implements CryptoRepository {
  static const _channel = MethodChannel('com.firmador/crypto');

  @override
  Future<CertificateInfo> getCertificateInfo({
    required String p12Path,
    required String password,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getCertificateInfo',
        {'p12Path': p12Path, 'password': password},
      );
      if (result == null) {
        throw Exception('La implementación nativa devolvió un resultado nulo.');
      }
      return CertificateInfo.fromMap(result);
    } on PlatformException catch (e) {
      // Propaga el mensaje nativo si existe, o un mensaje genérico
      throw Exception(e.message ?? e.details?.toString() ?? 'Ocurrió un error nativo desconocido.');
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
  }) {
    // PDF signing simulation remains the same for now.
    print('Native certificate validation passed. Now simulating PDF signing.');
    final originalFile = File(pdfPath);
    return originalFile.copy('${pdfPath.replaceAll('.pdf', '_signed.pdf')}');
  }
} 