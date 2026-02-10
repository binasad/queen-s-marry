# 🏢 SALON APP - COMPLETE PROJECT DOCUMENTATION
**Comprehensive Guide for Exact Project Recreation**
**Last Updated:** January 20, 2026

---

## 📋 TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Project Structure](#3-project-structure)
4. [UI Design System](#4-ui-design-system)
5. [Authentication & Security](#5-authentication--security)
6. [Firebase Architecture](#6-firebase-architecture)
7. [Core Features](#7-core-features)
8. [Data Models](#8-data-models)
9. [Business Logic](#9-business-logic)
10. [UI Screens & Navigation](#10-ui-screens--navigation)
11. [Implementation Guides](#11-implementation-guides)
12. [Security Rules](#12-security-rules)
13. [Testing Checklist](#13-testing-checklist)
14. [Production Deployment](#14-production-deployment)

---

## 1. PROJECT OVERVIEW

### Purpose
A comprehensive **salon booking application** that enables customers to:
- Book salon appointments online
- Browse services and stylists
- Manage reservations
- Receive notifications
- Pay for services

Admin/Owner features:
- Manage salon services and availability
- View and manage appointments
- Track bookings and revenue
- Manage staff/stylists
- View analytics/dashboard

### Target Platforms
- ✅ Android (API 23-34)
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS

### Key Statistics
- **Framework:** Flutter (Dart ^3.8.1)
- **Backend:** Firebase (Auth, Realtime Database, Firestore, Storage)
- **Current Status:** Core auth & basic UI complete; services & bookings in progress

---

## 2. TECHNOLOGY STACK

### Frontend
```yaml
Flutter: Latest stable version
Dart: ^3.8.1

Key Dependencies:
  - firebase_core: ^4.4.0
  - firebase_auth: latest
  - firebase_database: ^12.0.0
  - cloud_firestore: latest
  - firebase_storage: ^13.0.0
  
UI Libraries:
  - cupertino_icons: ^1.0.8
  - lottie: ^3.3.1 (Animations)
  - crystal_navigation_bar: ^1.0.4 (Bottom nav)
  - iconly: ^1.0.1 (Icons)
  - image_picker: ^1.0.7 (Image selection)
  
Maps & Location:
  - google_maps_flutter: ^2.6.1
  - url_launcher: ^6.2.6
  
Utilities:
  - share_plus: ^10.0.2
  - internet_connection_checker_plus: ^2.7.2
  - intl: ^0.20.2 (Internationalization)
  - google_sign_in: ^6.1.1
```

### Backend
- **Firebase Project:** salon-app-7b3f5
- **Database URL:** https://salon-app-7b3f5-default-rtdb.firebaseio.com
- **Authentication:** Email/Password + Google Sign-In
- **Primary DB:** Realtime Database (with Firestore for some collections)
- **Storage:** Firebase Storage for images

### Build & DevOps
- **Android:** Gradle with Kotlin DSL
- **iOS:** Xcode project setup
- **CI/CD:** (To be implemented)
- **Code Style:** Flutter lints

---

## 3. PROJECT STRUCTURE

```
salon/
├── android/                    # Android native code
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json
│   │   └── src/
│   ├── build.gradle.kts
│   ├── gradlew
│   └── settings.gradle.kts
│
├── ios/                        # iOS native code
│   ├── Runner/
│   ├── Runner.xcodeproj/
│   └── Runner.xcworkspace/
│
├── web/                        # Web build
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│
├── windows/                    # Windows build
│   ├── CMakeLists.txt
│   ├── flutter/
│   └── runner/
│
├── macos/                      # macOS build
│   ├── Flutter/
│   └── Runner/
│
├── linux/                      # Linux build
│   ├── CMakeLists.txt
│   ├── flutter/
│   └── runner/
│
├── lib/                        # 🔴 MAIN DART CODE
│   ├── main.dart              # Entry point + AuthWrapper
│   ├── dev_config.dart        # Dev mode config
│   ├── firebase_options.dart  # Firebase initialization
│   │
│   ├── AppScreens/            # User-facing screens
│   │   ├── about.dart
│   │   ├── ChangePassword.dart
│   │   ├── Contact.dart
│   │   ├── FAQs.dart
│   │   ├── ForgotPassword.dart
│   │   ├── googleMap.dart
│   │   ├── introSlider.dart
│   │   ├── login.dart
│   │   ├── loginOption.dart
│   │   ├── PersonalInfo.dart
│   │   ├── Settings.dart
│   │   ├── ShareWithFriends.dart
│   │   ├── signup.dart
│   │   ├── splash.dart
│   │   ├── VerifyEmailScreen.dart
│   │   ├── VerifyPhoneScreen.dart
│   │   │
│   │   ├── UserScreens/       # Regular user screens
│   │   │   ├── userTabbar.dart
│   │   │   ├── userHome.dart
│   │   │   ├── userDrawer.dart
│   │   │   ├── AppointmentBooking.dart
│   │   │   ├── AppointmentList.dart
│   │   │   ├── UserGallery.dart
│   │   │   └── Course Screens/
│   │   │
│   │   ├── OwnerScreens/      # Admin/Owner screens
│   │   │   ├── OwnerTabbar.dart
│   │   │   ├── OwnerHome.dart
│   │   │   ├── OwnerDrawer.dart
│   │   │   ├── OwnerAppointmentList.dart
│   │   │   ├── OwnerGallery.dart
│   │   │   ├── OwnerDashboard.dart
│   │   │   └── OwnerCourseAppliedList.dart
│   │   │
│   │   ├── Services/          # Service-specific screens
│   │   │   ├── UserHairServices.dart
│   │   │   ├── UserMehndiServices.dart
│   │   │   ├── UserWaxingServices.dart
│   │   │   ├── UserMassageServices.dart
│   │   │   ├── UserMakeupServices.dart
│   │   │   ├── UserFacialServices.dart
│   │   │   ├── PhotoShootServices.dart
│   │   │   ├── userServices.dart
│   │   │   └── servicesdetails.dart
│   │
│   ├── Firebase/              # Firebase utilities
│   │   ├── firebase_auth.dart # Auth helper functions
│   │   └── authServices.dart  # Auth service (legacy)
│   │
│   ├── Manager/               # Business logic layers
│   │   ├── AppointmentManager.dart
│   │   ├── ExpertManager.dart
│   │   ├── NotificationManager.dart
│   │   └── OfferManager.dart
│   │
│   └── Testing/               # Test components
│       ├── crystalNavBar.dart
│       ├── curved_container.dart
│       ├── googleLogin.dart
│       ├── name_emailTest.dart
│       ├── numberTesting.dart
│       └── top_nav_bar.dart
│
├── assets/                    # Static assets
│   ├── slider1.jpg
│   ├── slider2.jpg
│   ├── slider3.jpg
│   ├── logo.png
│   ├── *.json (Lottie animations)
│   └── [service images]
│
├── test/                      # Unit tests
│   └── widget_test.dart
│
├── pubspec.yaml              # Dependencies & project config
├── analysis_options.yaml     # Linting rules
├── firebase.json             # Firebase config
└── [Documentation files]
    ├── README.md
    ├── AUTH_IMPLEMENTATION_SUMMARY.md
    ├── PHONE_VERIFICATION_SETUP.md
    ├── SERVICES_MODULE_DOCUMENTATION.md
    ├── PROJECT_STATUS_SUMMARY.md
    └── COMPLETE_PROJECT_DOCUMENTATION.md (this file)
```

---

## 4. UI DESIGN SYSTEM

### Color Palette

**Primary Colors:**
- **Pink (Primary CTA):** `Color(0xFFFF6CBF)` / `Colors.pink`
  - Used for: Buttons, active tabs, header backgrounds
- **Black:** `Colors.black` with opacity variations
  - `Colors.black.withOpacity(0.5)` - Semi-transparent overlays
  - `Colors.black` - Primary text

**Secondary Colors:**
- **White:** `Colors.white` with opacity variations
  - `.withOpacity(0.3)` - Frosted glass effects
  - Full opacity - Cards, backgrounds
- **Grey:** `Colors.grey` / `Colors.grey[600]`
  - Used for disabled states, secondary text
- **Blue:** `Colors.blue` and variations
  - Info boxes, verification screens

**Status Colors:**
```dart
// Success
const Color kSuccessColor = Color(0xFF4CAF50);

// Error/Warning
const Color kErrorColor = Color(0xFFB71C1C);

// Info
const Color kInfoColor = Colors.blue;
```

### Typography

**Font Family:** Default system fonts (no custom fonts configured)
- Use `Theme.of(context).textTheme.headlineSmall`
- Use `Theme.of(context).textTheme.bodyMedium`
- Use `Theme.of(context).textTheme.bodySmall`

**Font Sizes & Weights:**
```dart
// Headers
fontSize: 28, fontWeight: FontWeight.bold        // Page titles
fontSize: 24, fontWeight: FontWeight.bold        // Section headers
fontSize: 16, fontWeight: FontWeight.bold        // Card titles

// Body
fontSize: 16, fontWeight: FontWeight.w400        // Regular text
fontSize: 14, fontWeight: FontWeight.w400        // Secondary text
fontSize: 12, fontWeight: FontWeight.w300        // Small text

// Special
fontWeight: FontWeight.w500                      // Medium weight
fontStyle: FontStyle.italic                      // Loading messages
```

### Components & Patterns

#### 1. **Buttons**
```dart
// Primary CTA (Full Width)
ElevatedButton(
  onPressed: _onTap,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.pink,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  ),
  child: const Text('Button Text'),
);

// Secondary Button
OutlinedButton(
  onPressed: _onTap,
  child: const Text('Secondary'),
);
```

#### 2. **Text Fields**
```dart
TextFormField(
  decoration: InputDecoration(
    hintText: 'Enter text',
    prefixIcon: Icon(Icons.email),
    suffixIcon: Icon(Icons.check),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
);
```

#### 3. **Cards with Blur Effect**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(15),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
    child: Container(
      color: Colors.white.withOpacity(0.3),
      child: // content
    ),
  ),
);
```

#### 4. **Bottom Navigation with Blur**
```dart
ClipRRect(
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
    child: BottomNavigationBar(
      backgroundColor: Colors.white.withOpacity(0.3),
      selectedItemColor: Colors.pink,
      unselectedItemColor: Colors.grey,
      items: [
        // Bottom nav items
      ],
    ),
  ),
);
```

#### 5. **Image Backgrounds with Overlay**
```dart
Stack(
  fit: StackFit.expand,
  children: [
    Image.asset(
      'assets/slider1.jpg',
      fit: BoxFit.cover,
    ),
    BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(color: Colors.black.withOpacity(0.5)),
    ),
    // Content overlay
  ],
);
```

#### 6. **Progress Indicators**
```dart
LinearProgressIndicator(
  minHeight: 4,
  backgroundColor: Colors.grey[300],
  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6CBF)),
);
```

#### 7. **Animated Dots (Carousel)**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  margin: const EdgeInsets.symmetric(horizontal: 5),
  height: 8,
  width: _currentPage == index ? 16 : 8,
  decoration: BoxDecoration(
    color: _currentPage == index ? Colors.pink : Colors.white70,
    borderRadius: BorderRadius.circular(5),
  ),
);
```

#### 8. **Info Boxes**
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.blue, width: 1),
  ),
  child: Text('Information text'),
);
```

### Icons & Assets

**Icon Library Used:**
- `CupertinoIcons` - iOS-style icons
- `Icons` - Material Design icons
- `Iconly` - Custom icon set

**Common Icons:**
```dart
CupertinoIcons.home       // Home tab
CupertinoIcons.calendar   // Appointments/Calendar
CupertinoIcons.photo      // Gallery
CupertinoIcons.settings   // Settings
Icons.person              // Profile
Icons.menu                // Drawer
Icons.notifications       // Notifications
Icons.email              // Email
Icons.lock               // Password/Security
Icons.phone              // Phone
Icons.location_on        // Location
```

**Animation Assets (Lottie):**
```
assets/profile.json       // Profile icon animation
assets/Bellring.json      // Notification animation
assets/contact.json       // Contact animation
assets/email.json         // Email animation
assets/LocationPin.json   // Location animation
assets/LockUnlockKey.json // Security animation
assets/Password.json      // Password animation
assets/WomanHair.json     // Salon animation
```

---

## 5. AUTHENTICATION & SECURITY

### Authentication Flow Architecture

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Firebase.initializeApp()           │
│  Check for dev-mode auto-login      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  MyApp → AuthWrapper                │
│  (Main entry point)                 │
└────────┬────────────────────────────┘
         │
         ▼
    ┌────────────────┐
    │ Logged In?     │
    └─┬──────────┬───┘
      │NO        │YES
      │          │
      ▼          ▼
   LOGIN    ┌──────────────────┐
   SCREEN   │ Email Verified?  │
            └─┬──────────┬──────┘
              │NO        │YES
              │          │
              ▼          ▼
          VERIFY      LOAD ROLE
          EMAIL      FROM DB
          SCREEN     │
                     ▼
                  ┌──────────┐
                  │ Role     │
                  │ Check    │
                  └─┬──┬─────┘
                    │  │
              ADMIN │  │ USER
                    ▼  ▼
                 [Route to respective home]
```

### Login Implementation

**File:** `lib/AppScreens/login.dart`

**Features:**
1. **Rate Limiting (Brute Force Protection)**
   - 3 failed attempts → 30-second lockout
   - Button disabled during cooldown
   - Countdown timer visible to user
   - Auto-resets after 30 seconds

2. **Input Validation**
   - Email: Regex pattern matching
   - Password: Text field with visibility toggle
   - Form validation before submission

3. **Generic Error Messages (No User Enumeration)**
   - "Invalid email or password." (for both user-not-found AND wrong-password)
   - Prevents email discovery by attackers
   - Real errors logged internally with debugPrint

4. **Flow:**
   ```dart
   _login() async {
     // 1. Check if locked
     if (_isLocked) {
       show "Too many attempts. Try again shortly."
       return
     }
     
     // 2. Validate form
     if (!formValid) return
     
     // 3. Try Firebase Auth
     try {
       UserCredential = await signInWithEmailAndPassword()
       
       // 4. Load role from Realtime DB
       role = await database.child('Users').child(uid).get()
       
       // 5. Route by role
       switch(role):
         case "user": navigate to BottomTabBar()
         case "admin": navigate to OwnerBottomTabBar()
       
       // 6. Reset attempts on success
       _failedAttempts = 0
     } 
     catch (FirebaseAuthException e) {
       // 7. Handle errors
       _failedAttempts++
       if (_failedAttempts >= 3) {
         _isLocked = true
         Timer(30s) → unlock
       }
       show "Invalid email or password."
     }
   }
   ```

### Signup Implementation

**File:** `lib/AppScreens/signup.dart`

**Form Fields (Required):**
```dart
String name              // User full name
String email             // Email address (regex validated)
String password          // Strong password (8+ chars, upper, number, special)
String address           // Street address
String contact           // Phone number (10+ digits)
String gender            // Dropdown: Male/Female/Other
```

**Strong Password Validation:**
```dart
// Must contain:
// ✓ Minimum 8 characters
// ✓ At least 1 uppercase letter (A-Z)
// ✓ At least 1 number (0-9)
// ✓ At least 1 special character (!@#$%^&*)

Example valid: "Welcome@2025"
Example invalid: "welcome2025" (no uppercase, no special char)
```

**Signup Flow (Atomic):**
```dart
_signup() async {
  // 1. Validate form
  if (!formValid) return
  
  setState(() => _isLoading = true)
  
  try {
    // 2. Create user in FirebaseAuth
    UserCredential = await createUserWithEmailAndPassword(email, password)
    User? user = credential.user
    if (user == null) throw Exception("User creation failed")
    
    // 3. Update display name
    await user.updateDisplayName(name)
    await user.reload()
    
    // 4. Send email verification
    await user.sendEmailVerification()
    
    // 5. Save to Realtime Database (with rollback)
    try {
      await ref.child(user.uid).set({
        'name': name,
        'email': email,
        'address': address,
        'contact': contact,
        'gender': gender,
        'createdAt': DateTime.now().toString(),
        'lastLogin': DateTime.now().toString(),
        'role': 'user',  // Hardcoded - no privilege escalation
        'switch': 'user',
        'Profile url': 'https://default-profile-image-url',
      })
    } catch (e) {
      // ROLLBACK: Delete Auth user if DB write fails
      await user.delete()
      rethrow
    }
    
    // 6. Navigate to email verification screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyEmailScreen(email: email),
      ),
    )
  }
  catch (FirebaseAuthException e) {
    // Handle specific Firebase errors
    if (e.code == 'email-already-in-use') {
      show "This email is already registered. Please login instead."
    }
    else if (e.code == 'weak-password') {
      show "Password is too weak."
    }
    else {
      show e.message ?? "Signup failed."
    }
  }
  finally {
    setState(() => _isLoading = false)
  }
}
```

**Database Structure Created:**
```json
{
  "Users": {
    "{uid}": {
      "name": "John Doe",
      "email": "john@example.com",
      "address": "123 Main Street",
      "contact": "03001234567",
      "gender": "Male",
      "createdAt": "2025-01-20T10:30:00.000000",
      "lastLogin": "2025-01-20T10:30:00.000000",
      "role": "user",
      "switch": "user",
      "Profile url": "https://..."
    }
  }
}
```

### Email Verification

**File:** `lib/AppScreens/VerifyEmailScreen.dart`

**Two-Stage Verification Process:**

**Stage 1: Automatic Check (every 3 seconds)**
```dart
checkEmailVerified() async {
  // CRITICAL: Must reload to get latest Firebase state
  await FirebaseAuth.instance.currentUser?.reload()
  
  bool verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false
  
  if (verified) {
    // Navigate to home screen
    Navigator.pushReplacementNamed('/home')
  }
}
```

**Stage 2: Manual Controls**
- **Resend Email Button** - If user missed first verification email
- **Use Different Email** - Logout and try another email account
- **Email Display** - Show user's email for confirmation

**Security Guarantee:**
- Even if app restarts → AuthWrapper re-checks verification status
- Cannot bypass verification by force-restarting
- Unverified users ALWAYS redirected to VerifyEmailScreen

### Forgot Password

**File:** `lib/AppScreens/ForgotPassword.dart` & `lib/Firebase/firebase_auth.dart`

**Try-And-Catch Pattern (No User Enumeration):**
```dart
_resetPassword() async {
  try {
    // Validate email format
    if (!_validateEmail(_emailController.text)) {
      show "Invalid email format"
      return
    }
    
    setState(() => _isLoading = true)
    
    // Try to send reset email
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _emailController.text
    )
    
    // Generic success message (same for existing and non-existing emails)
    show "If account exists, reset link sent to your email"
    
  } catch (FirebaseAuthException e) {
    if (e.code == 'invalid-email') {
      show "Email is invalid"
    }
    else if (e.code == 'too-many-requests') {
      show "Too many attempts, try later"
    }
    else {
      show "An error occurred. Please try again."  // Generic fallback
    }
  }
  finally {
    setState(() => _isLoading = false)
  }
}
```

**Security Features:**
✅ No user enumeration
✅ Rate limiting by Firebase (too-many-requests)
✅ Email validation before attempt
✅ Generic success/failure messages
✅ Loading state during email send

### Dev Mode Configuration

**File:** `lib/main.dart`

**Purpose:** Auto-login for testing without manual auth each time

```dart
// Run with:
// flutter run --dart-define=IS_DEV_MODE=true \
//   --dart-define=DEV_EMAIL=test@example.com \
//   --dart-define=DEV_PASSWORD=Password123!

const bool kIsDevMode = bool.fromEnvironment(
  'IS_DEV_MODE',
  defaultValue: false,
);
const String kDevEmail = String.fromEnvironment('DEV_EMAIL', defaultValue: '');
const String kDevPass = String.fromEnvironment('DEV_PASSWORD', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Dev-mode auto-login (only if no user currently logged in)
  if (kIsDevMode &&
      FirebaseAuth.instance.currentUser == null &&
      kDevEmail.isNotEmpty &&
      kDevPass.isNotEmpty) {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: kDevEmail,
        password: kDevPass,
      );
      debugPrint("Dev Mode: Logged in as $kDevEmail");
    } catch (e) {
      debugPrint("Dev Mode Error: $e");
    }
  }
  
  runApp(const MyApp());
}
```

### AuthWrapper (Main Gate)

**File:** `lib/main.dart`

**Responsibilities:**
1. Check if user is logged in
2. If logged in → Check email verification
3. If verified → Load role from DB
4. Route to appropriate home screen based on role

```dart
class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? role;
  String name = "", email = "", contact = "";
  bool emailVerified = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(user.uid)
        .get();

    if (mounted) {
      setState(() {
        role = snap.child('role').value.toString();
        name = snap.child('name').value.toString();
        email = snap.child('email').value.toString();
        contact = snap.child('contact').value?.toString() ?? "";
      });
      emailVerified = user.emailVerified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in
      return OnboardingScreen();
    }

    if (!user.emailVerified) {
      // Logged in but email NOT verified
      return VerifyEmailScreen(email: user.email ?? '');
    }

    // Logged in and email verified → Route by role
    switch (role) {
      case "admin":
        return OwnerBottomTabBar();
      case "user":
      default:
        return BottomTabBar();
    }
  }
}
```

### Security Patterns Summary

| Pattern | Implementation | Benefit |
|---------|---|---|
| **No User Enumeration** | Generic errors for both user-not-found and wrong-password | Prevents email discovery |
| **Try-And-Catch** | Catch specific errors instead of check-then-act | Prevents timing attacks |
| **Atomic Operations** | Create Auth user → save DB → rollback on failure | No zombie accounts |
| **Rate Limiting** | 3 failures → 30s lockout + Firebase throttling | Prevents brute-force |
| **Email Verification** | Mandatory gate checked on every app launch | Prevents fake emails |
| **Strong Passwords** | 8+ chars, upper, number, special | Prevents weak passwords |
| **Hardcoded Roles** | Role set by backend, never from user input | Prevents privilege escalation |

---

## 6. FIREBASE ARCHITECTURE

### Firebase Project Details

```
Project Name: Salon App
Project ID: salon-app-7b3f5
Database URL: https://salon-app-7b3f5-default-rtdb.firebaseio.com
```

### Database Collections & Structure

#### **Realtime Database (Primary)**

```
salon-app-7b3f5/
│
├── Users/                           # User profiles & settings
│   └── {uid}/
│       ├── name: "John Doe"
│       ├── email: "john@example.com"
│       ├── address: "123 Main St"
│       ├── contact: "03001234567"
│       ├── gender: "Male"
│       ├── createdAt: "2025-01-20T10:30:00"
│       ├── lastLogin: "2025-01-20T10:30:00"
│       ├── role: "user" or "admin"
│       ├── switch: "user" or "admin"  
│       └── Profile url: "https://..."
│
├── Services/                        # Salon services catalog
│   └── {serviceId}/
│       ├── name: "Hair Cutting"
│       ├── category: "Hair"
│       ├── description: "Professional hair cut"
│       ├── basePrice: 500
│       ├── duration: 30
│       ├── available: true
│       └── image: "https://..."
│
├── Appointments/                    # Booking records
│   └── {appointmentId}/
│       ├── userId: "{uid}"
│       ├── serviceId: "{serviceId}"
│       ├── expertId: "{expertId}"
│       ├── date: "2025-02-20"
│       ├── time: "10:00 AM"
│       ├── status: "confirmed" | "reserved" | "cancelled"
│       ├── paymentStatus: "paid" | "unpaid"
│       ├── amount: 500
│       ├── createdAt: "2025-01-20T10:30:00"
│       └── notes: "Customer notes"
│
├── Experts/                         # Stylists/Professionals
│   └── {expertId}/
│       ├── name: "Sarah Khan"
│       ├── specialty: "Hair"
│       ├── phone: "03001234567"
│       ├── rating: 4.5
│       ├── available: true
│       └── image: "https://..."
│
├── Offers/                          # Promotions/Discounts
│   └── {offerId}/
│       ├── title: "Haircut 30% Off"
│       ├── description: "Limited time offer"
│       ├── discount: 30
│       ├── validFrom: "2025-01-20"
│       ├── validTo: "2025-02-20"
│       └── image: "https://..."
│
└── Notifications/                   # User notifications
    └── {userId}/
        └── {notificationId}/
            ├── title: "Appointment confirmed"
            ├── message: "Your appointment is scheduled..."
            ├── timestamp: "2025-01-20T10:30:00"
            ├── type: "appointment" | "offer" | "system"
            └── read: false
```

#### **Firestore (Secondary - Optional)**

Light usage for structured queries:
```
Collections:
- users/ (backup)
- services/ (catalog)
- appointments/ (bookings)
```

### Firebase Storage

**Purpose:** User profile images, service photos, gallery images

**Bucket Structure:**
```
salon-app-7b3f5.appspot.com/
├── user-profiles/
│   └── {uid}/
│       └── profile-picture.jpg
├── service-images/
│   └── {serviceId}/
│       └── service-photo.jpg
└── gallery/
    └── {galleryId}/
        └── photo.jpg
```

---

## 7. CORE FEATURES

### 1. User Management
- ✅ Registration with extended profile
- ✅ Login with rate limiting
- ✅ Email verification
- ✅ Password reset
- ✅ Profile updates
- 🔄 Google Sign-In (configured, not wired)

### 2. Appointment Booking
- Service selection with browsing
- Date/time picker
- Expert/Stylist selection
- Pricing calculation
- 4-hour payment window (pay-later option)
- Status tracking (reserved, confirmed, cancelled)

### 3. Services Management
- Browse services by category:
  - Hair Services
  - Mehndi (Henna)
  - Waxing
  - Massage
  - Makeup
  - Facials
  - Photo Shoots
- Service details with pricing & duration
- Sorting (by name, price, rating)
- Search functionality

### 4. User Dashboard
- Home screen with offers & experts
- Appointment list (upcoming/past)
- Gallery view
- Courses/Training programs
- Settings & profile management
- Notifications
- Contact & Support

### 5. Admin/Owner Dashboard
- Appointment management
- Service management
- Expert/Staff management
- Gallery management
- Course/Training tracking
- Analytics & reporting
- Settings

### 6. Notifications
- Appointment reminders
- Offer notifications
- System messages
- Push notifications (to be implemented)

### 7. Social Features
- Share salon with friends (share_plus)
- Gallery sharing
- Ratings & reviews (to be implemented)

---

## 8. DATA MODELS

### User Model
```dart
class User {
  String uid;
  String name;
  String email;
  String? address;
  String? contact;
  String? gender;
  DateTime createdAt;
  DateTime lastLogin;
  String role;        // "user" or "admin"
  String? profileUrl;
  bool emailVerified;
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'address': address,
    'contact': contact,
    'gender': gender,
    'createdAt': createdAt.toString(),
    'lastLogin': lastLogin.toString(),
    'role': role,
    'Profile url': profileUrl,
  };
  
  factory User.fromMap(String uid, Map<String, dynamic> map) {
    return User(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      address: map['address'],
      contact: map['contact'],
      gender: map['gender'],
      role: map['role'] ?? 'user',
      profileUrl: map['Profile url'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      lastLogin: DateTime.parse(map['lastLogin'] ?? DateTime.now().toString()),
    );
  }
}
```

### Service Model
```dart
class Service {
  String id;
  String name;
  String category;        // Hair, Mehndi, Waxing, etc.
  String description;
  double basePrice;
  int duration;           // in minutes
  bool available;
  String? imageUrl;
  double? rating;
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'description': description,
    'basePrice': basePrice,
    'duration': duration,
    'available': available,
    'imageUrl': imageUrl,
    'rating': rating,
  };
}
```

### Appointment Model
```dart
class Appointment {
  String id;
  String userId;
  String serviceId;
  String? expertId;
  DateTime dateTime;
  String status;          // confirmed, reserved, cancelled
  String paymentStatus;   // paid, unpaid
  double amount;
  DateTime createdAt;
  String? notes;
  
  // For 4-hour rule
  bool get isPastDue => 
    status == 'reserved' && 
    paymentStatus == 'unpaid' &&
    DateTime.now().difference(createdAt).inHours >= 4;
  
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'serviceId': serviceId,
    'expertId': expertId,
    'dateTime': dateTime.toString(),
    'status': status,
    'paymentStatus': paymentStatus,
    'amount': amount,
    'createdAt': createdAt.toString(),
    'notes': notes,
  };
}
```

### Expert Model
```dart
class Expert {
  String id;
  String name;
  String specialty;       // Hair, Mehndi, etc.
  String? phone;
  double rating;
  bool available;
  String? imageUrl;
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'specialty': specialty,
    'phone': phone,
    'rating': rating,
    'available': available,
    'imageUrl': imageUrl,
  };
}
```

### Offer Model
```dart
class Offer {
  String id;
  String title;
  String description;
  double discountPercent;
  DateTime validFrom;
  DateTime validTo;
  String? imageUrl;
  
  bool get isActive => 
    DateTime.now().isAfter(validFrom) &&
    DateTime.now().isBefore(validTo);
  
  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'discountPercent': discountPercent,
    'validFrom': validFrom.toString(),
    'validTo': validTo.toString(),
    'imageUrl': imageUrl,
  };
}
```

---

## 9. BUSINESS LOGIC

### Manager Pattern

The app uses **Manager** classes to centralize business logic:

```dart
// Location: lib/Manager/

// 1. AppointmentManager.dart
class AppointmentManager {
  static List<Appointment> appointments = [];
  
  static void addAppointment(Appointment apt) {
    appointments.add(apt);
  }
  
  static List<Appointment> getUpcomingAppointments() {
    return appointments
      .where((a) => a.dateTime.isAfter(DateTime.now()))
      .toList();
  }
  
  static List<Appointment> getPastAppointments() {
    return appointments
      .where((a) => a.dateTime.isBefore(DateTime.now()))
      .toList();
  }
}

// 2. ExpertManager.dart
class ExpertManager {
  static List<Map<String, String>> experts = [
    {
      'name': 'Sarah Khan',
      'specialty': 'Hair Styling',
      'rating': '4.8',
      'image': 'assets/expert1.jpg',
    },
    // ...
  ];
  
  static List<Map<String, String>> getBySpecialty(String specialty) {
    return experts
      .where((e) => e['specialty']?.toLowerCase() == specialty.toLowerCase())
      .toList();
  }
}

// 3. OfferManager.dart
class OfferManager {
  static List<Map<String, String>> offers = [
    {
      'title': 'Hair Cut 30% Off',
      'discount': '30%',
      'image': 'assets/offer1.jpg',
    },
    // ...
  ];
}

// 4. NotificationManager.dart
class NotificationManager {
  static void sendNotification(String title, String message) {
    // Push notification logic
  }
}
```

### 4-Hour Payment Window Rule

**Purpose:** Prevent no-shows while offering payment flexibility

**Logic:**
1. User books appointment → Can choose "Pay Later"
2. Status: `reserved`, Payment: `unpaid`
3. Created at: current timestamp
4. User has 4 hours to pay at salon
5. If 4 hours pass without payment:
   - Status → `cancelled`
   - Slot released for others
   - Push notification sent to user
6. If user pays within 4 hours:
   - Status → `confirmed`
   - Payment → `paid`
   - Slot secured

---

## 10. UI SCREENS & NAVIGATION

### Screen Hierarchy

```
AuthWrapper (Entry Point)
│
├─ OnboardingScreen (Intro Slider)
│  └─ LoginOption
│     ├─ LoginScreen
│     │  ├─ ForgotPasswordScreen
│     │  └─ SignupScreen
│     └─ VerifyEmailScreen
│
├─ BottomTabBar (User)
│  ├─ UserHome
│  │  ├─ AppointmentBooking
│  │  └─ ServiceDetails
│  ├─ AppointmentList
│  ├─ Gallery
│  ├─ CoursesScreen
│  └─ SettingsScreen
│     ├─ PersonalInfo
│     ├─ ChangePassword
│     ├─ Contact
│     ├─ About
│     ├─ FAQs
│     └─ ShareWithFriends
│
└─ OwnerBottomTabBar (Admin)
   ├─ OwnerHome
   ├─ OwnerAppointmentList
   ├─ OwnerGallery
   ├─ OwnerDashboard
   └─ SettingsScreen
```

### Navigation Routes

```dart
// lib/main.dart

routes: {
  '/home': (ctx) => const AuthWrapper(),
  '/login': (ctx) => OnboardingScreen(),
}

// Navigation patterns:

// 1. Push (Add to stack)
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NextScreen()),
);

// 2. Push Replacement (Replace current)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => NextScreen()),
);

// 3. Push And Remove Until (Clear stack)
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => NextScreen()),
  (route) => false,  // Remove all
);

// 4. Named Navigation
Navigator.pushNamed(context, '/home');
```

### Key Screens

#### **OnboardingScreen (introSlider.dart)**
- 3-page carousel with salon features
- Animated dots indicator
- Skip/Next button
- Navigation to LoginOption

#### **LoginScreen (login.dart)**
- Email & password fields
- Password visibility toggle
- Rate limiting (3 attempts → 30s lock)
- Forgot password link
- Signup link
- Generic error messages

#### **SignupScreen (signup.dart)**
- Form fields: Name, Email, Password, Address, Phone, Gender
- Strong password validation
- Atomic signup with rollback
- Email verification trigger
- Terms & conditions (optional)

#### **VerifyEmailScreen (VerifyEmailScreen.dart)**
- Waiting room interface
- Auto-check every 3 seconds
- Resend email button
- Use different email button
- Email display for confirmation

#### **UserHome (userHome.dart)**
- Welcome greeting with user name
- Location display
- Search bar (search offers & experts)
- Featured offers carousel
- Expert showcase
- Service categories (quick access buttons)
- Quick action buttons

#### **AppointmentBooking (AppointmentBooking.dart)**
- Service selection
- Date picker (with pink theme)
- Time picker (with pink theme)
- Expert/Stylist selection
- Special notes text area
- Payment option selection (Pay online / Pay at salon)
- Booking confirmation button
- Price summary

#### **SettingsScreen (Settings.dart)**
- User profile info
- Change password
- Notification preferences
- Privacy settings
- About
- Contact support
- Logout

---

## 11. IMPLEMENTATION GUIDES

### How to Add a New Service Category

**Steps:**

1. **Create Service Screen** (`lib/AppScreens/Services/User[Service]Services.dart`)
```dart
class [Service]Services extends StatefulWidget {
  @override
  _[Service]ServicesState createState() => _[Service]ServicesState();
}

class _[Service]ServicesState extends State<[Service]Services> {
  List<Map<String, dynamic>> services = [
    {
      'name': 'Service Name',
      'image': 'assets/service-image.jpg',
      'price': 500,
      'duration': '30–45 mins',
      'description': 'Service description...',
    },
    // Add more services
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Service Name')),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (ctx, idx) {
          return ServiceCard(
            service: services[idx],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentBooking(
                    service: services[idx],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

2. **Add to UserHome Navigation**
```dart
// In UserHome, add to service grid:
InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => [Service]Services()),
    );
  },
  child: ServiceCategoryCard(
    name: '[Service Name]',
    icon: Icons.scissors,  // Choose appropriate icon
    image: 'assets/service-image.jpg',
  ),
);
```

3. **Add to Tabbar Menu** (if applicable)
```dart
// In userTabbar.dart or direct navigation
```

---

### How to Connect to Firebase Database

**1. Import Firebase packages:**
```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
```

**2. Get reference:**
```dart
final ref = FirebaseDatabase.instance.ref();
final user = FirebaseAuth.instance.currentUser;
```

**3. Read data:**
```dart
// Single read
final snapshot = await ref.child('Users').child(user!.uid).get();
String name = snapshot.child('name').value.toString();

