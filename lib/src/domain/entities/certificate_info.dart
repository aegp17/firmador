import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_info.freezed.dart';

@freezed
class CertificateInfo with _$CertificateInfo {
  const factory CertificateInfo({
    required String subject, // Who the certificate belongs to
    required String issuer, // Who issued the certificate
    required DateTime validFrom,
    required DateTime validTo,
    @Default(false) bool isTrusted,
  }) = _CertificateInfo;

  factory CertificateInfo.fromMap(Map<dynamic, dynamic> map) {
    return CertificateInfo(
      subject: map['subject'] as String? ?? 'Desconocido',
      issuer: map['issuer'] as String? ?? 'Desconocido',
      validFrom: DateTime.fromMillisecondsSinceEpoch(map['validFrom'] as int? ?? 0),
      validTo: DateTime.fromMillisecondsSinceEpoch(map['validTo'] as int? ?? 0),
      isTrusted: map['isTrusted'] as bool? ?? false,
    );
  }
} 