# HomeFix Deep System Recovery - Requirements

## Overview
Complete system stabilization to eliminate all runtime failures including App Check issues, blocked writes, broken media, and layout errors while maintaining Firebase-first security architecture.

## User Stories

### US-1: App Check Reliability
**As a** developer  
**I want** App Check to initialize correctly and generate tokens reliably  
**So that** all Firebase operations work without attestation failures

**Acceptance Criteria:**
- 1.1: App Check initializes after Firebase.initializeApp() in correct order
- 1.2: Debug provider works in debug mode, Play Integrity in release
- 1.3: Token generation is logged and visible in debug output
- 1.4: No "App attestation failed" errors appear in logs
- 1.5: Debug mode failures log warnings but don't break UI
- 1.6: App Check is never disabled in release builds

### US-2: Write Operations Guarantee
**As a** user  
**I want** all my actions (cart, favorites, addresses) to work reliably  
**So that** I never experience silent failures or unresponsive buttons

**Acceptance Criteria:**
- 2.1: Cart operations (add/update/remove) complete successfully
- 2.2: Favorite toggle operations work and provide feedback
- 2.3: Address save/update operations complete successfully
- 2.4: Profile updates are saved correctly
- 2.5: Notification read status updates work
- 2.6: Booking cancellations process correctly
- 2.7: All operations show loading states during execution
- 2.8: Success feedback is shown to users
- 2.9: Error messages are displayed when operations fail
- 2.10: No silent failures occur - all errors are logged and reported

### US-3: Media Reliability
**As a** user  
**I want** all images and videos to load correctly or show appropriate fallbacks  
**So that** I never see crashes or broken media elements

**Acceptance Criteria:**
- 3.1: Empty or invalid image URLs are rejected before loading
- 3.2: Non-HTTP/HTTPS URLs are rejected
- 3.3: Network timeouts (10s) are handled gracefully
- 3.4: Fallback widgets are shown for failed images
- 3.5: Known bad URL patterns trigger automatic fallbacks
- 3.6: No infinite retry loops occur
- 3.7: Zero HttpException errors in production logs
- 3.8: All Image.network usages are replaced with SafeNetworkImage

### US-4: Video Player Stability
**As a** user  
**I want** professional reels to play smoothly or fail gracefully  
**So that** video issues never crash the app

**Acceptance Criteria:**
- 4.1: HTTPS URLs are validated before player initialization
- 4.2: Firebase Storage links are validated
- 4.3: ExoPlaybackException errors are caught and handled
- 4.4: 403/404 errors show thumbnail fallback
- 4.5: Failed videos retry only once
- 4.6: No uncaught player exceptions crash the screen
- 4.7: Reels section remains stable with bad video data

### US-5: Layout Integrity
**As a** user  
**I want** all screens to render correctly without overflow errors  
**So that** the UI is always clean and professional

**Acceptance Criteria:**
- 5.1: Long text uses TextOverflow.ellipsis
- 5.2: Flexible/Expanded only used in bounded width contexts
- 5.3: No unbounded Flex errors occur
- 5.4: Horizontal ListViews are properly constrained
- 5.5: Minimum constraints are applied where needed
- 5.6: Zero RenderFlex overflow warnings in logs
- 5.7: Zero "RenderBox not laid out" errors occur
- 5.8: All pixel overflows > 0.1px are fixed

### US-6: Data Path Safety
**As a** developer  
**I want** all Firestore document paths to be validated  
**So that** invalid paths never cause crashes

**Acceptance Criteria:**
- 6.1: Empty document IDs are blocked before Firestore calls
- 6.2: Null document IDs are blocked before Firestore calls
- 6.3: Path guards are applied to cart operations
- 6.4: Path guards are applied to favorites operations
- 6.5: Path guards are applied to address operations
- 6.6: Path guards are applied to booking operations
- 6.7: Path guards are applied to notification operations
- 6.8: All blocked paths are logged for debugging
- 6.9: No "invalid document path" crashes occur

### US-7: Data Resilience
**As a** developer  
**I want** all Firestore data parsing to handle dirty/invalid data  
**So that** bad data never causes runtime errors

**Acceptance Criteria:**
- 7.1: Null fields are handled with safe defaults
- 7.2: NaN values are detected and replaced
- 7.3: Missing price fields default to 0
- 7.4: Invalid type conversions are caught
- 7.5: Infinity values are detected and handled
- 7.6: All numeric conversions check isFinite
- 7.7: Model parsers never throw on unexpected data
- 7.8: Zero NaN/Infinity errors in production

### US-8: User Feedback Quality
**As a** user  
**I want** clear feedback for all my actions  
**So that** I always know what's happening

**Acceptance Criteria:**
- 8.1: Loading states are shown during operations
- 8.2: Success messages appear after successful operations
- 8.3: Error messages explain what went wrong
- 8.4: Users never feel buttons are unresponsive
- 8.5: Feedback is consistent across all features
- 8.6: Loading indicators are removed after completion

## Non-Functional Requirements

### NFR-1: Security
- All fixes must maintain Firebase-first security architecture
- No direct client writes to Firestore
- Callable-first architecture is preserved
- Security rules remain unchanged
- App Check stays enabled in production

### NFR-2: Production Safety
- All changes must be production-safe
- No experimental or risky approaches
- Backward compatibility maintained
- Graceful degradation for failures

### NFR-3: Performance
- No performance regressions introduced
- Media loading remains efficient
- UI remains responsive during operations

### NFR-4: Maintainability
- All fixes include debug logging
- Error messages are descriptive
- Code follows existing patterns
- Documentation is updated

## Success Criteria

The system recovery is complete when:
1. App Check tokens appear in logs consistently
2. Zero permission-denied errors occur
3. Cart operations work reliably
4. Favorites operations work reliably
5. Address save operations work reliably
6. Images never crash the app
7. Videos fail safely without crashes
8. Zero RenderFlex overflow warnings
9. Zero invalid path errors
10. Premium HomeFix UX is maintained

## Out of Scope

- New feature development
- UI/UX redesigns
- Performance optimizations beyond stability
- Migration to new architectures
- Third-party service integrations

## Dependencies

- Firebase SDK (current versions)
- firebase_app_check package
- Video player packages
- Image caching packages
- Existing Cloud Functions

## Constraints

- Must not weaken security rules
- Must not reintroduce direct client writes
- Must maintain callable-first architecture
- Must be production-safe
- Must preserve existing functionality
