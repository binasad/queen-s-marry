# Services Module - Firebase Backend & Dart Business Logic

## Overview
The Services Module manages the salon's service catalog, including service categories, individual services, pricing, availability, and bookings. This document outlines the complete architecture for implementing Firebase backend logic and Dart business logic.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Appointment Booking Lifecycle - 4-Hour Rule](#appointment-booking-lifecycle---4-hour-rule)
3. [Firebase Database Structure](#firebase-database-structure)
4. [Data Models (Dart)](#data-models-dart)
5. [Firebase Service Layer](#firebase-service-layer)
6. [Business Logic Layer (Managers)](#business-logic-layer-managers)
7. [Background Jobs & Auto-Cancellation](#background-jobs--auto-cancellation)
8. [UI Integration](#ui-integration)
9. [Security Rules](#security-rules)
10. [Best Practices](#best-practices)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                         │
│  (ServicesScreen, ServiceDetails, BookingForm)     │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│              Business Logic Layer                    │
│  (ServiceManager, CategoryManager, BookingManager)  │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│           Firebase Service Layer                     │
│      (FirebaseServiceRepository)                     │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│              Firebase Backend                        │
│  (Firestore Collections: services, bookings, etc.)  │
└─────────────────────────────────────────────────────┘
```

---

## Appointment Booking Lifecycle - 4-Hour Rule

### Overview
To prevent no-shows while offering payment flexibility, we implement a **strict 4-hour time window** for unpaid bookings.

### Payment Options

#### Option A: Pay Full Online
- User pays immediately during booking
- Appointment status: `confirmed`
- Payment status: `paid`
- **No expiration** - appointment is secured

#### Option B: Pay at Salon (Pay Later)
- User reserves the slot without immediate payment
- Appointment status: `reserved`
- Payment status: `unpaid`
- **4-hour window** starts immediately

### The 4-Hour Window Logic

```
Booking Created
      ↓
   created_at timestamp recorded
      ↓
[4-Hour Window Starts]
      ↓
   Option 1: User pays at salon within 4 hours
      ↓
   Receptionist marks as "Paid"
      ↓
   Status: reserved → confirmed
   Payment: unpaid → paid
      ↓
   ✅ Appointment Secured

      OR

   Option 2: 4 hours pass without payment
      ↓
   Background Job Detects Expiration
      ↓
   Status: reserved → cancelled
   Reason: "Reservation expired (4-hour limit)"
      ↓
   Send Push Notification to User
      ↓
   ❌ Slot Released for Other Customers
```

### Business Rules

1. **Immediate Confirmation**:
   - Online payments bypass the 4-hour rule
   - Status set to `confirmed` instantly

2. **4-Hour Countdown**:
   - Starts at `created_at` timestamp
   - Calculated as: `current_time - created_at >= 4 hours`

3. **Auto-Cancellation**:
   - Background job runs every **10 minutes**
   - Finds: `status = 'reserved' AND payment_status = 'unpaid' AND created_at < (now - 4 hours)`
   - Action: Set status to `cancelled`, add cancellation reason

4. **In-Person Payment**:
   - Admin/Receptionist can mark reservation as paid
   - Changes: `status → confirmed`, `payment_status → paid`
   - Records `paid_at` timestamp

5. **Grace Period**:
   - None - strictly 4 hours from creation
   - Users receive reminder notifications at 3 hours

### User Experience Flow

**Scenario 1: Online Payment (Happy Path)**
```
User books service → Selects "Pay Now" → Payment Success 
→ Status: confirmed → Receives confirmation email/SMS
```

**Scenario 2: Pay at Salon (Within 4 Hours)**
```
User books service → Selects "Pay Later" → Status: reserved 
→ Visits salon within 4 hours → Receptionist marks paid 
→ Status: confirmed → Appointment secured
```

**Scenario 3: Pay at Salon (Exceeds 4 Hours)**
```
User books service → Selects "Pay Later" → Status: reserved 
→ 4 hours pass → Auto-cancelled by system 
→ Push notification sent → User must rebook
```

### Notifications Timeline

| Time | Event | Notification |
|------|-------|-------------|
| 0 min | Booking created (Pay Later) | "Reservation confirmed! Please visit salon within 4 hours to complete payment." |
| 3 hours | Reminder | "⏰ Reminder: You have 1 hour left to complete payment at the salon." |
| 4 hours | Auto-cancelled | "❌ Your reservation has expired due to non-payment. Please rebook if needed." |

### Admin/Receptionist Actions

**Mark as Paid** (Mobile/Web Admin Panel):
1. Navigate to "Reservations" tab
2. Filter by "Unpaid" or "Expiring Soon"
3. Select the appointment
4. Click "Mark as Paid"
5. System updates:
   - `payment_status: unpaid → paid`
   - `status: reserved → confirmed`
   - `paid_at: current_timestamp`
   - `payment_method: cash/card`

---

## Firebase Database Structure

### Firestore Collections Structure

```
/services                          (Collection)
  /{serviceId}                     (Document)
    - id: string
    - categoryId: string
    - name: string
    - description: string
    - price: number
    - duration: number (minutes)
    - imageUrl: string
    - isActive: boolean
    - createdAt: timestamp
    - updatedAt: timestamp
    - expertIds: array<string>
    - tags: array<string>
    - subServices: array<map> (optional)

/service_categories                (Collection)
  /{categoryId}                    (Document)
    - id: string
    - name: string
    - description: string
    - imageUrl: string
    - order: number
    - isActive: boolean
    - icon: string

/bookings                          (Collection)
  /{bookingId}                     (Document)
    - id: string
    - userId: string
    - serviceId: string
    - expertId: string (optional)
    - customerName: string
    - customerPhone: string
    - customerEmail: string
    - date: string (YYYY-MM-DD)
    - time: string (HH:MM)
    - status: string (reserved, confirmed, completed, cancelled)
    - paymentStatus: string (unpaid, paid, refunded)
    - paymentMethod: string (online, cash, card)
    - notes: string
    - totalPrice: number
    - createdAt: timestamp
    - updatedAt: timestamp
    - paidAt: timestamp (optional)
    - cancelledAt: timestamp (optional)
    - cancelReason: string (optional)
    - expiresAt: timestamp (for 4-hour rule)
    - reminderSent: boolean (3-hour reminder flag)

/experts                           (Collection)
  /{expertId}                      (Document)
    - id: string
    - name: string
    - specialization: array<string>
    - serviceIds: array<string>
    - imageUrl: string
    - rating: number
    - isAvailable: boolean
    - schedule: map<string, array>

/service_reviews                   (Collection)
  /{reviewId}                      (Document)
    - id: string
    - serviceId: string
    - userId: string
    - userName: string
    - rating: number
    - comment: string
    - createdAt: timestamp
```

---

## Data Models (Dart)

### Create: `lib/Models/service_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final int duration; // in minutes
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> expertIds;
  final List<String> tags;
  final List<SubService>? subServices;

  ServiceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.expertIds = const [],
    this.tags = const [],
    this.subServices,
  });

  // Convert Firestore document to ServiceModel
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ServiceModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      duration: data['duration'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expertIds: List<String>.from(data['expertIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      subServices: (data['subServices'] as List?)
          ?.map((e) => SubService.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convert ServiceModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expertIds': expertIds,
      'tags': tags,
      'subServices': subServices?.map((e) => e.toMap()).toList(),
    };
  }

  // Create a copy with updated fields
  ServiceModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    int? duration,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? expertIds,
    List<String>? tags,
    List<SubService>? subServices,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expertIds: expertIds ?? this.expertIds,
      tags: tags ?? this.tags,
      subServices: subServices ?? this.subServices,
    );
  }
}

class SubService {
  final String name;
  final double price;
  final int duration;

  SubService({
    required this.name,
    required this.price,
    required this.duration,
  });

  factory SubService.fromMap(Map<String, dynamic> map) {
    return SubService(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'duration': duration,
    };
  }
}
```

### Create: `lib/Models/service_category_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int order;
  final bool isActive;
  final String icon;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.order,
    this.isActive = true,
    this.icon = '',
  });

  factory ServiceCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ServiceCategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      icon: data['icon'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive,
      'icon': icon,
    };
  }

  ServiceCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? order,
    bool? isActive,
    String? icon,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
    );
  }
}
```

### Create: `lib/Models/booking_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  reserved,   // Pay Later option - awaiting payment (4-hour window)
  confirmed,  // Payment received or online payment completed
  completed,  // Service has been delivered
  cancelled,  // Cancelled by user, admin, or auto-expired
}

