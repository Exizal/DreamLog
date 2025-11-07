import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/dream_entry.dart';
import '../main.dart';
import '../repository/dream_repository.dart';
import '../theme/app_theme.dart';

class RecentlyDeletedScreen extends ConsumerStatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  ConsumerState<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends ConsumerState<RecentlyDeletedScreen> {
  bool _isSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Clean up old deleted dreams when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repoAsync = ref.read(dreamRepositoryProvider);
      repoAsync.whenData((repo) async {
        await repo.permanentlyDeleteOldDreams();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(dreamRepositoryProvider);

    return AppTheme.dreamBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: repoAsync.when(
            data: (repo) {
              final deletedDreams = repo.getDeletedDreams();
              
              // Calculate days remaining for the oldest deleted dream
              int daysRemaining = 30;
              if (deletedDreams.isNotEmpty) {
                final oldestDeleted = deletedDreams.last;
                if (oldestDeleted.deletedAt != null) {
                  final daysSinceDeleted = DateTime.now()
                      .difference(oldestDeleted.deletedAt!)
                      .inDays;
                  daysRemaining = 30 - daysSinceDeleted;
                  if (daysRemaining < 0) daysRemaining = 0;
                }
              }

              return Column(
                children: [
                  // Top navigation bar
                  _buildTopBar(daysRemaining),
                  
                  // Informational text
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.responsiveHorizontalPadding(context).horizontal,
                      vertical: AppTheme.spacingM,
                    ),
                    child: Text(
                      'Entries are available here for 30 days. After that time, entries will be permanently deleted.',
                      style: TextStyle(
                        color: AppTheme.starLight.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  // Days remaining
                  Padding(
                    padding: AppTheme.responsiveHorizontalPadding(context),
                    child: Text(
                      '$daysRemaining Days Remaining',
                      style: const TextStyle(
                        color: AppTheme.starLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingM),
                  
                  // Deleted dreams list
                  Expanded(
                    child: deletedDreams.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: AppTheme.responsiveHorizontalPadding(context),
                            itemCount: deletedDreams.length,
                            itemBuilder: (context, index) {
                              final dream = deletedDreams[index];
                              return _buildDeletedDreamCard(dream, repo);
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.dreamPurple),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(int daysRemaining) {
    return Padding(
      padding: AppTheme.responsivePadding(context),
      child: Row(
        children: [
          // Back button
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassOverlay,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.pop();
                  },
                  color: AppTheme.starLight,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Expanded(
            child: Text(
              'Recently Deleted',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.starLight,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // Select button
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassOverlay,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isSelectMode = !_isSelectMode;
                        if (!_isSelectMode) {
                          _selectedIds.clear();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS + 4,
                      ),
                      child: Text(
                        _isSelectMode ? 'Cancel' : 'Select',
                        style: const TextStyle(
                          color: AppTheme.starLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Search button
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassOverlay,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded, size: 22),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    // TODO: Implement search
                  },
                  color: AppTheme.starLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedDreamCard(DreamEntry dream, DreamRepository repo) {
    final isSelected = _selectedIds.contains(dream.id);
    final daysSinceDeleted = dream.deletedAt != null
        ? DateTime.now().difference(dream.deletedAt!).inDays
        : 0;
    final daysRemaining = 30 - daysSinceDeleted;

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.nebulaPurple.withOpacity(0.2),
                  AppTheme.nebulaPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.dreamPurple.withOpacity(0.3)
                    : AppTheme.glassBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isSelectMode) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_selectedIds.contains(dream.id)) {
                        _selectedIds.remove(dream.id);
                      } else {
                        _selectedIds.add(dream.id);
                      }
                    });
                  } else {
                    // Show options menu
                    _showOptionsMenu(dream, repo, daysRemaining);
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isSelectMode = true;
                    _selectedIds.add(dream.id);
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: AppTheme.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isSelectMode)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.dreamPurple.withOpacity(0.6)
                      : AppTheme.glassBorder,
                  width: 1.5,
                ),
                color: isSelected
                    ? AppTheme.dreamPurple.withOpacity(0.4)
                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: AppTheme.starLight,
                                    )
                                  : null,
                            ),
                          if (_isSelectMode) const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dream.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.starLight,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dream.content.isNotEmpty
                                      ? dream.content
                                      : 'No content',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.moonGlow.withOpacity(0.7),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!_isSelectMode)
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _showOptionsMenu(dream, repo, daysRemaining);
                              },
                              color: AppTheme.moonGlow.withOpacity(0.6),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: AppTheme.glassBorder.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(dream.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.moonGlow.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (daysRemaining > 0)
                            Text(
                              '$daysRemaining days left',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.moonGlow.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
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

  void _showOptionsMenu(DreamEntry dream, DreamRepository repo, int daysRemaining) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: AppTheme.responsivePadding(context),
            decoration: AppTheme.glassContainer(borderRadius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.restore_rounded, color: AppTheme.dreamPurple),
                  title: const Text('Restore', style: TextStyle(color: AppTheme.starLight)),
                  onTap: () async {
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                    await repo.restoreDream(dream.id);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.disturbingRed),
                  title: const Text('Permanently Delete', style: TextStyle(color: AppTheme.disturbingRed)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => _buildDeleteDialog(),
                    );
                    if (confirmed == true && mounted) {
                      HapticFeedback.mediumImpact();
                      await repo.permanentlyDeleteDream(dream.id);
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: AppTheme.responsivePadding(context),
            decoration: AppTheme.glassContainer(borderRadius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Permanently Delete?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.starLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: AppTheme.moonGlow.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
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
                              colors: [AppTheme.disturbingRed, AppTheme.disturbingRed],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.glassBorder, width: 1),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, true),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.responsiveHorizontalPadding(context).horizontal,
                                  vertical: AppTheme.spacingS + 4,
                                ),
                                child: Text(
                                  'Delete',
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cosmicGray.withOpacity(0.2),
                    AppTheme.cosmicGray.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 100,
                color: AppTheme.moonGlow,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No deleted entries',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.starLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Deleted entries will appear here\nfor 30 days',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.moonGlow.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

