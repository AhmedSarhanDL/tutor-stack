# Tutor Stack Platform

A comprehensive tutoring system that combines multiple services into a unified platform with a modern React frontend.

## Services

- **Content Service**: Handles content storage and search functionality
- **Assessment Service**: Manages grading and assessment functionality
- **Notifier Service**: Handles notification delivery
- **Tutor Chat Service**: Provides interactive tutoring using DSPy and OpenAI
- **Auth Service**: Handles user authentication and authorization
- **Frontend**: Modern React TypeScript application with Vite

## Architecture

This platform uses a unified approach where all services are installed as Python packages from their respective Git repositories and combined into a single FastAPI application. For development, the services are cloned locally and used directly.

## Installation

### Quick Setup (Recommended)

Use the automated setup script for a complete installation:

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/AhmedSarhanDL/tutor-stack.git
cd tutor-stack

# Run the setup script
./setup.sh
```

This script will:
- Initialize git submodules (including frontend)
- Set up Python virtual environment
- Install Python dependencies
- Fetch and install all services from their git repositories
- Install frontend dependencies
- Create necessary configuration files
- Run tests to verify the setup

### Manual Development Setup

1. Clone the repository with submodules:
```bash
git clone --recursive https://github.com/AhmedSarhanDL/tutor-stack.git
cd tutor-stack
```

2. If submodules weren't cloned, initialize them:
```bash
git submodule update --init --recursive
```

3. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

4. Install the project in development mode:
```bash
pip install -e ".[dev]"
```

5. Install services in development mode:
```bash
pip install -e "./services/content"
pip install -e "./services/assessment"
pip install -e "./services/notifier"
pip install -e "./services/tutor_chat"
pip install -e "./services/auth"
```

6. Setup frontend:
```bash
cd frontend
npm install
cd ..
```

### Production Installation

For production, install the package without development dependencies:

```bash
pip install .
```

## Project Structure

```
tutor-stack/
├── main.py              # Main FastAPI application that combines all services
├── pyproject.toml       # Project configuration with service dependencies
├── setup.sh             # Automated setup script
├── Dockerfile.base      # Docker configuration for production (uses Git packages)
├── Dockerfile.dev       # Docker configuration for development (uses local services)
├── docker-compose.yaml  # Docker Compose configuration
├── frontend/            # React TypeScript frontend (git submodule)
│   ├── src/             # React source code
│   ├── public/          # Static assets
│   ├── package.json     # Frontend dependencies
│   └── README.md        # Frontend documentation
├── services/            # Local service repositories for development
│   ├── content/         # Content service (cloned from Git)
│   ├── assessment/      # Assessment service (cloned from Git)
│   ├── notifier/        # Notifier service (cloned from Git)
│   ├── tutor_chat/      # Tutor chat service (cloned from Git)
│   └── auth/            # Auth service (cloned from Git)
└── README.md           # This file
```

## Running the Platform

### Local Development

#### Backend API

Run the unified platform locally:

```bash
python main.py
```

The platform will be available at `http://localhost:8000` with the following endpoints:
- `/` - Platform overview
- `/health` - Health check
- `/content` - Content service
- `/assessment` - Assessment service
- `/notify` - Notifier service
- `/chat` - Tutor chat service
- `/auth` - Authentication service

#### Frontend

Start the frontend development server:

```bash
cd frontend
npm run dev
```

The frontend will be available at `http://localhost:3000`

#### Full Stack Development

For full stack development, run both backend and frontend:

```bash
# Terminal 1: Backend
python main.py

# Terminal 2: Frontend
cd frontend && npm run dev
```

### Using Docker (Development)

Build and run the platform using Docker with local services:

```bash
# Build the development image
docker build -f Dockerfile.dev -t tutor-stack-dev .

# Run the container
docker run -p 8000:8000 tutor-stack-dev
```

### Using Docker Compose (Development)

Run the complete platform with Traefik reverse proxy:

```bash
docker-compose up
```

This will start:
- Traefik reverse proxy (port 80)
- Traefik dashboard (port 8080)
- Tutor Stack platform (port 8000)

### Using Docker (Production)

For production, use the base Dockerfile that installs services from Git:

```bash
# Build the production image
docker build -f Dockerfile.base -t tutor-stack-prod .

# Run the container
docker run -p 8000:8000 tutor-stack-prod
```

## Service Dependencies

The platform automatically installs the following services from their Git repositories:

- `tutor-stack-content` - Content management service
- `tutor-stack-assessment` - Assessment and grading service  
- `tutor-stack-notifier` - Notification service
- `tutor-stack-chat` - Interactive tutoring service
- `tutor-stack-auth` - Authentication and authorization service

## Frontend Repository

The frontend is maintained as a separate repository and included as a git submodule:

- **Repository**: [tutor-stack-frontend](https://github.com/AhmedSarhanDL/tutor-stack-frontend)
- **Technology**: React 19 + TypeScript + Vite
- **Features**: Modern UI with authentication, dashboard, and API integration
- **Documentation**: See `frontend/README.md` for detailed frontend documentation

## Development

For development, the services are cloned locally in the `services/` directory. You can:

1. Make changes to the local service code
2. The changes will be reflected immediately when running locally
3. For Docker development, rebuild the image to see changes
4. Push changes to the respective Git repositories for production deployment

## License

MIT 