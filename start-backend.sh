#!/bin/bash

# Firmador Backend - Docker Compose Startup Script
echo "🚀 Starting Firmador Backend with Docker Compose..."

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Parse arguments
REBUILD=false
DETACH=true
LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --foreground)
            DETACH=false
            shift
            ;;
        --logs)
            LOGS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --rebuild      Force rebuild of Docker images"
            echo "  --foreground   Run in foreground (default: background)"
            echo "  --logs         Show logs after starting"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to cleanup on exit
cleanup() {
    print_step "Stopping backend..."
    docker-compose down
    exit 0
}

# Set trap for cleanup
if [ "$DETACH" = false ]; then
    trap cleanup SIGINT SIGTERM
fi

# Stop any existing containers
print_step "Stopping existing containers..."
docker-compose down

# Build and start
if [ "$REBUILD" = true ]; then
    print_step "Rebuilding and starting backend..."
    docker-compose up --build $([ "$DETACH" = true ] && echo "-d")
else
    print_step "Starting backend..."
    docker-compose up $([ "$DETACH" = true ] && echo "-d")
fi

if [ $? -eq 0 ]; then
    if [ "$DETACH" = true ]; then
        print_step "Waiting for backend to be ready..."
        for i in {1..30}; do
            if curl -s http://localhost:8080/api/signature/health > /dev/null 2>&1; then
                print_info "✅ Backend is ready at http://localhost:8080"
                break
            fi
            if [ $i -eq 30 ]; then
                print_error "Backend failed to start within 30 seconds"
                docker-compose logs backend
                exit 1
            fi
            sleep 1
        done
        
        print_info "📋 Useful commands:"
        print_info "  View logs: docker-compose logs -f backend"
        print_info "  Stop backend: docker-compose down"
        print_info "  Restart: docker-compose restart backend"
        
        if [ "$LOGS" = true ]; then
            print_step "Showing logs (Ctrl+C to exit)..."
            docker-compose logs -f backend
        fi
    fi
else
    print_error "Failed to start backend"
    exit 1
fi 