enum PaymentStatus {
  unpaid,    // Awaiting payment
  paid,      // Payment completed
  refunded,  // Payment refunded (cancellation)
}

enum PaymentMethod {
  online,    // Paid online during booking
  cash,      // Cash payment at salon
  card,      // Card payment at salon
}

class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final String? expertId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String date; // YYYY-MM-DD
  final String time; // HH:MM
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String notes;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? expiresAt; // 4-hour expiration time
  final bool reminderSent; // Track if 3-hour reminder was sent

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    this.expertId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.date,
    required this.time,
    this.status = BookingStatus.reserved,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod,
    this.notes = '',
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.cancelledAt,
    this.cancelReason,
    this.expiresAt,
    this.reminderSent = false,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      expertId: data['expertId'],
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      status: _parseStatus(data['status']),
      paymentStatus: _parsePaymentStatus(data['paymentStatus']),
      paymentMethod: _parsePaymentMethod(data['paymentMethod']),
      notes: data['notes'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      cancelReason: data['cancelReason'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      reminderSent: data['reminderSent'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'serviceId': serviceId,
      'expertId': expertId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'date': date,
      'time': time,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'notes': notes,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelReason': cancelReason,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'reminderSent': reminderSent,
    };
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.reserved;
    }
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unpaid;
    }
  }

  static PaymentMethod? _parsePaymentMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'online':
        return PaymentMethod.online;
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      default:
        return null;
    }
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? expertId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? date,
    String? time,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
    String? cancelReason,
    DateTime? expiresAt,
    bool? reminderSent,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      expertId: expertId ?? this.expertId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      expiresAt: expiresAt ?? this.expiresAt,
      reminderSent: reminderSent ?? this.reminderSent,
    );
  }

  // Status checks
  bool get isReserved => status == BookingStatus.reserved;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get canCancel => status == BookingStatus.reserved || status == BookingStatus.confirmed;
  
  // Payment checks
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isUnpaid => paymentStatus == PaymentStatus.unpaid;
  bool get isRefunded => paymentStatus == PaymentStatus.refunded;
  
  // 4-Hour Rule checks
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final timeLeft = expiresAt!.difference(DateTime.now());
    return timeLeft.inHours < 1 && timeLeft.inMinutes > 0;
  }
  
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }
  
  bool get needsPayment => isReserved && isUnpaid && !isExpired;
}
```

---

## Firebase Service Layer

### Create: `lib/Firebase/firebase_service_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/service_model.dart';
import '../Models/service_category_model.dart';
import '../Models/booking_model.dart';

class FirebaseServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _servicesCollection => _firestore.collection('services');
  CollectionReference get _categoriesCollection => _firestore.collection('service_categories');
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _reviewsCollection => _firestore.collection('service_reviews');

  // ==================== SERVICE CATEGORY OPERATIONS ====================

  /// Get all service categories
  Future<List<ServiceCategory>> getAllCategories() async {
    try {
      final snapshot = await _categoriesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ServiceCategory.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get category by ID
  Future<ServiceCategory?> getCategoryById(String categoryId) async {
    try {
      final doc = await _categoriesCollection.doc(categoryId).get();
      if (doc.exists) {
        return ServiceCategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Stream categories (real-time updates)
  Stream<List<ServiceCategory>> streamCategories() {
    return _categoriesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceCategory.fromFirestore(doc))
            .toList());
  }

  // ==================== SERVICE OPERATIONS ====================

  /// Get all services
  Future<List<ServiceModel>> getAllServices() async {
    try {
      final snapshot = await _servicesCollection
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  /// Get services by category
  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    try {
      final snapshot = await _servicesCollection
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch services by category: $e');
    }
  }

  /// Get service by ID
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _servicesCollection.doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch service: $e');
    }
  }

  /// Search services by name or tags
  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final snapshot = await _servicesCollection
          .where('isActive', isEqualTo: true)
          .get();

      final services = snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();

      // Filter by name or tags (Firestore doesn't support full-text search)
      return services.where((service) {
        final lowercaseQuery = query.toLowerCase();
        return service.name.toLowerCase().contains(lowercaseQuery) ||
            service.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search services: $e');
    }
  }

  /// Stream services by category (real-time)
  Stream<List<ServiceModel>> streamServicesByCategory(String categoryId) {
    return _servicesCollection
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList());
  }

  /// Add new service (Admin only)
  Future<String> addService(ServiceModel service) async {
    try {
      final docRef = await _servicesCollection.add(service.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add service: $e');
    }
  }

  /// Update service (Admin only)
  Future<void> updateService(String serviceId, ServiceModel service) async {
    try {
      await _servicesCollection.doc(serviceId).update(service.toFirestore());
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  /// Delete service (Admin only - soft delete)
  Future<void> deleteService(String serviceId) async {
    try {
      await _servicesCollection.doc(serviceId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  // ==================== BOOKING OPERATIONS ====================

  /// Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _bookingsCollection.add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get bookings by user
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    try {
      final snapshot = await _bookingsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  /// Get all bookings (Admin)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final snapshot = await _bookingsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all bookings: $e');
    }
  }

  /// Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus(BookingStatus status) async {
    try {
      final statusString = status.toString().split('.').last;
      final snapshot = await _bookingsCollection
          .where('status', isEqualTo: statusString)
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings by status: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? cancelReason,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == BookingStatus.cancelled) {
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
        if (cancelReason != null) {
          updateData['cancelReason'] = cancelReason;
        }
      }

      await _bookingsCollection.doc(bookingId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await updateBookingStatus(
        bookingId,
        BookingStatus.cancelled,
        cancelReason: reason,
      );
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Stream user bookings (real-time)
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _bookingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// Mark booking as paid (Admin/Receptionist)
  Future<void> markBookingAsPaid(
    String bookingId,
    PaymentMethod paymentMethod,
  ) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.confirmed.toString().split('.').last,
        'paymentStatus': PaymentStatus.paid.toString().split('.').last,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark booking as paid: $e');
    }
  }

  /// Get expired reservations (for auto-cancellation)
  Future<List<BookingModel>> getExpiredReservations() async {
    try {
      final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
      
      final snapshot = await _bookingsCollection
          .where('status', isEqualTo: 'reserved')
          .where('paymentStatus', isEqualTo: 'unpaid')
          .where('createdAt', isLessThan: Timestamp.fromDate(fourHoursAgo))
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expired reservations: $e');
    }
  }

  /// Get reservations needing reminder (3 hours)
  Future<List<BookingModel>> getReservationsNeedingReminder() async {
    try {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      
      final snapshot = await _bookingsCollection
          .where('status', isEqualTo: 'reserved')
          .where('paymentStatus', isEqualTo: 'unpaid')
          .where('reminderSent', isEqualTo: false)
          .where('createdAt', isLessThan: Timestamp.fromDate(threeHoursAgo))
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reservations needing reminder: $e');
    }
  }

  /// Mark reminder as sent
  Future<void> markReminderSent(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'reminderSent': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark reminder as sent: $e');
    }
  }

  /// Auto-cancel expired reservation
  Future<void> autoCancelExpiredBooking(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.cancelled.toString().split('.').last,
        'cancelReason': 'Reservation expired (4-hour payment window exceeded)',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to auto-cancel booking: $e');
    }
  }

  /// Check availability for a specific date and time
  Future<bool> checkAvailability(String date, String time, String? expertId) async {
    try {
      var query = _bookingsCollection
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .where('status', whereIn: ['reserved', 'confirmed']);

      if (expertId != null) {
        query = query.where('expertId', isEqualTo: expertId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }

  // ==================== REVIEW OPERATIONS ====================

  /// Add service review
  Future<String> addReview({
    required String serviceId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewData = {
        'serviceId': serviceId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _reviewsCollection.add(reviewData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  /// Get reviews for a service
  Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Get average rating for a service
  Future<double> getAverageRating(String serviceId) async {
    try {
      final reviews = await getServiceReviews(serviceId);
      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<double>(
        0.0,
        (sum, review) => sum + (review['rating'] as num).toDouble(),
      );

      return totalRating / reviews.length;
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }
}
```

---

## Business Logic Layer (Managers)

### Update: `lib/Manager/ServiceManager.dart`

```dart
import 'package:flutter/foundation.dart';
import '../Models/service_model.dart';
import '../Models/service_category_model.dart';
import '../Firebase/firebase_service_repository.dart';

class ServiceManager extends ChangeNotifier {
  final FirebaseServiceRepository _repository = FirebaseServiceRepository();

  List<ServiceCategory> _categories = [];
  List<ServiceModel> _services = [];
  Map<String, List<ServiceModel>> _servicesByCategory = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ServiceCategory> get categories => _categories;
  List<ServiceModel> get services => _services;
  Map<String, List<ServiceModel>> get servicesByCategory => _servicesByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== CATEGORY OPERATIONS ====================

  /// Load all categories
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _categories = await _repository.getAllCategories();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get category by ID
  ServiceCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // ==================== SERVICE OPERATIONS ====================

  /// Load all services
  Future<void> loadAllServices() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _services = await _repository.getAllServices();
      
      // Group services by category
      _servicesByCategory.clear();
      for (var service in _services) {
        if (!_servicesByCategory.containsKey(service.categoryId)) {
          _servicesByCategory[service.categoryId] = [];
        }
        _servicesByCategory[service.categoryId]!.add(service);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load services by category
  Future<List<ServiceModel>> loadServicesByCategory(String categoryId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final services = await _repository.getServicesByCategory(categoryId);
      _servicesByCategory[categoryId] = services;
      
      _isLoading = false;
      notifyListeners();
      
      return services;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Get service by ID
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      // First check in memory
      for (var service in _services) {
        if (service.id == serviceId) {
          return service;
        }
      }
      
      // If not found, fetch from Firebase
      return await _repository.getServiceById(serviceId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Search services
  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final results = await _repository.searchServices(query);
      
      _isLoading = false;
      notifyListeners();
      
      return results;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Get services for a specific category (from memory)
  List<ServiceModel> getServicesForCategory(String categoryId) {
    return _servicesByCategory[categoryId] ?? [];
  }

  /// Filter services by price range
  List<ServiceModel> filterByPriceRange(double minPrice, double maxPrice) {
    return _services
        .where((service) => service.price >= minPrice && service.price <= maxPrice)
        .toList();
  }

  /// Filter services by duration
  List<ServiceModel> filterByDuration(int maxDuration) {
    return _services.where((service) => service.duration <= maxDuration).toList();
  }

  /// Get featured/popular services (you can implement your own logic)
  List<ServiceModel> getFeaturedServices({int limit = 5}) {
    // Example: Return first N services or implement your own logic
    return _services.take(limit).toList();
  }

  // ==================== ADMIN OPERATIONS ====================

  /// Add new service (Admin only)
  Future<bool> addService(ServiceModel service) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final serviceId = await _repository.addService(service);
      
      // Update local state
      final newService = service.copyWith(id: serviceId);
      _services.add(newService);
      
      if (!_servicesByCategory.containsKey(service.categoryId)) {
        _servicesByCategory[service.categoryId] = [];
      }
      _servicesByCategory[service.categoryId]!.add(newService);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update service (Admin only)
  Future<bool> updateService(ServiceModel service) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateService(service.id, service);
      
      // Update local state
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = service;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete service (Admin only)
  Future<bool> deleteService(String serviceId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteService(serviceId);
      
      // Update local state
      _services.removeWhere((s) => s.id == serviceId);
      _servicesByCategory.forEach((key, services) {
        services.removeWhere((s) => s.id == serviceId);
      });
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset manager
  void reset() {
    _categories = [];
    _services = [];
    _servicesByCategory = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
```

### Update: `lib/Manager/BookingManager.dart`

```dart
import 'package:flutter/foundation.dart';
import '../Models/booking_model.dart';
import '../Firebase/firebase_service_repository.dart';

class BookingManager extends ChangeNotifier {
  final FirebaseServiceRepository _repository = FirebaseServiceRepository();

  List<BookingModel> _userBookings = [];
  List<BookingModel> _allBookings = []; // For admin
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get allBookings => _allBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter bookings by status
  List<BookingModel> get pendingBookings =>
      _userBookings.where((b) => b.isPending).toList();
  List<BookingModel> get confirmedBookings =>
      _userBookings.where((b) => b.isConfirmed).toList();
  List<BookingModel> get completedBookings =>
      _userBookings.where((b) => b.isCompleted).toList();
  List<BookingModel> get cancelledBookings =>
      _userBookings.where((b) => b.isCancelled).toList();

  // ==================== USER BOOKING OPERATIONS ====================

  /// Create a new booking with payment option
  Future<String?> createBooking({
    required String userId,
    required String serviceId,
    String? expertId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String date,
    required String time,
    required double totalPrice,
    required bool payNow, // true = pay online, false = pay at salon
    PaymentMethod? paymentMethod, // Required if payNow = true
    String notes = '',
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check availability first
      final isAvailable = await _repository.checkAvailability(date, time, expertId);
      if (!isAvailable) {
        _error = 'This time slot is not available';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final now = DateTime.now();
      final BookingStatus status;
      final PaymentStatus paymentStatus;
      final DateTime? expiresAt;
      final DateTime? paidAt;

      if (payNow) {
        // Option A: Pay Full Online
        status = BookingStatus.confirmed;
        paymentStatus = PaymentStatus.paid;
        expiresAt = null; // No expiration for paid bookings
        paidAt = now;
      } else {
        // Option B: Pay at Salon (4-hour window)
        status = BookingStatus.reserved;
        paymentStatus = PaymentStatus.unpaid;
        expiresAt = now.add(const Duration(hours: 4)); // 4-hour countdown
        paidAt = null;
      }

      final booking = BookingModel(
        id: '', // Will be set by Firestore
        userId: userId,
        serviceId: serviceId,
        expertId: expertId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        date: date,
        time: time,
        status: status,
        paymentStatus: paymentStatus,
        paymentMethod: payNow ? paymentMethod : null,
        totalPrice: totalPrice,
        notes: notes,
        createdAt: now,
        updatedAt: now,
        expiresAt: expiresAt,
        paidAt: paidAt,
      );

      final bookingId = await _repository.createBooking(booking);
      
      // Add to local state
      _userBookings.add(booking.copyWith(id: bookingId));
      
      _isLoading = false;
      notifyListeners();
      
      return bookingId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load user bookings
  Future<void> loadUserBookings(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userBookings = await _repository.getBookingsByUser(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.cancelBooking(bookingId, reason);
      
      // Update local state
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
          status: BookingStatus.cancelled,
          cancelledAt: DateTime.now(),
          cancelReason: reason,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if time slot is available
  Future<bool> checkAvailability(String date, String time, String? expertId) async {
    try {
      return await _repository.checkAvailability(date, time, expertId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark booking as paid (Admin/Receptionist)
  Future<bool> markAsPaid(String bookingId, PaymentMethod paymentMethod) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.markBookingAsPaid(bookingId, paymentMethod);
      
      // Update local state
      final updateBooking = (List<BookingModel> bookings) {
        final index = bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          bookings[index] = bookings[index].copyWith(
            status: BookingStatus.confirmed,
            paymentStatus: PaymentStatus.paid,
            paymentMethod: paymentMethod,
            paidAt: DateTime.now(),
            expiresAt: null, // Clear expiration
          );
        }
      };
      
      updateBooking(_userBookings);
      updateBooking(_allBookings);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get expiring reservations (for admin dashboard)
  List<BookingModel> getExpiringReservations() {
    return _allBookings.where((b) => b.isExpiringSoon).toList();
  }

  /// Get unpaid reservations
  List<BookingModel> getUnpaidReservations() {
    return _allBookings.where((b) => b.needsPayment).toList();
  }

  // ==================== ADMIN OPERATIONS ====================

  /// Load all bookings (Admin)
  Future<void> loadAllBookings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allBookings = await _repository.getAllBookings();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update booking status (Admin)
  Future<bool> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? cancelReason,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateBookingStatus(
        bookingId,
        status,
        cancelReason: cancelReason,
      );
      
      // Update local state
      final updateBooking = (List<BookingModel> bookings) {
        final index = bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          bookings[index] = bookings[index].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
        }
      };
      
      updateBooking(_userBookings);
      updateBooking(_allBookings);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get bookings by status (Admin)
  Future<List<BookingModel>> getBookingsByStatus(BookingStatus status) async {
    try {
      return await _repository.getBookingsByStatus(status);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get bookings for today (Admin)
  List<BookingModel> getTodayBookings() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _allBookings.where((b) => b.date == todayString).toList();
  }

  /// Get upcoming bookings
  List<BookingModel> getUpcomingBookings() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _userBookings.where((b) {
      return (b.isPending || b.isConfirmed) && 
             (b.date.compareTo(todayString) >= 0);
    }).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset manager
  void reset() {
    _userBookings = [];
    _allBookings = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
```

---

## Background Jobs & Auto-Cancellation

### Implementation Strategy

Since Flutter doesn't have built-in cron jobs, we implement the 4-hour rule using:

#### Option 1: Firebase Cloud Functions (Recommended)

**Setup: `functions/index.js`**

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Run every 10 minutes
exports.checkExpiredReservations = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async (context) => {
    const fourHoursAgo = new Date(Date.now() - 4 * 60 * 60 * 1000);
    
    // Find expired reservations
    const expiredSnapshot = await db.collection('bookings')
      .where('status', '==', 'reserved')
      .where('paymentStatus', '==', 'unpaid')
      .where('createdAt', '<', fourHoursAgo)
      .get();

    const batch = db.batch();
    const notifications = [];

    expiredSnapshot.forEach((doc) => {
      // Auto-cancel
      batch.update(doc.ref, {
        status: 'cancelled',
        cancelReason: 'Reservation expired (4-hour payment window exceeded)',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Prepare push notification
      const data = doc.data();
      notifications.push({
        userId: data.userId,
        title: 'Reservation Expired',
        body: 'Your reservation has expired due to non-payment. Please rebook if needed.',
      });
    });

    // Commit batch
    await batch.commit();

    // Send notifications
    for (const notif of notifications) {
      await sendNotificationToUser(notif.userId, notif.title, notif.body);
    }

    console.log(`Auto-cancelled ${expiredSnapshot.size} expired reservations`);
    return null;
  });

// Run every hour to send 3-hour reminders
exports.sendPaymentReminders = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
    const fourHoursAgo = new Date(Date.now() - 4 * 60 * 60 * 1000);
    
    // Find reservations created 3 hours ago (not yet expired)
    const reminderSnapshot = await db.collection('bookings')
      .where('status', '==', 'reserved')
      .where('paymentStatus', '==', 'unpaid')
      .where('reminderSent', '==', false)
      .where('createdAt', '<', threeHoursAgo)
      .where('createdAt', '>', fourHoursAgo)
      .get();

    const batch = db.batch();

    for (const doc of reminderSnapshot.docs) {
      const data = doc.data();
      
      // Mark reminder as sent
      batch.update(doc.ref, {
        reminderSent: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send reminder notification
      await sendNotificationToUser(
        data.userId,
        '⏰ Payment Reminder',
        'You have 1 hour left to complete payment at the salon.'
      );
    }

    await batch.commit();
    console.log(`Sent ${reminderSnapshot.size} payment reminders`);
    return null;
  });

// Helper function to send push notifications
async function sendNotificationToUser(userId, title, body) {
  try {
    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    const message = {
      notification: { title, body },
      token: fcmToken,
    };

    await messaging.send(message);
    console.log(`Notification sent to user ${userId}`);
  } catch (error) {
    console.error(`Failed to send notification: ${error}`);
  }
}
```

**Deploy:**
```bash
firebase deploy --only functions
```

#### Option 2: Server-Side Polling (Alternative)

If you have a backend server (Node.js, Python, etc.), set up a cron job:

```javascript
// Node.js with node-cron
const cron = require('node-cron');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Run every 10 minutes
cron.schedule('*/10 * * * *', async () => {
  console.log('Checking for expired reservations...');
  
  const fourHoursAgo = new Date(Date.now() - 4 * 60 * 60 * 1000);
  
  const snapshot = await db.collection('bookings')
    .where('status', '==', 'reserved')
    .where('paymentStatus', '==', 'unpaid')
    .where('createdAt', '<', fourHoursAgo)
    .get();

  const batch = db.batch();
  
  snapshot.forEach((doc) => {
    batch.update(doc.ref, {
      status: 'cancelled',
      cancelReason: 'Reservation expired (4-hour payment window exceeded)',
      cancelledAt: admin.firestore.Timestamp.now(),
    });
  });

  await batch.commit();
  console.log(`Cancelled ${snapshot.size} expired reservations`);
});
```

#### Option 3: Client-Side Check (Fallback)

Add a check in your Flutter app when user opens the app:

**Create: `lib/Services/expiration_checker.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/booking_model.dart';
import '../Firebase/firebase_service_repository.dart';

class ExpirationChecker {
  final FirebaseServiceRepository _repository = FirebaseServiceRepository();

  /// Check and auto-cancel expired reservations for current user
  Future<void> checkUserExpiredReservations(String userId) async {
    try {
      final bookings = await _repository.getBookingsByUser(userId);
      
      for (var booking in bookings) {
        if (booking.isReserved && booking.isUnpaid && booking.isExpired) {
          await _repository.autoCancelExpiredBooking(booking.id);
          print('Auto-cancelled expired booking: ${booking.id}');
        }
      }
    } catch (e) {
      print('Error checking expired reservations: $e');
    }
  }

  /// Start periodic check (every 5 minutes while app is open)
  void startPeriodicCheck(String userId) {
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      checkUserExpiredReservations(userId);
    });
  }
}
```

**Call in main.dart after login:**
```dart
final expirationChecker = ExpirationChecker();
expirationChecker.startPeriodicCheck(currentUser.uid);
```

### Testing the Auto-Cancellation

**For Development: Reduce time window to 5 minutes**

```dart
// In dev_config.dart
class DevConfig {
  static const bool isDevelopment = true;
  static const Duration reservationWindow = isDevelopment 
      ? Duration(minutes: 5)  // 5 min for testing
      : Duration(hours: 4);   // 4 hours for production
}
```

**Manual Testing:**
1. Create a "Pay Later" booking
2. Wait 5 minutes (dev) or 4 hours (prod)
3. Run cloud function manually or wait for scheduled run
4. Verify booking status changes to `cancelled`
5. Check user receives push notification

---

## UI Integration

### Example: Service List Screen with Firebase Integration

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Manager/ServiceManager.dart';
import '../Models/service_model.dart';

class ServiceListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ServiceListScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  @override
  void initState() {
    super.initState();
    // Load services when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceManager>().loadServicesByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
      ),
      body: Consumer<ServiceManager>(
        builder: (context, serviceManager, child) {
          if (serviceManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (serviceManager.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${serviceManager.error}'),
                  ElevatedButton(
                    onPressed: () {
                      serviceManager.loadServicesByCategory(widget.categoryId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final services = serviceManager.getServicesForCategory(widget.categoryId);

          if (services.isEmpty) {
            return const Center(
              child: Text('No services available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceCard(service: service);
            },
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const ServiceCard({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigate to service details
          Navigator.pushNamed(
            context,
            '/service-details',
            arguments: service,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: Image.network(
                service.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text('${service.duration} min'),
                        ],
                      ),
                      Text(
                        '\$${service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example: Booking Form with Payment Option

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Manager/BookingManager.dart';
import '../Models/booking_model.dart';

class BookingFormScreen extends StatefulWidget {
  final String serviceId;
  final double servicePrice;

  const BookingFormScreen({
    Key? key,
    required this.serviceId,
    required this.servicePrice,
  }) : super(key: key);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  bool _payNow = true; // Default to "Pay Now"
  
  Future<void> _submitBooking() async {
    final bookingManager = context.read<BookingManager>();
    
    final bookingId = await bookingManager.createBooking(
      userId: currentUser.uid,
      serviceId: widget.serviceId,
      customerName: nameController.text,
      customerPhone: phoneController.text,
      customerEmail: emailController.text,
      date: selectedDate,
      time: selectedTime,
      totalPrice: widget.servicePrice,
      payNow: _payNow,
      paymentMethod: _payNow ? PaymentMethod.online : null,
    );

    if (bookingId != null) {
      if (_payNow) {
        // Navigate to payment gateway
        Navigator.pushNamed(context, '/payment', arguments: bookingId);
      } else {
        // Show 4-hour warning
        _showReservationConfirmation();
      }
    }
  }

  void _showReservationConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Reservation Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your slot has been reserved!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                '⚠️ Important: Please visit the salon within 4 HOURS to complete payment, or your reservation will be automatically cancelled.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ... form fields ...
            
            // Payment Option
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            RadioListTile<bool>(
              title: const Text('Pay Now (Online)'),
              subtitle: const Text('Instant confirmation ✅'),
              value: true,
              groupValue: _payNow,
              onChanged: (value) => setState(() => _payNow = value!),
            ),
            
            RadioListTile<bool>(
              title: const Text('Pay at Salon'),
              subtitle: const Text('⏰ Must pay within 4 hours'),
              value: false,
              groupValue: _payNow,
              onChanged: (value) => setState(() => _payNow = value!),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _submitBooking,
              child: Text(_payNow ? 'Proceed to Payment' : 'Reserve Slot'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example: Admin "Mark as Paid" Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Manager/BookingManager.dart';
import '../Models/booking_model.dart';

class AdminUnpaidReservationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Reservations'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<BookingManager>(
        builder: (context, bookingManager, child) {
          final unpaidBookings = bookingManager.getUnpaidReservations();
          final expiringBookings = bookingManager.getExpiringReservations();

          return Column(
            children: [
              // Expiring Soon Warning
              if (expiringBookings.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        '${expiringBookings.length} reservations expiring soon!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              
              // Unpaid List
              Expanded(
                child: unpaidBookings.isEmpty
                    ? const Center(child: Text('No unpaid reservations'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: unpaidBookings.length,
                        itemBuilder: (context, index) {
                          final booking = unpaidBookings[index];
                          return UnpaidBookingCard(booking: booking);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class UnpaidBookingCard extends StatelessWidget {
  final BookingModel booking;

  const UnpaidBookingCard({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeLeft = booking.timeUntilExpiration;
    final isExpiringSoon = booking.isExpiringSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isExpiringSoon ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.customerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isExpiringSoon)
                  Chip(
                    label: const Text('EXPIRING SOON'),
                    backgroundColor: Colors.red,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Phone: ${booking.customerPhone}'),
            Text('Date: ${booking.date} at ${booking.time}'),
            Text('Amount: \$${booking.totalPrice.toStringAsFixed(2)}'),
            
            if (timeLeft != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Time left: ${timeLeft.inHours}h ${timeLeft.inMinutes.remainder(60)}m',
                      style: TextStyle(
                        color: isExpiringSoon ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPaid(context, PaymentMethod.cash),
                    icon: const Icon(Icons.money),
                    label: const Text('Cash'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPaid(context, PaymentMethod.card),
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Card'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context, PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Mark this reservation as paid via ${method.toString().split('.').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bookingManager = context.read<BookingManager>();
      final success = await bookingManager.markAsPaid(booking.id, method);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment confirmed! Reservation secured.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${bookingManager.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

---

## Security Rules

### Firestore Security Rules (firestore.rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Service Categories
    match /service_categories/{categoryId} {
      allow read: if true; // Public read
      allow write: if isAdmin(); // Only admin can write
    }
    
    // Services
    match /services/{serviceId} {
      allow read: if true; // Public read
      allow create, update, delete: if isAdmin(); // Only admin can modify
    }
    
    // Bookings
    match /bookings/{bookingId} {
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      
      allow update: if isAuthenticated() && 
                       (resource.data.userId == request.auth.uid || isAdmin());
      
      allow delete: if isAdmin();
    }
    
    // Reviews
    match /service_reviews/{reviewId} {
      allow read: if true; // Public read
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                               resource.data.userId == request.auth.uid;
    }
    
    // Experts
    match /experts/{expertId} {
      allow read: if true; // Public read
      allow write: if isAdmin(); // Only admin can write
    }
  }
}
```

---

## Best Practices

### 1. **Error Handling**
- Always wrap Firebase calls in try-catch blocks
- Provide user-friendly error messages
- Log errors for debugging

### 2. **State Management**
- Use Provider/Riverpod for state management
- Keep UI reactive with ChangeNotifier
- Separate business logic from UI

### 3. **Performance Optimization**
- Use pagination for large lists
- Implement caching strategies
- Use indexed queries in Firestore
- Lazy load images

### 4. **Data Validation**
- Validate input on client side
- Use Firestore security rules for server-side validation
- Sanitize user input

### 5. **Real-time Updates**
- Use Stream listeners for real-time data
- Properly dispose stream subscriptions
- Handle connection states

### 6. **Testing**
- Write unit tests for business logic
- Mock Firebase services for testing
- Test error scenarios

### 7. **Security**
- Never expose sensitive data
- Implement proper authentication checks
- Use role-based access control
- Regularly update security rules

---

## Implementation Checklist

### Phase 1: Data Models & Firebase Setup
- [ ] Create data models (ServiceModel, ServiceCategory, BookingModel)
- [ ] Add payment enums (BookingStatus, PaymentStatus, PaymentMethod)
- [ ] Update BookingModel with 4-hour rule fields
- [ ] Implement Firebase repository layer
- [ ] Configure Firestore security rules

### Phase 2: Business Logic
- [ ] Create ServiceManager with state management
- [ ] Create BookingManager with payment logic
- [ ] Implement `createBooking()` with payNow option
- [ ] Implement `markAsPaid()` for admin
- [ ] Add expiration checking methods
- [ ] Set up Provider in main.dart

### Phase 3: Background Jobs (Critical)
- [ ] Set up Firebase Cloud Functions project
- [ ] Implement `checkExpiredReservations` (runs every 10 min)
- [ ] Implement `sendPaymentReminders` (3-hour reminder)
- [ ] Configure FCM for push notifications
- [ ] Deploy cloud functions to Firebase
- [ ] Test auto-cancellation with 5-minute window

### Phase 4: UI Implementation
- [ ] Update booking form with "Pay Now" vs "Pay Later" options
- [ ] Add 4-hour warning dialog for "Pay Later"
- [ ] Create admin "Unpaid Reservations" screen
- [ ] Implement "Mark as Paid" functionality
- [ ] Add countdown timer display
- [ ] Show expiring soon badges
- [ ] Update existing UI screens to use managers

### Phase 5: Notifications
- [ ] Implement FCM token storage in user profile
- [ ] Create notification service class
- [ ] Add reservation confirmation notification
- [ ] Add 3-hour reminder notification
- [ ] Add expiration notification
- [ ] Add payment confirmation notification

### Phase 6: Testing & Validation
- [ ] Test CRUD operations for services
- [ ] Test booking flow with "Pay Now"
- [ ] Test booking flow with "Pay Later"
- [ ] Test 4-hour auto-cancellation
- [ ] Test admin "Mark as Paid" flow
- [ ] Test 3-hour reminder notifications
- [ ] Test availability checking
- [ ] Verify security rules work correctly
- [ ] Load test with multiple concurrent bookings

### Phase 7: Production Readiness
- [ ] Switch from 5-minute to 4-hour window
- [ ] Add error handling for all edge cases
- [ ] Implement loading states across UI
- [ ] Add analytics tracking
- [ ] Set up monitoring for cloud functions
- [ ] Create admin dashboard for analytics
- [ ] Deploy to production

---

## Next Steps

### 1. Firebase Cloud Functions Setup (Critical!)

**Initialize Functions:**
```bash
cd "D:\Aztrosys\Salon App\Source code\salon"
firebase init functions
# Select JavaScript or TypeScript
# Select "Use existing project" and choose your Firebase project
```

**Install Dependencies:**
```bash
cd functions
npm install firebase-admin firebase-functions
```

**Deploy Functions:**
```bash
firebase deploy --only functions
```

**Monitor Function Execution:**
```bash
firebase functions:log
```

**Set Environment Variables (if needed):**
```bash
firebase functions:config:set notification.key="YOUR_FCM_KEY"
```

### 2. Set up Firebase collections with initial data

**Add sample service categories:**
```javascript
// Firebase Console > Firestore > Add Collection
service_categories/
  - hair (name: "Hair Services", order: 1, isActive: true)
  - makeup (name: "Makeup Services", order: 2, isActive: true)
  - facial (name: "Facial Services", order: 3, isActive: true)
```

### 3. Configure security rules in Firebase Console

Copy the security rules from this document to:
Firebase Console > Firestore Database > Rules

### 4. Integrate Provider in your app

Update `main.dart`:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ServiceManager()),
    ChangeNotifierProvider(create: (_) => BookingManager()),
  ],
  child: MyApp(),
)
```

### 5. Update existing UI to use new managers

Replace hardcoded data with ServiceManager and BookingManager calls.

### 6. Test thoroughly with different scenarios

- Create booking with "Pay Now"
- Create booking with "Pay Later"
- Let reservation expire (test with 5-minute window first)
- Admin marks booking as paid
- Check notifications are sent

### 7. Add analytics to track user behavior

Use Firebase Analytics to track:
- Booking creation
- Payment method selection
- Cancellations
- Expirations

### 8. Implement push notifications for booking updates

Set up FCM and store user tokens in Firestore.

---

## Additional Features to Consider

- **Service Packages**: Bundle multiple services
- **Loyalty Programs**: Reward frequent customers
- **Ratings & Reviews**: Enhanced review system
- **Scheduling**: Advanced calendar integration
- **Payment Integration**: Online payment processing (Stripe, Razorpay)
- **SMS Notifications**: Booking reminders via Twilio
- **Multi-language Support**: Internationalization
- **Admin Dashboard**: Web-based management panel
- **Refund Processing**: Handle cancellation refunds
- **Waitlist System**: Allow users to join waitlist for fully booked slots
- **Expert Preferences**: Let users choose specific stylists
- **Time Zone Support**: Handle bookings across time zones

---

## Edge Cases & Troubleshooting

### Common Issues & Solutions

#### 1. User Pays Just Before 4-Hour Expiration
**Problem:** User arrives at 3:59 hours, but background job runs at 4:00 and cancels.

**Solution:** 
- Add 5-minute grace period in cloud function
- Check `paidAt` timestamp before cancelling
- Lock booking when admin opens "Mark as Paid" dialog

```dart
// In cloud function
if (booking.paidAt || booking.updatedAt > fourHoursAgo) {
  continue; // Skip this booking
}
```

#### 2. Multiple Admins Mark Same Booking
**Problem:** Two receptionists try to mark the same booking as paid.

**Solution:** Use Firestore transactions
```dart
await db.runTransaction((transaction) async {
  final bookingDoc = await transaction.get(bookingRef);
  if (bookingDoc.data().status == 'reserved') {
    transaction.update(bookingRef, {'status': 'confirmed'});
  }
});
```

#### 3. Cloud Function Fails to Run
**Problem:** Auto-cancellation doesn't happen.

**Solution:**
- Check Firebase Console > Functions > Logs
- Verify billing is enabled (Cloud Scheduler requires Blaze plan)
- Add fallback client-side check on app launch
- Set up monitoring alerts

#### 4. Push Notification Not Received
**Problem:** User doesn't get expiration warning.

**Solution:**
- Verify FCM token is stored correctly
- Check notification permissions are granted
- Use Firebase Cloud Messaging console to test
- Add email/SMS as backup notification channel

#### 5. Time Zone Confusion
**Problem:** 4-hour window incorrect due to time zones.

**Solution:**
- Store all timestamps in UTC
- Convert to local time only for display
- Use `FieldValue.serverTimestamp()` in Firestore

```dart
// Always use server timestamp
'createdAt': FieldValue.serverTimestamp(),

// For expiration calculation, use UTC
final expiresAt = DateTime.now().toUtc().add(Duration(hours: 4));
```

#### 6. Double Booking
**Problem:** Two users book the same slot simultaneously.

**Solution:** Use Firestore transactions for availability check
```dart
await db.runTransaction((transaction) async {
  // Check availability
  final existingBookings = await transaction.get(
    bookingsRef.where('date', '==', date).where('time', '==', time)
  );
  
  if (existingBookings.isEmpty) {
    // Create booking
    transaction.set(newBookingRef, bookingData);
  } else {
    throw Exception('Time slot no longer available');
  }
});
```

#### 7. Payment Gateway Timeout
**Problem:** User pays online but payment confirmation is delayed.

**Solution:**
- Set booking status to `processing` during payment
- Add webhook to handle delayed confirmations
- Auto-confirm after successful payment notification
- Keep 4-hour window active until payment confirmed/failed

```dart
enum BookingStatus {
  reserved,
  processing, // New: payment in progress
  confirmed,
  completed,
  cancelled,
}
```

#### 8. Network Issues During Booking
**Problem:** App crashes/network fails during booking creation.

**Solution:**
- Use Firestore offline persistence
- Implement retry logic
- Show clear error messages
- Allow user to check "My Bookings" to verify

```dart
// Enable offline persistence
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

#### 9. Admin Accidentally Cancels Wrong Booking
**Problem:** Human error in admin panel.

**Solution:**
- Add confirmation dialogs
- Implement undo/restore functionality
- Log all admin actions with timestamps
- Add audit trail

```dart
// Add to bookings collection
'history': [
  {
    'action': 'marked_paid',
    'by': 'admin_id',
    'at': timestamp,
    'previous_status': 'reserved'
  }
]
```

#### 10. Peak Hour Overload
**Problem:** Too many bookings at popular times.

**Solution:**
- Implement slot capacity limits
- Add queueing system
- Show availability heatmap
- Suggest alternative times

```dart
// Add to service_categories
'capacity': {
  'max_concurrent': 5,
  'time_slot_duration': 30,
}
```

---

## Performance Optimization Tips

1. **Index Firestore Queries**
   - Create composite indexes for complex queries
   - Index: `status + paymentStatus + createdAt`

2. **Pagination**
   ```dart
   final query = _bookingsCollection
       .limit(20)
       .startAfter(lastDocument);
   ```

3. **Caching**
   ```dart
   // Cache service categories locally
   final prefs = await SharedPreferences.getInstance();
   prefs.setString('categories_cache', jsonEncode(categories));
   ```

4. **Image Optimization**
   - Use Firebase Storage with CDN
   - Compress images before upload
   - Use thumbnails for list views

5. **Batch Operations**
   ```dart
   final batch = FirebaseFirestore.instance.batch();
   // Add multiple operations
   await batch.commit();
   ```

---

## Support & Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Provider Package](https://pub.dev/packages/provider)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
