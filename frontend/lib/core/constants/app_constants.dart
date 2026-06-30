class AppConstants {
  // Cấu hình URL Backend theo thiết bị và môi trường:
  // - Máy ảo Android (Android Emulator): "http://10.0.2.2:8080"
  // - Máy ảo iOS (iOS Simulator) hoặc Web: "http://localhost:8080"
  // - Thiết bị thật chạy chung mạng Wi-Fi: "http://<IP_MÁY_TÍNH>:8080" (Ví dụ: "http://192.168.1.5:8080")
  // - Môi trường Production (Cloud Server): "http://178.128.62.29:8080" hoặc tên miền của bạn
  static const String baseUrl = "http://178.128.62.29:8080";
  
  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userRoleKey = 'user_role';

  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String fieldDetail = '/fieldDetail';
  static const String bookingHistory = '/bookingHistory';
  static const String booking = '/booking';
  static const String favorites = '/favorites';
  static const String ratings = '/ratings';
  static const String addRating = '/addRating';
  static const String ownerFields = '/ownerFields';
  static const String addEditField = '/addEditField';
  static const String profile = '/profile';
  static const String fieldBookingHistory = '/fieldBookingHistory';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String map = '/map';
  static const String ownerMain = '/ownerMain';
  static const String ownerNotifications = '/ownerNotifications';
  static const String ownerSettings = '/ownerSettings';
  static const String ownerEditProfile = '/ownerEditProfile';
  static const String ownerRevenue = '/ownerRevenue';
  static const String adminDashboard = '/adminDashboard';
  static const String adminFieldForm = '/adminFieldForm';
  static const String chat = '/chat';
  static const String payment = '/payment';
  static const String maintenance = '/maintenance';
}
