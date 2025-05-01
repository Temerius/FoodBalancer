import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../repositories/data_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Геттеры
  User? get user => _user;
  // Добавляем дополнительный геттер для совместимости со скринами
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Инициализация
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        try {
          _user = await _authService.getCurrentUser();
          _isAuthenticated = true;
        } catch (e) {
          // Если не удалось получить текущего пользователя, сбрасываем статус
          await _authService.saveLoginStatus(false);
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      _setError(e.toString());
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  // Регистрация
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.register(name, email, password);
      _isAuthenticated = true;

      // After successful registration, initialize user data in DataRepository
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Вход
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.login(email, password);
      _isAuthenticated = true;

      if (rememberMe) {
        await _authService.saveLoginStatus(true);
      }

      // After successful login, load user data in DataRepository
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Выход
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      await _authService.saveLoginStatus(false);
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load user data in DataRepository
  void loadUserDataInRepository(BuildContext context) {
    if (!_isAuthenticated || _user == null) return;

    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    if (!dataRepository.isInitialized) {
      dataRepository.initialize().then((_) {
        dataRepository.loadUserData();
      });
    } else {
      dataRepository.loadUserData();
    }
  }

  // Восстановление пароля
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Обновление профиля пользователя
  Future<bool> updateUserProfile(User updatedUser) async {
    _setLoading(true);
    _clearError();

    try {
      // Здесь будет запрос к API для обновления профиля
      // TODO: Добавить метод updateProfile в AuthService
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Вспомогательные методы
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}