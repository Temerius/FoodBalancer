# api_test.py
import requests
import random
import string
import json

# Configuration
BASE_URL = "http://localhost:8000/api"

# These headers mimic a mobile app API client rather than a browser
HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json",  # Key header - tells server we only want JSON
    "User-Agent": "Flutter/1.0",  # Pretend to be Flutter
    "X-Requested-With": "XMLHttpRequest"  # Marks as AJAX request
}


def random_string(length=8):
    """Generate a random string for test data"""
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))


def test_register_and_login():
    """Test the registration and login endpoints"""
    print("\n=== Testing Registration and Login ===\n")

    # Create test user data
    test_email = f"test_{random_string()}@example.com"
    test_password = "TestPassword123"
    test_name = f"Test User {random_string()}"

    # Registration data
    register_data = {
        "usr_mail": test_email,
        "usr_name": test_name,
        "password": test_password,
        "usr_height": 180,
        "usr_weight": 75,
        "usr_age": 30,
        "usr_gender": "MALE",  # Using uppercase as in your model
        "usr_cal_day": 2000
    }

    # Test registration
    print(f"Registering user: {test_email}")
    register_url = f"{BASE_URL}/users/register/"
    response = requests.post(register_url, json=register_data, headers=HEADERS)

    print(f"Status: {response.status_code}")
    try:
        result = response.json()
        print(f"Response: {json.dumps(result, indent=2)}")

        if response.status_code == 201 and 'token' in result:
            token = result['token']
            auth_headers = HEADERS.copy()
            auth_headers["Authorization"] = f"Token {token}"

            # Test login
            print("\nTesting login...")
            login_url = f"{BASE_URL}/users/login/"
            login_data = {
                "email": test_email,
                "password": test_password
            }

            login_response = requests.post(login_url, json=login_data, headers=HEADERS)
            print(f"Login Status: {login_response.status_code}")
            login_result = login_response.json()
            print(f"Login Response: {json.dumps(login_result, indent=2)}")

            # Test profile
            print("\nTesting profile...")
            profile_url = f"{BASE_URL}/users/profile/"
            profile_response = requests.get(profile_url, headers=auth_headers)
            print(f"Profile Status: {profile_response.status_code}")
            profile_result = profile_response.json()
            print(f"Profile Response: {json.dumps(profile_result, indent=2)}")

            return True, token
        else:
            return False, None
    except Exception as e:
        print(f"Error: {str(e)}")
        print(f"Raw response: {response.text[:200]}...")
        return False, None


if __name__ == "__main__":
    success, token = test_register_and_login()
    if success:
        print("\n✅ Test completed successfully!")
    else:
        print("\n❌ Test failed")