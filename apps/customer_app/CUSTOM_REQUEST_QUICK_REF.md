# Custom Request Feature - Quick Reference

## 📁 File Structure

```
lib/features/custom_request/
└── presentation/
    ├── custom_request_screen.dart      (Main screen - 100 lines)
    ├── request_form.dart               (Form widget - 180 lines)
    ├── category_selector.dart          (Category chips - 40 lines)
    └── image_picker_widget.dart        (Image picker - 100 lines)
```

## 🔧 Key Components

### CustomRequestScreen
- Entry point for the feature
- Manages form state and submission
- Handles image picking
- Shows success dialog

### RequestForm
- Reusable form component
- All form fields in one place
- Sticky submit button
- Form validation

### CategorySelector
- Horizontal scrollable chips
- 5 categories: Electrical, Plumbing, AC Repair, Cleaning, Other
- Active/inactive styling

### ImagePickerWidget
- Camera/Gallery picker
- Max 3 images
- Image preview with delete
- Add more button

## 📋 Form Fields

1. **Service Title** (Required)
   - Text input
   - Example: "AC gas refill needed"

2. **Description** (Required)
   - Multiline text (4 lines)
   - Example: "AC not cooling properly"

3. **Category** (Required)
   - Chip selector
   - Options: Electrical, Plumbing, AC Repair, Cleaning, Other

4. **Preferred Date** (Required)
   - Date picker
   - Range: Today to 90 days ahead

5. **Preferred Time** (Required)
   - Time picker
   - Any time of day

6. **Budget** (Optional)
   - Number input
   - Currency: ₹

7. **Images** (Optional)
   - Up to 3 images
   - Camera or Gallery

## 🔄 Data Flow

```
User Input
    ↓
Form Validation
    ↓
Image Picking (Optional)
    ↓
Submit Button Click
    ↓
Create Firestore Document
    ↓
Success Dialog
    ↓
Navigate Back
```

## 📊 Firestore Document

```json
{
  "customerId": "user_uid",
  "title": "string",
  "description": "string",
  "category": "string",
  "preferredDate": "YYYY-MM-DD",
  "preferredTime": "HH:MM",
  "budget": number or null,
  "images": [],
  "status": "pending_admin_review",
  "createdAt": timestamp
}
```

## 🎨 UI/UX

- Modern rounded corners (12-14px)
- Primary color for active states
- Accent color for secondary elements
- Proper spacing (8px, 12px, 16px, 24px)
- Sticky bottom button
- Loading state during submission
- Success confirmation

## ✅ Validation Rules

- Title: Required, non-empty
- Description: Required, non-empty
- Category: Required (default: Electrical)
- Date: Required
- Time: Required
- Budget: Optional, numeric if provided
- Images: Optional, max 3

## 🚀 Integration

### Import
```dart
import 'package:customer_app/features/custom_request/presentation/custom_request_screen.dart';
```

### Navigate
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CustomRequestScreen()),
);
```

### Add to Home Screen
```dart
// Add a card/button with:
// Title: "Can't find your service?"
// Button: "Request Custom Service"
// onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomRequestScreen()))
```

## 🔐 Security Features

✅ Only authenticated users can submit
✅ Customer ID auto-captured from auth
✅ Status always "pending_admin_review"
✅ No direct technician assignment
✅ Firestore rules enforce customer ownership

## 📱 Responsive Design

- Works on all screen sizes
- Horizontal scrolling for categories
- Flexible date/time pickers
- Adaptive image grid

## 🐛 Error Handling

- Form validation errors shown inline
- Firestore errors shown as snackbars
- Loading overlay during submission
- Graceful error recovery

## 💾 State Management

- Local state with setState
- No external providers needed
- Form key for validation
- Controllers for text inputs

## 🎯 Next Steps

1. Add entry point on Home screen
2. Implement admin review panel
3. Add image upload to Firebase Storage
4. Create notification system
5. Add technician assignment workflow
