# Firmador - Digital Document Signing App

Firmador es una aplicación híbrida de firma digital que combina una aplicación móvil Flutter con un backend Java Spring Boot para proporcionar una solución robusta y segura de firma electrónica de documentos.

## 🏗️ Arquitectura

### Arquitectura Híbrida
La aplicación utiliza una arquitectura híbrida que combina:

- **Frontend**: Aplicación móvil Flutter (iOS/Android)
- **Backend**: Servidor Java Spring Boot con APIs REST
- **Procesamiento**: Firma digital realizada en el servidor usando iText y BouncyCastle

```
┌─────────────────┐    HTTP/REST     ┌─────────────────┐
│   Flutter App   │ ────────────────▶ │  Spring Boot    │
│   (Frontend)    │                  │    Backend      │
├─────────────────┤                  ├─────────────────┤
│ • File Selection│                  │ • PDF Processing│
│ • UI/UX         │                  │ • Digital Sign  │
│ • Certificate   │                  │ • Certificate   │
│   Validation    │                  │   Validation    │
│ • User Input    │                  │ • Crypto Ops    │
│ • Health Check  │                  │ • Visual Stamps │
└─────────────────┘                  └─────────────────┘
```

### ¿Por qué esta arquitectura?

1. **Limitaciones de iOS**: iOS tiene restricciones en el acceso directo a APIs de firma digital
2. **Seguridad**: El procesamiento criptográfico se realiza en un entorno controlado del servidor
3. **Consistencia**: Garantiza resultados idénticos independientemente de la plataforma
4. **Escalabilidad**: Permite manejar múltiples clientes desde un servidor centralizado
5. **Mantenimiento**: Lógica de negocio centralizada facilita actualizaciones

## 🚀 Características

### Frontend (Flutter)
- ✅ Interfaz de usuario moderna y responsiva
- ✅ Selección de archivos PDF y certificados P12
- ✅ **Previsualización de documentos PDF** con navegación de páginas
- ✅ **Selección visual de posición de firma** mediante toque en el documento
- ✅ **Persistencia de datos del usuario** con opción "Recordar mis datos"
- ✅ Validación en tiempo real de certificados
- ✅ **Monitoreo automático del estado del servidor** (actualización cada 2 minutos)
- ✅ Manejo de errores robusto con mensajes descriptivos
- ✅ Soporte para iOS y Android
- ✅ Dos modos de operación: servidor y local
- ✅ Indicadores de progreso para operaciones largas
- ✅ Validación de formularios en tiempo real

### Backend (Spring Boot)
- ✅ API REST para firma digital
- ✅ Validación y extracción de información de certificados digitales
- ✅ Procesamiento de PDF con iText 7.2.5
- ✅ Soporte para certificados PKCS#12
- ✅ Estampado visual de firmas con metadata
- ✅ Manejo seguro de credenciales en memoria
- ✅ Health checks y monitoreo
- ✅ Configuración Docker-ready
- ✅ CORS configurado para desarrollo y producción
- ✅ Manejo de archivos temporales seguros

## 🎯 Nuevas Funcionalidades UX

### 📄 Previsualización de Documentos
- **Visor PDF integrado**: Visualiza completamente el documento antes de firmar
- **Navegación fluida**: Navega entre páginas con indicadores de progreso
- **Responsivo**: Adaptado a diferentes tamaños de pantalla
- **Zoom automático**: Ajuste óptimo para visualización

### 🎯 Selección Visual de Posición de Firma
- **Interfaz intuitiva**: Toca directamente donde quieres la firma
- **Indicador visual**: Marcador claro de la posición seleccionada
- **Información de página**: Muestra página actual y total de páginas
- **Confirmación**: Proceso de confirmación antes de aplicar
- **Persistencia**: La posición se mantiene durante la sesión

### 💾 Persistencia de Datos del Usuario
- **Recordar datos**: Checkbox para guardar información del firmante
- **Carga automática**: Datos se restauran automáticamente al iniciar
- **Privacidad**: Almacenamiento local seguro usando `SharedPreferences`
- **Campos incluidos**: Nombre, Cédula/RUC, Ubicación, Razón de firma
- **Gestión flexible**: Opción de limpiar datos guardados

