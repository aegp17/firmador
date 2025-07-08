import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firmador/src/data/services/backend_signature_service.dart';

// Provider for the BackendSignatureService
final backendSignatureServiceProvider = Provider<BackendSignatureService>((ref) {
  return BackendSignatureService();
});

// Provider for backend health status
final backendHealthProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(backendSignatureServiceProvider);
  return await service.checkHealth();
});

// State provider for tracking signing progress
final signingProgressProvider = StateProvider<double?>((ref) => null);

// State provider for tracking the current signing status
final signingStatusProvider = StateProvider<String?>((ref) => null);

// Provider for the last signature result
final lastSignatureResultProvider = StateProvider<SignatureResult?>((ref) => null);

// Provider for the last certificate validation result
final lastCertificateValidationProvider = StateProvider<CertificateValidationResult?>((ref) => null);

// Provider for the last certificate info result
final lastCertificateInfoProvider = StateProvider<CertificateInfoResult?>((ref) => null); 