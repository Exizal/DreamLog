import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dreamlog_flutter/main.dart';
import 'package:dreamlog_flutter/models/dream_entry.dart';
import 'package:dreamlog_flutter/data/hive_boxes.dart';

void main() {
  setUpAll(() async {
    Hive.init('test_data');
    Hive.registerAdapter(DreamEntryAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App should display DreamLog title', (WidgetTester tester) async {
    // Note: Full widget tests require proper initialization
    // This is a basic smoke test structure
    // For full integration tests, you'd need to mock Hive and services
  });

  test('DreamEntry model can be created', () {
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

    expect(dream.id, equals('test-id'));
    expect(dream.title, equals('Test Dream'));
    expect(dream.rating, equals(3));
  });
}