### 📡 Monitoreo Automático del Servidor
- **Verificación continua**: Estado del servidor cada 2 minutos
- **Actualización manual**: Botón de refresh disponible
- **Indicadores visuales**: Iconos de estado en tiempo real
- **Manejo de errores**: Notificaciones claras de problemas de conectividad
- **Optimización**: Evita verificaciones innecesarias

### 🔧 Mejoras en la Experiencia de Usuario
- **Formularios inteligentes**: Validación en tiempo real
- **Botones dinámicos**: Estados habilitados/deshabilitados según contexto
- **Mensajes descriptivos**: Feedback claro para cada acción
- **Progreso visual**: Indicadores de carga durante operaciones
- **Navegación mejorada**: Flujo más intuitivo y lógico

## 📋 Requisitos

### Desarrollo
- **Java 17+** (para el backend)
- **Maven 3.6+** (para el backend)
- **Flutter 3.0+** (para el frontend)
- **Dart 3.0+** (para el frontend)
- **Docker** (opcional, para despliegue)
- **iOS Simulator** (para desarrollo iOS)
- **Android Emulator** (para desarrollo Android)

### Dependencias Principales
#### Backend
- **Spring Boot 3.x**: Framework principal
- **iText 7.2.5**: Procesamiento y firma de PDFs
- **BouncyCastle 1.70**: Operaciones criptográficas
- **Jackson**: Serialización JSON

#### Frontend
- **Flutter Riverpod**: Gestión de estado reactivo
- **Dio**: Cliente HTTP para comunicación con backend
- **Syncfusion PDF Viewer**: Visualización de documentos PDF
- **File Picker**: Selección de archivos del dispositivo
- **Shared Preferences**: Persistencia de datos del usuario
- **URL Launcher**: Apertura de enlaces de descarga

### Producción
- **Docker** y **Docker Compose**
- **2GB RAM** mínimo para el backend
- **Certificados SSL** (recomendado para producción)
- **Nginx** (incluido en Docker setup)

## 🛠️ Instalación y Configuración

### Setup Rápido con Script de Desarrollo

El proyecto incluye un script automatizado para development:

```bash
# Dar permisos de ejecución
chmod +x start-dev.sh

# Iniciar todo (backend + frontend)
./start-dev.sh

# Solo backend
./start-dev.sh --skip-frontend

# Solo frontend
./start-dev.sh --skip-backend

# Con Docker
./start-dev.sh --docker
```

### Setup Manual

#### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd firmador
```

#### 2. Configurar el Backend

##### Desarrollo Local
```bash
cd backend
mvn clean install
mvn spring-boot:run
```

El backend estará disponible en `http://localhost:8080`

##### Con Docker
```bash
cd backend
docker build -t firmador-backend .
docker run -p 8080:8080 firmador-backend
```

##### Con Docker Compose
```bash
cd backend
docker-compose up -d
```

#### 3. Configurar el Frontend

##### Instalar dependencias
```bash
flutter pub get
```

##### Configurar URL del backend
La URL del backend se configura automáticamente:
- **Desarrollo**: `http://localhost:8080`
- **Producción**: Configurable en `lib/src/data/services/backend_signature_service.dart`

##### Ejecutar la aplicación
```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Dispositivo físico
flutter run

# Con device específico
flutter run -d <device-id>
```

## 🔧 Configuración

### Backend Configuration

#### Desarrollo (`application.yml`)
```yaml
server:
  port: 8080

spring:
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 60MB

firmador:
  storage:
    path: /tmp/firmador-storage
  signature:
    default-location: "Ecuador"
    default-reason: "Firma digital realizada con Firmador App"
```

#### Producción (`application-docker.yml`)
```yaml
server:
  port: 8080

spring:
  servlet:
    multipart:
      max-file-size: 100MB
      max-request-size: 120MB

firmador:
  storage:
    path: /app/storage
  signature:
    default-location: "Ecuador"
    default-reason: "Documento firmado digitalmente"
```

### Variables de Entorno

```bash
# Backend
SPRING_PROFILES_ACTIVE=docker
JAVA_OPTS=-Xmx1g -Xms512m

# Frontend
BACKEND_URL=https://your-backend-domain.com
```

## 📱 Uso de la Aplicación

