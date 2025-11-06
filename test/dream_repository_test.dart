import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dreamlog_flutter/models/dream_entry.dart';
import 'package:dreamlog_flutter/repository/dream_repository.dart';
import 'package:dreamlog_flutter/data/hive_boxes.dart';

void main() {
  group('DreamRepository', () {
    late DreamRepository repository;

    setUpAll(() async {
      Hive.init('test_data');
      Hive.registerAdapter(DreamEntryAdapter());
    });

    setUp(() async {
      repository = DreamRepository();
      await repository.init();
      // Clear box before each test
      final box = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
      await box.clear();
    });

    tearDown(() async {
      final box = await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
      await box.clear();
    });

    test('addDream should save dream to Hive', () async {
      final dream = DreamEntry(
        id: 'test-id',
        title: 'Test Dream',
        content: 'Test content',
        date: DateTime.now(),
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: ['test'],
      );

      await repository.addDream(dream);
      final retrieved = repository.getDream('test-id');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Test Dream'));
    });

    test('updateDream should update existing dream', () async {
      final dream = DreamEntry(
        id: 'test-id',
        title: 'Original Title',
        content: 'Original content',
        date: DateTime.now(),
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      );

      await repository.addDream(dream);
      final updated = dream.copyWith(title: 'Updated Title');
      await repository.updateDream(updated);

      final retrieved = repository.getDream('test-id');
      expect(retrieved!.title, equals('Updated Title'));
    });

    test('deleteDream should remove dream from Hive', () async {
      final dream = DreamEntry(
        id: 'test-id',
        title: 'Test Dream',
        content: 'Test content',
        date: DateTime.now(),
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      );

      await repository.addDream(dream);
      await repository.deleteDream('test-id');

      final retrieved = repository.getDream('test-id');
      expect(retrieved, isNull);
    });

    test('getByDate should return dreams for specific date', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final dream1 = DreamEntry(
        id: 'today-1',
        title: 'Today Dream',
        content: 'Content',
        date: today,
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      );

      final dream2 = DreamEntry(
        id: 'yesterday-1',
        title: 'Yesterday Dream',
        content: 'Content',
        date: yesterday,
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      );

      await repository.addDream(dream1);
      await repository.addDream(dream2);

      final todayDreams = repository.getByDate(today);
      expect(todayDreams.length, equals(1));
      expect(todayDreams.first.id, equals('today-1'));
    });

    test('computeStreak should return 0 for empty repository', () {
      final streak = repository.computeStreak();
      expect(streak, equals(0));
    });

    test('computeStreak should calculate consecutive days correctly', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      await repository.addDream(DreamEntry(
        id: '1',
        title: 'Today',
        content: 'Content',
        date: today,
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      ));

      await repository.addDream(DreamEntry(
        id: '2',
        title: 'Yesterday',
        content: 'Content',
        date: yesterday,
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      ));

      await repository.addDream(DreamEntry(
        id: '3',
        title: 'Two Days Ago',
        content: 'Content',
        date: twoDaysAgo,
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      ));

      final streak = repository.computeStreak();
      expect(streak, equals(3));
    });
  });
}

