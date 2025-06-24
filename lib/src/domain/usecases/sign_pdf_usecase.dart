import 'dart:io';
import 'package:firmador/src/domain/repositories/crypto_repository.dart';

class SignPdfUseCase {
  final CryptoRepository _cryptoRepository;

  SignPdfUseCase(this._cryptoRepository);

  Future<File> call({
    required String pdfPath,
    required String p12Path,
    required String password,
    required int page,
    required double x,
    required double y,
  }) {
    return _cryptoRepository.signPdf(
      pdfPath: pdfPath,
      p12Path: p12Path,
      password: password,
      page: page,
      x: x,
      y: y,
    );
  }
} 