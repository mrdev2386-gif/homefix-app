/// Centralized configuration constants
/// Single source of truth for all hardcoded values
class FirebaseConfig {
  // Firebase Cloud Functions region
  static const String functionsRegion = 'asia-south1';

  // Firestore collection names
  static const String customersCollection = 'customers';
  static const String techniciansCollection = 'technicians';
  static const String bookingsCollection = 'bookings';
  static const String servicesCollection = 'technician_services';
  static const String categoriesCollection = 'categories';
  static const String couponsCollection = 'coupons';
  static const String walletsCollection = 'wallets';
  static const String walletTransactionsCollection = 'walletTransactions';
  static const String reviewsCollection = 'reviews';
  static const String bannersCollection = 'home_banners';
  static const String customRequestsCollection = 'custom_requests';

  // Subcollections
  static const String addressesSubcollection = 'addresses';
  static const String cartSubcollection = 'cart';
  static const String favoritesSubcollection = 'favorites';
  static const String paymentMethodsSubcollection = 'payment_methods';

  // Cloud Function names
  static const String createBookingRequestFunction = 'createBookingRequest';
  static const String manageAddressFunction = 'manageAddress';
  static const String updateUserProfileFunction = 'updateUserProfile';
  static const String addToCartFunction = 'addToCartCallable';
  static const String removeFromCartFunction = 'removeFromCartCallable';
  static const String updateCartQuantityFunction = 'updateCartQuantityCallable';
  static const String clearCartFunction = 'clearCartCallable';
  static const String toggleFavoriteFunction = 'toggleFavoriteCallable';
  static const String cancelBookingFunction = 'cancelBooking';
  static const String confirmPaymentFunction = 'customerConfirmPayment';

  // Pagination defaults
  static const int defaultPageSize = 15;
  static const int maxPageSize = 50;

  // Validation limits
  static const int maxAddressLength = 500;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;
  static const double maxPrice = 1000000; // ₹10 lakhs

  // Timeouts
  static const Duration functionTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(seconds: 15);

  // Cache durations
  static const Duration locationCacheDuration = Duration(minutes: 30);
  static const Duration userInteractionCacheDuration = Duration(minutes: 5);
  static const Duration idempotencyKeyDuration = Duration(minutes: 5);
}

/// Booking status constants
class BookingStatus {
  static const String pendingAdmin = 'pending_admin';
  static const String technicianPending = 'technician_pending';
  static const String awaitingPayment = 'awaiting_payment';
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> allStatuses = [
    pendingAdmin,
    technicianPending,
    awaitingPayment,
    confirmed,
    inProgress,
    completed,
    cancelled,
  ];
}

/// Payment status constants
class PaymentStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
}

/// Payment method constants
class PaymentMethod {
  static const String online = 'online';
  static const String cash = 'cash';
  static const String wallet = 'wallet';
}

/// Service status constants
class ServiceStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String disabled = 'disabled';
}
