# HomeFix - Running on Mobile Device (Wireless)

## Prerequisites
- Android phone with Developer Options enabled
- Phone and PC on same WiFi network
- ADB installed (comes with Flutter)

## Steps to Connect Wirelessly

### Method 1: Using Wireless Debugging (Android 11+)

1. **Enable Wireless Debugging on Phone**
   - Go to Settings > Developer Options
   - Enable "Wireless debugging"
   - Tap "Pair device with pairing code"
   - Note the IP address and port (e.g., 192.168.31.178:34749)

2. **Connect from PC**
   ```bash
   cd apps/customer_app
   adb connect [IP_ADDRESS]:[PORT]
   ```
   Example:
   ```bash
   adb connect 192.168.31.178:34749
   ```

3. **Verify Connection**
   ```bash
   adb devices
   ```
   You should see your device listed.

4. **Run Flutter App**
   ```bash
   flutter run
   ```

### Method 2: Using USB First (Any Android Version)

1. **Connect via USB**
   - Connect phone to PC with USB cable
   - Enable USB debugging on phone

2. **Get Device IP**
   ```bash
   adb shell ip -f inet addr show wlan0
   ```
   Note the IP address (e.g., 192.168.31.178)

3. **Enable TCP/IP Mode**
   ```bash
   adb tcpip 5555
   ```

4. **Disconnect USB and Connect Wirelessly**
   ```bash
   adb connect [IP_ADDRESS]:5555
   ```

5. **Run Flutter App**
   ```bash
   flutter run
   ```

## Quick Connect Script

We've created a helper script for you:

### Windows:
```bash
cd apps/customer_app
connect_device.bat
```

## Troubleshooting

### "Connection Refused" Error
- Ensure phone and PC are on the same WiFi network
- Check if wireless debugging is still enabled on phone
- Try restarting wireless debugging on phone
- Restart ADB server:
  ```bash
  adb kill-server
  adb start-server
  ```

### "Device Offline" Error
- Disconnect and reconnect:
  ```bash
  adb disconnect
  adb connect [IP]:[PORT]
  ```

### Multiple Devices
- List all devices:
  ```bash
  adb devices
  ```
- Specify device when running:
  ```bash
  flutter run -d [DEVICE_ID]
  ```

## Running the App

Once connected, run:

```bash
cd apps/customer_app
flutter run
```

Or for release mode:
```bash
flutter run --release
```

## Features to Test

### Dashboard
- ✅ Professional Reels (video carousel)
- ✅ Cleaning Essentials section
- ✅ Service Spotlight with technician count
- ✅ Banner slider
- ✅ Services grid
- ✅ Categories grid

### Profile
- ✅ Profile header with avatar
- ✅ Wallet balance card
- ✅ My Addresses (Add/Edit/Delete)
- ✅ Become a Technician flow (7 steps)
- ✅ All menu items

### Become a Technician
- ✅ Step 1: Personal details
- ✅ Step 2: Service selection
- ✅ Step 3: Experience
- ✅ Step 4: Document upload
- ✅ Step 5: Address
- ✅ Step 6: Bank details
- ✅ Step 7: Agreement

## Note on Sample Data

The new dashboard features require sample data in Firestore:
- `professional_reels` collection
- `cleaning_essentials` collection
- `service_spotlight` collection

If these collections are empty, the sections will be hidden (no errors).
