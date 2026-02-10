# Hardcoded Services Analysis

## Overview

The Flutter app currently has **ALL services hardcoded** in individual Dart files instead of fetching them from the backend API. This analysis documents all hardcoded services and their locations.

---

## 📊 Summary Statistics

- **Total Service Categories**: 7 main categories
- **Total Hardcoded Services**: ~80+ individual services
- **Files with Hardcoded Data**: 10+ files
- **API Service Available**: ✅ `ServiceCatalogService` exists but **NOT USED** for displaying services

---

## 🗂️ Service Categories & Files

### 1. **Main Services Screen** (`userServices.dart`)
**Location**: `salon-app/lib/AppScreens/Services/userServices.dart`

**Hardcoded Categories**:
```dart
List<Map<String, dynamic>> services = [
  {'name': 'Hair Services', 'image': 'assets/FeatherCutting.png', 'screen': HairServices()},
  {'name': 'MakeUp Services', 'image': 'assets/MakeUp.jpg', 'screen': MakeUpServices()},
  {'name': 'Mehndi Services', 'image': 'assets/Mehndi.jpg', 'screen': MehndiServices()},
  {'name': 'Shoot Services', 'image': 'assets/PhotoShoot.jpg', 'screen': ShootServices()},
  {'name': 'Waxing Services', 'image': 'assets/Waxing.jpg', 'screen': WaxingServices()},
  {'name': 'Facial Services', 'image': 'assets/FruitFacial.jpg', 'screen': FacialServices()},
  {'name': 'Massage Services', 'image': 'assets/DeepTissueMassage.jpg', 'screen': MassageServices()},
];
```

**Issue**: Categories are hardcoded, not fetched from `/api/v1/categories`

---

### 2. **Hair Services** (`HairCutting.dart`, `HairColoring.dart`, `HairTreatment.dart`)

#### **Hair Cutting** (`HairCutting.dart`)
**Location**: `salon-app/lib/AppScreens/Services/HairCutting.dart`

**Hardcoded Services** (14 services):
```dart
List<Map<String, dynamic>> hairCutServices = [
  {'name': 'Wispy Haircut', 'price': 2500, 'duration': '40 mins', ...},
  {'name': 'Long Layers Haircut', 'price': 1500, 'duration': '45 mins', ...},
  {'name': 'Bob Haircut', 'price': 2000, 'duration': '35 mins', ...},
  {'name': 'Pixie Haircut', 'price': 3000, 'duration': '40 mins', ...},
  {'name': 'Bangs Haircut', 'price': 2500, 'duration': '25 mins', ...},
  {'name': 'Butterfly Haircut', 'price': 2000, 'duration': '50 mins', ...},
  {'name': 'Wolf Haircut', 'price': 1500, 'duration': '50 mins', ...},
  {'name': 'Blunt Haircut', 'price': 1500, 'duration': '30 mins', ...},
  {'name': 'Baby Bangs', 'price': 1500, 'duration': '20 mins', ...},
  {'name': 'Baby Cutting', 'price': 1500, 'duration': '25 mins', ...},
  {'name': 'Feather Haircut', 'price': 2500, 'duration': '45 mins', ...},
  {'name': 'Wash/ Blow dry', 'price': 1500, 'duration': '35 mins', ...},
  {'name': 'Ironing/Straightening', 'price': 1000, 'duration': '45 mins', ...},
  {'name': 'Curls/ Waves', 'price': 2000, 'duration': '45 mins', ...},
];
```

#### **Hair Coloring** (`HairColoring.dart`)
**Location**: `salon-app/lib/AppScreens/Services/HairColoring.dart`

**Hardcoded Services** (7 services):
```dart
List<Map<String, dynamic>> hairColorServices = [
  {'name': 'Root Touch-up', 'price': 2500, 'duration': '40 mins', ...},
  {'name': 'One Tone Dye', 'price': 5000, 'duration': '60 mins', ...},
  {'name': 'Color Cut Down', 'price': 6500, 'duration': '50 mins', ...},
  {'name': 'Highlights (Full/Half)', 'price': 8000, 'duration': '90 mins', ...},
  {'name': 'Cap Hair Streak', 'price': 12000, 'duration': '75 mins', ...},
  {'name': 'Per Foil Highlights (Shoulder)', 'price': 8000, 'duration': '100 mins', ...},
  {'name': 'Per Foil Highlights (Full)', 'price': 12000, 'duration': '130 mins', ...},
];
```

