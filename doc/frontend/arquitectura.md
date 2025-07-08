# Arquitectura del Frontend

## Resumen General
El frontend de Firmador es una aplicación Flutter que implementa la interfaz de usuario para el proceso de firma digital. Utiliza una arquitectura limpia con separación de responsabilidades y gestión de estado reactiva.

## Arquitectura de Capas

### 1. Capa de Presentación (Presentation Layer)
**Ubicación**: `lib/src/presentation/`

#### Pantallas (Screens)
```dart
// lib/src/presentation/screens/

// Pantalla de bienvenida con selección de modo
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Modo servidor para iOS
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/backend-signature'),
            child: Text('Firmar con Servidor'),
          ),
          // Modo local para Android
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/local-signature'),
            child: Text('Firmar Localmente'),
          ),
        ],
      ),
    );
  }
}

// Pantalla principal de firma con backend
class BackendSignatureScreen extends StatefulWidget {
  @override
  _BackendSignatureScreenState createState() => _BackendSignatureScreenState();
}

class _BackendSignatureScreenState extends State<BackendSignatureScreen> {
  // Estado local del formulario
  final _formKey = GlobalKey<FormState>();
  final _signerNameController = TextEditingController();
  final _signerIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();
  
  // Control de archivos
  File? _selectedPdf;
  File? _selectedCertificate;
  String? _certificatePassword;
  
  // Estado de proceso
  bool _isProcessing = false;
  bool _rememberData = false;
  
  // Previsualización y posición
  SignaturePosition? _selectedPosition;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firma Digital')),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildServerStatus(),
            _buildFileSection(),
            _buildFormSection(),
            _buildSignaturePositionSection(),
            _buildRememberDataSection(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}

// Pantalla de previsualización PDF
class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final Function(SignaturePosition?) onPositionSelected;
  
  PdfPreviewScreen({
    required this.pdfFile,
    required this.onPositionSelected,
  });
  
  @override
  _PdfPreviewScreenState createState() => _PdfPreviewScreenState();
}
```

#### Providers (Gestión de Estado)
```dart
// lib/src/presentation/providers/

// Provider para el estado de salud del backend
final backendHealthProvider = FutureProvider<bool>((ref) async {
  final service = BackendSignatureService();
  return await service.checkHealth();
});

// Provider para el estado de firma
final signingStateProvider = StateProvider<SigningState>((ref) {
  return SigningState.initial();
});

// Provider para certificados
final certificateProvider = StateNotifierProvider<CertificateNotifier, CertificateState>((ref) {
  return CertificateNotifier();
});

// Provider para PDFs
final pdfProvider = StateNotifierProvider<PdfNotifier, PdfState>((ref) {
  return PdfNotifier();
});
```

#### Tema (Theme)
```dart
// lib/src/presentation/theme/app_theme.dart

class AppTheme {
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color lightGrey = Color(0xFFF8FAFC);
  static const Color darkGrey = Color(0xFF374151);
  
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        filled: true,
        fillColor: lightGrey,
      ),
    );
  }
}
```

### 2. Capa de Datos (Data Layer)
**Ubicación**: `lib/src/data/`

#### Servicios (Services)
```dart
// lib/src/data/services/

// Servicio de comunicación con backend
class BackendSignatureService {
  late final Dio _dio;
  
  BackendSignatureService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(minutes: 5),
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }
  
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/signature/health');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
  
  Future<SignatureResponse> signDocument({
    required File pdfFile,
    required File certificateFile,
    required String password,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    int? signatureX,
    int? signatureY,
    int? signatureWidth,
    int? signatureHeight,
    int? signaturePage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(pdfFile.path),
        'certificate': await MultipartFile.fromFile(certificateFile.path),
        'password': password,
        'signerName': signerName,
        'signerId': signerId,
        'location': location,
        'reason': reason,
        if (signatureX != null) 'signatureX': signatureX,
        if (signatureY != null) 'signatureY': signatureY,
        if (signatureWidth != null) 'signatureWidth': signatureWidth,
        if (signatureHeight != null) 'signatureHeight': signatureHeight,
        if (signaturePage != null) 'signaturePage': signaturePage,
      });
      
      final response = await _dio.post('/api/signature/sign', data: formData);
      return SignatureResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<bool> validateCertificate({
    required File certificateFile,
    required String password,
  }) async {
    try {
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(certificateFile.path),
        'password': password,
      });
      
      final response = await _dio.post('/api/signature/validate-certificate', data: formData);
      return response.data['valid'] == true;
    } catch (e) {
      print('Certificate validation failed: $e');
      return false;
    }
  }
  
  Future<CertificateInfo> getCertificateInfo({
    required File certificateFile,
    required String password,
  }) async {
    try {
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(certificateFile.path),
        'password': password,
      });
      
      final response = await _dio.post('/api/signature/certificate-info', data: formData);
      return CertificateInfo.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
}

// Servicio de persistencia local
class UserPreferencesService {
  static const String _signerNameKey = 'signer_name';
  static const String _signerIdKey = 'signer_id';
  static const String _locationKey = 'location';
  static const String _reasonKey = 'reason';
  static const String _rememberDataKey = 'remember_data';
  
  static Future<void> saveUserData({
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_signerNameKey, signerName);
    await prefs.setString(_signerIdKey, signerId);
    await prefs.setString(_locationKey, location);
    await prefs.setString(_reasonKey, reason);
    await prefs.setBool(_rememberDataKey, true);
  }
  
  static Future<UserData?> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.getBool(_rememberDataKey, false)) {
      return null;
    }
    
    return UserData(
      signerName: prefs.getString(_signerNameKey) ?? '',
      signerId: prefs.getString(_signerIdKey) ?? '',
      location: prefs.getString(_locationKey) ?? '',
      reason: prefs.getString(_reasonKey) ?? '',
    );
  }
  
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signerNameKey);
    await prefs.remove(_signerIdKey);
    await prefs.remove(_locationKey);
    await prefs.remove(_reasonKey);
    await prefs.setBool(_rememberDataKey, false);
  }
}
```

