import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:firmador/src/data/repositories/windows_crypto_repository.dart';
import 'package:firmador/src/data/repositories/windows_hybrid_signature_service.dart';
import 'package:firmador/src/domain/entities/certificate_info.dart';

void main() {
  group('Windows Crypto Tests', () {
    late WindowsCryptoRepository repository;
    late WindowsHybridSignatureService hybridService;

    setUp(() {
      repository = WindowsCryptoRepository();
      hybridService = WindowsHybridSignatureService();
    });

    group('WindowsCryptoRepository', () {
      testWidgets('should handle method channel calls', (WidgetTester tester) async {
        // Mock method channel
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        // Mock successful certificate info response
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'getCertificateInfo') {
            return {
              'subject': 'CN=Test Certificate',
              'issuer': 'CN=Test CA',
              'serialNumber': '123456789',
              'validFrom': '2024-01-01',
              'validTo': '2025-01-01',
              'thumbprint': 'ABCDEF123456789',
              'isValid': true,
              'keyUsage': ['Digital Signature', 'Non Repudiation'],
            };
          }
          return null;
        });

        final result = await repository.loadCertificate(
          certificatePath: 'test.p12',
          password: 'test123',
        );

        expect(result, isNotNull);
        expect(result!.subject, equals('CN=Test Certificate'));
        expect(result.isValid, isTrue);
        expect(result.keyUsage, contains('Digital Signature'));
      });

      testWidgets('should handle getAvailableCertificates', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'getAvailableCertificates') {
            return [
              {
                'subject': 'CN=Certificate 1',
                'issuer': 'CN=CA 1',
                'serialNumber': '111',
                'validFrom': '2024-01-01',
                'validTo': '2025-01-01',
                'thumbprint': 'THUMB1',
                'isValid': true,
                'keyUsage': ['Digital Signature'],
              },
              {
                'subject': 'CN=Certificate 2',
                'issuer': 'CN=CA 2',
                'serialNumber': '222',
                'validFrom': '2024-01-01',
                'validTo': '2025-01-01',
                'thumbprint': 'THUMB2',
                'isValid': true,
                'keyUsage': ['Non Repudiation'],
              },
            ];
          }
          return null;
        });

        final certificates = await repository.getAvailableCertificates();

        expect(certificates, hasLength(2));
        expect(certificates[0].subject, equals('CN=Certificate 1'));
        expect(certificates[1].subject, equals('CN=Certificate 2'));
      });

      testWidgets('should handle PDF signing', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'signPdf') {
            final args = methodCall.arguments as Map<String, dynamic>;
            expect(args['pdfPath'], isNotNull);
            expect(args['outputPath'], isNotNull);
            expect(args['includeTimestamp'], isTrue);
            
            return {
              'success': true,
              'signedPdfPath': args['outputPath'],
              'timestampServer': 'FreeTSA',
              'signingTime': '20240101120000',
              'originalSize': 1024,
              'signedSize': 1200,
            };
          }
          return null;
        });

        final result = await repository.signPdf(
          pdfPath: '/test/input.pdf',
          outputPath: '/test/output.pdf',
          certificatePath: 'test.p12',
          password: 'test123',
          position: {'x': 100.0, 'y': 200.0, 'pageNumber': 1},
          includeTimestamp: true,
        );

        expect(result, equals('/test/output.pdf'));
      });

      testWidgets('should handle TSA connectivity test', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'testTSAConnectivity') {
            return [
              {
                'name': 'FreeTSA',
                'url': 'https://freetsa.org/tsr',
                'available': true,
              },
              {
                'name': 'DigiCert',
                'url': 'http://timestamp.digicert.com',
                'available': false,
              },
            ];
          }
          return null;
        });

        final servers = await repository.testTSAConnectivity();

        expect(servers, hasLength(2));
        expect(servers[0]['name'], equals('FreeTSA'));
        expect(servers[0]['available'], isTrue);
        expect(servers[1]['available'], isFalse);
      });
    });

    group('WindowsHybridSignatureService', () {
      testWidgets('should test local capabilities', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getAvailableCertificates':
              return [
                {
                  'subject': 'CN=Test Cert',
                  'issuer': 'CN=Test CA',
                  'serialNumber': '123',
                  'validFrom': '2024-01-01',
                  'validTo': '2025-01-01',
                  'thumbprint': 'THUMB',
                  'isValid': true,
                  'keyUsage': ['Digital Signature'],
                }
              ];
            case 'testTSAConnectivity':
              return [
                {'name': 'FreeTSA', 'url': 'https://freetsa.org/tsr', 'available': true},
                {'name': 'DigiCert', 'url': 'http://timestamp.digicert.com', 'available': true},
              ];
            default:
              return null;
          }
        });

        final capabilities = await hybridService.testLocalCapabilities();

        expect(capabilities['available'], isTrue);
        expect(capabilities['certificateCount'], equals(1));
        expect(capabilities['tsaServers'], equals(2));
      });

      testWidgets('should handle local capabilities error', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'NATIVE_ERROR',
            message: 'Windows crypto not available',
          );
        });

        final capabilities = await hybridService.testLocalCapabilities();

        expect(capabilities['available'], isFalse);
        expect(capabilities['error'], contains('Windows crypto not available'));
      });
    });

    group('Certificate Store Integration', () {
      testWidgets('should load certificate from Windows Certificate Store', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'getCertificateInfo') {
            final args = methodCall.arguments as Map<String, dynamic>;
            expect(args['thumbprint'], isNotNull);
            
            return {
              'subject': 'CN=Corporate Certificate',
              'issuer': 'CN=Corporate CA',
              'serialNumber': 'CORP123',
              'validFrom': '2024-01-01',
              'validTo': '2025-01-01',
              'thumbprint': args['thumbprint'],
              'isValid': true,
              'keyUsage': ['Digital Signature', 'Key Encipherment'],
            };
          }
          return null;
        });

        final result = await repository.loadCertificate(
          thumbprint: 'ABCDEF123456789',
        );

        expect(result, isNotNull);
        expect(result!.subject, equals('CN=Corporate Certificate'));
        expect(result.thumbprint, equals('ABCDEF123456789'));
        expect(result.keyUsage, contains('Key Encipherment'));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle native errors gracefully', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'CERTIFICATE_LOAD_FAILED',
            message: 'Certificate not found in store',
          );
        });

        final result = await repository.loadCertificate(
          thumbprint: 'INVALID_THUMBPRINT',
        );

        expect(result, isNull);
      });

      testWidgets('should handle signing errors', (WidgetTester tester) async {
        const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');
        
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'signPdf') {
            throw PlatformException(
              code: 'SIGNING_FAILED',
              message: 'PDF file is password protected',
            );
          }
          return null;
        });

        final result = await repository.signPdf(
          pdfPath: '/test/protected.pdf',
          outputPath: '/test/output.pdf',
          thumbprint: 'VALID_THUMBPRINT',
        );

        expect(result, isNull);
      });
    });
  });
} 