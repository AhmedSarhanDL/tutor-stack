"""
Pytest configuration and common fixtures for Tutor Stack tests
"""
import pytest
import os
import sys
from typing import Generator
import requests
import time

# Add the project root to the Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Test configuration
BASE_URL = "http://localhost:8000"
TEST_TIMEOUT = 30  # seconds

@pytest.fixture(scope="session")
def base_url() -> str:
    """Base URL for the API under test"""
    return BASE_URL

@pytest.fixture(scope="session")
def test_timeout() -> int:
    """Timeout for API requests"""
    return TEST_TIMEOUT

@pytest.fixture(scope="function")
def unique_email() -> str:
    """Generate a unique email for each test"""
    timestamp = int(time.time() * 1000)
    return f"test{timestamp}@example.com"

@pytest.fixture(scope="function")
def test_user_credentials(unique_email: str) -> dict:
    """Test user credentials"""
    return {
        "email": unique_email,
        "password": "testpass123"
    }

@pytest.fixture(scope="function")
def auth_headers() -> Generator[dict, None, None]:
    """Authentication headers for protected endpoints"""
    headers = {}
    yield headers

@pytest.fixture(scope="function")
def authenticated_headers(test_user_credentials: dict, base_url: str) -> Generator[dict, None, None]:
    """Headers with authentication token"""
    # Register and login to get token
    email = test_user_credentials["email"]
    password = test_user_credentials["password"]
    
    # Register user
    register_data = {"email": email, "password": password}
    response = requests.post(f"{base_url}/auth/register", json=register_data)
    
    # Login to get token
    login_data = {"username": email, "password": password}
    response = requests.post(f"{base_url}/auth/jwt/login", data=login_data)
    
    if response.status_code == 200:
        token_data = response.json()
        access_token = token_data.get("access_token")
        headers = {"Authorization": f"Bearer {access_token}"}
    else:
        headers = {}
    
    yield headers

def pytest_configure(config):
    """Configure pytest with custom markers"""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "e2e: marks tests as end-to-end tests"
    )
    config.addinivalue_line(
        "markers", "auth: marks tests as authentication related"
    ) 