#!/usr/bin/env python3
"""Test script to verify auth service mounting"""

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_mounting():
    """Test if the auth service is properly mounted"""
    print("=== Testing Auth Service Mounting ===")
    
    try:
        from main import app
        
        # Check if auth is in the routes
        auth_routes = []
        for route in app.routes:
            if hasattr(route, 'path') and route.path.startswith('/auth'):
                auth_routes.append(route.path)
        
        print(f"Auth routes found: {auth_routes}")
        
        # Check if auth is in the mounted apps
        print(f"All routes: {[route.path for route in app.routes]}")
        
        # Try to access the auth service directly
        from services.auth.tutor_stack_auth.main import app as auth_app
        print(f"Auth app routes: {[route.path for route in auth_app.routes]}")
        
        return True
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_mounting() 