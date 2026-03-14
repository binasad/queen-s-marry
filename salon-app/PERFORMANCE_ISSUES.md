# Performance & Lag Vulnerabilities Report

Analysis of the Queens Saloon salon app for issues that can cause slowness or lag.

---

## 1. **Debug `print()` Statements in Production** (High Impact)

**Location:** Multiple service files  
**Impact:** `print()` blocks the main isolate and can cause noticeable lag when many logs fire (e.g. during API calls, auth flow).

| File | Count |
|------|-------|
| `auth_service.dart` | ~25 prints |
| `user_service.dart` | 4 prints |
| `course_service.dart` | 5 prints |
| `service_catalog_service.dart` | 6 prints |
| `support_ticket_service.dart` | 6 prints |
| `push_notification_service.dart` | 10 prints |
| `services_provider.dart` | 3 prints |
| Others | Various |

**Fix:** Replace with `debugPrint()` (stripped in release) or use a proper logging package (e.g. `logger`) with log levels.

---

## 2. **`Image.network` Without Caching** (High Impact)

**Location:**
- `OwnerHome.dart` line 332 – profile avatar
- `userServices.dart` line 300 – offer/category card images

**Impact:** Every rebuild or scroll re-downloads images. No disk/memory cache → repeated network calls and UI jank.

**Fix:** Use `CachedImageWidget` or `CachedNetworkImage` instead of `Image.network`.

---

## 3. **Debouncer Not Disposed** (Medium Impact – Memory Leak)

**Location:** `userHome.dart`  
**Issue:** `_searchDebouncer` is created but never disposed. It holds a `Timer` that can fire after the widget is disposed.

```dart
// userHome.dart - dispose() does NOT call:
_searchDebouncer.dispose();
```

**Fix:** Add `_searchDebouncer.dispose()` in `dispose()`.

---

## 4. **PageController Listener Causing setState During Scroll** (Medium Impact)

**Location:** `userHome.dart` lines 114–119

**Issue:** `_offerPageController.addListener()` calls `setState()` when the page index changes. During fast swiping, this can trigger multiple rebuilds.

**Fix:** Throttle or use `PageController`'s `page` only when needed (e.g. via `AnimatedBuilder` or `ListenableBuilder` scoped to the indicator widget instead of the whole screen).

---

## 5. **Excessive API Calls on Init** (Medium Impact)

**Location:** `services_provider.dart` – `ServicesNotifier` constructor  
**Issue:** Constructor calls both `_loadCategoriesFromCache()` and `loadCategories()` (API). Combined with `UserHome._loadAllData()` which calls `loadUserData()`, `loadOffers()`, `loadExperts()`, and `loadCategories()` – many parallel requests on app start.

**Impact:** Network congestion, possible timeouts, and UI waiting on multiple endpoints.

**Fix:** Coordinate loading (e.g. load cache first, then refresh in background). Avoid duplicate category loads from different entry points.

---

## 6. **servicesdetails.dart – 4 Parallel API Calls in initState** (Medium Impact)

**Location:** `ServiceDetailedScreen` `initState()`  
**Issue:** Starts 4 async calls at once:
- `_loadRelatedServices()`
- `_loadReviews()`
- `_loadFavoriteStatus()`
- `_loadApplicableOffers()`

**Impact:** Each triggers `setState()` when done, causing multiple full rebuilds in quick succession.

**Fix:** Batch where possible, or use a single loading state and one `setState` when all complete.

---

## 7. **GridView.count in OwnerDashboard** (Low–Medium Impact)

**Location:** `OwnerDashboard.dart` line 64  
**Issue:** `GridView.count` creates all children at once instead of lazily.

**Fix:** Use `GridView.builder` for lazy building when item count can be large.

---

## 8. **Missing `const` Constructors** (Low Impact)

**Impact:** Unnecessary widget rebuilds when parent rebuilds.

**Fix:** Add `const` to widgets where possible (e.g. `const SizedBox()`, `const Text()`, `const Icon()`).

---

## 9. **Shimmer Placeholder on Every Image** (Low Impact)

**Location:** `cached_image.dart`  
**Issue:** `Shimmer.fromColors` creates an animation for each image placeholder. Many images on screen = many simultaneous shimmers.

**Fix:** Consider a static grey placeholder for list items, or limit shimmer to hero/featured images only.

---

## 10. **WebSocket Reconnection / Multiple Listeners** (Low–Medium Impact)

**Location:** `userTabbar.dart`, `userHome.dart`, `userServices.dart`  
**Issue:** Multiple screens subscribe to WebSocket streams. If reconnection logic is aggressive, it can cause repeated `loadOffers(forceRefresh: true)` and similar calls.

**Fix:** Ensure WebSocket reconnects are debounced and that listeners are properly cancelled in `dispose()`.

---

## Summary – Priority Fixes

| Priority | Issue | File(s) | Effort |
|----------|-------|---------|--------|
| **P0** | Remove/replace `print()` with `debugPrint` | Services, providers | Low |
| **P0** | Replace `Image.network` with `CachedImageWidget` | OwnerHome, userServices | Low |
| **P1** | Dispose `Debouncer` in userHome | userHome.dart | Low |
| **P1** | Throttle PageController listener | userHome.dart | Medium |
| **P2** | Consolidate initState API calls in servicesdetails | servicesdetails.dart | Medium |
| **P2** | Use GridView.builder in OwnerDashboard | OwnerDashboard.dart | Low |
| **P3** | Add const where possible | App-wide | Low |
