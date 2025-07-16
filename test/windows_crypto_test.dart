import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firmador/src/data/repositories/windows_crypto_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowsCryptoRepository Tests', () {
    late WindowsCryptoRepository repository;
    const MethodChannel channel = MethodChannel('com.example.firmador/native_crypto');

    setUp(() {
      repository = WindowsCryptoRepository();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getCertificateInfo should return certificate info', () async {
      // Mock method call response
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getCertificateInfo') {
          return {
            'subject': 'Test Subject',
            'issuer': 'Test Issuer',
            'validFrom': '2023-01-01 00:00:00',
            'validTo': '2024-12-31 23:59:59',
            'serialNumber': '123456789',
            'thumbprint': 'abc123def456',
            'isValid': true,
            'keyUsage': ['Digital Signature', 'Non Repudiation'],
          };
        }
        return null;
      });

      final result = await repository.getCertificateInfo(
        p12Path: '/path/to/cert.p12',
        password: 'password123',
      );

      expect(result.subject, 'Test Subject');
      expect(result.thumbprint, 'abc123def456');
      expect(result.isValid, true);
      expect(result.keyUsage, ['Digital Signature', 'Non Repudiation']);
    });

    test('getAvailableCertificates should return certificate list', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAvailableCertificates') {
          return [
            {
              'subject': 'Certificate 1',
              'issuer': 'Issuer 1',
              'validFrom': '2023-01-01 00:00:00',
              'validTo': '2024-12-31 23:59:59',
              'serialNumber': '111',
              'thumbprint': 'thumb1',
              'isValid': true,
              'keyUsage': ['Digital Signature'],
            },
            {
              'subject': 'Certificate 2',
              'issuer': 'Issuer 2',
              'validFrom': '2023-01-01 00:00:00',
              'validTo': '2024-12-31 23:59:59',
              'serialNumber': '222',
              'thumbprint': 'thumb2',
              'isValid': true,
              'keyUsage': ['Key Encipherment'],
            },
          ];
        }
        return null;
      });

      final certificates = await repository.getAvailableCertificates();

      expect(certificates.length, 2);
      expect(certificates[0].subject, 'Certificate 1');
      expect(certificates[1].subject, 'Certificate 2');
    });

    test('signPdf should sign PDF successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'signPdf') {
          return {
            'success': true,
            'signedPdfPath': '/path/to/signed.pdf',
            'timestampServer': 'FreeTSA',
            'signingTime': '2023-12-01 12:00:00',
            'originalSize': 1024,
            'signedSize': 1500,
          };
        }
        return null;
      });

      final result = await repository.signPdf(
        pdfPath: '/path/to/document.pdf',
        p12Path: '/path/to/cert.p12',
        password: 'password123',
        page: 1,
        x: 100.0,
        y: 200.0,
      );

      expect(result.path, '/path/to/signed.pdf');
    });

    test('signPdfWithOptions should sign PDF with custom options', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'signPdf') {
          return {
            'success': true,
            'signedPdfPath': '/path/to/signed.pdf',
            'timestampServer': 'FreeTSA',
            'signingTime': '2023-12-01 12:00:00',
            'originalSize': 1024,
            'signedSize': 1500,
          };
        }
        return null;
      });

      final result = await repository.signPdfWithOptions(
        pdfPath: '/path/to/document.pdf',
        outputPath: '/path/to/signed.pdf',
        certificatePath: '/path/to/cert.p12',
        password: 'password123',
        position: {
          'x': 100.0,
          'y': 200.0,
          'pageNumber': 1,
          'width': 200.0,
          'height': 50.0,
        },
        includeTimestamp: true,
      );

      expect(result, '/path/to/signed.pdf');
    });

    test('testTSAConnectivity should return TSA server status', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'testTSAConnectivity') {
          return {
            'servers': [
              {
                'name': 'FreeTSA',
                'url': 'https://freetsa.org/tsr',
                'available': true,
                'requiresAuth': false,
              },
              {
                'name': 'DigiCert',
                'url': 'http://timestamp.digicert.com',
                'available': false,
                'requiresAuth': false,
              },
            ],
            'totalServers': 2,
            'availableServers': 1,
          };
        }
        return null;
      });

      final result = await repository.testTSAConnectivity();

      expect(result.length, 2);
      expect(result[0]['name'], 'FreeTSA');
      expect(result[0]['available'], true);
      expect(result[1]['available'], false);
    });

    test('validatePdf should validate PDF format', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'validatePdf') {
          return {
            'isValid': true,
            'pageCount': 3,
            'pageDimensions': {
              'width': 612.0,
              'height': 792.0,
            },
          };
        }
        return null;
      });

      final result = await repository.validatePdf('/path/to/document.pdf');

      expect(result, true);
    });

    test('loadCertificate with thumbprint should return certificate info', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getCertificateInfo') {
          return {
            'subject': 'Store Certificate',
            'issuer': 'Store Issuer',
            'validFrom': '2023-01-01 00:00:00',
            'validTo': '2024-12-31 23:59:59',
            'serialNumber': '987654321',
            'thumbprint': 'store123thumb456',
            'isValid': true,
            'keyUsage': ['Digital Signature', 'Key Encipherment'],
          };
        }
        return null;
      });

      final result = await repository.loadCertificate(
        thumbprint: 'store123thumb456',
      );

      expect(result, isNotNull);
      expect(result!.subject, 'Store Certificate');
      expect(result.thumbprint, 'store123thumb456');
      expect(result.keyUsage, ['Digital Signature', 'Key Encipherment']);
    });

    test('loadCertificate should handle errors gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'CERT_NOT_FOUND', message: 'Certificate not found');
      });

      final result = await repository.loadCertificate(
        thumbprint: 'nonexistent',
      );

      expect(result, isNull);
    });

    test('signPdfWithOptions should handle errors gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'SIGNING_FAILED', message: 'Signing failed');
      });

      final result = await repository.signPdfWithOptions(
        pdfPath: '/path/to/document.pdf',
        outputPath: '/path/to/signed.pdf',
        thumbprint: 'invalid_thumbprint',
      );

      expect(result, isNull);
    });
  });
} 