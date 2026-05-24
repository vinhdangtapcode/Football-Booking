import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:football_booking_flutter/screens/admin_add_edit_field_screen.dart';
import 'package:football_booking_flutter/screens/main_tab_scaffold.dart';
import 'package:football_booking_flutter/screens/owner_edit_profile_screen.dart';
import 'package:football_booking_flutter/services/push_notification_service.dart';
import 'package:football_booking_flutter/services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/field_detail_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/add_rating_screen.dart';
import 'screens/owner_fields_screen.dart';
import 'screens/add_edit_field_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/field_booking_history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/owner_main_tab_scaffold.dart';
import 'screens/owner_notifications_screen.dart';
import 'screens/map_screen.dart';
import 'screens/location_picker_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'models/field.dart';
import 'screens/splash_screen.dart';

// Global RouteObserver để lắng nghe navigation events
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// Global NavigatorKey để navigate từ notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Khởi tạo Push Notification Service
  await PushNotificationService.initialize();
  
  // Set navigatorKey cho PushNotificationService để xử lý notification tap
  PushNotificationService.navigatorKey = navigatorKey;
  
  runApp(FootballBookingApp());
}

class FootballBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Booking',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorObservers: [routeObserver],
      home: SplashScreen(), // Sử dụng SplashScreen từ file mới
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => MainTabScaffold(),
        '/fieldDetail': (context) => FieldDetailScreen(),
        '/bookingHistory': (context) => MainTabScaffold(initialIndex: 1),
        '/booking': (context) => BookingScreen(),
        '/favorites': (context) => FavoritesScreen(),
        '/ratings': (context) => RatingScreen(),
        '/addRating': (context) => AddRatingScreen(),
        '/ownerFields': (context) => OwnerFieldsScreen(),
        '/addEditField': (context) => AddEditFieldScreen(),
        '/profile': (context) => ProfileScreen(),
        '/fieldBookingHistory': (context) => FieldBookingHistoryScreen(),
        '/notifications': (context) => MainTabScaffold(initialIndex: 2),
        '/settings': (context) => MainTabScaffold(initialIndex: 3),
        '/map': (context) => MapScreen(field: ModalRoute.of(context)!.settings.arguments as Field),
        '/ownerMain': (context) => OwnerMainTabScaffold(),
        '/ownerNotifications': (context) => OwnerMainTabScaffold(initialIndex: 1),
        '/ownerSettings': (context) => OwnerMainTabScaffold(initialIndex: 2),
        '/ownerEditProfile': (context) => OwnerEditProfileScreen(),
        '/adminDashboard': (context) => AdminDashboardScreen(),
        '/adminFieldForm': (context) => AdminAddEditFieldScreen(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}
