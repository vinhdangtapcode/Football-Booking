class ApiEndpoints {
  // Authentication & Users
  static const String login = '/api/users/login';
  static const String register = '/api/users/register';
  static const String changePassword = '/api/users/change-password';
  static const String currentUser = '/api/users/me';
  static const String users = '/api/users';
  static const String fcmToken = '/api/users/fcm-token';
  
  // Public Fields
  static const String publicFields = '/danh-sach-san';
  
  // Favorites
  static const String favorites = '/yeu-thich';
  
  // Ratings
  static const String ratings = '/danh-gia-san';
  
  // Bookings
  static const String bookingConfirm = '/dat-san/xac-nhan';
  static const String bookingHistory = '/dat-san/lich-su-dat-san';
  static const String bookingBase = '/dat-san';

  // Owner specific
  static const String ownerBase = '/api/owner';
  static const String ownerFields = '/api/owner/fields';
  
  // Chat
  static const String chatConversations = '/api/chat/conversations';
  static const String chatMessages = '/api/chat/messages';
  static const String chatOwnerId = '/api/chat/owner-id';

  // Notifications
  static const String notifications = '/api/users/notifications';

  // Google OAuth
  static const String googleAuth = '/api/oauth/google';

  // Admin Dashboard API
  static const String adminDashboardStats = '/api/admin/dashboard-stats';
  static const String adminBookings = '/api/admin/bookings';
  static const String adminUsers = '/api/admin/users';
  static const String adminFields = '/api/admin/fields';
  static const String adminConfig = '/api/admin/config';
  static const String adminAuditLog = '/api/admin/audit-log';
  static const String adminOwners = '/api/admin/owners';
  static const String adminBroadcast = '/api/admin/notifications/broadcast';
  
  // Admin Stadiums & Revenue
  static const String adminStadiumsBase = '/api/stadiums';
  static const String adminRevenue = '/api/stadiums/admin/revenue';
  static const String adminOwnersRevenue = '/api/stadiums/admin/owners-revenue';
  static const String adminSettle = '/api/stadiums/admin/settle';
}
