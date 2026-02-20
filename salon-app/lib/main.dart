import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_package;

import 'AppScreens/OwnerScreens/OwnerTabbar.dart';
import 'AppScreens/UserScreens/userTabbar.dart';
import 'AppScreens/introSlider.dart';
import 'providers/auth_provider.dart';
import 'services/cache_service.dart';
import 'services/image_preload_service.dart';
import 'services/push_notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in separate isolate when app is background/terminated
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification payload is shown by the system; we just ensure Firebase is init
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit image cache to reduce memory (default is 1000 images, 100MB)
  PaintingBinding.instance.imageCache.maximumSize = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20; // 80 MB

  // Load env (fast) – defer heavy init to after first frame
  await dotenv.load();

  // Register FCM background handler (handler inits Firebase when notification arrives)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Stripe key from .env
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
  }

  // Defer ALL heavy work so first frame shows immediately
  Future(() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
    await CacheService.init();
    await Future.delayed(const Duration(milliseconds: 2000));
    ImagePreloadService.preloadImagesInBackground();
  });

  runApp(
    // Wrap with ProviderScope for Riverpod
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider_package.MultiProvider(
      providers: [
        provider_package.ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/home': (ctx) => const AuthWrapper(),
          '/login': (ctx) => OnboardingScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<Map<String, dynamic>?>? _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkLoginStatus();
    if (!authProvider.isLoggedIn) return null;

    // Build profile from AuthProvider (already set from cache/guest/fetch)
    final user = authProvider.user;
    if (user == null) return null;

    // Defer push notifications to background – don't block home screen
    Future(() => PushNotificationService().initialize());

    return {'user': user};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        // Show intro immediately while auth checks – no spinner delay
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const OnboardingScreen();
        }

        final profile = snapshot.data;
        if (profile == null) {
          return OnboardingScreen();
        }

        final roleObj = profile['user']?['role'] ?? profile['role'];
        final roleName = (roleObj is Map ? roleObj['name'] : roleObj)?.toString().toLowerCase() ?? 'user';
        if (roleName == 'admin' || roleName == 'owner') {
          return OwnerBottomTabBar();
        }
        return BottomTabBar();
      },
    );
  }
}
