# Phone Verification Setup Guide

## Issue: reCAPTCHA Error on Web

The error you're seeing:
```
Failed to initialize reCAPTCHA Enterprise config.
TypeError: Cannot read properties of null (reading 'style')
```

This happens because Firebase Phone Auth on **web** requires additional setup that's different from mobile platforms.

## Solutions

### Option 1: Use Test Phone Numbers (Recommended for Development)

This is the **easiest** way to test phone verification during development without dealing with reCAPTCHA.

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method** → **Phone**
4. Scroll down to **Phone numbers for testing**
5. Add test phone numbers with their verification codes:
   - Phone: `+923001234567` → Code: `123456`
   - Phone: `+923009876543` → Code: `654321`

**Usage:**
- When testing, enter the test phone number (e.g., `03001234567`)
- Firebase won't send a real SMS
- Use the test code you configured (e.g., `123456`)

### Option 2: Configure reCAPTCHA for Production Web

For real phone numbers in production web:

#### Step 1: Register Authorized Domain
1. Go to Firebase Console → **Authentication** → **Settings** → **Authorized domains**
2. Add your domains:
   - `localhost` (for development)
   - Your production domain (e.g., `yoursalon.com`)

#### Step 2: Enable reCAPTCHA
Firebase automatically uses invisible reCAPTCHA, but it requires:
- Valid authorized domains
- User interaction (button click) before calling `verifyPhoneNumber`
- The site must be served over HTTPS in production

#### Step 3: Update Flutter Web Code (Optional - for visible reCAPTCHA)

If you want a visible reCAPTCHA widget, you need to create a container in your HTML and reference it. This is **not required** for invisible reCAPTCHA.

**Note:** The current implementation uses invisible reCAPTCHA automatically.

### Option 3: Test on Mobile/Emulator

Phone verification works seamlessly on Android/iOS without reCAPTCHA:

```bash
# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <ios-device-id>
```

On mobile:
- Real SMS is sent to the phone number
- Auto-retrieval works (especially on Android)
- No reCAPTCHA required

## Current Implementation Notes

- **Platform detection**: Code checks `kIsWeb` to handle web-specific behavior
- **Error handling**: Wrapped in try-catch to show clear error messages
- **Phone format**: Converts Pakistani format `03XXXXXXXXX` to E.164 `+923XXXXXXXXX`

## Recommended Development Workflow

1. **During Development:**
   - Use Firebase test phone numbers (Option 1)
   - OR test on Android/iOS emulator (Option 3)

2. **For Production Web:**
   - Ensure domain is authorized in Firebase
   - Test thoroughly with real phone numbers
   - Monitor Firebase Console for any auth errors

## Troubleshooting

### "Failed to initialize reCAPTCHA Enterprise config"
- This is expected; Firebase falls back to v2 automatically
- Ensure your domain is in authorized domains list

### "TypeError: Cannot read properties of null"
- This happens when no valid reCAPTCHA container exists
- **Solution**: Use test phone numbers OR test on mobile

### "Invalid phone number"
- Ensure format is E.164: `+92XXXXXXXXXX`
- Our code converts `03XXXXXXXXX` → `+923XXXXXXXXX`

### SMS not received
- Check Firebase Console → Authentication → Usage for quota limits
- Verify phone number is correct and can receive SMS
- Try test phone numbers first

## Next Steps

**Immediate fix for testing:**
1. Add test phone numbers in Firebase Console
2. Use those numbers when signing up
3. Enter the test verification code

**For production:**
1. Verify domain authorization
2. Test with real numbers
3. Monitor Firebase quota and billing
