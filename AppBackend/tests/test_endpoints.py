#!/usr/bin/env python
"""
Django API Endpoint Tester

This script tests the API endpoints in your Django backend.
It prints a detailed report of which endpoints are working and which are not.

Usage:
    python test_endpoints.py

Place this file in your AppBackend directory and run it while the server is running.
"""

import os
import sys
import json
import requests
from urllib.parse import urljoin

# Configuration
BASE_URL = "http://localhost:8000"  # Change this to your server URL
ENDPOINTS = [
    # Authentication endpoints
    {"path": "/api/users/register/", "method": "POST", "data": {
        "usr_mail": "test_endpoint@example.com",
        "usr_name": "Test User",
        "password": "TestPassword123",
        "usr_gender": "male",
        "usr_height": 180,
        "usr_weight": 75,
        "usr_age": 30,
        "usr_cal_day": 2000
    }},
    {"path": "/api/users/login/", "method": "POST", "data": {
        "email": "test_endpoint@example.com",
        "password": "TestPassword123"
    }},

    # Core endpoints
    {"path": "/api/allergens/", "method": "GET"},
    {"path": "/api/equipment/", "method": "GET"},
    {"path": "/api/ingredient-types/", "method": "GET"},
    {"path": "/api/ingredients/", "method": "GET"},
    {"path": "/api/recipes/", "method": "GET"},
    {"path": "/api/steps/", "method": "GET"},
    {"path": "/api/meal-plans/", "method": "GET"},
    {"path": "/api/daily-plans/", "method": "GET"},
    {"path": "/api/meals/", "method": "GET"},
    {"path": "/api/shopping-list/", "method": "GET"}
]


def check_endpoint(endpoint, token=None):
    """Check if an endpoint is working properly."""
    url = urljoin(BASE_URL, endpoint["path"])
    method = endpoint["method"]
    data = endpoint.get("data", {})

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    if token:
        headers["Authorization"] = f"Token {token}"

    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data)
        elif method == "PUT":
            response = requests.put(url, headers=headers, json=data)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers)
        else:
            return {
                "status": "error",
                "message": f"Unknown method: {method}",
                "code": None
            }

        return {
            "status": "success" if response.status_code < 400 else "error",
            "code": response.status_code,
            "content": response.text[:200] + "..." if len(response.text) > 200 else response.text
        }
    except requests.RequestException as e:
        return {
            "status": "error",
            "message": str(e),
            "code": None
        }


def run_tests():
    """Run tests for all endpoints and print results."""
    token = None
    results = []

    print("\n========== Django API Endpoint Tester ==========\n")
    print(f"Server URL: {BASE_URL}\n")

    for endpoint in ENDPOINTS:
        result = check_endpoint(endpoint, token)
        results.append({
            "endpoint": endpoint["path"],
            "method": endpoint["method"],
            "result": result
        })

        # If this is a login endpoint and it succeeded, save the token
        if endpoint["path"] == "/api/users/login/" and result["status"] == "success":
            try:
                response_data = json.loads(result["content"])
                if "token" in response_data:
                    token = response_data["token"]
                    print(f"Successfully logged in. Got token: {token}\n")
            except:
                pass

    # Print results
    print("\n========== Test Results ==========\n")

    working = []
    not_working = []

    for result in results:
        if result["result"]["status"] == "success":
            working.append(result)
        else:
            not_working.append(result)

    # Print working endpoints
    print(f"✅ Working Endpoints: {len(working)}/{len(results)}")
    for result in working:
        print(f"  {result['method']} {result['endpoint']} - {result['result']['code']}")

    # Print non-working endpoints
    if not_working:
        print(f"\n❌ Non-Working Endpoints: {len(not_working)}/{len(results)}")
        for result in not_working:
            print(f"  {result['method']} {result['endpoint']} - {result['result']['code'] or 'Error'}")
            if "message" in result["result"]:
                print(f"    Message: {result['result']['message']}")
            else:
                print(f"    Content: {result['result']['content']}")

    # Also print details about the URL configuration
    try:
        url = urljoin(BASE_URL, "/api/debug/url-patterns/")
        response = requests.get(url)
        if response.status_code == 200:
            url_patterns = response.json()
            print("\n========== URL Patterns ==========\n")
            for pattern in url_patterns:
                print(f"  {pattern}")
    except:
        # If this fails, it's not critical
        pass

    print("\n=======================================\n")


run_tests()