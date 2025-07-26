#!/usr/bin/env python3
"""Test script for the auth service"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Health check: {response.status_code} - {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_auth_endpoints():
    """Test auth endpoints"""
    print("\nTesting auth endpoints...")
    
    # Test auth service root
    try:
        response = requests.get(f"{BASE_URL}/auth/")
        print(f"Auth root: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Auth root failed: {e}")
    
    # Test registration endpoint
    try:
        response = requests.get(f"{BASE_URL}/auth/register")
        print(f"Register endpoint: {response.status_code}")
    except Exception as e:
        print(f"Register endpoint failed: {e}")

def test_protected_endpoints():
    """Test protected endpoints (should fail without token)"""
    print("\nTesting protected endpoints (should fail without token)...")
    
    endpoints = ["/content", "/assessment", "/notify", "/chat"]
    
    for endpoint in endpoints:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}")
            print(f"{endpoint}: {response.status_code}")
        except Exception as e:
            print(f"{endpoint} failed: {e}")

if __name__ == "__main__":
    print("=== Tutor Stack Auth Test ===")
    
    if test_health():
        test_auth_endpoints()
        test_protected_endpoints()
    else:
        print("Health check failed, skipping other tests") 