#### **Hair Treatment** (`HairTreatment.dart`)
**Location**: `salon-app/lib/AppScreens/Services/HairTreatment.dart`

**Hardcoded Services** (8 services):
```dart
List<Map<String, dynamic>> hairTreatmentServices = [
  {'name': 'Hair Spa', 'price': 2500, 'duration': '60 mins', ...},
  {'name': 'Deep Conditioning + Blowdry', 'price': 1500, 'duration': '45 mins', ...},
  {'name': 'Keratin Treatment', 'price': 12000, 'duration': '2–3 hrs', ...},
  {'name': 'Protein Treatment', 'price': 18000, 'duration': '90 mins', ...},
  {'name': 'Extenso Treatment (6 Sessions)', 'price': 45000, 'duration': '2–3 hrs per session', ...},
  {'name': 'Herbal Treatment', 'price': 4000, 'duration': '60 mins', ...},
  {'name': 'Smoothening / Rebounding', 'price': 3500, 'duration': '3–4 hrs', ...},
  {'name': 'Scalp Treatment', 'price': 6500, 'duration': '50 mins', ...},
];
```

**Total Hair Services**: **29 services**

---

### 3. **Makeup Services** (`UserMakeupServices.dart`)
**Location**: `salon-app/lib/AppScreens/Services/UserMakeupServices.dart`

**Hardcoded Services** (9 services):
```dart
List<Map<String, dynamic>> makeUpServices = [
  {'name': 'Party Makeup (Pakistani)', 'price': 7000, 'duration': '60 mins', ...},
  {'name': 'Turkish Party Look', 'price': 5000, 'duration': '45 mins', ...},
  {'name': 'Smokey & Glam Look', 'price': 15000, 'duration': '75 mins', ...},
  {'name': 'Engagement Look', 'price': 15000, 'duration': '90 mins', ...},
  {'name': 'Nikkah Signature Makeup', 'price': 20000, 'duration': '2 hrs', ...},
  {'name': 'Barat Signature Makeup', 'price': 35000, 'duration': '3 hrs', ...},
  {'name': 'Walima Signature Makeup', 'price': 30000, 'duration': '2 hrs', ...},
  {'name': 'Full Bridal Package', 'price': 45000, 'duration': 'Varies (2–3 hrs per event)', ...},
  {'name': 'Sangeet Makeup', 'price': 10000, 'duration': '90 mins', ...},
];
```

---

### 4. **Mehndi Services** (`UserMehndiServices.dart`)
**Location**: `salon-app/lib/AppScreens/Services/UserMehndiServices.dart`

**Hardcoded Services** (5 services):
```dart
List<Map<String, dynamic>> mehndiServices = [
  {'name': 'Hands', 'price': 500, 'duration': '30–45 mins', ...},
  {'name': 'Half Arm', 'price': 1000, 'duration': '60–90 mins', ...},
  {'name': 'Full Arm', 'price': 1500, 'duration': '2–3 hrs', ...},
  {'name': 'Foot Mehndi', 'price': 500, 'duration': '45–60 mins', ...},
  {'name': 'Bridal Mehndi', 'price': 7500, 'duration': '4–6 hrs', ...},
];
```

---

### 5. **Photo Shoot Services** (`PhotoShootServices.dart`)
**Location**: `salon-app/lib/AppScreens/Services/PhotoShootServices.dart`

**Hardcoded Services** (3 services):
```dart
List<Map<String, dynamic>> shootServices = [
  {'name': 'Bridal Shoot', 'price': 15000, 'duration': '2–3 hrs', ...},
  {'name': 'Couple Shoot', 'price': 25000, 'duration': '3–4 hrs', ...},
  {'name': 'Outdoor Shoot', 'price': 40000, 'duration': '4–6 hrs', ...},
];
```

---

### 6. **Waxing Services** (`UserWaxingServices.dart`)
**Location**: `salon-app/lib/AppScreens/Services/UserWaxingServices.dart`