// Listen for changes (realtime)
ref.child('Appointments').onValue.listen((event) {
  final data = event.snapshot.value as Map<dynamic, dynamic>;
  // Process data
});
```

**4. Write data:**
```dart
// Create
await ref.child('Services').push().set({
  'name': 'Hair Cut',
  'price': 500,
  'available': true,
});

// Update
await ref.child('Users').child(user!.uid).update({
  'lastLogin': DateTime.now().toString(),
});

// Delete
await ref.child('Appointments').child(appointmentId).remove();
```

**5. Error handling:**
```dart
try {
  await ref.child('path').set(data);
} catch (e) {
  debugPrint('Firebase error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

### How to Add Date/Time Picker

```dart
import 'package:flutter/material.dart';

// Date Picker
Future<void> _pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 90)),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6CBF),     // Pink header
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      _selectedDate = picked;
      _dateController.text = "${picked.year}-${picked.month}-${picked.day}";
    });
  }
}

// Time Picker
Future<void> _pickTime() async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6CBF),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      _selectedTime = picked;
      _timeController.text = picked.format(context);
    });
  }
}

// UI
TextField(
  controller: _dateController,
  readOnly: true,
  onTap: _pickDate,
  decoration: InputDecoration(
    hintText: 'Select Date',
    prefixIcon: Icon(Icons.calendar_today),
    border: OutlineInputBorder(),
  ),
);

TextField(
  controller: _timeController,
  readOnly: true,
  onTap: _pickTime,
  decoration: InputDecoration(
    hintText: 'Select Time',
    prefixIcon: Icon(Icons.access_time),
    border: OutlineInputBorder(),
  ),
);
```

---

### How to Create Frosted Glass Effect

```dart
import 'dart:ui';

ClipRRect(
  borderRadius: BorderRadius.circular(15),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
        ),
      ),
      child: // Your content here
    ),
  ),
);
```

---

### How to Add Animations (Lottie)

```dart
import 'package:lottie/lottie.dart';

// Display animation
Lottie.asset(
  'assets/profile.json',
  width: 50,
  height: 50,
  fit: BoxFit.contain,
);

// In suffix of TextFormField
suffixIcon: Padding(
  padding: const EdgeInsets.all(8.0),
  child: Lottie.asset(
    'assets/check.json',
    width: 20,
    height: 20,
  ),
);

// With loop control
Lottie.asset(
  'assets/loading.json',
  width: 100,
  height: 100,
  repeat: true,
  reverse: false,
);
```

---

## 12. SECURITY RULES

### Realtime Database Rules

```json
{
  "rules": {
    "Users": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('Users').child($uid).child('role').val() === 'admin'",
        ".write": "$uid === auth.uid || root.child('Users').child($uid).child('role').val() === 'admin'",
        "role": {
          ".validate": "newData.val() === 'user' || newData.val() === 'admin'"
        },
        "email": {
          ".validate": "newData.isString() && newData.val().matches(/^[^@]+@[^@]+\\.[^@]+$/)"
        }
      }
    },
    "Services": {
      ".read": true,
      "$serviceId": {
        ".write": "root.child('Users').child(auth.uid).child('role').val() === 'admin'",
        "price": {
          ".validate": "newData.isNumber() && newData.val() > 0"
        }
      }
    },
    "Appointments": {
      "$appointmentId": {
        ".read": "$appointmentId.parent().child(auth.uid).exists() || root.child('Users').child(auth.uid).child('role').val() === 'admin'",
        ".write": "auth.uid !== null && (newData.child('userId').val() === auth.uid || root.child('Users').child(auth.uid).child('role').val() === 'admin')",
        ".validate": "newData.child('userId').exists() && newData.child('serviceId').exists() && newData.child('dateTime').exists()"
      }
    }
  }
}
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId || 
                           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Services (public read, admin write)
    match /services/{serviceId} {
      allow read: if true;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Appointments
    match /appointments/{appointmentId} {
      allow read: if resource.data.userId == request.auth.uid || 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow create: if request.auth.uid != null && 
                       request.auth.uid == request.resource.data.userId;
      allow update, delete: if resource.data.userId == request.auth.uid || 
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Firebase Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user-profiles/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
    
    match /service-images/{serviceId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

---

## 13. TESTING CHECKLIST

### Authentication Tests
- [ ] Signup with valid data → User created, email verification sent
- [ ] Signup with existing email → Generic error message
- [ ] Signup with weak password → Validation error before Firebase attempt
- [ ] Signup with invalid phone → Validation error
- [ ] Signup failure on DB write → Auth user deleted (no zombie account)
- [ ] Login with correct credentials → Verified user → Home screen
- [ ] Login with correct credentials → Unverified user → VerifyEmailScreen
- [ ] Login with wrong password 3 times → 30s lockout, button disabled
- [ ] Login attempt during lockout → Generic "Too many attempts" message
- [ ] Forgot password with valid email → Generic success message
- [ ] Forgot password with invalid email → Specific error message
- [ ] Forgot password 5+ times in 1 hour → Rate limited by Firebase
- [ ] Email verification auto-check → 3-second interval
- [ ] Email verification manual resend → New email sent
- [ ] Verification email click → Status updates, AuthWrapper routes correctly
- [ ] App restart while unverified → Forced back to VerifyEmailScreen
- [ ] App restart while verified → Routes to correct home screen

### Navigation Tests
- [ ] OnboardingScreen → LoginOption → LoginScreen
- [ ] OnboardingScreen → Skip to LoginOption
- [ ] LoginScreen → SignupScreen (signup link)
- [ ] LoginScreen → ForgotPassword (forgot link)
- [ ] User login → BottomTabBar (5 tabs visible)
- [ ] Admin login → OwnerBottomTabBar (5 tabs visible)
- [ ] Tab switching → Correct screen displayed
- [ ] Back button → Returns to previous screen (except main tabs)

### UI/UX Tests
- [ ] Colors match spec (Pink: #FF6CBF, Black, White, Grey)
- [ ] Buttons have correct styling (pink background, border radius)
- [ ] Forms validate before submission
- [ ] Loading states show spinners
- [ ] Error messages display in snackbars
- [ ] Date/time pickers have pink theme
- [ ] Animated dots move smoothly in carousel
- [ ] Frosted glass effects visible on cards/navigation
- [ ] Lottie animations play smoothly

### Service Booking Tests
- [ ] Browse services by category
- [ ] Search services by name/specialty
- [ ] Service details show price, duration, description
- [ ] Date picker allows future dates only
- [ ] Time picker shows valid time slots
- [ ] Expert selection updates price if applicable
- [ ] "Pay Online" → Mark as paid, confirmed
- [ ] "Pay at Salon" → Mark as unpaid, reserved
- [ ] 4-hour timer counts down
- [ ] After 4 hours unpaid → Auto-cancel, notification sent

### Database Tests
- [ ] User profile saved correctly in Realtime DB
- [ ] Appointment created with correct structure
- [ ] Role-based access works (user can't see admin data)
- [ ] Atomic operations prevent orphaned records

### Cross-Platform Tests
- [ ] Android app builds and runs
- [ ] iOS app builds and runs
- [ ] Web version loads (without reCAPTCHA errors)
- [ ] Windows app launches
- [ ] Responsive layout on different screen sizes

---

## 14. PRODUCTION DEPLOYMENT

### Pre-Launch Checklist

#### Code
- [ ] Remove all debug prints and dev-mode code
- [ ] Disable verbose logging in production
- [ ] Remove hardcoded test data
- [ ] Enable ProGuard/R8 for Android
- [ ] Code review completed
- [ ] No secrets in code (API keys, test accounts)

#### Firebase
- [ ] Security rules implemented and tested
- [ ] Firebase App Check enabled
- [ ] Email domain whitelist configured
- [ ] Backup enabled
- [ ] Monitoring/alerts set up

#### Authentication
- [ ] Email templates customized
- [ ] Password reset flow tested end-to-end
- [ ] SMTP configured for custom emails (optional)
- [ ] Google Sign-In credentials configured for production domains

#### Performance
- [ ] Database indexed for common queries
- [ ] Images optimized and compressed
- [ ] Lottie animations converted to optimized format
- [ ] Network requests batched where possible

#### Security
- [ ] SSL certificate installed (web)
- [ ] OAuth 2.0 properly configured
- [ ] No personal data in logs
- [ ] Encryption for sensitive fields
- [ ] Rate limiting enabled on all auth endpoints

#### Analytics & Monitoring
- [ ] Firebase Analytics events implemented
- [ ] Crash reporting configured
- [ ] Performance monitoring enabled
- [ ] Error tracking set up

#### Signing & Distribution
- Android:
  - [ ] Signed APK/AAB created with keystore
  - [ ] Keystore backed up securely
  - [ ] App signed with production key
  - [ ] Google Play Console configured
  
- iOS:
  - [ ] Provisioning profiles created
  - [ ] Distribution certificate generated
  - [ ] App signed with production certificate
  - [ ] TestFlight beta configured
  - [ ] App Store Connect configured

#### Testing Before Deploy
- [ ] Full regression test suite passed
- [ ] Perform on real devices (not just emulator)
- [ ] Test all network conditions (WiFi, 4G, edge cases)
- [ ] Test on older OS versions (min SDK version)
- [ ] Offline functionality tested
- [ ] Battery/memory profiling completed

#### Documentation
- [ ] Deployment guide created
- [ ] Rollback procedure documented
- [ ] Support runbook prepared
- [ ] Database backup procedure documented

### Deployment Steps

**Android:**
```bash
# Build AAB for Play Store
flutter build appbundle \
  --release \
  --target-platform android-arm64

# Upload to Google Play Console
# Test in alpha → beta → production
```

**iOS:**
```bash
# Build IPA for App Store
flutter build ios \
  --release

# Archive in Xcode
# Upload to App Store Connect
# Submit for review
```

**Web:**
```bash
# Build for production
flutter build web --release

# Deploy to hosting (Firebase Hosting, Vercel, etc.)
firebase deploy --only hosting
```

### Post-Launch Monitoring

- Monitor crash reports daily
- Check user feedback/reviews
- Track usage analytics
- Monitor Firebase database performance
- Set up alerts for critical errors
- Prepare hotfix procedures

---

## APPENDIX: QUICK REFERENCE

### Common Commands

```bash
# Setup
flutter pub get
flutter pub upgrade

# Build
flutter build apk
flutter build appbundle
flutter build ios
flutter build web --release

# Run
flutter run
flutter run --dart-define=IS_DEV_MODE=true \
  --dart-define=DEV_EMAIL=test@example.com \
  --dart-define=DEV_PASSWORD=Password123!

# Analysis
flutter analyze
dart format lib/

# Test
flutter test
```

### Useful Resources

- Flutter Docs: https://flutter.dev
- Firebase Docs: https://firebase.google.com/docs
- Material Design: https://m3.material.io
- Dart Language: https://dart.dev
- Lottie Documentation: https://lottiefiles.com

### Contact & Support

For questions about this project:
1. Check existing documentation files
2. Review code comments in key files
3. Check Firebase Console for data/logs
4. Enable Firebase Analytics for debugging

---

**Document Version:** 1.0  
**Last Updated:** January 20, 2026  
**Maintained By:** Salon App Development Team  
**Status:** 🟢 Complete (Ready for AI Recreation)

