import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/admin_user_info.dart';
import 'auth_provider.dart';

class AdminUsersState {
  final List<AdminUserInfo> users;
  final bool isLoading;
  final String? error;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  int get pendingApprovalCount =>
      users.where((u) => !u.isApproved && u.role != 'admin').length;

  AdminUsersState copyWith({
    List<AdminUserInfo>? users,
    bool? isLoading,
    String? error,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final Ref ref;

  AdminUsersNotifier(this.ref) : super(const AdminUsersState());

  String get _apiUrl => ref.read(authApiUrlProvider);
  String? get _token => ref.read(authProvider).token;

  Future<void> fetchUsers() async {
    if (_token == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await http.get(
        Uri.parse('$_apiUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['users'] as List)
            .map((u) => AdminUserInfo.fromJson(u))
            .toList();
        state = state.copyWith(users: list, isLoading: false);
      } else {
        final err = jsonDecode(res.body)['error'] ?? 'Erreur chargement utilisateurs';
        state = state.copyWith(isLoading: false, error: err);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approveUser(String userId) async {
    if (_token == null) return false;

    try {
      final res = await http.post(
        Uri.parse('$_apiUrl/admin/users/$userId/approve'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        await fetchUsers();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteUser(String userId) async {
    if (_token == null) return false;

    try {
      final res = await http.delete(
        Uri.parse('$_apiUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        await fetchUsers();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref);
});
