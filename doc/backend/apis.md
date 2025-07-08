# APIs del Backend

## Resumen
El backend expone APIs REST para todas las operaciones de firma digital. Todas las APIs usan el prefijo `/api/signature/` y soportan CORS para desarrollo local.

## Base URL
- **Desarrollo**: `http://localhost:8080`
- **Producción**: `https://your-domain.com`

## Endpoints Disponibles

### 1. Health Check
Verifica el estado del servidor.

**Endpoint**: `GET /api/signature/health`

**Respuesta**:
```json
{
  "status": "UP",
  "timestamp": "2024-12-01T10:30:00Z",
  "service": "Digital Signature Service",
  "version": "1.0.0"
}
```

**Códigos de Estado**:
- `200 OK`: Servidor funcionando correctamente

---

### 2. Firmar Documento
Firma un documento PDF con un certificado digital.

**Endpoint**: `POST /api/signature/sign`

**Content-Type**: `multipart/form-data`

**Parámetros**:
| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `file` | File | ✅ | Archivo PDF a firmar |
| `certificate` | File | ✅ | Certificado digital (formato P12) |
| `password` | String | ✅ | Contraseña del certificado |
| `signerName` | String | ✅ | Nombre del firmante |
| `signerId` | String | ✅ | Cédula/RUC del firmante |
| `location` | String | ✅ | Ubicación donde se firma |
| `reason` | String | ✅ | Razón de la firma |
| `signatureX` | Integer | ❌ | Posición X de la firma (default: 100) |
| `signatureY` | Integer | ❌ | Posición Y de la firma (default: 100) |
| `signatureWidth` | Integer | ❌ | Ancho de la firma (default: 200) |
| `signatureHeight` | Integer | ❌ | Alto de la firma (default: 80) |
| `signaturePage` | Integer | ❌ | Página donde colocar la firma (default: 1) |

**Ejemplo de Request**:
```bash
curl -X POST http://localhost:8080/api/signature/sign \
  -F "file=@document.pdf" \
  -F "certificate=@certificate.p12" \
  -F "password=mypassword" \
  -F "signerName=Juan Pérez" \
  -F "signerId=1234567890" \
  -F "location=Quito, Ecuador" \
  -F "reason=Aprobación de documento" \
  -F "signatureX=150" \
  -F "signatureY=200" \
  -F "signaturePage=1"
```

**Respuesta Exitosa** (`200 OK`):
```json
{
  "success": true,
  "message": "Documento firmado exitosamente",
  "documentId": "abc123def456",
  "originalFilename": "document.pdf",
  "downloadUrl": "http://localhost:8080/api/signature/download/abc123def456",
  "fileSizeBytes": 524288
}
```

**Respuesta de Error** (`400 Bad Request`):
```json
{
  "success": false,
  "message": "Error en la validación del certificado",
  "error": "INVALID_CERTIFICATE"
}
```

**Códigos de Estado**:
- `200 OK`: Documento firmado exitosamente
- `400 Bad Request`: Error en parámetros o validación
- `413 Payload Too Large`: Archivo muy grande
- `500 Internal Server Error`: Error interno del servidor

---

### 3. Validar Certificado
Valida un certificado digital.

**Endpoint**: `POST /api/signature/validate-certificate`

**Content-Type**: `multipart/form-data`

**Parámetros**:
| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `certificate` | File | ✅ | Certificado digital (formato P12) |
| `password` | String | ✅ | Contraseña del certificado |

**Ejemplo de Request**:
```bash
curl -X POST http://localhost:8080/api/signature/validate-certificate \
  -F "certificate=@certificate.p12" \
  -F "password=mypassword"
```

**Respuesta Exitosa** (`200 OK`):
```json
{
  "valid": true,
  "message": "Certificado válido",
  "details": {
    "subject": "CN=Juan Pérez",
    "issuer": "CN=Autoridad Certificadora",
    "validFrom": "2024-01-01T00:00:00Z",
    "validTo": "2025-01-01T00:00:00Z"
  }
}
```

**Respuesta de Error** (`400 Bad Request`):
```json
{
  "valid": false,
  "message": "Certificado inválido o contraseña incorrecta",
  "error": "INVALID_CERTIFICATE"
}
```

**Códigos de Estado**:
- `200 OK`: Validación completada
- `400 Bad Request`: Certificado inválido o contraseña incorrecta
- `500 Internal Server Error`: Error interno del servidor

---

### 4. Información del Certificado
Obtiene información detallada de un certificado digital.

**Endpoint**: `POST /api/signature/certificate-info`

**Content-Type**: `multipart/form-data`

**Parámetros**:
| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `certificate` | File | ✅ | Certificado digital (formato P12) |
| `password` | String | ✅ | Contraseña del certificado |

**Ejemplo de Request**:
```bash
curl -X POST http://localhost:8080/api/signature/certificate-info \
  -F "certificate=@certificate.p12" \
  -F "password=mypassword"
```

