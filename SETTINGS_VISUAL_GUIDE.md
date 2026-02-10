# Settings Feature - Visual Guide

## 🎨 UI Structure Overview

```
Profile Screen
    └─ PREFERENCES Section
        └─ Settings ⚙️ (NEW)
            │
            └─ SettingsScreen
                ├─ NOTIFICATIONS 🔔
                │   ├─ Push Notifications (Master Toggle)
                │   ├─ Booking Updates
                │   ├─ Promotions & Offers
                │   ├─ Payments & Wallet
                │   └─ Technician Status (conditional)
                │
                ├─ ACCOUNT 👤
                │   ├─ Edit Profile →
                │   ├─ Change Phone Number (Coming Soon)
                │   ├─ Email Preferences (Coming Soon)
                │   └─ Language (Coming Soon)
                │
                ├─ PRIVACY & SECURITY 🔒
                │   ├─ App Lock (Coming Soon)
                │   ├─ Logout (Confirmation)
                │   └─ Delete Account (Warning)
                │
                └─ SUPPORT & INFO ℹ️
                    ├─ Help & Support →
                    ├─ Terms & Conditions →
                    ├─ Privacy Policy →
                    └─ About HomeFix (Dialog)
```

---

## 📱 Screen Layouts

### Settings Screen
```
┌─────────────────────────────────┐
│ ← Settings                      │ AppBar
├─────────────────────────────────┤
│                                 │
│ NOTIFICATIONS                   │ Section Header
│ ┌─────────────────────────────┐ │
│ │ 🔔 Push Notifications    ⚪ │ │ Master Toggle
│ ├─────────────────────────────┤ │
│ │ 📅 Booking Updates       ⚪ │ │ Sub-option
│ ├─────────────────────────────┤ │
│ │ 🎁 Promotions & Offers   ⚪ │ │ Sub-option
│ ├─────────────────────────────┤ │
│ │ 💳 Payments & Wallet     ⚪ │ │ Sub-option
│ └─────────────────────────────┘ │
│                                 │
│ ACCOUNT                         │ Section Header
│ ┌─────────────────────────────┐ │
│ │ 👤 Edit Profile           → │ │ Navigation
│ ├─────────────────────────────┤ │
│ │ 📱 Change Phone Number    → │ │ Navigation
│ ├─────────────────────────────┤ │
│ │ 🌐 Language               → │ │ Navigation
│ └─────────────────────────────┘ │
│                                 │
│ PRIVACY & SECURITY              │ Section Header
│ ┌─────────────────────────────┐ │
│ │ 🔒 App Lock              ⚪ │ │ Toggle
│ ├─────────────────────────────┤ │
│ │ 🚪 Logout                 → │ │ Action (Orange)
│ ├─────────────────────────────┤ │
│ │ 🗑️ Delete Account         → │ │ Action (Red)
│ └─────────────────────────────┘ │
│                                 │
│ SUPPORT & INFO                  │ Section Header
│ ┌─────────────────────────────┐ │
│ │ ❓ Help & Support         → │ │ Navigation
│ ├─────────────────────────────┤ │
│ │ 📄 Terms & Conditions     → │ │ Navigation
│ ├─────────────────────────────┤ │
│ │ 🔐 Privacy Policy         → │ │ Navigation
│ ├─────────────────────────────┤ │
│ │ ℹ️ About HomeFix          → │ │ Dialog
│ └─────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

---

## 🎨 Component Styles

### Section Header
```
NOTIFICATIONS
─────────────
Font: Outfit, 12px, w800
Color: Gray (subtitleColor)
Letter Spacing: 1px
Transform: UPPERCASE
Padding: 4px left, 12px bottom
```

### Settings Card
```
┌─────────────────────────────────┐
│ White background                │
│ 24px border radius              │
│ Gray border (shade 100)         │
│ Subtle shadow (2% opacity)      │
└─────────────────────────────────┘
```

### Switch Tile
```
┌─────────────────────────────────┐
│ [Icon] Title              [⚪]  │
│        Subtitle                 │
└─────────────────────────────────┘

Icon Container:
- 10px padding
- 12px border radius
- Primary color with 10% opacity
- Icon: 20px, primary color

Title:
- Outfit, 15px, w700
- Text color (dark)

Subtitle:
- Outfit, 12px, w400
- Subtitle color (gray)

Switch:
- Native adaptive
- Primary color when active
```

### Navigation Tile
```
┌─────────────────────────────────┐
│ [Icon] Title               [→]  │
│        Subtitle                 │
└─────────────────────────────────┘

