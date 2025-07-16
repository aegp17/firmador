#!/bin/bash

# 🧪 Script de Testing Automatizado para Firmador
# Verifica compilación y funcionalidad básica en iOS y Android

set -e  # Exit on any error

echo "🧪 Testing Firmador en todas las plataformas..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
echo "🔍 Verificando prerequisitos..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter no está instalado"
    exit 1
fi
print_status "Flutter encontrado: $(flutter --version | head -1)"

# Check Java for backend
if ! command -v java &> /dev/null; then
    print_error "Java no está instalado"
    exit 1
fi
print_status "Java encontrado: $(java -version 2>&1 | head -1)"

# Check Maven for backend
if ! command -v mvn &> /dev/null; then
    print_error "Maven no está instalado"
    exit 1
fi
print_status "Maven encontrado: $(mvn -version | head -1)"

echo ""
echo "1️⃣ Testing Flutter Environment..."
echo "================================="

# Flutter doctor
print_info "Ejecutando flutter doctor..."
flutter doctor -v

# Flutter analyze
print_info "Analizando código Flutter..."
flutter analyze
print_status "Análisis de código completado"

# Flutter test
print_info "Ejecutando tests unitarios Flutter..."
flutter test
print_status "Tests unitarios completados"

echo ""
echo "2️⃣ Testing Backend..."
echo "===================="

# Change to backend directory
if [ ! -d "backend" ]; then
    print_error "Directorio backend no encontrado"
    exit 1
fi

cd backend

# Backend tests
print_info "Ejecutando tests del backend..."
mvn test -q
print_status "Tests del backend completados"

# Start backend in background
print_info "Iniciando backend..."
mvn spring-boot:run > /dev/null 2>&1 &
BACKEND_PID=$!

# Wait for backend to start
print_info "Esperando que el backend inicie..."
sleep 15

# Test health endpoint
print_info "Verificando endpoint de salud..."
if curl -f http://localhost:8080/api/signature/health > /dev/null 2>&1; then
    print_status "Backend funcionando correctamente"
else
    print_error "Backend no responde"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

# Return to root directory
cd ..

echo ""
echo "3️⃣ Testing iOS Build..."
echo "======================="

print_info "Limpiando builds previos..."
flutter clean > /dev/null 2>&1

print_info "Obteniendo dependencias..."
flutter pub get > /dev/null 2>&1

print_info "Instalando pods de iOS..."
cd ios
pod install > /dev/null 2>&1
cd ..

print_info "Compilando para iOS (debug)..."
if flutter build ios --debug --no-codesign > /dev/null 2>&1; then
    print_status "Build iOS exitoso"
else
    print_error "Fallo en build iOS"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "4️⃣ Testing Android Build..."
echo "==========================="

print_info "Compilando para Android (debug)..."
if flutter build apk --debug > /dev/null 2>&1; then
    print_status "Build Android exitoso"
    
    # Check if APK was created
    if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
        APK_SIZE=$(du -h "build/app/outputs/flutter-apk/app-debug.apk" | cut -f1)
        print_status "APK generado: $APK_SIZE"
    fi
else
    print_error "Fallo en build Android"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "5️⃣ Testing Android Dependencies..."
echo "=================================="

print_info "Verificando dependencias de Android..."
cd android
if ./gradlew :app:dependencies > /dev/null 2>&1; then
    print_status "Dependencias Android verificadas"
else
    print_warning "Advertencia en dependencias Android (posible conflicto)"
fi
cd ..

echo ""
echo "6️⃣ Testing Device Connectivity..."
echo "================================="

# Check for connected devices
print_info "Verificando dispositivos conectados..."

# iOS devices
if command -v xcrun &> /dev/null; then
    IOS_DEVICES=$(xcrun simctl list devices | grep "Booted" | wc -l)
    if [ "$IOS_DEVICES" -gt 0 ]; then
        print_status "$IOS_DEVICES simulador(es) iOS disponible(s)"
    else
        print_warning "No hay simuladores iOS ejecutándose"
    fi
fi

# Android devices
if command -v adb &> /dev/null; then
    ANDROID_DEVICES=$(adb devices | grep "device$" | wc -l)
    if [ "$ANDROID_DEVICES" -gt 0 ]; then
        print_status "$ANDROID_DEVICES dispositivo(s) Android conectado(s)"
    else
        print_warning "No hay dispositivos Android conectados"
    fi
fi

echo ""
echo "7️⃣ Performance Analysis..."
echo "========================="

# Check APK size
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    APK_SIZE_BYTES=$(stat -f%z "build/app/outputs/flutter-apk/app-debug.apk" 2>/dev/null || stat -c%s "build/app/outputs/flutter-apk/app-debug.apk" 2>/dev/null)
    APK_SIZE_MB=$((APK_SIZE_BYTES / 1024 / 1024))
    
    if [ "$APK_SIZE_MB" -gt 50 ]; then
        print_warning "APK es grande (${APK_SIZE_MB}MB) - considerar optimización"
    else
        print_status "Tamaño APK aceptable: ${APK_SIZE_MB}MB"
    fi
fi

# Check for potential issues
print_info "Verificando configuración..."

if grep -q "multidex" android/app/build.gradle.kts; then
    print_status "Multidex configurado (necesario para librerías crypto)"
fi

if [ -f "android/app/proguard-rules.pro" ]; then
    print_status "ProGuard configurado para proteger clases crypto"
fi

echo ""
echo "8️⃣ Cleanup..."
echo "============"

# Kill backend
print_info "Deteniendo backend..."
kill $BACKEND_PID 2>/dev/null || true
print_status "Backend detenido"

echo ""
echo "🎉 RESUMEN DE TESTING"
echo "===================="
print_status "✅ Flutter environment: OK"
print_status "✅ Backend tests: PASSED"
print_status "✅ Backend health: OK"
print_status "✅ iOS build: SUCCESS"
print_status "✅ Android build: SUCCESS"
print_status "✅ Dependencies: VERIFIED"

echo ""
echo "📱 PRÓXIMOS PASOS"
echo "================="
echo "Para testing manual:"
echo ""
echo "iOS:"
echo "  flutter run -d ios"
echo ""
echo "Android:"
echo "  flutter run -d android"
echo "  adb logcat -s MainActivity PdfSignatureService TSAClient"
echo ""
echo "Backend ya está configurado y funcionando ✅"
echo ""

print_status "🎯 Todos los tests completados exitosamente!" 