### Pantalla de Bienvenida
La aplicación ofrece dos modos de operación:

1. **Firmar con Servidor** (Recomendado para iOS)
   - Utiliza el backend para procesamiento
   - Más confiable y consistente
   - Ideal para iOS donde hay limitaciones

2. **Firmar Localmente** (Solo Android)
   - Procesamiento en el dispositivo
   - Requiere Android con APIs nativas

### Proceso de Firma con Servidor

#### 1. Verificar Conexión
- Al abrir la pantalla, verifica que el indicador del servidor esté verde
- Si está rojo, verifica la URL del backend y la conectividad
- El sistema verifica automáticamente cada 2 minutos
- Botón de actualización manual disponible

#### 2. Seleccionar Documento
- Toca "Seleccionar Documento PDF"
- Elige el documento que deseas firmar
- El sistema valida automáticamente que sea un PDF válido
- **Previsualización disponible**: Usa "Previsualizar" para ver el documento

#### 3. Seleccionar Posición de Firma
- Toca "Seleccionar Posición" para abrir la previsualización
- Navega entre páginas del documento
- **Toca directamente en el documento** donde quieres la firma
- Indicador visual muestra la posición seleccionada
- Confirma la posición elegida

#### 4. Seleccionar Certificado
- Toca "Seleccionar Certificado (.p12)"
- Elige tu certificado digital (formato P12/PFX)
- Ingresa la contraseña del certificado
- El sistema valida automáticamente el certificado

#### 5. Completar Información del Firmante
- **Datos persistentes**: Marca "Recordar mis datos" para guardar información
- Llena los campos requeridos:
  - **Nombre completo**: Nombre del firmante
  - **Cédula/RUC**: Identificación del firmante
  - **Ubicación**: Lugar de la firma (por defecto: Ecuador)
  - **Razón**: Motivo de la firma (por defecto: Firma digital)
- Los datos se cargan automáticamente en futuras sesiones si está activado

#### 6. Firmar Documento
- Toca "Firmar Documento" (se activa cuando todo está listo)
- El sistema muestra progreso en tiempo real
- El documento firmado se procesa en el servidor
- Se genera un estampado visual con la información del firmante
- **Descarga directa**: Botón "Descargar PDF" en el diálogo de éxito

## 🔐 Seguridad

### Medidas Implementadas
- ✅ Validación de tipos de archivo (PDF, P12/PFX)
- ✅ Límites de tamaño de archivo (50MB desarrollo, 100MB producción)
- ✅ Validación estricta de certificados digitales
- ✅ Comunicación HTTPS (recomendada para producción)
- ✅ Manejo seguro de contraseñas en memoria
- ✅ Logs de auditoría en el backend
- ✅ CORS configurado apropiadamente
- ✅ Headers de seguridad en Nginx
- ✅ Rate limiting en producción
- ✅ Limpieza automática de archivos temporales

### Recomendaciones de Seguridad
1. **HTTPS**: Usar siempre HTTPS en producción
2. **Firewall**: Configurar firewall para restringir acceso al backend
3. **Certificados SSL**: Usar certificados SSL válidos
4. **Logs**: Monitorear logs de acceso y errores
5. **Actualizaciones**: Mantener dependencias actualizadas
6. **Secrets**: No hardcodear credenciales en el código
7. **Backup**: Realizar backups regulares de certificados

## 🚧 API Documentation

### Endpoints Principales

#### POST `/api/signature/sign`
Firma un documento PDF.

**Content-Type**: `multipart/form-data`

