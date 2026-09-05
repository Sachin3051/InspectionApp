import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _userName;
  int? _userId;

  bool get isLoading => _isLoading;
  String? get userName => _userName;
  int? get userId => _userId;

  AuthProvider() {
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    _userName = prefs.getString('userName');
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      
      if (response['success'] == true) {
        final userData = response['data'];
        _userId = userData['id'];
        _userName = userData['userName'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', _userId!);
        await prefs.setString('userName', _userName!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    _userId = null;
    _userName = null;

    notifyListeners();
  }

  bool get isAuthenticated => _userId != null;
}
