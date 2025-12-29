import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firmador/src/data/services/secure_certificate_storage_service.dart';

final secureCertificateStorageServiceProvider =
    Provider<SecureCertificateStorageService>((ref) {
  return SecureCertificateStorageService();
});

final savedCertificatesProvider =
    StateNotifierProvider<SavedCertificatesNotifier, AsyncValue<List<SavedCertificate>>>(
  (ref) {
    final service = ref.watch(secureCertificateStorageServiceProvider);
    return SavedCertificatesNotifier(service);
  },
);

class SavedCertificatesNotifier
    extends StateNotifier<AsyncValue<List<SavedCertificate>>> {
  final SecureCertificateStorageService _service;

  SavedCertificatesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadCertificates();
  }

  Future<void> loadCertificates() async {
    state = const AsyncValue.loading();
    try {
      final certificates = await _service.getAllSavedCertificates();
      state = AsyncValue.data(certificates);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<String> saveCertificate({
    required String certificatePath,
    required String password,
    required String certificateInfoJson,
    String? customName,
  }) async {
    try {
      // This will need to be implemented with actual file and certificate info
      // For now, returning a placeholder
      throw UnimplementedError('Save certificate implementation needed');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteCertificate(String certificateId) async {
    try {
      await _service.deleteCertificate(certificateId);
      await loadCertificates();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await loadCertificates();
  }
}

