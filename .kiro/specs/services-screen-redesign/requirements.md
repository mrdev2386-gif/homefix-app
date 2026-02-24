# Services Screen Redesign - Requirements

## 1. Overview

Transform the HomeFix customer app Services Screen into a modern, premium, production-ready UI with Urban Company-inspired design while fixing critical data visibility issues and maintaining the existing Firebase-first architecture.

## 2. Problem Statement

### Current Issues
1. **Critical Bug**: Categories and services are not displaying properly
2. **Outdated UI**: Current design lacks modern premium feel
3. **Limited Engagement**: No horizontal scrolling sections or featured content
4. **Poor Discovery**: Missing search functionality and content organization
5. **Performance**: Potential rebuild issues and lack of optimization

### Business Impact
- Poor user experience leading to reduced engagement
- Data not visible = zero conversions
- Outdated UI reduces trust and brand perception
- Missing features limit service discovery

## 3. User Stories

### US-1: Data Visibility Fix (CRITICAL)
**As a** customer  
**I want** to see all available categories and services  
**So that** I can browse and book services

**Acceptance Criteria:**
- AC-1.1: All active categories from Firestore are displayed
- AC-1.2: All active services under each category are visible
- AC-1.3: Debug logs show category and service counts
- AC-1.4: Empty states are shown when no data exists
- AC-1.5: Loading states are shown during data fetch
- AC-1.6: Error states with retry are shown on failures
- AC-1.7: Firestore paths match current architecture (categories/{id}/services)
- AC-1.8: No client-side writes to Firestore (read-only)

### US-2: Modern Search Experience
**As a** customer  
**I want** a sticky search bar at the top  
**So that** I can quickly find services

**Acceptance Criteria:**
- AC-2.1: Search bar is sticky at top of screen
- AC-2.2: Rounded pill design with search icon prefix
- AC-2.3: Placeholder text: "Search for services"
- AC-2.4: Light shadow for depth
- AC-2.5: Debounced search (400ms delay)
- AC-2.6: Search doesn't rebuild entire screen
- AC-2.7: Proper SafeArea padding
- AC-2.8: Clear button appears when text is entered

### US-3: Top Rated Services Banner
**As a** customer  
**I want** to see highly-rated services prominently  
**So that** I can choose quality services

**Acceptance Criteria:**
- AC-3.1: Shows services with rating >= 4.0
- AC-3.2: Horizontal carousel with 4-5 items
- AC-3.3: Large premium cards with service image
- AC-3.4: Service name and rating badge (⭐) visible
- AC-3.5: Smooth PageView scrolling
- AC-3.6: Section title: "Top Rated Services"
- AC-3.7: Optional auto-scroll functionality
- AC-3.8: Tappable cards navigate to service details

### US-4: Popular Services Horizontal Scroller
**As a** customer  
**I want** to browse popular services horizontally  
**So that** I can discover trending options

**Acceptance Criteria:**
- AC-4.1: Shows 2.5 cards visible at once
- AC-4.2: Horizontal ListView with smooth physics
- AC-4.3: viewportFraction ≈ 0.4
- AC-4.4: Right-to-left sliding feel
- AC-4.5: Cards show service image, title, starting price
- AC-4.6: Section title: "Popular Services"
- AC-4.7: Smooth scroll performance
- AC-4.8: Cards are tappable

### US-5: Featured Offers Carousel
**As a** customer  
**I want** to see promotional offers  
**So that** I can take advantage of deals

**Acceptance Criteria:**
- AC-5.1: Full-width promotional slider
- AC-5.2: 4-5 promotional images
- AC-5.3: AspectRatio maintained
- AC-5.4: Page indicator dots
- AC-5.5: Swipe right-to-left
- AC-5.6: Section title: "Featured Offers"
- AC-5.7: Auto-advance optional
- AC-5.8: Smooth transitions

### US-6: Recommended Services Section
**As a** customer  
**I want** personalized recommendations  
**So that** I can discover relevant services

**Acceptance Criteria:**
- AC-6.1: Second 2.5 card horizontal section
- AC-6.2: Section title: "Recommended for You"
- AC-6.3: Reuses horizontal scroller widget (DRY)
- AC-6.4: Same card design as Popular Services
- AC-6.5: Different data source (recommendations logic)

### US-7: Category Grid Display
**As a** customer  
**I want** to browse all categories in a grid  
**So that** I can explore service types

**Acceptance Criteria:**
- AC-7.1: GridView with 3 items per row
- AC-7.2: Icon/image in rounded container
- AC-7.3: Category name below icon
- AC-7.4: Proper spacing between items
- AC-7.5: Tap ripple effect
- AC-7.6: Section title: "All Categories"
- AC-7.7: Responsive to screen size
- AC-7.8: Navigates to category services on tap

### US-8: Additional Modern Sections
**As a** customer  
**I want** diverse content sections  
**So that** I have multiple ways to discover services

**Acceptance Criteria:**
- AC-8.1: At least 2 additional sections implemented
- AC-8.2: Options include: Recently Booked, Trending Near You, New on HomeFix, Quick Services
- AC-8.3: Reusable horizontal components
- AC-8.4: Consistent design language
- AC-8.5: Proper section titles
- AC-8.6: Smooth scrolling

