# ADR-001: Arquitectura Híbrida Flutter + Spring Boot

## Estado
**Aceptado** - Diciembre 2024

## Contexto
El proyecto Firmador inicialmente se concibió como una aplicación Flutter nativa que realizaría el procesamiento de firma digital directamente en el dispositivo móvil. Sin embargo, durante el desarrollo se identificaron varios problemas críticos:

1. **Limitaciones de iOS**: iOS tiene restricciones estrictas en el acceso a APIs de criptografía y constantes del sistema de seguridad
2. **Compilación fallida**: Error continuo `Command CodeSign failed with a nonzero exit code` en iOS
3. **APIs no disponibles**: Constantes como `kSecPropertyKeyValue` y `kSecOIDX509V1SerialNumber` no están disponibles en iOS
4. **Inconsistencia entre plataformas**: Diferentes comportamientos entre Android e iOS
5. **Complejidad de mantenimiento**: Lógica criptográfica duplicada y compleja en el cliente

## Decisión
Implementar una **arquitectura híbrida** que combine:

- **Frontend**: Aplicación Flutter para UI/UX y gestión de archivos
- **Backend**: Servidor Spring Boot para procesamiento criptográfico
- **Comunicación**: APIs REST para intercambio de datos

### Flujo de la Arquitectura
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

### Responsabilidades

#### Frontend (Flutter)
- Selección de archivos PDF y certificados
- Validación de formularios
- Interfaz de usuario
- Comunicación con backend
- Descarga de documentos firmados
- Monitoreo del estado del servidor

#### Backend (Spring Boot)
- Procesamiento de PDFs con iText
- Operaciones criptográficas con BouncyCastle
- Validación de certificados digitales
- Generación de estampados visuales
- Almacenamiento temporal de documentos
- APIs REST para todas las operaciones

## Consecuencias

### ✅ Positivas
1. **Solución a problemas de iOS**: Elimina completamente las limitaciones de la plataforma
2. **Consistencia cross-platform**: Mismo resultado en iOS y Android
3. **Seguridad centralizada**: Lógica criptográfica en entorno controlado
4. **Escalabilidad**: Un backend puede servir múltiples clientes
5. **Mantenimiento simplificado**: Lógica de negocio centralizada
6. **Testing más fácil**: Backend testeable independientemente
7. **Deployment flexible**: Backend deployable en cualquier entorno

### ⚠️ Negativas
1. **Dependencia de red**: Requiere conectividad para funcionar
2. **Latencia**: Operaciones requieren round-trip al servidor
3. **Complejidad de deployment**: Dos componentes a desplegar
4. **Infraestructura adicional**: Requiere servidor para el backend
5. **Punto único de falla**: Backend se convierte en SPOF

### 🔧 Mitigaciones Implementadas
1. **Health checks**: Monitoreo continuo del estado del backend
2. **Manejo de errores robusto**: Feedback claro cuando hay problemas de conectividad
3. **Docker deployment**: Facilita el deployment del backend
4. **Nginx como proxy**: Load balancing y SSL termination
5. **Retry logic**: Reintentos automáticos en caso de errores temporales

## Alternativas Consideradas

### Opción 1: Flutter Nativo Puro
- **Rechazada**: Por las limitaciones de iOS mencionadas
- **Problemas**: Compilación fallida, APIs no disponibles

### Opción 2: Aplicaciones Nativas Separadas
- **Rechazada**: Por complejidad de mantenimiento
- **Problemas**: Duplicación de código, inconsistencias

### Opción 3: Framework Web (PWA)
- **Rechazada**: Por limitaciones en acceso a archivos
- **Problemas**: UX inferior, capacidades limitadas

## Implementación
- **Frontend**: Flutter con Riverpod para state management
- **Backend**: Spring Boot con iText y BouncyCastle
- **Comunicación**: REST APIs con JSON
- **Deployment**: Docker containers con docker-compose
- **Proxy**: Nginx para SSL y load balancing

## Referencias
- [Código fuente backend](../../backend/)
- [Código fuente frontend](../../lib/)
- [Docker configuration](../../backend/docker-compose.yml)
- [Documentación de APIs](../backend/apis.md) 