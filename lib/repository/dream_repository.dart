import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dream_entry.dart';
import '../data/hive_boxes.dart';
import '../services/streak_service.dart';

class DreamRepository {
  Box<DreamEntry>? _dreamsBox;
  bool _isInitializing = false;
  final StreakService _streakService = StreakService();

  Future<void> init() async {
    if (_isInitializing) {
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    
    _isInitializing = true;
    
    try {
      // Try to get existing box first (should already be open from main.dart)
      if (Hive.isBoxOpen(HiveBoxes.dreams)) {
        _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        debugPrint('Dreams box already open, using existing box');
      } else {
        // Open the box if it's not already open
        debugPrint('Opening dreams box...');
        _dreamsBox = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
        debugPrint('Dreams box opened successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in dream repository init: $e');
      debugPrint('Stack trace: $stackTrace');
      try {
        // Retry once
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
          debugPrint('Dreams box retrieved on retry');
        } else {
          _dreamsBox = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
          debugPrint('Dreams box opened on retry');
        }
      } catch (e2) {
        debugPrint('Error in dream repository init fallback: $e2');
        _dreamsBox = null;
      }
    } finally {
      _isInitializing = false;
    }
  }

  // Ensure box is initialized before operations
  Future<void> _ensureBoxInitialized() async {
    if (_dreamsBox != null && _dreamsBox!.isOpen) {
      return; // Box is already initialized
    }

    // Try to get the box
    if (Hive.isBoxOpen(HiveBoxes.dreams)) {
      _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        return; // Successfully got the box
      }
    }

    // Box is not open, try to initialize
    await init();

    // If still not initialized, try one more time
    if (_dreamsBox == null || !_dreamsBox!.isOpen) {
      if (Hive.isBoxOpen(HiveBoxes.dreams)) {
        _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
      } else {
        try {
          _dreamsBox = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
        } catch (e) {
          debugPrint('Failed to open dreams box: $e');
          throw Exception('Unable to initialize dreams storage. Please restart the app.');
        }
      }
    }
  }

  Stream<List<DreamEntry>> watchAll() async* {
    try {
      // Try to get box if not already set
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          // Box not available, emit empty list
          yield <DreamEntry>[];
          return;
        }
      }
      
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        yield <DreamEntry>[];
        return;
      }
      
      // Emit initial value immediately
      try {
        final initialDreams = _dreamsBox!.values
            .where((dream) => !dream.isDeleted)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        yield initialDreams;
      } catch (e) {
        yield <DreamEntry>[];
      }
      
      // Watch for changes and emit updated lists
      await for (final _ in _dreamsBox!.watch()) {
        try {
          if (_dreamsBox == null || !_dreamsBox!.isOpen) {
            yield <DreamEntry>[];
            continue;
          }
          final dreams = _dreamsBox!.values
              .where((dream) => !dream.isDeleted)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          yield dreams;
        } catch (e) {
          yield <DreamEntry>[];
        }
      }
    } catch (e) {
      debugPrint('Error in watchAll stream: $e');
      yield <DreamEntry>[];
    }
  }

  List<DreamEntry> getAll() {
    try {
      // Try to get box if not already set
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          return [];
        }
      }
      
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
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
      // Ensure box is initialized before adding
      await _ensureBoxInitialized();
      
      // Verify box is open
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        throw Exception('Dream box is not initialized. Please restart the app.');
      }
      
      // Ensure folderId is set to Dreams by default if not set
      final dreamToSave = dream.folderId.isEmpty ? dream.copyWith(folderId: 'Dreams') : dream;
      
      debugPrint('Saving dream with id: ${dreamToSave.id}');
      await _dreamsBox!.put(dreamToSave.id, dreamToSave);
      debugPrint('Dream saved successfully');
      
      // Update streak when a dream is added
      try {
        await _streakService.updateStreak(dreamToSave.date);
      } catch (e) {
        // Silently handle streak update errors - don't fail dream save
        debugPrint('Error updating streak: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding dream: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Re-throw to show error to user
    }
  }

  Future<void> updateDream(DreamEntry dream) async {
    try {
      await _ensureBoxInitialized();
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        await _dreamsBox!.put(dream.id, dream);
      }
    } catch (e) {
      debugPrint('Error updating dream: $e');
    }
  }

  Future<void> deleteDream(String id) async {
    try {
      await _ensureBoxInitialized();
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
      debugPrint('Error deleting dream: $e');
    }
  }

  // Get deleted dreams
  List<DreamEntry> getDeletedDreams() {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          return [];
        }
      }

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
      await _ensureBoxInitialized();
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
      debugPrint('Error restoring dream: $e');
    }
  }

  // Permanently delete old dreams (older than 30 days)
  Future<void> permanentlyDeleteOldDreams() async {
    try {
      await _ensureBoxInitialized();
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
      debugPrint('Error permanently deleting old dreams: $e');
    }
  }

  // Permanently delete a specific dream
  Future<void> permanentlyDeleteDream(String id) async {
    try {
      await _ensureBoxInitialized();
      if (_dreamsBox != null && _dreamsBox!.isOpen) {
        await _dreamsBox!.delete(id);
      }
    } catch (e) {
      debugPrint('Error permanently deleting dream: $e');
    }
  }

  DreamEntry? getDream(String id) {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          return null;
        }
      }

      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        return null;
      }

      return _dreamsBox!.get(id);
    } catch (e) {
      debugPrint('Error getting dream: $e');
      return null;
    }
  }

  List<DreamEntry> getByDate(DateTime date) {
    try {
      if (_dreamsBox == null || !_dreamsBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.dreams)) {
          _dreamsBox = Hive.box<DreamEntry>(HiveBoxes.dreams);
        } else {
          return [];
        }
      }

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
      // Validate the streak (check if it should be reset based on time since last dream)
      // This will reset streak to 0 if more than 24 hours have passed
      _streakService.validateStreak();
      
      // Return the persisted streak count
      return _streakService.getCurrentStreak();
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