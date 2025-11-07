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
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacingS + 4),
          decoration: AppTheme.glassContainer(borderRadius: 22),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            calendarStyle: CalendarStyle(
              // Today decoration - softer, more rounded
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPrimary.withOpacity(0.25),
                    AppTheme.accentPrimary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentPrimary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              // Selected decoration - softer colors
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentSecondary.withOpacity(0.6),
                    AppTheme.accentPrimary.withOpacity(0.4),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentSecondary.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              // Marker decoration - smaller, softer
              markerDecoration: BoxDecoration(
                color: AppTheme.accentPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              // Text styles - smaller for mobile
              defaultTextStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              weekendTextStyle: TextStyle(
                color: AppTheme.accentTertiary.withOpacity(0.7),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              outsideTextStyle: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.3),
                fontSize: 12,
              ),
              selectedTextStyle: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              todayTextStyle: TextStyle(
                color: AppTheme.accentPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.glassOverlay.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              weekendStyle: TextStyle(
                color: AppTheme.accentTertiary.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 11,
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
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPrimary.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 0.5,
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
