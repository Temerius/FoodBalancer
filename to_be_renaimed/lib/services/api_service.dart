import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Для эмулятора Android
  // static const String baseUrl = 'http://10.0.2.2:8000';
  // Для реального устройства (замените на свой IP)
  static const String baseUrl = 'http://192.168.100.5:8000';

  // Отключаем моковые ответы
  static const bool useMockResponses = false;

  // Эндпоинты
  static const String loginUrl = '/api/users/login/';
  static const String registerUrl = '/api/users/register/';
  static const String profileUrl = '/api/users/profile/';
  static const String passwordResetUrl = '/api/users/password-reset/';
  static const String passwordResetConfirmUrl = '/api/users/password-reset/confirm/';
  static const String logoutUrl = '/api/users/logout/';

  // HTTP клиент
  final http.Client _client = http.Client();

  // Заголовки по умолчанию
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  // Токен авторизации
  String? _token;

  // Установка токена
  void setToken(String token) {
    _token = token;
  }

  // Очистка токена
  void clearToken() {
    _token = null;
  }

  // GET запрос
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // POST запрос
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // PUT запрос
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // DELETE запрос
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // Добавьте в начало файла этот импорт


// Обновите метод _handleResponse
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      // Обработка ошибок
      String errorMessage = 'Ошибка сервера: ${response.statusCode}';

      try {
        var errorData = jsonDecode(utf8.decode(response.bodyBytes));

        if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('errors')) {
          // Обработка объекта с ошибками
          final errors = errorData['errors'];
          if (errors is Map) {
            List<String> errorList = [];
            errors.forEach((key, value) {
              if (value is List) {
                errorList.add('$key: ${value.join(', ')}');
              } else {
                errorList.add('$key: $value');
              }
            });
            errorMessage = errorList.join('. ');
          } else if (errors is String) {
            errorMessage = errors;
          }
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (e) {
        // Если не удалось распарсить JSON или мы не смогли найти подходящее сообщение
        if (response.bodyBytes.isNotEmpty) {
          try {
            // Просто декодируем тело как текст в UTF-8
            errorMessage = utf8.decode(response.bodyBytes);
          } catch (_) {
            // Если и это не работает, оставляем стандартное сообщение
          }
        }
      }

      // Обрабатываем специфические случаи ошибок
      if (errorMessage.contains("already exists") ||
          errorMessage.contains("уже существует")) {
        errorMessage = "Пользователь с таким email уже существует";
      }

      throw Exception(errorMessage);
    }
  }

  Map<String, dynamic> _getMockResponse(String endpoint, [Map<String, dynamic>? data]) {
    // Мок для регистрации
    if (endpoint == '/register/') {
      return {
        'user': {
          'usr_id': 1,
          'usr_name': data?['name'] ?? 'Тестовый пользователь',
          'usr_mail': data?['email'] ?? 'test@example.com',
          'usr_height': null,
          'usr_weight': null,
          'usr_age': null,
          'usr_gender': 'male',
          'usr_cal_day': null,
        },
        'token': 'mock_token_12345',
      };
    }

    // Мок для входа
    if (endpoint == '/token/') {
      // Проверка моковых учетных данных
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
        throw Exception('Неверный email или пароль');
      }
    }

    // Мок для восстановления пароля
    if (endpoint == '/password-reset/') {
      return {
        'success': true,
        'message': 'Инструкции по восстановлению пароля отправлены на указанный email',
      };
    }

    // Мок для данных пользователя
    if (endpoint == '/users/me/') {
      return {
        'usr_id': 1,
        'usr_name': 'Тестовый пользователь',
        'usr_mail': 'test@example.com',
        'usr_height': 180,
        'usr_weight': 75,
        'usr_age': 30,
        'usr_gender': 'male',
        'usr_cal_day': 2000,
      };
    }

    // Для всех остальных эндпоинтов
    return {'message': 'Мок-ответ для $endpoint'};
  }
}