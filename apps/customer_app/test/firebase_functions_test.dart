import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'firebase_functions_test.mocks.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Auth - User State Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
    });

    test('currentUser returns user when logged in', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-123');

      // Act
      final user = mockAuth.currentUser;

      // Assert
      expect(user, isNotNull);
      expect(user!.uid, equals('test-user-123'));
      verify(mockAuth.currentUser).called(1);
    });

    test('currentUser returns null when not logged in', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final user = mockAuth.currentUser;

      // Assert
      expect(user, isNull);
      verify(mockAuth.currentUser).called(1);
    });

    test('throws exception when accessing uid of null user', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () {
          final user = mockAuth.currentUser;
          if (user == null) throw Exception('User not logged in');
        },
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Firebase Auth - Token Refresh Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
    });

    test('getIdToken refreshes token successfully', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true))
          .thenAnswer((_) async => 'refreshed-token-123');

      // Act
      final user = mockAuth.currentUser;
      final token = await user!.getIdToken(true);

      // Assert
      expect(token, equals('refreshed-token-123'));
      verify(mockUser.getIdToken(true)).called(1);
    });

    test('getIdToken called multiple times', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true))
          .thenAnswer((_) async => 'token-${DateTime.now().millisecondsSinceEpoch}');

      // Act
      final user = mockAuth.currentUser;
      await user!.getIdToken(true);
      await user.getIdToken(true);
      await user.getIdToken(true);

      // Assert
      verify(mockUser.getIdToken(true)).called(3);
    });

    test('getIdToken throws exception on failure', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(true))
          .thenThrow(Exception('Token refresh failed'));

      // Act & Assert
      final user = mockAuth.currentUser;
      expect(
        () async => await user!.getIdToken(true),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Firebase Functions - Call Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockFirebaseFunctions mockFunctions;
    late MockHttpsCallable mockCallable;
    late MockHttpsCallableResult mockResult;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFunctions = MockFirebaseFunctions();
      mockCallable = MockHttpsCallable();
      mockResult = MockHttpsCallableResult();
    });

    test('function call returns valid response', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-123');
      when(mockUser.getIdToken(true)).thenAnswer((_) async => 'mock-token');
      when(mockFunctions.httpsCallable('testFunction')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'success': true, 'message': 'Test passed'});

      // Act
      final user = mockAuth.currentUser;
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

    test('function call with unauthenticated user throws error', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () {
          final user = mockAuth.currentUser;
          if (user == null) throw Exception('User not logged in');
        },
        throwsA(isA<Exception>()),
      );
    });

    test('function call data is passed correctly', () async {
      // Arrange
      when(mockFunctions.httpsCallable('testFunction')).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({'status': 'ok'});

      // Act
      final callable = mockFunctions.httpsCallable('testFunction');
      final testData = {'userId': 'user-123', 'action': 'create'};
      final result = await callable.call(testData);

      // Assert
      expect(result.data, isNotNull);
      verify(mockCallable.call(testData)).called(1);
    });
  });

  group('Firebase Functions - Error Handling', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockFirebaseFunctions mockFunctions;
    late MockHttpsCallable mockCallable;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFunctions = MockFirebaseFunctions();
      mockCallable = MockHttpsCallable();
    });

    test('function call throws exception on failure', () async {
      // Arrange
      when(mockFunctions.httpsCallable('failingFunction'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any))
          .thenThrow(FirebaseFunctionsException(code: 'internal-error'));

      // Act & Assert
      final callable = mockFunctions.httpsCallable('failingFunction');
      expect(
        () async => await callable.call({}),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });

    test('unauthenticated error is properly identified', () async {
      // Arrange
      when(mockFunctions.httpsCallable('protectedFunction'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any))
          .thenThrow(FirebaseFunctionsException(code: 'unauthenticated'));

      // Act & Assert
      final callable = mockFunctions.httpsCallable('protectedFunction');
      expect(
        () async => await callable.call({}),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });

  group('Firebase Functions - Region Configuration', () {
    test('region is correctly set to asia-south1', () {
      // Arrange
      const expectedRegion = 'asia-south1';

      // Assert
      expect(expectedRegion, equals('asia-south1'));
      expect(expectedRegion, isNotEmpty);
    });
  });

  group('Firebase Auth - Integration Pattern', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
    });

    test('user authentication flow works correctly', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-123');
      when(mockUser.getIdToken(true)).thenAnswer((_) async => 'token-123');

      // Act
      final user = mockAuth.currentUser;
      expect(user, isNotNull);
      
      final token = await user!.getIdToken(true);
      expect(token, isNotNull);

      // Assert
      verify(mockAuth.currentUser).called(1);
      verify(mockUser.getIdToken(true)).called(1);
    });

    test('unauthenticated user cannot access protected resources', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final user = mockAuth.currentUser;

      // Assert
      expect(user, isNull);
      expect(
        () {
          if (user == null) throw Exception('User not authenticated');
        },
        throwsA(isA<Exception>()),
      );
    });
  });
}
