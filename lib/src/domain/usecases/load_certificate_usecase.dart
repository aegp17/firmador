import 'package:firmador/src/domain/entities/certificate_info.dart';
import 'package:firmador/src/domain/repositories/crypto_repository.dart';

// Este usecase ya está adaptado para la integración nativa iOS/Flutter

class LoadCertificateUseCase {
  final CryptoRepository _cryptoRepository;

  LoadCertificateUseCase(this._cryptoRepository);

  Future<CertificateInfo> call({
    required String p12Path,
    required String password,
  }) {
    return _cryptoRepository.getCertificateInfo(
      p12Path: p12Path,
      password: password,
    );
  }
} 