import 'package:hive/hive.dart';

class DreamEntry extends HiveObject {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final int rating; // 1-5
  final String mood; // peaceful/joyful/disturbing/anxious/surreal/custom
  final String category; // Lucid/Nightmare/Symbolic/Abstract
  final List<String> tags;
  final bool hasAIComment;
  final String? aiComment;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String folderId; // Folder ID - default is "Dreams"

  DreamEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.rating,
    required this.mood,
    required this.category,
    required this.tags,
    this.hasAIComment = false,
    this.aiComment,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isDeleted = false,
    this.deletedAt,
    this.folderId = 'Dreams', // Default folder
  });

  DreamEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    int? rating,
    String? mood,
    String? category,
    List<String>? tags,
    bool? hasAIComment,
    String? aiComment,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isDeleted,
    DateTime? deletedAt,
    String? folderId,
  }) {
    return DreamEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      rating: rating ?? this.rating,
      mood: mood ?? this.mood,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      hasAIComment: hasAIComment ?? this.hasAIComment,
      aiComment: aiComment ?? this.aiComment,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      folderId: folderId ?? this.folderId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'rating': rating,
      'mood': mood,
      'category': category,
      'tags': tags,
      'hasAIComment': hasAIComment,
      'aiComment': aiComment,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'folderId': folderId,
    };
  }

  factory DreamEntry.fromJson(Map<String, dynamic> json) {
    return DreamEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      rating: json['rating'] as int,
      mood: json['mood'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      hasAIComment: json['hasAIComment'] as bool? ?? false,
      aiComment: json['aiComment'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationName: json['locationName'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null 
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      folderId: json['folderId'] as String? ?? 'Dreams',
    );
  }
}

class DreamEntryAdapter extends TypeAdapter<DreamEntry> {
  @override
  final int typeId = 0;

  @override
  DreamEntry read(BinaryReader reader) {
    return DreamEntry.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, DreamEntry obj) {
    writer.writeMap(obj.toJson());
  }
}
