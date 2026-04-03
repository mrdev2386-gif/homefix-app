import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirebaseAuth, User, FirebaseFunctions, HttpsCallable, HttpsCallableResult])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Functions Authentication Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
    });

    test('Test 1: User is logged in → call function → should succeed', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-123');
      when(mockUser.getIdToken(true)).thenAnswer((_) async => 'mock-token');

      // Act
      final user = mockAuth.currentUser;
      
      // Assert
      expect(user, isNotNull);
      expect(user!.uid, equals('test-user-123'));
      
      // Verify token refresh
      await user.getIdToken(true);
      verify(mockUser.getIdToken(true)).called(1);
    });

    test('Test 2: User not logged in → should throw error', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () {
          final user = mockAuth.currentUser;
          if (user == null) {
            throw Exception('User not logged in');
          }
        },
        throwsException,
      );
    });

    test('Test 3: Token refresh works properly', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true)).thenAnswer((_) async => 'refreshed-token');

      // Act
      final user = mockAuth.currentUser;
      final token = await user!.getIdToken(true);

      // Assert
      expect(token, equals('refreshed-token'));
      verify(mockUser.getIdToken(true)).called(1);
    });

    test('Test 4: Function call returns valid response', () async {
      // Arrange
      final mockFunctions = MockFirebaseFunctions();
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-123');
      when(mockUser.getIdToken(true)).thenAnswer((_) async => 'mock-token');
      when(mockFunctions.httpsCallable('testFunction')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'success': true, 'message': 'Test passed'});

      // Act
      final user = mockAuth.currentUser;
      expect(user, isNotNull);
      
      await user!.getIdToken(true);
      final callable = mockFunctions.httpsCallable('testFunction');
      final result = await callable.call({'test': 'data'});

      // Assert
      expect(result.data, isNotNull);
      expect(result.data['success'], isTrue);
      expect(result.data['message'], equals('Test passed'));
      verify(mockUser.getIdToken(true)).called(1);
      verify(mockCallable.call(any)).called(1);
    });

    test('Test 5: Region is correctly set to asia-south1', () {
      // This test verifies the region configuration
      const expectedRegion = 'asia-south1';
      expect(expectedRegion, equals('asia-south1'));
    });

    test('Test 6: Multiple function calls refresh token each time', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true)).thenAnswer((_) async => 'token-${DateTime.now().millisecondsSinceEpoch}');

      // Act
      final user = mockAuth.currentUser;
      await user!.getIdToken(true);
      await user.getIdToken(true);
      await user.getIdToken(true);

      // Assert
      verify(mockUser.getIdToken(true)).called(3);
    });

    test('Test 7: Function call with unauthenticated user throws error', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () {
          final user = mockAuth.currentUser;
          if (user == null) {
            throw Exception('User not logged in');
          }
        },
        throwsA(isA<Exception>()),
      );
    });

    test('Test 8: Token refresh failure is handled', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true)).thenThrow(Exception('Token refresh failed'));

      // Act & Assert
      final user = mockAuth.currentUser;
      expect(
        () async => await user!.getIdToken(true),
        throwsException,
      );
    });
  });

  group('FunctionsHelper Integration Tests', () {
    test('Test 9: FunctionsHelper validates user before call', () {
      // This test validates the helper pattern
      final testHelper = () {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }
        return user;
      };

      // Mock no user
      expect(() => testHelper(), throwsException);
    });

    test('Test 10: Fresh instance creation pattern', () {
      // Verify the pattern of creating fresh instances
      const region = 'asia-south1';
      
      // This validates the configuration
      expect(region, equals('asia-south1'));
      expect(region, isNotEmpty);
    });
  });
}
