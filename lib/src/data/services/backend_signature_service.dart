import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';

class BackendSignatureService {
  static const String _baseUrl = 'http://localhost:8080'; // Change for production
  late final Dio _dio;

  BackendSignatureService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5), // Longer timeout for signing
      sendTimeout: const Duration(minutes: 2),
    ));

    // Add request/response interceptors for logging in debug mode
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 REQUEST: ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ ERROR: ${error.response?.statusCode} ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Sign a document using the backend service
  Future<SignatureResult> signDocument({
    required File documentFile,
    required File certificateFile,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    required String certificatePassword,
    int signatureX = 100,
    int signatureY = 100,
    int signatureWidth = 200,
    int signatureHeight = 80,
    int signaturePage = 1,
  }) async {
    try {
      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
          contentType: DioMediaType.parse('application/pdf'),
        ),
        'certificate': await MultipartFile.fromFile(
          certificateFile.path,
          filename: certificateFile.path.split('/').last,
          contentType: DioMediaType.parse('application/x-pkcs12'),
        ),
        'signerName': signerName,
        'signerId': signerId,
        'location': location,
        'reason': reason,
        'password': certificatePassword,
        'signatureX': signatureX,
        'signatureY': signatureY,
        'signatureWidth': signatureWidth,
        'signatureHeight': signatureHeight,
        'signaturePage': signaturePage,
      });

      // Send request
      final response = await _dio.post(
        '/api/signature/sign',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return SignatureResult(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Documento firmado exitosamente',
          documentId: data['documentId'],
          filename: data['filename'],
          downloadUrl: data['downloadUrl'],
          signedAt: data['signedAt'] != null 
              ? DateTime.parse(data['signedAt']) 
              : DateTime.now(),
          fileSize: data['fileSize'] ?? 0,
        );
      } else {
        return SignatureResult(
          success: false,
          message: 'Error del servidor: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return SignatureResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return SignatureResult(
        success: false,
        message: 'Error inesperado: $e',
      );
    }
  }

  /// Validate a certificate using the backend service
  Future<CertificateValidationResult> validateCertificate({
    required File certificateFile,
    required String password,
  }) async {
    try {
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(
          certificateFile.path,
          filename: certificateFile.path.split('/').last,
          contentType: DioMediaType.parse('application/x-pkcs12'),
        ),
        'password': password,
      });

      final response = await _dio.post(
        '/api/signature/validate-certificate',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return CertificateValidationResult(
          valid: data['valid'] ?? false,
          message: data['message'] ?? 'Validación completada',
        );
      } else {
        return CertificateValidationResult(
          valid: false,
          message: 'Error del servidor: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return CertificateValidationResult(
        valid: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return CertificateValidationResult(
        valid: false,
        message: 'Error inesperado: $e',
      );
    }
  }

  /// Get certificate information using the backend service
  Future<CertificateInfoResult> getCertificateInfo({
    required File certificateFile,
    required String password,
  }) async {
    try {
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(
          certificateFile.path,
          filename: certificateFile.path.split('/').last,
          contentType: DioMediaType.parse('application/x-pkcs12'),
        ),
        'password': password,
      });

      final response = await _dio.post(
        '/api/signature/certificate-info',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true && data['certificateInfo'] != null) {
          final certData = data['certificateInfo'];
          
          final certificateInfo = CertificateInfo(
            subject: certData['subject'] ?? 'Desconocido',
            issuer: certData['issuer'] ?? 'Desconocido',
            validFrom: certData['validFrom'] != null 
                ? DateTime.parse(certData['validFrom'])
                : DateTime.now(),
            validTo: certData['validTo'] != null 
                ? DateTime.parse(certData['validTo'])
                : DateTime.now(),
            serialNumber: certData['serialNumber'] ?? '',
            commonName: certData['commonName'] ?? '',
            keyUsages: List<String>.from(certData['keyUsages'] ?? []),
            isTrusted: certData['trusted'] ?? false,
          );

          return CertificateInfoResult(
            success: true,
            message: data['message'] ?? 'Información extraída exitosamente',
            certificateInfo: certificateInfo,
          );
        } else {
          return CertificateInfoResult(
            success: false,
            message: data['message'] ?? 'Error al extraer información',
          );
        }
      } else {
        return CertificateInfoResult(
          success: false,
          message: 'Error del servidor: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return CertificateInfoResult(
        success: false,
        message: _handleDioError(e),
      );
    } catch (e) {
      return CertificateInfoResult(
        success: false,
        message: 'Error inesperado: $e',
      );
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/signature/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de conexión agotado. Verifica tu conexión a internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message;
        return 'Error del servidor ($statusCode): $message';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica que el servidor esté funcionando.';
      case DioExceptionType.cancel:
        return 'Operación cancelada';
      default:
        return 'Error de red: ${e.message}';
    }
  }
}

// Result classes for better type safety
class SignatureResult {
  final bool success;
  final String message;
  final String? documentId;
  final String? filename;
  final String? downloadUrl;
  final DateTime? signedAt;
  final int? fileSize;

  SignatureResult({
    required this.success,
    required this.message,
    this.documentId,
    this.filename,
    this.downloadUrl,
    this.signedAt,
    this.fileSize,
  });
}

class CertificateValidationResult {
  final bool valid;
  final String message;

  CertificateValidationResult({
    required this.valid,
    required this.message,
  });
}

class CertificateInfoResult {
  final bool success;
  final String message;
  final CertificateInfo? certificateInfo;

  CertificateInfoResult({
    required this.success,
    required this.message,
    this.certificateInfo,
  });
} 