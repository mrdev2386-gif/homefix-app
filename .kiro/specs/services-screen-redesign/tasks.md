# Services Screen Redesign - Implementation Tasks

## Task 1: Critical Data Fix and Debugging (PHASE 1 - HIGHEST PRIORITY)

**Status**: Not Started  
**Priority**: CRITICAL  
**Estimated Time**: 2-3 hours

### Subtasks:

- [ ] 1.1 Add comprehensive debug logging to CategoryService
  - Add logs for category count
  - Add logs for services count per category
  - Add logs for Firestore query execution
  - Add logs for data parsing

- [ ] 1.2 Verify Firestore paths match architecture
  - Confirm path: `categories/{categoryId}/services/{serviceId}`
  - Test getCategoriesOnce() method
  - Test getServicesByCategory() method
  - Test getAllServices() method

- [ ] 1.3 Implement proper error handling
  - Add try-catch blocks
  - Categorize errors (network, permission, unknown)
  - Set error state properly
  - Log all errors with context

- [ ] 1.4 Add defensive null checks
  - Check snapshot.data for null
  - Check document data for null
  - Check field values for null
  - Use null-aware operators

- [ ] 1.5 Test data visibility
  - Run app and check debug logs
  - Verify categories appear
  - Verify services appear
  - Confirm counts match Firestore

**Acceptance Criteria**:
- Debug logs show category and service counts
- All active categories are visible
- All active services are visible
- No null pointer exceptions
- Proper error messages on failures

---

## Task 2: Core UI Foundation (PHASE 2)

**Status**: Not Started  
**Priority**: HIGH  
**Estimated Time**: 3-4 hours

### Subtasks:

- [ ] 2.1 Create new ServicesScreen widget
  - Create file: `services_screen.dart`
  - Implement StatefulWidget
  - Add AutomaticKeepAliveClientMixin
  - Set up state variables

- [ ] 2.2 Implement CustomScrollView structure
  - Add SafeArea wrapper
  - Create CustomScrollView
  - Add BouncingScrollPhysics
  - Set up scroll controller

- [ ] 2.3 Create sticky search bar widget
  - Create file: `sticky_search_bar.dart`
  - Implement SliverPersistentHeader
  - Add search TextField
  - Implement debounce logic (400ms)
  - Add clear button

- [ ] 2.4 Implement skeleton loaders
  - Create file: `shimmer_service_card.dart`
  - Add shimmer package if needed
  - Create skeleton for search bar
  - Create skeleton for service cards
  - Create skeleton for category grid

- [ ] 2.5 Apply theme and styling
  - Use AppTheme colors
  - Use GoogleFonts.outfit
  - Apply consistent spacing
  - Apply consistent border radius

**Acceptance Criteria**:
- ServicesScreen renders without errors
- Search bar is sticky at top
- Skeleton loaders show during loading
- Theme is consistent with app
- Smooth scrolling performance

---

## Task 3: Top Rated Services Section (PHASE 3.1)

**Status**: Not Started  
**Priority**: HIGH  
**Estimated Time**: 2-3 hours

### Subtasks:

- [ ] 3.1 Create TopRatedServicesSection widget
  - Create file: `top_rated_services_section.dart`
  - Filter services with rating >= 4.0
  - Limit to 5 services
  - Add section title

- [ ] 3.2 Create TopRatedServiceCard widget
  - Create file: `top_rated_service_card.dart`
  - Card size: 280w x 200h
  - Show service image (140h)
  - Show service name
  - Show rating badge with star icon
  - Show starting price

- [ ] 3.3 Implement PageView carousel
  - Use PageView.builder
  - Add page controller
  - Implement smooth scrolling
  - Add spacing between cards

- [ ] 3.4 Add page indicator dots
  - Create dot indicator widget
  - Position below carousel
  - Update on page change
  - Style with primary color

