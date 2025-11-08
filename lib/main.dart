import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'models/dream_entry.dart';
import 'models/folder.dart';
import 'data/hive_boxes.dart';
import 'repository/dream_repository.dart';
import 'repository/folder_repository.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_dream_screen.dart';
import 'screens/dream_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recently_deleted_screen.dart';
import 'widgets/page_transition.dart';

// Providers
final dreamRepositoryProvider = FutureProvider<DreamRepository>((ref) async {
  final repo = DreamRepository();
  await repo.init();
  return repo;
});

final folderRepositoryProvider = FutureProvider<FolderRepository>((ref) async {
  final repo = FolderRepository();
  await repo.init();
  return repo;
});

// Stream provider for folders list that auto-updates when Hive box changes
final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final repoAsync = ref.watch(folderRepositoryProvider);
  
  return repoAsync.when(
    data: (repo) {
      // Use the repository's watchAll method which properly handles streaming
      return repo.watchAll();
    },
    loading: () {
      // Return default folder while loading
      return Stream.value([
        Folder(
          id: 'Dreams',
          name: 'Dreams',
          createdAt: DateTime.now(),
          color: '#9B59B6',
          icon: 'nightlight_round',
        ),
      ]);
    },
    error: (error, stack) {
      debugPrint('Error loading folder repository: $error');
      // Return default folder on error
      return Stream.value([
        Folder(
          id: 'Dreams',
          name: 'Dreams',
          createdAt: DateTime.now(),
          color: '#9B59B6',
          icon: 'nightlight_round',
        ),
      ]);
    },
  );
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          Widget screen;
          try {
            screen = const HomeScreen();
          } catch (e) {
            screen = Scaffold(
              body: Center(
                child: Text('Error loading home: $e'),
              ),
            );
          }
          return PageTransitionBuilder.fade(context, state, screen);
        },
      ),
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) => PageTransitionBuilder.slideRight(
          context,
          state,
          const AddDreamScreen(),
        ),
      ),
      GoRoute(
        path: '/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return PageTransitionBuilder.slideRight(
            context,
            state,
            DreamDetailScreen(dreamId: id),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => PageTransitionBuilder.fade(
          context,
          state,
          const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/deleted',
        pageBuilder: (context, state) => PageTransitionBuilder.fade(
          context,
          state,
          const RecentlyDeletedScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(DreamEntryAdapter());
    Hive.registerAdapter(FolderAdapter());

    // Open boxes
    await Hive.openBox<DreamEntry>(HiveBoxes.dreams);
    await Hive.openBox(HiveBoxes.preferences);
    await Hive.openBox<Folder>(HiveBoxes.folders);

    // Initialize repositories to ensure they're ready
    try {
      final folderRepo = FolderRepository();
      await folderRepo.init();
      debugPrint('Folder repository initialized successfully');
    } catch (e) {
      debugPrint('Error initializing folder repository: $e');
    }

    try {
      final dreamRepo = DreamRepository();
      await dreamRepo.init();
      debugPrint('Dream repository initialized successfully');
    } catch (e) {
      debugPrint('Error initializing dream repository: $e');
    }

    // Initialize services
    await NotificationService.initialize();

    // Request notification permissions on first launch
    final prefsBox = Hive.box(HiveBoxes.preferences);
    final hasRequestedPermissions =
        prefsBox.get('has_requested_permissions', defaultValue: false) as bool;
    if (!hasRequestedPermissions) {
      await NotificationService.requestPermissions();
      await prefsBox.put('has_requested_permissions', true);
      // Set default notification time
      await NotificationService.scheduleDailyNotification(
          const TimeOfDay(hour: 8, minute: 0));
    } else {
      // Restore scheduled notification
      final time = await NotificationService.getNotificationTime();
      if (time != null) {
        await NotificationService.scheduleDailyNotification(time);
      }
    }
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Continue anyway - app should still work
  }

  runApp(
    const ProviderScope(
      child: DreamLogApp(),
    ),
  );
}

class DreamLogApp extends ConsumerWidget {
  const DreamLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DreamLog',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
