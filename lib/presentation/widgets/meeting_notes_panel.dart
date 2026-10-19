import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/meeting_note.dart';
import '../providers/meeting_notes_provider.dart';

class MeetingNotesPanel extends ConsumerStatefulWidget {
  const MeetingNotesPanel({super.key});

  @override
  ConsumerState<MeetingNotesPanel> createState() => _MeetingNotesPanelState();
}

class _MeetingNotesPanelState extends ConsumerState<MeetingNotesPanel> {
  final _titleCtrl = TextEditingController();
  final _participantsCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _newActionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String? _currentEditingId;
  String _searchQuery = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _participantsCtrl.dispose();
    _contentCtrl.dispose();
    _newActionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _syncControllersWithActive(MeetingNote? active) {
    if (active == null) {
      _currentEditingId = null;
      _titleCtrl.clear();
      _participantsCtrl.clear();
      _contentCtrl.clear();
      return;
    }

    if (_currentEditingId != active.id) {
      _currentEditingId = active.id;
      _titleCtrl.text = active.title;
      _participantsCtrl.text = active.participants;
      _contentCtrl.text = active.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meetingNotesProvider);
    _syncControllersWithActive(state.activeMeeting);

    final filteredMeetings = state.meetings.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.title.toLowerCase().contains(q) ||
          m.participants.toLowerCase().contains(q) ||
          m.content.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              // 1. Barre Latérale : Historique des Réunions & Recherche
              SizedBox(
                width: isDesktop ? 290 : 230,
                child: _buildSidebar(context, filteredMeetings, state.activeMeeting),
              ),

              const VerticalDivider(width: 1),

              // 2. Zone Éditeur Principal de Prise de Note
              Expanded(
                child: state.activeMeeting == null
                    ? _buildEmptyState()
                    : _buildEditor(context, state.activeMeeting!, state.isSaving, state.lastSavedAt),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    List<MeetingNote> meetings,
    MeetingNote? active,
  ) {
    return Container(
      color: AppTheme.bgDeep.withValues(alpha: 0.5),
      child: Column(
        children: [
          // En-tête Sidebar avec Bouton Nouvelle Réunion
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(meetingNotesProvider.notifier).createNewMeeting();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Nouvelle Réunion',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 8),

                // Champ de recherche
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une note...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste des réunions passées
          Expanded(
            child: meetings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'Aucun résultat'
                            : 'Aucune réunion enregistrée.\nCliquez sur "+ Nouvelle Réunion" pour commencer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      final m = meetings[index];
                      final isSelected = active?.id == m.id;

                      final dateStr =
                          '${m.meetingDate.day.toString().padLeft(2, '0')}/${m.meetingDate.month.toString().padLeft(2, '0')} ${m.meetingDate.hour.toString().padLeft(2, '0')}:${m.meetingDate.minute.toString().padLeft(2, '0')}';

                      return InkWell(
                        onTap: () {
                          ref.read(meetingNotesProvider.notifier).selectMeeting(m);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentBlue.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.title.isEmpty ? 'Réunion sans titre' : m.title,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.accentBlue
                                            : AppTheme.textPrimary,
                                        fontWeight:
                                            isSelected ? FontWeight.w700 : FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.content.isEmpty
                                    ? 'Note vide...'
                                    : m.content.replaceAll('\n', ' '),
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (m.actionItems.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 11, color: AppTheme.neonAmber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${m.actionItems.length} action(s)',
                                      style: TextStyle(
                                        color: AppTheme.neonAmber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    MeetingNote meeting,
    bool isSaving,
    DateTime? lastSaved,
  ) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre Supérieure de l'Éditeur : Indicateur Auto-Save + Modèles + Exporter + Supprimer
          Row(
            children: [
              // Indicateur Auto-save dynamique
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSaving
                      ? AppTheme.neonAmber.withValues(alpha: 0.16)
                      : AppTheme.neonGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSaving)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.neonAmber,
                        ),
                      )
                    else
                      const Icon(Icons.cloud_done_rounded,
                          size: 13, color: AppTheme.neonGreen),
                    const SizedBox(width: 6),
                    Text(
                      isSaving
                          ? 'Enregistrement automatique...'
                          : 'Sauvegardé automatiquement',
                      style: TextStyle(
                        color: isSaving ? AppTheme.neonAmber : AppTheme.neonGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Modèles de Réunions rapides
              PopupMenuButton<String>(
                tooltip: 'Appliquer un modèle de réunion',
                color: AppTheme.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppTheme.borderHighlight),
                ),
                onSelected: (tpl) {
                  _applyTemplate(tpl, meeting);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: '1on1',
                    child: Text('Modèle : Point Synchro 1:1', style: TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuItem(
                    value: 'archi',
                    child: Text('Modèle : Revue d\'Architecture', style: TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuItem(
                    value: 'daily',
                    child: Text('Modèle : Daily / Standup Triage', style: TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuItem(
                    value: 'client',
                    child: Text('Modèle : Cadrage Client / Projet', style: TextStyle(fontSize: 12)),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 13, color: AppTheme.neonAmber),
                      const SizedBox(width: 4),
                      Text(
                        'Modèles',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Copier en Markdown
              IconButton(
                tooltip: 'Copier les notes en Markdown',
                icon: const Icon(Icons.copy_rounded, size: 16),
                color: AppTheme.textSecondary,
                onPressed: () {
                  final text = _formatAsMarkdown(meeting);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notes copiées dans le presse-papier !'),
                      backgroundColor: AppTheme.neonGreen,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Supprimer
              IconButton(
                tooltip: 'Supprimer cette réunion',
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                color: AppTheme.neonPink,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surfaceCard,
                      title: const Text('Supprimer la réunion ?'),
                      content: const Text('Cette action est irréversible.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(meetingNotesProvider.notifier).deleteMeeting(meeting.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Titre de la réunion (Gros champ épuré)
          TextField(
            controller: _titleCtrl,
            onChanged: (val) {
              ref.read(meetingNotesProvider.notifier).updateActiveMeeting(title: val);
            },
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            decoration: const InputDecoration(
              hintText: 'Titre de la réunion (Ex: Revue Technique Sprint 14)...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Ligne Métadonnées (Date + Participants)
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.accentBlue),
              const SizedBox(width: 6),
              Text(
                '${meeting.meetingDate.day}/${meeting.meetingDate.month}/${meeting.meetingDate.year}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people_alt_outlined, size: 15, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _participantsCtrl,
                  onChanged: (val) {
                    ref
                        .read(meetingNotesProvider.notifier)
                        .updateActiveMeeting(participants: val);
                  },
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                  decoration: const InputDecoration(
                    hintText: 'Participants (Ex: Salio, Alice, Bob, Product Owner)...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Section Actions & Décisions clés (To-Dos convertibles en tâches PrioStack)
          _buildActionItemsSection(context, meeting),

          const SizedBox(height: 12),
          Text(
            'NOTES DE SÉANCE :',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),

          // Zone principale de texte (Auto-save en temps réel)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgDeep,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TextField(
                controller: _contentCtrl,
                onChanged: (val) {
                  ref.read(meetingNotesProvider.notifier).updateActiveMeeting(content: val);
                },
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'Prenez vos notes ici en direct pendant la réunion...\n'
                      '• Sujets abordés\n'
                      '• Décisions d\'architecture\n'
                      '• Points de blocage à débloquer\n\n'
                      'Toute frappe s\'enregistre automatiquement instantanément.',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontFamily: 'sans-serif',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemsSection(BuildContext context, MeetingNote meeting) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded, size: 15, color: AppTheme.neonAmber),
              const SizedBox(width: 6),
              Text(
                'DÉCISIONS & ACTIONS À MENER (${meeting.actionItems.length})',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Liste des actions avec possibilité d'injecter directement dans PrioStack
          if (meeting.actionItems.isNotEmpty)
            Column(
              children: meeting.actionItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final action = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_rounded, size: 16, color: AppTheme.neonAmber),
                      Expanded(
                        child: Text(
                          action,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5),
                        ),
                      ),
                      // Bouton Transformer en Tâche PrioStack
                      InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: () async {
                          await ref
                              .read(meetingNotesProvider.notifier)
                              .convertActionItemToTask(action);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Action convertie en tâche active dans PrioStack !'),
                                backgroundColor: AppTheme.neonGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_task_rounded,
                                  size: 11, color: AppTheme.accentBlue),
                              const SizedBox(width: 4),
                              Text(
                                '+ Tâche Pile Active',
                                style: TextStyle(
                                  color: AppTheme.accentBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Supprimer l'action
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 13, color: AppTheme.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final updated = List<String>.from(meeting.actionItems)..removeAt(idx);
                          ref
                              .read(meetingNotesProvider.notifier)
                              .updateActiveMeeting(actionItems: updated);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 6),

          // Champ d'ajout rapide d'action
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newActionCtrl,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5),
                  onSubmitted: (val) => _addAction(meeting),
                  decoration: InputDecoration(
                    hintText: 'Ajouter une action clé ou décision (Touche Entrée)...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(7),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                onPressed: () => _addAction(meeting),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addAction(MeetingNote meeting) {
    final text = _newActionCtrl.text.trim();
    if (text.isEmpty) return;
    final updated = List<String>.from(meeting.actionItems)..add(text);
    ref.read(meetingNotesProvider.notifier).updateActiveMeeting(actionItems: updated);
    _newActionCtrl.clear();
  }

  void _applyTemplate(String tpl, MeetingNote meeting) {
    String templateContent = '';
    String defaultTitle = meeting.title;

    switch (tpl) {
      case '1on1':
        defaultTitle = 'Point Synchro 1:1 - ${meeting.participants.isEmpty ? 'Collaborateur' : meeting.participants}';
        templateContent = '''### 🎯 Objectifs & Météo de la semaine
• Ressenti général : 
• Priorité absolue cette semaine : 

### 🚧 Blocages & Dépendances
• Ce qui freine le delivery : 
• Assistance ou arbitrage attendu : 

### 💡 Idées d'amélioration & Prochains jalons
• Prochaines étapes :
''';
        break;

      case 'archi':
        defaultTitle = 'Revue d\'Architecture & Décisions Techniques';
        templateContent = '''### 🏗 Contexte & Problématique
• Composant ou service ciblé : 
• Enjeux de performance / scalabilité : 

### 📐 Options Évaluées (Trade-offs)
1. Option A : 
2. Option B : 

### 🏆 Décision retenue (ADR)
• Solution actée : 
• Impacts sur la base Neon & APIs : 
''';
        break;

      case 'daily':
        defaultTitle = 'Daily Triage & Call Stack';
        templateContent = '''### 🔥 Urgences & Alertes du jour
• Incidents ou blocages critiques : 

### 🛡 Sanctuaire Focus (Deep Work)
• Sujet principal à sanctuariser (90 min) : 

### 🤝 Délégations & Suivis
• Tâches transmises : 
''';
        break;

      case 'client':
        defaultTitle = 'Point de Cadrage Client & Délais';
        templateContent = '''### 👥 Présents & Ordre du jour
• 

### 📌 Besoins exprimés & Périmètre
• Attentes clés : 

### 🗓 Délais & Engagements
• Prochaine livraison / démo : 
''';
        break;
    }

    _titleCtrl.text = defaultTitle;
    _contentCtrl.text = templateContent;
    ref.read(meetingNotesProvider.notifier).updateActiveMeeting(
          title: defaultTitle,
          content: templateContent,
        );
  }

  String _formatAsMarkdown(MeetingNote m) {
    final sb = StringBuffer();
    sb.writeln('# ${m.title}');
    sb.writeln('**Date :** ${m.meetingDate.toLocal()}');
    if (m.participants.isNotEmpty) {
      sb.writeln('**Participants :** ${m.participants}');
    }
    sb.writeln();
    if (m.actionItems.isNotEmpty) {
      sb.writeln('## Actions & Décisions');
      for (final a in m.actionItems) {
        sb.writeln('- [ ] $a');
      }
      sb.writeln();
    }
    sb.writeln('## Notes');
    sb.writeln(m.content);
    return sb.toString();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            'Sélectionnez une réunion ou créez-en une nouvelle',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            onPressed: () {
              ref.read(meetingNotesProvider.notifier).createNewMeeting();
            },
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Nouvelle Réunion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
