import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../main.dart';
import '../widgets/rating_picker.dart';
import '../theme/app_theme.dart';

class DreamDetailScreen extends ConsumerStatefulWidget {
  final String dreamId;

  const DreamDetailScreen({super.key, required this.dreamId});

  @override
  ConsumerState<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends ConsumerState<DreamDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(dreamRepositoryProvider);

    return repoAsync.when(
      data: (repo) {
        final dream = repo.getDream(widget.dreamId);

        if (dream == null) {
          return _buildNotFoundScreen();
        }

        return AppTheme.dreamBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              leading: _buildGlassBackButton(),
              actions: [
                _buildGlassIconButton(
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _deleteDream(repo),
                ),
              ],
            ),
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    padding: AppTheme.responsivePadding(context),
                    children: [
                      // Title & Date Glass Card
                      _buildTitleCard(dream),
                      
                      SizedBox(height: AppTheme.spacingM),
                      
                      // Dream Content Glass Panel
                      _buildContentCard(dream),
                      
                      SizedBox(height: AppTheme.spacingM),
                      
                      // Details Glass Panel
                      _buildDetailsCard(dream),
                      
                      SizedBox(height: AppTheme.spacingM),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen('$error'),
    );
  }

  /// Glass title card with gradient
  Widget _buildTitleCard(dream) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Stronger liquid glass blur
            child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.deepViolet.withOpacity(0.3),
                AppTheme.nebulaPurple.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.glassBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepViolet.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large emoji rating with glow
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.getMoodColor(dream.mood).withOpacity(0.3),
                        AppTheme.getMoodColor(dream.mood).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getMoodColor(dream.mood).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    RatingPicker.emojis[dream.rating - 1],
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                dream.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.starLight,
                  letterSpacing: -1,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppTheme.moonGlow.withOpacity(0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, MMMM d, y • h:mm a').format(dream.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.moonGlow.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Glass content card
  Widget _buildContentCard(dream) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassContainer(borderRadius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.deepViolet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: AppTheme.moonGlow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dream Story',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.starLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                dream.content,
                style: const TextStyle(
                  fontSize: 17,
                  color: AppTheme.moonGlow,
                  height: 1.7,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Glass details card with chips
  Widget _buildDetailsCard(dream) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassContainer(borderRadius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cosmicBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.moonGlow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.starLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Mood chip with glow
              _buildDetailChip(
                label: 'Mood',
                value: dream.mood[0].toUpperCase() + dream.mood.substring(1),
                color: AppTheme.getMoodColor(dream.mood),
              ),
              
              const SizedBox(height: 12),
              
              // Category chip
              _buildDetailChip(
                label: 'Category',
                value: dream.category,
                color: AppTheme.dreamPurple,
              ),
              
              const SizedBox(height: 12),
              
              // Rating
              _buildDetailRow(
                label: 'Rating',
                child: Row(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        index < dream.rating ? '⭐' : '☆',
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
              
              if (dream.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cosmicGray,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dream.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cosmicBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.cosmicBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cosmicBlue.withOpacity(0.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.cosmicGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.25),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.cosmicGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildGlassBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.glassOverlay,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                HapticFeedback.selectionClick(); // Apple-style haptic
                context.pop();
              },
              color: AppTheme.starLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.glassOverlay,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder, width: 1),
            ),
            child: IconButton(
              icon: Icon(icon),
              onPressed: () {
                HapticFeedback.mediumImpact(); // Apple-style haptic
                onPressed();
              },
              color: AppTheme.disturbingRed.withOpacity(0.5),
              iconSize: 22,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDream(repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(),
    );

    if (confirmed == true) {
      await repo.deleteDream(widget.dreamId);
      if (mounted) {
        context.pop();
      }
    }
  }

  Widget _buildDeleteDialog() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: AppTheme.nebulaPurple.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
        title: const Text(
          'Delete Dream?',
          style: TextStyle(color: AppTheme.starLight, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This dream will be permanently deleted.',
          style: TextStyle(color: AppTheme.moonGlow),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.cosmicGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.disturbingRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return AppTheme.dreamBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: _buildGlassBackButton(),
        ),
        body: const Center(
          child: Text(
            'Dream not found',
            style: TextStyle(
              color: AppTheme.cosmicGray,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return AppTheme.dreamBackground(
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.dreamPurple),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return AppTheme.dreamBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(leading: _buildGlassBackButton()),
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppTheme.disturbingRed),
          ),
        ),
      ),
    );
  }
}
