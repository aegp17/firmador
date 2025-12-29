import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';

/// Service for securely storing and retrieving certificates and their passwords
/// Uses Flutter Secure Storage for encrypted storage on the device
class SecureCertificateStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(
      useSessionKeyring: true,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _certificatesListKey = 'saved_certificates_list';
  static const String _certificatePrefix = 'cert_';
  static const String _passwordPrefix = 'pwd_';
  static const String _infoPrefix = 'info_';

  /// Save a certificate file and its password securely
  /// Returns the certificate ID (UUID) for future reference
  Future<String> saveCertificate({
    required File certificateFile,
    required String password,
    required CertificateInfo certificateInfo,
    String? customName,
  }) async {
    try {
      // Generate unique ID for this certificate
      final certificateId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Read certificate file bytes
      final certificateBytes = await certificateFile.readAsBytes();
      
      // Encode certificate to base64 for storage
      final certificateBase64 = base64Encode(certificateBytes);
      
      // Store certificate data securely
      await _storage.write(
        key: '$_certificatePrefix$certificateId',
        value: certificateBase64,
      );
      
      // Store password securely
      await _storage.write(
        key: '$_passwordPrefix$certificateId',
        value: password,
      );
      
      // Store certificate info as JSON
      final infoJson = {
        'subject': certificateInfo.subject,
        'issuer': certificateInfo.issuer,
        'validFrom': certificateInfo.validFrom.toIso8601String(),
        'validTo': certificateInfo.validTo.toIso8601String(),
        'serialNumber': certificateInfo.serialNumber,
        'commonName': certificateInfo.commonName,
        'thumbprint': certificateInfo.thumbprint,
        'isValid': certificateInfo.isValid,
        'isTrusted': certificateInfo.isTrusted,
        'keyUsages': certificateInfo.keyUsages,
        'customName': customName ?? certificateInfo.commonName,
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      await _storage.write(
        key: '$_infoPrefix$certificateId',
        value: jsonEncode(infoJson),
      );
      
      // Add to certificates list
      await _addToCertificatesList(certificateId);
      
      return certificateId;
    } catch (e) {
      throw Exception('Error saving certificate: $e');
    }
  }

  /// Retrieve a saved certificate as a temporary file
  /// The file will be created in the app's temporary directory
  Future<File> getCertificateFile(String certificateId) async {
    try {
      final certificateBase64 = await _storage.read(
        key: '$_certificatePrefix$certificateId',
      );
      
      if (certificateBase64 == null) {
        throw Exception('Certificate not found');
      }
      
      // Decode from base64
      final certificateBytes = base64Decode(certificateBase64);
      
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cert_$certificateId.p12');
      
      await tempFile.writeAsBytes(certificateBytes);
      
      return tempFile;
    } catch (e) {
      throw Exception('Error retrieving certificate: $e');
    }
  }

  /// Get the password for a saved certificate
  Future<String> getCertificatePassword(String certificateId) async {
    try {
      final password = await _storage.read(
        key: '$_passwordPrefix$certificateId',
      );
      
      if (password == null) {
        throw Exception('Password not found for certificate');
      }
      
      return password;
    } catch (e) {
      throw Exception('Error retrieving password: $e');
    }
  }

  /// Get certificate info for a saved certificate
  Future<Map<String, dynamic>> getCertificateInfo(String certificateId) async {
    try {
      final infoJson = await _storage.read(
        key: '$_infoPrefix$certificateId',
      );
      
      if (infoJson == null) {
        throw Exception('Certificate info not found');
      }
      
      return jsonDecode(infoJson) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error retrieving certificate info: $e');
    }
  }

  /// Get list of all saved certificates
  Future<List<SavedCertificate>> getAllSavedCertificates() async {
    try {
      final certificatesListJson = await _storage.read(
        key: _certificatesListKey,
      );
      
      if (certificatesListJson == null) {
        return [];
      }
      
      final List<dynamic> certificateIds = jsonDecode(certificatesListJson);
      
      final List<SavedCertificate> certificates = [];
      
      for (final id in certificateIds) {
        try {
          final info = await getCertificateInfo(id as String);
          certificates.add(SavedCertificate(
            id: id,
            customName: info['customName'] as String? ?? '',
            subject: info['subject'] as String? ?? '',
            issuer: info['issuer'] as String? ?? '',
            validTo: DateTime.parse(info['validTo'] as String),
            savedAt: DateTime.parse(info['savedAt'] as String),
            thumbprint: info['thumbprint'] as String? ?? '',
            isValid: info['isValid'] as bool? ?? true,
          ));
        } catch (e) {
          // Skip certificates that can't be loaded
          debugPrint('Error loading certificate $id: $e');
        }
      }
      
      // Sort by saved date (newest first)
      certificates.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      
      return certificates;
    } catch (e) {
      throw Exception('Error retrieving certificates list: $e');
    }
  }

  /// Delete a saved certificate
  Future<void> deleteCertificate(String certificateId) async {
    try {
      // Delete certificate data
      await _storage.delete(key: '$_certificatePrefix$certificateId');
      
      // Delete password
      await _storage.delete(key: '$_passwordPrefix$certificateId');
      
      // Delete info
      await _storage.delete(key: '$_infoPrefix$certificateId');
      
      // Remove from list
      await _removeFromCertificatesList(certificateId);
    } catch (e) {
      throw Exception('Error deleting certificate: $e');
    }
  }

  /// Update custom name for a certificate
  Future<void> updateCertificateName(
    String certificateId,
    String newName,
  ) async {
    try {
      final info = await getCertificateInfo(certificateId);
      info['customName'] = newName;
      
      await _storage.write(
        key: '$_infoPrefix$certificateId',
        value: jsonEncode(info),
      );
    } catch (e) {
      throw Exception('Error updating certificate name: $e');
    }
  }

  /// Add certificate ID to the list
  Future<void> _addToCertificatesList(String certificateId) async {
    final currentList = await _getCertificatesList();
    if (!currentList.contains(certificateId)) {
      currentList.add(certificateId);
      await _storage.write(
        key: _certificatesListKey,
        value: jsonEncode(currentList),
      );
    }
  }

  /// Remove certificate ID from the list
  Future<void> _removeFromCertificatesList(String certificateId) async {
    final currentList = await _getCertificatesList();
    currentList.remove(certificateId);
    await _storage.write(
      key: _certificatesListKey,
      value: jsonEncode(currentList),
    );
  }

  /// Get current certificates list
  Future<List<String>> _getCertificatesList() async {
    final listJson = await _storage.read(key: _certificatesListKey);
    if (listJson == null) {
      return [];
    }
    return List<String>.from(jsonDecode(listJson));
  }
}

/// Model for saved certificate information
class SavedCertificate {
  final String id;
  final String customName;
  final String subject;
  final String issuer;
  final DateTime validTo;
  final DateTime savedAt;
  final String thumbprint;
  final bool isValid;

  SavedCertificate({
    required this.id,
    required this.customName,
    required this.subject,
    required this.issuer,
    required this.validTo,
    required this.savedAt,
    required this.thumbprint,
    required this.isValid,
  });

  bool get isExpired => validTo.isBefore(DateTime.now());
  
  String get displayName => customName.isNotEmpty ? customName : subject;
}