**Hardcoded Services** (8 services):
```dart
List<Map<String, dynamic>> waxingServices = [
  {'name': 'Full Arms', 'price': 800, 'duration': '20–25 mins', ...},
  {'name': 'Full Legs', 'price': 1400, 'duration': '30–40 mins', ...},
  {'name': 'Underarms', 'price': 400, 'duration': '10–15 mins', ...},
  {'name': 'Full Body Waxing', 'price': 8500, 'duration': '90–120 mins', ...},
  {'name': 'Upper Lips', 'price': 200, 'duration': '5–10 mins', ...},
  {'name': 'Chin', 'price': 150, 'duration': '5–10 mins', ...},
  {'name': 'Forehead', 'price': 350, 'duration': '10–15 mins', ...},
  {'name': 'Full Face', 'price': 1000, 'duration': '25–30 mins', ...},
];
```

---

### 7. **Facial Services** (`FacialService.dart`, `FacialTreatment.dart`)
**Location**: `salon-app/lib/AppScreens/Services/FacialService.dart`

**Hardcoded Services** (7 services):
```dart
List<Map<String, dynamic>> facialService = [
  {'name': 'CleanUp', 'price': 1200, 'duration': '25 mins', ...},
  {'name': 'Fruit Facial', 'price': 3500, 'duration': '40 mins', ...},
  {'name': 'Glow Facial', 'price': 1500, 'duration': '35 mins', ...},
  {'name': 'Gold/Diamond/Pearl Facial', 'price': 4500, 'duration': '50 mins', ...},
  {'name': 'Brightening Facial', 'price': 3500, 'duration': '55 mins', ...},
  {'name': 'Skin Whitening / De-tan', 'price': 4500, 'duration': '60 mins', ...},
  {'name': 'Vitamin C Facial', 'price': 2500, 'duration': '65 mins', ...},
];
```

**Note**: There's also `FacialTreatment.dart` which may have additional services.

---

### 8. **Massage Services** (`UserMassageServices.dart`)
**Location**: `salon-app/lib/AppScreens/Services/UserMassageServices.dart`

**Hardcoded Services** (9 services):
```dart
List<Map<String, dynamic>> massageServices = [
  {'name': 'Body Massage (Full)', 'price': 3500, 'duration': '60–90 mins', ...},
  {'name': 'Swedish Massage', 'price': 6500, 'duration': '60 mins', ...},
  {'name': 'Deep Tissue', 'price': 4500, 'duration': '60 mins', ...},
  {'name': 'Aromatherapy (Medical Therapy)', 'price': 9500, 'duration': '45 mins', ...},
  {'name': 'Therapeutic Massage (Fat Dissolving)', 'price': 12500, 'duration': '45–60 mins', ...},
  {'name': 'Scalp Massage', 'price': 1000, 'duration': '20–30 mins', ...},
  {'name': 'Neck & Shoulder Relief', 'price': 1500, 'duration': '30–45 mins', ...},
  {'name': 'Relaxing Foot Massage', 'price': 1000, 'duration': '30–45 mins', ...},
  {'name': 'Stress Relief Session', 'price': 2500, 'duration': '20–40 mins', ...},
];
```

---

## 📋 Complete Service Count

| Category | File | Service Count |
|----------|------|---------------|
| Hair Cutting | `HairCutting.dart` | 14 |
| Hair Coloring | `HairColoring.dart` | 7 |
| Hair Treatment | `HairTreatment.dart` | 8 |
| Makeup | `UserMakeupServices.dart` | 9 |
| Mehndi | `UserMehndiServices.dart` | 5 |
| Photo Shoot | `PhotoShootServices.dart` | 3 |
| Waxing | `UserWaxingServices.dart` | 8 |
| Facial | `FacialService.dart` | 7 |
| Massage | `UserMassageServices.dart` | 9 |
| **TOTAL** | | **~70+ services** |

---

## ⚠️ Issues Identified

### 1. **No API Integration**
- ✅ Backend API exists: `GET /api/v1/services`
- ✅ `ServiceCatalogService` exists with `getServices()` method
- ❌ **NOT USED** - All screens use hardcoded lists instead

### 2. **Data Duplication**
- Services are hardcoded in Flutter app
- Services can be created via backend API (`POST /api/v1/services`)
- **Problem**: Services created via API won't appear in app (hardcoded data takes precedence)

### 3. **Maintenance Nightmare**
- To add/update/delete a service, you must:
  1. Update hardcoded list in Dart file
  2. Rebuild and redeploy the app
- **Should be**: Update in admin panel → automatically appears in app

### 4. **No Dynamic Categories**
- Categories are hardcoded in `userServices.dart`
- Backend has `/api/v1/categories` endpoint
- **Not used** - categories can't be managed dynamically

