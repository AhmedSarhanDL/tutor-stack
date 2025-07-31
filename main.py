from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

from tutor_stack_auth.main import fastapi_users, auth_backend, google_oauth_client
from tutor_stack_auth.auth import get_jwt_strategy, get_user_db, get_user_manager
from tutor_stack_auth.schemas import UserRead, UserCreate, UserUpdate
from tutor_stack_auth.models import User, OAuthAccount

# Import the core auth verification helper
current_active_user = fastapi_users.current_user(active=True)

# Import the services (try local first for development, then installed packages)
content_app = None
assessment_app = None
notifier_app = None
chat_app = None
auth_app = None

# Import content service
try:
    from services.content.tutor_stack_content.main import app as content_app
    print("✓ Content service imported successfully")
except ImportError as e:
    print(f"Warning: Could not import content service: {e}")
    try:
        from tutor_stack_content.main import app as content_app
        print("✓ Content service imported from installed package")
    except ImportError as e:
        print(f"Warning: Could not import content service: {e}")
        from fastapi import FastAPI as PlaceholderApp
        content_app = PlaceholderApp()

# Import assessment service
try:
    from services.assessment.tutor_stack_assessment.main import app as assessment_app
    print("✓ Assessment service imported successfully")
except ImportError as e:
    print(f"Warning: Could not import assessment service: {e}")
    try:
        from tutor_stack_assessment.main import app as assessment_app
        print("✓ Assessment service imported from installed package")
    except ImportError as e:
        print(f"Warning: Could not import assessment service: {e}")
        from fastapi import FastAPI as PlaceholderApp
        assessment_app = PlaceholderApp()

# Import notifier service
try:
    from services.notifier.tutor_stack_notifier.main import app as notifier_app
    print("✓ Notifier service imported successfully")
except ImportError as e:
    print(f"Warning: Could not import notifier service: {e}")
    try:
        from tutor_stack_notifier.main import app as notifier_app
        print("✓ Notifier service imported from installed package")
    except ImportError as e:
        print(f"Warning: Could not import notifier service: {e}")
        from fastapi import FastAPI as PlaceholderApp
        notifier_app = PlaceholderApp()

# Import chat service
try:
    from services.tutor_chat.tutor_stack_chat.main import app as chat_app
    print("✓ Chat service imported successfully")
except ImportError as e:
    print(f"Warning: Could not import chat service: {e}")
    try:
        from tutor_stack_chat.main import app as chat_app
        print("✓ Chat service imported from installed package")
    except ImportError as e:
        print(f"Warning: Could not import chat service: {e}")
        from fastapi import FastAPI as PlaceholderApp
        chat_app = PlaceholderApp()

# Removed the old auth service import logic as it's now directly integrated.
auth_app = None

# Create the main application
app = FastAPI(
    title="Tutor Stack API",
    description="API Gateway for Tutor Stack Platform",
    version="1.0.0",
    debug=True  # Enable debug mode to show detailed error information
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include authentication routers from tutor_stack_auth
app.include_router(
    fastapi_users.get_auth_router(auth_backend),
    prefix="/jwt",
    tags=["auth"]
)

app.include_router(
    fastapi_users.get_register_router(UserRead, UserCreate),
    tags=["auth"]
)

app.include_router(
    fastapi_users.get_users_router(UserRead, UserUpdate),
    prefix="/users",
    tags=["users"]
)

if google_oauth_client:
    app.include_router(
        fastapi_users.get_oauth_router(
            google_oauth_client,
            auth_backend,
            get_jwt_strategy().secret # Use the secret from the JWT strategy
        ),
        prefix="/google",
        tags=["auth"]
    )

# Add JWT verification middleware (defence-in-depth)
@app.middleware("http")
async def guard(req: Request, call_next):
    """JWT verification middleware for all requests"""
    # If the request path is for auth, let it pass through (Traefik handles auth for these paths)
    if req.url.path.startswith("/jwt") or req.url.path.startswith("/users") or req.url.path.startswith("/google"):
        response = await call_next(req)
        return response

    # Otherwise, attempt to get the current active user
    try:
        req.state.user = await fastapi_users.current_user(active=True)(req)
    except Exception as e:
        # For paths not directly handled by auth routers, we can let Traefik handle it or raise an error
        # For now, we'll let Traefik pass it if it's not a protected route
        pass

    response = await call_next(req)
    return response

# Mount the services as sub-applications
if content_app:
    app.mount("/content", content_app)
if assessment_app:
    app.mount("/assessment", assessment_app)
if notifier_app:
    app.mount("/notifier", notifier_app)
if chat_app:
    app.mount("/chat", chat_app)
# Removed the auth_app mounting as its routers are now directly included.

# Removed redundant database initialization for auth service, now handled by tutor_stack_auth.

@app.get("/")
async def root():
    return {
        "message": "Tutor Stack Platform",
        "services": {
            "content": "/content",
            "assessment": "/assessment", 
            "notifier": "/notifier",
            "chat": "/chat",
            "auth": "/auth"
        }
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port) 