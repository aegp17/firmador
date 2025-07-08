# ADR-003: Stack Tecnológico del Backend

## Estado
**Aceptado** - Diciembre 2024

## Contexto
Con la decisión de implementar una arquitectura híbrida (ADR-001), se requería seleccionar un stack tecnológico robusto para el backend que manejara operaciones criptográficas, procesamiento de PDFs y APIs REST. Los requisitos principales eran:

1. **Procesamiento criptográfico robusto**: Firma digital de documentos PDF
2. **Manipulación de PDFs**: Lectura, modificación y escritura de archivos PDF
3. **APIs REST**: Endpoints para comunicación con el frontend
4. **Validación de certificados**: Soporte para certificados X.509/PKCS#12
5. **Escalabilidad**: Capacidad de manejar múltiples clientes concurrentes
6. **Docker support**: Facilidad de despliegue en contenedores
7. **Estabilidad**: Stack maduro y bien documentado

## Decisión
Implementar el backend usando el siguiente stack tecnológico:

### Framework Principal: **Spring Boot 3.x**
- Framework maduro y robusto para APIs REST
- Excelente soporte para microservicios
- Configuración por convención
- Amplio ecosistema de dependencias
- Fácil integración con Docker

### Lenguaje: **Java 17**
- LTS (Long Term Support) hasta 2029
- Performance mejorada vs versiones anteriores
- Nuevas características del lenguaje
- Amplio soporte en librerías criptográficas

### Procesamiento PDF: **iText 7.2.5**
- Líder en el mercado para manipulación de PDFs en Java
- Soporte completo para firmas digitales
- Capacidades avanzadas de estampado visual
- Documentación exhaustiva
- Comunidad activa

### Operaciones Criptográficas: **BouncyCastle 1.70**
- Implementación completa de algoritmos criptográficos
- Soporte robusto para certificados X.509
- Compatibilidad con PKCS#12
- Estándar de facto en Java para criptografía
- Actualizaciones regulares de seguridad

### Build Tool: **Maven**
- Gestión de dependencias robusta
- Integración perfecta con Spring Boot
- Soporte Docker nativo
- Amplia adopción en el ecosistema Java

### Serialización: **Jackson**
- Incluido por defecto en Spring Boot
- Soporte JSON completo
- Performance excelente
- Configuración flexible

## Implementación

### Estructura del Proyecto
```
backend/
├── src/main/java/com/firmador/backend/
│   ├── FirmadorBackendApplication.java      # Main application
│   ├── controller/
│   │   └── DigitalSignatureController.java  # REST endpoints
│   ├── service/
│   │   ├── DigitalSignatureService.java     # Core signing logic
│   │   ├── CertificateService.java          # Certificate operations
│   │   └── DocumentStorageService.java      # Document management
│   └── dto/
│       ├── SignatureRequest.java            # Input DTOs
│       ├── SignatureResponse.java           # Output DTOs
│       └── CertificateInfo.java             # Certificate metadata
├── src/main/resources/
│   ├── application.yml                      # Development config
│   └── application-docker.yml               # Production config
├── pom.xml                                  # Maven dependencies
└── Dockerfile                               # Container definition
```

### Dependencias Principales
```xml
<dependencies>
    <!-- Spring Boot Starter -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- iText for PDF processing -->
    <dependency>
        <groupId>com.itextpdf</groupId>
        <artifactId>itext7-core</artifactId>
        <version>7.2.5</version>
    </dependency>
    
    <!-- BouncyCastle for cryptography -->
    <dependency>
        <groupId>org.bouncycastle</groupId>
        <artifactId>bcprov-jdk15on</artifactId>
        <version>1.70</version>
    </dependency>
    
    <!-- Jackson for JSON -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
    </dependency>
</dependencies>
```

## Consecuencias

### ✅ Positivas
1. **Ecosistema maduro**: Todas las librerías tienen años de desarrollo
2. **Documentación excelente**: Abundante documentación y ejemplos
3. **Performance**: Java 17 + Spring Boot ofrecen excelente rendimiento
4. **Seguridad**: BouncyCastle mantenido activamente para vulnerabilidades
5. **Escalabilidad**: Spring Boot permite escalamiento horizontal fácil
6. **Testing**: Framework de testing robusto incluido
7. **Docker support**: Spring Boot optimizado para contenedores
8. **Mantenimiento**: Stack familiar para desarrolladores Java

### ⚠️ Consideraciones
1. **Tamaño del JAR**: Aplicación resultante es relativamente grande (~50MB)
2. **Tiempo de startup**: Spring Boot tiene tiempo de arranque moderado
3. **Memoria**: JVM requiere configuración de memoria adecuada
4. **Licencias**: iText tiene licencia comercial para uso comercial

### 🔧 Configuraciones Específicas

#### Tamaños de Archivo
```yaml
spring:
  servlet:
    multipart:
      max-file-size: 50MB      # Development
      max-request-size: 60MB   # Development
```

#### CORS Configuration
```java
@CrossOrigin(origins = {"http://localhost:*", "https://yourdomain.com"})
```

#### Docker Optimizations
```dockerfile
# Multi-stage build for smaller image
FROM maven:3.9-eclipse-temurin-17 AS build
FROM openjdk:17-jdk-slim
```

## Alternativas Consideradas

### Framework Alternativo: Node.js + Express
- **Rechazada**: Limitaciones en librerías de PDF y criptografía
- **Problemas**: Ecosistema menos maduro para operaciones criptográficas

### Framework Alternativo: .NET Core
- **Rechazada**: Menor experiencia del equipo
- **Problemas**: Licencias y ecosistema menos conocido

### PDF Library Alternativa: PDFBox
- **Rechazada**: Funcionalidades de firma menos robustas que iText
- **Limitaciones**: Menos opciones de estampado visual

### Crypto Library Alternativa: Java Security API nativo
- **Rechazada**: Funcionalidades limitadas comparado con BouncyCastle
- **Problemas**: Menos flexibilidad para certificados complejos

## Versiones y Compatibilidad

### Matriz de Versiones
| Componente | Versión | Motivo de Elección |
|------------|---------|-------------------|
| Java | 17 LTS | Soporte a largo plazo, performance |
| Spring Boot | 3.x | Última versión estable, features modernas |
| iText | 7.2.5 | Versión estable con todas las características |
| BouncyCastle | 1.70 | Compatibilidad con iText, vulnerabilidades resueltas |
| Maven | 3.9+ | Soporte para Java 17 |

### Issues de Compatibilidad Resueltos
1. **BouncyCastle 1.76 → 1.70**: Downgrade por incompatibilidad con iText
2. **Maven image**: Cambio de `maven:3.9.0-openjdk-17` a `maven:3.9-eclipse-temurin-17`

## Métricas de Performance

### Tiempo de Procesamiento (Promedio)
- **Validación de certificado**: ~500ms
- **Firma de PDF (1MB)**: ~2-3 segundos
- **Extracción de info de certificado**: ~300ms

### Uso de Recursos
- **RAM**: ~512MB-1GB en ejecución
- **CPU**: Picos durante operaciones criptográficas
- **Disco**: ~50MB para la aplicación + archivos temporales

## Referencias
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [iText PDF Library](https://itextpdf.com/)
- [BouncyCastle Crypto APIs](https://www.bouncycastle.org/)
- [Código fuente completo](../../backend/)
- [Configuración Docker](../../backend/docker-compose.yml) 