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
import '../widgets/calendar_month.dart';

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
  bool _showCalendarExpanded = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedFolderId; // Track selected folder


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
                final streak = repo?.computeStreak() ?? 0;
                final markedDates = dreams
                    .map((dream) => DateTime(dream.date.year, dream.date.month, dream.date.day))
                    .toSet();

                if (_showDreamList) {
                  return _buildDreamListView(dreams);
                }

                return ListView(
                  padding: AppTheme.responsivePadding(context),
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
                      padding: AppTheme.responsiveHorizontalPadding(context),
                      child: Text(
                        'Today',
                        style: AppTheme.largeTitle(context),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    // Insights Card with integrated Calendar
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: _buildInsightsCard(entriesThisYear, daysJournaled, totalWords, streak, markedDates),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // Places Card with interactive map
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 300),
                      child: _buildPlacesCard(dreams),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // Dreams Section
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 400),
                      child: _buildDreamsSection(totalDreams, deletedCount),
                    ),
                  ],
                );
              },
              loading: () {
                // Show main menu with default values while loading
                return ListView(
                  padding: AppTheme.responsivePadding(context),
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
                      padding: AppTheme.responsiveHorizontalPadding(context),
                      child: Text(
                        'Today',
                        style: AppTheme.largeTitle(context),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    // Insights Card with default values
                    _buildInsightsCard(0, 0, 0, 0, {}),
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
          size: AppTheme.responsiveIconSize(context, 20),
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }


  // Insights Card - Large horizontal card with integrated expandable Calendar
  Widget _buildInsightsCard(int entriesThisYear, int daysJournaled, int totalWords, int streak, Set<DateTime> markedDates) {
    return GlassSurface(
      borderRadius: AppTheme.radiusL,
      elevated: true,
      padding: EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row with Calendar Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Insights',
                style: AppTheme.title3(context),
              ),
              // Calendar Toggle Button - Always clickable
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCalendarExpanded = !_showCalendarExpanded;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPrimary.withOpacity(0.2),
                        AppTheme.accentSecondary.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppTheme.accentPrimary,
                      ),
                      SizedBox(width: AppTheme.spacingXS),
                      Text(
                        streak > 0 ? '$streak day${streak != 1 ? 's' : ''}' : 'Calendar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingXS),
                      Icon(
                        _showCalendarExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: AppTheme.responsiveIconSize(context, 16),
                        color: AppTheme.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingM),
          // Stats Row
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
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 0.9,
                        letterSpacing: -1.2,
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
              // Right side - Three stats including streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      icon: Icons.local_fire_department_rounded,
                      value: '$streak',
                      label: streak == 1 ? 'Day Streak' : 'Days Streak',
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    _buildStatRow(
                      icon: Icons.calendar_today_rounded,
                      value: '$daysJournaled',
                      label: 'Days Journaled',
                    ),
                    SizedBox(height: AppTheme.spacingM),
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
          // Expandable Calendar
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: _showCalendarExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: AppTheme.spacingM),
                        Divider(
                          color: AppTheme.glassBorder.withOpacity(0.3),
                          height: 1,
                        ),
                        SizedBox(height: AppTheme.spacingM),
                        CalendarMonth(
                          selectedDay: _selectedDay,
                          focusedDay: _focusedDay,
                          markedDates: markedDates,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
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
          size: 16,
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
                  fontSize: 16,
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
    LatLng centerPoint;
    double initialZoom = 2.0; // Start zoomed out (world view)
    
    if (dreamsWithLocations.isNotEmpty) {
      double avgLat = dreamsWithLocations
          .map((d) => d.latitude!)
          .reduce((a, b) => a + b) / dreamsWithLocations.length;
      double avgLng = dreamsWithLocations
          .map((d) => d.longitude!)
          .reduce((a, b) => a + b) / dreamsWithLocations.length;
      centerPoint = LatLng(avgLat, avgLng);
      // Zoom out more if there are multiple locations
      initialZoom = dreamsWithLocations.length > 1 ? 3.0 : 5.0;
    } else {
      // Default to world center, zoomed out
      centerPoint = const LatLng(20.0, 0.0); // World center
      initialZoom = 2.0;
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
              Text(
                'Places',
                style: AppTheme.title3(context),
              ),
              const SizedBox(height: 12),
              // Interactive map
              SizedBox(
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder, width: 1),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: centerPoint,
                        initialZoom: initialZoom,
                        minZoom: 2.0,
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
                          minZoom: 2,
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
              ),
              if (dreamsWithLocations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No locations yet. Add a location when creating a dream.',
                    style: AppTheme.footnote(context).copyWith(
                      color: AppTheme.textMuted.withOpacity(0.6),
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
    final foldersAsync = ref.watch(foldersStreamProvider);
    
    return foldersAsync.when(
      data: (allFolders) {
        // Always ensure Dreams folder exists and is first
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
        
        // Ensure Dreams folder is always first
        final folders = [
          dreamsFolder,
          ...allFolders.where((f) => f.id != 'Dreams'),
        ];
        
        final dreamsAsync = ref.watch(dreamsStreamProvider);
        
        return dreamsAsync.when(
          data: (dreams) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title only
                Text(
                  'Dreams',
                  style: AppTheme.headline(context),
                ),
                SizedBox(height: AppTheme.spacingS),
                // Display all folders (Dreams folder first, always visible)
                ...folders.map((folder) {
                  final folderDreams = dreams.where((dream) => dream.folderId == folder.id).toList();
                  final folderCount = folderDreams.length;
                  
                  // Get icon from folder.icon string
                  IconData folderIcon = Icons.folder_rounded;
                  try {
                    // Try to parse icon name to IconData
                    final iconName = folder.icon ?? 'folder_rounded';
                    // Map common icon names to IconData
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
                  Color folderColor = const Color(0xFF9B59B6); // Default purple
                  try {
                    if (folder.color != null && folder.color!.isNotEmpty) {
                      folderColor = Color(int.parse(folder.color!.replaceFirst('#', '0xFF')));
                    }
                  } catch (e) {
                    folderColor = const Color(0xFF9B59B6);
                  }
                  
                  // For Dreams folder, don't wrap in Dismissible to avoid tap interference
                  if (folder.id == 'Dreams') {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: _buildDreamFolderItem(
                        icon: folderIcon,
                        title: folder.name,
                        count: folderCount,
                        color: folderColor,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          // Open folder - show dreams in this folder
                          setState(() {
                            _selectedFolderId = folder.id;
                            _showDreamList = true;
                          });
                        },
                        onCreateTap: () {
                          // Not used
                        },
                      ),
                    );
                  }
                  
                  // For other folders, allow swipe to delete
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Dismissible(
                      key: Key('folder_${folder.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.only(bottom: AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.disturbingRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                            color: AppTheme.disturbingRed.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: AppTheme.spacingM),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.disturbingRed,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingS),
                            Text(
                              'Delete',
                              style: AppTheme.callout(context).copyWith(
                                color: AppTheme.disturbingRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (direction) async {
                        HapticFeedback.mediumImpact();
                        try {
                          // Get folder repository
                          final folderRepo = await ref.read(folderRepositoryProvider.future);
                          await folderRepo.deleteFolder(folder.id);
                          // Invalidate to refresh the list
                          ref.invalidate(foldersStreamProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${folder.name} deleted'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.accentPrimary.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting folder: $e'),
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
                      child: _buildDreamFolderItem(
                        icon: folderIcon,
                        title: folder.name,
                        count: folderCount,
                        color: folderColor,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          // Open folder - show dreams in this folder
                          setState(() {
                            _selectedFolderId = folder.id;
                            _showDreamList = true;
                          });
                        },
                        onCreateTap: () {
                          // Not used
                        },
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: AppTheme.spacingS),
                // Create Folder button - Liquid glass style
                ScaleAnimation(
                  onTap: () {
                    AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                    _showCreateFolderDialog(context, ref);
                  },
                  child: GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                      _showCreateFolderDialog(context, ref);
                    },
                    padding: EdgeInsets.all(AppTheme.spacingS),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.glassOverlay.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: AppTheme.glassBorder.withOpacity(0.3),
                              width: 1,
                            ),
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
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted.withOpacity(0.5),
                          size: 18,
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
          },
          loading: () {
            // Show default Dreams section while loading
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dreams',
                  style: AppTheme.headline(context),
                ),
                SizedBox(height: AppTheme.spacingS),
                // Dreams folder (default)
                _buildDreamFolderItem(
                  icon: Icons.nightlight_round,
                  title: 'Dreams',
                  count: 0,
                  color: const Color(0xFF9B59B6),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFolderId = 'Dreams';
                      _showDreamList = true;
                    });
                  },
                  onCreateTap: () {},
                ),
                SizedBox(height: AppTheme.spacingS),
                // Create Folder button
                ScaleAnimation(
                  onTap: () {
                    AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                    _showCreateFolderDialog(context, ref);
                  },
                  child: GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                      _showCreateFolderDialog(context, ref);
                    },
                    padding: EdgeInsets.all(AppTheme.spacingS),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.glassOverlay.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: AppTheme.glassBorder.withOpacity(0.3),
                              width: 1,
                            ),
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
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted.withOpacity(0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          error: (_, __) {
            // Show default Dreams section on error
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dreams',
                  style: AppTheme.headline(context),
                ),
                SizedBox(height: AppTheme.spacingS),
                // Dreams folder (default)
                _buildDreamFolderItem(
                  icon: Icons.nightlight_round,
                  title: 'Dreams',
                  count: 0,
                  color: const Color(0xFF9B59B6),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFolderId = 'Dreams';
                      _showDreamList = true;
                    });
                  },
                  onCreateTap: () {},
                ),
                SizedBox(height: AppTheme.spacingS),
                // Create Folder button
                ScaleAnimation(
                  onTap: () {
                    AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                    _showCreateFolderDialog(context, ref);
                  },
                  child: GlassSurface(
                    borderRadius: AppTheme.radiusM,
                    onTap: () {
                      AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                      _showCreateFolderDialog(context, ref);
                    },
                    padding: EdgeInsets.all(AppTheme.spacingS),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.glassOverlay.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: AppTheme.glassBorder.withOpacity(0.3),
                              width: 1,
                            ),
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
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted.withOpacity(0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () {
        // Show default Dreams section while folders are loading
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dreams',
              style: AppTheme.headline(context),
            ),
            SizedBox(height: AppTheme.spacingS),
            // Dreams folder (default)
            _buildDreamFolderItem(
              icon: Icons.nightlight_round,
              title: 'Dreams',
              count: 0,
              color: const Color(0xFF9B59B6),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFolderId = 'Dreams';
                  _showDreamList = true;
                });
              },
              onCreateTap: () {},
            ),
            SizedBox(height: AppTheme.spacingS),
            // Create Folder button
            ScaleAnimation(
              onTap: () {
                AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                _showCreateFolderDialog(context, ref);
              },
              child: GlassSurface(
                borderRadius: AppTheme.radiusM,
                onTap: () {
                  AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                  _showCreateFolderDialog(context, ref);
                },
                padding: EdgeInsets.all(AppTheme.spacingS),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.glassOverlay.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color: AppTheme.glassBorder.withOpacity(0.3),
                          width: 1,
                        ),
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
                      Icons.chevron_right_rounded,
                      color: AppTheme.textMuted.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      error: (_, __) {
        // Show default Dreams section on error
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dreams',
              style: AppTheme.headline(context),
            ),
            SizedBox(height: AppTheme.spacingS),
            // Dreams folder (default)
            _buildDreamFolderItem(
              icon: Icons.nightlight_round,
              title: 'Dreams',
              count: 0,
              color: const Color(0xFF9B59B6),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFolderId = 'Dreams';
                  _showDreamList = true;
                });
              },
              onCreateTap: () {},
            ),
            SizedBox(height: AppTheme.spacingS),
            // Create Folder button
            ScaleAnimation(
              onTap: () {
                AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                _showCreateFolderDialog(context, ref);
              },
              child: GlassSurface(
                borderRadius: AppTheme.radiusM,
                onTap: () {
                  AppTheme.hapticFeedback(HapticFeedbackType.selectionClick);
                  _showCreateFolderDialog(context, ref);
                },
                padding: EdgeInsets.all(AppTheme.spacingS),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.glassOverlay.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color: AppTheme.glassBorder.withOpacity(0.3),
                          width: 1,
                        ),
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
                      Icons.chevron_right_rounded,
                      color: AppTheme.textMuted.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDreamFolderItem({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    required VoidCallback onCreateTap,
    Color? color,
  }) {
    final folderColor = color ?? AppTheme.accentSecondary;
    return GlassSurface(
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
                    folderColor.withOpacity(0.3),
                    folderColor.withOpacity(0.2),
                    folderColor.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: folderColor.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: folderColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: folderColor,
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
    // Filter dreams by selected folder
    final filteredDreams = _selectedFolderId != null
        ? dreams.where((dream) => dream.folderId == _selectedFolderId).toList()
        : dreams;
    
    // Get folder name if folder is selected
    final foldersAsync = ref.watch(foldersStreamProvider);
    
    return foldersAsync.when(
      data: (allFolders) {
        String folderName = 'Dreams';
        if (_selectedFolderId != null) {
          final folder = allFolders.firstWhere(
            (f) => f.id == _selectedFolderId,
            orElse: () => Folder(
              id: 'Dreams',
              name: 'Dreams',
              createdAt: DateTime.now(),
              color: '#9B59B6',
              icon: 'nightlight_round',
            ),
          );
          folderName = folder.name;
        }
        
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            // Swipe from left edge to go back
            if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
              HapticFeedback.mediumImpact();
              setState(() {
                _showDreamList = false;
                _selectedFolderId = null;
              });
            }
          },
          child: Scaffold(
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
                            setState(() {
                              _showDreamList = false;
                              _selectedFolderId = null;
                            });
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
                          folderName,
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
              child: filteredDreams.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      itemCount: filteredDreams.length,
                      itemBuilder: (context, index) => FadeSlideTransition(
                        delay: Duration(milliseconds: 100 + (index * 50)),
                        child: _buildDreamCard(filteredDreams[index], index, context),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: GlassSurface(
        borderRadius: AppTheme.radiusPill,
        elevated: true,
        onTap: () {
          AppTheme.hapticFeedback(HapticFeedbackType.mediumImpact);
          context.push('/add');
        },
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Icon(
          Icons.add_rounded,
          color: AppTheme.textPrimary,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      );
        },
        loading: () => Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentPrimary,
            ),
          ),
        ),
        error: (_, __) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Error loading folder',
              style: AppTheme.subheadline(context),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDreamCard(DreamEntry dream, int index, BuildContext context) {
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
                        AppTheme.getMoodColor(dream.mood).withOpacity(0.18),
                        AppTheme.getMoodColor(dream.mood).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.getMoodColor(dream.mood).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getMoodColor(dream.mood).withOpacity(0.15),
                        blurRadius: 12,
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
                  context: context,
                ),
                _buildGlassChip(
                  label: dream.category,
                  color: AppTheme.accentSecondary,
                  context: context,
                ),
                ...dream.tags.take(2).map(
                      (tag) => _buildGlassChip(
                        label: tag,
                        color: AppTheme.accentPrimary,
                        context: context,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassChip({required String label, required Color color, required BuildContext context}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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

  Widget _buildEmptyState(BuildContext context) {
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

  void _showCreateFolderDialog(BuildContext dialogContext, WidgetRef stateRef) {
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
    
    showDialog(
      context: dialogContext,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogBuilderContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassContainer(borderRadius: 24),
                child: SingleChildScrollView(
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
                      // Folder Name Input
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.glassOverlay.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3), width: 1),
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
                      // Icon Selection
                      Text(
                        'Icon',
                        style: AppTheme.subheadline(dialogBuilderContext).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: availableIcons.map((icon) {
                          final isSelected = icon == selectedIcon;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedIcon = icon;
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withOpacity(0.3)
                                    : AppTheme.glassOverlay.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? selectedColor.withOpacity(0.5)
                                      : AppTheme.glassBorder.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? selectedColor : AppTheme.textPrimary,
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Color Selection
                      Text(
                        'Color',
                        style: AppTheme.subheadline(dialogBuilderContext).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: availableColors.map((color) {
                          final isSelected = color == selectedColor;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColor = color;
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? color : Colors.transparent,
                                  width: isSelected ? 3 : 0,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: color,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(dialogBuilderContext).pop();
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
                                  gradient: LinearGradient(
                                    colors: [
                                      selectedColor.withOpacity(0.25),
                                      selectedColor.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      final folderName = folderNameController.text.trim();
                                      if (folderName.isNotEmpty) {
                                        try {
                                          // Access ref from captured state - FutureProvider needs .future
                                          final folderRepo = await stateRef.read(folderRepositoryProvider.future);
                                          
                                          // Convert icon to string name
                                          String iconName = 'folder_rounded';
                                          final iconIndex = availableIcons.indexOf(selectedIcon);
                                          if (iconIndex >= 0) {
                                            iconName = availableIcons[iconIndex].toString().split('.').last;
                                          }
                                          
                                          // Convert color to hex
                                          String colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';
                                          
                                          final folder = Folder(
                                            id: const Uuid().v4(),
                                            name: folderName,
                                            createdAt: DateTime.now(),
                                            color: colorHex,
                                            icon: iconName,
                                          );
                                          await folderRepo.createFolder(folder);
                                          // Use context to check if widget is still mounted
                                          if (dialogBuilderContext.mounted) {
                                            Navigator.of(dialogBuilderContext).pop();
                                            // Refresh folder list by invalidating stream provider
                                            stateRef.invalidate(foldersStreamProvider);
                                            // Wait a bit for the provider to refresh
                                            await Future.delayed(const Duration(milliseconds: 200));
                                            // Show success message
                                            if (dialogContext.mounted) {
                                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                                SnackBar(
                                                  content: Text('Folder "$folderName" created'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: selectedColor.withOpacity(0.9),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (dialogBuilderContext.mounted) {
                                            ScaffoldMessenger.of(dialogContext).showSnackBar(
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
        ),
      ),
    );
  }
