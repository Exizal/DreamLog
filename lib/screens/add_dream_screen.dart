import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import '../models/dream_entry.dart';
import '../main.dart';
import '../theme/app_theme.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveDream() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repoAsync = ref.read(dreamRepositoryProvider);
      final repo = await repoAsync.when(
        data: (repo) => repo,
        loading: () => null,
        error: (_, __) => null,
      );

      if (repo == null) {
        throw Exception('Repository not initialized');
      }

      final dream = DreamEntry(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: DateTime.now(),
        rating: _rating,
        mood: _mood,
        category: 'Lucid',
        tags: [],
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName,
        folderId: 'Dreams',
      );

      await repo.addDream(dream);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Error saving dream: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dream: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.disturbingRed.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Navigation Bar
                _buildTopBar(),
                // Date Display
                _buildDateDisplay(),
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
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back Button
          _buildGlassButton(
            icon: Icons.chevron_left_rounded,
            size: 22,
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
          ),
          const Spacer(),
          // Center Buttons (Aa, A, ...)
          ClipRRect(
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
                    _buildGlassIconButton(
                      child: const Text(
                        'Aa',
                        style: TextStyle(
                          color: AppTheme.starLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                    _buildGlassIconButton(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.starLight, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: AppTheme.starLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                    _buildGlassIconButton(
                      child: const Icon(Icons.more_horiz_rounded, size: 20),
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Save Button
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.cosmicBlue.withOpacity(0.7),
                      AppTheme.dreamPurple.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cosmicBlue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSaving ? null : () {
                      HapticFeedback.mediumImpact();
                      _saveDream();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.starLight),
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20, color: AppTheme.starLight),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: AppTheme.glassContainer(
            borderRadius: 22,
            backgroundColor: AppTheme.glassOverlay,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(10),
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
    final now = DateTime.now();
    final dateFormat = DateFormat('EEE, MMM d');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 13,
            color: AppTheme.moonGlow.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            dateFormat.format(now),
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.moonGlow.withOpacity(0.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing...',
                hintStyle: TextStyle(
                  color: AppTheme.moonGlow.withOpacity(0.3),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                filled: true,
                fillColor: AppTheme.glassOverlay.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.glassBorder.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.dreamPurple.withOpacity(0.4),
                    width: 1.5,
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
                  fontSize: 17,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                  filled: true,
                  fillColor: AppTheme.glassOverlay.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.glassBorder.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.dreamPurple.withOpacity(0.4),
                      width: 1.5,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.glassOverlay.withOpacity(0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.glassBorder.withOpacity(0.5), width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: AppTheme.starLight, size: 24),
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
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping sheet
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.glassOverlay.withOpacity(0.3), // Much darker, more frosted
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
                          margin: const EdgeInsets.only(top: 14),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.moonGlow.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title with Navigation Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Choose how you\'re feeling right now',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.starLight,
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
                                      color: AppTheme.glassOverlay.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.glassBorder.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          // TODO: Expand to show more options
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppTheme.starLight,
                                            size: 20,
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
                        const SizedBox(height: 40),
                        // Multi-layered Mood Indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _getMoodColor(_mood).withOpacity(0.15),
                                    _getMoodColor(_mood).withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                            // Middle ring
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _getMoodColor(_mood).withOpacity(0.4),
                                    _getMoodColor(_mood).withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getMoodColor(_mood).withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            // Inner glowing circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _getMoodColor(_mood).withOpacity(0.9),
                                    _getMoodColor(_mood).withOpacity(0.7),
                                    _getMoodColor(_mood).withOpacity(0.5),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getMoodColor(_mood).withOpacity(0.6),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                  ),
                                  BoxShadow(
                                    color: _getMoodColor(_mood).withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            // Innermost core
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getMoodColor(_mood).withOpacity(1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getMoodColor(_mood).withOpacity(0.8),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Mood Label
                        Text(
                          _getMoodLabel(_mood),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.starLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'VERY UNPLEASANT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.moonGlow.withOpacity(0.6),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'VERY PLEASANT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.moonGlow.withOpacity(0.6),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _getMoodColor(_mood),
                                  inactiveTrackColor: AppTheme.glassBorder.withOpacity(0.3),
                                  thumbColor: AppTheme.starLight,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                                  trackHeight: 3.5,
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
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
                        const SizedBox(height: 40),
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
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismiss when tapping sheet
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.glassOverlay.withOpacity(0.3), // Much darker, more frosted
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
                          margin: const EdgeInsets.only(top: 14),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.moonGlow.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title with Navigation Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Rate this dream',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.starLight,
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
                                      color: AppTheme.glassOverlay.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.glassBorder.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          // TODO: Expand to show more options
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppTheme.starLight,
                                            size: 20,
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
                        const SizedBox(height: 40),
                        // Multi-layered Rating Indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.dreamPurple.withOpacity(0.15),
                                    AppTheme.dreamPurple.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                            // Middle ring
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.dreamPurple.withOpacity(0.4),
                                    AppTheme.dreamPurple.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.dreamPurple.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            // Inner glowing circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.dreamPurple.withOpacity(0.9),
                                    AppTheme.dreamPurple.withOpacity(0.7),
                                    AppTheme.dreamPurple.withOpacity(0.5),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.dreamPurple.withOpacity(0.6),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.dreamPurple.withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$_rating',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.starLight,
                                    letterSpacing: -1.0,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            // Innermost core
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.dreamPurple.withOpacity(1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.dreamPurple.withOpacity(0.8),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.starLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '1',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.moonGlow.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    '5',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.moonGlow.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppTheme.dreamPurple,
                                  inactiveTrackColor: AppTheme.glassBorder.withOpacity(0.3),
                                  thumbColor: AppTheme.starLight,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                                  trackHeight: 3.5,
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
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
                        const SizedBox(height: 40),
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
                          margin: const EdgeInsets.only(top: 14),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.moonGlow.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Add Location',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.starLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Map
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.glassBorder.withOpacity(0.4), width: 1),
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
                                                color: AppTheme.dreamPurple.withOpacity(0.9),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.starLight,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.dreamPurple.withOpacity(0.5),
                                                    blurRadius: 12,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.nightlight_round,
                                                color: AppTheme.starLight,
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
                        const SizedBox(height: 24),
                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              // Use Current Location
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassOverlay.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppTheme.glassBorder.withOpacity(0.4), width: 1),
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
                                          borderRadius: BorderRadius.circular(16),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 14),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.my_location_rounded, size: 18, color: AppTheme.starLight),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Use Current Location',
                                                  style: TextStyle(
                                                    color: AppTheme.starLight,
                                                    fontSize: 15,
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
                                const SizedBox(width: 12),
                                // Clear Location
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassOverlay.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppTheme.glassBorder.withOpacity(0.4), width: 1),
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
                                          borderRadius: BorderRadius.circular(16),
                                          child: const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: Icon(Icons.close_rounded, size: 20, color: AppTheme.starLight),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Text(
                              _locationName!,
                              style: TextStyle(
                                color: AppTheme.moonGlow.withOpacity(0.7),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
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