### 3. Capa de Dominio (Domain Layer)
**Ubicación**: `lib/src/domain/`

#### Entidades (Entities)
```dart
// lib/src/domain/entities/

// Información de certificado
@freezed
class CertificateInfo with _$CertificateInfo {
  const factory CertificateInfo({
    required String subject,
    required String issuer,
    required String serialNumber,
    required String validFrom,
    required String validTo,
    required bool isValid,
    required String keyAlgorithm,
    required String signatureAlgorithm,
  }) = _CertificateInfo;
  
  factory CertificateInfo.fromJson(Map<String, dynamic> json) =>
      _$CertificateInfoFromJson(json);
}

// Posición de firma
class SignaturePosition {
  final double x;
  final double y;
  final int pageNumber;
  
  SignaturePosition({
    required this.x,
    required this.y,
    required this.pageNumber,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'pageNumber': pageNumber,
    };
  }
}

// Respuesta de firma
class SignatureResponse {
  final bool success;
  final String message;
  final String? documentId;
  final String? originalFilename;
  final String? downloadUrl;
  final int? fileSizeBytes;
  
  SignatureResponse({
    required this.success,
    required this.message,
    this.documentId,
    this.originalFilename,
    this.downloadUrl,
    this.fileSizeBytes,
  });
  
  factory SignatureResponse.fromJson(Map<String, dynamic> json) {
    return SignatureResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      documentId: json['documentId'],
      originalFilename: json['originalFilename'],
      downloadUrl: json['downloadUrl'],
      fileSizeBytes: json['fileSizeBytes'],
    );
  }
}

// Datos de usuario
class UserData {
  final String signerName;
  final String signerId;
  final String location;
  final String reason;
  
  UserData({
    required this.signerName,
    required this.signerId,
    required this.location,
    required this.reason,
  });
}
```

#### Repositorios (Repositories)
```dart
// lib/src/domain/repositories/

// Repositorio abstracto para operaciones criptográficas
abstract class CryptoRepository {
  Future<bool> validateCertificate(File certificateFile, String password);
  Future<CertificateInfo> getCertificateInfo(File certificateFile, String password);
  Future<SignatureResponse> signDocument({
    required File pdfFile,
    required File certificateFile,
    required String password,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    SignaturePosition? position,
  });
}

// Implementación para backend
class PlatformCryptoRepository implements CryptoRepository {
  final BackendSignatureService _service;
  
  PlatformCryptoRepository(this._service);
  
  @override
  Future<bool> validateCertificate(File certificateFile, String password) {
    return _service.validateCertificate(
      certificateFile: certificateFile,
      password: password,
    );
  }
  
  @override
  Future<CertificateInfo> getCertificateInfo(File certificateFile, String password) {
    return _service.getCertificateInfo(
      certificateFile: certificateFile,
      password: password,
    );
  }
  
  @override
  Future<SignatureResponse> signDocument({
    required File pdfFile,
    required File certificateFile,
    required String password,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    SignaturePosition? position,
  }) {
    return _service.signDocument(
      pdfFile: pdfFile,
      certificateFile: certificateFile,
      password: password,
      signerName: signerName,
      signerId: signerId,
      location: location,
      reason: reason,
      signatureX: position?.x.toInt(),
      signatureY: position?.y.toInt(),
      signaturePage: position?.pageNumber,
    );
  }
}
```

