import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/active_stack_panel.dart';
import '../widgets/bottom_status_bar.dart';
import '../widgets/morning_checklist_panel.dart';
import '../widgets/quick_capture_bar.dart';
import '../widgets/triage_shield_panel.dart';

/// Intent pour le raccourci clavier global Ctrl + K (Capture Éclair)
class FocusQuickCaptureIntent extends Intent {
  const FocusQuickCaptureIntent();
}

/// Écran principal adaptatif de PrioStack :
/// - Windows Desktop (width >= 1024px) : Cockpit 3 colonnes côte à côte + Barre Capture Éclair + Barre de Statut
/// - Mobile (width < 1024px) : Navigation par BottomNavigationBar + Bouton de capture rapide
class CockpitScreen extends ConsumerStatefulWidget {
  const CockpitScreen({super.key});

  @override
  ConsumerState<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends ConsumerState<CockpitScreen> {
  final FocusNode _quickCaptureFocusNode = FocusNode();
  int _mobileNavIndex = 1; // Par défaut sur "La Pile Active" sur mobile

  @override
  void dispose() {
    _quickCaptureFocusNode.dispose();
    super.dispose();
  }

  void _focusQuickCapture() {
    _quickCaptureFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const FocusQuickCaptureIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          FocusQuickCaptureIntent: CallbackAction<FocusQuickCaptureIntent>(
            onInvoke: (_) {
              _focusQuickCapture();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;

              return Scaffold(
                backgroundColor: AppTheme.bgDeep,
                body: SafeArea(
                  child: Column(
                    children: [
                      // 1. Barre de Capture Éclair (toujours accessible en haut + Ctrl+K)
                      QuickCaptureBar(searchFocusNode: _quickCaptureFocusNode),

                      // 2. Corps principal : Cockpit 3 colonnes (Desktop) ou Vue onglet (Mobile)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: isDesktop
                              ? _buildDesktopThreeColumns()
                              : _buildMobileBody(),
                        ),
                      ),

                      // 3. Barre de Statut Inférieure (% Temps Fond vs % Temps Urgences + Compteur PUSH)
                      const BottomStatusBar(),
                    ],
                  ),
                ),
                bottomNavigationBar: isDesktop
                    ? null
                    : Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          border: Border(
                            top: BorderSide(color: AppTheme.borderSubtle),
                          ),
                        ),
                        child: BottomNavigationBar(
                          currentIndex: _mobileNavIndex,
                          onTap: (idx) => setState(() => _mobileNavIndex = idx),
                          backgroundColor: AppTheme.surfaceCard,
                          selectedItemColor: AppTheme.accentBlue,
                          unselectedItemColor: AppTheme.textSecondary,
                          items: const [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.checklist_rtl_rounded),
                              label: 'Morning Check',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.layers_rounded),
                              label: 'Pile Active',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.shield_moon_rounded),
                              label: 'Triage & Assistance',
                            ),
                          ],
                        ),
                      ),
                floatingActionButton: isDesktop
                    ? null
                    : FloatingActionButton(
                        backgroundColor: AppTheme.accentBlue,
                        onPressed: _focusQuickCapture,
                        tooltip: 'Capture Éclair',
                        child: const Icon(Icons.bolt_rounded, color: Colors.white),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Disposition Cockpit 3 Colonnes côte à côte (Windows Desktop >= 1024px)
  /// Calquée sur les proportions de la maquette Dribbble (Gauche 24%, Centre 46%, Droite 30%)
  Widget _buildDesktopThreeColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zone 1 (Gauche) : Morning Check-list & Profil Manager
        Expanded(
          flex: 25,
          child: MorningChecklistPanel(
            onQuickCreatePressed: _focusQuickCapture,
          ),
        ),
        const SizedBox(width: 16),

        // Zone 2 (Centre) : La Pile Active (Sanctuaire & Gestion des Interruptions PUSH/POP)
        const Expanded(
          flex: 45,
          child: ActiveStackPanel(),
        ),
        const SizedBox(width: 16),

        // Zone 3 (Droite) : Triage & Bouclier Manager (3 Onglets)
        const Expanded(
          flex: 30,
          child: TriageShieldPanel(),
        ),
      ],
    );
  }

  /// Disposition Mobile adaptative (< 1024px)
  Widget _buildMobileBody() {
    switch (_mobileNavIndex) {
      case 0:
        return MorningChecklistPanel(onQuickCreatePressed: _focusQuickCapture);
      case 1:
        return const ActiveStackPanel();
      case 2:
      default:
        return const TriageShieldPanel();
    }
  }
}
