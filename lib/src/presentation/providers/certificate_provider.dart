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
    try {
      if (file.path == null) {
        throw Exception('Ruta del archivo no disponible');
      }
      
      final appDir = await getApplicationDocumentsDirectory();
      final sanitizedName = file.name.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      final newPath = '${appDir.path}/$sanitizedName';
      final sourceFile = File(file.path!);
      
      // Verify source file exists and is readable
      if (!await sourceFile.exists()) {
        throw Exception('El archivo seleccionado no existe o no es accesible');
      }
      
      final newFile = File(newPath);
      
      // Copy file safely
      await sourceFile.copy(newPath);
      
      // Verify copy was successful
      if (!await newFile.exists()) {
        throw Exception('Error al copiar el archivo');
      }
      
      return newPath;
    } catch (e) {
      throw Exception('Error al procesar archivo: ${e.toString()}');
    }
  }

  Future<void> pickFile() async {
    try {
      // Clear any previous errors
      state = state.copyWith(error: null);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12'],
        allowMultiple: false,
        withData: false, // Important: don't load file data immediately
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        
        // Validate file
        if (file.path == null) {
          state = state.copyWith(error: 'Error: No se pudo acceder al archivo seleccionado.');
          return;
        }
        
        if (!file.name.toLowerCase().endsWith('.p12')) {
          state = state.copyWith(error: 'Error: Por favor selecciona un archivo .p12 válido.');
          return;
        }
        
        state = state.copyWith(file: file, error: null);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error al seleccionar archivo: ${e.toString()}',
      );
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