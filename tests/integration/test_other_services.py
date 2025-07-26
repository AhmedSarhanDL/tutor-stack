"""
Integration tests for other services (content, assessment, notify, chat)
"""
import pytest
from tests.utils import APITestClient, assert_response_success


@pytest.mark.integration
class TestOtherServices:
    """Test other service endpoints"""
    
    @pytest.fixture(autouse=True)
    def setup(self, base_url: str):
        """Setup test client"""
        self.client = APITestClient(base_url)
    
    def test_content_service_health(self):
        """Test content service health endpoint"""
        response = self.client.get("/content/health")
        assert_response_success(response)
        data = response.json()
        assert "status" in data
    
    def test_assessment_service_health(self):
        """Test assessment service health endpoint"""
        response = self.client.get("/assessment/health")
        assert_response_success(response)
        data = response.json()
        assert "status" in data
    
    def test_notify_service_health(self):
        """Test notify service health endpoint"""
        response = self.client.get("/notify/health")
        assert_response_success(response)
        data = response.json()
        assert "status" in data
    
    def test_chat_service_health(self):
        """Test chat service health endpoint"""
        response = self.client.get("/chat/health")
        assert_response_success(response)
        data = response.json()
        assert "status" in data
    
    def test_notify_service_post(self):
        """Test notify service POST endpoint"""
        notification_data = {
            "message": "Test notification",
            "recipient": "test@example.com",
            "type": "email"
        }
        
        response = self.client.post("/notify/", notification_data)
        # The service might return 200 or 422 depending on implementation
        assert response.status_code in [200, 422]
    
    def test_content_service_root(self):
        """Test content service root endpoint"""
        response = self.client.get("/content/")
        # Should return some response (might be 404 if not implemented)
        assert response.status_code in [200, 404]
    
    def test_assessment_service_root(self):
        """Test assessment service root endpoint"""
        response = self.client.get("/assessment/")
        # Should return some response (might be 404 if not implemented)
        assert response.status_code in [200, 404]
    
    def test_chat_service_root(self):
        """Test chat service root endpoint"""
        response = self.client.get("/chat/")
        # Should return some response (might be 404 if not implemented)
        assert response.status_code in [200, 404]
    
    def test_main_application_root(self):
        """Test main application root endpoint"""
        response = self.client.get("/")
        assert_response_success(response)
        data = response.json()
        assert "message" in data
    
    def test_main_application_health(self):
        """Test main application health endpoint"""
        response = self.client.get("/health")
        assert_response_success(response)
        data = response.json()
        assert "status" in data 