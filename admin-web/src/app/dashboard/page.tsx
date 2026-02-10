'use client';

import { useState, useEffect } from 'react';
import io from 'socket.io-client';
import { fetchDashboardStats, fetchRecentAppointments, fetchRecentPayments } from '@/lib/api/dashboard';
import PaymentsTable from './PaymentsTable';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { useAuthStore } from '@/store/authStore';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import Link from 'next/link';

export default function DashboardPage() {
  const { user } = useAuthStore();

  // Live dashboard state
  const [stats, setStats] = useState<any>(null);
  const [recentAppointments, setRecentAppointments] = useState<any[]>([]);
  const [revenueData, setRevenueData] = useState<any[]>([]);
  const [topServices, setTopServices] = useState<any[]>([]);
  const [staffPerformance, setStaffPerformance] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);

  useEffect(() => {
    const controller = new AbortController();
    const signal = controller.signal;
    // Initial fetch
    fetchDashboardStats(signal).then(data => {
      setStats(data.stats);
      setRevenueData(data.revenueData);
      setTopServices(data.topServices);
      setStaffPerformance(data.staffPerformance);
    }).catch((err) => {
      if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
    });
    fetchRecentAppointments(signal).then(data => setRecentAppointments(data.appointments)).catch((err) => {
      if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
    });
    fetchRecentPayments(signal).then(data => setPayments(data.payments)).catch((err) => {
      if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
    });

    // Socket.io live updates
    const socket = io(process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:5000');
    socket.on('appointments-updated', (payload) => {
      fetchDashboardStats(signal).then(data => {
        setStats(data.stats);
        setRevenueData(data.revenueData);
        setTopServices(data.topServices);
        setStaffPerformance(data.staffPerformance);
      }).catch((err) => {
        if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
      });
      fetchRecentAppointments(signal).then(data => setRecentAppointments(data.appointments)).catch((err) => {
        if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
      });
    });
    socket.on('payments-updated', () => {
      fetchDashboardStats(signal).then(data => {
        setStats(data.stats);
        setRevenueData(data.revenueData);
        setTopServices(data.topServices);
        setStaffPerformance(data.staffPerformance);
      }).catch((err) => {
        if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
      });
      fetchRecentPayments(signal).then(data => setPayments(data.payments)).catch((err) => {
        if (err.name !== 'CanceledError' && err.name !== 'AbortError') console.error(err);
      });
    });
    return () => {
      controller.abort();
      socket.disconnect();
    };
  }, []);

  const getStatusColor = (status: string) => {
    const statusColors: { [key: string]: string } = {
      Completed: 'bg-green-100 text-green-800',
      Pending: 'bg-yellow-100 text-yellow-800',
      Confirmed: 'bg-blue-100 text-blue-800',
      Cancelled: 'bg-red-100 text-red-800',
    };
    return statusColors[status] || 'bg-gray-100 text-gray-800';
  };

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
              <div className="mb-6">
                <h1 className="text-3xl font-bold text-gray-800 mb-2">Dashboard</h1>
                <p className="text-gray-600">
                  Welcome back, {user?.name || 'Sarah'}! Here's what's happening today.
                </p>
              </div>

              <>
                  {/* Stats Grid */}
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                    <StatCard
                      title="Total Revenue"
                      value={`$${parseFloat(stats?.total_revenue || 0).toLocaleString()}`}
                      change={0}
                      changeType="positive"
                    />
                    <StatCard
                      title="Appointments"
                      value={stats?.total_appointments || 0}
                      change={0}
                      changeType="positive"
                    />
                    <StatCard
                      title="Total Customers"
                      value={stats?.total_customers || 0}
                      change={0}
                      changeType="positive"
                    />
                    <StatCard
                      title="Active Services"
                      value={stats?.services_count || 24}
                      change={stats?.services_change || 0}
                      changeType="neutral"
                    />
                  </div>

                  {/* Revenue Overview */}
                  <div className="bg-white rounded-lg shadow p-6 mb-6">
                    <div className="flex items-center justify-between mb-4">
                      <h2 className="text-xl font-semibold text-gray-800">Revenue Overview</h2>
                      <div className="flex space-x-2">
                        <button className="px-3 py-1 text-sm bg-primary-500 text-white rounded">7 Days</button>
                        <button className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">30 Days</button>
                        <button className="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 rounded">Year</button>
                      </div>
                    </div>
                    <p className="text-sm text-gray-500 mb-4">Last 7 days performance</p>
                    <ResponsiveContainer width="100%" height={300}>
                      <LineChart data={revenueData}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                        <XAxis dataKey="day" stroke="#6b7280" />
                        <YAxis stroke="#6b7280" />
                        <Tooltip 
                          contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                        />
                        <Line 
                          type="monotone" 
                          dataKey="revenue" 
                          stroke="#FF6CBF" 
                          strokeWidth={3}
                          dot={{ fill: '#FF6CBF', r: 5 }}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                    {/* Top Services */}
                    <div className="bg-white rounded-lg shadow p-6">
                      <h2 className="text-xl font-semibold text-gray-800 mb-4">Top Services</h2>
                      <div className="space-y-4">
                        {(topServices || []).map((service, index) => (
                          <div key={index} className="flex items-center justify-between pb-4 border-b last:border-0">
                            <div className="flex-1">
                              <p className="font-medium text-gray-800">{service.name}</p>
                              <p className="text-sm text-gray-500">{service.bookings} bookings</p>
                            </div>
                            <p className="text-lg font-semibold text-primary-600">${service.revenue.toLocaleString()}</p>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Staff Performance */}
                    <div className="bg-white rounded-lg shadow p-6">
                      <h2 className="text-xl font-semibold text-gray-800 mb-4">Staff Performance</h2>
                      <div className="grid grid-cols-2 gap-4">
                        {(staffPerformance || []).map((staff, index) => (
                          <div key={index} className="text-center p-4 bg-gray-50 rounded-lg">
                            <div className="w-12 h-12 rounded-full bg-primary-500 flex items-center justify-center text-white font-bold text-lg mx-auto mb-2">
                              {staff.initials}
                            </div>
                            <p className="font-medium text-gray-800 text-sm">{staff.name}</p>
                            <p className="text-yellow-500 text-sm font-semibold">★ {staff.rating}</p>
                            <p className="text-gray-500 text-xs">{staff.appointments} apts</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Recent Payments */}
                  <PaymentsTable payments={payments} />
                  {/* Recent Appointments */}
                  <div className="bg-white rounded-lg shadow p-6">
                    <div className="flex items-center justify-between mb-4">
                      <h2 className="text-xl font-semibold text-gray-800">Recent Appointments</h2>
                      <Link 
                        href="/appointments"
                        className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                      >
                        View All
                      </Link>
                    </div>
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead>
                          <tr className="border-b border-gray-200">
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Customer</th>
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Service</th>
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Time</th>
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {(recentAppointments || []).map((appointment) => (
                            <tr key={appointment.id} className="border-b border-gray-100 hover:bg-gray-50">
                              <td className="py-3 px-4 text-sm text-gray-800">
                                {appointment.customerName || appointment.customer?.name || 'N/A'}
                              </td>
                              <td className="py-3 px-4 text-sm text-gray-600">
                                {appointment.serviceName || appointment.service?.name || 'N/A'}
                              </td>
                              <td className="py-3 px-4 text-sm text-gray-600">
                                {appointment.time || appointment.appointmentTime || 'N/A'}
                              </td>
                              <td className="py-3 px-4">
                                <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(appointment.status || 'Pending')}`}>
                                  {appointment.status || 'Pending'}
                                </span>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </>
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}

function StatCard({ title, value, change, changeType }: any) {
  const changeColor = changeType === 'positive' ? 'text-green-600' : changeType === 'negative' ? 'text-red-600' : 'text-gray-600';
  const changeIcon = changeType === 'positive' ? '↑' : changeType === 'negative' ? '↓' : '';

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <p className="text-sm text-gray-600 mb-2">{title}</p>
      <div className="flex items-end justify-between">
        <p className="text-3xl font-bold text-gray-800">{value}</p>
        {change !== undefined && change !== 0 && (
          <div className={`flex items-center text-sm font-semibold ${changeColor}`}>
            <span>{changeIcon}</span>
            <span>{Math.abs(change)}%</span>
          </div>
        )}
      </div>
    </div>
  );
}
