#!/usr/bin/env python3
"""Debug script for auth service mounting"""

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def debug_auth_service():
    """Debug the auth service"""
    print("=== Debug Auth Service ===")
    
    try:
        from services.auth.tutor_stack_auth.main import app as auth_app
        print("✓ Auth service imported successfully")
        print(f"  - Auth app type: {type(auth_app)}")
        print(f"  - Auth app title: {auth_app.title}")
        
        # Check if the app has routes
        routes = [route.path for route in auth_app.routes]
        print(f"  - Auth app routes: {routes}")
        
        return auth_app
    except Exception as e:
        print(f"✗ Auth service import failed: {e}")
        import traceback
        traceback.print_exc()
        return None

def debug_main_app():
    """Debug the main app"""
    print("\n=== Debug Main App ===")
    
    try:
        from main import app
        print("✓ Main app imported successfully")
        print(f"  - Main app type: {type(app)}")
        print(f"  - Main app title: {app.title}")
        
        # Check if the app has routes
        routes = [route.path for route in app.routes]
        print(f"  - Main app routes: {routes}")
        
        # Check for auth routes in the main app
        auth_routes = [route.path for route in app.routes if route.path.startswith('/auth')]
        print(f"  - Auth routes in main app: {auth_routes}")
        
        return app
    except Exception as e:
        print(f"✗ Main app import failed: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    auth_app = debug_auth_service()
    main_app = debug_main_app()
    
    if auth_app and main_app:
        print("\n=== Summary ===")
        print("Both apps imported successfully!")
        print(f"Auth app has {len(auth_app.routes)} routes")
        print(f"Main app has {len(main_app.routes)} routes")
        
        # Test if auth routes are accessible
        print("\n=== Testing Auth Routes ===")
        import requests
        try:
            response = requests.get("http://localhost:8000/auth/")
            print(f"Auth root response: {response.status_code}")
            if response.status_code == 200:
                print(f"Auth root content: {response.json()}")
        except Exception as e:
            print(f"Auth root test failed: {e}") 