- [ ] 3.5 Add optional auto-scroll
  - Implement timer (5s interval)
  - Auto-advance to next page
  - Loop back to start
  - Pause on user interaction

**Acceptance Criteria**:
- Shows services with rating >= 4.0
- Horizontal carousel works smoothly
- Cards are tappable
- Page indicators work
- Section title displays correctly

---

## Task 4: Horizontal Service Scroller (PHASE 3.2 - Reusable Component)

**Status**: Not Started  
**Priority**: HIGH  
**Estimated Time**: 2-3 hours

### Subtasks:

- [ ] 4.1 Create HorizontalServiceScroller widget
  - Create file: `horizontal_service_scroller.dart`
  - Make it reusable with parameters
  - Accept title, services list, onTap callback
  - Accept optional card dimensions

- [ ] 4.2 Create ServiceCard widget
  - Create file: `service_card.dart`
  - Card size: 160w x 220h
  - Show service image (120h)
  - Show service name
  - Show price
  - Show duration

- [ ] 4.3 Implement 2.5 card layout
  - Use ListView.builder
  - Set viewportFraction to 0.42
  - Add horizontal padding
  - Add card spacing (12px)

- [ ] 4.4 Add smooth scroll physics
  - Use BouncingScrollPhysics
  - Test scroll performance
  - Ensure no jank
  - Add scroll controller if needed

- [ ] 4.5 Add tap handling
  - Implement onTap callback
  - Add haptic feedback
  - Add navigation guard
  - Handle navigation

**Acceptance Criteria**:
- Shows 2.5 cards at once
- Smooth horizontal scrolling
- Reusable for multiple sections
- Cards are tappable
- No performance issues

---

## Task 5: Featured Offers Carousel (PHASE 3.3)

**Status**: Not Started  
**Priority**: MEDIUM  
**Estimated Time**: 2 hours

### Subtasks:

- [ ] 5.1 Create FeaturedOffersCarousel widget
  - Create file: `featured_offers_carousel.dart`
  - Fetch banners from Firestore
  - Add section title

- [ ] 5.2 Implement full-width carousel
  - Use PageView.builder
  - Full width minus 32px padding
  - Aspect ratio 16:9
  - Border radius 20px

- [ ] 5.3 Add page indicator dots
  - Create dot indicator
  - Position at bottom
  - Update on page change
  - Style appropriately

- [ ] 5.4 Implement auto-advance
  - Add timer (4s interval)
  - Auto-scroll to next
  - Loop back to start
  - Pause on user interaction

- [ ] 5.5 Add banner images
  - Use SafeNetworkImage
  - Add placeholder
  - Add error widget
  - Cache images

**Acceptance Criteria**:
- Full-width carousel displays
- 4-5 promotional images show
- Page indicators work
- Auto-advance works
- Images load properly

---

## Task 6: Additional Horizontal Sections (PHASE 3.4-3.6)

**Status**: Not Started  
**Priority**: MEDIUM  
**Estimated Time**: 3-4 hours

### Subtasks:

- [ ] 6.1 Implement Popular Services section
  - Reuse HorizontalServiceScroller
  - Title: "Popular Services"
  - Data: Top services by order
  - Add to CustomScrollView

- [ ] 6.2 Implement Recommended Services section
  - Reuse HorizontalServiceScroller
  - Title: "Recommended for You"
  - Data: Recently added services
  - Add to CustomScrollView

- [ ] 6.3 Implement Trending Near You section
  - Reuse HorizontalServiceScroller
  - Title: "Trending Near You"
  - Data: Services with isTrending = true
  - Add to CustomScrollView

- [ ] 6.4 Implement New Services section
  - Reuse HorizontalServiceScroller
  - Title: "New on HomeFix"
  - Data: Recently added (by createdAt)
  - Add to CustomScrollView

- [ ] 6.5 Add section spacing
  - Consistent spacing between sections
  - Use SizedBox with const
  - Follow design specs
  - Test on different screens

