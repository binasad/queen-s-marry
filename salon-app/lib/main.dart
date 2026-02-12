import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_package;

import 'AppScreens/OwnerScreens/OwnerTabbar.dart';
import 'AppScreens/UserScreens/userTabbar.dart';
import 'AppScreens/introSlider.dart';
import 'providers/auth_provider.dart';
import 'services/user_service.dart';
import 'services/cache_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit image cache to reduce memory (default is 1000 images, 100MB)
  PaintingBinding.instance.imageCache.maximumSize = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20; // 80 MB

  // Load environment variables
  await dotenv.load();
  Stripe.publishableKey =
      'pk_test_51SGV17AdeL5kUQJvRdfCLGn4Dr8lBebNrq7dBFIn7nU7FKVTtflPI3E5haM3nsN2abws9UGoVJ0qlbUyjwQ6rEpa00TnRdVGad';

  // Initialize Hive cache
  await CacheService.init();

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

    try {
      final profile = await UserService().getProfile();
      return profile;
    } catch (e) {
      print('Error loading profile: $e');
      // Even if profile fails, user is still logged in
      // Return a default profile so home screen shows
      return {
        'id': authProvider.user?['id'] ?? '',
        'name': authProvider.user?['name'] ?? 'User',
        'email': authProvider.user?['email'] ?? '',
        'role': authProvider.user?['role'] ?? 'user',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data;
        if (profile == null) {
          return OnboardingScreen();
        }

        final role = (profile['role'] ?? 'user').toString();
        if (role == 'admin' || role == 'owner') {
          return OwnerBottomTabBar();
        }
        return BottomTabBar();
      },
    );
  }
}
