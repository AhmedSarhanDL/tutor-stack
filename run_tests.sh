#!/bin/bash

# Tutor Stack Test Runner
# Usage: ./run_tests.sh [test_type] [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TEST_TYPE="all"
PYTEST_OPTS=""
DOCKER_UP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            TEST_TYPE="unit"
            shift
            ;;
        --integration)
            TEST_TYPE="integration"
            shift
            ;;
        --e2e)
            TEST_TYPE="e2e"
            DOCKER_UP=true
            shift
            ;;
        --smoke)
            TEST_TYPE="smoke"
            DOCKER_UP=true
            shift
            ;;
        --docker-up)
            DOCKER_UP=true
            shift
            ;;
        --coverage)
            PYTEST_OPTS="$PYTEST_OPTS --cov=tutor_stack_core --cov-report=html --cov-report=term-missing"
            shift
            ;;
        --verbose)
            PYTEST_OPTS="$PYTEST_OPTS -v"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --unit          Run unit tests only"
            echo "  --integration   Run integration tests only"
            echo "  --e2e           Run end-to-end tests only"
            echo "  --smoke         Run smoke tests only"
            echo "  --docker-up     Start Docker services before testing"
            echo "  --coverage      Generate coverage report"
            echo "  --verbose       Verbose output"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 Tutor Stack Test Runner${NC}"
echo "================================"

# Check if Docker services need to be started
if [ "$DOCKER_UP" = true ]; then
    echo -e "${YELLOW}📦 Starting Docker services...${NC}"
    docker compose up --build -d
    
    echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
    sleep 30
    
    # Check if services are running
    if ! docker compose ps | grep -q "Up"; then
        echo -e "${RED}❌ Docker services failed to start${NC}"
        docker compose logs --tail=50
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker services are running${NC}"
fi

# Run tests based on type
case $TEST_TYPE in
    "unit")
        echo -e "${BLUE}🧪 Running unit tests...${NC}"
        pytest tests/unit/ $PYTEST_OPTS
        ;;
    "integration")
        echo -e "${BLUE}🔗 Running integration tests...${NC}"
        pytest tests/integration/ $PYTEST_OPTS
        ;;
    "e2e")
        echo -e "${BLUE}🌐 Running end-to-end tests...${NC}"
        pytest tests/e2e/ $PYTEST_OPTS
        ;;
    "smoke")
        echo -e "${BLUE}💨 Running smoke tests...${NC}"
        pytest tests/e2e/test_smoke.py $PYTEST_OPTS
        ;;
    "all")
        echo -e "${BLUE}🧪 Running all tests...${NC}"
        pytest tests/ $PYTEST_OPTS
        ;;
esac

# Cleanup if Docker was started
if [ "$DOCKER_UP" = true ]; then
    echo -e "${YELLOW}🧹 Cleaning up Docker services...${NC}"
    docker compose down
fi

echo -e "${GREEN}✅ Tests completed!${NC}" 