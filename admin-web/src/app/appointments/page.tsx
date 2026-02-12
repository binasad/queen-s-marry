'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { appointmentsAPI } from '@/lib/api';
import toast from 'react-hot-toast';
import websocketService from '@/services/websocket';

interface Appointment {
  id: string;
  customer_name: string;
  customer_phone: string;
  customer_email?: string;
  service_name: string;
  appointment_date: string;
  appointment_time: string;
  total_price: string;
  status: string;
  payment_status: string;
  payment_method?: string;
  expert_name?: string;
  notes?: string;
  offer_id?: string;
  offer_title?: string;
  created_at?: string;
}

export default function AppointmentsPage() {
  const [filter, setFilter] = useState('all');
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState<string | null>(null);

  useEffect(() => {
    loadAppointments();
  }, [filter]);

  useEffect(() => {
    // Setup WebSocket listeners
    websocketService.onAppointmentCreated = (data) => {
      console.log('New appointment created:', data);
      loadAppointments();
      toast.success('New appointment received!');
    };

    websocketService.onAppointmentUpdated = (data) => {
      console.log('Appointment updated:', data);
      loadAppointments();
    };

    websocketService.onAppointmentDeleted = (data) => {
      console.log('Appointment deleted:', data);
      loadAppointments();
      toast.success('Appointment deleted successfully');
    };

    websocketService.onAppointmentsUpdated = (data) => {
      console.log('Appointments updated:', data);
      loadAppointments();
    };

    websocketService.connect();

    return () => {
      websocketService.onAppointmentCreated = undefined;
      websocketService.onAppointmentUpdated = undefined;
      websocketService.onAppointmentDeleted = undefined;
      websocketService.onAppointmentsUpdated = undefined;
    };
  }, []);

  const loadAppointments = async () => {
    try {
      setLoading(true);
      const params: any = { page: 1, limit: 100 };
      if (filter !== 'all') {
        params.status = filter;
      }
      const res = await appointmentsAPI.getAll(params);
      // Handle response format: { data: { appointments: [...], pagination: {...} } }
      const appointmentsData = res.data?.data?.appointments || res.data?.appointments || [];
      setAppointments(appointmentsData);
    } catch (error: any) {
      console.error('Failed to load appointments:', error);
      toast.error(error.response?.data?.message || 'Failed to load appointments');
      setAppointments([]);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (id: string, status: string) => {
    try {
      setUpdating(id);
      await appointmentsAPI.updateStatus(id, { status });
      toast.success('Status updated successfully');
      await loadAppointments();
    } catch (error: any) {
      console.error('Failed to update status:', error);
      toast.error(error.response?.data?.message || 'Failed to update status');
    } finally {
      setUpdating(null);
    }
  };

  const handleMarkPaid = async (id: string) => {
    try {
      setUpdating(id);
      await appointmentsAPI.markAsPaid(id, { paymentMethod: 'cash' });
      toast.success('Marked as paid successfully');
      await loadAppointments();
    } catch (error: any) {
      console.error('Failed to mark as paid:', error);
      toast.error(error.response?.data?.message || 'Failed to mark as paid');
    } finally {
      setUpdating(null);
    }
  };

  const handleDelete = async (id: string, customerName: string) => {
    if (!confirm(`Are you sure you want to delete the appointment for ${customerName}?`)) {
      return;
    }

    try {
      setUpdating(id);
      await appointmentsAPI.delete(id);
      toast.success('Appointment deleted successfully');
      await loadAppointments();
    } catch (error: any) {
      console.error('Failed to delete appointment:', error);
      toast.error(error.response?.data?.message || 'Failed to delete appointment');
    } finally {
      setUpdating(null);
    }
  };

  const getStatusColor = (status: string) => {
    const colors: any = {
      reserved: 'bg-yellow-100 text-yellow-800',
      confirmed: 'bg-green-100 text-green-800',
      completed: 'bg-blue-100 text-blue-800',
      cancelled: 'bg-red-100 text-red-800',
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Appointments</h1>

              <select
                value={filter}
                onChange={(e) => setFilter(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
              >
                <option value="all">All Status</option>
                <option value="reserved">Reserved</option>
                <option value="confirmed">Confirmed</option>
                <option value="completed">Completed</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>

            {loading ? (
              <div className="bg-white rounded-lg shadow p-8 text-center">
                <p className="text-gray-500">Loading appointments...</p>
              </div>
            ) : appointments.length === 0 ? (
              <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                No appointments found
              </div>
            ) : (
              <div className="bg-white rounded-lg shadow overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Customer
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Service
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Date & Time
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Price
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Status
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Payment
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {appointments.map((appointment) => (
                      <tr key={appointment.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div>
                            <div className="font-medium text-gray-900">{appointment.customer_name}</div>
                            <div className="text-sm text-gray-500">{appointment.customer_phone}</div>
                            {appointment.customer_email && (
                              <div className="text-sm text-gray-500">{appointment.customer_email}</div>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-900">{appointment.service_name}</div>
                          {appointment.offer_title && (
                            <span className="inline-block mt-1 px-2 py-0.5 text-xs font-medium rounded-full bg-pink-100 text-pink-800" title="Purchased with offer">
                              🎁 {appointment.offer_title}
                            </span>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-900">{appointment.appointment_date}</div>
                          <div className="text-sm text-gray-500">{appointment.appointment_time}</div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-900">
                          Rs. {parseFloat(appointment.total_price).toLocaleString()}
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(
                              appointment.status
                            )}`}
                          >
                            {appointment.status}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`px-2 py-1 text-xs font-semibold rounded-full ${
                              appointment.payment_status === 'paid'
                                ? 'bg-green-100 text-green-800'
                                : 'bg-red-100 text-red-800'
                            }`}
                          >
                            {appointment.payment_status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm">
                          <div className="flex gap-2">
                            {appointment.payment_status === 'unpaid' && (
                              <button
                                onClick={() => handleMarkPaid(appointment.id)}
                                disabled={updating === appointment.id}
                                className="text-green-600 hover:text-green-800 disabled:opacity-50 disabled:cursor-not-allowed"
                              >
                                {updating === appointment.id ? 'Updating...' : 'Mark Paid'}
                              </button>
                            )}
                            {appointment.status === 'reserved' && (
                              <button
                                onClick={() => handleStatusChange(appointment.id, 'confirmed')}
                                disabled={updating === appointment.id}
                                className="text-blue-600 hover:text-blue-800 disabled:opacity-50 disabled:cursor-not-allowed"
                              >
                                {updating === appointment.id ? 'Updating...' : 'Confirm'}
                              </button>
                            )}
                            {appointment.status === 'confirmed' && (
                              <button
                                onClick={() => handleStatusChange(appointment.id, 'completed')}
                                disabled={updating === appointment.id}
                                className="text-purple-600 hover:text-purple-800 disabled:opacity-50 disabled:cursor-not-allowed"
                              >
                                {updating === appointment.id ? 'Updating...' : 'Complete'}
                              </button>
                            )}
                            {(appointment.status === 'reserved' || appointment.status === 'confirmed') && (
                              <button
                                onClick={() => handleStatusChange(appointment.id, 'cancelled')}
                                disabled={updating === appointment.id}
                                className="text-red-600 hover:text-red-800 disabled:opacity-50 disabled:cursor-not-allowed"
                              >
                                {updating === appointment.id ? 'Updating...' : 'Cancel'}
                              </button>
                            )}
                            <button
                              onClick={() => handleDelete(appointment.id, appointment.customer_name)}
                              disabled={updating === appointment.id}
                              className="text-gray-600 hover:text-gray-800 disabled:opacity-50 disabled:cursor-not-allowed"
                              title="Delete Appointment"
                            >
                              {updating === appointment.id ? '...' : '🗑️'}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