**Respuesta Exitosa** (`200 OK`):
```json
{
  "subject": "CN=Juan Pérez, OU=Desarrollo, O=Empresa, L=Quito, ST=Pichincha, C=EC",
  "issuer": "CN=Autoridad Certificadora Nacional, O=Banco Central, C=EC",
  "serialNumber": "1234567890ABCDEF",
  "validFrom": "2024-01-01T00:00:00Z",
  "validTo": "2025-01-01T00:00:00Z",
  "isValid": true,
  "keyAlgorithm": "RSA",
  "signatureAlgorithm": "SHA256withRSA"
}
```

**Respuesta de Error** (`400 Bad Request`):
```json
{
  "error": "INVALID_CERTIFICATE",
  "message": "No se pudo extraer información del certificado"
}
```

**Códigos de Estado**:
- `200 OK`: Información extraída exitosamente
- `400 Bad Request`: Error en certificado o contraseña
- `500 Internal Server Error`: Error interno del servidor

---

### 5. Descargar Documento
Descarga un documento firmado usando su ID.

**Endpoint**: `GET /api/signature/download/{id}`

**Parámetros de Ruta**:
| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | String | ID del documento generado tras la firma |

**Ejemplo de Request**:
```bash
curl -X GET http://localhost:8080/api/signature/download/abc123def456 \
  -o document_signed.pdf
```

**Respuesta Exitosa** (`200 OK`):
- **Content-Type**: `application/pdf`
- **Content-Disposition**: `attachment; filename="document_signed.pdf"`
- **Body**: Contenido binario del PDF firmado

**Respuesta de Error** (`404 Not Found`):
```json
{
  "error": "DOCUMENT_NOT_FOUND",
  "message": "Documento no encontrado o expirado"
}
```

**Códigos de Estado**:
- `200 OK`: Documento descargado exitosamente
- `404 Not Found`: Documento no encontrado
- `500 Internal Server Error`: Error interno del servidor

---

## Manejo de Errores

### Códigos de Error Comunes
| Código | Descripción |
|--------|-------------|
| `INVALID_CERTIFICATE` | Certificado inválido o contraseña incorrecta |
| `INVALID_PDF` | Archivo PDF corrupto o inválido |
| `FILE_TOO_LARGE` | Archivo excede el tamaño máximo permitido |
| `MISSING_PARAMETER` | Parámetro requerido faltante |
| `PROCESSING_ERROR` | Error durante el procesamiento |
| `DOCUMENT_NOT_FOUND` | Documento no encontrado |
| `INTERNAL_ERROR` | Error interno del servidor |

### Estructura de Respuesta de Error
```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Descripción del error",
  "timestamp": "2024-12-01T10:30:00Z",
  "details": {
    "field": "certificatePassword",
    "rejected": "****",
    "message": "Contraseña incorrecta"
  }
}
```

## Límites y Restricciones

### Tamaños de Archivo
- **Desarrollo**: 50MB máximo por archivo
- **Producción**: 100MB máximo por archivo

### Rate Limiting
- **Desarrollo**: Sin límites
- **Producción**: 100 requests por minuto por IP

### Formatos Soportados
- **PDF**: Todas las versiones estándar
- **Certificados**: PKCS#12 (.p12, .pfx)

### Timeouts
- **Conexión**: 30 segundos
- **Procesamiento**: 5 minutos
- **Descarga**: 10 minutos

## Configuración CORS

### Orígenes Permitidos
```java
// Desarrollo
"http://localhost:*"

// Producción
"https://yourdomain.com"
```

### Métodos Permitidos
```
GET, POST, PUT, DELETE, OPTIONS
```

### Headers Permitidos
```
Content-Type, Authorization, X-Requested-With
```

## Ejemplos de Integración

### JavaScript/Axios
```javascript
// Firmar documento
const formData = new FormData();
formData.append('file', pdfFile);
formData.append('certificate', certificateFile);
formData.append('password', password);
formData.append('signerName', 'Juan Pérez');
formData.append('signerId', '1234567890');
formData.append('location', 'Quito, Ecuador');
formData.append('reason', 'Aprobación');

const response = await axios.post('/api/signature/sign', formData, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
});
```

### Flutter/Dio
```dart
// Firmar documento
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(pdfFile.path),
  'certificate': await MultipartFile.fromFile(certificateFile.path),
  'password': password,
  'signerName': signerName,
  'signerId': signerId,
  'location': location,
  'reason': reason,
});

final response = await dio.post('/api/signature/sign', data: formData);
```

## Referencias
- [Spring Boot REST APIs](https://spring.io/guides/gs/rest-service/)
- [Multipart File Upload](https://spring.io/guides/gs/uploading-files/)
- [CORS Configuration](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors)
- [Código fuente](../../backend/src/main/java/com/firmador/backend/controller/) 