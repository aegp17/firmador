import 'package:firmador/src/data/repositories/platform_crypto_repository.dart';
import 'package:firmador/src/domain/repositories/crypto_repository.dart';
import 'package:firmador/src/domain/usecases/load_certificate_usecase.dart';
import 'package:firmador/src/domain/usecases/sign_pdf_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Repository Provider
// For the MVP, we directly provide the Fake implementation.
// In the future, this could be decided by environment.
final cryptoRepositoryProvider = Provider<CryptoRepository>((ref) {
  return PlatformCryptoRepository();
});

// 2. Use Case Providers
// These providers depend on the repository provider.

final loadCertificateUseCaseProvider = Provider<LoadCertificateUseCase>((ref) {
  final cryptoRepository = ref.watch(cryptoRepositoryProvider);
  return LoadCertificateUseCase(cryptoRepository);
});

final signPdfUseCaseProvider = Provider<SignPdfUseCase>((ref) {
  final cryptoRepository = ref.watch(cryptoRepositoryProvider);
  return SignPdfUseCase(cryptoRepository);
}); 