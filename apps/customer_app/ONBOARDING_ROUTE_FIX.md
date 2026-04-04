# Onboarding & Route Error Fix

## Issues Fixed

### 1. Route Error - Missing `/home` Route
**Problem**: `district_selection_screen.dart` was calling `Navigator.pushNamedAndRemoveUntil('/home', ...)` but the `/home` route was NOT defined in `main.dart`, causing a navigation error.

**Solution**: Added missing routes to `main.dart`:
```dart
routes: {
  '/onboarding': (context) => const OnboardingScreen(),
  '/home': (context) => const MainWrapperScreen(),
  '/customRequest': (context) => const CustomRequestScreen(),
  '/addresses': (context) => const SavedAddressesScreen(),
},
```

### 2. Inconsistent Navigation Flow
**Problem**: After Google/OTP login, users were sent to `DistrictSelectionScreen`, which is a separate flow from the main `OnboardingScreen`.

**Solution**: Unified the flow:
- Google Sign-In → OnboardingScreen (name + location)
- Phone OTP → OnboardingScreen (name + location)
- OnboardingScreen → MainWrapperScreen (after completion)

### 3. Navigation Method Improvements
**Problem**: Using `pushAndRemoveUntil` with MaterialPageRoute instead of named routes.

**Solution**: Changed to `pushReplacementNamed` for cleaner navigation:
- `onboarding_screen.dart`: `Navigator.pushReplacementNamed('/home')`
- `district_selection_screen.dart`: `Navigator.pushReplacementNamed('/home')`
- `login_screen.dart`: `Navigator.pushReplacementNamed('/onboarding')`
- `otp_screen.dart`: `Navigator.pushReplacementNamed('/onboarding')`

### 4. Added Debug Logging
**Enhancement**: Added debug logging to `_routeFromProfile` to help diagnose any future onboarding repeat issues:
```dart
AppLogger.debug('AuthWrapper', 
    'profileCompleted=${userData.profileCompleted}, '
    'isOnboarded=${userData.isOnboarded}, '
    'district=${userData.district}, '
    'ready=$ready');
```

## Files Modified

1. `lib/main.dart` - Added routes, improved logging
2. `lib/features/auth/screens/onboarding_screen.dart` - Changed navigation
3. `lib/features/auth/screens/district_selection_screen.dart` - Changed navigation
4. `lib/features/auth/screens/login_screen.dart` - Changed navigation flow
5. `lib/features/auth/screens/otp_screen.dart` - Changed navigation flow

## Testing Checklist

- [ ] Clean build: `flutter clean && flutter pub get`
- [ ] Test Google Sign-In → Should go to OnboardingScreen
- [ ] Test Phone OTP → Should go to OnboardingScreen
- [ ] Complete onboarding → Should go to MainWrapperScreen
- [ ] Restart app after onboarding → Should go directly to MainWrapperScreen (not repeat onboarding)
- [ ] Check debug logs for routing decisions

## How Profile Completion Works

The app checks THREE conditions before allowing access to MainWrapperScreen:
1. `profileCompleted == true`
2. `isOnboarded == true`
3. `district` is not empty

All three are set when user completes the OnboardingScreen:
```dart
await functionsService.updateUserProfile({
  'name': _nameController.text.trim(),
  'displayName': _nameController.text.trim(),
  'isOnboarded': true,
  'profileCompleted': true,
  'state': _selectedState,
  'district': _selectedDistrict,
  'districtNormalized': _selectedDistrict!.trim().toLowerCase(),
  'defaultAddress': _selectedDistrict,
  'latitude': 0.0,
  'longitude': 0.0,
});
```

## Run Commands

```powershell
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```
