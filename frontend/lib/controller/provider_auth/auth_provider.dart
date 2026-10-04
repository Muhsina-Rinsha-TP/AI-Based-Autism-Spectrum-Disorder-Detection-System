import 'dart:convert';
import 'package:autism_project/services/api_service.dart';
import 'package:autism_project/services/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final String? userRole;
  final String? error;
  final bool isLoading;
  final Map<String, dynamic>? userData;
  final String? token;

  AuthState({
    this.isAuthenticated = false,
    this.userName,
    this.userRole,
    this.error,
    this.isLoading = false,
    this.userData,
    this.token,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? userRole,
    String? error,
    bool? isLoading,
    Map<String, dynamic>? userData,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      userData: userData ?? this.userData,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkExistingToken();
  }

  String? _selectedRole = 'user';

  String? get selectedRole => _selectedRole;

  void setSelectedRole(String role) {
    _selectedRole = role;
  }

  Future<void> _checkExistingToken() async {
    final isLoggedIn = await TokenStorageService.isLoggedIn();
    if (isLoggedIn) {
      final token = await TokenStorageService.getToken();
      final username = await TokenStorageService.getUsername();
      final roleId = await TokenStorageService.getRoleId();
      final userData = await TokenStorageService.getUserData();

      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        userName: username,
        userRole: roleId == 2 ? 'doctor' : (roleId == 3 ? 'user' : null),
        userData: userData,
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? department,
    int? experienceYears,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phone.isEmpty) {
      state = state.copyWith(error: 'All fields are required', isLoading: false);
      return false;
    }

    if (!email.contains('@')) {
      state = state.copyWith(error: 'Invalid email format', isLoading: false);
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(error: 'Password must be at least 6 characters', isLoading: false);
      return false;
    }

    if (password != confirmPassword) {
      state = state.copyWith(error: 'Passwords do not match', isLoading: false);
      return false;
    }

    if (phone.length < 10) {
      state = state.copyWith(error: 'Please enter a valid phone number', isLoading: false);
      return false;
    }

    if (_selectedRole == 'doctor') {
      if (department == null || department.isEmpty) {
        state = state.copyWith(error: 'Please select department', isLoading: false);
        return false;
      }
      if (experienceYears == null || experienceYears < 0) {
        state = state.copyWith(error: 'Please enter valid experience years', isLoading: false);
        return false;
      }
    }

    try {
      Map<String, dynamic> result;

      print('🔵 Starting registration for role: $_selectedRole');
      print('🔵 Data: name=$name, email=$email, phone=$phone');

      if (_selectedRole == 'doctor') {
        result = await ApiService.registerDoctor(
          username: name,
          email: email,
          phone: phone,
          password: password,
          department: department!,
          experienceYears: experienceYears!,
        );
      } else {
        result = await ApiService.registerUser(
          username: name,
          email: email,
          phone: phone,
          password: password,
        );
      }

      print('🔵 Registration result: $result');

      if (result['success']) {
        final userData = result['data'] ?? {};

        state = state.copyWith(
          isAuthenticated: true,
          userName: name,
          userRole: _selectedRole,
          userData: userData,
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          error: result['error'] ?? 'Registration failed',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      state = state.copyWith(
        error: 'Network error: Please check your connection',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔵 Attempting login for email: $email');

      final result = await ApiService.login(
        email: email,
        password: password,
      );

      print('🔵 Login result: $result');

      if (result['success']) {
        final userData = result['data'] ?? {};
        final token = userData['token'];
        final roleId = userData['role_id'];
        final username = userData['username'] ?? '';

        if (token != null) {
          await TokenStorageService.saveAuthData(
            token: token,
            roleId: roleId ?? 0,
            username: username,
            userData: userData,
          );
        }

        state = state.copyWith(
          isAuthenticated: true,
          userName: username,
          userRole: roleId == 2 ? 'doctor' : (roleId == 3 ? 'user' : null),
          userData: userData,
          token: token,
          isLoading: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          error: result['error'] ?? 'Login failed',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      state = state.copyWith(
        error: 'Network error: Please check your connection',
        isLoading: false,
      );
      return false;
    }
  }

  // Updated logout method with API call
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Call logout API
      await ApiService.logout();

      // Clear local storage regardless of API response
      await TokenStorageService.clearAuthData();

      // Reset state
      state = AuthState();
    } catch (e) {
      print('❌ Logout error: $e');
      // Still clear local storage and reset state even if API fails
      await TokenStorageService.clearAuthData();
      state = AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}