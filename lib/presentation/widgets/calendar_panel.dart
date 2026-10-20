import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/meeting_note.dart';
import '../providers/meeting_notes_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/priostack_providers.dart';

const List<String> kFrenchMonths = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

const List<String> kFrenchWeekdaysShort = [
  'LUN',
  'MAR',
  'MER',
  'JEU',
  'VEN',
  'SAM',
  'DIM',
];

const List<String> kFrenchWeekdaysFull = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

String formatFullFrenchDate(DateTime date) {
  final wd = kFrenchWeekdaysFull[(date.weekday - 1).clamp(0, 6)];
  final month = kFrenchMonths[(date.month - 1).clamp(0, 11)];
  return '$wd ${date.day} $month ${date.year}';
}

/// Vue complète dédiée au Calendrier & Agenda PrioStack :
/// - Grille mensuelle interactive avec aperçu des créneaux et filtres par type
/// - Vue Agenda horaire détaillée du jour sélectionné (avec heure début/fin, participants/lieu, notes)
/// - Pont direct avec la Pile Active : bouton « 🚨 Rejoindre (PUSH) » pour interrompre proprement la Tâche de Fond
class CalendarScreenPanel extends ConsumerStatefulWidget {
  const CalendarScreenPanel({super.key});

  @override
  ConsumerState<CalendarScreenPanel> createState() => _CalendarScreenPanelState();
}

