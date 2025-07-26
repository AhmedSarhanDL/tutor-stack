from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

# Import the core auth verification helper
try:
    from tutor_stack_core.auth import current_active_user
    print("✓ Core auth helper imported successfully")
except ImportError as e:
    print(f"Warning: Could not import core auth helper: {e}")
    current_active_user = None

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

# Import auth service from local services directory
try:
    from services.auth.tutor_stack_auth.main import app as auth_app
    print("✓ Auth service imported successfully")
except ImportError as e:
    print(f"Warning: Could not import auth service from local: {e}")
    try:
        from tutor_stack_auth.main import app as auth_app
        print("✓ Auth service imported from installed package")
    except ImportError as e:
        print(f"Warning: Could not import auth service: {e}")
        from fastapi import FastAPI as PlaceholderApp
        auth_app = PlaceholderApp()

# Create the main application
app = FastAPI(
    title="Tutor Stack Platform",
    description="A comprehensive tutoring system with multiple services",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add JWT verification middleware (defence-in-depth)
@app.middleware("http")
async def guard(req: Request, call_next):
    """JWT verification middleware for all requests"""
    if current_active_user:
        try:
            req.state.user = current_active_user(req)  # raises 401/403
        except Exception:
            # Let Traefik handle auth for now, but we could add additional logic here
            pass
    return await call_next(req)

# Mount the services as sub-applications
if content_app:
    app.mount("/content", content_app)
if assessment_app:
    app.mount("/assessment", assessment_app)
if notifier_app:
    app.mount("/notify", notifier_app)
if chat_app:
    app.mount("/chat", chat_app)
if auth_app:
    app.mount("/auth", auth_app)

@app.get("/")
async def root():
    return {
        "message": "Tutor Stack Platform",
        "services": {
            "content": "/content",
            "assessment": "/assessment", 
            "notifier": "/notify",
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