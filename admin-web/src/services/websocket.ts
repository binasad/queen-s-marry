import { io, Socket } from 'socket.io-client';

class WebSocketService {
  private socket: Socket | null = null;

  // Service event callbacks
  public onServiceCreated?: (data: any) => void;
  public onServiceUpdated?: (data: any) => void;
  public onServiceDeleted?: (data: any) => void;

  // Course event callbacks
  public onCourseCreated?: (data: any) => void;
  public onCourseUpdated?: (data: any) => void;
  public onCourseDeleted?: (data: any) => void;

  // Offer event callbacks
  public onOfferCreated?: (data: any) => void;
  public onOfferUpdated?: (data: any) => void;
  public onOfferDeleted?: (data: any) => void;
  public onOffersUpdated?: (data: any) => void;

  // Appointment event callbacks
  public onAppointmentCreated?: (data: any) => void;
  public onAppointmentUpdated?: (data: any) => void;
  public onAppointmentDeleted?: (data: any) => void;
  public onAppointmentsUpdated?: (data: any) => void;

  constructor() {
    this.initializeSocket();
  }

  private initializeSocket() {
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:5000';

    this.socket = io(backendUrl, {
      transports: ['websocket'],
      timeout: 5000,
      forceNew: true,
    });

    this.setupEventListeners();
  }

  private setupEventListeners() {
    if (!this.socket) return;

    this.socket.on('connect', () => {
      console.log('🔌 Connected to WebSocket server');
      this.socket?.emit('join-admin');
    });

    this.socket.on('disconnect', () => {
      console.log('🔌 Disconnected from WebSocket server');
    });

    this.socket.on('connect_error', (error) => {
      console.error('🔌 WebSocket connection error:', error);
      this.handleReconnect();
    });

    // Service events
    this.socket.on('service-created', (data) => {
      console.log('💇 Service created via WebSocket:', data);
      if (this.onServiceCreated) {
        this.onServiceCreated(data);
      }
    });

    this.socket.on('service-updated', (data) => {
      console.log('💇 Service updated via WebSocket:', data);
      if (this.onServiceUpdated) {
        this.onServiceUpdated(data);
      }
    });

    this.socket.on('service-deleted', (data) => {
      console.log('💇 Service deleted via WebSocket:', data);
      if (this.onServiceDeleted) {
        this.onServiceDeleted(data);
      }
    });

    // Course events
    this.socket.on('course-created', (data) => {
      console.log('📚 Course created via WebSocket:', data);
      if (this.onCourseCreated) {
        this.onCourseCreated(data);
      }
    });

    this.socket.on('course-updated', (data) => {
      console.log('📚 Course updated via WebSocket:', data);
      if (this.onCourseUpdated) {
        this.onCourseUpdated(data);
      }
    });

    this.socket.on('course-deleted', (data) => {
      console.log('📚 Course deleted via WebSocket:', data);
      if (this.onCourseDeleted) {
        this.onCourseDeleted(data);
      }
    });

    // Offer events (admin-specific)
    this.socket.on('offer-created', (data) => {
      console.log('🏷️ Offer created via WebSocket:', data);
      if (this.onOfferCreated) {
        this.onOfferCreated(data);
      }
    });

    this.socket.on('offer-updated', (data) => {
      console.log('🏷️ Offer updated via WebSocket:', data);
      if (this.onOfferUpdated) {
        this.onOfferUpdated(data);
      }
    });

    this.socket.on('offer-deleted', (data) => {
      console.log('🏷️ Offer deleted via WebSocket:', data);
      if (this.onOfferDeleted) {
        this.onOfferDeleted(data);
      }
    });

    // General offers update event (broadcast to all clients)
    this.socket.on('offers-updated', (data) => {
      console.log('🏷️ Offers updated via WebSocket:', data);
      if (this.onOffersUpdated) {
        this.onOffersUpdated(data);
      }
    });

    // Appointment events
    this.socket.on('appointment-created', (data) => {
      console.log('📅 Appointment created via WebSocket:', data);
      if (this.onAppointmentCreated) {
        this.onAppointmentCreated(data);
      }
    });

    this.socket.on('appointment-updated', (data) => {
      console.log('📅 Appointment updated via WebSocket:', data);
      if (this.onAppointmentUpdated) {
        this.onAppointmentUpdated(data);
      }
    });

    this.socket.on('appointment-deleted', (data) => {
      console.log('📅 Appointment deleted via WebSocket:', data);
      if (this.onAppointmentDeleted) {
        this.onAppointmentDeleted(data);
      }
    });

    this.socket.on('appointments-updated', (data) => {
      console.log('📅 Appointments updated via WebSocket:', data);
      if (this.onAppointmentsUpdated) {
        this.onAppointmentsUpdated(data);
      }
    });
  }

  private handleReconnect() {
    if (this.socket?.disconnected) {
      setTimeout(() => {
        console.log('🔄 Attempting to reconnect to WebSocket...');
        this.socket?.connect();
      }, 3000);
    }
  }

  public connect() {
    if (this.socket && !this.socket.connected) {
      console.log('🔌 Connecting to WebSocket server...');
      this.socket.connect();
    }
  }

  public disconnect() {
    if (this.socket?.connected) {
      console.log('🔌 Disconnecting from WebSocket server...');
      this.socket.disconnect();
    }
  }

  public isConnected(): boolean {
    return this.socket?.connected || false;
  }

  public emit(event: string, data?: any) {
    if (this.socket?.connected) {
      this.socket.emit(event, data);
    } else {
      console.warn('⚠️ Cannot emit event - WebSocket not connected');
    }
  }
}

export const wsService = new WebSocketService();
export default wsService;