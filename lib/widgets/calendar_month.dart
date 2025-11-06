import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class CalendarMonth extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final OnDaySelected onDaySelected;
  final Set<DateTime> markedDates;

  const CalendarMonth({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    this.markedDates = const {},
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassContainer(borderRadius: 24),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            calendarStyle: CalendarStyle(
              // Today decoration
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.cosmicBlue.withOpacity(0.3),
                    AppTheme.cosmicBlue.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.cosmicBlue.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              // Selected decoration
              selectedDecoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.deepViolet,
                    AppTheme.dreamPurple,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepViolet.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              // Marker decoration
              markerDecoration: BoxDecoration(
                color: AppTheme.joyfulAmber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.joyfulAmber.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              // Text styles
              defaultTextStyle: const TextStyle(
                color: AppTheme.moonGlow,
                fontWeight: FontWeight.w500,
              ),
              weekendTextStyle: TextStyle(
                color: AppTheme.nebulaPink.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              outsideTextStyle: TextStyle(
                color: AppTheme.cosmicGray.withOpacity(0.3),
              ),
              selectedTextStyle: const TextStyle(
                color: AppTheme.starLight,
                fontWeight: FontWeight.w700,
              ),
              todayTextStyle: const TextStyle(
                color: AppTheme.cosmicBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                color: AppTheme.starLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.moonGlow,
                size: 28,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.moonGlow,
                size: 28,
              ),
              decoration: BoxDecoration(
                color: AppTheme.glassOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppTheme.moonGlow.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: AppTheme.nebulaPink.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            eventLoader: (day) {
              return markedDates.contains(DateTime(day.year, day.month, day.day))
                  ? [1]
                  : [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.joyfulAmber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.joyfulAmber.withOpacity(0.8),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

}
