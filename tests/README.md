# Tutor Stack Test Suite

This directory contains all tests for the Tutor Stack application, organized by test type and functionality.

## 📁 Directory Structure

```
tests/
├── __init__.py              # Test package initialization
├── conftest.py              # Pytest configuration and fixtures
├── utils.py                 # Test utilities and helper functions
├── README.md               # This file
├── unit/                   # Unit tests for individual components
│   ├── __init__.py
│   └── test_auth_direct.py
├── integration/            # Integration tests for service interactions
│   ├── __init__.py
│   ├── test_auth_service.py
│   ├── test_auth_integration.py
│   ├── test_auth_local.py
│   ├── test_mounting.py
│   └── test_other_services.py
├── e2e/                    # End-to-end tests for complete workflows
│   ├── __init__.py
│   └── test_smoke.py
└── fixtures/               # Test fixtures and utilities
    ├── __init__.py
    ├── test_db.py
    └── debug_auth.py
```

## 🧪 Test Types

### Unit Tests (`tests/unit/`)
- Test individual functions and components in isolation
- Fast execution, no external dependencies
- Focus on logic and edge cases

### Integration Tests (`tests/integration/`)
- Test service interactions and API endpoints
- May require database or other services
- Test real HTTP requests and responses

### End-to-End Tests (`tests/e2e/`)
- Test complete user workflows
- Require full application stack (Docker)
- Slowest but most comprehensive

### Fixtures (`tests/fixtures/`)
- Test utilities, debugging tools, and setup scripts
- Not actual tests, but supporting code

## 🚀 Running Tests

### Using the Test Runner Script
```bash
# Run all tests
./run_tests.sh

# Run specific test types
./run_tests.sh --unit
./run_tests.sh --integration
./run_tests.sh --e2e
./run_tests.sh --smoke

# Run with Docker services
./run_tests.sh --e2e --docker-up

# Run with coverage
./run_tests.sh --coverage

# Verbose output
./run_tests.sh --verbose
```

### Using Pytest Directly
```bash
# Run all tests
pytest

# Run specific test types
pytest tests/unit/
pytest tests/integration/
pytest tests/e2e/

# Run with markers
pytest -m "unit"
pytest -m "integration"
pytest -m "e2e"
pytest -m "auth"

# Run specific test file
pytest tests/integration/test_auth_service.py

# Run with coverage
pytest --cov=tutor_stack_core --cov-report=html
```

## 🔧 Test Configuration

### Pytest Configuration (`pytest.ini`)
- Test discovery paths
- Markers for test categorization
- Default options and warnings

### Test Fixtures (`conftest.py`)
- Common fixtures for all tests
- Database setup and teardown
- Authentication helpers
- Test data generators

### Test Utilities (`utils.py`)
- `APITestClient` for HTTP requests
- Authentication helpers
- Assertion utilities
- Test data generators

## 🏷️ Test Markers

Use these markers to categorize and filter tests:

- `@pytest.mark.unit` - Unit tests
- `@pytest.mark.integration` - Integration tests
- `@pytest.mark.e2e` - End-to-end tests
- `@pytest.mark.slow` - Slow running tests
- `@pytest.mark.auth` - Authentication related tests

## 📊 Test Coverage

Generate coverage reports:
```bash
# HTML coverage report
pytest --cov=tutor_stack_core --cov-report=html

# Terminal coverage report
pytest --cov=tutor_stack_core --cov-report=term-missing

# XML coverage report (for CI)
pytest --cov=tutor_stack_core --cov-report=xml
```

## 🐳 Docker Integration

For tests that require the full application stack:

```bash
# Start services
docker compose up --build -d

# Wait for services to be ready
sleep 30

# Run tests
pytest tests/e2e/

# Cleanup
docker compose down
```

## 🔍 Debugging Tests

### Debug Auth Issues
```bash
# Use the debug script
python tests/fixtures/debug_auth.py

# Check service logs
docker compose logs auth
```

### Database Testing
```bash
# Initialize test database
python tests/fixtures/test_db.py

# Check database connection
python -c "from tests.fixtures.test_db import test_connection; test_connection()"
```

## 📝 Writing New Tests

### Unit Test Example
```python
import pytest
from tutor_stack_core.auth import some_function

@pytest.mark.unit
def test_some_function():
    result = some_function("input")
    assert result == "expected_output"
```

### Integration Test Example
```python
import pytest
from tests.utils import APITestClient, assert_response_success

@pytest.mark.integration
class TestSomeService:
    @pytest.fixture(autouse=True)
    def setup(self, base_url: str):
        self.client = APITestClient(base_url)
    
    def test_endpoint(self):
        response = self.client.get("/some/endpoint")
        assert_response_success(response)
```

### E2E Test Example
```python
import pytest
from tests.utils import APITestClient, test_user_session

@pytest.mark.e2e
@pytest.mark.slow
def test_complete_workflow():
    client = APITestClient()
    
    with test_user_session(client, "test@example.com") as (headers, user_id):
        # Test complete user workflow
        response = client.get("/protected/endpoint", headers=headers)
        assert response.status_code == 200
```

## 🚨 Common Issues

### Bcrypt Version Compatibility
Some auth tests may fail due to bcrypt version issues. This is a known dependency problem, not a test issue.

### Docker Service Startup
If Docker services fail to start, check:
- Docker is running
- Ports are available
- Docker Compose file is valid

### Database Connection
If database tests fail:
- Check PostgreSQL is running
- Verify connection parameters
- Ensure test database exists

## 📈 CI/CD Integration

Tests are automatically run in GitHub Actions:
- **CI Pipeline**: Runs on every push and PR
- **Deploy Pipeline**: Runs on version tags
- **Coverage Reports**: Uploaded to Codecov

See `.github/workflows/` for workflow configurations. 