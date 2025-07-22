# Tutor Stack

A microservices-based tutoring platform.

## Services

- **Content Service**: Content management and search
- **Auth Service**: User authentication and authorization
- **Assessment Service**: Student assessment handling
- **Notifier Service**: Notification management
- **Tutor Chat Service**: Interactive tutoring chat

## Development

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Make (optional)

### Local Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd tutor-stack
   ```

2. Run the stack:
   ```bash
   docker compose up --build
   ```

3. Run tests:
   ```bash
   ./run_tests.sh
   ```

### Testing

Each service has its own test suite in the `tests/` directory. Tests are written using pytest and include:
- Functional tests
- Input validation tests
- Edge cases

To run tests for a specific service:
```bash
cd services/<service-name>
pytest tests/
```

To run tests with coverage:
```bash
pytest tests/ --cov=. --cov-report=term-missing
```

### Code Quality

We use several tools to maintain code quality:
- **Black**: Code formatting
- **isort**: Import sorting
- **Flake8**: Style guide enforcement
- **MyPy**: Static type checking

To run linting locally:
```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run formatters
black services/*/app services/*/tests
isort services/*/app services/*/tests

# Run linters
flake8 services/*/app services/*/tests
mypy services/*/app services/*/tests
```

## CI/CD

We use GitHub Actions for continuous integration and deployment:

### CI Workflow
- Runs on pull requests and pushes to main
- Tests each service independently
- Builds Docker images
- Reports test coverage to Codecov
- Enforces code quality with linters

### Workflow Status
[![CI](https://github.com/<org>/<repo>/actions/workflows/ci.yml/badge.svg)](https://github.com/<org>/<repo>/actions/workflows/ci.yml)
[![Lint](https://github.com/<org>/<repo>/actions/workflows/lint.yml/badge.svg)](https://github.com/<org>/<repo>/actions/workflows/lint.yml)

## API Documentation

Each service exposes its API documentation at `/docs` when running:
- Content Service: http://localhost/content/docs
- Auth Service: http://localhost/auth/docs
- Assessment Service: http://localhost/assessment/docs
- Notifier Service: http://localhost/notify/docs
- Tutor Chat Service: http://localhost/chat/docs 