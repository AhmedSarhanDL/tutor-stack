#!/usr/bin/env python3
"""Local test script for the auth service"""

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test if all modules can be imported"""
    print("Testing imports...")
    
    try:
        from tutor_stack_core.auth import current_active_user, User
        print("✓ Core auth helper imported successfully")
    except Exception as e:
        print(f"✗ Core auth helper import failed: {e}")
        return False
    
    try:
        from services.auth.tutor_stack_auth.models import User, OAuthAccount
        print("✓ Auth models imported successfully")
    except Exception as e:
        print(f"✗ Auth models import failed: {e}")
        return False
    
    try:
        from services.auth.tutor_stack_auth.database import engine, Base
        print("✓ Auth database imported successfully")
    except Exception as e:
        print(f"✗ Auth database import failed: {e}")
        return False
    
    try:
        from services.auth.tutor_stack_auth.auth import get_jwt_strategy, get_user_db
        print("✓ Auth configuration imported successfully")
    except Exception as e:
        print(f"✗ Auth configuration import failed: {e}")
        return False
    
    return True

def test_auth_app():
    """Test if the auth app can be created"""
    print("\nTesting auth app creation...")
    
    try:
        from services.auth.tutor_stack_auth.main import app
        print("✓ Auth app created successfully")
        print(f"  - App title: {app.title}")
        print(f"  - App version: {app.version}")
        return True
    except Exception as e:
        print(f"✗ Auth app creation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_main_app():
    """Test if the main app can be created"""
    print("\nTesting main app creation...")
    
    try:
        from main import app
        print("✓ Main app created successfully")
        print(f"  - App title: {app.title}")
        print(f"  - App version: {app.version}")
        return True
    except Exception as e:
        print(f"✗ Main app creation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("=== Local Auth Service Test ===")
    
    if test_imports():
        if test_auth_app():
            test_main_app()
        else:
            print("Auth app test failed, skipping main app test")
    else:
        print("Import test failed, stopping") 