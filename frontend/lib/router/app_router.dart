import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/booking.dart';
import '../models/field.dart';

// auth
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';

// field
import '../features/field/screens/home_screen.dart';
import '../features/field/screens/field_detail_screen.dart';
import '../features/field/screens/location_picker_screen.dart';
import '../features/field/screens/map_screen.dart';
import '../features/field/screens/favorites_screen.dart';
import '../features/field/screens/main_tab_scaffold.dart';

// booking
import '../features/booking/screens/booking_screen.dart';
import '../features/booking/screens/booking_history_screen.dart';
import '../features/booking/screens/payment_screen.dart';

// rating
import '../features/rating/screens/rating_screen.dart';
import '../features/rating/screens/add_rating_screen.dart';

// chat
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/conversation_list_screen.dart';
import '../features/chat/screens/user_messages_screen.dart';

// notification
import '../features/notification/screens/notifications_screen.dart';
import '../features/notification/screens/owner_notifications_screen.dart';

// profile
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';

// owner
import '../features/owner/screens/owner_main_tab_scaffold.dart';
import '../features/owner/screens/owner_fields_screen.dart';
import '../features/owner/screens/owner_revenue_screen.dart';
import '../features/owner/screens/owner_settings_screen.dart';
import '../features/owner/screens/owner_edit_profile_screen.dart';
import '../features/owner/screens/owner_messages_screen.dart';
import '../features/owner/screens/add_edit_field_screen.dart';
import '../features/owner/screens/field_booking_history_screen.dart';

// admin
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_add_edit_field_screen.dart';

// shared
import '../shared/screens/maintenance_screen.dart';


class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppConstants.login: (context) => LoginScreen(),
      AppConstants.register: (context) => RegisterScreen(),
      AppConstants.home: (context) => MainTabScaffold(),
      AppConstants.fieldDetail: (context) => FieldDetailScreen(),
      AppConstants.bookingHistory: (context) => MainTabScaffold(initialIndex: 1),
      AppConstants.booking: (context) => BookingScreen(),
      AppConstants.favorites: (context) => FavoritesScreen(),
      AppConstants.ratings: (context) => RatingScreen(),
      AppConstants.addRating: (context) => AddRatingScreen(),
      AppConstants.ownerFields: (context) => OwnerFieldsScreen(),
      AppConstants.addEditField: (context) => AddEditFieldScreen(),
      AppConstants.profile: (context) => ProfileScreen(),
      AppConstants.fieldBookingHistory: (context) => FieldBookingHistoryScreen(),
      AppConstants.notifications: (context) => MainTabScaffold(initialIndex: 3),
      AppConstants.settings: (context) => MainTabScaffold(initialIndex: 4),
      AppConstants.map: (context) => MapScreen(
            field: ModalRoute.of(context)!.settings.arguments as Field,
          ),
      AppConstants.ownerMain: (context) => OwnerMainTabScaffold(),
      AppConstants.ownerNotifications: (context) => OwnerMainTabScaffold(initialIndex: 1),
      AppConstants.ownerSettings: (context) => OwnerMainTabScaffold(initialIndex: 2),
      AppConstants.ownerEditProfile: (context) => OwnerEditProfileScreen(),
      AppConstants.ownerRevenue: (context) => OwnerRevenueScreen(),
      AppConstants.adminDashboard: (context) => AdminDashboardScreen(),
      AppConstants.adminFieldForm: (context) => AdminAddEditFieldScreen(),
      AppConstants.chat: (context) => ChatScreen(),
      AppConstants.payment: (context) => PaymentScreen(
            booking: ModalRoute.of(context)!.settings.arguments as Booking,
          ),
      AppConstants.maintenance: (context) => const MaintenanceScreen(),
    };
  }
}
