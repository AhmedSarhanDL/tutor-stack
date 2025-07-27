#!/bin/bash

# Tutor Stack Full Project Setup Script

set -e  # Exit on any error

echo "🚀 Setting up Tutor Stack Full Project..."

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
    
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is required to generate JWT keys. Please install OpenSSL."
        exit 1
    fi
    
    # Generate private key
    if [ ! -f "keys/jwtRS256.key" ]; then
        openssl genrsa -out keys/jwtRS256.key 2048
        print_success "Private key generated"
    else
        print_success "Private key already exists"
    fi
    
    # Generate public key
    if [ ! -f "keys/jwtRS256.key.pub" ]; then
        openssl rsa -in keys/jwtRS256.key -pubout -out keys/jwtRS256.key.pub
        print_success "Public key generated"
    else
        print_success "Public key already exists"
    fi
    
    # Set proper permissions
    chmod 600 keys/jwtRS256.key
    chmod 644 keys/jwtRS256.key.pub
    print_success "JWT keys ready"
}

# Check if we're in the right directory
if [ ! -f "pyproject.toml" ]; then
    print_error "This script must be run from the Tutor Stack root directory"
    exit 1
fi

print_status "Starting Tutor Stack setup..."

# 0. Stop any running processes
print_status "Stopping any running processes..."
pkill -f "python main.py" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
print_success "Processes stopped"

# 1. Initialize and update git submodules
print_status "Setting up git submodules..."
if [ -d ".git" ]; then
    # Only initialize submodules if .gitmodules exists
    if [ -f ".gitmodules" ]; then
        if git submodule update --init --recursive 2>/dev/null; then
            print_success "Git submodules initialized"
        else
            print_warning "Failed to initialize submodules, continuing with setup"
        fi
    else
        print_warning "No .gitmodules file found, skipping submodule setup"
    fi
else
    print_warning "Not a git repository, skipping submodule setup"
fi

# 2. Check Python version (updated to 3.11+)
print_status "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="3.11"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    print_error "Python 3.11 or later is required. Current version: $PYTHON_VERSION"
    print_status "Please upgrade Python to version 3.11 or later"
    exit 1
fi

print_success "Python version: $PYTHON_VERSION"

# 3. Create virtual environment
print_status "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_success "Virtual environment already exists"
fi

# 4. Activate virtual environment and install Python dependencies
print_status "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip

# Install the main project first
print_status "Installing main project..."
if pip install -e .; then
    print_success "Main project installed"
else
    print_warning "Main project installation failed, continuing with local service setup"
fi

# 5. Setup and install services
print_status "Setting up services..."
if [ -d "services" ]; then
    cd services
    
    # List of services to install
    services=("auth" "content" "assessment" "notifier" "tutor_chat")
    
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            print_status "Setting up $service service..."
            cd "$service"
            
            # Fetch latest changes from remote if it's a git repo and clean
            if [ -d ".git" ]; then
                if ! git diff --quiet HEAD; then
                    print_warning "Uncommitted changes found in $service. Skipping update."
                else
                    print_status "Updating $service from remote..."
                    git fetch origin 2>/dev/null || true
                    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
                    print_success "Updated $service from remote"
                fi
            fi
            
            # Install the service
            if pip install -e .; then
                print_success "$service service installed"
            else
                print_warning "$service service installation failed, continuing..."
            fi
            cd ..
        else
            print_warning "Service directory $service not found"
        fi
    done
    
    cd ..
    print_success "All services processed"
else
    print_warning "Services directory not found"
fi

# 6. Check Node.js for frontend
print_status "Checking Node.js for frontend..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18 or later."
    print_status "You can install Node.js from: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18 or later is required. Current version: $(node -v)"
    exit 1
fi

print_success "Node.js version: $(node -v)"

# 7. Setup frontend
print_status "Setting up frontend..."
if [ -d "frontend" ]; then
    cd frontend
    
    # Update from git if it's a repo and there are no local changes
    if [ -d ".git" ]; then
        if ! git diff --quiet HEAD; then
            print_warning "Uncommitted changes found in frontend. Skipping update."
        else
            print_status "Updating frontend from remote..."
            git fetch origin 2>/dev/null || true
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
            print_success "Updated frontend from remote"
        fi
    fi
    
    # Install frontend dependencies
    print_status "Installing frontend dependencies..."
    if npm install; then
        print_success "Frontend dependencies installed"
    else
        print_error "Frontend dependency installation failed"
        exit 1
    fi
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating frontend .env file..."
        cat > .env << EOF
# API Configuration
VITE_API_BASE_URL=http://localhost:8000

# Google OAuth (optional)
VITE_GOOGLE_CLIENT_ID=

# Debug mode (optional)
VITE_DEBUG=false
EOF
        print_success "Frontend .env file created"
    else
        print_success "Frontend .env file already exists"
    fi
    
    cd ..
    print_success "Frontend setup complete"
else
    print_warning "Frontend directory not found. Make sure git submodules are initialized."
fi

# 8. Create main .env file if it doesn't exist
print_status "Setting up environment configuration..."
if [ ! -f ".env" ]; then
    cat > .env << EOF
# Database Configuration (SQLite for development)
DATABASE_URL=sqlite+aiosqlite:///./tutor_auth.db

# Security
SECRET_KEY=dev-secret-key-change-in-production
JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production

