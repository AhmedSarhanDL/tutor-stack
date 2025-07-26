#!/usr/bin/env python3
"""Test database connection"""

import pytest
import sys
import os
from sqlalchemy import text

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

@pytest.mark.asyncio
async def test_database():
    """Test database connection"""
    print("Testing database connection...")
    
    try:
        from services.auth.tutor_stack_auth.database import engine
        
        # Test connection
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT 1"))
            print("✓ Database connection successful")
            
            # Check if tables exist
            result = await conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"))
            tables = result.fetchall()
            print(f"✓ Tables found: {[table[0] for table in tables]}")
            
            # Assert that the connection works
            assert result is not None
            
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
        # Skip the test if database is not available (expected when running outside Docker)
        if "Connect call failed" in str(e) or "Connection refused" in str(e):
            pytest.skip(f"Database not available (expected when running outside Docker): {e}")
        else:
            # For other errors, fail the test
            import traceback
            traceback.print_exc()
            pytest.fail(f"Database connection failed: {e}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(test_database()) 