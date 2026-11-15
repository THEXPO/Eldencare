import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'models/app_notification.dart';
import 'providers/auth_provider.dart';
import 'providers/care_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/role_provider.dart';
import 'repositories/local_care_repository.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Supabase if valid environment keys are supplied
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }

  final care = CareProvider(repository: LocalCareRepository());
  await care.load();

  final notificationProvider = NotificationProvider();

  // Initialize notification service and listeners
  try {
    await NotificationService.instance.initialize(
      onForegroundMessage: (msg) {
        notificationProvider.addNotification(
          AppNotification(
            id: msg.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: msg.notification?.title ?? 'Notification',
            body: msg.notification?.body ?? '',
            notificationType: (msg.data['type'] as String?) ?? 'general',
            metadata: msg.data,
            createdAt: DateTime.now(),
          ),
        );
      },
    );
  } catch (e) {
    debugPrint('Notification service initialization note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider.value(value: care),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const EldenCareApp(),
    ),
  );
}