# JWT Key Paths
SECRET_PRIVATE_KEY_PATH=./keys/jwtRS256.key
SECRET_PUBLIC_KEY_PATH=./keys/jwtRS256.key.pub

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# CORS Configuration
CORS_ORIGINS=["http://localhost:3000"]

# Google OAuth (optional)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Debug mode
DEBUG=true
EOF
    print_success "Main .env file created"
else
    print_success "Main .env file already exists"
fi

# 9. Create keys directory and generate JWT keys
print_status "Setting up keys directory..."
mkdir -p keys
generate_jwt_keys

# 10. Initialize database
print_status "Initializing database..."
if [ -f "venv/bin/python" ]; then
    # Create a temporary script to initialize the database
    cat > init_db_temp.py << 'EOF'
#!/usr/bin/env python3
"""Initialize the database tables for the auth service"""

import asyncio
import os
import sys

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

async def init_db():
    """Initialize database tables"""
    try:
        # Try to import from local services first
        try:
            from services.auth.tutor_stack_auth.database import engine, Base
            print("Using local auth service")
        except ImportError:
            # Try to import from installed package
            from tutor_stack_auth.database import engine, Base
            print("Using installed auth service")
        
        print("Creating database tables...")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("Database tables created successfully!")
    except Exception as e:
        print(f"Error initializing database: {e}")
        print("Database initialization failed, but continuing with setup...")
        return False
    return True

if __name__ == "__main__":
    # Set environment variables
    os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///./tutor_auth.db"
    os.environ["SECRET_PRIVATE_KEY_PATH"] = "./keys/jwtRS256.key"
    os.environ["SECRET_PUBLIC_KEY_PATH"] = "./keys/jwtRS256.key.pub"
    
    success = asyncio.run(init_db())
    if not success:
        sys.exit(1)
EOF

    # Run the database initialization
    source venv/bin/activate
    if python init_db_temp.py; then
        print_success "Database initialized"
    else
        print_warning "Database initialization failed, but continuing..."
    fi
    rm -f init_db_temp.py
else
    print_warning "Virtual environment not found, skipping database initialization"
fi

# 11. Run unit tests (these don't need a server)
print_status "Running unit tests..."
if [ -d "tests" ]; then
    # Set environment variables for testing
    export DATABASE_URL="sqlite+aiosqlite:///./tutor_auth.db"
    export SECRET_PRIVATE_KEY_PATH="./keys/jwtRS256.key"
    export SECRET_PUBLIC_KEY_PATH="./keys/jwtRS256.key.pub"
    
    if python -m pytest tests/unit/ -v; then
        print_success "Unit tests passed"
    else
        print_warning "Unit tests failed, but continuing..."
    fi
else
    print_warning "Tests directory not found"
fi

# 12. Start the full project
print_status "🚀 Starting Tutor Stack full project..."
echo ""

# Start backend in background
print_status "Starting backend server..."
cd "$(dirname "$0")"  # Ensure we're in the root directory

# Set environment variables for the server
export DATABASE_URL="sqlite+aiosqlite:///./tutor_auth.db"
export SECRET_PRIVATE_KEY_PATH="./keys/jwtRS256.key"
export SECRET_PUBLIC_KEY_PATH="./keys/jwtRS256.key.pub"

# Start backend with proper error handling
python main.py &
BACKEND_PID=$!
sleep 5  # Wait for backend to start

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    print_success "Backend is running on http://localhost:8000"
else
    print_error "Backend failed to start"
    kill $BACKEND_PID 2>/dev/null || true
    print_status "Check the logs above for backend startup errors"
    exit 1
fi

# Start frontend in background
print_status "Starting frontend development server..."
if [ -d "frontend" ]; then
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    sleep 8  # Wait for frontend to start
    
    # Check if frontend is running
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "Frontend is running on http://localhost:3000"
    else
        print_warning "Frontend may not be fully started yet, but continuing..."
    fi
    
    cd ..
else
    print_warning "Frontend directory not found"
    FRONTEND_PID=""
fi

# 13. Run integration and smoke tests (after server is running)
print_status "Running integration and smoke tests..."
if [ -d "tests" ]; then
    # Set environment variables for testing
    export DATABASE_URL="sqlite+aiosqlite:///./tutor_auth.db"
    export SECRET_PRIVATE_KEY_PATH="./keys/jwtRS256.key"
    export SECRET_PUBLIC_KEY_PATH="./keys/jwtRS256.key.pub"
    
    # Wait a bit more for server to be fully ready
    sleep 3
    
    # Run integration tests
    print_status "Running integration tests..."
    if python -m pytest tests/integration/ -v --tb=short; then
        print_success "Integration tests completed"
    else
        print_warning "Integration tests failed, but continuing..."
    fi
    
    # Run smoke tests
    print_status "Running smoke tests..."
    if python -m pytest tests/e2e/ -v --tb=short; then
        print_success "Smoke tests completed"
    else
        print_warning "Smoke tests failed, but continuing..."
    fi
else
    print_warning "Tests directory not found"
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
echo "📚 Documentation:"
echo "   - README.md - Main project documentation"
echo "   - frontend/README.md - Frontend documentation"
echo ""

# Function to cleanup on exit
cleanup() {
    print_status "Shutting down servers..."
    kill $BACKEND_PID 2>/dev/null || true
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    print_success "Servers stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Wait for user to stop the servers
echo "Press Ctrl+C to stop all servers..."
wait 