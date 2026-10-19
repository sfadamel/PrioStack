import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/memory/web_storage_helper.dart';
import '../../data/local/memory/web_storage_stub.dart'
    if (dart.library.html) '../../data/local/memory/web_storage_html.dart';
import '../../domain/models/task_enums.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';
import '../providers/admin_provider.dart';
import 'notification_center_widgets.dart';
import 'admin_user_management_dialog.dart';

/// Barre supérieure minimaliste (Style Linear / Raycast) :
/// - Gauche : Marque PrioStack + Commutateur segmenté (Cockpit | Calendrier)
/// - Centre : Command Bar épurée (Ctrl + K) avec dévoilement progressif des options au focus
/// - Droite : Icônes épurées (Notifications 🔔 + Thème 🌙/☀️)
class QuickCaptureBar extends ConsumerStatefulWidget {
  final FocusNode? searchFocusNode;
  const QuickCaptureBar({super.key, this.searchFocusNode});

  @override
  ConsumerState<QuickCaptureBar> createState() => _QuickCaptureBarState();
}

class _QuickCaptureBarState extends ConsumerState<QuickCaptureBar> {
  final _titleController = TextEditingController();
  final _externalRefController = TextEditingController();
  final _personController = TextEditingController();
  late FocusNode _internalFocusNode;
  TaskType _selectedType = TaskType.urgence;
  bool _isTeamVisible = false;
  bool _isExpanded = false;

