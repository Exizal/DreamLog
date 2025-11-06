import 'package:hive_flutter/hive_flutter.dart';
import '../models/folder.dart';
import '../data/hive_boxes.dart';

class FolderRepository {
  Box<Folder>? _foldersBox;
  bool _isInitializing = false;

  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      // Try to get existing box first
      if (Hive.isBoxOpen(HiveBoxes.folders)) {
        _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
      } else {
        // Open the box if it's not already open
        _foldersBox = await Hive.openBox<Folder>(HiveBoxes.folders);
      }
      
      // Ensure default "Dreams" folder exists
      if (_foldersBox != null && _foldersBox!.isOpen) {
        if (!_foldersBox!.containsKey('Dreams')) {
          final dreamsFolder = Folder(
            id: 'Dreams',
            name: 'Dreams',
            createdAt: DateTime.now(),
            color: '#9B59B6', // Purple color
            icon: 'nightlight_round',
          );
          await _foldersBox!.put('Dreams', dreamsFolder);
        }
      }
    } catch (e) {
      try {
        if (Hive.isBoxOpen(HiveBoxes.folders)) {
          _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
        } else {
          _foldersBox = await Hive.openBox<Folder>(HiveBoxes.folders);
        }
      } catch (e2) {
        _foldersBox = null;
      }
    } finally {
      _isInitializing = false;
    }
  }

  List<Folder> getAll() {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        return [];
      }
      return _foldersBox!.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      return [];
    }
  }

  Folder? getFolder(String id) {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        return null;
      }
      return _foldersBox!.get(id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createFolder(Folder folder) async {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        await init();
      }
      if (_foldersBox != null && _foldersBox!.isOpen) {
        await _foldersBox!.put(folder.id, folder);
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        await init();
      }
      if (_foldersBox != null && _foldersBox!.isOpen) {
        // Don't allow deleting the default "Dreams" folder
        if (id == 'Dreams') {
          throw Exception('Cannot delete the default Dreams folder');
        }
        await _foldersBox!.delete(id);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFolder(Folder folder) async {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        await init();
      }
      if (_foldersBox != null && _foldersBox!.isOpen) {
        await _foldersBox!.put(folder.id, folder);
      }
    } catch (e) {
      // Silently handle errors
    }
  }
}