**Parámetros:**
- `document` (file): Archivo PDF a firmar
- `certificate` (file): Certificado P12/PFX
- `signerName` (string): Nombre del firmante
- `signerId` (string): Cédula/RUC del firmante
- `location` (string): Ubicación de la firma (opcional)
- `reason` (string): Razón de la firma (opcional)
- `certificatePassword` (string): Contraseña del certificado
- `signatureX` (int): Posición X de la firma (opcional, default: 100)
- `signatureY` (int): Posición Y de la firma (opcional, default: 100)
- `signatureWidth` (int): Ancho de la firma (opcional, default: 200)
- `signatureHeight` (int): Alto de la firma (opcional, default: 80)
- `signaturePage` (int): Página donde colocar la firma (opcional, default: 1)

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Documento firmado exitosamente",
  "documentId": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "documento_firmado.pdf",
  "signedAt": "2024-01-01T12:00:00Z",
  "fileSize": 1024,
  "downloadUrl": "/api/signature/download/550e8400-e29b-41d4-a716-446655440000"
}
```

#### POST `/api/signature/validate-certificate`
Valida un certificado digital.

**Content-Type**: `multipart/form-data`

**Parámetros:**
- `certificate` (file): Certificado P12/PFX
- `password` (string): Contraseña del certificado

**Respuesta exitosa (200):**
```json
{
  "valid": true,
  "message": "Certificado válido",
  "expirationDate": "2025-12-31T23:59:59Z"
}
```

#### POST `/api/signature/certificate-info`
Extrae información detallada de un certificado.

**Content-Type**: `multipart/form-data`

**Parámetros:**
- `certificate` (file): Certificado P12/PFX
- `password` (string): Contraseña del certificado

**Respuesta exitosa (200):**
```json
{
  "subject": "CN=Juan Pérez, O=Empresa XYZ",
  "issuer": "CN=CA Root, O=Certificate Authority",
  "serialNumber": "123456789",
  "notBefore": "2024-01-01T00:00:00Z",
  "notAfter": "2025-12-31T23:59:59Z",
  "keyAlgorithm": "RSA",
  "keySize": 2048,
  "signatureAlgorithm": "SHA256withRSA"
}
```

#### GET `/api/signature/download/{documentId}`
Descarga un documento firmado.

**Parámetros:**
- `documentId` (path): ID del documento generado durante la firma

**Respuesta exitosa (200):**
- **Content-Type**: `application/pdf`
- **Content-Disposition**: `attachment; filename="documento_firmado.pdf"`
- Datos binarios del PDF firmado

#### GET `/api/signature/health`
Verifica el estado del servidor.

**Respuesta exitosa (200):**
```json
{
  "status": "UP",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0"
}
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
mvn test
```

### Frontend Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Manual Testing
1. Verificar health check: `curl http://localhost:8080/api/signature/health`
2. Probar con certificado de prueba
3. Verificar logs de errores
4. Probar límites de tamaño de archivo

## 📦 Despliegue

### Desarrollo Local

#### Script Automatizado
```bash
# Iniciar todo
./start-dev.sh

# Solo backend
./start-dev.sh --skip-frontend

# Solo frontend
./start-dev.sh --skip-backend
```

#### Manual
```bash
# Backend
cd backend
mvn spring-boot:run

# Frontend (nueva terminal)
flutter run -d ios
```

### Producción

#### Con Docker Compose (Recomendado)
```bash
cd backend
docker-compose --profile production up -d
```

#### Solo Backend
```bash
cd backend
docker build -t firmador-backend .
docker run -d -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=docker \
  -e JAVA_OPTS="-Xmx1g -Xms512m" \
  firmador-backend
```

### Despliegue de Flutter

#### iOS
```bash
flutter build ios --release
# Después usar Xcode para subir a App Store
```

#### Android
```bash
flutter build apk --release
# O para Google Play:
flutter build appbundle --release
```

## 🐛 Troubleshooting

### Problemas Comunes

#### 1. Backend no conecta
**Síntomas**: Indicador rojo en la app, errores de conexión

**Soluciones**:
- Verificar que el puerto 8080 esté libre: `lsof -i :8080`
- Verificar la URL en el frontend
- Revisar logs del backend: `docker logs firmador-backend`
- Verificar firewall/antivirus

#### 2. Error de certificado inválido
**Síntomas**: "Certificado no válido" en la app

**Soluciones**:
- Verificar que el archivo sea .p12 o .pfx
- Verificar la contraseña del certificado
- Verificar que el certificado no haya expirado
- Probar con un certificado diferente

#### 3. Archivo PDF no válido
**Síntomas**: Error al seleccionar PDF

**Soluciones**:
- Verificar que el archivo sea un PDF real
- Verificar que el PDF no esté corrupto
- Verificar que el tamaño sea menor al límite (50MB)
- Probar con un PDF diferente

#### 4. Error de memoria en el backend
**Síntomas**: OutOfMemoryError en logs

