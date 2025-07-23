# Tutor Stack Platform

A comprehensive tutoring system composed of multiple microservices.

## Services

- **Content Service**: Handles content storage and search functionality
- **Assessment Service**: Manages grading and assessment functionality
- **Notifier Service**: Handles notification delivery
- **Tutor Chat Service**: Provides interactive tutoring using DSPy and OpenAI

## Installation

### Development Setup

1. Clone the repository:
```bash
git clone https://github.com/AhmedSarhanDL/tutor-stack.git
cd tutor-stack
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install the project in development mode:
```bash
pip install -e ".[dev]"
```

This will install all services and their dependencies in development mode.

### Production Installation

For production, install the package without development dependencies:

```bash
pip install .
```

## Project Structure

```
tutor-stack/
├── services/
│   ├── content/          # Content management service
│   ├── assessment/       # Assessment and grading service
│   ├── notifier/         # Notification service
│   └── tutor_chat/       # Interactive tutoring service
├── pyproject.toml        # Root project configuration
└── README.md            # This file
```

## Development

Each service can be developed independently in its own directory. They can also be installed and used independently:

```bash
pip install -e "./services/content[dev]"  # Install just the content service
```

## Running the Services

Each service can be run independently using uvicorn:

```bash
# Content Service
uvicorn services.content.app.main:app --reload --port 8000

# Assessment Service
uvicorn services.assessment.app.main:app --reload --port 8001

# Notifier Service
uvicorn services.notifier.app.main:app --reload --port 8002

# Tutor Chat Service
uvicorn services.tutor_chat.app.main:app --reload --port 8003
```

## License

MIT 