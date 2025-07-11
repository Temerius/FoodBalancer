
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/foundation.dart';

class ApiTestService {
  
  final String baseUrl;

  
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  
  late String testEmail;
  late String testPassword;
  late String testName;
  String? token;

  
  ApiTestService({required this.baseUrl}) {
    _initTestData();
  }

  
  void _initTestData() {
    final random = Random();
    final randomString = List.generate(8,
            (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[random.nextInt(36)]
    ).join();

    testEmail = 'test_$randomString@example.com';
    testPassword = 'TestPassword123';
    testName = 'Test User $randomString';
  }

  
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
      
      await _testRegisterUser(logCallback);
      await _testLoginUser(logCallback);
      await _testGetProfile(logCallback);

      
      if (token != null) {
        await _testGetRefrigerator(logCallback);
        await _testGetFavorites(logCallback);
        await _testGetAllAllergens(logCallback);
        await _testGetAllEquipment(logCallback);

        
        await _testLogoutUser(logCallback);
      } else {
        logCallback('❌ Authentication failed - skipping API tests');
      }

      logCallback('=== All API Tests Completed ===');
    } catch (e) {
      logCallback('ERROR: Test execution failed - $e');
    }

    return logs;
  }

  
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
      logCallback('Using token: ${token?.substring(0, min(token!.length, 10))}...');  
    }

    http.Response response;

    try {
      logCallback('REQUEST: $method $endpoint');
      if (data != null) {
        logCallback('REQUEST BODY: ${jsonEncode(data)}');
      }

      
      logCallback('REQUEST HEADERS: ${requestHeaders.toString()}');

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

  
  Future<void> _testRegisterUser(Function(String) logCallback) async {
    logCallback('\n=== TEST 1: Register User ===');

    
    final data = {
      'usr_mail': testEmail,
      'usr_name': testName,
      'password': testPassword
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
    }
  }

  
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

  
  Future<void> _testGetProfile(Function(String) logCallback) async {
    logCallback('\n=== TEST 3: Get Profile ===');

    final response = await _makeRequest('GET', '/api/users/profile/', null, logCallback);

    if (response != null) {
      logCallback('✅ Profile retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve profile');
    }
  }

  
  Future<void> _testGetRefrigerator(Function(String) logCallback) async {
    logCallback('\n=== TEST 4: Get Refrigerator ===');

    
    final response = await _makeRequest('GET', '/api/refrigerator/', null, logCallback);

    if (response != null) {
      logCallback('✅ Refrigerator retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve refrigerator');
    }
  }

  
  Future<void> _testGetFavorites(Function(String) logCallback) async {
    logCallback('\n=== TEST 5: Get Favorites ===');

    
    final response = await _makeRequest('GET', '/api/favorites/', null, logCallback);

    if (response != null) {
      logCallback('✅ Favorites retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve favorites');
    }
  }

  
  Future<void> _testGetAllAllergens(Function(String) logCallback) async {
    logCallback('\n=== TEST 6: Get All Allergens ===');

    
    final response = await _makeRequest('GET', '/api/allergens/', null, logCallback);

    if (response != null) {
      logCallback('✅ Allergens retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve allergens');
    }
  }

  
  Future<void> _testGetAllEquipment(Function(String) logCallback) async {
    logCallback('\n=== TEST 7: Get All Equipment ===');

    
    final response = await _makeRequest('GET', '/api/equipment/', null, logCallback);

    if (response != null) {
      logCallback('✅ Equipment retrieved successfully');
    } else {
      logCallback('❌ Failed to retrieve equipment');
    }
  }

  
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