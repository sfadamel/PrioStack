import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/auth_user.dart';

// Import conditionnel pour stocker le token dans le localStorage ou SharedPreferences
import '../../data/local/memory/web_storage_stub.dart'
    if (dart.library.html) '../../data/local/memory/web_storage_html.dart';

const String kDefaultApiBaseUrl = 'http://localhost:4000/api';
const String _kTokenStorageKey = 'priostack_auth_jwt_token';
const String _kUserStorageKey = 'priostack_auth_user_data';

final authApiUrlProvider = StateProvider<String>((ref) => kDefaultApiBaseUrl);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiUrl = ref.watch(authApiUrlProvider);
  return AuthNotifier(apiUrl);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final String _baseUrl;

  AuthNotifier(this._baseUrl) : super(const AuthState(isLoading: true)) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = getStorageItem(_kTokenStorageKey);
    final userRaw = getStorageItem(_kUserStorageKey);

    if (token != null && token.isNotEmpty && userRaw != null) {
      try {
        final userData = jsonDecode(userRaw) as Map<String, dynamic>;
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          user: AuthUser.fromJson(userData),
        );
        return;
      } catch (_) {}
    }

    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 200 && data['token'] != null) {
        final token = data['token'] as String;
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

        setStorageItem(_kTokenStorageKey, token);
        setStorageItem(_kUserStorageKey, jsonEncode(user.toJson()));

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['error'] as String? ?? 'Erreur de connexion',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de joindre le serveur API Neon ($e)',
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 201 && data['token'] != null) {
        final token = data['token'] as String;
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

        setStorageItem(_kTokenStorageKey, token);
        setStorageItem(_kUserStorageKey, jsonEncode(user.toJson()));

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['error'] as String? ?? 'Erreur d\'inscription',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de joindre le serveur API Neon ($e)',
      );
      return false;
    }
  }

  void logout() {
    removeStorageItem(_kTokenStorageKey);
    removeStorageItem(_kUserStorageKey);
    state = const AuthState(isAuthenticated: false);
  }
}
