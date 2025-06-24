import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firmador/src/domain/usecases/sign_pdf_usecase.dart';
import 'package:firmador/src/presentation/providers/certificate_provider.dart';
import 'package:firmador/src/presentation/providers/repository_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_provider.freezed.dart';

class SignaturePosition {
  final int page;
  final Offset position;
  const SignaturePosition({required this.page, required this.position});
}

@freezed
class PdfState with _$PdfState {
  const factory PdfState({
    File? pdfFile,
    File? signedPdfFile,
    @Default(0) int pageCount,
    @Default(0) int currentPage,
    PDFViewController? controller,
    SignaturePosition? signaturePosition,
    @Default(false) bool isSigning,
    @Default(false) bool isLoading,
    String? error,
  }) = _PdfState;
}

class PdfNotifier extends StateNotifier<PdfState> {
  final SignPdfUseCase _signPdfUseCase;
  final Function _read;

  PdfNotifier(this._signPdfUseCase, this._read) : super(const PdfState());

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      state = state.copyWith(
        pdfFile: File(result.files.single.path!),
        isLoading: true,
        error: null,
      );
    }
  }

  void onPdfRender(int? pages) {
    state = state.copyWith(pageCount: pages ?? 0, isLoading: false);
  }

  void onPageChanged(int? page, int? total) {
    state = state.copyWith(
      currentPage: page ?? 0,
      pageCount: total ?? 0,
    );
  }

  void onPdfError(dynamic error) {
    state = state.copyWith(
      error: 'Error al cargar el PDF: $error',
      isLoading: false,
    );
  }

  void setController(PDFViewController controller) {
    state = state.copyWith(controller: controller);
  }

  void setSignaturePosition(Offset position) {
    state = state.copyWith(
      signaturePosition: SignaturePosition(
        page: state.currentPage,
        position: position,
      ),
    );
  }

  void clearSignaturePosition() {
    state = state.copyWith(signaturePosition: null);
  }

  Future<void> signPdf() async {
    final certState = _read(certificateUploadProvider);
    if (state.pdfFile == null ||
        state.signaturePosition == null ||
        certState.file == null ||
        certState.password.isEmpty) {
      state = state.copyWith(error: 'Faltan datos para la firma.');
      return;
    }

    state = state.copyWith(isSigning: true, error: null);

    try {
      final signedFile = await _signPdfUseCase(
        pdfPath: state.pdfFile!.path,
        p12Path: certState.file!.path!,
        password: certState.password,
        page: state.signaturePosition!.page,
        x: state.signaturePosition!.position.dx,
        y: state.signaturePosition!.position.dy,
      );
      state = state.copyWith(isSigning: false, signedPdfFile: signedFile);
    } catch (e) {
      state = state.copyWith(isSigning: false, error: e.toString());
    }
  }
}

final pdfProvider = StateNotifierProvider<PdfNotifier, PdfState>(
  (ref) {
    final useCase = ref.watch(signPdfUseCaseProvider);
    return PdfNotifier(useCase, ref.read);
  },
); 