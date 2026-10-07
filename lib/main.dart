import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'data/repositories/services/PermissionService.dart';
import 'data/repositories/services/notification.dart';
import 'features/intro/splashscreen.dart';
import 'firebase_options.dart'; // file được gen bởi flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    try {
      await PermissionService.requestAllPermissions();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService().init();
      final token = await NotificationService().getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Mobile services initialization error: $e');
    }
  }

  runApp(const MyApp());
}
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF111827),
          surface: Color(0xFFFFFFFF),
        ),
      ),
      builder: (context, appWidget) {
        final mediaQuery = MediaQuery.of(context);
        final isWideScreen = mediaQuery.size.width > 540;

        final mobileMediaQuery = isWideScreen
            ? mediaQuery.copyWith(
                size: const Size(390, 844),
                padding: const EdgeInsets.only(top: 44, bottom: 24),
                viewInsets: EdgeInsets.zero,
              )
            : mediaQuery;

        Widget content = MediaQuery(
          data: mobileMediaQuery,
          child: ScreenUtilInit(
            designSize: const Size(360, 740),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (ctx, _) => appWidget ?? const SizedBox.shrink(),
          ),
        );

        if (!isWideScreen) {
          return content;
        }

        // Trên máy tính / Web màn hình rộng: hiển thị trong khung điện thoại cố định
        return Scaffold(
          backgroundColor: const Color(0xFF18181B),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF27272A),
                  Color(0xFF09090B),
                ],
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  width: 390,
                  height: 844,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(52),
                    border: Border.all(
                      color: const Color(0xFF3F3F46),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(47),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: content,
                        ),
                        // Dynamic Island (Notch)
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 116,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Home bar
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 130,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}