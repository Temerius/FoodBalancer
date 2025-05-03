// api_test_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/foundation.dart';

class ApiTestService {
  // Base URL for your API
  final String baseUrl;

  // Headers
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Test data
  late String testEmail;
  late String testPassword;
  late String testName;
  String? token;

  // Constructor
  ApiTestService({required this.baseUrl}) {
    _initTestData();
  }

  // Initialize test data
  void _initTestData() {
    final random = Random();
    final randomString = List.generate(8,
            (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[random.nextInt(36)]
    ).join();

    testEmail = 'test_$randomString@example.com';
    testPassword = 'TestPassword123';
    testName = 'Test User $randomString';
  }

  // Run all tests
  Future<List<String>> runAllTests() async {
    List<String> logs = [];
    void logCallback(String message) {
      logs.add(message);
      if (kDebugMode) {
        print(message);
      }
    }

    logCallback('=== Starting API Tests ===');
    logCallback('Test user: $testEmail');

    try {
      // User management tests
      await _testRegisterUser(logCallback);
      await _testLoginUser(logCallback);
      await _testGetProfile(logCallback);

      // Core API tests
      await _testGetRefrigerator(logCallback);
      await _testGetFavorites(logCallback);
      await _testGetAllAllergens(logCallback);
      await _testGetAllEquipment(logCallback);

      // Logout
      await _testLogoutUser(logCallback);

      logCallback('=== All API Tests Completed ===');
    } catch (e) {
      logCallback('ERROR: Test execution failed - $e');
    }

    return logs;
  }

  // Helper to make API requests and log results
  Future<dynamic> _makeRequest(
      String method,
      String endpoint,
      Map<String, dynamic>? data,
      Function(String) logCallback,
      {bool requiresAuth = true}
      ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    Map<String, String> requestHeaders = {...headers};

    if (requiresAuth && token != null) {
      requestHeaders['Authorization'] = 'Token $token';
    }

    http.Response response;

    try {
      logCallback('REQUEST: $method $endpoint');
      if (data != null) {
        logCallback('REQUEST BODY: ${jsonEncode(data)}');
      }

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
              url,
              headers: requestHeaders,
              body: data != null ? jsonEncode(data) : null
          );
          break;
        case 'PUT':
          response = await http.put(
              url,
              headers: requestHeaders,
              body: data != null ? jsonEncode(data) : null
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Invalid method: $method');
      }

      logCallback('RESPONSE STATUS: ${response.statusCode}');

      // Try to parse JSON
      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = jsonDecode(response.body);
          final responseStr = jsonEncode(responseData);
          logCallback('RESPONSE BODY: ${responseStr.substring(0, min(responseStr.length, 200))}${responseStr.length > 200 ? '...' : ''}');
        } catch (e) {
          logCallback('RESPONSE BODY (not JSON): ${response.body.substring(0, min(response.body.length, 200))}${response.body.length > 200 ? '...' : ''}');
          return null;
        }
      }

      return responseData;
    } catch (e) {
      logCallback('REQUEST ERROR: $e');
      return null;
    }
  }

  // Test 1: Register User
  Future<void> _testRegisterUser(Function(String) logCallback) async {
    logCallback('\n=== TEST 1: Register User ===');

    // Looking at your model and the error, we need to use 'male' not 'MALE'
    final data = {
      'usr_mail': testEmail,
      'usr_name': testName,
      'password': testPassword,
      'usr_height': 180,
      'usr_weight': 75,
      'usr_age': 30,
      'usr_gender': 'male', // PostgreSQL enums are case-sensitive
      'usr_cal_day': 2000
    };

    final response = await _makeRequest(
        'POST',
        '/api/users/register/',
        data,
        logCallback,
        requiresAuth: false
    );

    if (response != null && response['token'] != null) {
      token = response['token'];
      logCallback('✅ Registration successful - token received');
    } else {
      logCallback('❌ Registration failed or user already exists');

      // Try alternative with MALE in uppercase if the first attempt failed
      logCallback('Trying with uppercase MALE...');
      final altData = {...data, 'usr_gender': 'MALE'};
      final altResponse = await _makeRequest(
          'POST',
          '/api/users/register/',
          altData,
          logCallback,
          requiresAuth: false
      );

      if (altResponse != null && altResponse['token'] != null) {
        token = altResponse['token'];
        logCallback('✅ Registration successful with uppercase MALE - token received');
      }
    }
  }

  // Test 2: Login User
  Future<void> _testLoginUser(Function(String) logCallback) async {
    logCallback('\n=== TEST 2: Login User ===');

    final data = {
      'email': testEmail,
      'password': testPassword
    };

    final response = await _makeRequest(
        'POST',
        '/api/users/login/',
        data,
        logCallback,
        requiresAuth: false
    );

    if (response != null && response['token'] != null) {
      token = response['token'];
      logCallback('✅ Login successful - token received');
    } else {
      logCallback('❌ Login failed');
    }
  }

  // Test 3: Get Profile
  Future<void> _testGetProfile(Function(String) logCallback) async {
    logCallback('\n=== TEST 3: Get Profile ===');

    final response = await _makeRequest('GET', '/api/users/profile/', null, logCallback);

    if (response != null) {
      logCallback('✅ Profile retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve profile');
    }
  }

  // Test 4: Get Refrigerator
  Future<void> _testGetRefrigerator(Function(String) logCallback) async {
    logCallback('\n=== TEST 4: Get Refrigerator ===');

    // Based on your backend code, correct endpoint is /api/refrigerator/
    final response = await _makeRequest('GET', '/api/refrigerator/', null, logCallback);

    if (response != null) {
      logCallback('✅ Refrigerator retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve refrigerator');
    }
  }

  // Test 5: Get Favorites
  Future<void> _testGetFavorites(Function(String) logCallback) async {
    logCallback('\n=== TEST 5: Get Favorites ===');

    // Based on your backend code, correct endpoint is /api/favorites/
    final response = await _makeRequest('GET', '/api/favorites/', null, logCallback);

    if (response != null) {
      logCallback('✅ Favorites retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve favorites');
    }
  }

  // Test 6: Get All Allergens
  Future<void> _testGetAllAllergens(Function(String) logCallback) async {
    logCallback('\n=== TEST 6: Get All Allergens ===');

    // Based on your backend code, correct endpoint is /api/allergens/
    final response = await _makeRequest('GET', '/api/allergens/', null, logCallback);

    if (response != null) {
      logCallback('✅ Allergens retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve allergens');
    }
  }

  // Test 7: Get All Equipment
  Future<void> _testGetAllEquipment(Function(String) logCallback) async {
    logCallback('\n=== TEST 7: Get All Equipment ===');

    // Based on your backend code, correct endpoint is /api/equipment/
    final response = await _makeRequest('GET', '/api/equipment/', null, logCallback);

    if (response != null) {
      logCallback('✅ Equipment retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve equipment');
    }
  }

  // Test 8: Logout User
  Future<void> _testLogoutUser(Function(String) logCallback) async {
    logCallback('\n=== TEST 8: Logout User ===');

    final response = await _makeRequest('POST', '/api/users/logout/', {}, logCallback);

    if (response != null) {
      token = null;
      logCallback('✅ Logout successful');
    } else {
      logCallback('❌ Logout failed');
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}