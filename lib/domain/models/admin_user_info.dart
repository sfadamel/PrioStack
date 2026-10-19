class AdminUserInfo {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;

  AdminUserInfo({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isApproved,
    required this.createdAt,
  });

  factory AdminUserInfo.fromJson(Map<String, dynamic> json) {
    return AdminUserInfo(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: json['is_active'] == true,
      isApproved: json['is_approved'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
