import 'dart:io';
import 'package:firmador/src/data/repositories/platform_crypto_repository.dart';
import 'package:firmador/src/data/repositories/windows_crypto_repository.dart';
import 'package:firmador/src/data/repositories/windows_hybrid_signature_service.dart';
import 'package:firmador/src/domain/repositories/crypto_repository.dart';
import 'package:firmador/src/domain/usecases/load_certificate_usecase.dart';
import 'package:firmador/src/domain/usecases/sign_pdf_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Repository Provider
// Platform-specific repository selection
final cryptoRepositoryProvider = Provider<CryptoRepository>((ref) {
  if (Platform.isWindows) {
    return WindowsCryptoRepository();
  } else {
    return PlatformCryptoRepository();
  }
});

// 2. Windows Hybrid Signature Service Provider
final windowsHybridSignatureServiceProvider = Provider<WindowsHybridSignatureService>((ref) {
  return WindowsHybridSignatureService();
});

// 3. Use Case Providers
// These providers depend on the repository provider.

final loadCertificateUseCaseProvider = Provider<LoadCertificateUseCase>((ref) {
  final cryptoRepository = ref.watch(cryptoRepositoryProvider);
  return LoadCertificateUseCase(cryptoRepository);
});

final signPdfUseCaseProvider = Provider<SignPdfUseCase>((ref) {
  final cryptoRepository = ref.watch(cryptoRepositoryProvider);
  return SignPdfUseCase(cryptoRepository);
}); 