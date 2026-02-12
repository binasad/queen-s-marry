import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
///import '../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  late IO.Socket socket;
  bool _isConnected = false;

  // Stream controllers for broadcasting events to multiple listeners
  final _offersUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _servicesUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _coursesUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _appointmentCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _appointmentUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _appointmentDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _appointmentsUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams for listeners
  Stream<Map<String, dynamic>> get offersUpdatedStream =>
      _offersUpdatedController.stream;
  Stream<Map<String, dynamic>> get servicesUpdatedStream =>
      _servicesUpdatedController.stream;
  Stream<Map<String, dynamic>> get coursesUpdatedStream =>
      _coursesUpdatedController.stream;
  Stream<Map<String, dynamic>> get appointmentCreatedStream =>
      _appointmentCreatedController.stream;
  Stream<Map<String, dynamic>> get appointmentUpdatedStream =>
      _appointmentUpdatedController.stream;
  Stream<Map<String, dynamic>> get appointmentDeletedStream =>
      _appointmentDeletedController.stream;
  Stream<Map<String, dynamic>> get appointmentsUpdatedStream =>
      _appointmentsUpdatedController.stream;

  // Legacy callbacks for backward compatibility (deprecated - use streams instead)
  @Deprecated('Use offersUpdatedStream instead')
  Function? onOffersUpdated;
  @Deprecated('Use servicesUpdatedStream instead')
  Function? onServicesUpdated;
  @Deprecated('Use coursesUpdatedStream instead')
  Function? onCoursesUpdated;
  @Deprecated('Use appointmentUpdatedStream instead')
  Function(Map<String, dynamic>)? onAppointmentUpdated;

  WebSocketService._internal() {
    _initializeSocket();
  }

  void _initializeSocket() {
    // Use the backend URL from dotenv (without /api/v1)
    final backendUrl = (dotenv.env['API_BASE_URL'] ?? '').replaceAll(
      '/api/v1',
      '',
    );

    debugPrint('🔌 WebSocket: Connecting to $backendUrl');

    socket = IO.io(
      backendUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setTimeout(10000) // Increased timeout
          .disableAutoConnect()
          .enableForceNewConnection()
          .build(),
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socket.onConnect((_) {
      debugPrint('🔌 Connected to WebSocket server');
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      debugPrint('🔌 Disconnected from WebSocket server');
      _isConnected = false;
      // Attempt to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          debugPrint('🔄 Attempting to reconnect...');
          connect();
        }
      });
    });

    socket.onConnectError((error) {
      debugPrint('🔌 WebSocket connection error: $error');
      debugPrint(
        '🔌 Attempted URL: ${(dotenv.env['API_BASE_URL'] ?? '').replaceAll('/api/v1', '')}',
      );
      _isConnected = false;
      // Attempt to reconnect after a delay
      Future.delayed(const Duration(seconds: 10), () {
        if (!_isConnected) {
          debugPrint('🔄 Retrying WebSocket connection...');
          connect();
        }
      });
    });

    socket.onError((error) {
      debugPrint('🔌 WebSocket error: $error');
    });

    // --- OFFERS UPDATES ---
    // Listen for offers updates - broadcast to stream and call legacy callback
    socket.on('offers-updated', (data) {
      debugPrint('📢 Offers updated: $data');
      final eventData = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{'data': data};
      _offersUpdatedController.add(eventData);
      // Legacy callback support
      if (onOffersUpdated != null) {
        onOffersUpdated!();
      }
    });

    // --- SERVICES UPDATES (FIXED - Listen to both singular and plural events) ---
    void broadcastServiceUpdate(dynamic data, String eventType) {
      debugPrint('📢 Service Update Received ($eventType): $data');
      final eventData = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{'data': data};

      // Push to the stream so UI screens can react
      _servicesUpdatedController.add(eventData);

      // Support legacy callback if used
      if (onServicesUpdated != null) {
        onServicesUpdated!();
      }
    }

    // Listen for PLURAL event (batch updates)
    socket.on(
      'services-updated',
      (data) => broadcastServiceUpdate(data, 'services-updated'),
    );

    // Listen for SINGULAR events (what backend actually sends)
    socket.on(
      'service-created',
      (data) => broadcastServiceUpdate(data, 'service-created'),
    );
    socket.on(
      'service-updated',
      (data) => broadcastServiceUpdate(data, 'service-updated'),
    );
    socket.on(
      'service-deleted',
      (data) => broadcastServiceUpdate(data, 'service-deleted'),
    );

    // --- COURSES UPDATES (FIXED - Listen to both singular and plural events) ---
    void broadcastCourseUpdate(dynamic data, String eventType) {
      debugPrint('📢 Course Update Received ($eventType): $data');
      final eventData = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{'data': data};

      _coursesUpdatedController.add(eventData);

      // Legacy callback support
      if (onCoursesUpdated != null) {
        onCoursesUpdated!();
      }
    }

    // Listen for PLURAL event (batch updates)
    socket.on(
      'courses-updated',
      (data) => broadcastCourseUpdate(data, 'courses-updated'),
    );

    // Listen for SINGULAR events (what backend actually sends)
    socket.on(
      'course-created',
      (data) => broadcastCourseUpdate(data, 'course-created'),
    );
    socket.on(
      'course-updated',
      (data) => broadcastCourseUpdate(data, 'course-updated'),
    );
    socket.on(
      'course-deleted',
      (data) => broadcastCourseUpdate(data, 'course-deleted'),
    );

    // --- APPOINTMENT UPDATES (FIXED - Listen to both singular and plural events) ---
    void broadcastAppointmentUpdate(dynamic data, String eventType) {
      debugPrint('📢 Appointment Update Received ($eventType): $data');
      final eventData = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{'data': data};

      // Add to appropriate stream based on event type
      if (eventType == 'appointment-created') {
        _appointmentCreatedController.add(eventData);
      } else if (eventType == 'appointment-updated') {
        _appointmentUpdatedController.add(eventData);
      } else if (eventType == 'appointment-deleted') {
        _appointmentDeletedController.add(eventData);
      } else if (eventType == 'appointments-updated') {
        _appointmentsUpdatedController.add(eventData);
      }

      // Legacy callback support
      if (onAppointmentUpdated != null) {
        onAppointmentUpdated!(eventData);
      }
    }

    // Listen for SINGULAR events (admin-specific)
    socket.on(
      'appointment-created',
      (data) => broadcastAppointmentUpdate(data, 'appointment-created'),
    );
    socket.on(
      'appointment-updated',
      (data) => broadcastAppointmentUpdate(data, 'appointment-updated'),
    );
    socket.on(
      'appointment-deleted',
      (data) => broadcastAppointmentUpdate(data, 'appointment-deleted'),
    );

    // Listen for PLURAL event (broadcast to all)
    socket.on(
      'appointments-updated',
      (data) => broadcastAppointmentUpdate(data, 'appointments-updated'),
    );
  }

  void connect() {
    if (!_isConnected) {
      debugPrint('🔌 Connecting to WebSocket server...');
      socket.connect();
    }
  }

  void disconnect() {
    if (_isConnected) {
      debugPrint('🔌 Disconnecting from WebSocket server...');
      socket.disconnect();
    }
  }

  bool get isConnected => _isConnected;

  // Join user-specific room for personalized updates
  void joinUserRoom(String userId) {
    if (_isConnected) {
      socket.emit('join-user', userId);
      debugPrint('👤 Joined user room: $userId');
    }
  }

  // Join admin room for admin updates
  void joinAdminRoom() {
    if (_isConnected) {
      socket.emit('join-admin');
      debugPrint('👑 Joined admin room');
    }
  }
}
