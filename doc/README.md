# 📚 Documentación Firmador

Esta carpeta contiene toda la documentación técnica del proyecto Firmador, una aplicación híbrida de firma digital que combina Flutter y Spring Boot.

## 📋 Índice de Documentación

### 🏗️ Arquitectura y Decisiones (ADR)
Los Architecture Decision Records documentan todas las decisiones técnicas importantes:

- [ADR-001: Arquitectura Híbrida Flutter + Spring Boot](adr/001-arquitectura-hibrida.md)
- [ADR-002: Eliminación del Procesamiento Local iOS](adr/002-eliminacion-ios-local.md)
- [ADR-003: Stack Tecnológico del Backend](adr/003-stack-backend.md)
- [ADR-004: Stack Tecnológico del Frontend](adr/004-stack-frontend.md)
- [ADR-005: Eliminación del Campo Email](adr/005-eliminacion-campo-email.md)
- [ADR-006: Implementación de Previsualización PDF](adr/006-previsualizacion-pdf.md)
- [ADR-007: Persistencia de Datos del Usuario](adr/007-persistencia-datos-usuario.md)
- [ADR-008: Monitoreo Automático del Servidor](adr/008-monitoreo-automatico-servidor.md)

### 🚀 Backend Documentation
Documentación específica del backend Spring Boot:

- [Arquitectura del Backend](backend/arquitectura.md)
- [APIs y Endpoints](backend/apis.md)
- [Configuración y Deployment](backend/deployment.md)
- [Testing del Backend](backend/testing.md)

### 📱 Frontend Documentation
Documentación específica del frontend Flutter:

- [Arquitectura del Frontend](frontend/arquitectura.md)
- [Gestión de Estado](frontend/state-management.md)
- [Componentes y Pantallas](frontend/components.md)
- [Testing del Frontend](frontend/testing.md)

## 🎯 Resumen de Decisiones Técnicas

### Arquitectura Principal
- **Híbrida**: Frontend Flutter + Backend Spring Boot
- **Comunicación**: APIs REST con formato JSON
- **Deployment**: Docker con nginx como proxy

### Backend (Spring Boot)
- **Lenguaje**: Java 17
- **Framework**: Spring Boot 3.x
- **Firma PDF**: iText 7.2.5 + BouncyCastle 1.70
- **Build**: Maven
- **Containerización**: Docker multi-stage

### Frontend (Flutter)
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **PDF Viewer**: Syncfusion Flutter PDF Viewer
- **File Picker**: file_picker plugin
- **Persistencia**: SharedPreferences
- **URL Launcher**: url_launcher

### Mejoras UX Implementadas
- ✅ Previsualización de documentos PDF
- ✅ Selección visual de posición de firma
- ✅ Persistencia de datos del usuario
- ✅ Monitoreo automático del servidor (cada 2 minutos)
- ✅ Eliminación del campo email del formulario

## 🔄 Proceso de Actualización de Documentación

1. **Para nuevas decisiones técnicas**: Crear nuevo ADR en `adr/`
2. **Para cambios en backend**: Actualizar documentación en `backend/`
3. **Para cambios en frontend**: Actualizar documentación en `frontend/`
4. **Para cambios arquitectónicos**: Actualizar este README

## 🏷️ Convenciones

### Formato ADR
Seguimos el formato estándar ADR:
- **Título**: Decisión tomada
- **Estado**: Aceptado/Rechazado/Superseded
- **Contexto**: Situación que requiere la decisión
- **Decisión**: Qué se decidió hacer
- **Consecuencias**: Efectos positivos y negativos

### Versionado de Documentación
- La documentación se versiona junto con el código
- Los ADRs nunca se modifican, solo se marcan como superseded
- Los cambios importantes se reflejan en nuevos ADRs

---

📝 **Última actualización**: Diciembre 2024  
👥 **Mantenido por**: Equipo de Desarrollo Firmador 