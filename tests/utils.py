"""
Test utilities and helper functions
"""
import requests
import time
import json
from typing import Dict, Any, Optional, Tuple
from contextlib import contextmanager


class APITestClient:
    """Client for testing API endpoints"""
    
    def __init__(self, base_url: str = "http://localhost:8000", timeout: int = 30):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
    
    def get(self, endpoint: str, headers: Optional[Dict[str, str]] = None, **kwargs) -> requests.Response:
        """Make a GET request"""
        url = f"{self.base_url}{endpoint}"
        return self.session.get(url, headers=headers, timeout=self.timeout, **kwargs)
    
    def post(self, endpoint: str, data: Optional[Dict[str, Any]] = None, 
             headers: Optional[Dict[str, str]] = None, **kwargs) -> requests.Response:
        """Make a POST request"""
        url = f"{self.base_url}{endpoint}"
        return self.session.post(url, json=data, headers=headers, timeout=self.timeout, **kwargs)
    
    def put(self, endpoint: str, data: Optional[Dict[str, Any]] = None,
            headers: Optional[Dict[str, str]] = None, **kwargs) -> requests.Response:
        """Make a PUT request"""
        url = f"{self.base_url}{endpoint}"
        return self.session.put(url, json=data, headers=headers, timeout=self.timeout, **kwargs)
    
    def delete(self, endpoint: str, headers: Optional[Dict[str, str]] = None, **kwargs) -> requests.Response:
        """Make a DELETE request"""
        url = f"{self.base_url}{endpoint}"
        return self.session.delete(url, headers=headers, timeout=self.timeout, **kwargs)


def wait_for_service(url: str, timeout: int = 60, interval: int = 2) -> bool:
    """Wait for a service to be ready"""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                return True
        except requests.RequestException:
            pass
        time.sleep(interval)
    return False


def create_test_user(client: APITestClient, email: str, password: str = "testpass123") -> Tuple[bool, Optional[str]]:
    """Create a test user and return (success, user_id)"""
    try:
        # Register user
        response = client.post("/auth/register", {"email": email, "password": password})
        if response.status_code == 201:
            user_data = response.json()
            return True, user_data.get("id")
        return False, None
    except Exception:
        return False, None


def login_user(client: APITestClient, email: str, password: str = "testpass123") -> Tuple[bool, Optional[str]]:
    """Login user and return (success, access_token)"""
    try:
        # Use form data for login endpoint
        login_data = {"username": email, "password": password}
        response = client.session.post(
            f"{client.base_url}/auth/jwt/login", 
            data=login_data,  # Use form data, not JSON
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=client.timeout
        )
        if response.status_code == 200:
            token_data = response.json()
            return True, token_data.get("access_token")
        return False, None
    except Exception:
        return False, None


def get_auth_headers(token: str) -> Dict[str, str]:
    """Get authentication headers with Bearer token"""
    return {"Authorization": f"Bearer {token}"}


@contextmanager
def test_user_session(client: APITestClient, email: str, password: str = "testpass123"):
    """Context manager for creating and cleaning up a test user session"""
    # Create user
    success, user_id = create_test_user(client, email, password)
    if not success:
        raise Exception(f"Failed to create test user: {email}")
    
    # Login to get token
    success, token = login_user(client, email, password)
    if not success:
        raise Exception(f"Failed to login test user: {email}")
    
    headers = get_auth_headers(token)
    
    try:
        yield headers, user_id
    finally:
        # Cleanup could be added here if needed
        pass


def assert_response_success(response: requests.Response, expected_status: int = 200) -> None:
    """Assert that a response was successful"""
    assert response.status_code == expected_status, \
        f"Expected status {expected_status}, got {response.status_code}. Response: {response.text}"


def assert_response_error(response: requests.Response, expected_status: int = 400) -> None:
    """Assert that a response was an error"""
    assert response.status_code == expected_status, \
        f"Expected error status {expected_status}, got {response.status_code}. Response: {response.text}"


def generate_unique_email() -> str:
    """Generate a unique email for testing"""
    timestamp = int(time.time() * 1000)
    return f"test{timestamp}@example.com" 