import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService({ApiService? apiService}) :
        _apiService = apiService ?? ApiService();
  static const String _tokenKey = 'auth_token';

  // Инициализация - проверяем наличие сохраненного токена
  Future<void> initialize() async {
    final token = await _getToken();
    if (token != null) {
      _apiService.setToken(token);
    }
  }

  // Регистрация
  // В методе register в классе AuthService
  Future<User> register(String name, String email, String password) async {
    try {
      final response = await _apiService.post('/api/users/register/', {
        'usr_name': name,
        'usr_mail': email,
        'password': password,
      });

      final String token = response['token'];
      final user = User.fromJson(response['user']);

      await _saveToken(token);
      _apiService.setToken(token);

      return user;
    } catch (e) {
      String errorMessage = e.toString();

      // Обработка специфичных ошибок
      if (errorMessage.contains("Unique") ||
          errorMessage.contains("unique") ||
          errorMessage.contains("уже существует") ||
          errorMessage.contains("already exists")) {
        throw Exception('Пользователь с таким email уже существует');
      }

      // Обработка юникод-последовательностей в ошибке
      if (errorMessage.contains('\\u')) {
        try {
          // Извлекаем часть после "Exception: "
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring('Exception: '.length);
          }

          // Убираем экранирование для JSON
          errorMessage = errorMessage.replaceAll('\\', '');

          // Пытаемся распарсить JSON
          var jsonStart = errorMessage.indexOf('{');
          var jsonEnd = errorMessage.lastIndexOf('}');

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            var jsonString = errorMessage.substring(jsonStart, jsonEnd + 1);
            var errorJson = jsonDecode(jsonString);

            if (errorJson.containsKey('error')) {
              errorMessage = errorJson['error'];
            }
          }
        } catch (_) {
          // Если не удалось обработать, оставляем как есть
        }
      }

      throw Exception(errorMessage);
    }
  }

  // Вход
  Future<User> login(String email, String password) async {
    final response = await _apiService.post(ApiService.loginUrl, {
      'email': email,
      'password': password,
    });

    final String token = response['token'];
    final user = User.fromJson(response['user']);

    // Устанавливаем токен в ApiService
    _apiService.setToken(token);

    // Сохраняем токен
    await _saveToken(token);

    return user;
  }

  // Выход
  Future<void> logout() async {
    try {
      await _apiService.post(ApiService.logoutUrl, {});
    } catch (e) {
      // Если выход не удался, все равно очищаем локальные данные
      print('Error logging out: $e');
    }

    await _clearToken();
    _apiService.clearToken();
  }

  // Восстановление пароля
  Future<void> resetPassword(String email) async {
    await _apiService.post(ApiService.passwordResetUrl, {
      'email': email,
    });
  }

  // Подтверждение восстановления пароля
  Future<bool> confirmResetPassword(String token, String newPassword) async {
    try {
      await _apiService.post(ApiService.passwordResetConfirmUrl, {
        'token': token,
        'password': newPassword,
      });
      return true;
    } catch (e) {
      print('Error confirming password reset: $e');
      return false;
    }
  }

  // Получение данных текущего пользователя
  Future<User> getCurrentUser() async {
    final response = await _apiService.get(ApiService.profileUrl);
    return User.fromJson(response);
  }

  // Обновление профиля пользователя
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put(ApiService.profileUrl, data);
    return User.fromJson(response);
  }

  // Проверка авторизации
  Future<bool> isAuthenticated() async {
    return await _getToken() != null;
  }

  // Методы для работы с токеном в SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static const String _isLoggedInKey = 'is_logged_in';

// Сохранение статуса входа
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

// Проверка статуса входа
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // В классе AuthService (services/auth_service.dart)
  String? getToken() {
    return _tokenKey;
  }
}