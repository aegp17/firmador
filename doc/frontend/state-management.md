# Gestión de Estado (State Management)

## Resumen
La aplicación utiliza **Riverpod** como solución de gestión de estado. Riverpod proporciona un enfoque reactivo, type-safe y testeable para manejar el estado de la aplicación.

## Arquitectura de Estado

### Filosofía de Riverpod
- **Inmutable**: El estado no se modifica directamente
- **Reactive**: Los widgets se reconstruyen automáticamente cuando cambia el estado
- **Type-safe**: Compilación de errores si los tipos no coinciden
- **Testeable**: Fácil de mockear y probar
- **Scoped**: Estado local a componentes específicos

### Estructura de Providers
```
providers/
├── repository_providers.dart        # Repositorios de datos
├── backend_signature_provider.dart   # Estado de firma con backend
├── certificate_provider.dart        # Estado de certificados
├── pdf_provider.dart                # Estado de PDFs
└── user_preferences_provider.dart   # Estado de preferencias
```

## Tipos de Providers

### 1. FutureProvider
Para operaciones asíncronas que retornan un valor único.

```dart
// Provider para health check del backend
final backendHealthProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(backendSignatureServiceProvider);
  return await service.checkHealth();
});

// Provider para cargar datos de usuario
final userDataProvider = FutureProvider<UserData?>((ref) async {
  return await UserPreferencesService.loadUserData();
});

// Provider para información de certificado
final certificateInfoProvider = FutureProvider.family<CertificateInfo?, CertificateParams>((ref, params) async {
  final service = ref.read(backendSignatureServiceProvider);
  return await service.getCertificateInfo(
    certificateFile: params.file,
    password: params.password,
  );
});
```

### 2. StateProvider
Para estado simple que puede cambiar.

```dart
// Estado de procesamiento
final processingStateProvider = StateProvider<bool>((ref) => false);

// Estado de recordar datos
final rememberDataProvider = StateProvider<bool>((ref) => false);

// Posición de firma seleccionada
final selectedSignaturePositionProvider = StateProvider<SignaturePosition?>((ref) => null);

// Archivos seleccionados
final selectedFilesProvider = StateProvider<SelectedFiles>((ref) => SelectedFiles());
```

### 3. StateNotifierProvider
Para estado complejo con lógica de negocio.

```dart
// Estado de certificado
final certificateProvider = StateNotifierProvider<CertificateNotifier, CertificateState>((ref) {
  final service = ref.read(backendSignatureServiceProvider);
  return CertificateNotifier(service);
});

// Estado de PDF
final pdfProvider = StateNotifierProvider<PdfNotifier, PdfState>((ref) {
  return PdfNotifier();
});

// Estado de firma
final signingProvider = StateNotifierProvider<SigningNotifier, SigningState>((ref) {
  final service = ref.read(backendSignatureServiceProvider);
  return SigningNotifier(service);
});
```

### 4. Provider
Para servicios y dependencias.

```dart
// Servicio de backend
final backendSignatureServiceProvider = Provider<BackendSignatureService>((ref) {
  return BackendSignatureService();
});

// Repositorio de criptografía
final cryptoRepositoryProvider = Provider<CryptoRepository>((ref) {
  final service = ref.read(backendSignatureServiceProvider);
  return PlatformCryptoRepository(service);
});
```

## Estados Complejos con Freezed

### CertificateState
```dart
@freezed
class CertificateState with _$CertificateState {
  const factory CertificateState({
    @Default(false) bool isLoading,
    @Default(false) bool isValid,
    @Default(false) bool hasError,
    @Default('') String errorMessage,
    CertificateInfo? info,
    File? file,
    @Default('') String password,
  }) = _CertificateState;
}

class CertificateNotifier extends StateNotifier<CertificateState> {
  final BackendSignatureService _service;
  
  CertificateNotifier(this._service) : super(const CertificateState());
  
  Future<void> loadCertificate(File file, String password) async {
    state = state.copyWith(isLoading: true, hasError: false);
    
    try {
      final isValid = await _service.validateCertificate(
        certificateFile: file,
        password: password,
      );
      
      if (isValid) {
        final info = await _service.getCertificateInfo(
          certificateFile: file,
          password: password,
        );
        
        state = state.copyWith(
          isLoading: false,
          isValid: true,
          info: info,
          file: file,
          password: password,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: 'Certificado inválido o contraseña incorrecta',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }
  
  void clearCertificate() {
    state = const CertificateState();
  }
  
  void setPassword(String password) {
    state = state.copyWith(password: password);
  }
}
```

### PdfState
```dart
@freezed
class PdfState with _$PdfState {
  const factory PdfState({
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    @Default('') String errorMessage,
    File? file,
    @Default(0) int totalPages,
    @Default(1) int currentPage,
    SignaturePosition? selectedPosition,
  }) = _PdfState;
}

class PdfNotifier extends StateNotifier<PdfState> {
  PdfNotifier() : super(const PdfState());
  
  void loadPdf(File file) {
    state = state.copyWith(
      file: file,
      isLoading: false,
      hasError: false,
      selectedPosition: null,
    );
  }
  
  void setPageInfo(int totalPages, int currentPage) {
    state = state.copyWith(
      totalPages: totalPages,
      currentPage: currentPage,
    );
  }
  
  void setSignaturePosition(SignaturePosition? position) {
    state = state.copyWith(selectedPosition: position);
  }
  
  void clearPdf() {
    state = const PdfState();
  }
}
```