  FocusNode get _effectiveFocusNode =>
      widget.searchFocusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
    _titleController.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _handleTextChange() {
    if (_titleController.text.isNotEmpty && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _titleController.removeListener(_handleTextChange);
    _internalFocusNode.dispose();
    _titleController.dispose();
    _externalRefController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<void> _submitQuickCapture() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await ref.read(taskRepositoryProvider).quickCaptureTask(
          title: title,
          type: _selectedType,
          externalRef: _externalRefController.text.trim(),
          requesterOrAssignee: _personController.text.trim(),
          criticality: _selectedType == TaskType.urgence ? 3 : 2,
          visibility: _isTeamVisible
              ? VisibilityScope.team
              : VisibilityScope.privateScope,
        );

    ref.read(appNotificationsProvider.notifier).pushNotification(
          title: 'Capturé dans ${_selectedType.label}',
          body: title,
          type: AppNotificationType.taskCaptured,
          showBanner: false,
        );

    _titleController.clear();
    _externalRefController.clear();
    _personController.clear();
    setState(() => _isExpanded = false);
    _effectiveFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final currentView = ref.watch(cockpitMainViewProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final now = DateTime.now();

    final todayRemainingCount = eventsAsync.maybeWhen(
      data: (list) =>
          list.where((e) => e.isSameDay(now) && !e.isCompleted).length,
      orElse: () => 0,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Marque PrioStack épurée
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'PrioStack',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // 2. Commutateur de vue segmenté (Cockpit | Calendrier)
              Flexible(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewSegment(
                        label: 'Cockpit',
                        icon: Icons.dashboard_customize_outlined,
                        isActive: currentView == CockpitMainView.cockpit,
                        onTap: () => ref
                            .read(cockpitMainViewProvider.notifier)
                            .setView(CockpitMainView.cockpit),
                      ),
                      const SizedBox(width: 2),
                      _buildViewSegment(
                        label: 'Calendrier',
                        icon: Icons.calendar_today_rounded,
                        badgeCount: todayRemainingCount,
                        isActive: currentView == CockpitMainView.calendar,
                        onTap: () => ref
                            .read(cockpitMainViewProvider.notifier)
                            .setView(CockpitMainView.calendar),
                      ),
                      const SizedBox(width: 2),
                      _buildViewSegment(
                        label: 'Réunions',
                        icon: Icons.edit_note_rounded,
                        isActive: currentView == CockpitMainView.meetings,
                        onTap: () => ref
                            .read(cockpitMainViewProvider.notifier)
                            .setView(CockpitMainView.meetings),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Command Bar Centrale (Style Raycast / Linear)
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isExpanded
                          ? _selectedType.accentColor.withValues(alpha: 0.65)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Pastille de type cliquable (cycle rapide ou ouvre le tiroir)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _selectedType.accentColor
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _selectedType.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _shortTypeLabel(_selectedType),
                                style: TextStyle(
                                  color: _selectedType.accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 13,
                                color: _selectedType.accentColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          focusNode: _effectiveFocusNode,
                          onTap: () {
                            if (!_isExpanded) {
                              setState(() => _isExpanded = true);
                            }
                          },
                          onSubmitted: (_) => _submitQuickCapture(),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12.5,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Capture éclair : saisir une tâche, urgence ou assistance...',
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_isExpanded)
                        InkWell(
                          onTap: () {
                            _titleController.clear();
                            _effectiveFocusNode.unfocus();
                            setState(() => _isExpanded = false);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text(
                            'Ctrl K',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 4. Actions globales épurées (Sauvegarde 💾 + Notifications 🔔 + Thème 🌙/☀️ + Profil/Déconnexion 👤)
              if (kIsWeb) ...[
                _buildBackupMenuButton(context),
                const SizedBox(width: 6),
              ],
              const NotificationBellButton(),
              const SizedBox(width: 6),
              _buildMinimalThemeButton(),
              const SizedBox(width: 6),
              _buildUserProfileButton(context),
            ],
          ),

          // Tiroir contextuel de Capture Éclair (visible uniquement pendant la saisie)
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderSubtle.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Choix du flux
                  ...TaskType.values.map((type) {
                    final isSel = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel
                                ? type.accentColor.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? type.accentColor.withValues(alpha: 0.7)
                                  : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            type.label,
                            style: TextStyle(
                              color: isSel
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Champ Interlocuteur compact
                  SizedBox(
                    width: 140,
                    height: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDeep,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: TextField(
                        controller: _personController,
                        onSubmitted: (_) => _submitQuickCapture(),
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 11.5),
                        decoration: InputDecoration(
                          hintText: ' Interlocuteur / Dev',
                          hintStyle: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Champ Ticket AzDO compact
                  SizedBox(
                    width: 95,
                    height: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDeep,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: TextField(
                        controller: _externalRefController,
                        onSubmitted: (_) => _submitQuickCapture(),
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 11.5),
                        decoration: InputDecoration(
                          hintText: 'AB#...',
                          hintStyle: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Visibilité Privé / Équipe
                  InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () =>
                        setState(() => _isTeamVisible = !_isTeamVisible),
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _isTeamVisible
                            ? AppTheme.accentIndigo.withValues(alpha: 0.18)
                            : AppTheme.bgDeep,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: _isTeamVisible
                              ? AppTheme.accentIndigo
                              : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Icon(
                        _isTeamVisible
                            ? Icons.groups_rounded
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: _isTeamVisible
                            ? AppTheme.accentBlue
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton Valider
                  InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: _submitQuickCapture,
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Ajouter ↵',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewSegment({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: isActive ? AppTheme.accentBlue : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: AppTheme.accentBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Sauvegarde des données',
      offset: const Offset(0, 42),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderHighlight),
      ),
      onSelected: (value) {
        if (value == 'export') {
          _handleExport(context);
        } else if (value == 'import') {
          _handleImport(context);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: [
              const Icon(Icons.download_rounded,
                  size: 16, color: AppTheme.accentBlue),
              const SizedBox(width: 10),
              Text(
                'Exporter mes données (.json)',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'import',
          child: Row(
            children: [
              const Icon(Icons.upload_rounded,
                  size: 16, color: AppTheme.neonAmber),
              const SizedBox(width: 10),
              Text(
                'Importer une sauvegarde…',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Icon(
          Icons.save_alt_rounded,
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _showBackupMessage(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.neonPink : AppTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final repo = ref.read(taskRepositoryProvider);
    final jsonStr = await repo.exportBackupJson();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      downloadTextFile(WebStorageHelper.backupFileName(), jsonStr);
      if (context.mounted) {
        _showBackupMessage(
          context,
          'Sauvegarde téléchargée : ${WebStorageHelper.backupFileName()}',
        );
      }
    } else {
      final ok = WebStorageHelper.exportBackup();
      if (context.mounted) {
        _showBackupMessage(
          context,
          ok
              ? 'Sauvegarde téléchargée : ${WebStorageHelper.backupFileName()}'
              : 'Aucune donnée à exporter pour le moment.',
          isError: !ok,
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderHighlight),
        ),
        title: Text(
          'Importer une sauvegarde ?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Les données actuelles seront REMPLACÉES par celles du fichier JSON importé. '
          'Pensez à exporter d\'abord si vous souhaitez les conserver.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonAmber),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choisir un fichier',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final raw = await pickTextFile();
    if (raw == null) return;

    final repo = ref.read(taskRepositoryProvider);
    final error = await repo.importBackupJson(raw);
    if (error != null) {
      if (context.mounted) {
        _showBackupMessage(context, error, isError: true);
      }
      return;
    }

    if (context.mounted) {
      _showBackupMessage(
        context,
        'Sauvegarde importée avec succès ! Synchronisation...',
      );
    }

    // Rechargement propre pour rafraîchir l'ensemble de l'interface
    Future.delayed(const Duration(milliseconds: 600), () {
      reloadPage();
    });
  }

  Widget _buildMinimalThemeButton() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          size: 16,
          color: isDark ? AppTheme.neonAmber : AppTheme.accentBlue,
        ),
      ),
    );
  }

  Widget _buildUserProfileButton(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final initials = user != null && user.fullName.isNotEmpty
        ? user.fullName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'US';

    final pendingCount = (user?.isAdmin ?? false)
        ? ref.watch(adminUsersProvider).pendingApprovalCount
        : 0;

    return PopupMenuButton<String>(
      tooltip: user != null ? '${user.fullName} (${user.role})' : 'Mon compte',
      offset: const Offset(0, 42),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderHighlight),
      ),
      onSelected: (value) {
        if (value == 'admin_users') {
          showDialog(
            context: context,
            builder: (_) => const AdminUserManagementDialog(),
          );
        } else if (value == 'logout') {
          ref.read(authProvider.notifier).logout();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.fullName ?? 'Utilisateur',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? '',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (user?.isAdmin ?? false)
                      ? AppTheme.neonAmber.withValues(alpha: 0.16)
                      : AppTheme.accentBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  (user?.isAdmin ?? false) ? 'ADMINISTRATEUR NEON' : 'UTILISATEUR CLOUD',
                  style: TextStyle(
                    color: (user?.isAdmin ?? false) ? AppTheme.neonAmber : AppTheme.accentBlue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (user?.isAdmin ?? false) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'admin_users',
            child: Row(
              children: [
                const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.neonAmber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestion des inscriptions',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: AppTheme.neonPink),
              SizedBox(width: 10),
              Text(
                'Se déconnecter',
                style: TextStyle(color: AppTheme.neonPink, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (user?.isAdmin ?? false)
                  ? AppTheme.neonAmber.withValues(alpha: 0.18)
                  : AppTheme.accentBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (user?.isAdmin ?? false)
                    ? AppTheme.neonAmber.withValues(alpha: 0.5)
                    : AppTheme.accentBlue.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: (user?.isAdmin ?? false) ? AppTheme.neonAmber : AppTheme.accentBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (pendingCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.neonPink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _shortTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.urgence:
        return 'Urgence';
      case TaskType.devBlock:
        return 'Assistance';
      case TaskType.deepWork:
        return 'Fond';
      case TaskType.delegated:
        return 'Délégué';
    }
  }
}
