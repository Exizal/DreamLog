import 'package:flutter_test/flutter_test.dart';
import 'package:dreamlog_flutter/models/dream_entry.dart';

void main() {
  group('DreamEntry', () {
    test('toJson and fromJson should be symmetric', () {
      final original = DreamEntry(
        id: 'test-id',
        title: 'Test Dream',
        content: 'Test content',
        date: DateTime(2024, 1, 1, 12, 0),
        rating: 4,
        mood: 'joyful',
        category: 'Lucid',
        tags: ['test', 'dream'],
        hasAIComment: true,
        aiComment: 'Test comment',
      );

      final json = original.toJson();
      final restored = DreamEntry.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.content, equals(original.content));
      expect(restored.date, equals(original.date));
      expect(restored.rating, equals(original.rating));
      expect(restored.mood, equals(original.mood));
      expect(restored.category, equals(original.category));
      expect(restored.tags, equals(original.tags));
      expect(restored.hasAIComment, equals(original.hasAIComment));
      expect(restored.aiComment, equals(original.aiComment));
    });

    test('copyWith should create new instance with updated fields', () {
      final original = DreamEntry(
        id: 'test-id',
        title: 'Original',
        content: 'Content',
        date: DateTime.now(),
        rating: 3,
        mood: 'peaceful',
        category: 'Lucid',
        tags: [],
      );

      final updated = original.copyWith(
        title: 'Updated',
        rating: 5,
      );

      expect(updated.title, equals('Updated'));
      expect(updated.rating, equals(5));
      expect(updated.id, equals(original.id));
      expect(updated.content, equals(original.content));
    });
  });
}

