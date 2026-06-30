import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:football_booking_flutter/services/push_notification_service.dart';
import 'package:football_booking_flutter/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/field/providers/field_provider.dart';
import 'features/booking/providers/booking_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/rating/providers/rating_provider.dart';

// Global RouteObserver để lắng nghe navigation events
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// Global NavigatorKey để navigate từ notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi', null);
  await initializeDateFormatting('vi_VN', null);
  Intl.defaultLocale = 'vi';
  
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Khởi tạo Push Notification Service
  await PushNotificationService.initialize();
  
  // Set navigatorKey cho PushNotificationService để xử lý notification tap
  PushNotificationService.navigatorKey = navigatorKey;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FieldProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
      ],
      child: FootballBookingApp(),
    ),
  );
}

class FootballBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Football Booking',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: themeProvider.themeData,
      navigatorObservers: [routeObserver],
      home: SplashScreen(),
      routes: AppRouter.routes,
    );
  }
}
