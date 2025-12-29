import 'package:file_picker/file_picker.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';
import 'package:firmador/src/domain/usecases/load_certificate_usecase.dart';
import 'package:firmador/src/presentation/providers/repository_providers.dart';
import 'package:firmador/src/presentation/screens/pdf_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
// Conditional import for File - use stub on web, real File on native
import 'dart:io' if (dart.library.html) 'package:firmador/src/presentation/providers/file_stub.dart' show File;

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
      if (kIsWeb) {
        // On web, use bytes directly
        if (file.bytes == null) {
          throw Exception('No se pudieron leer los bytes del archivo');
        }
        
        // For web, we need to save to a temporary location
        // Since we can't use File in web, we'll return a data URL or handle differently
        // For now, we'll use the bytes directly in the use case
        // This is a workaround - in a real app you might want to use IndexedDB
        final sanitizedName = file.name.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
        // Return a placeholder path that the use case can handle
        return 'web://$sanitizedName';
      } else {
        // On native platforms, use file path
        if (file.path == null) {
          throw Exception('Ruta del archivo no disponible');
        }
        
        // Use conditional import - File is available from dart:io on native
        // ignore: undefined_class
        final sourceFile = File(file.path!);
        
        final appDir = await getApplicationDocumentsDirectory();
        final sanitizedName = file.name.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
        final newPath = '${appDir.path}/$sanitizedName';
        
        // Verify source file exists and is readable
        if (!await sourceFile.exists()) {
          throw Exception('El archivo seleccionado no existe o no es accesible');
        }
        
        // ignore: undefined_class
        final newFile = File(newPath);
        
        // Copy file safely
        await sourceFile.copy(newPath);
        
        // Verify copy was successful
        if (!await newFile.exists()) {
          throw Exception('Error al copiar el archivo');
        }
        
        return newPath;
      }
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
        allowedExtensions: ['p12', 'pfx'],
        allowMultiple: false,
        // On web, we need to load file data
        withData: kIsWeb,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        
        // Validate file extension
        final fileName = file.name.toLowerCase();
        if (!fileName.endsWith('.p12') && !fileName.endsWith('.pfx')) {
          state = state.copyWith(error: 'Error: Por favor selecciona un archivo .p12 o .pfx válido.');
          return;
        }
        
        // On web, path will be null but bytes should be available
        // On native platforms, path should be available
        if (!kIsWeb && file.path == null) {
          state = state.copyWith(error: 'Error: No se pudo acceder al archivo seleccionado.');
          return;
        }
        
        if (kIsWeb && file.bytes == null) {
          state = state.copyWith(error: 'Error: No se pudieron leer los bytes del archivo.');
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
      String p12Path;
      
      if (kIsWeb) {
        // On web, we need to handle bytes differently
        // For now, we'll need to pass bytes to the use case or save to a temporary location
        // This is a limitation - we may need to modify the use case to accept bytes
        if (state.file!.bytes == null) {
          throw Exception('No se pudieron leer los bytes del archivo');
        }
        
        // Save bytes to a temporary file that can be accessed
        // In a real implementation, you might want to use IndexedDB or modify the use case
        final sanitizedName = state.file!.name.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
        p12Path = 'web://$sanitizedName'; // Placeholder - needs proper handling
      } else {
        p12Path = await copyP12ToAppDir(state.file!);
      }
      
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