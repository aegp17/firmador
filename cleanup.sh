#!/bin/bash

# Firmador - Cleanup Script
# This script stops all services and cleans up development artifacts

set -e

echo "🧹 Cleaning up Firmador Development Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Parse command line arguments
DEEP_CLEAN=false
CLEAN_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --deep)
            DEEP_CLEAN=true
            shift
            ;;
        --docker)
            CLEAN_DOCKER=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --deep    Deep clean (remove build artifacts, node_modules, etc.)"
            echo "  --docker  Clean Docker containers and images"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_step "Stopping running processes..."

# Stop Docker containers
if command -v docker &> /dev/null; then
    print_status "Stopping Docker containers..."
    
    # Stop and remove development containers
    docker stop firmador-backend-dev 2>/dev/null || true
    docker rm firmador-backend-dev 2>/dev/null || true
    
    # Stop docker-compose services
    if [ -f "backend/docker-compose.yml" ]; then
        cd backend
        docker-compose down 2>/dev/null || true
        cd ..
    fi
    
    if [ "$CLEAN_DOCKER" = true ]; then
        print_status "Cleaning Docker images..."
        docker rmi firmador-backend 2>/dev/null || true
        docker system prune -f
    fi
fi

# Kill any remaining Java processes (Spring Boot)
print_status "Stopping Java processes..."
pkill -f "spring-boot:run" 2>/dev/null || true
pkill -f "firmador-backend" 2>/dev/null || true

# Kill any remaining Flutter processes
print_status "Stopping Flutter processes..."
pkill -f "flutter" 2>/dev/null || true

# Kill any processes using port 8080
print_status "Freeing port 8080..."
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Clean up logs
print_status "Cleaning up logs..."
rm -rf logs/
mkdir -p logs

# Deep clean if requested
if [ "$DEEP_CLEAN" = true ]; then
    print_step "Performing deep clean..."
    
    # Clean Maven artifacts
    if [ -d "backend" ]; then
        print_status "Cleaning Maven artifacts..."
        cd backend
        mvn clean 2>/dev/null || true
        rm -rf target/
        cd ..
    fi
    
    # Clean Flutter artifacts
    print_status "Cleaning Flutter artifacts..."
    flutter clean 2>/dev/null || true
    rm -rf build/
    rm -rf .dart_tool/
    rm -rf ios/Pods/
    rm -rf ios/Podfile.lock
    rm -rf android/.gradle/
    rm -rf android/app/build/
    
    # Clean Flutter pub cache (optional)
    # flutter pub cache clean
    
    print_status "Cleaning temporary files..."
    rm -rf /tmp/firmador-*
    
    print_status "Deep clean completed!"
fi

print_step "Cleanup completed!"

# Show status
echo ""
print_status "All services stopped and cleaned up."
print_status "You can now run ./start-dev.sh to start fresh."
echo ""

# Check if any processes are still running
if pgrep -f "spring-boot:run" > /dev/null; then
    print_warning "Some Spring Boot processes may still be running."
    print_warning "You may need to kill them manually: pkill -f spring-boot:run"
fi

if pgrep -f "flutter" > /dev/null; then
    print_warning "Some Flutter processes may still be running."
    print_warning "You may need to kill them manually: pkill -f flutter"
fi

if lsof -ti:8080 > /dev/null 2>&1; then
    print_warning "Port 8080 is still in use. You may need to kill the process manually."
    print_warning "Check with: lsof -ti:8080"
fi

echo "✨ Cleanup complete!" 