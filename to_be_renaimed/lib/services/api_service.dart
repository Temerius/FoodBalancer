import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_util.dart';


class ApiService {
  
  static const String baseUrl = 'http://192.168.151.120:8000';

  
  static const bool useMockResponses = false;

  static const bool DEBUG = true;
  
  static const String loginUrl = '/api/users/login/';
  static const String registerUrl = '/api/users/register/';
  static const String profileUrl = '/api/users/profile/';
  static const String passwordResetUrl = '/api/users/password-reset/';
  static const String passwordResetConfirmUrl = '/api/users/password-reset/confirm/';
  static const String logoutUrl = '/api/users/logout/';

  
  static const String _tokenKey = 'auth_token';

  
  static const int defaultCacheTime = 24 * 60 * 60 * 1000; 

  
  final http.Client _client = http.Client();

  
  final NetworkUtil _networkUtil = NetworkUtil();

  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  
  String? _token;

  
  void setToken(String token) {
    _token = token;
  }

  String? getCurrentToken() {
    return _token;
  }

  
  void clearToken() {
    _token = null;
  }

  
  Future<void> initialize() async {
    await _networkUtil.initialize();

    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _token = token;
      print('Токен аутентификации восстановлен');
    } else {
      print('Токен аутентификации не найден');
    }
  }

  
  Future<List<dynamic>> getAllPaginatedResults(String endpoint, {int pageSize = 1000}) async {
    
    try {
      if (DEBUG) {
        print('API Request (No Pagination): GET $baseUrl$endpoint');
      }

      final hasConnection = await _networkUtil.checkConnection();
      if (!hasConnection) {
        throw NoConnectionException(
            'Нет подключения к интернету. Запрос: GET $endpoint'
        );
      }

      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (DEBUG) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body.substring(0,
            response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];

        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));

          
          if (decoded is List) {
            
            return decoded;
          } else if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
            
            return decoded['results'] as List<dynamic>;
          } else {
            
            throw FormatException('Неожиданный формат ответа: ${decoded.runtimeType}');
          }
        } catch (e) {
          throw FormatException('Ошибка при декодировании ответа: $e');
        }
      } else {
        
        String errorMessage = 'Ошибка сервера: ${response.statusCode}';

        
        try {
          var errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (_) {
          
        }

        throw ApiException(errorMessage);
      }
    } catch (e) {
      if (DEBUG) {
        print('API Error getting results: $e');
      }
      rethrow;
    }
  }

  
  Future<Map<String, dynamic>> get(String endpoint) async {
    
    final hasConnection = await _networkUtil.checkConnection();
    if (!hasConnection) {
      throw NoConnectionException(
          'Нет подключения к интернету. Запрос: GET $endpoint'
      );
    }

    try {
      if (DEBUG) {
        print('API Request: GET $baseUrl$endpoint');
        print('Headers: $_headers');
      }

      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (DEBUG) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body.substring(0,
            response.body.length > 200 ? 200 : response.body.length)}...');
      }

      return _handleResponse(response);
    } catch (e) {
      if (DEBUG) {
        print('API Error: $e');
      }
      throw ApiException('Ошибка при запросе: $e. Запрос: GET $endpoint');
    }
  }


  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    
    final hasConnection = await _networkUtil.checkConnection();
    if (!hasConnection) {
      throw NoConnectionException(
          'Нет подключения к интернету. Запрос: POST $endpoint'
      );
    }

    if (DEBUG) {
      print('API Request: POST $baseUrl$endpoint');
      print('Headers: $_headers');
      print('Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException(
          'Ошибка соединения с сервером. Запрос: POST $endpoint'
      );
    } on TimeoutException {
      throw TimeoutException(
          'Превышено время ожидания ответа от сервера. Запрос: POST $endpoint'
      );
    } catch (e) {
      throw ApiException('Ошибка при запросе: $e. Запрос: POST $endpoint');
    }
  }

  
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    
    final hasConnection = await _networkUtil.checkConnection();
    if (!hasConnection) {
      throw NoConnectionException(
          'Нет подключения к интернету. Запрос: PUT $endpoint'
      );
    }
    if (DEBUG) {
      print('API Request: PUT $baseUrl$endpoint');
      print('Headers: $_headers');
      print('Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException(
          'Ошибка соединения с сервером. Запрос: PUT $endpoint'
      );
    } on TimeoutException {
      throw TimeoutException(
          'Превышено время ожидания ответа от сервера. Запрос: PUT $endpoint'
      );
    } catch (e) {
      throw ApiException('Ошибка при запросе: $e. Запрос: PUT $endpoint');
    }
  }

  
  



  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? data}) async {
    
    final hasConnection = await _networkUtil.checkConnection();
    if (!hasConnection) {
      throw NoConnectionException(
          'Нет подключения к интернету. Запрос: DELETE $endpoint'
      );
    }

    if (DEBUG) {
      print('API Request: DELETE $baseUrl$endpoint');
      print('Headers: $_headers');
      if (data != null) {
        print('Body: ${jsonEncode(data)}');
      }
    }

    try {
      http.Response response;

      if (data != null) {
        
        final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
        request.headers.addAll(_headers);
        request.body = jsonEncode(data);

        final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 15));
        response = await http.Response.fromStream(streamedResponse);
      } else {
        
        response = await _client.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
        ).timeout(const Duration(seconds: 15));
      }

      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException(
          'Ошибка соединения с сервером. Запрос: DELETE $endpoint'
      );
    } on TimeoutException {
      throw TimeoutException(
          'Превышено время ожидания ответа от сервера. Запрос: DELETE $endpoint'
      );
    } catch (e) {
      throw ApiException('Ошибка при запросе: $e. Запрос: DELETE $endpoint');
    }
  }

  Future<Map<String, dynamic>> getWithExtendedTimeout(String endpoint, {Duration timeout = const Duration(seconds: 60)}) async {
    
    final hasConnection = await _networkUtil.checkConnection();
    if (!hasConnection) {
      throw NoConnectionException(
          'Нет подключения к интернету. Запрос: GET $endpoint'
      );
    }

    try {
      if (DEBUG) {
        print('API Request (Extended Timeout: ${timeout.inSeconds}s): GET $baseUrl$endpoint');
        print('Headers: $_headers');
      }

      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout); 

      if (DEBUG) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body.substring(0,
            response.body.length > 200 ? 200 : response.body.length)}...');
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is TimeoutException) {
        
        if (DEBUG) {
          print('API Request Timeout: $e');
        }
        throw TimeoutException(
            'Превышено время ожидания ответа от сервера (${timeout.inSeconds} сек). '
                'Возможно, сервер занят обработкой других запросов. Запрос: GET $endpoint'
        );
      } else {
        
        if (DEBUG) {
          print('API Error: $e');
        }
        throw ApiException('Ошибка при запросе: $e. Запрос: GET $endpoint');
      }
    }
  }

  
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};

      try {
        dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

        
        if (decoded is List) {
          return {'results': decoded};
        } else if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw FormatException('Неожиданный формат ответа: ${decoded.runtimeType}');
        }
      } catch (e) {
        throw FormatException('Ошибка при декодировании ответа: $e');
      }
    } else {
      
      String errorMessage = 'Ошибка сервера: ${response.statusCode}';

      
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        
        if (response.statusCode == 404) {
          errorMessage = 'Эндпоинт не найден: ${response.request?.url.path}';
        } else {
          errorMessage = 'Сервер вернул HTML-страницу вместо ожидаемого JSON ответа';
        }
      } else {
        
        try {
          var errorData = jsonDecode(utf8.decode(response.bodyBytes));
          
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('error')) {
              errorMessage = errorData['error'];
            } else if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'];
            }
          }
        } catch (e) {
          
          if (response.bodyBytes.isNotEmpty) {
            try {
              errorMessage = utf8.decode(response.bodyBytes);
            } catch (_) {
              
            }
          }
        }
      }

      
      if (response.statusCode == 401) {
        throw UnauthorizedException(errorMessage);
      } else if (response.statusCode == 403) {
        throw ForbiddenException(errorMessage);
      } else if (response.statusCode == 404) {
        throw NotFoundException(errorMessage);
      } else if (response.statusCode >= 500) {
        throw ServerException(errorMessage);
      } else {
        throw ApiException(errorMessage);
      }
    }
  }

  
  Map<String, dynamic> _getMockResponse(String endpoint, [Map<String, dynamic>? data]) {
    
    if (endpoint == '/api/users/register/') {
      return {
        'user': {
          'usr_id': 1,
          'usr_name': data?['usr_name'] ?? 'Тестовый пользователь',
          'usr_mail': data?['usr_mail'] ?? 'test@example.com',
          'usr_height': null,
          'usr_weight': null,
          'usr_age': null,
          'usr_gender': null,
          'usr_cal_day': null,
        },
        'token': 'mock_token_12345',
      };
    }

    if (DEBUG) {
      print('API Request: PUT $baseUrl$endpoint');
      print('Headers: $_headers');
      print('Body: ${jsonEncode(data)}');
    }

    
    if (endpoint == '/api/users/login/') {
      
      if (data?['email'] == 'test@example.com' && data?['password'] == 'password') {
        return {
          'user': {
            'usr_id': 1,
            'usr_name': 'Тестовый пользователь',
            'usr_mail': 'test@example.com',
            'usr_height': 180,
            'usr_weight': 75,
            'usr_age': 30,
            'usr_gender': 'male',
            'usr_cal_day': 2000,
          },
          'token': 'mock_token_12345',
        };
      } else {
        throw ApiException('Неверный email или пароль');
      }
    }

    
    return {'message': 'Мок-ответ для $endpoint'};
  }
}


class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NoConnectionException extends ApiException {
  NoConnectionException(String message) : super(message);
}

class TimeoutException extends ApiException {
  TimeoutException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}