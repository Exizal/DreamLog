import 'package:hive/hive.dart';

class Folder extends HiveObject {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? color; // Hex color for folder icon
  final String? icon; // Icon name

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.color,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'icon': icon,
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 1;

  @override
  Folder read(BinaryReader reader) {
    return Folder.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer.writeMap(obj.toJson());
  }
}