class _CalendarScreenPanelState extends ConsumerState<CalendarScreenPanel> {
  late DateTime _focusedMonth;
  CalendarEventCategory? _selectedCategoryFilter;
  bool _mobileShowMonthGrid = false;
  final ScrollController _monthGridScrollController = ScrollController();
  final ScrollController _dayTimelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _monthGridScrollController.dispose();
    _dayTimelineScrollController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
    });
    ref.read(selectedCalendarDateProvider.notifier).selectDate(now);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return eventsAsync.when(
      data: (allEvents) {
        final filteredEvents = _selectedCategoryFilter == null
            ? allEvents
            : allEvents
                .where((e) => e.category == _selectedCategoryFilter)
                .toList();

        final selectedDayEvents = filteredEvents
            .where((e) => e.isSameDay(selectedDate))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 54,
                    child: _buildMonthlyCalendarColumn(
                      context,
                      selectedDate,
                      filteredEvents,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 46,
                    child: _buildDayTimelineColumn(
                      context,
                      selectedDate,
                      selectedDayEvents,
                    ),
                  ),
                ],
              );
            } else {
              // Disposition Mobile & Écrans compacts (< 960px) avec bascule ergonomique Agenda / Mois
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => setState(() => _mobileShowMonthGrid = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_mobileShowMonthGrid
                                    ? AppTheme.accentBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 15,
                                    color: !_mobileShowMonthGrid
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Agenda (${selectedDayEvents.length})',
                                    style: TextStyle(
                                      color: !_mobileShowMonthGrid
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => setState(() => _mobileShowMonthGrid = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _mobileShowMonthGrid
                                    ? AppTheme.accentBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 15,
                                    color: _mobileShowMonthGrid
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Vue Mois',
                                    style: TextStyle(
                                      color: _mobileShowMonthGrid
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _mobileShowMonthGrid
                        ? _buildMonthlyCalendarColumn(
                            context,
                            selectedDate,
                            filteredEvents,
                          )
                        : _buildDayTimelineColumn(
                            context,
                            selectedDate,
                            selectedDayEvents,
                          ),
                  ),
                ],
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur Calendrier: $e')),
    );
  }

  /// Colonne Gauche : Grille Mensuelle Interactive + Filtres + Bilan Capacité
  Widget _buildMonthlyCalendarColumn(
    BuildContext context,
    DateTime selectedDate,
    List<CalendarEventItem> events,
  ) {
    final monthName = kFrenchMonths[(_focusedMonth.month - 1).clamp(0, 11)];
    final daysInGrid = _computeMonthGridDays(_focusedMonth);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calcul des statistiques du jour sélectionné
    final dayEvents = events.where((e) => e.isSameDay(selectedDate)).toList();
    final totalMinutes =
        dayEvents.fold<int>(0, (sum, e) => sum + e.durationMinutes);
    final meetingsCount = dayEvents
        .where((e) =>
            e.category == CalendarEventCategory.meeting ||
            e.category == CalendarEventCategory.teamSync)
        .length;

    return LayoutBuilder(
      builder: (context, colConstraints) {
        final isCompact = colConstraints.maxWidth < 640;

        return Container(
          decoration: AppTheme.neumorphicCard(
            color: AppTheme.bgMain,
            radius: 24,
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Titre du Mois + Navigation
              if (isCompact) ...[
                // En-tête Compact pour Mobile (ne s'écrase jamais)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$monthName ${_focusedMonth.year}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _buildIconPillButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _previousMonth,
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _goToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderHighlight),
                        ),
                        child: Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildIconPillButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _nextMonth,
                    ),
                  ],
                ),
              ] else ...[
                // En-tête Large pour Desktop / Tablettes
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.accentBlue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthName ${_focusedMonth.year}',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Calendrier des Réunions, Points Équipe, Créneaux Focus & Échéances',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildIconPillButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _previousMonth,
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _goToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppTheme.borderHighlight),
                        ),
                        child: Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildIconPillButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _nextMonth,
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => ref
                          .read(cockpitMainViewProvider.notifier)
                          .setView(CockpitMainView.cockpit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color:
                                AppTheme.accentBlue.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.layers_rounded,
                              size: 15,
                              color: AppTheme.accentBlue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Retour Cockpit',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Barre de filtres par catégorie
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryFilterChip(null, 'Tous les flux'),
                    ...CalendarEventCategory.values.map(
                      (cat) => _buildCategoryFilterChip(cat, cat.label),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // En-tête des 7 jours de la semaine (LUN -> DIM)
              Row(
                children: kFrenchWeekdaysShort
                    .map(
                      (dayLabel) => Expanded(
                        child: Center(
                          child: Text(
                            dayLabel,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: isCompact ? 0 : 0.8,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Grille Mensuelle
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isCompact ? 4 : 8),
                  decoration: AppTheme.neumorphicCard(
                    color: AppTheme.surfaceCard,
                    radius: 18,
                  ),
                  child: LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final calculatedRowHeight =
                          (gridConstraints.maxHeight - 30) / 6;
                      final cellHeight =
                          calculatedRowHeight.clamp(isCompact ? 52.0 : 84.0, 135.0);

                      return Scrollbar(
                        controller: _monthGridScrollController,
                        thumbVisibility: true,
                        child: GridView.builder(
                          controller: _monthGridScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(right: 6),
                          itemCount: daysInGrid.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: isCompact ? 4 : 6,
                            crossAxisSpacing: isCompact ? 4 : 6,
                            mainAxisExtent: cellHeight,
                          ),
                          itemBuilder: (context, index) {
                            final day = daysInGrid[index];
                            final isCurrentMonth =
                                day.month == _focusedMonth.month;
                            final isToday = day.year == today.year &&
                                day.month == today.month &&
                                day.day == today.day;
                            final isSelected =
                                day.year == selectedDate.year &&
                                    day.month == selectedDate.month &&
                                    day.day == selectedDate.day;

                            final cellEvents =
                                events.where((e) => e.isSameDay(day)).toList();

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                ref
                                    .read(selectedCalendarDateProvider.notifier)
                                    .selectDate(day);
                                if (!isCurrentMonth) {
                                  setState(() {
                                    _focusedMonth =
                                        DateTime(day.year, day.month, 1);
                                  });
                                }
                                if (isCompact) {
                                  setState(() {
                                    _mobileShowMonthGrid = false;
                                  });
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 3 : 6,
                                    vertical: isCompact ? 3 : 5),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            AppTheme.accentBlue
                                                .withValues(alpha: 0.28),
                                            AppTheme.accentIndigo
                                                .withValues(alpha: 0.18),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : isCurrentMonth
                                          ? AppTheme.surfaceElevated
                                          : AppTheme.bgDeep
                                              .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.accentBlue
                                        : isToday
                                            ? AppTheme.neonAmber
                                                .withValues(alpha: 0.85)
                                            : AppTheme.borderSubtle,
                                    width:
                                        isSelected || isToday ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${day.day}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.accentBlue
                                                : isCurrentMonth
                                                    ? AppTheme.textPrimary
                                                    : AppTheme.textMuted,
                                            fontWeight: isSelected || isToday
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: isCompact ? 11 : 12,
                                          ),
                                        ),
                                        if (isToday)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                    vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.neonAmber
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              'AUJ',
                                              style: TextStyle(
                                                color: AppTheme.neonAmber,
                                                fontSize: isCompact ? 7.5 : 8.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          )
                                        else if (cellEvents.isNotEmpty &&
                                            !isCompact)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgDeep,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${cellEvents.length}',
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    // Aperçu des événements du jour dans la cellule
                                    if (cellEvents.isNotEmpty)
                                      Expanded(
                                        child: isCompact
                                            ? Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 1),
                                                  child: Wrap(
                                                    spacing: 2.5,
                                                    runSpacing: 2,
                                                    alignment:
                                                        WrapAlignment.center,
                                                    children: cellEvents
                                                        .take(3)
                                                        .map((ev) {
                                                      return Container(
                                                        width: 5,
                                                        height: 5,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: ev.category
                                                              .accentColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              )
                                            : ClipRect(
                                                child: SingleChildScrollView(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: cellEvents
                                                        .take(3)
                                                        .map((ev) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 2),
                                                        child: Container(
                                                          width: double.infinity,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      4,
                                                                  vertical:
                                                                      1.5),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ev
                                                                .category
                                                                .accentColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.18),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            border: Border(
                                                              left: BorderSide(
                                                                color: ev
                                                                    .category
                                                                    .accentColor,
                                                                width: 2.5,
                                                              ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            '${ev.formattedStartTime} ${ev.title}',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: ev
                                                                      .isCompleted
                                                                  ? AppTheme
                                                                      .textMuted
                                                                  : AppTheme
                                                                      .textPrimary,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              decoration: ev
                                                                      .isCompleted
                                                                  ? TextDecoration
                                                                      .lineThrough
                                                                  : null,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bandeau récapitulatif de charge du jour sélectionné (avec défilement horizontal fluide)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: AppTheme.neumorphicCard(
                  color: AppTheme.surfaceCard,
                  radius: 14,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDayMetricBadge(
                        icon: Icons.event_note_rounded,
                        color: AppTheme.accentBlue,
                        label: 'Événements',
                        value: '${dayEvents.length}',
                      ),
                      const SizedBox(width: 12),
                      _buildDayMetricBadge(
                        icon: Icons.videocam_rounded,
                        color: AppTheme.neonPurple,
                        label: 'Réunions',
                        value: '$meetingsCount',
                      ),
                      const SizedBox(width: 12),
                      _buildDayMetricBadge(
                        icon: Icons.schedule_rounded,
                        color: AppTheme.neonAmber,
                        label: 'Planifié',
                        value: _formatMinutes(totalMinutes),
                      ),
                      const SizedBox(width: 12),
                      _buildDayMetricBadge(
                        icon: Icons.shield_rounded,
                        color: AppTheme.neonGreen,
                        label: 'Focus libre',
                        value:
                            _formatMinutes((480 - totalMinutes).clamp(0, 480)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Colonne Droite : Timeline Horaire & Agenda détaillé du jour sélectionné
  Widget _buildDayTimelineColumn(
    BuildContext context,
    DateTime selectedDate,
    List<CalendarEventItem> dayEvents,
  ) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Container(
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.bgMain,
        radius: 24,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du jour sélectionné + Bouton "+ Planifier Réunion / Tâche"
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            formatFullFrenchDate(selectedDate),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.neonGreen.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text(
                              'AUJOURD\'HUI',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cliquez sur « 🚨 Rejoindre (PUSH) » au début d\'une réunion pour sauvegarder votre contexte de fond',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showAddOrEditCalendarEventDialog(
                  context,
                  ref,
                  initialDate: selectedDate,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 17, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Planifier',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Liste chronologique des événements du jour
          Expanded(
            child: dayEvents.isEmpty
                ? _buildEmptyDayState(context, selectedDate)
                : Scrollbar(
                    controller: _dayTimelineScrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _dayTimelineScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(right: 6),
                      itemCount: dayEvents.length,
                      itemBuilder: (context, index) {
                        final ev = dayEvents[index];
                        return _buildTimelineEventCard(context, ev);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEventCard(BuildContext context, CalendarEventItem ev) {
    final accent = ev.category.accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colonne Horaire à gauche (ex: 11:00 -> 12:00 + durée)
            SizedBox(
              width: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ev.formattedStartTime,
                    style: TextStyle(
                      color: ev.isCompleted
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ev.formattedDuration,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Carte détaillée de la réunion / tâche datée
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ev.isCompleted
                      ? AppTheme.surfaceCard.withValues(alpha: 0.65)
                      : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ev.isCompleted
                        ? AppTheme.neonGreen.withValues(alpha: 0.35)
                        : accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne supérieure : Catégorie + Horaires + Ticket AzDO + Modifier/Supprimer
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(ev.category.icon, size: 12, color: accent),
                              const SizedBox(width: 5),
                              Text(
                                ev.category.label,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ev.formattedTimeRange,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (ev.externalRef != null &&
                            ev.externalRef!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentBlue.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ev.externalRef!,
                              style: const TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Modifier
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => showAddOrEditCalendarEventDialog(
                            context,
                            ref,
                            existingEvent: ev,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Supprimer
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => ref
                              .read(taskRepositoryProvider)
                              .deleteCalendarEvent(ev.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Titre de la réunion / échéance
                    Text(
                      ev.title,
                      style: TextStyle(
                        color: ev.isCompleted
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration:
                            ev.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),

                    // Participants / Lieu
                    if (ev.participantsOrLocation != null &&
                        ev.participantsOrLocation!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              ev.participantsOrLocation!,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Notes / Ordre du jour
                    if (ev.notes != null && ev.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          ev.notes!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Indicateur de Note de réunion associée
                    Builder(
                      builder: (context) {
                        final notesState = ref.watch(meetingNotesProvider);
                        final linkedNote = notesState.meetings
                            .cast<MeetingNote?>()
                            .firstWhere((m) => m?.calendarEventId == ev.id,
                                orElse: () => null);

                        if (linkedNote == null) return const SizedBox.shrink();

                        return InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () async {
                            await ref
                                .read(meetingNotesProvider.notifier)
                                .getOrCreateNoteForCalendarEvent(ev);
                            ref
                                .read(cockpitMainViewProvider.notifier)
                                .setView(CockpitMainView.meetings);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.neonCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                  color:
                                      AppTheme.neonCyan.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description_rounded,
                                    size: 13, color: AppTheme.neonCyan),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '📝 Note associée (${linkedNote.actionItems.length} action${linkedNote.actionItems.length > 1 ? "s" : ""}) • Cliquer pour ouvrir',
                                    style: const TextStyle(
                                      color: AppTheme.neonCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Barre d'actions adaptative : Rejoindre (PUSH Pile) + Prise de notes + Marquer Terminé
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!ev.isCompleted)
                          InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => _showPushMeetingToStackDialog(
                              context,
                              ref,
                              ev,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: AppTheme.urgencyGradient,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call_received_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '🚨 Rejoindre (PUSH Pile)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Bouton d'accès direct à la prise de notes pour ce rendez-vous
                        Builder(
                          builder: (context) {
                            final notesState = ref.watch(meetingNotesProvider);
                            final hasNote = notesState.meetings.any(
                                (m) => m.calendarEventId == ev.id);

                            return InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () async {
                                await ref
                                    .read(meetingNotesProvider.notifier)
                                    .getOrCreateNoteForCalendarEvent(ev);
                                ref
                                    .read(cockpitMainViewProvider.notifier)
                                    .setView(CockpitMainView.meetings);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: hasNote
                                      ? AppTheme.neonCyan
                                          .withValues(alpha: 0.16)
                                      : AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: hasNote
                                        ? AppTheme.neonCyan
                                            .withValues(alpha: 0.6)
                                        : AppTheme.borderHighlight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasNote
                                          ? Icons.description_rounded
                                          : Icons.edit_note_rounded,
                                      size: 14,
                                      color: hasNote
                                          ? AppTheme.neonCyan
                                          : AppTheme.accentBlue,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      hasNote ? 'Notes (Ouvrir)' : 'Prendre notes',
                                      style: TextStyle(
                                        color: hasNote
                                            ? AppTheme.neonCyan
                                            : AppTheme.textPrimary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () => ref
                              .read(taskRepositoryProvider)
                              .toggleCalendarEventCompleted(
                                  ev.id, !ev.isCompleted),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: ev.isCompleted
                                  ? AppTheme.surfaceElevated
                                  : AppTheme.neonGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: ev.isCompleted
                                    ? AppTheme.borderHighlight
                                    : AppTheme.neonGreen.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ev.isCompleted
                                      ? Icons.replay_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: ev.isCompleted
                                      ? AppTheme.textSecondary
                                      : AppTheme.neonGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  ev.isCompleted ? 'Rouvrir' : 'Terminé ✓',
                                  style: TextStyle(
                                    color: ev.isCompleted
                                        ? AppTheme.textSecondary
                                        : AppTheme.neonGreen,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context, DateTime selectedDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.neumorphicCard(
        color: AppTheme.surfaceCard,
        radius: 18,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentBlue.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppTheme.accentBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun événement ou réunion sur cette journée',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Journée 100 % disponible pour vos Tâches de Fond (Deep Work) ou planifiez une réunion.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => showAddOrEditCalendarEventDialog(
              context,
              ref,
              initialDate: selectedDate,
            ),
            icon: const Icon(Icons.add_rounded, size: 17, color: Colors.white),
            label: const Text(
              'Planifier une réunion ou échéance',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(
      CalendarEventCategory? category, String label) {
    final isSelected = _selectedCategoryFilter == category;
    final color = category?.accentColor ?? AppTheme.accentBlue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedCategoryFilter = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected ? color.withValues(alpha: 0.8) : AppTheme.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPillButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderHighlight),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildDayMetricBadge({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatMinutes(int mins) {
    if (mins <= 0) return '0h00';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h00' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  /// Génère les 42 jours (6 semaines du Lundi au Dimanche) de la grille mensuelle
  List<DateTime> _computeMonthGridDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingDays = firstOfMonth.weekday - 1; // 0 pour Lundi, 6 pour Dimanche
    return List.generate(
      42,
      (i) => DateTime(month.year, month.month, 1 - leadingDays + i),
    );
  }

  /// Modale PUSH Réunion : met en pause le chronomètre Focus, sauvegarde la Note de reprise obligatoire
  /// et empile la réunion au sommet de la Pile Active.
  Future<void> _showPushMeetingToStackDialog(
    BuildContext context,
    WidgetRef ref,
    CalendarEventItem ev,
  ) async {
    await ref.read(focusTimerProvider.notifier).pauseTimer();
    if (!context.mounted) return;

    final resumeCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonPink.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: AppTheme.neonPink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🚨 Rejoindre Réunion (PUSH dans la Pile)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '📅 ${ev.formattedTimeRange} — ${ev.title}',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Note de reprise obligatoire : où en étais-tu exactement avant la réunion ?',
                style: TextStyle(
                  color: AppTheme.neonAmber,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: resumeCtrl,
                autofocus: true,
                maxLines: 2,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText:
                      'Ex: J\'étais à la moitié de la spécification RPC V2, reprendre le test unitaire après la réunion.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
            onPressed: () async {
              final note = resumeCtrl.text.trim().isEmpty
                  ? 'Pause réunion [${ev.title}] — reprendre le fil immédiatement après.'
                  : resumeCtrl.text.trim();
              await ref.read(taskRepositoryProvider).pushCalendarEventToStack(
                    eventId: ev.id,
                    resumeNote: note,
                  );
              ref.read(appNotificationsProvider.notifier).pushNotification(
                    title: '🚨 Réunion empilée au sommet (PUSH) : ${ev.title}',
                    body: 'Note de reprise verrouillée : "$note"',
                    type: AppNotificationType.stackPush,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              ref
                  .read(cockpitMainViewProvider.notifier)
                  .setView(CockpitMainView.cockpit);
            },
            icon: const Icon(Icons.layers_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Sauvegarder & PUSH Réunion',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boîte de dialogue réutilisable pour créer ou modifier un événement du calendrier
/// (Accessible depuis la vue Calendrier complète ET depuis le Mini-Agenda de la colonne gauche)
Future<void> showAddOrEditCalendarEventDialog(
  BuildContext context,
  WidgetRef ref, {
  DateTime? initialDate,
  CalendarEventItem? existingEvent,
}) async {
  final DateTime baseDate = existingEvent?.startTime ??
      initialDate ??
      ref.read(selectedCalendarDateProvider);

  DateTime selectedDay =
      DateTime(baseDate.year, baseDate.month, baseDate.day);
  TimeOfDay startTime = existingEvent != null
      ? TimeOfDay(
          hour: existingEvent.startTime.hour,
          minute: existingEvent.startTime.minute)
      : const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay endTime = existingEvent != null
      ? TimeOfDay(
          hour: existingEvent.endTime.hour,
          minute: existingEvent.endTime.minute)
      : const TimeOfDay(hour: 11, minute: 0);

  CalendarEventCategory selectedCategory =
      existingEvent?.category ?? CalendarEventCategory.meeting;

  final titleCtrl = TextEditingController(text: existingEvent?.title ?? '');
  final locationCtrl = TextEditingController(
      text: existingEvent?.participantsOrLocation ?? '');
  final refCtrl = TextEditingController(text: existingEvent?.externalRef ?? '');
  final notesCtrl = TextEditingController(text: existingEvent?.notes ?? '');

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          String formatTime(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.borderHighlight),
            ),
            title: Row(
              children: [
                Icon(
                  existingEvent != null
                      ? Icons.edit_calendar_rounded
                      : Icons.add_alert_rounded,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  existingEvent != null
                      ? 'Modifier l\'événement planifié'
                      : 'Planifier une Réunion / Tâche datée',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélecteur de catégorie
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CalendarEventCategory.values.map((cat) {
                        final isSel = selectedCategory == cat;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setModalState(() => selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? cat.accentColor.withValues(alpha: 0.2)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? cat.accentColor
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                color: isSel
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Titre
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Titre de la réunion ou tâche planifiée',
                        hintText:
                            'Ex: Comité d\'Architecture Sync V2 / Revue PR Sprint',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sélecteur de Date + Heure Début + Heure Fin
                    Row(
                      children: [
                        // Date
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDay,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDay = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 14, color: AppTheme.accentBlue),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '${selectedDay.day.toString().padLeft(2, '0')}/${selectedDay.month.toString().padLeft(2, '0')}/${selectedDay.year}',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Heure Début
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setModalState(() => startTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 14, color: AppTheme.neonGreen),
                                  const SizedBox(width: 5),
                                  Text(
                                    formatTime(startTime),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Heure Fin
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setModalState(() => endTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.flag_outlined,
                                      size: 14, color: AppTheme.neonPink),
                                  const SizedBox(width: 5),
                                  Text(
                                    formatTime(endTime),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Participants / Lieu + Ticket AzDO
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: locationCtrl,
                            style: TextStyle(
                                color: AppTheme.textPrimary, fontSize: 12.5),
                            decoration: const InputDecoration(
                              labelText: 'Lieu / Lien Teams / Participants',
                              hintText: 'Ex: Teams • CTO, Lucas M.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: refCtrl,
                            style: TextStyle(
                                color: AppTheme.textPrimary, fontSize: 12.5),
                            decoration: const InputDecoration(
                              labelText: 'Ticket AzDO',
                              hintText: 'AB#8412',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes / Ordre du jour
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
                      decoration: const InputDecoration(
                        labelText: 'Ordre du jour / Notes préparatoires',
                        hintText:
                            'Ex: Valider le diagramme de séquence et les index SQL',
                      ),
                    ),

                    // Section directe Prise de Notes de Réunion (si événement existant)
                    if (existingEvent != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentBlue.withValues(alpha: 0.15),
                              AppTheme.neonCyan.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.neonCyan.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_rounded,
                                color: AppTheme.neonCyan, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Prise de notes associée',
                                    style: TextStyle(
                                      color: AppTheme.neonCyan,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Comptes-rendus, ordre du jour et actions clés synchronisés',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await ref
                                    .read(meetingNotesProvider.notifier)
                                    .getOrCreateNoteForCalendarEvent(
                                        existingEvent);
                                ref
                                    .read(cockpitMainViewProvider.notifier)
                                    .setView(CockpitMainView.meetings);
                              },
                              icon: const Icon(Icons.edit_note_rounded,
                                  size: 16),
                              label: const Text(
                                'Ouvrir les notes',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;

                  final startDt = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  var endDt = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                    endTime.hour,
                    endTime.minute,
                  );
                  if (!endDt.isAfter(startDt)) {
                    endDt = startDt.add(const Duration(minutes: 45));
                  }

                  if (existingEvent != null) {
                    await ref.read(taskRepositoryProvider).updateCalendarEvent(
                          existingEvent.copyWith(
                            title: titleCtrl.text.trim(),
                            category: selectedCategory,
                            startTime: startDt,
                            endTime: endDt,
                            participantsOrLocation:
                                locationCtrl.text.trim().isEmpty
                                    ? null
                                    : locationCtrl.text.trim(),
                            externalRef: refCtrl.text.trim().isEmpty
                                ? null
                                : refCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          ),
                        );
                  } else {
                    await ref.read(taskRepositoryProvider).addCalendarEvent(
                          title: titleCtrl.text.trim(),
                          category: selectedCategory,
                          startTime: startDt,
                          endTime: endDt,
                          participantsOrLocation: locationCtrl.text.trim(),
                          externalRef: refCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                        );
                  }
                  ref
                      .read(selectedCalendarDateProvider.notifier)
                      .selectDate(selectedDay);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon:
                    const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                label: Text(
                  existingEvent != null ? 'Enregistrer' : 'Planifier',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