### SigningState
```dart
@freezed
class SigningState with _$SigningState {
  const factory SigningState({
    @Default(SigningStatus.idle) SigningStatus status,
    @Default('') String message,
    @Default(0.0) double progress,
    SignatureResponse? response,
    @Default('') String errorMessage,
  }) = _SigningState;
}

enum SigningStatus {
  idle,
  uploading,
  processing,
  completed,
  error,
}

class SigningNotifier extends StateNotifier<SigningState> {
  final BackendSignatureService _service;
  
  SigningNotifier(this._service) : super(const SigningState());
  
  Future<void> signDocument({
    required File pdfFile,
    required File certificateFile,
    required String password,
    required String signerName,
    required String signerId,
    required String location,
    required String reason,
    SignaturePosition? position,
  }) async {
    state = state.copyWith(
      status: SigningStatus.uploading,
      message: 'Subiendo archivos...',
      progress: 0.1,
    );
    
    try {
      // Simular progreso
      await Future.delayed(Duration(milliseconds: 500));
      state = state.copyWith(
        status: SigningStatus.processing,
        message: 'Procesando firma digital...',
        progress: 0.5,
      );
      
      final response = await _service.signDocument(
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
      
      state = state.copyWith(
        status: SigningStatus.completed,
        message: 'Documento firmado exitosamente',
        progress: 1.0,
        response: response,
      );
    } catch (e) {
      state = state.copyWith(
        status: SigningStatus.error,
        message: 'Error al firmar documento',
        errorMessage: e.toString(),
        progress: 0.0,
      );
    }
  }
  
  void reset() {
    state = const SigningState();
  }
}
```

## Uso en Widgets

### Consumer
Para leer estado y reconstruir widget cuando cambia.

```dart
class ServerStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthCheck = ref.watch(backendHealthProvider);
    
    return healthCheck.when(
      data: (isHealthy) => Row(
        children: [
          Icon(
            isHealthy ? Icons.circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 12,
          ),
          SizedBox(width: 8),
          Text(
            isHealthy ? 'Servidor Conectado' : 'Servidor Desconectado',
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Verificando servidor...'),
        ],
      ),
      error: (error, stack) => Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 12),
          SizedBox(width: 8),
          Text('Error de conexión', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
```

### ref.listen
Para ejecutar efectos secundarios cuando cambia el estado.

```dart
class BackendSignatureScreen extends ConsumerStatefulWidget {
  @override
  _BackendSignatureScreenState createState() => _BackendSignatureScreenState();
}

class _BackendSignatureScreenState extends ConsumerState<BackendSignatureScreen> {
  @override
  void initState() {
    super.initState();
    
    // Escuchar cambios en el estado de firma
    ref.listen<SigningState>(signingProvider, (previous, next) {
      if (next.status == SigningStatus.completed) {
        _showSuccessDialog(next.response!);
      } else if (next.status == SigningStatus.error) {
        _showErrorDialog(next.errorMessage);
      }
    });
    
    // Cargar datos de usuario al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  Future<void> _loadUserData() async {
    final userData = await ref.read(userDataProvider.future);
    if (userData != null) {
      setState(() {
        _signerNameController.text = userData.signerName;
        _signerIdController.text = userData.signerId;
        _locationController.text = userData.location;
        _reasonController.text = userData.reason;
      });
      ref.read(rememberDataProvider.notifier).state = true;
    }
  }
}
```

### ref.read
Para leer estado sin escuchar cambios.

```dart
Future<void> _signDocument() async {
  // Verificar salud del servidor
  final isHealthy = await ref.read(backendHealthProvider.future);
  if (!isHealthy) {
    _showServerDownDialog();
    return;
  }
  
  // Obtener archivos seleccionados
  final selectedFiles = ref.read(selectedFilesProvider);
  final signaturePosition = ref.read(selectedSignaturePositionProvider);
  
  // Iniciar proceso de firma
  ref.read(signingProvider.notifier).signDocument(
    pdfFile: selectedFiles.pdfFile!,
    certificateFile: selectedFiles.certificateFile!,
    password: _certificatePasswordController.text,
    signerName: _signerNameController.text,
    signerId: _signerIdController.text,
    location: _locationController.text,
    reason: _reasonController.text,
    position: signaturePosition,
  );
}
```

## Invalidación y Refresh

### Invalidar Provider
```dart
// Invalidar health check para forzar nueva verificación
ref.invalidate(backendHealthProvider);

// Invalidar datos de usuario para recargar
ref.invalidate(userDataProvider);
```

### Refresh Automático
```dart
class _BackendSignatureScreenState extends ConsumerStatefulWidget {
  Timer? _healthCheckTimer;
  
  @override
  void initState() {
    super.initState();
    _startHealthMonitoring();
  }
  
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      ref.invalidate(backendHealthProvider);
    });
  }
  
  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}
```

