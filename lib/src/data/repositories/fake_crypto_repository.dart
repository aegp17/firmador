import 'dart:io';

import 'package:firmador/src/domain/entities/certificate_info.dart';
import 'package:firmador/src/domain/repositories/crypto_repository.dart';

/// A fake implementation of [CryptoRepository] for testing and development.
/// This repository simulates certificate operations with mock data.
class FakeCryptoRepository implements CryptoRepository {
  
  @override
  Future<CertificateInfo> getCertificateInfo({
    required String p12Path,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simulate password validation
    if (password.isEmpty) {
      throw Exception('Password cannot be empty');
    }
    
    if (password == 'wrong') {
      throw Exception('Contraseña incorrecta.');
    }
    
    // Simulate file validation
    final file = File(p12Path);
    if (!file.existsSync()) {
      throw Exception('El archivo del certificado no existe: $p12Path');
    }
    
    // Return mock certificate data
    final now = DateTime.now();
    final validFrom = now.subtract(const Duration(days: 365));
    final validTo = now.add(const Duration(days: 365));
    
    return CertificateInfo(
      subject: 'CN=Juan Pérez,OU=Desarrollo,O=Empresa Ejemplo,L=Quito,ST=Pichincha,C=EC',
      issuer: 'CN=AUTORIDAD DE CERTIFICACION SUBCA-1 FIRMASEGURA S.A.S.,OU=ENTIDAD DE CERTIFICACION DE INFORMACION,O=FIRMASEGURA S.A.S.,L=AMBATO,ST=TUNGURAHUA,C=EC',
      validFrom: validFrom,
      validTo: validTo,
      serialNumber: '4A:B2:C8:D5:3F:12:87:E9:44:A1:B3:C7:F8:D2:E5:91',
      commonName: 'Juan Pérez',
      keyUsages: [
        'Digital Signature',
        'Key Encipherment',
        'Data Encipherment',
        'Key Agreement',
        'Certificate Sign',
        'CRL Sign'
      ],
      isTrusted: true,
    );
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
    // Simulate signing delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Validate input parameters
    if (password.isEmpty) {
      throw Exception('Password is required for signing');
    }
    
    final originalFile = File(pdfPath);
    if (!originalFile.existsSync()) {
      throw Exception('PDF file not found: $pdfPath');
    }
    
    final p12File = File(p12Path);
    if (!p12File.existsSync()) {
      throw Exception('Certificate file not found: $p12Path');
    }
    
    // Create a fake signed PDF by copying the original
    final originalDir = originalFile.parent;
    final originalName = originalFile.uri.pathSegments.last.replaceAll('.pdf', '');
    final signedPath = '${originalDir.path}/${originalName}_signed.pdf';
    final signedFile = File(signedPath);
    
    // Copy original file to create fake signed version
    await originalFile.copy(signedPath);
    
    // Fake signing completed successfully
    
    return signedFile;
  }
} 