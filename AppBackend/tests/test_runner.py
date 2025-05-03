#!/usr/bin/env python3
"""
Test Runner for CookHelper API Tests

This script executes the test suite against the CookHelper API server.
It provides clear reporting of test results and can be configured to run
specific test cases or all tests.

Usage:
    python test_runner.py [--server URL] [--verbose] [--test TEST_NAME] [--check-config]

Options:
    --server URL       Base URL for the API server (default: http://localhost:8000/api)
    --verbose          Enable verbose output
    --test TEST_NAME   Run only the specified test method
    --check-config     Check server configuration before running tests
"""

import unittest
import sys
import argparse
import time
import os
import subprocess
import requests
from db_tests import CookHelperAPITestSuite


def check_server_config(server_url):
    """Check server configuration for common issues"""
    print("\n=== Checking Server Configuration ===\n")

    # Extract base URL without the /api suffix
    base_url = server_url.rsplit('/api', 1)[0]

    # Check if server is running
    try:
        response = requests.get(base_url)
        print(f"✅ Server is running at {base_url}")
    except requests.ConnectionError:
        print(f"❌ Server is not running at {base_url}")
        print("  Please start the Django server before running tests")
        return False

    # Check for Django Debug Toolbar issues
    try:
        debug_url = f"{base_url}/__debug__/"
        response = requests.get(debug_url)
        if response.status_code == 404:
            print("⚠️ Django Debug Toolbar URLs may not be properly configured")
            print("  Consider running the debug_toolbar_fix.py script")
    except requests.RequestException:
        print("⚠️ Could not verify Debug Toolbar configuration")

    # Check API endpoint
    try:
        response = requests.get(f"{server_url}/allergens/")
        if response.status_code in (401, 403):
            print("✅ API endpoints are responding (authentication required)")
        elif response.status_code == 200:
            print("✅ API endpoints are accessible")
        else:
            print(f"⚠️ API endpoints returned unexpected status code: {response.status_code}")
    except requests.RequestException:
        print("❌ API endpoints are not responding correctly")
        print("  There might be an issue with your API configuration")
        return False

    # Check if debug_toolbar_fix.py exists and offer to run it
    if os.path.exists("debug_toolbar_fix.py"):
        print("\nThe debug_toolbar_fix.py script was found.")
        choice = input("Would you like to run it to fix potential issues? (y/n): ")
        if choice.lower() == 'y':
            try:
                subprocess.run([sys.executable, "debug_toolbar_fix.py"], check=True)
                print("You might need to restart your Django server for changes to take effect.")
                choice = input("Would you like to continue with the tests? (y/n): ")
                if choice.lower() != 'y':
                    return False
            except subprocess.CalledProcessError:
                print("Failed to run the fix script")

    print("\nConfiguration check complete. Proceeding with tests...\n")
    return True


def run_tests(server_url=None, verbose=False, test_pattern=None, check_config=False):
    """Run the test suite with the specified options"""

    # Check server configuration if requested
    if check_config:
        if not check_server_config(server_url):
            return 1

    # Configure the test suite
    if server_url:
        CookHelperAPITestSuite.base_url = server_url

    # Create the test suite
    loader = unittest.TestLoader()

    if test_pattern:
        suite = loader.loadTestsFromName(f'api_test_suite.CookHelperAPITestSuite.{test_pattern}')
    else:
        suite = loader.loadTestsFromTestCase(CookHelperAPITestSuite)

    # Configure the test runner
    runner = unittest.TextTestRunner(verbosity=2 if verbose else 1)

    # Run the tests
    print("\n=== CookHelper API Test Suite ===\n")
    print(f"Server: {CookHelperAPITestSuite.base_url}")
    print(f"Running {suite.countTestCases()} tests...\n")

    start_time = time.time()
    result = runner.run(suite)
    end_time = time.time()

    # Report results
    print("\n=== Test Results ===\n")
    print(f"Ran {result.testsRun} tests in {end_time - start_time:.2f} seconds")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")

    if result.failures:
        print(f"Failures: {len(result.failures)}")
        for i, failure in enumerate(result.failures, 1):
            print(f"  {i}. {failure[0]}")
            if verbose:
                print(f"     Error: {failure[1]}")

    if result.errors:
        print(f"Errors: {len(result.errors)}")
        for i, error in enumerate(result.errors, 1):
            print(f"  {i}. {error[0]}")
            if verbose:
                print(f"     Error: {error[1]}")

    # Look for common patterns in errors
    error_texts = [err[1] for err in result.errors + result.failures]
    if any("NoReverseMatch: 'djdt'" in err for err in error_texts):
        print("\n⚠️ Debug Toolbar configuration issue detected!")
        print("Run debug_toolbar_fix.py to fix this issue.")

    if any("ConnectionError" in err for err in error_texts):
        print("\n⚠️ Connection errors detected!")
        print("Make sure your Django server is running.")

    if any("401 Client Error: Unauthorized" in err for err in error_texts):
        print("\n⚠️ Authentication errors detected!")
        print("User registration or login tests may be failing.")

    if not result.failures and not result.errors:
        print("\n✅ All tests passed!")
        return 0
    else:
        print("\n❌ Some tests failed or had errors.")
        return 1


def main():
    """Parse command line arguments and run tests"""
    parser = argparse.ArgumentParser(description='Run CookHelper API tests')
    parser.add_argument('--server', dest='server_url',
                        default='http://localhost:8000/api',
                        help='Base URL for the API server')
    parser.add_argument('--verbose', dest='verbose',
                        action='store_true',
                        help='Enable verbose output')
    parser.add_argument('--test', dest='test_pattern',
                        help='Run only the specified test method')
    parser.add_argument('--check-config', dest='check_config',
                        action='store_true',
                        help='Check server configuration before running tests')

    args = parser.parse_args()

    try:
        return run_tests(args.server_url, args.verbose, args.test_pattern, args.check_config)
    except KeyboardInterrupt:
        print("\nTest run interrupted by user.")
        return 130


if __name__ == '__main__':
    sys.exit(main())