## Family Providers

### Providers con Parámetros
```dart
// Provider family para validación de certificado
final certificateValidationProvider = FutureProvider.family<bool, CertificateParams>((ref, params) async {
  final service = ref.read(backendSignatureServiceProvider);
  return await service.validateCertificate(
    certificateFile: params.file,
    password: params.password,
  );
});

// Clase para parámetros
class CertificateParams {
  final File file;
  final String password;
  
  CertificateParams({required this.file, required this.password});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificateParams &&
          runtimeType == other.runtimeType &&
          file.path == other.file.path &&
          password == other.password;
  
  @override
  int get hashCode => file.path.hashCode ^ password.hashCode;
}

// Uso en widget
class CertificateValidationWidget extends ConsumerWidget {
  final File certificateFile;
  final String password;
  
  const CertificateValidationWidget({
    required this.certificateFile,
    required this.password,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = CertificateParams(file: certificateFile, password: password);
    final validation = ref.watch(certificateValidationProvider(params));
    
    return validation.when(
      data: (isValid) => Icon(
        isValid ? Icons.check_circle : Icons.error,
        color: isValid ? Colors.green : Colors.red,
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Icon(Icons.error, color: Colors.red),
    );
  }
}
```

## Testing

### Mock Providers
```dart
class MockBackendSignatureService extends Mock implements BackendSignatureService {}

void main() {
  group('Certificate Provider Tests', () {
    late MockBackendSignatureService mockService;
    late ProviderContainer container;
    
    setUp(() {
      mockService = MockBackendSignatureService();
      container = ProviderContainer(
        overrides: [
          backendSignatureServiceProvider.overrideWithValue(mockService),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should validate certificate successfully', () async {
      // Arrange
      final file = File('test.p12');
      const password = 'password';
      when(mockService.validateCertificate(
        certificateFile: file,
        password: password,
      )).thenAnswer((_) async => true);
      
      // Act
      final notifier = container.read(certificateProvider.notifier);
      await notifier.loadCertificate(file, password);
      
      // Assert
      final state = container.read(certificateProvider);
      expect(state.isValid, true);
      expect(state.hasError, false);
      expect(state.file, file);
    });
    
    test('should handle certificate validation error', () async {
      // Arrange
      final file = File('invalid.p12');
      const password = 'wrong';
      when(mockService.validateCertificate(
        certificateFile: file,
        password: password,
      )).thenThrow(Exception('Invalid certificate'));
      
      // Act
      final notifier = container.read(certificateProvider.notifier);
      await notifier.loadCertificate(file, password);
      
      // Assert
      final state = container.read(certificateProvider);
      expect(state.isValid, false);
      expect(state.hasError, true);
      expect(state.errorMessage, contains('Invalid certificate'));
    });
  });
}
```

### Widget Testing con Providers
```dart
testWidgets('should show server status correctly', (tester) async {
  final mockService = MockBackendSignatureService();
  when(mockService.checkHealth()).thenAnswer((_) async => true);
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backendSignatureServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ServerStatusWidget(),
        ),
      ),
    ),
  );
  
  // Wait for async operation
  await tester.pumpAndSettle();
  
  // Verify
  expect(find.text('Servidor Conectado'), findsOneWidget);
  expect(find.byIcon(Icons.circle), findsOneWidget);
});
```

## Best Practices

### 1. Separación de Responsabilidades
```dart
// ✅ Bueno: Un provider por responsabilidad
final userDataProvider = FutureProvider<UserData?>((ref) async {
  return await UserPreferencesService.loadUserData();
});

final certificateValidationProvider = FutureProvider.family<bool, CertificateParams>((ref, params) async {
  final service = ref.read(backendSignatureServiceProvider);
  return await service.validateCertificate(/* ... */);
});

// ❌ Malo: Un provider que hace demasiado
final everythingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Loads user data, validates certificate, checks health...
});
```

### 2. Gestión de Errores
```dart
// ✅ Bueno: Manejo explícito de errores
final dataProvider = FutureProvider<Data>((ref) async {
  try {
    return await apiService.fetchData();
  } catch (e) {
    throw DataException('Failed to load data: ${e.toString()}');
  }
});

// En el widget
data.when(
  data: (data) => DataWidget(data),
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(error.toString()),
);
```

### 3. Autodispose
```dart
// ✅ Usar autodispose para providers que no necesitan persistir
final temporaryDataProvider = FutureProvider.autoDispose<Data>((ref) async {
  final data = await fetchTemporaryData();
  
  // Cleanup cuando no se use más
  ref.onDispose(() {
    data.dispose();
  });
  
  return data;
});
```

### 4. Dependencias
```dart
// ✅ Bueno: Inyectar dependencias a través de providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final dataProvider = FutureProvider<Data>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.fetchData();
});
```

## Referencias
- [Riverpod Documentation](https://riverpod.dev/)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [State Management Best Practices](https://docs.flutter.dev/development/data-and-backend/state-mgmt)
- [Código fuente](../../lib/src/presentation/providers/) 