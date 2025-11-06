import 'package:hive_flutter/hive_flutter.dart';
import '../models/dream_entry.dart';
import '../data/hive_boxes.dart';

class DreamRepository {
  Box<DreamEntry>? _dreamsBox;
  bool _isInitializing = false;

  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      // Boxes are already opened in main.dart, so just get the existing box
      if (Hive.isBoxOpen(HiveBoxes.dreams)) {
        _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
      } else {
        // If for some reason it's not open, open it
        _dreamsBox = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
      }
    } catch (e) {
      // If there's an error, try to get the box anyway
      try {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          // Last resort: try to open it
          _dreamsBox = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
        }
      } catch (e2) {
        // If we can't get the box, it will remain null
        // Methods will handle this gracefully
        _dreamsBox = null;
      }
    } finally {
      _isInitializing = false;
    }
  }

  Stream<List<DreamEntry>> watchAll() {
    try {
      // Try to get box if not already set
      if (_dreamsBox == null) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          return Stream.value(<DreamEntry>[]);
        }
      }
      
      if (!_dreamsBox!.isOpen) {
        return Stream.value(<DreamEntry>[]);
      }
      
      return _dreamsBox!.watch().map((_) {
        try {
          if (_dreamsBox == null || !_dreamsBox!.isOpen) {
            return <DreamEntry>[];
          }
          return _dreamsBox!.values
              .where((dream) => !dream.isDeleted)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        } catch (e) {
          return <DreamEntry>[];
        }
      });
    } catch (e) {
      return Stream.value(<DreamEntry>[]);
    }
  }

  List<DreamEntry> getAll() {
    try {
      // Try to get box if not already set
      if (_dreamsBox == null) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          return [];
        }
      }
      
      if (!_dreamsBox!.isOpen) {
        return [];
      }
      
      return _dreamsBox!.values
          .where((dream) => !dream.isDeleted)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  Future<void> addDream(DreamEntry dream) async {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        await init();
      }
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        // Ensure folderId is set to Dreams by default if not set
        final dreamToSave = dream.folderId.isEmpty ? dream.copyWith(folderId: 'Dreams') : dream;
        await _dreamsBox!.put(dreamToSave.id, dreamToSave);
      } else {
        throw Exception('Dream box is not initialized');
      }
    } catch (e) {
      rethrow; // Re-throw to show error to user
    }
  }

  Future<void> updateDream(DreamEntry dream) async {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        await init();
      }
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        await _dreamsBox!.put(dream.id, dream);
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> deleteDream(String id) async {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        await init();
      }
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        final dream = _dreamsBox!.get(id);
        if (dream != null) {
          // Mark as deleted instead of permanently deleting
          final deletedDream = dream.copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
          );
          await _dreamsBox!.put(id, deletedDream);
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  // Get deleted dreams
  List<DreamEntry> getDeletedDreams() {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        return [];
      }
      return _dreamsBox!.values
          .where((dream) => dream.isDeleted && dream.deletedAt != null)
          .toList()
        ..sort((a, b) => (b.deletedAt ?? DateTime.now())
            .compareTo(a.deletedAt ?? DateTime.now()));
    } catch (e) {
      return [];
    }
  }

  // Restore a deleted dream
  Future<void> restoreDream(String id) async {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        await init();
      }
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        final dream = _dreamsBox!.get(id);
        if (dream != null) {
          final restoredDream = dream.copyWith(
            isDeleted: false,
            deletedAt: null,
          );
          await _dreamsBox!.put(id, restoredDream);
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  // Permanently delete old dreams (older than 30 days)
  Future<void> permanentlyDeleteOldDreams() async {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        await init();
      }
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final deletedDreams = _dreamsBox!.values
            .where((dream) => 
                dream.isDeleted && 
                dream.deletedAt != null &&
                dream.deletedAt!.isBefore(thirtyDaysAgo))
            .toList();
        
        for (final dream in deletedDreams) {
          await _dreamsBox!.delete(dream.id);
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  // Permanently delete a specific dream
  Future<void> permanentlyDeleteDream(String id) async {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        await init();
      }
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        await _dreamsBox!.delete(id);
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  DreamEntry? getDream(String id) {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        return null;
      }
      return _dreamsBox!.get(id);
    } catch (e) {
      return null;
    }
  }

  List<DreamEntry> getByDate(DateTime date) {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        return [];
      }
      final dateOnly = DateTime(date.year, date.month, date.day);
      return _dreamsBox!.values
          .where((dream) {
            if (dream.isDeleted) return false;
            final dreamDateOnly =
                DateTime(dream.date.year, dream.date.month, dream.date.day);
            return dreamDateOnly.isAtSameMomentAs(dateOnly);
          })
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  int computeStreak() {
    try {
      final allDreams = getAll();
      if (allDreams.isEmpty) return 0;

      // Get unique dates (day-level)
      final datesWithEntries = allDreams
          .map((dream) => DateTime(
                dream.date.year,
                dream.date.month,
                dream.date.day,
              ))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      if (datesWithEntries.isEmpty) return 0;

      // Check if today has an entry
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final latestDate = datesWithEntries.first;

      // If latest entry is not today or yesterday, streak is 0
      final daysDiff = todayOnly.difference(latestDate).inDays;
      if (daysDiff > 1) return 0;

      // Count consecutive days from latest date backwards
      int streak = 0;
      DateTime currentDate = latestDate;

      for (final entryDate in datesWithEntries) {
        final daysDiff = currentDate.difference(entryDate).inDays;
        if (daysDiff == 0) {
          // Same day
          if (streak == 0) streak = 1;
        } else if (daysDiff == 1) {
          // Consecutive day
          streak++;
          currentDate = entryDate;
        } else {
          // Gap found, streak breaks
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Calculate entries this year
  int getEntriesThisYear() {
    try {
      final allDreams = getAll();
      if (allDreams.isEmpty) return 0;
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);
      return allDreams.where((dream) => 
          dream.date.isAfter(yearStart.subtract(const Duration(days: 1))) || 
          dream.date.isAtSameMomentAs(yearStart)).length;
    } catch (e) {
      return 0;
    }
  }

  // Calculate unique days journaled
  int getDaysJournaled() {
    try {
      final allDreams = getAll();
      if (allDreams.isEmpty) return 0;
      final uniqueDates = allDreams
          .map((dream) => DateTime(dream.date.year, dream.date.month, dream.date.day))
          .toSet();
      return uniqueDates.length;
    } catch (e) {
      return 0;
    }
  }

  // Calculate total words
  int getTotalWords() {
    try {
      final allDreams = getAll();
      if (allDreams.isEmpty) return 0;
      return allDreams.fold(0, (sum, dream) {
        try {
          final titleWords = dream.title.trim().isEmpty ? 0 : dream.title.split(RegExp(r'\s+')).length;
          final contentWords = dream.content.trim().isEmpty ? 0 : dream.content.split(RegExp(r'\s+')).length;
          return sum + titleWords + contentWords;
        } catch (e) {
          return sum;
        }
      });
    } catch (e) {
      return 0;
    }
  }
}
