# Deployment del Backend

## Resumen
El backend de Firmador se puede desplegar usando Docker containers o directamente como aplicación Java. Esta guía cubre ambos métodos y las configuraciones necesarias.

## Deployment con Docker (Recomendado)

### 1. Configuración Docker

#### Dockerfile
```dockerfile
# Multi-stage build para optimizar tamaño
FROM maven:3.9-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:17-jdk-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=build /app/target/firmador-backend-*.jar app.jar

# Create non-root user
RUN groupadd -r firmador && useradd -r -g firmador firmador
RUN chown firmador:firmador /app
USER firmador

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/api/signature/health || exit 1

# Run application
CMD ["java", "-jar", "app.jar", "--spring.profiles.active=docker"]
```

#### docker-compose.yml
```yaml
version: '3.8'

services:
  firmador-backend:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: firmador-backend
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - JAVA_OPTS=-Xmx1g -Xms512m
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/signature/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    container_name: firmador-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - firmador-backend
    restart: unless-stopped

volumes:
  logs:
```

#### nginx.conf
```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    # Upstream backend
    upstream backend {
        server firmador-backend:8080;
    }

    server {
        listen 80;
        server_name your-domain.com;
        
        # Redirect HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/certificate.crt;
        ssl_certificate_key /etc/nginx/ssl/private.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

        # CORS headers
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";

        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }

        # Client max body size (for file uploads)
        client_max_body_size 100M;

        # Proxy settings
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # API endpoints
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Health check endpoint (no rate limiting)
        location /api/signature/health {
            proxy_pass http://backend;
        }
    }
}
```

### 2. Comandos de Deployment

#### Build y Deploy
```bash
# Construir imagen
docker-compose build

# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f firmador-backend

# Detener servicios
docker-compose down

# Reiniciar servicios
docker-compose restart

# Actualizar aplicación
docker-compose pull
docker-compose up -d --build
```

#### Monitoreo
```bash
# Estado de contenedores
docker-compose ps

# Uso de recursos
docker stats

# Health check manual
curl http://localhost:8080/api/signature/health

# Logs en tiempo real
docker-compose logs -f --tail=100
```

## Deployment Directo (Java)

### 1. Requisitos del Sistema
- **Java 17 o superior**
- **Maven 3.6 o superior**
- **Mínimo 1GB RAM**
- **50GB espacio en disco**

### 2. Proceso de Build
```bash
# Clonar repositorio
git clone https://github.com/your-org/firmador.git
cd firmador/backend

# Build del proyecto
mvn clean package -DskipTests

# El JAR se genera en: target/firmador-backend-1.0.0.jar
```

### 3. Configuración de Producción

#### application-prod.yml
```yaml
server:
  port: 8080
  servlet:
    context-path: /

spring:
  application:
    name: firmador-backend
  profiles:
    active: prod
  servlet:
    multipart:
      max-file-size: 100MB
      max-request-size: 120MB

logging:
  level:
    com.firmador.backend: INFO
    org.springframework.web: WARN
  file:
    name: logs/firmador-backend.log
  pattern:
    file: "%d{ISO8601} [%thread] %-5level %logger{36} - %msg%n"
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"

management:
  endpoints:
    web:
      exposure:
        include: health,metrics,info
  endpoint:
    health:
      show-details: when-authorized
```

### 4. Scripts de Deployment

#### start-backend.sh
```bash
#!/bin/bash

# Script para iniciar el backend en producción

APP_NAME="firmador-backend"
JAR_FILE="target/firmador-backend-1.0.0.jar"
PID_FILE="/var/run/${APP_NAME}.pid"
LOG_FILE="logs/${APP_NAME}.log"

# Configuración JVM
JAVA_OPTS="-Xmx1g -Xms512m"
JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=prod"
JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"

# Crear directorio de logs
mkdir -p logs

# Verificar si ya está ejecutándose
if [ -f $PID_FILE ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "$APP_NAME ya está ejecutándose (PID: $PID)"
        exit 1
    else
        rm -f $PID_FILE
    fi
fi

# Iniciar aplicación
echo "Iniciando $APP_NAME..."
nohup java $JAVA_OPTS -jar $JAR_FILE > $LOG_FILE 2>&1 &
echo $! > $PID_FILE

echo "$APP_NAME iniciado con PID: $(cat $PID_FILE)"
```

#### stop-backend.sh
```bash
#!/bin/bash

APP_NAME="firmador-backend"
PID_FILE="/var/run/${APP_NAME}.pid"

if [ -f $PID_FILE ]; then
    PID=$(cat $PID_FILE)
    echo "Deteniendo $APP_NAME (PID: $PID)..."
    kill $PID
    
    # Esperar hasta 30 segundos para que se detenga
    for i in {1..30}; do
        if ! ps -p $PID > /dev/null 2>&1; then
            echo "$APP_NAME detenido exitosamente"
            rm -f $PID_FILE
            exit 0
        fi
        sleep 1
    done
    
    # Force kill si no se detuvo
    echo "Forzando detención de $APP_NAME..."
    kill -9 $PID
    rm -f $PID_FILE
    echo "$APP_NAME detenido forzadamente"
else
    echo "$APP_NAME no está ejecutándose"
fi
```

