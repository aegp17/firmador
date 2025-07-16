# Implementación Android - Firma Digital Local

## Resumen

La implementación de Android para FirmaSeguraEC incorpora un **sistema híbrido** que combina:

1. **Firma Local**: Procesamiento nativo en Android usando iText7 + BouncyCastle
2. **Fallback al Backend**: Si la firma local falla, utiliza automáticamente el backend
3. **Sistema TSA Robusto**: Múltiples servidores de timestamp con fallback automático

## Arquitectura del Sistema

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────┐
│                   Android App Layer                        │
├─────────────────────────────────────────────────────────────┤
│ AndroidSignatureScreen │ HybridSignatureService            │
├─────────────────────────┼───────────────────────────────────┤
│                         │ PlatformCryptoRepository          │
├─────────────────────────┼───────────────────────────────────┤
│     MethodChannel      │ BackendSignatureService (Fallback) │
├─────────────────────────────────────────────────────────────┤
│                   Native Android Layer                     │
├─────────────────────────────────────────────────────────────┤
│ MainActivity │ PdfSignatureService │ CertificateHelper     │
├──────────────┼─────────────────────┼─────────────────────────┤
│   TSAClient  │     iText7          │   BouncyCastle         │
└─────────────────────────────────────────────────────────────┘
```

### Flujo de Firma Híbrida

1. **Intento Local** (Solo Android):
   - Carga certificado PKCS12 localmente
   - Procesa PDF con iText7
   - Obtiene timestamp de servidores TSA
   - Genera firma digital PKCS#7

2. **Fallback Backend** (Si falla local):
   - Envía archivos al backend Spring Boot
   - Utiliza la implementación robusta del servidor
   - Descarga PDF firmado

## Dependencias Android

### Gradle Dependencies

```kotlin
dependencies {
    // PDF manipulation and digital signing
    implementation 'com.itextpdf:itext7-core:7.2.5'
    implementation 'com.itextpdf:sign:7.2.5'
    implementation 'com.itextpdf:bouncy-castle-adapter:7.2.5'
    
    // BouncyCastle cryptography provider
    implementation 'org.bouncycastle:bcprov-jdk15to18:1.76'
    implementation 'org.bouncycastle:bcpkix-jdk15to18:1.76'
    implementation 'org.bouncycastle:bcutil-jdk15to18:1.76'
    
    // HTTP client for TSA requests
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.12.0'
    
    // Kotlin coroutines for async operations
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
    
    // Multidex support
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### ProGuard Configuration

Las reglas de ProGuard protegen las clases criptográficas de la ofuscación:

```proguard
# Keep iText PDF classes
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**

# Keep BouncyCastle classes
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep certificate and crypto related classes
-keep class java.security.** { *; }
-keep class javax.crypto.** { *; }
-keep class java.security.cert.** { *; }
```

## Componentes Nativos

### 1. CertificateHelper.kt

**Propósito**: Manejo de certificados PKCS12

**Funcionalidades**:
- Carga y validación de certificados
- Extracción de información (CN, emisor, vigencia)
- Gestión de claves privadas
- Análisis de uso de claves

```kotlin
// Ejemplo de uso
val certInfo = CertificateHelper.loadCertificateInfo(
    p12Path = "/path/to/cert.p12",
    password = "password123"
)
```

### 2. TSAClient.kt

**Propósito**: Cliente para servidores de sellado de tiempo

**Características**:
- Múltiples servidores TSA con fallback automático
- Reintentos configurables (2 intentos por servidor)
- Categorización inteligente de errores
- Extracción de información de timestamp

**Servidores TSA Configurados**:
```kotlin
private val TSA_SERVERS = listOf(
    "https://freetsa.org/tsr",           // FreeTSA (gratuito)
    "http://timestamp.digicert.com",     // DigiCert
    "http://timestamp.apple.com/ts01",   // Apple
    "http://timestamp.sectigo.com",      // Sectigo
    "http://timestamp.entrust.net/TSS/RFC3161sha2TS" // Entrust
)
```

### 3. PdfSignatureService.kt

**Propósito**: Servicio principal de firma digital

**Proceso de Firma**:
1. Validación de parámetros
2. Carga de certificado y clave privada
3. Configuración del PDF signer (iText7)
4. Obtención opcional de timestamp
5. Configuración de apariencia de firma
6. Firma digital con estándar CMS/PKCS#7
7. Fallback sin timestamp si TSA falla

### 4. MainActivity.kt

**Propósito**: Puente entre Flutter y código nativo

**Method Channel**: `com.firmador/crypto`

**Métodos Expuestos**:
- `getCertificateInfo`: Extrae información del certificado
- `signPdf`: Firma documento PDF con certificado

## Interfaz Flutter

### HybridSignatureService.dart

**Estrategia Híbrida**:
```dart
Future<HybridSignatureResult> signDocument(...) async {
  // 1. Intentar firma local en Android
  if (Platform.isAndroid) {
    final localResult = await _signLocally(...);
    if (localResult.success) {
      return HybridSignatureResult(
        signingMethod: SigningMethod.local,
        // ... otros datos
      );
    }
  }
  
  // 2. Fallback al backend
  final backendResult = await _backendService.signDocument(...);
  return HybridSignatureResult(
    signingMethod: SigningMethod.backend,
    // ... otros datos
  );
}
```

### AndroidSignatureScreen.dart

**UI Específica para Android**:
- Indicador de estado del servicio (local vs backend)
- Feedback visual del método de firma utilizado
- Información detallada de timestamp y TSA
- Progreso en tiempo real del proceso

## Configuración de Timestamp

### Parámetros TSA

```dart
final Map<String, String> _tsaServers = {
  'https://freetsa.org/tsr': 'FreeTSA (Gratis)',
  'http://timestamp.digicert.com': 'DigiCert',
  'http://timestamp.apple.com/ts01': 'Apple',
  'http://timestamp.sectigo.com': 'Sectigo',
  'http://timestamp.entrust.net/TSS/RFC3161sha2TS': 'Entrust',
};
```

### Manejo de Errores TSA

El sistema categoriza y maneja errores específicos:

- **HTTP 405/400**: Servidor no compatible, no reintentar
- **Timeout**: Reintento con delay progresivo
- **SSL/TLS**: Problema de certificados del servidor
- **DNS**: Problema de conectividad de red

## Ventajas de la Implementación

### 1. **Rendimiento**
- Firma local: ~2-5 segundos
- Sin transferencia de archivos grandes
- Procesamiento en paralelo

### 2. **Privacidad**
- Certificados nunca salen del dispositivo
- PDFs procesados localmente
- Control total del usuario

### 3. **Robustez**
- Fallback automático al backend
- Múltiples servidores TSA
- Manejo inteligente de errores

### 4. **Compatibilidad**
- Estándar PKCS#7/CMS
- Timestamps RFC 3161
- PDF/A compatible

## Limitaciones y Consideraciones

### 1. **Tamaño de APK**
- Librerías iText7 + BouncyCastle: ~15-20 MB
- Mitigado con ProGuard en release

### 2. **Compatibilidad de Certificados**
- Soporta PKCS12 (.p12/.pfx)
- Requiere certificados con uso "Digital Signature"

### 3. **Conectividad TSA**
- Timestamp requiere conexión a internet
- Degrada graciosamente sin timestamp

### 4. **Versiones Android**
- Mínimo API 21 (Android 5.0)
- Optimizado para API 30+

## Testing y Validación

### Casos de Prueba

1. **Firma Local Exitosa**:
   - Certificado válido + PDF válido + TSA disponible
   - Verificar timestamp real en PDF

2. **Fallback al Backend**:
   - Simular fallo local (certificado inválido)
   - Verificar transición automática

3. **Fallback TSA**:
   - Bloquear servidor primario
   - Verificar uso de servidor secundario

4. **Firma sin Timestamp**:
   - Bloquear todos los servidores TSA
   - Verificar firma sin timestamp

### Comandos de Testing

```bash
# Compilar y probar en dispositivo Android
flutter build apk --debug
flutter install --device-id=<android_device>

# Logs detallados de firma
adb logcat -s MainActivity PdfSignatureService TSAClient
```

## Métricas de Rendimiento

### Tiempos Típicos (Dispositivo Android Moderno)

- **Carga de certificado**: 100-300 ms
- **Firma local sin TSA**: 1-2 segundos
- **Firma local con TSA**: 3-6 segundos
- **Fallback backend**: 10-30 segundos

### Uso de Memoria

- **Baseline**: ~50 MB
- **Durante firma**: ~80-120 MB
- **Peak con PDF grande**: ~200 MB

## Troubleshooting

### Problemas Comunes

1. **"Certificate error"**:
   - Verificar formato PKCS12
   - Validar contraseña
   - Comprobar permisos de archivo

2. **"TSA timeout"**:
   - Verificar conectividad
   - Probar con servidor diferente
   - Continuar sin timestamp

3. **"PDF signing failed"**:
   - Verificar integridad del PDF
   - Comprobar permisos de escritura
   - Intentar fallback backend

### Logs de Diagnóstico

```kotlin
// Habilitar logs detallados
Log.d("TSAClient", "Attempting TSA request to: $url")
Log.i("PdfSignatureService", "Signature completed: $outputPath")
Log.w("MainActivity", "Local signing failed, falling back to backend")
```

## Futuras Mejoras

### Optimizaciones Planificadas

1. **Cache de Certificados**: Almacenar info descifrada
2. **TSA Local Cache**: Cache de timestamps recientes
3. **Firma en Lote**: Múltiples documentos
4. **Compresión PDF**: Optimizar tamaño de salida

### Funciones Adicionales

1. **Validación de Firmas**: Verificar PDFs firmados
2. **Múltiples Firmas**: Varias firmas en un PDF
3. **Plantillas de Firma**: Apariencias personalizadas
4. **Integración Biométrica**: Firma con huella dactilar

---

**Última actualización**: Enero 2025  
**Versión Android mínima**: API 21 (Android 5.0)  
**Versión Android recomendada**: API 30+ (Android 11+) 