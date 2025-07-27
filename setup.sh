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

# 2. Check Python version
print_status "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="3.9"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    print_error "Python 3.9 or later is required. Current version: $PYTHON_VERSION"
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

# Install the main project (skip for now due to service dependencies)
print_status "Installing main project..."
# pip install -e .  # Skip for now due to service dependency conflicts
print_success "Main project installation skipped (will install services locally)"

# 5. Setup and install services
print_status "Setting up services..."
if [ -d "services" ]; then
    cd services
    
    # List of services to install
    services=("content" "assessment" "notifier" "tutor_chat" "auth")
    
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            print_status "Setting up $service service..."
            cd "$service"
            
            # Fetch latest changes from remote
            if [ -d ".git" ]; then
                git fetch origin
                git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
                print_success "Updated $service from remote"
            fi
            
            # Install the service
            pip install -e .
            print_success "$service service installed"
            cd ..
        else
            print_warning "Service directory $service not found"
        fi
    done
    
    cd ..
    print_success "All services installed"
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
    
    # Install frontend dependencies
    print_status "Installing frontend dependencies..."
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating frontend .env file..."
        cat > .env << EOF
# API Configuration
VITE_API_BASE_URL=http://api.tutor-stack.local

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
# Database Configuration
DATABASE_URL=sqlite:///./tutor_stack.db

# Security
SECRET_KEY=your-secret-key-here-change-in-production
JWT_SECRET_KEY=your-jwt-secret-key-here-change-in-production

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# CORS Configuration
CORS_ORIGINS=["http://localhost:3000", "http://app.tutor-stack.local"]

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

# 9. Create keys directory if it doesn't exist
print_status "Setting up keys directory..."
mkdir -p keys
print_success "Keys directory ready"

# 10. Run tests to verify setup
print_status "Running tests to verify setup..."
if [ -d "tests" ]; then
    python -m pytest tests/unit/ -v
    print_success "Unit tests passed"
else
    print_warning "Tests directory not found"
fi

print_success "🎉 Tutor Stack setup complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "  1. Start the development server:"
echo "     python main.py"
echo ""
echo "  2. Start the frontend development server:"
echo "     cd frontend && npm run dev"
echo ""
echo "  3. Or use Docker for full stack:"
echo "     docker-compose -f docker-compose.dev.yaml up"
echo ""
echo "  4. Access URLs:"
echo "     - Backend API: http://localhost:8000"
echo "     - Frontend: http://localhost:3000"
echo "     - Docker: http://app.tutor-stack.local"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Main project documentation"
echo "   - frontend/README.md - Frontend documentation"
echo "" 