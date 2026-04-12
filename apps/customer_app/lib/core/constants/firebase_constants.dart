/// Firebase Configuration Constants
/// Centralized configuration for Firebase services
class FirebaseConstants {
  // Firebase Region
  static const String region = 'asia-south1';
  
  // Collection Names
  static const String customersCollection = 'customers';
  static const String techniciansCollection = 'technicians';
  static const String bookingsCollection = 'bookings';
  static const String servicesCollection = 'services';
  static const String technicianServicesCollection = 'technician_services';
  static const String categoriesCollection = 'categories';
  static const String couponsCollection = 'coupons';
  static const String reviewsCollection = 'reviews';
  static const String referralsCollection = 'referrals';
  static const String supportTicketsCollection = 'support_tickets';
  static const String homeBannersCollection = 'home_banners';
  static const String serviceBottomBannersCollection = 'service_bottom_banners';
  static const String cleaningEssentialsCollection = 'cleaning_essentials';
  static const String serviceSpotlightCollection = 'service_spotlight';
  static const String customRequestsCollection = 'custom_requests';
  
  // Subcollection Names
  static const String addressesSubcollection = 'addresses';
  static const String paymentMethodsSubcollection = 'payment_methods';
  static const String walletTransactionsSubcollection = 'wallet_transactions';
  static const String cartSubcollection = 'cart';
  static const String favoritesSubcollection = 'favorites';
  static const String fcmTokensSubcollection = 'fcmTokens';
  
  // Query Limits (Performance Optimization)
  static const int defaultLimit = 15;
  static const int maxLimit = 100;
  static const int bannerLimit = 10;
  static const int categoryLimit = 50;
  static const int bookingLimit = 20;
  
  // Cache Duration
  static const Duration interactionCacheDuration = Duration(minutes: 5);
  
  // Status Values
  static const String statusApproved = 'approved';
  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
  
  // Booking Status Values
  static const String bookingStatusPendingAdmin = 'pending_admin';
  static const String bookingStatusTechnicianPending = 'technician_pending';
  static const String bookingStatusAwaitingPayment = 'awaiting_payment';
  static const String bookingStatusConfirmed = 'confirmed';
  static const String bookingStatusInProgress = 'in_progress';
  static const String bookingStatusCompleted = 'completed';
  static const String bookingStatusCancelled = 'cancelled';
}