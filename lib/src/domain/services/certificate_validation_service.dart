import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class CertificateValidationService {
  static const String _rootCaCertPath = 'assets/certificates/firmasegura_root_ca.pem';
  static const String _subCaCertPath = 'assets/certificates/firmasegura_sub_ca.pem';

  // Trusted CA information
  static const Map<String, String> trustedCAs = {
    'FIRMASEGURA_ROOT_CA': 'AUTORIDAD DE CERTIFICACION RAIZ CA-1 FIRMASEGURA S.A.S.',
    'FIRMASEGURA_SUB_CA': 'AUTORIDAD DE CERTIFICACION SUBCA-1 FIRMASEGURA S.A.S.',
  };

  // Serial numbers of trusted CAs
  static const Map<String, String> trustedSerials = {
    'FIRMASEGURA_ROOT_CA': 'ACA2C43F5805508A52D09F5C9FAC9CA6',
    'FIRMASEGURA_SUB_CA': 'D10DC6FB7670EDE3C957C896ACE941',
  };

  /// Loads trusted CA certificates from assets
  static Future<Map<String, String>> loadTrustedCACertificates() async {
    try {
      final rootCaCert = await rootBundle.loadString(_rootCaCertPath);
      final subCaCert = await rootBundle.loadString(_subCaCertPath);
      
      return {
        'root_ca': rootCaCert,
        'sub_ca': subCaCert,
      };
    } catch (e) {
      debugPrint('Error loading trusted CA certificates: $e');
      return {};
    }
  }

  /// Validates if a certificate is issued by a trusted CA
  static bool isCertificateFromTrustedCA(String issuerName, String serialNumber) {
    // Check if the issuer name matches any of our trusted CAs
    final normalizedIssuer = issuerName.toUpperCase();
    
    for (final trustedCA in trustedCAs.values) {
      if (normalizedIssuer.contains(trustedCA.toUpperCase()) ||
          normalizedIssuer.contains('FIRMASEGURA') ||
          normalizedIssuer.contains('AUTORIDAD DE CERTIFICACION')) {
        return true;
      }
    }

    // Check if the serial number matches any of our trusted CA serials
    final normalizedSerial = serialNumber.toUpperCase().replaceAll(':', '');
    
    for (final trustedSerial in trustedSerials.values) {
      if (normalizedSerial.contains(trustedSerial.toUpperCase())) {
        return true;
      }
    }

    return false;
  }

  /// Validates certificate chain
  static bool validateCertificateChain(
    String subjectName,
    String issuerName,
    String serialNumber,
    DateTime validFrom,
    DateTime validTo,
  ) {
    // Basic validation checks
    if (subjectName.isEmpty || issuerName.isEmpty) {
      return false;
    }

    // Check if certificate is still valid
    final now = DateTime.now();
    if (now.isBefore(validFrom) || now.isAfter(validTo)) {
      return false;
    }

    // Check if issued by trusted CA
    return isCertificateFromTrustedCA(issuerName, serialNumber);
  }

  /// Gets certificate trust level
  static String getCertificateTrustLevel(String issuerName, String serialNumber) {
    if (isCertificateFromTrustedCA(issuerName, serialNumber)) {
      return 'TRUSTED';
    }
    return 'UNTRUSTED';
  }

  /// Gets certificate validation details
  static Map<String, dynamic> getCertificateValidationDetails(
    String subjectName,
    String issuerName,
    String serialNumber,
    DateTime validFrom,
    DateTime validTo,
  ) {
    final isValid = validateCertificateChain(
      subjectName,
      issuerName,
      serialNumber,
      validFrom,
      validTo,
    );

    final isTrusted = isCertificateFromTrustedCA(issuerName, serialNumber);
    final trustLevel = getCertificateTrustLevel(issuerName, serialNumber);

    final now = DateTime.now();
    final isExpired = now.isAfter(validTo);
    final isNotYetValid = now.isBefore(validFrom);

    return {
      'isValid': isValid,
      'isTrusted': isTrusted,
      'trustLevel': trustLevel,
      'isExpired': isExpired,
      'isNotYetValid': isNotYetValid,
      'validationMessage': _getValidationMessage(isValid, isTrusted, isExpired, isNotYetValid),
    };
  }

  static String _getValidationMessage(
    bool isValid,
    bool isTrusted,
    bool isExpired,
    bool isNotYetValid,
  ) {
    if (isNotYetValid) {
      return 'El certificado aún no es válido';
    }
    if (isExpired) {
      return 'El certificado ha expirado';
    }
    if (!isTrusted) {
      return 'El certificado no es de una CA confiable';
    }
    if (isValid && isTrusted) {
      return 'Certificado válido y confiable';
    }
    return 'Certificado no válido';
  }

  /// Checks if certificate is about to expire (within 30 days)
  static bool isCertificateExpiringSoon(DateTime validTo) {
    final now = DateTime.now();
    final daysUntilExpiry = validTo.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Gets days until certificate expires
  static int getDaysUntilExpiry(DateTime validTo) {
    final now = DateTime.now();
    return validTo.difference(now).inDays;
  }
} 