#### Casos de Uso (Use Cases)
```dart
// lib/src/domain/usecases/

// Caso de uso para cargar certificado
class LoadCertificateUseCase {
  final CryptoRepository _repository;
  
  LoadCertificateUseCase(this._repository);
  
  Future<CertificateInfo> execute(File certificateFile, String password) async {
    // Validar certificado
    final isValid = await _repository.validateCertificate(certificateFile, password);
    if (!isValid) {
      throw Exception('Certificado inválido');
    }
    
    // Obtener información
    return await _repository.getCertificateInfo(certificateFile, password);
  }
}

// Caso de uso para firmar PDF
class SignPdfUseCase {
  final CryptoRepository _repository;
  
  SignPdfUseCase(this._repository);
  
  Future<SignatureResponse> execute({
    required File pdfFile,
    required File certificateFile,
    required String password,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    SignaturePosition? position,
  }) async {
    // Validar archivos
    if (!pdfFile.existsSync()) {
      throw Exception('Archivo PDF no encontrado');
    }
    
    if (!certificateFile.existsSync()) {
      throw Exception('Archivo de certificado no encontrado');
    }
    
    // Validar certificado
    final isValid = await _repository.validateCertificate(certificateFile, password);
    if (!isValid) {
      throw Exception('Certificado inválido');
    }
    
    // Firmar documento
    return await _repository.signDocument(
      pdfFile: pdfFile,
      certificateFile: certificateFile,
      password: password,
      signerName: signerName,
      signerId: signerId,
      location: location,
      reason: reason,
      position: position,
    );
  }
}
```

## Flujo de Navegación

### Estructura de Navegación
```
WelcomeScreen
├── BackendSignatureScreen (iOS/Android)
│   ├── PdfPreviewScreen (previsualización)
│   └── PdfPreviewScreen (selección de posición)
└── LocalSignatureScreen (solo Android)
    ├── CertificateUploadScreen
    └── PdfSelectionScreen
```

### Configuración de Rutas
```dart
// lib/main.dart

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firmador',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/backend-signature': (context) => BackendSignatureScreen(),
        '/local-signature': (context) => LocalSignatureScreen(),
        '/certificate-upload': (context) => CertificateUploadScreen(),
        '/pdf-selection': (context) => PdfSelectionScreen(),
      },
    );
  }
}
```

## Gestión de Estado

### Arquitectura de Estado con Riverpod
```dart
// Estados principales de la aplicación

// Estado de salud del backend
final backendHealthProvider = FutureProvider<bool>((ref) async {
  final service = BackendSignatureService();
  return await service.checkHealth();
});

// Estado de archivos seleccionados
final selectedFilesProvider = StateProvider<SelectedFiles>((ref) {
  return SelectedFiles();
});

// Estado de procesamiento
final processingStateProvider = StateProvider<ProcessingState>((ref) {
  return ProcessingState.idle();
});

// Estado de datos de usuario
final userDataProvider = FutureProvider<UserData?>((ref) async {
  return await UserPreferencesService.loadUserData();
});
```

### Manejo de Errores
```dart
// Manejo centralizado de errores
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Tiempo de conexión agotado. Verifica tu conexión a internet.';
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de respuesta agotado. El servidor puede estar ocupado.';
        case DioExceptionType.badResponse:
          return 'Error del servidor: ${error.response?.statusCode}';
        default:
          return 'Error de conexión. Verifica que el servidor esté disponible.';
      }
    }
    
    return error.toString();
  }
  
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Testing

### Estructura de Tests
```dart
// test/

// Widget tests
test/widget/
├── screens/
│   ├── welcome_screen_test.dart
│   ├── backend_signature_screen_test.dart
│   └── pdf_preview_screen_test.dart
└── components/
    ├── file_picker_widget_test.dart
    └── status_indicator_test.dart

// Unit tests
test/unit/
├── services/
│   ├── backend_signature_service_test.dart
│   └── user_preferences_service_test.dart
├── providers/
│   ├── certificate_provider_test.dart
│   └── signing_state_provider_test.dart
└── usecases/
    ├── load_certificate_usecase_test.dart
    └── sign_pdf_usecase_test.dart

// Integration tests
test/integration/
├── complete_signing_workflow_test.dart
├── file_selection_workflow_test.dart
└── health_monitoring_test.dart
```

## Referencias
- [Flutter Documentation](https://flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Syncfusion PDF Viewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer)
- [Código fuente completo](../../lib/) 