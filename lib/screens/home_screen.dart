import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui';
import '../models/dream_entry.dart';
import '../models/folder.dart';
import '../main.dart';
import '../widgets/rating_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_components.dart';
import '../widgets/animations.dart';

final dreamsStreamProvider = StreamProvider<List<DreamEntry>>((ref) {
  final repoAsync = ref.watch(dreamRepositoryProvider);
  return repoAsync.when(
    data: (repo) => repo.watchAll(),
    loading: () => Stream.value(<DreamEntry>[]),
    error: (_, __) => Stream.value(<DreamEntry>[]),
  );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showDreamList = false;


  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dreamsAsync = ref.watch(dreamsStreamProvider);
    final repoAsync = ref.watch(dreamRepositoryProvider);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: dreamsAsync.when(
              data: (dreams) {
                // Show main menu immediately, even if repo is still loading
                final repo = repoAsync.valueOrNull;
                final entriesThisYear = repo?.getEntriesThisYear() ?? 0;
                final daysJournaled = repo?.getDaysJournaled() ?? 0;
                final totalWords = repo?.getTotalWords() ?? 0;
                final totalDreams = dreams.length;
                final deletedDreams = repo?.getDeletedDreams() ?? [];
                final deletedCount = deletedDreams.length;

                if (_showDreamList) {
                  return _buildDreamListView(dreams);
                }

                return ListView(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  children: [
                    // Top right menu button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMenuButton(),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // Large Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                      child: Text(
                        'Today',
                        style: AppTheme.largeTitle(context),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    // Insights Card
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 100),
                      child: _buildInsightsCard(entriesThisYear, daysJournaled, totalWords),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // Places Card with interactive map
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: _buildPlacesCard(dreams),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // Dreams Section
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 300),
                      child: _buildDreamsSection(totalDreams, deletedCount),
                    ),
                  ],
                );
              },
              loading: () {
                // Show main menu with default values while loading
                return ListView(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  children: [
                    // Top right menu button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMenuButton(),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // Large Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                      child: Text(
                        'Today',
                        style: AppTheme.largeTitle(context),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    // Insights Card with default values
                    _buildInsightsCard(0, 0, 0),
                    SizedBox(height: AppTheme.spacingM),
                    // Places Card with interactive map
                    _buildPlacesCard([]),
                    SizedBox(height: AppTheme.spacingM),
                    // Dreams Section with default values
                    _buildDreamsSection(0, 0),
                  ],
                );
              },
              error: (error, stack) => _buildErrorState('$error'),
            ),
          ),
        ),
      ),
    );
  }

  // Top right menu button (three dots)
  Widget _buildMenuButton() {
    return ScaleAnimation(
      onTap: () {
        AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
        context.push('/settings');
      },
      child: GlassSurface(
        borderRadius: AppTheme.radiusM,
        padding: EdgeInsets.all(AppTheme.spacingS),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // Insights Card - Large horizontal card with gradient
  Widget _buildInsightsCard(int entriesThisYear, int daysJournaled, int totalWords) {
    return GlassSurface(
      borderRadius: AppTheme.radiusL,
      elevated: true,
      padding: EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Insights',
            style: AppTheme.title3(context),
          ),
          SizedBox(height: AppTheme.spacingM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Large number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$entriesThisYear',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 0.9,
                            letterSpacing: -1.5,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'Entries This Year',
                          style: AppTheme.subheadline(context),
                        ),
                      ],
                    ),
                  ),
                  // Right side - Two stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          icon: Icons.calendar_today_rounded,
                          value: '$daysJournaled',
                          label: 'Days Journaled',
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          value: _formatNumber(totalWords),
                          label: 'Words All Time',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: AppTheme.spacingXS),
              Text(
                label,
                style: AppTheme.caption(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    // Format with dot separator (e.g., 1.791)
    if (number >= 1000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      if (remainder == 0) {
        return '$thousands.000';
      }
      return '$thousands.${remainder.toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  // Places Card with interactive map
  Widget _buildPlacesCard(List<DreamEntry> dreams) {
    // Get dreams with locations
    final dreamsWithLocations = dreams.where((dream) => 
        dream.latitude != null && dream.longitude != null).toList();
    
    // Calculate center point if there are locations
    LatLng? centerPoint;
    if (dreamsWithLocations.isNotEmpty) {
      double avgLat = dreamsWithLocations
          .map((d) => d.latitude!)
          .reduce((a, b) => a + b) / dreamsWithLocations.length;
      double avgLng = dreamsWithLocations
          .map((d) => d.longitude!)
          .reduce((a, b) => a + b) / dreamsWithLocations.length;
      centerPoint = LatLng(avgLat, avgLng);
    } else {
      // Default to a central location (e.g., world center or user's region)
      centerPoint = const LatLng(39.8283, -98.5795); // Center of USA
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.glassContainer(borderRadius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Places',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.starLight,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              // Interactive map
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: dreamsWithLocations.length > 1 ? 5.0 : 10.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
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
                      if (dreamsWithLocations.isNotEmpty)
                        MarkerLayer(
                          markers: dreamsWithLocations.map((dream) {
                            return Marker(
                              point: LatLng(dream.latitude!, dream.longitude!),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  context.push('/detail/${dream.id}');
                                },
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
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              if (dreamsWithLocations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No locations yet. Add a location when creating a dream.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.moonGlow.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Dreams Section
  Widget _buildDreamsSection(int totalDreams, int deletedCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title only (create button is inside Dreams folder view)
        Text(
          'Dreams',
          style: AppTheme.headline(context),
        ),
        SizedBox(height: AppTheme.spacingS),
        // Dream list item with create button inside
        _buildDreamFolderItem(
          icon: Icons.nightlight_round,
          title: 'Dream',
          count: totalDreams,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showDreamList = true);
          },
          onCreateTap: () {
            HapticFeedback.mediumImpact();
            context.push('/add');
          },
        ),
        SizedBox(height: AppTheme.spacingS),
        // Create Folder button
        ScaleAnimation(
          onTap: () {
            AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
            _showCreateFolderDialog(context);
          },
          child: GlassSurface(
            borderRadius: AppTheme.radiusM,
            onTap: () {
              AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
              _showCreateFolderDialog(context);
            },
            padding: EdgeInsets.all(AppTheme.spacingS),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentPrimary.withOpacity(0.3),
                        AppTheme.accentSecondary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.create_new_folder_rounded,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                ),
                SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Create Folder',
                    style: AppTheme.callout(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_circle_rounded,
                  color: AppTheme.accentPrimary.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Recently Deleted - only show if there are deleted dreams
        if (deletedCount > 0) ...[
          SizedBox(height: AppTheme.spacingS),
          _buildDreamListItem(
            icon: Icons.delete_outline_rounded,
            title: 'Recently Deleted',
            count: deletedCount,
            isDeleted: true,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/deleted');
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDreamFolderItem({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    required VoidCallback onCreateTap,
  }) {
    return ScaleAnimation(
      onTap: onTap,
      child: GlassSurface(
        borderRadius: AppTheme.radiusM,
        onTap: onTap,
        padding: EdgeInsets.all(AppTheme.spacingS),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              padding: EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentSecondary.withOpacity(0.3),
                    AppTheme.accentPrimary.withOpacity(0.2),
                    AppTheme.accentTertiary.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: AppTheme.accentSecondary.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentSecondary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppTheme.textPrimary,
                size: 22,
              ),
            ),
            SizedBox(width: AppTheme.spacingS),
            // Title
            Expanded(
              child: Text(
                title,
                style: AppTheme.callout(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Create button inside folder
            ScaleAnimation(
              onTap: onCreateTap,
              child: GlassSurface(
                borderRadius: AppTheme.radiusS,
                padding: EdgeInsets.all(AppTheme.spacingXS),
                child: Icon(
                  Icons.add_rounded,
                  color: AppTheme.accentSecondary,
                  size: 18,
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacingS),
            // Count and arrow
            Row(
              children: [
                Text(
                  '$count',
                  style: AppTheme.subheadline(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: AppTheme.spacingXS),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDreamListItem({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    bool isDeleted = false,
  }) {
    return ScaleAnimation(
      onTap: onTap,
      child: GlassSurface(
        borderRadius: AppTheme.radiusM,
        onTap: onTap,
        padding: EdgeInsets.all(AppTheme.spacingS),
        child: Row(
          children: [
            // Icon with gradient background (like butterfly in image) or simple for deleted
            Container(
              padding: EdgeInsets.all(AppTheme.spacingS),
              decoration: isDeleted
                  ? BoxDecoration(
                      color: AppTheme.glassOverlay,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.glassBorder,
                        width: 1,
                      ),
                    )
                  : BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.accentSecondary.withOpacity(0.3),
                          AppTheme.accentPrimary.withOpacity(0.2),
                          AppTheme.accentTertiary.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.accentSecondary.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentSecondary.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
              child: Icon(
                icon,
                color: AppTheme.textPrimary,
                size: isDeleted ? 20 : 22,
              ),
            ),
            SizedBox(width: AppTheme.spacingS),
            // Title
            Expanded(
              child: Text(
                title,
                style: AppTheme.callout(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Count and arrow
            Row(
              children: [
                Text(
                  '$count',
                  style: AppTheme.subheadline(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: AppTheme.spacingXS),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDreamListView(List<DreamEntry> dreams) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              child: Row(
                children: [
                  // Back button
                  ScaleAnimation(
                    onTap: () {
                      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                      setState(() => _showDreamList = false);
                    },
                    child: GlassSurface(
                      borderRadius: AppTheme.radiusM,
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingS),
                  // Title
                  Expanded(
                    child: Text(
                      'Dreams',
                      style: AppTheme.title(context),
                    ),
                  ),
                  // Search button
                  ScaleAnimation(
                    onTap: () {
                      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                      // TODO: Implement search
                    },
                    child: GlassSurface(
                      borderRadius: AppTheme.radiusM,
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      child: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingS),
                  // Menu button
                  ScaleAnimation(
                    onTap: () {
                      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                      context.push('/settings');
                    },
                    child: GlassSurface(
                      borderRadius: AppTheme.radiusM,
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Dream list or empty state
            Expanded(
              child: dreams.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      itemCount: dreams.length,
                      itemBuilder: (context, index) => FadeSlideTransition(
                        delay: Duration(milliseconds: 100 + (index * 50)),
                        child: _buildDreamCard(dreams[index], index),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: ScaleAnimation(
        onTap: () {
          AppTheme.hapticFeedback(HapticFeedbackType.mediumImpact);
          context.push('/add');
        },
        child: GlassSurface(
          borderRadius: AppTheme.radiusPill,
          elevated: true,
          padding: EdgeInsets.all(AppTheme.spacingM),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentPrimary.withOpacity(0.4),
                  AppTheme.accentSecondary.withOpacity(0.3),
                ],
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: AppTheme.textPrimary,
              size: 28,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDreamCard(DreamEntry dream, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingM),
      child: GlassSurface(
        borderRadius: AppTheme.radiusXL,
        elevated: true,
        onTap: () {
          AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
          context.push('/detail/${dream.id}');
        },
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.getMoodColor(dream.mood).withOpacity(0.25),
                        AppTheme.getMoodColor(dream.mood).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.getMoodColor(dream.mood).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getMoodColor(dream.mood).withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Text(
                    RatingPicker.emojis[dream.rating - 1],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dream.title,
                        style: AppTheme.title2(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppTheme.spacingXS),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                          SizedBox(width: AppTheme.spacingXS),
                          Text(
                            DateFormat('MMM d • h:mm a').format(dream.date),
                            style: AppTheme.footnote(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [
                _buildGlassChip(
                  label: dream.mood[0].toUpperCase() + dream.mood.substring(1),
                  color: AppTheme.getMoodColor(dream.mood),
                ),
                _buildGlassChip(
                  label: dream.category,
                  color: AppTheme.accentSecondary,
                ),
                ...dream.tags.take(2).map(
                      (tag) => _buildGlassChip(
                        label: tag,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassChip({required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTheme.caption(context).copyWith(
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Butterfly-like icon with gradient
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left wing (blue to purple gradient)
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 60,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.accentPrimary.withOpacity(0.8),
                            AppTheme.accentSecondary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                          topRight: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPrimary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right wing (pink to orange gradient)
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 60,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppTheme.accentTertiary.withOpacity(0.8),
                            const Color(0xFFFF6B35).withOpacity(0.7), // Orange
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                          topLeft: Radius.circular(50),
                          bottomLeft: Radius.circular(50),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentTertiary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spacingXL),
            Text(
              'No Entries',
              style: AppTheme.title2(context),
            ),
            SizedBox(height: AppTheme.spacingS),
            Text(
              'To add an entry, tap the plus button.',
              textAlign: TextAlign.center,
              style: AppTheme.callout(context).copyWith(
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.disturbingRed.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.disturbingRed.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppTheme.starLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: AppTheme.cosmicGray.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final folderNameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassContainer(borderRadius: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Folder',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.starLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.glassOverlay,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.glassBorder, width: 1),
                        ),
                        child: TextField(
                          controller: folderNameController,
                          autofocus: true,
                          style: const TextStyle(
                            color: AppTheme.starLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Folder name',
                            hintStyle: TextStyle(
                              color: AppTheme.moonGlow.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.moonGlow.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.deepViolet, AppTheme.dreamPurple],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.glassBorder, width: 1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  HapticFeedback.mediumImpact();
                                  final folderName = folderNameController.text.trim();
                                  if (folderName.isNotEmpty) {
                                    try {
                                      final folderRepoAsync = ref.read(folderRepositoryProvider);
                                      final folderRepo = await folderRepoAsync.when(
                                        data: (repo) => repo,
                                        loading: () => null,
                                        error: (_, __) => null,
                                      );
                                      
                                      if (folderRepo != null) {
                                        final folder = Folder(
                                          id: const Uuid().v4(),
                                          name: folderName,
                                          createdAt: DateTime.now(),
                                          color: '#9B59B6', // Default purple
                                          icon: 'folder_rounded',
                                        );
                                        await folderRepo.createFolder(folder);
                                        if (mounted) {
                                          Navigator.of(context).pop();
                                          // Show success message
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Folder "$folderName" created'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: AppTheme.dreamPurple.withOpacity(0.9),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Text(
                                    'Create',
                                    style: TextStyle(
                                      color: AppTheme.starLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
    );
  }
}
