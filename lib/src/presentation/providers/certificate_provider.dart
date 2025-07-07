import 'package:file_picker/file_picker.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';
import 'package:firmador/src/domain/usecases/load_certificate_usecase.dart';
import 'package:firmador/src/presentation/providers/repository_providers.dart';
import 'package:firmador/src/presentation/screens/pdf_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'certificate_provider.freezed.dart';

@freezed
class CertificateUploadState with _$CertificateUploadState {
  const factory CertificateUploadState({
    PlatformFile? file,
    @Default('') String password,
    @Default(false) bool isLoading,
    CertificateInfo? certificateInfo,
    String? error,
  }) = _CertificateUploadState;
}

class CertificateUploadNotifier extends StateNotifier<CertificateUploadState> {
  final LoadCertificateUseCase _loadCertificateUseCase;

  CertificateUploadNotifier(this._loadCertificateUseCase)
      : super(const CertificateUploadState());

  Future<String> copyP12ToAppDir(PlatformFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDir.path}/${file.name}';
    final newFile = File(newPath);
    await newFile.writeAsBytes(await File(file.path!).readAsBytes());
    return newPath;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['p12'],
    );

    if (result != null) {
      state = state.copyWith(file: result.files.single, error: null);
    }
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<void> loadCertificate(BuildContext context) async {
    if (state.file == null || state.password.isEmpty) {
      state = state.copyWith(
          error: 'Por favor, selecciona un archivo y escribe la contraseña.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final p12Path = await copyP12ToAppDir(state.file!);
      final cleanPassword = state.password.trim();
      // Loading certificate from copied file
      final certificateInfo = await _loadCertificateUseCase(
        p12Path: p12Path,
        password: cleanPassword,
      );
      state = state.copyWith(isLoading: false, certificateInfo: certificateInfo);
      
      // Check if context is still valid before navigation
      if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PdfSelectionScreen(),
        ),
      );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final certificateUploadProvider =
    StateNotifierProvider<CertificateUploadNotifier, CertificateUploadState>(
  (ref) {
    final useCase = ref.watch(loadCertificateUseCaseProvider);
    return CertificateUploadNotifier(useCase);
  },
);