import 'dart:io';

import 'package:firmador/src/domain/entities/certificate_info.dart';

abstract class CryptoRepository {
  Future<CertificateInfo> getCertificateInfo({
    required String p12Path,
    required String password,
  });

  Future<File> signPdf({
    required String pdfPath,
    required String p12Path,
    required String password,
    required int page,
    required double x,
    required double y,
  });
} 