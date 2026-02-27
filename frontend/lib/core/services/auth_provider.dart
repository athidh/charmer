import 'package:flutter/material.dart';
import 'api_service.dart';

/// Provider-based auth state management.
/// Stores JWT token, username, and role after login.
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? _token;
  String _username = 'Farmer';
  String _role = 'user';
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get token => _token;
  String get username => _username;
  String get role => _role;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiService get api => _api;

  /// Sign up a new user.
  /// Returns true on success, false on failure (check [error]).
  Future<bool> signup(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.signup(username, email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Is the server running?';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log in an existing user.
  /// Returns true on success, false on failure (check [error]).
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email, password);
      _token = data['token'] as String;
      _username = data['username'] as String? ?? 'Farmer';
      _role = data['role'] as String? ?? 'user';
      _api.setToken(_token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Is the server running?';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log out and clear all session data.
  void logout() {
    _token = null;
    _username = 'Farmer';
    _role = 'user';
    _error = null;
    _api.clearToken();
    notifyListeners();
  }
}