**Soluciones**:
- Aumentar memoria: `JAVA_OPTS=-Xmx1g -Xms512m`
- Verificar recursos del servidor
- Reducir tamaño máximo de archivos
- Reiniciar el backend

#### 5. Flutter build iOS falla
**Síntomas**: Errores de compilación en iOS

**Soluciones**:
- Limpiar build: `flutter clean && flutter pub get`
- Actualizar pods: `cd ios && pod install`
- Verificar Xcode y iOS SDK
- Revisar configuración de firma de código

### Logs y Debugging

#### Backend Logs
```bash
# Con Docker
docker logs firmador-backend

# Con Docker Compose
docker-compose logs backend

# Sin Docker
tail -f logs/application.log
```

#### Frontend Logs
```bash
# Durante desarrollo
flutter logs

# Específico para device
flutter logs -d <device-id>
```

#### Debugging
```bash
# Backend debug mode
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"

# Flutter debug mode
flutter run --debug
```

## 🔧 Scripts de Utilidad

### start-dev.sh
Script principal para desarrollo:

```bash
./start-dev.sh [OPTIONS]

Options:
  --docker            Use Docker for backend
  --skip-backend      Skip backend startup
  --skip-frontend     Skip frontend startup
  --help             Show this help message
```

### cleanup.sh
Script para limpieza:

```bash
./cleanup.sh [OPTIONS]

Options:
  --deep             Deep clean (remove all artifacts)
  --docker           Clean Docker containers/images
  --help             Show this help message
```

## 🤝 Contribuir

### Proceso de Contribución
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m '🤖 Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código
- **Backend**: Seguir Java Code Conventions
- **Frontend**: Seguir Dart Style Guide
- **Commits**: Usar emojis y ser descriptivos
- **Tests**: Incluir tests para nuevas funcionalidades

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Soporte

Para soporte técnico:

1. **Documentación**: Revisar esta documentación
2. **Issues**: Buscar en los Issues existentes
3. **Nuevo Issue**: Crear con información detallada:
   - Descripción del problema
   - Pasos para reproducir
   - Logs relevantes
   - Información del sistema
   - Capturas de pantalla

### Información del Sistema
```bash
# Backend
java -version
mvn -version

# Frontend
flutter --version
dart --version

# Docker
docker --version
docker-compose --version
```

## 🔄 Changelog

### v1.1.0 (2024-01-15)
- ✅ Script automatizado de desarrollo (`start-dev.sh`)
- ✅ Script de limpieza (`cleanup.sh`)
- ✅ Monitoreo de salud del servidor en tiempo real
- ✅ Mejoras en la UI/UX del frontend
- ✅ Validación mejorada de certificados
- ✅ Configuración Docker optimizada
- ✅ Documentación actualizada

### v1.0.0 (2024-01-01)
- ✅ Arquitectura híbrida con backend Spring Boot
- ✅ Frontend Flutter multiplataforma
- ✅ Firma digital con iText y BouncyCastle
- ✅ Validación de certificados PKCS#12
- ✅ API REST completa
- ✅ Soporte para Docker
- ✅ Documentación completa

## 🛣️ Roadmap

### Próximas Características
- [ ] Almacenamiento persistente de documentos firmados
- [ ] API para descarga de documentos firmados
- [ ] Soporte para múltiples formatos de certificado
- [ ] Integración con servicios de timestamp
- [ ] Dashboard web para administración
- [ ] Notificaciones push
- [ ] Soporte para firma batch (múltiples documentos)
- [ ] Integración con servicios en la nube
- [ ] Modo offline con sincronización
- [ ] Autenticación y autorización de usuarios

### Mejoras Técnicas
- [ ] Caché de certificados validados
- [ ] Optimización de rendimiento
- [ ] Monitoreo avanzado con Prometheus
- [ ] CI/CD pipeline completo
- [ ] Tests de carga y estrés
- [ ] Documentación OpenAPI/Swagger
- [ ] Métricas y analytics
- [ ] Backup automático

### Plataformas Adicionales
- [ ] Aplicación web (React/Vue)
- [ ] Aplicación desktop (Electron)
- [ ] API pública para terceros
- [ ] Plugins para navegadores
