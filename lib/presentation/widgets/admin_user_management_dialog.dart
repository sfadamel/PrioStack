import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';

class AdminUserManagementDialog extends ConsumerStatefulWidget {
  const AdminUserManagementDialog({super.key});

  @override
  ConsumerState<AdminUserManagementDialog> createState() =>
      _AdminUserManagementDialogState();
}

class _AdminUserManagementDialogState
    extends ConsumerState<AdminUserManagementDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsersProvider.notifier).fetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminUsersProvider);

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderHighlight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.neonAmber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppTheme.neonAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des Utilisateurs & Inscriptions',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Validez les nouvelles demandes de création de compte pour autoriser la connexion.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppTheme.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Liste des utilisateurs
              Expanded(
                child: adminState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : adminState.users.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun utilisateur enregistré.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: adminState.users.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 8, endIndent: 8),
                            itemBuilder: (context, index) {
                              final user = adminState.users[index];
                              final isPending =
                                  !user.isApproved && user.role != 'admin';

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isPending
                                          ? AppTheme.neonAmber.withValues(alpha: 0.16)
                                          : AppTheme.accentBlue.withValues(alpha: 0.16),
                                      child: Text(
                                        user.fullName.isNotEmpty
                                            ? user.fullName[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          color: isPending
                                              ? AppTheme.neonAmber
                                              : AppTheme.accentBlue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  user.fullName,
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              if (user.role == 'admin')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.neonAmber
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'ADMIN',
                                                    style: TextStyle(
                                                      color: AppTheme.neonAmber,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              if (isPending)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.neonPink
                                                        .withValues(alpha: 0.16),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'EN ATTENTE DE VALIDATION',
                                                    style: TextStyle(
                                                      color: AppTheme.neonPink,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                )
                                              else if (user.role != 'admin')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.neonGreen
                                                        .withValues(alpha: 0.16),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'VALIDÉ',
                                                    style: TextStyle(
                                                      color: AppTheme.neonGreen,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email,
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Actions
                                    if (isPending) ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.neonGreen,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          textStyle: const TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                        onPressed: () async {
                                          final ok = await ref
                                              .read(adminUsersProvider.notifier)
                                              .approveUser(user.id);
                                          if (ok && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Compte de ${user.fullName} validé avec succès !'),
                                                backgroundColor: AppTheme.neonGreen,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check_circle_outline_rounded,
                                            size: 14),
                                        label: const Text('Valider'),
                                      ),
                                      const SizedBox(width: 6),
                                    ],

                                    if (user.role != 'admin')
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded,
                                            size: 17, color: AppTheme.textMuted),
                                        tooltip: 'Supprimer ce compte',
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: AppTheme.surfaceCard,
                                              title: const Text('Confirmer la suppression'),
                                              content: Text(
                                                  'Voulez-vous vraiment supprimer le compte de ${user.fullName} (${user.email}) ?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Annuler'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.neonPink),
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('Supprimer',
                                                      style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await ref
                                                .read(adminUsersProvider.notifier)
                                                .deleteUser(user.id);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