**Acceptance Criteria**:
- All 4 sections implemented
- Reuses HorizontalServiceScroller
- Different data sources
- Proper spacing
- Smooth scrolling

---

## Task 7: All Categories Grid (PHASE 3.7)

**Status**: Not Started  
**Priority**: MEDIUM  
**Estimated Time**: 2 hours

### Subtasks:

- [ ] 7.1 Create CategoryGridItem widget
  - Create file: `category_grid_item.dart`
  - Square aspect ratio
  - Show icon/image (48px)
  - Show category name
  - Show service count

- [ ] 7.2 Implement SliverGrid
  - Use SliverGrid.builder
  - 3 columns
  - Spacing: 16px
  - Proper padding

- [ ] 7.3 Add category icons
  - Use existing icon mapping
  - Fallback to default icon
  - Style with primary color
  - Size: 48px

- [ ] 7.4 Add tap handling
  - Navigate to CategoryServicesScreen
  - Add haptic feedback
  - Add navigation guard
  - Pass category data

- [ ] 7.5 Add section title
  - Title: "All Categories"
  - Style consistently
  - Proper spacing
  - Use SliverToBoxAdapter

**Acceptance Criteria**:
- Grid shows 3 columns
- All categories visible
- Icons display correctly
- Tappable with navigation
- Responsive layout

---

## Task 8: Loading States (PHASE 4.1)

**Status**: Not Started  
**Priority**: MEDIUM  
**Estimated Time**: 2 hours

### Subtasks:

- [ ] 8.1 Enhance shimmer loaders
  - Add shimmer animation
  - Create for each section type
  - Match actual card dimensions
  - Use proper colors

- [ ] 8.2 Implement loading sequence
  - Show skeleton for search
  - Show skeleton for sections
  - Replace with data progressively
  - Smooth transitions

- [ ] 8.3 Add loading indicators
  - Use CircularProgressIndicator where appropriate
  - Style with primary color
  - Proper sizing
  - Center alignment

- [ ] 8.4 Test loading states
  - Test with slow network
  - Test with fast network
  - Verify no flicker
  - Verify smooth transitions

**Acceptance Criteria**:
- Shimmer loaders look professional
- Loading sequence is smooth
- No layout shifts
- Proper loading indicators

---

## Task 9: Empty and Error States (PHASE 4.2)

**Status**: Not Started  
**Priority**: MEDIUM  
**Estimated Time**: 2 hours

### Subtasks:

- [ ] 9.1 Enhance EmptyStateWidget
  - Update existing widget
  - Add friendly illustrations
  - Improve messaging
  - Style consistently

- [ ] 9.2 Enhance ErrorStateWidget
  - Update existing widget
  - Add error-specific icons
  - Improve error messages
  - Add retry button

- [ ] 9.3 Implement specific empty states
  - No categories state
  - No services state
  - Search no results state
  - Each with appropriate message

- [ ] 9.4 Implement specific error states
  - Network error state
  - Permission error state
  - Unknown error state
  - Each with retry action

- [ ] 9.5 Test all states
  - Test empty categories
  - Test empty services
  - Test network errors
  - Test permission errors

**Acceptance Criteria**:
- Empty states are friendly
- Error states are helpful
- Retry buttons work
- Messages are clear
- Icons are appropriate

---

## Task 10: Performance Optimization (PHASE 4.3)

**Status**: Not Started  
**Priority**: HIGH  
**Estimated Time**: 2-3 hours

### Subtasks:

- [ ] 10.1 Add const constructors
  - Review all widgets
  - Add const where possible
  - Use const for SizedBox
  - Use const for Text styles

- [ ] 10.2 Optimize image loading
  - Implement proper caching
  - Add placeholders
  - Add error widgets
  - Optimize image sizes

- [ ] 10.3 Reduce unnecessary rebuilds
  - Use ValueKey for lists
  - Separate stateful/stateless properly
  - Use const constructors
  - Profile with DevTools