Same as Switch Tile but with:
- Chevron right icon (gray, 20px)
- Tappable (onTap callback)
```

---

## 🎨 Color Palette

### Primary Actions
```
Icon Background: Primary (10% opacity)
Icon Color: Primary (#6366F1)
Text: Dark (#0F172A)
```

### Warning Actions (Logout)
```
Icon Background: Orange (10% opacity)
Icon Color: Orange
Text: Dark
```

### Destructive Actions (Delete)
```
Icon Background: Red (10% opacity)
Icon Color: Red Accent
Text: Dark
```

### Backgrounds
```
Screen: #FAFAFA (light gray)
Card: White (#FFFFFF)
Border: Gray shade 100
Shadow: Black (2% opacity)
```

---

## 📐 Spacing System

```
Section Spacing:     32px
Card Padding:        20px horizontal, 8px vertical
Icon Container:      10px padding
Icon Size:           20px
Icon Radius:         12px
Card Radius:         24px
Bottom Safe Area:    100px
```

---

## 🔄 State Transitions

### Toggle Animation
```
OFF → ON
─────────
1. User taps switch
2. UI updates immediately (optimistic)
3. Background: Sync to Firestore
4. Success: Keep new state
5. Error: Revert + show SnackBar
```

### Master Toggle Behavior
```
ENABLED → DISABLED
──────────────────
1. Master toggle OFF
2. Hide all sub-options (animated)
3. Sync to Firestore
4. Sub-options remain in their state
5. When re-enabled, sub-options reappear
```

---

## 💬 Dialog Designs

### Coming Soon Dialog
```
┌─────────────────────────────────┐
│ 🚀 Coming Soon                  │
│                                 │
│ [Feature Name] will be          │
│ available in a future update.   │
│ Stay tuned!                     │
│                                 │
│              [GOT IT]           │
└─────────────────────────────────┘
```

### Logout Confirmation
```
┌─────────────────────────────────┐
│ Logout?                         │
│                                 │
│ Are you sure you want to sign   │
│ out of your account?            │
│                                 │
│         [CANCEL]  [LOGOUT]      │
└─────────────────────────────────┘
```

### Delete Account Warning
```
┌─────────────────────────────────┐
│ ⚠️ Delete Account?              │
│                                 │
│ This action cannot be undone.   │
│ All your data, bookings, and    │
│ wallet balance will be          │
│ permanently deleted.            │
│                                 │
│ To proceed, please contact our  │
│ support team.                   │
│                                 │
│ [CANCEL]  [CONTACT SUPPORT]     │
└─────────────────────────────────┘
```

### About Dialog
```
┌─────────────────────────────────┐
│         [🏠 Icon]               │
│                                 │
│         HomeFix                 │
│      Version 1.0.0 (1)          │
│                                 │
│ Your trusted partner for home   │
│ services. We connect you with   │
│ verified professionals for all  │
│ your home maintenance needs.    │
│                                 │
│              [CLOSE]            │
└─────────────────────────────────┘
```

---

## 🎭 Interaction Patterns

### Switch Toggle
```
User Action: Tap switch
Visual: Immediate toggle animation
Backend: Async Firestore update
Feedback: SnackBar on error only
```

### Navigation Tile
```
User Action: Tap tile
Visual: Ripple effect
Backend: None
Feedback: Navigate to new screen
```

### Coming Soon
```
User Action: Tap tile
Visual: Dialog fade in
Backend: None
Feedback: Friendly message
```

### Logout
```
User Action: Tap Logout
Visual: Confirmation dialog
Backend: Firebase Auth signOut
Feedback: Navigate to login
```

### Delete Account
```
User Action: Tap Delete Account
Visual: Warning dialog
Backend: None (requires support)
Feedback: Navigate to support
```

---

## 📊 Responsive Behavior

### Small Screens (< 360px width)
- Text wraps properly
- Icons maintain size
- Padding adjusts
- Scrolling enabled

### Medium Screens (360-600px)
- Standard layout
- Optimal spacing
- Full features

### Large Screens (> 600px)
- Same layout (no tablet optimization yet)
- Centered content
- Maximum width constraint (future)

---

## 🌙 Dark Mode Support

### Current Implementation
- Uses AppTheme constants
- No hardcoded colors
- Opacity-based backgrounds
- Semantic color usage

### Future Enhancement
```dart
// When dark mode is implemented:
backgroundColor: Theme.of(context).scaffoldBackgroundColor
cardColor: Theme.of(context).cardColor
textColor: Theme.of(context).textTheme.bodyLarge?.color
```

---

## ♿ Accessibility

### Current Features
- Semantic labels on all interactive elements
- Native switch controls (platform-specific)
- Readable text sizes (15px title, 12px subtitle)
- High contrast colors
- Clear visual hierarchy

### Future Enhancements
- Screen reader optimization
- Larger touch targets option
- High contrast mode
- Font scaling support

---

## 🎯 User Flows

### Enable Notifications
```
1. Open Profile
2. Tap Settings
3. See NOTIFICATIONS section
4. Master toggle is ON by default
5. Toggle specific notification types
6. Changes save automatically
7. See confirmation (or error)
```

### Edit Profile
```
1. Open Profile
2. Tap Settings
3. Tap "Edit Profile" in ACCOUNT
4. Navigate to EditProfileScreen
5. Make changes
6. Save
7. Return to Settings
```

### Logout
```
1. Open Profile
2. Tap Settings
3. Scroll to PRIVACY & SECURITY
4. Tap "Logout"
5. See confirmation dialog
6. Tap "LOGOUT"
7. Sign out
8. Navigate to login screen
```

### Delete Account
```
1. Open Profile
2. Tap Settings
3. Scroll to PRIVACY & SECURITY
4. Tap "Delete Account"
5. See warning dialog
6. Read warning carefully
7. Tap "CONTACT SUPPORT"
8. Navigate to SupportScreen
9. Submit deletion request
10. Support team processes request
```

---

## 🔍 Visual Hierarchy

```
Level 1: Section Headers (UPPERCASE, small, gray)
Level 2: Card Containers (white, rounded, shadow)
Level 3: Tile Icons (colored background, primary icon)
Level 4: Tile Titles (bold, dark)
Level 5: Tile Subtitles (regular, gray)
Level 6: Trailing Elements (switch/arrow)
```

---

## 📱 Platform Differences

### iOS
- Switch.adaptive uses Cupertino style
- Smooth animations
- Haptic feedback (if implemented)

### Android
- Switch.adaptive uses Material style
- Material ripple effects
- Standard animations

### Web (Future)
- Mouse hover effects
- Keyboard navigation
- Responsive layout

---

**Visual Guide Version**: 1.0.0
**Last Updated**: Current
**Status**: Complete