## Configuraciones de Producción

### 1. Variables de Entorno
```bash
# Configuración de aplicación
export SPRING_PROFILES_ACTIVE=prod
export SERVER_PORT=8080

# Configuración JVM
export JAVA_OPTS="-Xmx1g -Xms512m"

# Configuración de logs
export LOG_LEVEL=INFO
export LOG_FILE=logs/firmador-backend.log

# Configuración de archivos
export MAX_FILE_SIZE=100MB
export MAX_REQUEST_SIZE=120MB
```

### 2. Systemd Service

#### /etc/systemd/system/firmador-backend.service
```ini
[Unit]
Description=Firmador Backend Service
After=network.target

[Service]
Type=simple
User=firmador
Group=firmador
WorkingDirectory=/opt/firmador
ExecStart=/usr/bin/java -Xmx1g -Xms512m -Dspring.profiles.active=prod -jar firmador-backend-1.0.0.jar
Restart=always
RestartSec=10

# Environment
Environment=SPRING_PROFILES_ACTIVE=prod
Environment=JAVA_OPTS=-Xmx1g -Xms512m

# Logging
StandardOutput=append:/var/log/firmador/backend.log
StandardError=append:/var/log/firmador/backend-error.log

# Security
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/firmador/logs
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

#### Comandos de Systemd
```bash
# Habilitar servicio
sudo systemctl enable firmador-backend

# Iniciar servicio
sudo systemctl start firmador-backend

# Ver estado
sudo systemctl status firmador-backend

# Ver logs
sudo journalctl -u firmador-backend -f

# Reiniciar servicio
sudo systemctl restart firmador-backend

# Detener servicio
sudo systemctl stop firmador-backend
```

## Monitoreo y Logs

### 1. Health Checks
```bash
# Health check básico
curl http://localhost:8080/api/signature/health

# Health check con detalles
curl http://localhost:8080/actuator/health

# Métricas de aplicación
curl http://localhost:8080/actuator/metrics
```

### 2. Configuración de Logs

#### logback-spring.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>

    <springProfile name="!prod">
        <include resource="org/springframework/boot/logging/logback/console-appender.xml"/>
        <root level="INFO">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>

    <springProfile name="prod">
        <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <file>logs/firmador-backend.log</file>
            <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
                <fileNamePattern>logs/firmador-backend-%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
                <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                    <maxFileSize>100MB</maxFileSize>
                </timeBasedFileNamingAndTriggeringPolicy>
                <maxHistory>30</maxHistory>
                <totalSizeCap>3GB</totalSizeCap>
            </rollingPolicy>
            <encoder>
                <pattern>%d{ISO8601} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>

        <root level="INFO">
            <appender-ref ref="FILE"/>
        </root>
    </springProfile>

    <logger name="com.firmador.backend" level="DEBUG" additivity="false">
        <appender-ref ref="FILE"/>
    </logger>
</configuration>
```

### 3. Métricas y Alertas

#### Configuración Prometheus (Opcional)
```yaml
# application-prod.yml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  endpoint:
    metrics:
      enabled: true
    prometheus:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
```

## Troubleshooting

### Problemas Comunes

#### 1. Error de Memoria
```bash
# Síntoma: OutOfMemoryError
# Solución: Aumentar memoria heap
export JAVA_OPTS="-Xmx2g -Xms1g"
```

#### 2. Archivos Muy Grandes
```bash
# Síntoma: PayloadTooLargeException
# Solución: Aumentar límites en application.yml
spring:
  servlet:
    multipart:
      max-file-size: 200MB
      max-request-size: 220MB
```

#### 3. Puerto Ocupado
```bash
# Verificar qué proceso usa el puerto
sudo lsof -i :8080

# Cambiar puerto
export SERVER_PORT=8081
```

#### 4. Certificados SSL
```bash
# Verificar certificado
openssl x509 -in certificate.crt -text -noout

# Verificar clave privada
openssl rsa -in private.key -check
```

### Logs de Depuración
```bash
# Activar logs de debug temporalmente
curl -X POST http://localhost:8080/actuator/loggers/com.firmador.backend \
  -H 'Content-Type: application/json' \
  -d '{"configuredLevel": "DEBUG"}'
```

## Referencias
- [Spring Boot Production](https://docs.spring.io/spring-boot/docs/current/reference/html/deployment.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [Systemd Services](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [Scripts de deployment](../../backend/) 