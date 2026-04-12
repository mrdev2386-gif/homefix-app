import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/services/user_location_service.dart';
import 'package:customer_app/core/models/booking.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/models/address.dart';
import 'firestore_service_test.mocks.dart';

@GenerateMocks([UserLocationService])
void main() {
  group('FirestoreService - Stream Cache Tests', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('getCachedServicesStream returns same instance on repeated calls', () {
      // Act
      final stream1 = firestoreService.getCachedServicesStream();
      final stream2 = firestoreService.getCachedServicesStream();

      // Assert - verify same object reference using identical()
      expect(identical(stream1, stream2), isTrue,
          reason: 'Cache should return same stream instance');
    });

    test('clearCachedServicesStream invalidates cache', () {
      // Arrange
      final stream1 = firestoreService.getCachedServicesStream();
      
      // Act
      firestoreService.clearCachedServicesStream();
      final stream2 = firestoreService.getCachedServicesStream();

      // Assert - verify different instances after clear
      expect(identical(stream1, stream2), isFalse,
          reason: 'Cache should return new stream instance after clear');
    });
  });

  group('FirestoreService - User Interaction Cache', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('getUserInteractionData returns empty sets for empty userId', () async {
      // Act
      final data = await firestoreService.getUserInteractionData('');

      // Assert
      expect(data['categories'], isA<Set>());
      expect(data['serviceIds'], isA<Set>());
      expect((data['categories'] as Set).isEmpty, isTrue);
      expect((data['serviceIds'] as Set).isEmpty, isTrue);
    });

    test('clearUserInteractionCache resets cache state', () async {
      // Arrange
      const userId = 'test-user-123';
      await firestoreService.getUserInteractionData(userId);
      
      // Act & Assert - should not throw
      expect(() => firestoreService.clearUserInteractionCache(), returnsNormally);
    });
  });

  group('FirestoreService - Stream Type Validation', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('streamBookings returns Stream<List<Booking>>', () {
      // Act
      final stream = firestoreService.streamBookings('user-123');

      // Assert
      expect(stream, isA<Stream<List<Booking>>>());
    });

    test('streamBookingDetail returns Stream<Booking>', () {
      // Act
      final stream = firestoreService.streamBookingDetail('booking-123');

      // Assert
      expect(stream, isA<Stream<Booking>>());
    });

    test('streamAddresses returns Stream<List<Address>>', () {
      // Act
      final stream = firestoreService.streamAddresses('user-123');

      // Assert
      expect(stream, isA<Stream<List<Address>>>());
    });

    test('streamTechnicianServices returns Stream<List<HomeService>>', () {
      // Act
      final stream = firestoreService.streamTechnicianServices(
        filterByLocation: false,
      );

      // Assert
      expect(stream, isA<Stream<List<HomeService>>>());
    });
  });

  group('FirestoreService - Input Validation', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('streamCart returns empty list for invalid userId', () async {
      // Act
      final stream = firestoreService.streamCart('');

      // Assert
      expect(stream, isNotNull);
      final result = await stream.first;
      expect(result, isA<List>());
      expect(result.isEmpty, isTrue);
    });

    test('streamPrimaryAddress returns null for empty userId', () async {
      // Act
      final stream = firestoreService.streamPrimaryAddress('');

      // Assert
      expect(stream, isNotNull);
      final result = await stream.first;
      expect(result, isNull);
    });

    test('streamAddresses handles empty userId gracefully', () async {
      // Act
      final stream = firestoreService.streamAddresses('');

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<Address>>>());
    });
  });

  group('FirestoreService - Pagination Support', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('streamTechnicianServices accepts limit parameter', () {
      // Act
      final stream = firestoreService.streamTechnicianServices(
        limit: 25,
        filterByLocation: false,
      );

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<HomeService>>>());
    });

    test('streamBookings accepts limit parameter', () {
      // Act
      final stream = firestoreService.streamBookings(
        'user-123',
        limit: 50,
      );

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<Booking>>>());
    });

    test('streamTechnicianServices accepts startAfter parameter', () {
      // Act
      final stream = firestoreService.streamTechnicianServices(
        limit: 15,
        startAfter: null,
        filterByLocation: false,
      );

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<HomeService>>>());
    });
  });

  group('FirestoreService - Error Resilience', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('streamCart emits data without throwing', () async {
      // Act
      final stream = firestoreService.streamCart('user-123');

      // Assert - stream should emit without error
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List>>());
    });

    test('streamTechnicianServices handles location filtering gracefully', () async {
      // Arrange
      when(mockLocationService.getUserLocationCached())
          .thenAnswer((_) async => null);

      // Act
      final stream = firestoreService.streamTechnicianServices(
        filterByLocation: true,
      );

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<HomeService>>>());
    });
  });

  group('FirestoreService - Location Service Integration', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('streamTechnicianServices uses location service when enabled', () async {
      // Arrange
      when(mockLocationService.getUserLocationCached())
          .thenAnswer((_) async => {'state': 'maharashtra', 'district': 'mumbai'});

      // Act
      final stream = firestoreService.streamTechnicianServices(
        filterByLocation: true,
      );

      // Assert
      expect(stream, isNotNull);
      verify(mockLocationService.getUserLocationCached()).called(greaterThan(0));
    });

    test('streamTechnicianServices skips location filter when disabled', () async {
      // Act
      final stream = firestoreService.streamTechnicianServices(
        filterByLocation: false,
      );

      // Assert
      expect(stream, isNotNull);
      verifyNever(mockLocationService.getUserLocationCached());
    });
  });

  group('FirestoreService - Sorting Support', () {
    late FirestoreService firestoreService;
    late MockUserLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockUserLocationService();
      firestoreService = FirestoreService(locationService: mockLocationService);
    });

    test('streamTechnicianServices supports recent sorting', () {
      // Act
      final stream = firestoreService.streamTechnicianServices(
        sortBy: 'recent',
        filterByLocation: false,
      );

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<HomeService>>>());
    });

    test('streamTechnicianServices supports topRated sorting', () {
      // Act
      final stream = firestoreService.streamTechnicianServices(
        sortBy: 'topRated',
        filterByLocation: false,
      );

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<HomeService>>>());
    });
  });
}
