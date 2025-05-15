
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService}) :
        _authService = authService ?? AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  
  User? get user => _user;
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  
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

  
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.register(name, email, password);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.login(email, password);
      _isAuthenticated = true;

      if (rememberMe) {
        await _authService.saveLoginStatus(true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  
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