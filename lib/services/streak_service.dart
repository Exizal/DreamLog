import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_boxes.dart';

/// Service to manage dream logging streak data
/// Streak is based on per day, not per dream
/// If 24+ hours pass without adding a dream, streak resets
class StreakService {
  static const String _lastDreamDateKey = 'last_dream_date';
  static const String _currentStreakKey = 'current_streak';

  /// Get the preferences box
  Box get _prefsBox {
    if (!Hive.isBoxOpen(HiveBoxes.preferences)) {
      throw Exception('Preferences box is not open');
    }
    return Hive.box(HiveBoxes.preferences);
  }

  /// Get the last date a dream was added (date only, no time)
  DateTime? getLastDreamDate() {
    try {
      final dateString = _prefsBox.get(_lastDreamDateKey) as String?;
      if (dateString == null) return null;
      final date = DateTime.parse(dateString);
      // Return date only (normalized to midnight)
      return DateTime(date.year, date.month, date.day);
    } catch (e) {
      return null;
    }
  }

  /// Get the current streak count
  int getCurrentStreak() {
    try {
      return _prefsBox.get(_currentStreakKey, defaultValue: 0) as int;
    } catch (e) {
      return 0;
    }
  }

  /// Update streak when a dream is added
  /// Returns the updated streak count
  /// Streak is based on per day, not per dream
  /// If 24+ hours pass without adding a dream, streak resets to 1 when next dream is added
  Future<int> updateStreak(DateTime dreamDate) async {
    try {
      // Normalize dream date to just the date (no time)
      final dreamDateOnly = DateTime(dreamDate.year, dreamDate.month, dreamDate.day);
      final now = DateTime.now();

      // Get current streak and last dream date
      int currentStreak = getCurrentStreak();
      final lastDreamDate = getLastDreamDate();

      if (lastDreamDate == null) {
        // First dream ever - start streak at 1
        currentStreak = 1;
      } else {
        // Calculate days difference between dream dates
        final daysDifference = dreamDateOnly.difference(lastDreamDate).inDays;

        if (daysDifference == 0) {
          // Same day as last dream - don't increment streak
          // Keep current streak as is (per day, not per dream)
          // If streak is 0, it means it was reset, so start at 1
          if (currentStreak == 0) {
            currentStreak = 1;
          }
        } else if (daysDifference == 1) {
          // Next consecutive day - check if 24 hours have passed
          // We check if more than 24 hours have passed since the last dream day ended
          final lastDreamDayEnd = DateTime(
            lastDreamDate.year,
            lastDreamDate.month,
            lastDreamDate.day,
            23,
            59,
            59,
          );
          
          final hoursSinceLastDreamDay = now.difference(lastDreamDayEnd).inHours;
          
          if (hoursSinceLastDreamDay <= 24) {
            // Within 24 hours of last dream day - increment streak
            // If streak is 0 (was reset), start at 1, otherwise increment
            if (currentStreak == 0) {
              currentStreak = 1;
            } else {
              currentStreak++;
            }
          } else {
            // More than 24 hours have passed - reset streak to 1 (starting fresh)
            currentStreak = 1;
          }
        } else {
          // More than 1 day gap - reset streak to 1 (starting fresh)
          currentStreak = 1;
        }
      }

      // Save updated streak and last dream date
      await _prefsBox.put(_currentStreakKey, currentStreak);
      await _prefsBox.put(_lastDreamDateKey, dreamDateOnly.toIso8601String());

      return currentStreak;
    } catch (e) {
      // If there's an error, return current streak or start at 1
      return getCurrentStreak() > 0 ? getCurrentStreak() : 1;
    }
  }

  /// Validate and potentially reset streak if needed
  /// This checks if streak should be reset based on time since last dream
  /// If 24+ hours have passed since the last dream day ended, reset streak to 0
  /// Returns true if streak was reset, false otherwise
  bool validateStreak() {
    try {
      final lastDreamDate = getLastDreamDate();
      if (lastDreamDate == null) {
        // No last dream date - reset streak to 0
        _prefsBox.put(_currentStreakKey, 0);
        return true;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Calculate hours since last dream day ended (assuming it was at end of that day, 23:59:59)
      final lastDreamDayEnd = DateTime(
        lastDreamDate.year,
        lastDreamDate.month,
        lastDreamDate.day,
        23,
        59,
        59,
      );
      
      final hoursSinceLastDream = now.difference(lastDreamDayEnd).inHours;
      final daysSinceLastDream = today.difference(lastDreamDate).inDays;

      // If more than 24 hours have passed since the last dream day ended
      if (hoursSinceLastDream > 24) {
        if (daysSinceLastDream > 1) {
          // More than 24 hours passed and more than 1 day gap - reset streak to 0
          _prefsBox.put(_currentStreakKey, 0);
          return true;
        } else if (daysSinceLastDream == 1) {
          // It's the next day but more than 24 hours have passed
          // Reset streak to 0 (they can start a new streak when they add a dream)
          _prefsBox.put(_currentStreakKey, 0);
          return true;
        }
        // daysSinceLastDream == 0 means same day - keep streak as is
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Reset streak (useful for testing or manual reset)
  Future<void> resetStreak() async {
    try {
      await _prefsBox.delete(_lastDreamDateKey);
      await _prefsBox.delete(_currentStreakKey);
    } catch (e) {
      // Ignore errors
    }
  }
}

