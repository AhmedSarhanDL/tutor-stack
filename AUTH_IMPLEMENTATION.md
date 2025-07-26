# Tutor Stack Auth Implementation

This document outlines the step-by-step implementation of authentication for the Tutor Stack platform.

## ✅ Completed Steps

### 1. JWT Key Generation
- Generated RSA 4096-bit key pair for RS256 signing
- Private key: `keys/jwtRS256.key`
- Public key: `keys/jwtRS256.key.pub`

### 2. Auth Service Setup
- Created `services/auth/` with FastAPI Users integration
- Models: `User` and `OAuthAccount` with UUID primary keys
- JWT Strategy with RS256 algorithm and 1-hour TTL
- Google OAuth support (configurable via environment variables)
- Database: PostgreSQL with asyncpg driver

### 3. Core Auth Helper
- Created `tutor_stack_core/auth.py` for JWT verification
- Reusable across all microservices
- Handles token validation, expiration, and user status checks

### 4. Docker Compose Configuration
- Added PostgreSQL database service
- Configured auth service with proper environment variables
- Updated Traefik with JWT plugin support
- Separated protected and public endpoints

### 5. Traefik JWT Middleware
- Dynamic configuration in `traefik/traefik-dynamic.yml`
- JWT verification at gateway level
- Public key embedded in configuration

## 🔧 Configuration

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql+asyncpg://tutor:tutor@db:5432/tutor_auth

# JWT
JWT_ALG=RS256
JWT_PUBLIC_KEY_PATH=./keys/jwtRS256.key.pub

# Google OAuth (optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# OpenAI
OPENAI_API_KEY=your_openai_api_key
```

### Service Endpoints
- **Auth Service**: `/auth/*` (no JWT required)
- **Protected Services**: `/content/*`, `/assessment/*`, `/notify/*`, `/chat/*` (JWT required)
- **Health Check**: `/health` (no JWT required)

## 🚀 Running the System

1. **Start the services**:
   ```bash
   docker-compose up -d
   ```

2. **Test the setup**:
   ```bash
   python test_auth.py
   ```

3. **Register a user**:
   ```bash
   curl -X POST http://localhost:8000/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email": "test@example.com", "password": "password123"}'
   ```

4. **Login**:
   ```bash
   curl -X POST http://localhost:8000/auth/jwt/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=test@example.com&password=password123"
   ```

## 🔒 Security Features

- **RS256 JWT signing** for production-grade security
- **Gateway-level JWT verification** via Traefik
- **Defence-in-depth** with application-level middleware
- **OAuth support** for Google authentication
- **Token expiration** (1 hour TTL)
- **User status validation** (active/inactive)

## 📋 Next Steps

1. **Frontend Implementation**: React SPA with auth context
2. **Google OAuth Setup**: Configure Google Cloud Console
3. **Role-based Access Control**: Implement user roles
4. **Token Refresh**: Implement refresh token flow
5. **Testing**: Comprehensive test suite
6. **Production Hardening**: HTTPS, secure headers, etc.

## 🐛 Troubleshooting

### Common Issues

1. **JWT Plugin Not Found**: Ensure Traefik v3.0+ with JWT plugin
2. **Database Connection**: Check PostgreSQL is running and accessible
3. **Key Permissions**: Ensure JWT keys are readable by containers
4. **CORS Issues**: Configure CORS for frontend integration

### Debug Commands

```bash
# Check Traefik logs
docker-compose logs traefik

# Check auth service logs
docker-compose logs auth

# Check database connection
docker-compose exec db psql -U tutor -d tutor_auth
``` 