### 5. **Inconsistent Data Structure**
- Hardcoded services use: `{'name', 'price', 'duration', 'description', 'image'}`
- Backend API returns: `{id, name, price, duration, description, image_url, category_id, ...}`
- **Mismatch**: Hardcoded data doesn't have `id` or `category_id`

### 6. **No Filtering/Search**
- Backend API supports: `categoryId`, `minPrice`, `maxPrice`, `search` filters
- Hardcoded lists don't support these features

---

## 🔧 Solution: Migration Plan

### Phase 1: Replace Hardcoded Categories
**File**: `userServices.dart`
- Replace hardcoded categories list with API call to `GET /api/v1/categories`
- Use `ServiceCatalogService.getCategories()`

### Phase 2: Replace Hardcoded Services
**Files**: All service screen files
- Replace hardcoded service lists with API calls
- Use `ServiceCatalogService.getServices(categoryId: ...)`
- Handle loading states and errors

### Phase 3: Update Service Detail Screens
**Files**: `ServiceDetailScreen` classes
- Update to use service `id` from API
- Fetch service details via `ServiceCatalogService.getServiceById(id)`
- Handle related services from API

### Phase 4: Remove Hardcoded Data
- Delete all hardcoded service lists
- Keep only UI components and API integration

---

## 📝 Example: Current vs. Proposed

### **Current (Hardcoded)**
```dart
// HairCutting.dart
List<Map<String, dynamic>> hairCutServices = [
  {'name': 'Wispy Haircut', 'price': 2500, ...},
  // ... 13 more hardcoded services
];

@override
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: hairCutServices.length,
    itemBuilder: (context, index) {
      final service = hairCutServices[index];
      // Display service
    },
  );
}
```

### **Proposed (API-Based)**
```dart
// HairCutting.dart
class HairCutScreen extends StatefulWidget {
  final String categoryId; // Pass category ID
  // ...
}

class _HairCutScreenState extends State<HairCutScreen> {
  List<Map<String, dynamic>> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final data = await ServiceCatalogService().getServices(
        categoryId: widget.categoryId,
      );
      setState(() {
        services = data['services'] as List;
        isLoading = false;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        // Display service from API
      },
    );
  }
}
```

---

## 🎯 Benefits of Migration

1. **Dynamic Updates**: Services can be added/updated via admin panel without app update
2. **Consistency**: Single source of truth (backend database)
3. **Filtering**: Support for search, price range, category filters
4. **Scalability**: Easy to add new categories/services
5. **Maintenance**: Update once in database, appears everywhere
6. **Real-time**: Changes reflect immediately (after refresh)

---

## 📍 Files to Update

### High Priority (Core Service Screens)
1. `salon-app/lib/AppScreens/Services/userServices.dart` - Main categories
2. `salon-app/lib/AppScreens/Services/HairCutting.dart` - Hair cutting services
3. `salon-app/lib/AppScreens/Services/UserMakeupServices.dart` - Makeup services
4. `salon-app/lib/AppScreens/Services/UserMassageServices.dart` - Massage services
5. `salon-app/lib/AppScreens/Services/UserMehndiServices.dart` - Mehndi services
6. `salon-app/lib/AppScreens/Services/UserWaxingServices.dart` - Waxing services
7. `salon-app/lib/AppScreens/Services/FacialService.dart` - Facial services
8. `salon-app/lib/AppScreens/Services/PhotoShootServices.dart` - Photo shoot services
9. `salon-app/lib/AppScreens/Services/HairColoring.dart` - Hair coloring
10. `salon-app/lib/AppScreens/Services/HairTreatment.dart` - Hair treatment

### Medium Priority (Detail Screens)
- All `ServiceDetailScreen` classes need to use service `id` from API

---

## ✅ Next Steps

1. **Create service categories in backend** matching the 7 hardcoded categories
2. **Migrate services to database** (create via API or SQL script)
3. **Update Flutter screens** to fetch from API instead of hardcoded lists
4. **Test thoroughly** to ensure all services display correctly
5. **Remove hardcoded data** once migration is complete

---

## 📊 Current State Summary

- **Backend**: ✅ Fully functional API for services
- **Flutter Service**: ✅ `ServiceCatalogService` exists with all methods
- **UI Integration**: ❌ **NOT USED** - All screens use hardcoded data
- **Result**: Services created via API won't appear in the app

**Recommendation**: Migrate to API-based service loading as soon as possible to enable dynamic service management.