- [ ] 10.4 Optimize stream subscriptions
  - Dispose properly
  - Use StreamBuilder efficiently
  - Avoid nested StreamBuilders
  - Cache stream results

- [ ] 10.5 Test scroll performance
  - Profile with DevTools
  - Check for jank
  - Verify 60fps
  - Test on low-end devices

**Acceptance Criteria**:
- Smooth 60fps scrolling
- No unnecessary rebuilds
- Images load efficiently
- No memory leaks
- Passes performance profiling

---

## Task 11: UX Polish (PHASE 5)

**Status**: Not Started  
**Priority**: MEDIUM  
**Estimated Time**: 2 hours

### Subtasks:

- [ ] 11.1 Add haptic feedback
  - Add to service card taps
  - Add to category taps
  - Add to search interactions
  - Use HapticFeedback.lightImpact()

- [ ] 11.2 Add smooth animations
  - Add to card taps (scale)
  - Add to page transitions
  - Duration: 200-300ms
  - Use Curves.easeInOut

- [ ] 11.3 Add semantic labels
  - Add to search bar
  - Add to service cards
  - Add to category cards
  - Add to buttons

- [ ] 11.4 Improve accessibility
  - Test with TalkBack/VoiceOver
  - Ensure proper focus order
  - Add tooltips where needed
  - Test with large text

- [ ] 11.5 Final polish
  - Review all spacing
  - Review all colors
  - Review all typography
  - Test on multiple devices

**Acceptance Criteria**:
- Haptic feedback works
- Animations are smooth
- Accessible to screen readers
- Works with large text
- Polished feel

---

## Task 12: Integration and Testing (FINAL)

**Status**: Not Started  
**Priority**: HIGH  
**Estimated Time**: 2-3 hours

### Subtasks:

- [ ] 12.1 Integration testing
  - Test complete user flow
  - Test navigation
  - Test search
  - Test all sections

- [ ] 12.2 Error scenario testing
  - Test with no internet
  - Test with empty Firestore
  - Test with invalid data
  - Test with slow network

- [ ] 12.3 Performance testing
  - Profile with DevTools
  - Check memory usage
  - Check CPU usage
  - Test on low-end device

- [ ] 12.4 Cross-device testing
  - Test on small phone
  - Test on large phone
  - Test on tablet
  - Test landscape mode

- [ ] 12.5 Final code review
  - Review all code
  - Check for TODOs
  - Verify documentation
  - Ensure code quality

**Acceptance Criteria**:
- All user flows work
- No runtime errors
- Good performance
- Works on all devices
- Code is production-ready

---

## Task 13: Documentation and Cleanup

**Status**: Not Started  
**Priority**: LOW  
**Estimated Time**: 1 hour

### Subtasks:

- [ ] 13.1 Add code documentation
  - Document all public methods
  - Add class-level documentation
  - Add inline comments for complex logic
  - Follow Dart doc conventions

- [ ] 13.2 Create implementation summary
  - Document what was built
  - Document any deviations
  - Document known issues
  - Document future improvements

- [ ] 13.3 Update README if needed
  - Add new screen documentation
  - Update architecture docs
  - Add screenshots
  - Update dependencies

- [ ] 13.4 Clean up code
  - Remove debug prints (keep essential ones)
  - Remove commented code
  - Remove unused imports
  - Format code

**Acceptance Criteria**:
- Code is well-documented
- Implementation summary exists
- README is updated
- Code is clean

---

## Estimated Total Time: 28-35 hours

## Priority Order:
1. Task 1 (CRITICAL - Data Fix)
2. Task 2 (Core Foundation)
3. Task 3 (Top Rated Section)
4. Task 4 (Reusable Scroller)
5. Task 10 (Performance)
6. Task 5-7 (Additional Sections)
7. Task 8-9 (States)
8. Task 11 (Polish)
9. Task 12 (Testing)
10. Task 13 (Documentation)
