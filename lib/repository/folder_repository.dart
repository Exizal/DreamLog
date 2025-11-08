import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/folder.dart';
import '../data/hive_boxes.dart';

class FolderRepository {
  Box<Folder>? _foldersBox;
  bool _isInitializing = false;

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
      // Ensure Hive is initialized
      if (!Hive.isAdapterRegistered(1)) {
        debugPrint('Folder adapter not registered, this is an error');
        _isInitializing = false;
        return;
      }

      // Try to get existing box first
      if (Hive.isBoxOpen(HiveBoxes.folders)) {
        _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
        debugPrint('Folders box already open, using existing box');
      } else {
        // Open the box if it's not already open
        debugPrint('Opening folders box...');
        _foldersBox = await Hive.openBox<Folder>(HiveBoxes.folders);
        debugPrint('Folders box opened successfully');
      }
      
      // Ensure default "Dreams" folder exists
      if (_foldersBox != null && _foldersBox!.isOpen) {
        await _ensureDreamsFolder();
      } else {
        debugPrint('Warning: Folders box is null or not open after init');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in folder repository init: $e');
      debugPrint('Stack trace: $stackTrace');
      try {
        // Retry once
        if (Hive.isBoxOpen(HiveBoxes.folders)) {
          _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
        } else {
          _foldersBox = await Hive.openBox<Folder>(HiveBoxes.folders);
        }
        if (_foldersBox != null && _foldersBox!.isOpen) {
          await _ensureDreamsFolder();
        }
      } catch (e2) {
        debugPrint('Error in folder repository init fallback: $e2');
        _foldersBox = null;
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _ensureDreamsFolder() async {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        return;
      }

      if (!_foldersBox!.containsKey('Dreams')) {
        debugPrint('Creating Dreams folder...');
        final dreamsFolder = Folder(
          id: 'Dreams',
          name: 'Dreams',
          createdAt: DateTime.now(),
          color: '#9B59B6',
          icon: 'nightlight_round',
        );
        await _foldersBox!.put('Dreams', dreamsFolder);
        debugPrint('Dreams folder created successfully');
      } else {
        debugPrint('Dreams folder already exists');
      }
    } catch (e) {
      debugPrint('Error ensuring Dreams folder: $e');
    }
  }

  // Stream of folders that updates when the box changes
  Stream<List<Folder>> watchAll() async* {
    try {
      // Ensure box is initialized
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        // Try to get the box
        if (Hive.isBoxOpen(HiveBoxes.folders)) {
          _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
        } else {
          // Return default folders if box is not available
          yield _getDefaultFolders();
          return;
        }
      }

      if (_foldersBox == null || !_foldersBox!.isOpen) {
        yield _getDefaultFolders();
        return;
      }

      // Emit initial value immediately
      yield getAll();

      // Watch the box and emit folder list on changes
      await for (final _ in _foldersBox!.watch()) {
        try {
          yield getAll();
        } catch (error) {
          debugPrint('Error in watchAll stream: $error');
          yield getAll(); // Try to return current state even on error
        }
      }
    } catch (e) {
      debugPrint('Error creating watchAll stream: $e');
      yield _getDefaultFolders();
    }
  }

  List<Folder> _getDefaultFolders() {
    return [
      Folder(
        id: 'Dreams',
        name: 'Dreams',
        createdAt: DateTime.now(),
        color: '#9B59B6',
        icon: 'nightlight_round',
      ),
    ];
  }

  List<Folder> getAll() {
    try {
      // Ensure box is initialized
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.folders)) {
          _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
        } else {
          debugPrint('Folders box is not open in getAll(), returning default');
          return _getDefaultFolders();
        }
      }

      if (_foldersBox == null || !_foldersBox!.isOpen) {
        return _getDefaultFolders();
      }

      // Get all folders from the box
      final folders = _foldersBox!.values.toList();
      debugPrint('Found ${folders.length} folders in repository');

      // Always ensure Dreams folder exists
      if (!folders.any((f) => f.id == 'Dreams')) {
        debugPrint('Dreams folder not found in getAll(), creating it...');
        final dreamsFolder = Folder(
          id: 'Dreams',
          name: 'Dreams',
          createdAt: DateTime.now(),
          color: '#9B59B6',
          icon: 'nightlight_round',
        );
        // Use putSync to ensure immediate effect
        _foldersBox!.put('Dreams', dreamsFolder);
        folders.insert(0, dreamsFolder);
        debugPrint('Dreams folder created in getAll()');
      }

      // Sort folders but keep Dreams first
      folders.sort((a, b) {
        if (a.id == 'Dreams') return -1;
        if (b.id == 'Dreams') return 1;
        return a.name.compareTo(b.name);
      });

      debugPrint('Returning ${folders.length} folders: ${folders.map((f) => f.name).join(", ")}');
      return folders;
    } catch (e, stackTrace) {
      debugPrint('Error getting folders: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return Dreams folder as fallback
      return _getDefaultFolders();
    }
  }

  Folder? get(String id) {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        if (Hive.isBoxOpen(HiveBoxes.folders)) {
          _foldersBox = Hive.box<Folder>(HiveBoxes.folders);
        } else {
          return null;
        }
      }

      if (_foldersBox == null || !_foldersBox!.isOpen) {
        return null;
      }

      return _foldersBox!.get(id);
    } catch (e) {
      debugPrint('Error getting folder $id: $e');
      return null;
    }
  }

  Future<void> createFolder(Folder folder) async {
    try {
      // Ensure repository is initialized
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        await init();
      }

      if (_foldersBox == null || !_foldersBox!.isOpen) {
        throw Exception('Folders box is not initialized. Please restart the app.');
      }

      // Don't allow creating a folder with the same ID as Dreams
      if (folder.id == 'Dreams') {
        throw Exception('Cannot create folder with reserved ID "Dreams"');
      }

      debugPrint('Creating folder: ${folder.name} with id: ${folder.id}');
      await _foldersBox!.put(folder.id, folder);
      
      // Verify the folder was saved
      final savedFolder = _foldersBox!.get(folder.id);
      if (savedFolder == null) {
        throw Exception('Folder was not saved to Hive box');
      }
      
      debugPrint('Folder created successfully: ${folder.id}');
    } catch (e, stackTrace) {
      debugPrint('Error creating folder: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        await init();
      }

      if (_foldersBox == null || !_foldersBox!.isOpen) {
        throw Exception('Folders box is not initialized');
      }

      // Don't allow deleting the default "Dreams" folder
      if (id == 'Dreams') {
        throw Exception('Cannot delete the default Dreams folder');
      }

      // Check if folder exists
      if (!_foldersBox!.containsKey(id)) {
        throw Exception('Folder not found');
      }

      await _foldersBox!.delete(id);
      debugPrint('Folder deleted: $id');
    } catch (e) {
      debugPrint('Error deleting folder: $e');
      rethrow;
    }
  }

  Future<void> updateFolder(Folder folder) async {
    try {
      if (_foldersBox == null || !_foldersBox!.isOpen) {
        await init();
      }

      if (_foldersBox == null || !_foldersBox!.isOpen) {
        throw Exception('Folders box is not initialized');
      }

      await _foldersBox!.put(folder.id, folder);
      debugPrint('Folder updated: ${folder.id}');
    } catch (e) {
      debugPrint('Error updating folder: $e');
      rethrow;
    }
  }

  // Get folder by ID (alias for get method for consistency)
  Folder? getFolder(String id) => get(id);
}