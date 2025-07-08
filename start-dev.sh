#!/bin/bash

# Firmador - Development Startup Script
# This script starts both backend and frontend in development mode

set -e

echo "🚀 Starting Firmador Development Environment..."

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

# Parse command line arguments first
MODE="local"
SKIP_BACKEND=false
SKIP_FRONTEND=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --docker)
            MODE="docker"
            shift
            ;;
        --skip-backend)
            SKIP_BACKEND=true
            shift
            ;;
        --skip-frontend)
            SKIP_FRONTEND=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --docker         Use Docker to run the backend"
            echo "  --skip-backend   Skip starting the backend"
            echo "  --skip-frontend  Skip starting the frontend"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check dependencies based on mode
print_step "Checking dependencies..."

# Always check Flutter if not skipping frontend
if [ "$SKIP_FRONTEND" = false ]; then
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter 3.0 or higher."
        exit 1
    fi
fi

# Check backend dependencies based on mode
if [ "$SKIP_BACKEND" = false ]; then
    if [ "$MODE" = "docker" ]; then
        # For Docker mode, only check Docker
        if ! command -v docker &> /dev/null; then
            print_error "Docker is not installed. Please install Docker and try again."
            exit 1
        fi
        
        # Check if Docker is running
        if ! docker info &> /dev/null; then
            print_error "Docker is not running. Please start Docker and try again."
            exit 1
        fi
        
        print_status "Docker is ready for backend"
    else
        # For local mode, check Java and Maven
        if ! command -v java &> /dev/null; then
            print_error "Java is not installed. Please install Java 17 or higher."
            exit 1
        fi
        
        if ! command -v mvn &> /dev/null; then
            print_error "Maven is not installed. Please install Maven 3.6 or higher."
            print_warning "Alternatively, use --docker flag to run backend in Docker container"
            exit 1
        fi
        
        print_status "Java and Maven are ready for backend"
    fi
fi

# Create logs directory
mkdir -p logs

# Function to cleanup background processes
cleanup() {
    print_step "Cleaning up background processes..."
    
    # Kill background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Stop and remove Docker containers if they exist
    if [ "$MODE" = "docker" ] && [ "$SKIP_BACKEND" = false ]; then
        print_status "Stopping Docker containers..."
        docker stop firmador-backend-dev 2>/dev/null || true
        docker rm firmador-backend-dev 2>/dev/null || true
    fi
    
    exit 0
}

# Set trap to cleanup on exit
trap cleanup SIGINT SIGTERM

# Start Backend
if [ "$SKIP_BACKEND" = false ]; then
    print_step "Starting Backend..."
    
    if [ "$MODE" = "docker" ]; then
        print_status "Using Docker for backend..."
        cd backend
        
        # Stop and remove any existing container
        print_status "Cleaning up existing containers..."
        docker stop firmador-backend-dev 2>/dev/null || true
        docker rm firmador-backend-dev 2>/dev/null || true
        
        # Build and run with Docker
        print_status "Building Docker image..."
        docker build -t firmador-backend . || {
            print_error "Failed to build Docker image"
            exit 1
        }
        
        print_status "Starting backend container..."
        docker run -d --name firmador-backend-dev -p 8080:8080 firmador-backend || {
            print_error "Failed to start backend container"
            exit 1
        }
        
        cd ..
        print_status "Backend started in Docker container"
        
    else
        print_status "Using local Java for backend..."
        cd backend
        
        # Check if Maven dependencies are up to date
        print_status "Installing/updating Maven dependencies..."
        mvn clean install -DskipTests || {
            print_error "Failed to install Maven dependencies"
            exit 1
        }
        
        # Start Spring Boot application in background
        print_status "Starting Spring Boot application..."
        mvn spring-boot:run > ../logs/backend.log 2>&1 &
        BACKEND_PID=$!
        
        cd ..
        print_status "Backend started with PID: $BACKEND_PID"
    fi
    
    # Wait for backend to be ready
    print_status "Waiting for backend to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8080/api/signature/health > /dev/null 2>&1; then
            print_status "Backend is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Backend failed to start within 30 seconds"
            if [ "$MODE" = "docker" ]; then
                docker stop firmador-backend-dev 2>/dev/null || true
                docker rm firmador-backend-dev 2>/dev/null || true
            fi
            exit 1
        fi
        sleep 1
    done
fi

# Start Frontend
if [ "$SKIP_FRONTEND" = false ]; then
    print_step "Starting Frontend..."
    
    # Install Flutter dependencies
    print_status "Installing Flutter dependencies..."
    flutter pub get || {
        print_error "Failed to install Flutter dependencies"
        exit 1
    }
    
    # Check for connected devices
    print_status "Checking for connected devices..."
    flutter devices
    
    # Ask user which device to use
    echo ""
    print_status "Starting Flutter app..."
    print_warning "This will open the Flutter app. Choose your target device when prompted."
    
    # Start Flutter app
    flutter run &
    FLUTTER_PID=$!
    
    print_status "Frontend started with PID: $FLUTTER_PID"
fi

# Show status
echo ""
print_step "🎉 Development Environment Started Successfully!"
echo ""
print_status "Backend: http://localhost:8080"
print_status "Backend Health: http://localhost:8080/api/signature/health"
if [ "$MODE" = "local" ]; then
    print_status "Backend Logs: tail -f logs/backend.log"
else
    print_status "Backend Logs: docker logs firmador-backend-dev"
fi
print_status "Frontend: Running on connected device/emulator"
echo ""
print_warning "Press Ctrl+C to stop all services"
echo ""

# Wait for user to stop
if [ "$SKIP_FRONTEND" = false ] && [ "$SKIP_BACKEND" = false ]; then
    wait
elif [ "$SKIP_FRONTEND" = false ]; then
    wait $FLUTTER_PID
elif [ "$SKIP_BACKEND" = false ] && [ "$MODE" = "local" ]; then
    wait $BACKEND_PID
else
    echo "Services started. Press Ctrl+C to stop."
    while true; do
        sleep 1
    done
fi 