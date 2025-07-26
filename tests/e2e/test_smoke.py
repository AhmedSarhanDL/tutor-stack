#!/usr/bin/env python3
"""
Comprehensive smoke test for Tutor Stack API endpoints
"""
import pytest
import requests
import json
import sys
import time
from typing import Dict, Any
from tests.utils import APITestClient, generate_unique_email, assert_response_success


@pytest.mark.e2e
@pytest.mark.slow
class TestSmokeTest:
    """Comprehensive smoke test for all API endpoints"""
    
    @pytest.fixture(autouse=True)
    def setup(self, base_url: str):
        """Setup test client"""
        self.client = APITestClient(base_url)
        self.test_email = generate_unique_email()
    
    def test_all_endpoints(self):
        """Test all major endpoints in the application"""
        total = 0
        passed = 0
        
        # Test main application endpoints
        total += 1
        if self._test_endpoint("GET", "/", expected_status=200):
            passed += 1
        
        total += 1
        if self._test_endpoint("GET", "/health", expected_status=200):
            passed += 1
        
        # Test auth service endpoints
        total += 1
        if self._test_endpoint("GET", "/auth/", expected_status=200):
            passed += 1
        
        total += 1
        if self._test_endpoint("POST", "/auth/register", 
                              {"email": self.test_email, "password": "testpass123"}, 
                              expected_status=201):
            passed += 1
        
        total += 1
        if self._test_endpoint("POST", "/auth/jwt/login", 
                              {"username": self.test_email, "password": "testpass123"}, 
                              expected_status=200, use_form_data=True):
            passed += 1
        
        # Test other service health endpoints
        total += 1
        if self._test_endpoint("GET", "/content/health", expected_status=200):
            passed += 1
        
        total += 1
        if self._test_endpoint("GET", "/assessment/health", expected_status=200):
            passed += 1
        
        total += 1
        if self._test_endpoint("GET", "/notify/health", expected_status=200):
            passed += 1
        
        total += 1
        if self._test_endpoint("GET", "/chat/health", expected_status=200):
            passed += 1
        
        # Test notify service POST endpoint
        total += 1
        if self._test_endpoint("POST", "/notify/", {"message": "test"}, expected_status=200):
            passed += 1
        
        # Test OpenAPI schema
        total += 1
        if self._test_endpoint("GET", "/openapi.json", expected_status=200):
            passed += 1
        
        # Test auth service OpenAPI schema
        total += 1
        if self._test_endpoint("GET", "/auth/openapi.json", expected_status=200):
            passed += 1
        
        # Print results
        print(f"\n🎯 Smoke Test Results: {passed}/{total} tests passed")
        
        if passed == total:
            print("✅ All smoke tests passed!")
        else:
            print(f"❌ {total - passed} tests failed")
            pytest.fail(f"Smoke test failed: {passed}/{total} tests passed")
    
    def _test_endpoint(self, method: str, endpoint: str, data: Dict[str, Any] = None, 
                      expected_status: int = 200, use_form_data: bool = False) -> bool:
        """Test a single endpoint"""
        try:
            if method.upper() == "GET":
                response = self.client.get(endpoint)
            elif method.upper() == "POST":
                if use_form_data:
                    response = self.client.session.post(
                        f"{self.client.base_url}{endpoint}",
                        data=data,
                        headers={"Content-Type": "application/x-www-form-urlencoded"},
                        timeout=self.client.timeout
                    )
                else:
                    response = self.client.post(endpoint, data)
            else:
                print(f"❌ Unsupported method: {method}")
                return False
            
            if response.status_code == expected_status:
                print(f"✅ {method} {endpoint} - {response.status_code}")
                return True
            else:
                print(f"❌ {method} {endpoint} - Expected {expected_status}, got {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ {method} {endpoint} - Exception: {str(e)}")
            return False 