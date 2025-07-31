#!/bin/bash

# Tutor Stack Full Project Setup Script

set -e  # Exit on any error

echo "🚀 Setting up Tutor Stack Full Project..."

# Configuration
GITHUB_ORG=${GITHUB_ORG:-"AhmedSarhanDL"}
REPO_PREFIX=${REPO_PREFIX:-"tutor-stack"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate JWT keys
generate_jwt_keys() {
    print_status "Generating JWT keys..."
    
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is required to generate JWT keys. Please install OpenSSL."
        exit 1
    fi
    
    mkdir -p keys
    
    if [ ! -f "keys/jwtRS256.key" ]; then
        openssl genrsa -out keys/jwtRS256.key 2048
        print_success "Private key generated"
    fi
    
    if [ ! -f "keys/jwtRS256.key.pub" ]; then
        openssl rsa -in keys/jwtRS256.key -pubout -out keys/jwtRS256.key.pub
        print_success "Public key generated"
    fi
    
    chmod 600 keys/jwtRS256.key
    chmod 644 keys/jwtRS256.key.pub
    print_success "JWT keys ready"
}

# Function to set environment variables
set_env_vars() {
    export DATABASE_URL="sqlite+aiosqlite:///./tutor_auth.db"
    export SECRET_PRIVATE_KEY_PATH="./keys/jwtRS256.key"
    export SECRET_PUBLIC_KEY_PATH="./keys/jwtRS256.key.pub"
    export SECRET_KEY="dev-secret-key-change-in-production"
    export JWT_SECRET_KEY="dev-jwt-secret-key-change-in-production"
    export API_HOST="0.0.0.0"
    export API_PORT="8000"
    export CORS_ORIGINS='["http://localhost:3000"]'
    export DEBUG="true"
}

# Check if we're in the right directory
if [ ! -f "pyproject.toml" ]; then
    print_error "This script must be run from the Tutor Stack root directory"
    exit 1
fi

print_status "Starting Tutor Stack setup..."

# Stop any running processes
print_status "Stopping any running processes..."
pkill -f "python main.py" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true

# Update main repository
print_status "Updating main repository..."
git pull origin main || print_warning "Could not pull latest changes"

# Clone subprojects
print_status "Setting up subprojects..."

REPOSITORIES=(
    "services/auth|git@github.com:${GITHUB_ORG}/${REPO_PREFIX}-auth.git"
    "services/content|git@github.com:${GITHUB_ORG}/${REPO_PREFIX}-content.git"
    "services/assessment|git@github.com:${GITHUB_ORG}/${REPO_PREFIX}-assessment.git"
    "services/notifier|git@github.com:${GITHUB_ORG}/${REPO_PREFIX}-notifier.git"
    "services/tutor_chat|git@github.com:${GITHUB_ORG}/${REPO_PREFIX}-tutor_chat.git"
    "frontend|git@github.com:${GITHUB_ORG}/${REPO_PREFIX}-frontend.git"
)

for repo_info in "${REPOSITORIES[@]}"; do
    path=$(echo "$repo_info" | cut -d'|' -f1)
    url=$(echo "$repo_info" | cut -d'|' -f2)
    
    print_status "Setting up $path..."
    
    if [ -d "$path" ]; then
        rm -rf "$path"
    fi
    
    mkdir -p "$(dirname "$path")"
    
    if git clone "$url" "$path" 2>/dev/null; then
        print_success "$path cloned successfully"
    else
        print_error "Failed to clone $path from $url"
        print_status "Please check the repository URL and your git access"
        return 1
    fi
done

# Check Python version
print_status "Checking Python version..."
if ! python3.11 --version &> /dev/null; then
    print_error "Python 3.11 is required but not found"
    exit 1
fi

print_success "Python version: $(python3.11 --version)"

# Setup virtual environment
print_status "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3.11 -m venv venv
fi

source venv/bin/activate

if [ -z "$VIRTUAL_ENV" ]; then
    print_error "Virtual environment activation failed"
    exit 1
fi

print_success "Virtual environment activated"

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip

if pip install -e .; then
    print_success "Project dependencies installed"
else
    print_error "Failed to install project dependencies"
    exit 1
fi

# Check Node.js for frontend
print_status "Checking Node.js..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18 or later."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18 or later is required. Current version: $(node -v)"
    exit 1
fi

print_success "Node.js version: $(node -v)"

# Setup frontend
if [ -d "frontend" ]; then
    print_status "Setting up frontend..."
    cd frontend
    
    if npm install; then
        print_success "Frontend dependencies installed"
    else
        print_error "Frontend dependency installation failed"
        exit 1
    fi
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cat > .env << EOF
VITE_API_BASE_URL=http://localhost:8000
VITE_GOOGLE_CLIENT_ID=
VITE_DEBUG=false
EOF
        print_success "Frontend .env file created"
    fi
    
    cd ..
fi

# Create main .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cat > .env << EOF
DATABASE_URL=sqlite+aiosqlite:///./tutor_auth.db
SECRET_KEY=dev-secret-key-change-in-production
JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production
SECRET_PRIVATE_KEY_PATH=./keys/jwtRS256.key
SECRET_PUBLIC_KEY_PATH=./keys/jwtRS256.key.pub
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=["http://localhost:3000"]
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
DEBUG=true
EOF
    print_success "Main .env file created"
fi

# Generate JWT keys
generate_jwt_keys

# Set environment variables
set_env_vars

# Run unit tests
print_status "Running unit tests..."
if [ -d "tests" ] && [ -d "tests/unit" ]; then
    if python -m pytest tests/unit/ -v; then
        print_success "Unit tests passed"
    else
        print_warning "Unit tests failed, but continuing..."
    fi
fi

# Start the project
print_status "🚀 Starting Tutor Stack..."
echo ""

# Start backend
print_status "Starting backend server..."
python main.py &
BACKEND_PID=$!

# Wait for backend to start
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        print_success "Backend is running on http://localhost:8000"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Backend failed to start"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

# Start frontend
if [ -d "frontend" ]; then
    print_status "Starting frontend development server..."
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
    # Wait for frontend to start
    for i in {1..30}; do
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            print_success "Frontend is running on http://localhost:3000"
            break
        fi
        if [ $i -eq 30 ]; then
            print_warning "Frontend may not be fully started yet"
        fi
        sleep 1
    done
fi

# Run integration tests
print_status "Running integration tests..."
if [ -d "tests" ] && [ -d "tests/integration" ]; then
    if python -m pytest tests/integration/ -v --tb=short; then
        print_success "Integration tests completed"
    else
        print_warning "Integration tests failed, but continuing..."
    fi
fi

# Run smoke tests
print_status "Running smoke tests..."
if [ -d "tests" ] && [ -d "tests/e2e" ]; then
    if python -m pytest tests/e2e/ -v --tb=short; then
        print_success "Smoke tests completed"
    else
        print_warning "Smoke tests failed, but continuing..."
    fi
fi

print_success "🎉 Tutor Stack is now running!"
echo ""
echo "🌐 Access your application:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend API: http://localhost:8000"
echo "   - API Documentation: http://localhost:8000/docs"
echo ""
echo "🛑 To stop the servers:"
echo "   - Press Ctrl+C in this terminal"
echo "   - Or run: pkill -f 'python main.py' && pkill -f 'vite'"
echo ""

# Cleanup function
cleanup() {
    print_status "Shutting down servers..."
    kill $BACKEND_PID 2>/dev/null || true
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    print_success "Servers stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "Press Ctrl+C to stop all servers..."
wait 