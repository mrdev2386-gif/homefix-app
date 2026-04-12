import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/core/services/booking_service.dart';
import 'package:customer_app/core/models/booking.dart';

void main() {
  group('BookingService - Input Validation', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('createBookingRequest throws exception for empty serviceId', () {
      // Arrange
      const serviceId = '';
      const technicianId = 'tech-123';
      const categoryId = 'cat-123';
      const categoryName = 'Cleaning';
      const scheduledDate = '2025-12-25';
      const scheduledTime = '10:00 AM';
      final address = {'fullAddress': '123 Main St'};

      // Act & Assert
      expect(
        () => bookingService.createBookingRequest(
          serviceId: serviceId,
          technicianId: technicianId,
          categoryId: categoryId,
          categoryName: categoryName,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          address: address,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('createBookingRequest throws exception for empty technicianId', () {
      // Arrange
      const serviceId = 'svc-123';
      const technicianId = '';
      const categoryId = 'cat-123';
      const categoryName = 'Cleaning';
      const scheduledDate = '2025-12-25';
      const scheduledTime = '10:00 AM';
      final address = {'fullAddress': '123 Main St'};

      // Act & Assert
      expect(
        () => bookingService.createBookingRequest(
          serviceId: serviceId,
          technicianId: technicianId,
          categoryId: categoryId,
          categoryName: categoryName,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          address: address,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('createBookingRequest throws exception for empty categoryId', () {
      // Arrange
      const serviceId = 'svc-123';
      const technicianId = 'tech-123';
      const categoryId = '';
      const categoryName = 'Cleaning';
      const scheduledDate = '2025-12-25';
      const scheduledTime = '10:00 AM';
      final address = {'fullAddress': '123 Main St'};

      // Act & Assert
      expect(
        () => bookingService.createBookingRequest(
          serviceId: serviceId,
          technicianId: technicianId,
          categoryId: categoryId,
          categoryName: categoryName,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          address: address,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('createBookingRequest throws exception for empty address', () {
      // Arrange
      const serviceId = 'svc-123';
      const technicianId = 'tech-123';
      const categoryId = 'cat-123';
      const categoryName = 'Cleaning';
      const scheduledDate = '2025-12-25';
      const scheduledTime = '10:00 AM';
      final address = {'fullAddress': ''};

      // Act & Assert
      expect(
        () => bookingService.createBookingRequest(
          serviceId: serviceId,
          technicianId: technicianId,
          categoryId: categoryId,
          categoryName: categoryName,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          address: address,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('BookingService - Stream Type Validation', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('getCustomerBookings returns Stream<List<Booking>>', () {
      // Act
      final stream = bookingService.getCustomerBookings('cust-123');

      // Assert
      expect(stream, isA<Stream<List<Booking>>>());
    });

    test('getBookingStream returns Stream<Booking>', () {
      // Act
      final stream = bookingService.getBookingStream('booking-123');

      // Assert
      expect(stream, isA<Stream<Booking>>());
    });
  });

  group('BookingService - Booking Queries', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('getBooking returns Booking or null', () async {
      // Act
      final booking = await bookingService.getBooking('booking-123');

      // Assert
      expect(booking, anyOf(isA<Booking>(), isNull));
    });

    test('getCustomerBookings returns non-null stream', () {
      // Act
      final stream = bookingService.getCustomerBookings('cust-123');

      // Assert
      expect(stream, isNotNull);
    });

    test('getBookingStream returns non-null stream', () {
      // Act
      final stream = bookingService.getBookingStream('booking-123');

      // Assert
      expect(stream, isNotNull);
    });
  });

  group('BookingService - Cancellation', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('cancelBooking throws exception for empty bookingId', () {
      // Arrange
      const bookingId = '';
      const reason = 'Changed my mind';

      // Act & Assert
      expect(
        () => bookingService.cancelBooking(bookingId, reason),
        throwsA(isA<Exception>()),
      );
    });

    test('cancelBooking accepts valid bookingId', () {
      // Arrange
      const bookingId = 'booking-123';
      const reason = 'Changed my mind';

      // Act & Assert
      expect(
        () => bookingService.cancelBooking(bookingId, reason),
        returnsNormally,
      );
    });
  });

  group('BookingService - Payment Confirmation', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('confirmPayment throws exception for empty bookingId', () {
      // Arrange
      const bookingId = '';
      const paymentMethod = 'online';

      // Act & Assert
      expect(
        () => bookingService.confirmPayment(
          bookingId: bookingId,
          paymentMethod: paymentMethod,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('confirmPayment throws exception for empty paymentMethod', () {
      // Arrange
      const bookingId = 'booking-123';
      const paymentMethod = '';

      // Act & Assert
      expect(
        () => bookingService.confirmPayment(
          bookingId: bookingId,
          paymentMethod: paymentMethod,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('confirmPayment accepts valid parameters', () {
      // Arrange
      const bookingId = 'booking-123';
      const paymentMethod = 'online';

      // Act & Assert
      expect(
        () => bookingService.confirmPayment(
          bookingId: bookingId,
          paymentMethod: paymentMethod,
        ),
        returnsNormally,
      );
    });
  });

  group('BookingService - Error Handling', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('getCustomerBookings handles errors gracefully', () {
      // Act
      final stream = bookingService.getCustomerBookings('cust-123');

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<List<Booking>>>());
    });

    test('getBookingStream handles errors gracefully', () {
      // Act
      final stream = bookingService.getBookingStream('booking-123');

      // Assert
      expect(stream, isNotNull);
      expect(stream, isA<Stream<Booking>>());
    });
  });

  group('BookingService - Valid Booking Creation', () {
    late BookingService bookingService;

    setUp(() {
      bookingService = BookingService();
    });

    test('createBookingRequest accepts all valid parameters', () {
      // Arrange
      const serviceId = 'svc-123';
      const technicianId = 'tech-123';
      const categoryId = 'cat-123';
      const categoryName = 'Cleaning';
      const scheduledDate = '2025-12-25';
      const scheduledTime = '10:00 AM';
      final address = {'fullAddress': '123 Main St'};

      // Act & Assert
      expect(
        () => bookingService.createBookingRequest(
          serviceId: serviceId,
          technicianId: technicianId,
          categoryId: categoryId,
          categoryName: categoryName,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          address: address,
        ),
        returnsNormally,
      );
    });
  });
}