### US-9: Performance Optimization
**As a** customer  
**I want** smooth, fast screen performance  
**So that** I have a pleasant browsing experience

**Acceptance Criteria:**
- AC-9.1: const constructors used where possible
- AC-9.2: AutomaticKeepAliveClientMixin for state preservation
- AC-9.3: Proper image caching implemented
- AC-9.4: No nested heavy rebuilds
- AC-9.5: SizedBox used instead of Container where possible
- AC-9.6: Skeleton loaders during loading
- AC-9.7: No jank during scrolling
- AC-9.8: Efficient stream subscriptions

### US-10: Empty and Error States
**As a** customer  
**I want** clear feedback when things go wrong  
**So that** I understand what's happening

**Acceptance Criteria:**
- AC-10.1: Loading state shows shimmer/skeleton
- AC-10.2: Empty state shows friendly illustration + text
- AC-10.3: Error state shows retry button
- AC-10.4: Network error has specific message
- AC-10.5: Permission error has specific message
- AC-10.6: All states are visually appealing
- AC-10.7: States don't break layout

## 4. Technical Requirements

### TR-1: Architecture Compliance
- Must maintain existing Firebase-first architecture
- Read-only Firestore access from client
- Use existing CategoryService and models
- No breaking changes to data structure

### TR-2: Code Quality
- Null-safe Dart code
- No hardcoded sizes (use MediaQuery/LayoutBuilder)
- Reusable widget components
- Clean folder structure (presentation/widgets)
- No deprecated APIs
- Follow existing HomeFix theme

### TR-3: Firestore Integration
- Stream-based data fetching
- Proper error handling
- Defensive null checks
- Debug logging for troubleshooting
- Efficient queries (indexed where needed)

### TR-4: UI/UX Standards
- Material Design 3 principles
- Consistent spacing and typography
- Smooth animations (200-300ms)
- Haptic feedback on interactions
- Accessibility support (semantic labels)

## 5. Non-Functional Requirements

### NFR-1: Performance
- Screen load time < 2 seconds
- Smooth 60fps scrolling
- Image loading with placeholders
- Efficient memory usage

### NFR-2: Responsiveness
- Works on all screen sizes (phones, tablets)
- Adaptive layouts
- Proper safe area handling
- Landscape orientation support

### NFR-3: Maintainability
- Well-documented code
- Reusable components
- Clear separation of concerns
- Easy to extend with new sections

### NFR-4: Reliability
- Graceful error handling
- Offline capability awareness
- No runtime crashes
- Proper state management

## 6. Constraints

### Technical Constraints
- Must use existing Firestore structure
- Cannot modify backend/admin panel
- Must work with current Flutter version
- Limited to existing dependencies

### Business Constraints
- No breaking changes to existing features
- Must maintain backward compatibility
- Cannot change navigation flow
- Must preserve existing booking flow

## 7. Dependencies

### Internal Dependencies
- CategoryService (core/firestore/category_service.dart)
- HomeService model (core/models/service.dart)
- Category model (core/models/category.dart)
- AppTheme (core/theme/app_theme.dart)
- SafeNetworkImage widget

### External Dependencies
- cloud_firestore
- provider
- google_fonts
- cached_network_image

## 8. Success Metrics

### Quantitative Metrics
- 100% of categories visible (currently 0%)
- 100% of services visible (currently 0%)
- Screen load time < 2s
- Zero runtime errors
- 60fps scroll performance

### Qualitative Metrics
- Modern, premium UI feel
- Improved user engagement
- Better service discovery
- Positive user feedback
- Reduced support tickets

## 9. Out of Scope

The following are explicitly out of scope for this redesign:

1. Backend/Firestore structure changes
2. Admin panel modifications
3. Booking flow changes
4. Payment integration
5. User authentication changes
6. Push notification system
7. Analytics integration
8. A/B testing framework
9. Internationalization (i18n)
10. Dark mode support

## 10. Risks and Mitigations

### Risk 1: Data Not Loading
**Mitigation**: Comprehensive debug logging, error states, and Firestore path verification

### Risk 2: Performance Degradation
**Mitigation**: Use const constructors, efficient widgets, proper state management

### Risk 3: Breaking Existing Features
**Mitigation**: Thorough testing, maintain existing navigation, preserve state

### Risk 4: Design Inconsistency
**Mitigation**: Follow existing AppTheme, reusable components, design review

## 11. Acceptance Testing Checklist

- [ ] All categories display correctly
- [ ] All services display correctly
- [ ] Search bar is functional
- [ ] Top rated services section works
- [ ] Popular services scroll smoothly
- [ ] Featured offers carousel works
- [ ] Recommended section displays
- [ ] Category grid is responsive
- [ ] Additional sections implemented
- [ ] Loading states show properly
- [ ] Empty states show properly
- [ ] Error states show properly
- [ ] No runtime errors
- [ ] Smooth 60fps scrolling
- [ ] Images load with placeholders
- [ ] Navigation works correctly
- [ ] Haptic feedback works
- [ ] Works on different screen sizes
- [ ] No memory leaks
- [ ] Code follows style guide
