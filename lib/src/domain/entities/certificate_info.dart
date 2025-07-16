import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_info.freezed.dart';

@freezed
class CertificateInfo with _$CertificateInfo {
  const factory CertificateInfo({
    required String subject, // Who the certificate belongs to
    required String issuer, // Who issued the certificate
    required DateTime validFrom,
    required DateTime validTo,
    @Default('') String serialNumber, // Certificate serial number
    @Default('') String commonName, // Common name extracted from subject
    @Default([]) List<String> keyUsages, // Key usage and extended key usage
    @Default([]) List<String> keyUsage, // Alternative key usage field for Windows compatibility
    @Default('') String thumbprint, // Certificate thumbprint (SHA1 hash)
    @Default(false) bool isTrusted,
    @Default(true) bool isValid, // Whether the certificate is valid
  }) = _CertificateInfo;

  factory CertificateInfo.fromMap(Map<dynamic, dynamic> map) {
    return CertificateInfo(
      subject: map['subject'] as String? ?? 'Desconocido',
      issuer: map['issuer'] as String? ?? 'Desconocido',
      validFrom: DateTime.fromMillisecondsSinceEpoch(map['validFrom'] as int? ?? 0),
      validTo: DateTime.fromMillisecondsSinceEpoch(map['validTo'] as int? ?? 0),
      serialNumber: map['serialNumber'] as String? ?? '',
      commonName: map['commonName'] as String? ?? '',
      keyUsages: (map['keyUsages'] as List<dynamic>?)?.cast<String>() ?? [],
      keyUsage: (map['keyUsage'] as List<dynamic>?)?.cast<String>() ?? [],
      thumbprint: map['thumbprint'] as String? ?? '',
      isTrusted: map['isTrusted'] as bool? ?? false,
      isValid: map['isValid'] as bool? ?? true,
    );
  }

  // JSON compatibility for Windows native calls
  factory CertificateInfo.fromJson(Map<String, dynamic> json) {
    return CertificateInfo(
      subject: json['subject'] as String? ?? 'Unknown',
      issuer: json['issuer'] as String? ?? 'Unknown',
      validFrom: _parseDateTime(json['validFrom']),
      validTo: _parseDateTime(json['validTo']),
      serialNumber: json['serialNumber'] as String? ?? '',
      commonName: json['commonName'] as String? ?? '',
      keyUsages: (json['keyUsages'] as List<dynamic>?)?.cast<String>() ?? [],
      keyUsage: (json['keyUsage'] as List<dynamic>?)?.cast<String>() ?? [],
      thumbprint: json['thumbprint'] as String? ?? '',
      isTrusted: json['isTrusted'] as bool? ?? false,
      isValid: json['isValid'] as bool? ?? true,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
} 