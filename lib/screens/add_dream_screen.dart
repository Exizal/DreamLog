import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import '../models/dream_entry.dart';
import '../models/folder.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../repository/dream_repository.dart';
import '../repository/folder_repository.dart';
import '../data/hive_boxes.dart';
import '../widgets/glass_components.dart';

class AddDreamScreen extends ConsumerStatefulWidget {
  const AddDreamScreen({super.key});

  @override
  ConsumerState<AddDreamScreen> createState() => _AddDreamScreenState();
}

class _AddDreamScreenState extends ConsumerState<AddDreamScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _rating = 3;
  String _mood = 'surreal';
  bool _isSaving = false;
  bool _showMoodSheet = false;
  bool _showRatingSheet = false;
  bool _showLocationSheet = false;
  double _moodValue = 0.5;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  final MapController _mapController = MapController();
  DateTime _selectedDate = DateTime.now();
  bool _isBold = false;
  bool _isItalic = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveDream() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill in both title and content'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Wait for the repository provider to be ready
      DreamRepository repo;
      try {
        repo = await ref.read(dreamRepositoryProvider.future);
      } catch (e) {
        // If provider fails, create a new instance and initialize it
        repo = DreamRepository();
        await repo.init();
        
        // Verify the box is actually open
        if (repo.getAll().isEmpty && !Hive.isBoxOpen(HiveBoxes.dreams)) {
          // Try to open the box manually
          await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
          await repo.init();
        }
      }

      final dream = DreamEntry(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _selectedDate,
        rating: _rating,
        mood: _mood,
        category: 'Lucid',
        tags: [],
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName,
        folderId: 'Dreams',
      );

      // Save dream first
      await repo.addDream(dream);

      if (mounted) {
        setState(() => _isSaving = false);
        // Show folder selection dialog
        await _showFolderSelectionDialog(dream.id, repo);
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('Error saving dream: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dream: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _getMoodFromValue(double value) {
    if (value < 0.2) return 'disturbing';
    if (value < 0.4) return 'anxious';
    if (value < 0.6) return 'surreal';
    if (value < 0.8) return 'peaceful';
    return 'joyful';
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'disturbing':
        return 'Disturbing';
      case 'anxious':
        return 'Anxious';
      case 'surreal':
        return 'Surreal';
      case 'peaceful':
        return 'Peaceful';
      case 'joyful':
        return 'Joyful';
      default:
        return 'Surreal';
    }
  }

  Color _getMoodColor(String mood) {
    return AppTheme.getMoodColor(mood);
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return AppTheme.disturbingRed;
      case 2:
        return AppTheme.anxiousOrange;
      case 3:
        return AppTheme.accentSecondary;
      case 4:
        return AppTheme.joyfulAmber;
      case 5:
        return AppTheme.accentPrimary;
      default:
        return AppTheme.accentSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Swipe right to go back (mobile-friendly)
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          HapticFeedback.mediumImpact();
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Navigation Bar with Date (Centered)
                  _buildTopBarWithDate(),
                  // Main Content Area
                  Expanded(
                    child: _buildContentArea(),
                  ),
                  // Bottom Action Bar
                  _buildBottomActionBar(),
                ],
              ),
              // Mood Bottom Sheet
              if (_showMoodSheet) _buildMoodBottomSheet(),
              // Rating Bottom Sheet
              if (_showRatingSheet) _buildRatingBottomSheet(),
              // Location Bottom Sheet
              if (_showLocationSheet) _buildLocationBottomSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarWithDate() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsiveHorizontalPadding(context).horizontal,
        vertical: AppTheme.spacingM,
      ),
      child: Column(
        children: [
          // Top Row: Back, Center Buttons, Save
          Stack(
            alignment: Alignment.center,
            children: [
              // Back and Save buttons on sides with equal width
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button - Fixed width to match save button
                  SizedBox(
                    width: AppTheme.minTouchTarget,
                    height: AppTheme.minTouchTarget,
                    child: _buildGlassButton(
                      icon: Icons.chevron_left_rounded,
                      size: AppTheme.responsiveIconSize(context, 28),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.pop();
                      },
                    ),
                  ),
                  // Save Button - Liquid Glass Style
                  GlassSurface(
                    borderRadius: AppTheme.minTouchTarget / 2,
                    onTap: _isSaving ? null : () {
                      HapticFeedback.mediumImpact();
                      _saveDream();
                    },
                    child: SizedBox(
                      width: AppTheme.minTouchTarget,
                      height: AppTheme.minTouchTarget,
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.starLight),
                                ),
                              )
                            : Icon(
                                Icons.check_rounded,
                                size: AppTheme.responsiveIconSize(context, 24),
                                color: AppTheme.starLight,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              // Center Buttons - Absolutely centered
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: AppTheme.glassContainer(
                        borderRadius: 22,
                        backgroundColor: AppTheme.glassOverlay,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Aa Button - Text Formatting
                          _buildGlassIconButton(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: AppTheme.starLight,
                                fontSize: 15,
                                fontWeight: _isBold ? FontWeight.w700 : FontWeight.w600,
                                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                                letterSpacing: -0.3,
                              ),
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showTextFormattingDialog();
                            },
                          ),
                          // Drawing Tool Button
                          _buildGlassIconButton(
                            child: Icon(
                              Icons.brush_rounded,
                              size: AppTheme.responsiveIconSize(context, 18),
                              color: AppTheme.starLight,
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showDrawingToolDialog();
                            },
                          ),
                          // Listing/Formatting Tool Button
                          _buildGlassIconButton(
                            child: Icon(
                              Icons.format_list_bulleted_rounded,
                              size: AppTheme.responsiveIconSize(context, 20),
                              color: AppTheme.starLight,
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showListingFormattingDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Date Display - Centered below buttons
          SizedBox(height: AppTheme.spacingS),
          Center(
            child: _buildDateDisplay(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 28, // Increased for mobile finger use
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: AppTheme.minTouchTarget, // Minimum touch target size
          height: AppTheme.minTouchTarget,
          decoration: AppTheme.glassContainer(
            borderRadius: 22,
            backgroundColor: AppTheme.glassOverlay,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Center(
                child: Icon(icon, size: size, color: AppTheme.starLight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDateDisplay() {
    final dateFormat = DateFormat('EEE, MMM d');
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showDatePickerDialog();
      },
      child: GlassSurface(
        borderRadius: AppTheme.radiusS,
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: AppTheme.responsiveIconSize(context, 13),
              color: AppTheme.moonGlow.withOpacity(0.7),
            ),
            SizedBox(width: AppTheme.spacingXS),
            Text(
              dateFormat.format(_selectedDate),
              style: AppTheme.subheadline(context).copyWith(
                color: AppTheme.moonGlow.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showDatePickerDialog() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentPrimary,
              onPrimary: AppTheme.textPrimary,
              surface: AppTheme.backgroundSecondary,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: AppTheme.backgroundSecondary,
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      HapticFeedback.mediumImpact();
    }
  }
  
  void _showTextFormattingDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: GlassSurface(
          borderRadius: 0,
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Text Formatting',
                style: AppTheme.title2(context),
              ),
              SizedBox(height: AppTheme.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bold Toggle
                  GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      setState(() => _isBold = !_isBold);
                      HapticFeedback.selectionClick();
                      // Apply formatting to content field
                      final currentText = _contentController.text;
                      final selection = _contentController.selection;
                      if (selection.isValid) {
                        final selectedText = currentText.substring(selection.start, selection.end);
                        final newText = _isBold ? '**$selectedText**' : selectedText.replaceAll(RegExp(r'\*\*'), '');
                        _contentController.text = currentText.replaceRange(selection.start, selection.end, newText);
                        _contentController.selection = TextSelection.collapsed(offset: selection.start + newText.length);
                      } else {
                        // Insert at cursor or append
                        final cursorPos = selection.baseOffset;
                        _contentController.text = currentText.substring(0, cursorPos) + '**' + currentText.substring(cursorPos);
                        _contentController.selection = TextSelection.collapsed(offset: cursorPos + 2);
                      }
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_bold_rounded,
                            color: _isBold ? AppTheme.accentPrimary : AppTheme.textSecondary,
                            size: 24,
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            'Bold',
                            style: AppTheme.caption(context).copyWith(
                              color: _isBold ? AppTheme.accentPrimary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Italic Toggle
                  GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      setState(() => _isItalic = !_isItalic);
                      HapticFeedback.selectionClick();
                      // Apply formatting to content field
                      final currentText = _contentController.text;
                      final selection = _contentController.selection;
                      if (selection.isValid) {
                        final selectedText = currentText.substring(selection.start, selection.end);
                        final newText = _isItalic ? '*$selectedText*' : selectedText.replaceAll(RegExp(r'\*'), '');
                        _contentController.text = currentText.replaceRange(selection.start, selection.end, newText);
                        _contentController.selection = TextSelection.collapsed(offset: selection.start + newText.length);
                      } else {
                        // Insert at cursor or append
                        final cursorPos = selection.baseOffset;
                        _contentController.text = currentText.substring(0, cursorPos) + '*' + currentText.substring(cursorPos);
                        _contentController.selection = TextSelection.collapsed(offset: cursorPos + 1);
                      }
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_italic_rounded,
                            color: _isItalic ? AppTheme.accentPrimary : AppTheme.textSecondary,
                            size: 24,
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            'Italic',
                            style: AppTheme.caption(context).copyWith(
                              color: _isItalic ? AppTheme.accentPrimary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingM),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDrawingToolDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: GlassSurface(
          borderRadius: 0,
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Drawing Tool',
                style: AppTheme.title2(context),
              ),
              SizedBox(height: AppTheme.spacingM),
              Text(
                'Drawing features coming soon!',
                style: AppTheme.body(context).copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
              GlassSurface(
                borderRadius: AppTheme.radiusM,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXL,
                    vertical: AppTheme.spacingM,
                  ),
                  child: Text(
                    'Close',
                    style: AppTheme.callout(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showListingFormattingDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: GlassSurface(
          borderRadius: 0,
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'List Formatting',
                style: AppTheme.title2(context),
              ),
              SizedBox(height: AppTheme.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bullet List
                  GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final currentText = _contentController.text;
                      final selection = _contentController.selection;
                      final cursorPos = selection.baseOffset;
                      final newLine = '\n• ';
                      _contentController.text = currentText.substring(0, cursorPos) + newLine + currentText.substring(cursorPos);
                      _contentController.selection = TextSelection.collapsed(offset: cursorPos + newLine.length);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_list_bulleted_rounded,
                            color: AppTheme.accentPrimary,
                            size: 24,
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            'Bullet',
                            style: AppTheme.caption(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Numbered List
                  GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final currentText = _contentController.text;
                      final selection = _contentController.selection;
                      final cursorPos = selection.baseOffset;
                      final newLine = '\n1. ';
                      _contentController.text = currentText.substring(0, cursorPos) + newLine + currentText.substring(cursorPos);
                      _contentController.selection = TextSelection.collapsed(offset: cursorPos + newLine.length);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_list_numbered_rounded,
                            color: AppTheme.accentPrimary,
                            size: 24,
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            'Numbered',
                            style: AppTheme.caption(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Title Field
          Text(
            'Title',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.moonGlow.withOpacity(0.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: TextField(
              controller: _titleController,
              autofocus: false,
              style: const TextStyle(
                color: AppTheme.starLight,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing...',
                hintStyle: TextStyle(
                  color: AppTheme.moonGlow.withOpacity(0.3),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppTheme.glassBorder.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppTheme.dreamPurple.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Content Field
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                controller: _contentController,
                style: const TextStyle(
                  color: AppTheme.starLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(
                    color: AppTheme.moonGlow.withOpacity(0.3),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppTheme.glassBorder.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppTheme.dreamPurple.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsiveHorizontalPadding(context).horizontal,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Orange - Mood button (sparkle icon)
          _buildActionButton(Icons.auto_awesome_rounded, () {
            HapticFeedback.selectionClick();
            setState(() {
              _showMoodSheet = true;
              _showRatingSheet = false;
            });
          }),
          // Red - Location button (send/paper airplane icon)
          _buildActionButton(Icons.send_rounded, () {
            HapticFeedback.selectionClick();
            setState(() {
              _showLocationSheet = true;
              _showMoodSheet = false;
              _showRatingSheet = false;
            });
          }),
          // Green - Rating button (tag icon)
          _buildActionButton(Icons.local_offer_rounded, () {
            HapticFeedback.selectionClick();
            setState(() {
              _showRatingSheet = true;
              _showMoodSheet = false;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GlassSurface(
      borderRadius: AppTheme.minTouchTarget / 2, // Perfect circle
      onTap: onTap,
      child: SizedBox(
        width: AppTheme.minTouchTarget, // Minimum touch target size
        height: AppTheme.minTouchTarget,
        child: Center(
          child: Icon(
            icon,
            color: AppTheme.starLight,
            size: AppTheme.responsiveIconSize(context, 28),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodBottomSheet() {
    return GestureDetector(
      onTap: () {
        setState(() => _showMoodSheet = false);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.35,
          maxChildSize: 0.75,
          snap: true,
          snapSizes: const [0.35, 0.48, 0.75],
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping sheet
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Pure transparent liquid glass
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border(
                        top: BorderSide(color: AppTheme.glassBorder.withOpacity(0.15), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, -8),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: Offset.zero,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title with Navigation Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Choose how you\'re feeling right now',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                // Navigation/Expansion Button
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassOverlay.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.glassBorder.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppTheme.textPrimary,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Multi-layered Mood Indicator - smaller, more subtle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring - very subtle
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getMoodColor(_mood).withOpacity(0.06),
                                      _getMoodColor(_mood).withOpacity(0.02),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              // Middle ring - subtle
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getMoodColor(_mood).withOpacity(0.15),
                                      _getMoodColor(_mood).withOpacity(0.08),
                                      Colors.transparent,
                                  ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getMoodColor(_mood).withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              // Inner circle - muted
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getMoodColor(_mood).withOpacity(0.4),
                                      _getMoodColor(_mood).withOpacity(0.25),
                                      _getMoodColor(_mood).withOpacity(0.15),
                                  ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getMoodColor(_mood).withOpacity(0.15),
                                      blurRadius: 12,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                              // Innermost core - very subtle
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getMoodColor(_mood).withOpacity(0.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getMoodColor(_mood).withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Mood Label
                          Text(
                            _getMoodLabel(_mood),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Slider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'VERY UNPLEASANT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted.withOpacity(0.6),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'VERY PLEASANT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted.withOpacity(0.6),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: _getMoodColor(_mood).withOpacity(0.6),
                                    inactiveTrackColor: AppTheme.glassBorder.withOpacity(0.2),
                                    thumbColor: AppTheme.textPrimary,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                                    trackHeight: 3.0,
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                                  ),
                                  child: Slider(
                                    value: _moodValue,
                                    onChanged: (value) {
                                      setState(() {
                                        _moodValue = value;
                                        _mood = _getMoodFromValue(value);
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Accept Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GlassSurface(
                              borderRadius: 18,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _showMoodSheet = false);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingBottomSheet() {
    return GestureDetector(
      onTap: () {
        setState(() => _showRatingSheet = false);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.35,
          maxChildSize: 0.75,
          snap: true,
          snapSizes: const [0.35, 0.48, 0.75],
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping sheet
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Pure transparent liquid glass
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border(
                        top: BorderSide(color: AppTheme.glassBorder.withOpacity(0.15), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, -8),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: Offset.zero,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title with Navigation Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Rate this dream',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                // Navigation/Expansion Button
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassOverlay.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.glassBorder.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppTheme.textPrimary,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Multi-layered Rating Indicator - smaller, more subtle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring - very subtle
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getRatingColor(_rating).withOpacity(0.06),
                                      _getRatingColor(_rating).withOpacity(0.02),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              // Middle ring - subtle
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getRatingColor(_rating).withOpacity(0.15),
                                      _getRatingColor(_rating).withOpacity(0.08),
                                      Colors.transparent,
                                  ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRatingColor(_rating).withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              // Inner circle - muted
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getRatingColor(_rating).withOpacity(0.4),
                                      _getRatingColor(_rating).withOpacity(0.25),
                                      _getRatingColor(_rating).withOpacity(0.15),
                                  ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRatingColor(_rating).withOpacity(0.15),
                                      blurRadius: 12,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$_rating',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -1.0,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              // Innermost core - very subtle
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRatingColor(_rating).withOpacity(0.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRatingColor(_rating).withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Rating Label
                          Text(
                            _rating == 1
                                ? 'Poor'
                                : _rating == 2
                                    ? 'Fair'
                                    : _rating == 3
                                        ? 'Good'
                                        : _rating == 4
                                            ? 'Great'
                                            : 'Excellent',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Slider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '1',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      '5',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: _getRatingColor(_rating).withOpacity(0.6),
                                    inactiveTrackColor: AppTheme.glassBorder.withOpacity(0.2),
                                    thumbColor: AppTheme.textPrimary,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                                    trackHeight: 3.0,
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                                  ),
                                  child: Slider(
                                    value: _rating.toDouble(),
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    onChanged: (value) {
                                      setState(() {
                                        _rating = value.round();
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Accept Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GlassSurface(
                              borderRadius: 18,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _showRatingSheet = false);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationBottomSheet() {
    return GestureDetector(
      onTap: () {
        setState(() => _showLocationSheet = false);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.4, 0.65, 0.9],
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping sheet
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.glassOverlay.withOpacity(0.3), // Darker, more frosted
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border(
                        top: BorderSide(color: AppTheme.glassBorder.withOpacity(0.4), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 50,
                          offset: const Offset(0, -10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Add Location',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Map - Fixed height to prevent overflow
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3), width: 1),
                                ),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _latitude != null && _longitude != null
                                        ? LatLng(_latitude!, _longitude!)
                                        : const LatLng(39.8283, -98.5795),
                                    initialZoom: _latitude != null && _longitude != null ? 12.0 : 5.0,
                                    minZoom: 3.0,
                                    maxZoom: 18.0,
                                    onTap: (tapPosition, point) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _latitude = point.latitude;
                                        _longitude = point.longitude;
                                        _locationName = '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                                      });
                                      _mapController.move(point, 12.0);
                                    },
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.all,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.dreamlog.app',
                                      tileProvider: NetworkTileProvider(),
                                      maxZoom: 18,
                                      minZoom: 3,
                                    ),
                                    if (_latitude != null && _longitude != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(_latitude!, _longitude!),
                                            width: 40,
                                            height: 40,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.dreamPurple.withOpacity(0.8),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.textPrimary,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.dreamPurple.withOpacity(0.4),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.nightlight_round,
                                                color: AppTheme.textPrimary,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Use Current Location
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassOverlay.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3), width: 1),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () async {
                                            HapticFeedback.selectionClick();
                                            try {
                                              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                              if (!serviceEnabled) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Location services are disabled'),
                                                      behavior: SnackBarBehavior.floating,
                                                      backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }

                                              LocationPermission permission = await Geolocator.checkPermission();
                                              if (permission == LocationPermission.denied) {
                                                permission = await Geolocator.requestPermission();
                                                if (permission == LocationPermission.denied) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: const Text('Location permissions are denied'),
                                                        behavior: SnackBarBehavior.floating,
                                                        backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                    );
                                                  }
                                                  return;
                                                }
                                              }

                                              if (permission == LocationPermission.deniedForever) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Location permissions are permanently denied'),
                                                      behavior: SnackBarBehavior.floating,
                                                      backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }

                                              Position position = await Geolocator.getCurrentPosition();
                                              setState(() {
                                                _latitude = position.latitude;
                                                _longitude = position.longitude;
                                                _locationName = 'Current Location';
                                              });
                                              _mapController.move(LatLng(position.latitude, position.longitude), 12.0);
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error getting location: $e'),
                                                    behavior: SnackBarBehavior.floating,
                                                    backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(18),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.my_location_rounded, size: 16, color: AppTheme.textPrimary),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Use Current Location',
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_latitude != null && _longitude != null) ...[
                                const SizedBox(width: 10),
                                // Clear Location
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassOverlay.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3), width: 1),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _latitude = null;
                                              _longitude = null;
                                              _locationName = null;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(18),
                                          child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textPrimary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_locationName != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Text(
                              _locationName!,
                              style: TextStyle(
                                color: AppTheme.textMuted.withOpacity(0.7),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Accept Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GlassSurface(
                            borderRadius: 18,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _showLocationSheet = false);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  'Accept',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Mobile-friendly folder selection dialog
  Future<void> _showFolderSelectionDialog(String dreamId, DreamRepository repo) async {
    final foldersAsync = ref.read(folderRepositoryProvider);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.5, 0.7, 0.9],
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassOverlay.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(color: AppTheme.glassBorder.withOpacity(0.4), width: 1),
                    ),
                  ),
                  child: foldersAsync.when(
                    data: (folderRepo) => _buildFolderSelectionContent(
                      context,
                      scrollController,
                      dreamId,
                      repo,
                      folderRepo,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.accentPrimary),
                    ),
                    error: (_, __) => Center(
                      child: Text(
                        'Error loading folders',
                        style: AppTheme.subheadline(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFolderSelectionContent(
    BuildContext context,
    ScrollController scrollController,
    String dreamId,
    DreamRepository repo,
    FolderRepository folderRepo,
  ) {
    final allFolders = folderRepo.getAll();
    // Ensure Dreams folder exists and is first
    final dreamsFolder = allFolders.firstWhere(
      (f) => f.id == 'Dreams',
      orElse: () => Folder(
        id: 'Dreams',
        name: 'Dreams',
        createdAt: DateTime.now(),
        color: '#9B59B6',
        icon: 'nightlight_round',
      ),
    );
    
    final folders = [
      dreamsFolder,
      ...allFolders.where((f) => f.id != 'Dreams'),
    ];

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textMuted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Select Folder',
            style: AppTheme.title(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Folder list - swipeable
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: folders.length + 1, // +1 for Create Folder option
            itemBuilder: (context, index) {
              if (index == folders.length) {
                // Create Folder option
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      // Don't close the folder selection dialog, just show create folder dialog
                      await _showCreateFolderDialog(context, ref, repo, dreamId);
                    },
                    child: GlassSurface(
                      borderRadius: AppTheme.radiusL,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.glassOverlay.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.glassBorder.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.create_new_folder_rounded,
                              color: AppTheme.textPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Folder',
                                  style: AppTheme.callout(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add a new folder to organize your dreams',
                                  style: AppTheme.footnote(context).copyWith(
                                    color: AppTheme.textMuted.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textMuted,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final folder = folders[index];
              
              // Get icon from folder.icon string
              IconData folderIcon = Icons.folder_rounded;
              try {
                final iconName = folder.icon ?? 'folder_rounded';
                switch (iconName) {
                  case 'folder_rounded':
                    folderIcon = Icons.folder_rounded;
                    break;
                  case 'folder_special_rounded':
                    folderIcon = Icons.folder_special_rounded;
                    break;
                  case 'bookmark_rounded':
                    folderIcon = Icons.bookmark_rounded;
                    break;
                  case 'star_rounded':
                    folderIcon = Icons.star_rounded;
                    break;
                  case 'favorite_rounded':
                    folderIcon = Icons.favorite_rounded;
                    break;
                  case 'work_rounded':
                    folderIcon = Icons.work_rounded;
                    break;
                  case 'home_rounded':
                    folderIcon = Icons.home_rounded;
                    break;
                  case 'school_rounded':
                    folderIcon = Icons.school_rounded;
                    break;
                  case 'flight_rounded':
                    folderIcon = Icons.flight_rounded;
                    break;
                  case 'restaurant_rounded':
                    folderIcon = Icons.restaurant_rounded;
                    break;
                  case 'music_note_rounded':
                    folderIcon = Icons.music_note_rounded;
                    break;
                  case 'movie_rounded':
                    folderIcon = Icons.movie_rounded;
                    break;
                  case 'nightlight_round':
                    folderIcon = Icons.nightlight_round;
                    break;
                  default:
                    folderIcon = Icons.folder_rounded;
                }
              } catch (e) {
                folderIcon = Icons.folder_rounded;
              }
              
              // Get color from folder.color hex string
              Color folderColor = const Color(0xFF9B59B6);
              try {
                if (folder.color != null && folder.color!.isNotEmpty) {
                  folderColor = Color(int.parse(folder.color!.replaceFirst('#', '0xFF')));
                }
              } catch (e) {
                folderColor = const Color(0xFF9B59B6);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    // Update dream with selected folder
                    final dream = repo.getDream(dreamId);
                    if (dream != null) {
                      await repo.updateDream(dream.copyWith(folderId: folder.id));
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close folder selection dialog
                        Navigator.of(context).pop(); // Close add dream screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dream saved to ${folder.name}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.accentPrimary.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Error: Dream not found'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: GlassSurface(
                    borderRadius: AppTheme.radiusL,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                folderColor.withOpacity(0.3),
                                folderColor.withOpacity(0.2),
                                folderColor.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: folderColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            folderIcon,
                            color: folderColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: AppTheme.callout(context).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Cancel button
        Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.glassOverlay.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: AppTheme.glassBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: AppTheme.callout(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Create folder dialog (mobile-friendly)
  Future<void> _showCreateFolderDialog(
    BuildContext dialogContext,
    WidgetRef stateRef,
    DreamRepository repo,
    String dreamId,
  ) async {
    final folderNameController = TextEditingController();
    final List<IconData> availableIcons = [
      Icons.folder_rounded,
      Icons.folder_special_rounded,
      Icons.bookmark_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
      Icons.work_rounded,
      Icons.home_rounded,
      Icons.school_rounded,
      Icons.flight_rounded,
      Icons.restaurant_rounded,
      Icons.music_note_rounded,
      Icons.movie_rounded,
    ];
    final List<Color> availableColors = [
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF3498DB), // Blue
      const Color(0xFF2ECC71), // Green
      const Color(0xFFE74C3C), // Red
      const Color(0xFFF39C12), // Orange
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF00BCD4), // Cyan
    ];
    
    IconData selectedIcon = availableIcons[0];
    Color selectedColor = availableColors[0];
    
    await showModalBottomSheet(
      context: dialogContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogBuilderContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.6, 0.85, 0.95],
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.glassOverlay.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(color: AppTheme.glassBorder.withOpacity(0.4), width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Text(
                          'Create Folder',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.starLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Folder Name Input
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.glassOverlay.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3), width: 1),
                              ),
                              child: TextField(
                                controller: folderNameController,
                                autofocus: true,
                                style: const TextStyle(
                                  color: AppTheme.starLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Folder name',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textMuted.withOpacity(0.5),
                                    fontSize: 18,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Icon Selection
                        Text(
                          'Icon',
                          style: AppTheme.subheadline(dialogBuilderContext).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: availableIcons.map((icon) {
                            final isSelected = icon == selectedIcon;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setDialogState(() => selectedIcon = icon);
                              },
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? selectedColor.withOpacity(0.3)
                                      : AppTheme.glassOverlay.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? selectedColor.withOpacity(0.6)
                                        : AppTheme.glassBorder.withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected ? selectedColor : AppTheme.textMuted,
                                  size: 32,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),
                        // Color Selection
                        Text(
                          'Color',
                          style: AppTheme.subheadline(dialogBuilderContext).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: availableColors.map((color) {
                            final isSelected = color == selectedColor;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? color : Colors.transparent,
                                    width: isSelected ? 3 : 0,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(dialogBuilderContext).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassOverlay.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppTheme.glassBorder.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (folderNameController.text.trim().isEmpty) {
                                    HapticFeedback.heavyImpact();
                                    return;
                                  }
                                  
                                  HapticFeedback.mediumImpact();
                                  
                                  try {
                                    final folderRepoAsync = stateRef.read(folderRepositoryProvider);
                                    final folderRepo = await folderRepoAsync.when(
                                      data: (repo) => repo,
                                      loading: () => null,
                                      error: (_, __) => null,
                                    );
                                    
                                    if (folderRepo != null) {
                                      // Get icon name string
                                      String iconName = 'folder_rounded';
                                      switch (selectedIcon) {
                                        case Icons.folder_rounded:
                                          iconName = 'folder_rounded';
                                          break;
                                        case Icons.folder_special_rounded:
                                          iconName = 'folder_special_rounded';
                                          break;
                                        case Icons.bookmark_rounded:
                                          iconName = 'bookmark_rounded';
                                          break;
                                        case Icons.star_rounded:
                                          iconName = 'star_rounded';
                                          break;
                                        case Icons.favorite_rounded:
                                          iconName = 'favorite_rounded';
                                          break;
                                        case Icons.work_rounded:
                                          iconName = 'work_rounded';
                                          break;
                                        case Icons.home_rounded:
                                          iconName = 'home_rounded';
                                          break;
                                        case Icons.school_rounded:
                                          iconName = 'school_rounded';
                                          break;
                                        case Icons.flight_rounded:
                                          iconName = 'flight_rounded';
                                          break;
                                        case Icons.restaurant_rounded:
                                          iconName = 'restaurant_rounded';
                                          break;
                                        case Icons.music_note_rounded:
                                          iconName = 'music_note_rounded';
                                          break;
                                        case Icons.movie_rounded:
                                          iconName = 'movie_rounded';
                                          break;
                                      }
                                      
                                      final newFolder = Folder(
                                        id: const Uuid().v4(),
                                        name: folderNameController.text.trim(),
                                        createdAt: DateTime.now(),
                                        color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                                        icon: iconName,
                                      );
                                      
                                      await folderRepo.createFolder(newFolder);
                                      stateRef.invalidate(folderRepositoryProvider);
                                      
                                      // Update dream with new folder
                                      final dream = repo.getDream(dreamId);
                                      if (dream != null) {
                                        await repo.updateDream(dream.copyWith(folderId: newFolder.id));
                                      }
                                      
                                      if (dialogBuilderContext.mounted) {
                                        Navigator.of(dialogBuilderContext).pop(); // Close create folder dialog
                                        Navigator.of(dialogBuilderContext).pop(); // Close folder selection dialog
                                        Navigator.of(dialogBuilderContext).pop(); // Close add dream screen
                                        ScaffoldMessenger.of(dialogBuilderContext).showSnackBar(
                                          SnackBar(
                                            content: Text('Dream saved to ${newFolder.name}'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppTheme.accentPrimary.withOpacity(0.9),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (dialogBuilderContext.mounted) {
                                      ScaffoldMessenger.of(dialogBuilderContext).showSnackBar(
                                        SnackBar(
                                          content: Text('Error creating folder: $e'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        selectedColor.withOpacity(0.6),
                                        selectedColor.withOpacity(0.4),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selectedColor.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Create',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
