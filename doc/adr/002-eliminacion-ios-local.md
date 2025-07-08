# ADR-002: Eliminación del Procesamiento Local iOS

## Estado
**Aceptado** - Diciembre 2024

## Contexto
Durante el desarrollo inicial de Firmador, se implementó procesamiento local de firma digital para iOS utilizando el Security Framework de Apple. El objetivo era tener una aplicación completamente nativa sin dependencias externas. Sin embargo, se encontraron múltiples problemas técnicos insuperables:

### Problemas Identificados

#### 1. Errores de Compilación Persistentes
```bash
Failed to build iOS app
Uncategorized (Xcode): Command CodeSign failed with a nonzero exit code
Could not build the application for the simulator.
Error launching application on iPhone 16 Plus.
```

#### 2. APIs y Constantes No Disponibles
El código en `CertificateHelper.m` utilizaba constantes que no están públicamente disponibles:
```objc
// Estas constantes causaban errores de compilación
kSecPropertyKeyValue
kSecOIDX509V1SerialNumber
kSecOIDCommonName
kSecOIDEmailAddress
```

#### 3. Limitaciones del Security Framework
- Acceso restringido a detalles internos de certificados
- APIs privadas no documentadas
- Comportamiento inconsistente entre versiones de iOS
- Limitaciones en el parsing de estructuras ASN.1

#### 4. Complejidad de Implementación Nativa
- Código complejo en Objective-C para parsing manual
- Lógica duplicada entre iOS y Android
- Mantenimiento difícil y propenso a errores
- Testing complicado en diferentes versiones de iOS

### Impacto en el Desarrollo
- **Tiempo perdido**: Semanas intentando resolver problemas de iOS
- **Inconsistencia**: Diferentes resultados entre plataformas
- **Frustración del desarrollador**: Bloqueo constante por limitaciones de iOS
- **Calidad del código**: Workarounds complejos y frágiles

## Decisión
**Eliminar completamente el procesamiento local de firma digital en iOS** y migrar toda la funcionalidad criptográfica al backend.

### Cambios Implementados

#### 1. Removal de Código iOS Problemático
- Eliminación de `CertificateHelper.m` complejo
- Removal de dependencias en constantes no disponibles
- Simplificación radical del código iOS

#### 2. Delegación al Backend
- Todas las operaciones criptográficas se realizan en el servidor
- iOS actúa únicamente como cliente de UI
- Comunicación vía REST APIs

#### 3. Nuevo CertificateHelper Simplificado
```objc
// Implementación minimalista que solo maneja lo básico
@implementation CertificateHelper
+ (BOOL)isValidP12Data:(NSData *)data withPassword:(NSString *)password {
    // Validación básica sin acceso a detalles internos
}
@end
```

## Consecuencias

### ✅ Positivas
1. **Compilación exitosa**: Elimina todos los errores de CodeSign
2. **Mantenimiento simplificado**: Código iOS mínimo y estable
3. **Consistencia total**: Mismo comportamiento en iOS y Android
4. **Robustez**: Sin dependencias en APIs privadas o no documentadas
5. **Escalabilidad**: Lógica centralizada fácil de actualizar
6. **Testing mejorado**: Backend testeable independientemente
7. **Seguridad**: Operaciones criptográficas en entorno controlado

### ⚠️ Negativas
1. **Dependencia de red**: iOS requiere conectividad obligatoria
2. **Latencia adicional**: Round-trip al servidor para cada operación
3. **Funcionalidad reducida offline**: No funciona sin internet
4. **Arquitectura más compleja**: Requiere backend adicional

### 📊 Comparación de Código

#### Antes (iOS Local)
```objc
// 300+ líneas de código complejo en CertificateHelper.m
// Manejo manual de estructuras ASN.1
// Parsing de OIDs y certificados
// Dependencias en APIs privadas
```

#### Después (iOS Cliente)
```objc
// 50 líneas de código simple
// Solo validación básica de archivos
// Delegación completa al backend
// Uso solo de APIs públicas
```

## Alternativas Consideradas

### Opción 1: Continuar con iOS Nativo
- **Rechazada**: Problemas técnicos insuperables
- **Tiempo estimado**: Semanas/meses adicionales
- **Riesgo**: Alto, sin garantía de solución

### Opción 2: Usar Librerías Terceras iOS
- **Rechazada**: Limitaciones similares del sistema
- **Problemas**: Dependencias externas, costos de licencia

### Opción 3: Solo Android Nativo
- **Rechazada**: Perdería mercado iOS
- **Impacto**: Reducción significativa de usuarios potenciales

### Opción 4: Web App Híbrida
- **Rechazada**: UX inferior
- **Limitaciones**: Acceso limitado a archivos

## Implementación

### Pasos Ejecutados
1. **Backup del código original**: Preservado para referencia
2. **Simplificación de CertificateHelper**: Reducido a funcionalidad básica
3. **Integración con backend**: Cliente HTTP para todas las operaciones
4. **Testing exhaustivo**: Verificación en múltiples dispositivos iOS
5. **Documentación**: ADRs y guías de desarrollo actualizadas

### Código Eliminado
- Parsing manual de certificados X.509
- Extracción de metadatos del certificado
- Validación criptográfica local
- Manejo de estructuras ASN.1
- Dependencias en Security Framework privado

### Funcionalidad Preservada
- Selección de archivos de certificado
- Validación básica de formato P12
- UI/UX completa de la aplicación
- Integración con backend para todas las operaciones

## Métricas de Éxito

### Antes de la Decisión
- ❌ Compilación iOS: **Fallida**
- ❌ Funcionalidad: **Inconsistente**
- ❌ Mantenimiento: **Muy Difícil**
- ❌ Testing: **Imposible**

### Después de la Decisión
- ✅ Compilación iOS: **Exitosa**
- ✅ Funcionalidad: **Consistente**
- ✅ Mantenimiento: **Fácil**
- ✅ Testing: **Automatizable**

## Referencias
- [ADR-001: Arquitectura Híbrida](001-arquitectura-hibrida.md)
- [Backend APIs Documentation](../backend/apis.md)
- [Código iOS original](../../ios/CertificateHelper.m)
- [Configuración Docker](../../backend/docker-compose.yml) 