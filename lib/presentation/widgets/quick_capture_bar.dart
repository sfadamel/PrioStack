import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/task_enums.dart';
import '../providers/priostack_providers.dart';

/// Barre de Capture Éclair toujours accessible en haut + invocable par Ctrl + K
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
  TaskType _selectedType = TaskType.urgence;
  bool _isTeamVisible = false;

  @override
  void dispose() {
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
          visibility:
              _isTeamVisible ? VisibilityScope.team : VisibilityScope.privateScope,
        );

    _titleController.clear();
    _externalRefController.clear();
    _personController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _selectedType.accentColor.withValues(alpha: 0.6)),
          ),
          content: Row(
            children: [
              Icon(Icons.bolt_rounded, color: _selectedType.accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Capturé dans [${_selectedType.label}] : "$title"',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 920;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.surfaceCard,
        radius: 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Badge PrioStack + Raccourci Ctrl+K
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'PrioStack',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Sélecteur de Type (Pills neumorphiques)
              if (!isCompact) ...[
                _buildTypeSelectorRow(),
                const SizedBox(width: 12),
              ],

              // Champ principal de capture éclair
              Expanded(
                child: Container(
                  height: 38,
                  decoration: AppTheme.neumorphicInset(radius: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        size: 16,
                        color: _selectedType.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          focusNode: widget.searchFocusNode,
                          onSubmitted: (_) => _submitQuickCapture(),
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: _hintForType(_selectedType),
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.borderHighlight),
                        ),
                        child: Text(
                          'Ctrl + K',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Champ Dev / Interlocuteur (optionnel)
              if (!isCompact) ...[
                SizedBox(
                  width: 135,
                  height: 38,
                  child: Container(
                    decoration: AppTheme.neumorphicInset(radius: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: _personController,
                      onSubmitted: (_) => _submitQuickCapture(),
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _selectedType == TaskType.devBlock
                            ? 'Demandeur (ex: Lucas)'
                            : 'Responsable / Source',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Champ externalRef (Ticket Azure DevOps)
              SizedBox(
                width: isCompact ? 95 : 120,
                height: 38,
                child: Container(
                  decoration: AppTheme.neumorphicInset(radius: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _externalRefController,
                    onSubmitted: (_) => _submitQuickCapture(),
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'AzDO AB#...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Toggle Visibilité V2-Ready (Private / Team)
              Tooltip(
                message: _isTeamVisible
                    ? 'Visibilité V2 : Équipe (Team Sync)'
                    : 'Visibilité V2 : Privé (Local)',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _isTeamVisible = !_isTeamVisible),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _isTeamVisible
                          ? AppTheme.accentIndigo.withValues(alpha: 0.2)
                          : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isTeamVisible
                            ? AppTheme.accentIndigo
                            : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Icon(
                      _isTeamVisible ? Icons.groups_rounded : Icons.lock_outline_rounded,
                      size: 16,
                      color: _isTeamVisible ? AppTheme.accentBlue : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton d'ajout rapide
              InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: _submitQuickCapture,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 17, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Capturer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton de bascule Mode Sombre / Mode Clair
              _buildThemeToggleButton(),
            ],
          ),
          if (isCompact) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTypeSelectorRow(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeSelectorRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TaskType.values.map((type) {
        final isSelected = _selectedType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? type.accentColor.withValues(alpha: 0.18)
                    : AppTheme.surfaceInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? type.accentColor.withValues(alpha: 0.85)
                      : AppTheme.borderSubtle,
                  width: isSelected ? 1.2 : 1.0,
                ),
              ),
              child: Text(
                type.label,
                style: TextStyle(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeToggleButton() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Tooltip(
      message: isDark
          ? 'Passer en Mode Clair (Light Soft UI)'
          : 'Passer en Mode Sombre (Dark Neumorphism)',
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppTheme.borderHighlight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 16,
                color: isDark ? AppTheme.neonAmber : AppTheme.accentBlue,
              ),
              const SizedBox(width: 6),
              Text(
                isDark ? 'Sombre' : 'Clair',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hintForType(TaskType type) {
    switch (type) {
      case TaskType.urgence:
        return 'Capturer une urgence critique en 2s (Entrée)...';
      case TaskType.devBlock:
        return 'Noter une demande d\'assistance...';
      case TaskType.deepWork:
        return 'Ajouter une tâche de fond (Architecture, Conception)...';
      case TaskType.delegated:
        return 'Noter un point délégué / en attente de retour...';
    }
  }
}
