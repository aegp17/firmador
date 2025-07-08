#!/bin/bash

# Simple script to run the backend
echo "🚀 Starting Firmador Backend..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Docker is available
if command -v docker &> /dev/null && docker info &> /dev/null; then
    print_step "Using Docker to run backend..."
    
    # Stop any existing container
    docker stop firmador-backend 2>/dev/null || true
    docker rm firmador-backend 2>/dev/null || true
    
    # Build and run
    cd backend
    print_step "Building Docker image..."
    docker build -t firmador-backend .
    
    if [ $? -eq 0 ]; then
        print_step "Starting backend container..."
        docker run -d --name firmador-backend -p 8080:8080 firmador-backend
        
        # Wait for health check
        print_step "Waiting for backend to be ready..."
        for i in {1..30}; do
            if curl -s http://localhost:8080/api/signature/health > /dev/null 2>&1; then
                print_info "✅ Backend is ready at http://localhost:8080"
                break
            fi
            if [ $i -eq 30 ]; then
                print_error "Backend failed to start within 30 seconds"
                docker logs firmador-backend
                exit 1
            fi
            sleep 1
        done
        
        print_info "Backend logs: docker logs firmador-backend"
        print_info "Stop backend: docker stop firmador-backend"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
elif command -v java &> /dev/null && command -v mvn &> /dev/null; then
    print_step "Using local Java/Maven to run backend..."
    
    cd backend
    print_step "Installing dependencies..."
    mvn clean install -DskipTests
    
    if [ $? -eq 0 ]; then
        print_step "Starting Spring Boot application..."
        mvn spring-boot:run
    else
        print_error "Failed to install Maven dependencies"
        exit 1
    fi
    
else
    print_error "Neither Docker nor Java/Maven is properly installed"
    print_info "Please install either:"
    print_info "1. Docker: https://docs.docker.com/get-docker/"
    print_info "2. Java 17+ and Maven 3.6+: https://maven.apache.org/install.html"
    exit 1
fi 