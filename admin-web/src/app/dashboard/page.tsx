'use client';

import { useState, useEffect, useCallback } from 'react';
import io from 'socket.io-client';
import { fetchDashboardStats, fetchRecentAppointments, fetchRecentPayments } from '@/lib/api/dashboard';
import PaymentsTable from './PaymentsTable';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { useAuthStore } from '@/store/authStore';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import Link from 'next/link';

type ChartPeriod = '7' | '30' | '90';

export default function DashboardPage() {
  const { user } = useAuthStore();
  const [chartPeriod, setChartPeriod] = useState<ChartPeriod>('7');
  const [stats, setStats] = useState<any>(null);
  const [recentAppointments, setRecentAppointments] = useState<any[]>([]);
  const [revenueData, setRevenueData] = useState<any[]>([]);
  const [topServices, setTopServices] = useState<any[]>([]);
  const [staffPerformance, setStaffPerformance] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('en-PK', {
      style: 'currency',
      currency: 'PKR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(val);

  const loadData = useCallback(async (signal?: AbortSignal, period?: string) => {
    try {
      setLoading(true);
      const p = period || chartPeriod;
      const [statsData, appointmentsData, paymentsData] = await Promise.all([
        fetchDashboardStats(signal, p),
        fetchRecentAppointments(signal),
        fetchRecentPayments(signal),
      ]);

      if (statsData) {
        setStats(statsData.stats);
        setRevenueData(statsData.revenueData || []);
        setTopServices(statsData.topServices || []);
        setStaffPerformance(statsData.staffPerformance || []);
      }
      setRecentAppointments(appointmentsData?.appointments || []);
      setPayments(paymentsData?.payments || []);
    } catch (err) {
      if (err && typeof err === 'object' && 'name' in err) {
        const e = err as { name?: string };
        if (e.name !== 'CanceledError' && e.name !== 'AbortError') console.error(err);
      }
    } finally {
      setLoading(false);
    }
  }, [chartPeriod]);

  useEffect(() => {
    const controller = new AbortController();
    const signal = controller.signal;
    loadData(signal);

    const socket = io(process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:5000');
    socket.on('appointments-updated', () => loadData(signal));
    socket.on('payments-updated', () => loadData(signal));
    socket.on('offer-created', () => loadData(signal));
    socket.on('offer-updated', () => loadData(signal));

    return () => {
      controller.abort();
      socket.disconnect();
    };
  }, [loadData]);

  const handlePeriodChange = (p: ChartPeriod) => {
    setChartPeriod(p);
    loadData(undefined, p);
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      completed: 'bg-green-100 text-green-800',
      confirmed: 'bg-blue-100 text-blue-800',
      reserved: 'bg-yellow-100 text-yellow-800',
      cancelled: 'bg-red-100 text-red-800',
    };
    return colors[String(status || '').toLowerCase()] || 'bg-gray-100 text-gray-800';
  };

  const totalRevenue = parseFloat(stats?.total_revenue || 0);
  const monthlyRevenue = parseFloat(stats?.monthly_revenue || 0);
  const todayRevenue = parseFloat(stats?.today_revenue || 0);

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
                  Welcome back, {user?.name || 'Admin'}! Here's your business overview.
                </p>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-12 text-center">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500 mx-auto mb-4" />
                  <p className="text-gray-500">Loading dashboard...</p>
                </div>
              ) : (
                <>
                  {/* Stats Grid */}
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                    <StatCard
                      title="Total Revenue"
                      value={formatCurrency(totalRevenue)}
                      subtitle="All time"
                      href="/reports"
                    />
                    <StatCard
                      title="This Month"
                      value={formatCurrency(monthlyRevenue)}
                      subtitle="Paid appointments"
                      href="/sales"
                    />
                    <StatCard
                      title="Today's Revenue"
                      value={formatCurrency(todayRevenue)}
                      subtitle={stats?.today_count ? `${stats.today_count} apts today` : 'Today'}
                    />
                    <StatCard
                      title="Appointments"
                      value={stats?.total_appointments ?? 0}
                      subtitle={`${stats?.confirmed_count ?? 0} confirmed, ${stats?.reserved_count ?? 0} reserved`}
                      href="/appointments"
                    />
                    <StatCard
                      title="Customers"
                      value={stats?.total_customers ?? 0}
                      subtitle="Registered"
                      href="/customers"
                    />
                    <StatCard
                      title="Active Services"
                      value={stats?.services_count ?? 0}
                      subtitle="Available"
                      href="/services"
                    />
                  </div>

                  {/* Revenue Overview */}
                  <div className="bg-white rounded-lg shadow p-6 mb-6">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-4">
                      <h2 className="text-xl font-semibold text-gray-800">Revenue Overview</h2>
                      <div className="flex gap-2">
                        {(['7', '30', '90'] as ChartPeriod[]).map((p) => (
                          <button
                            key={p}
                            onClick={() => handlePeriodChange(p)}
                            className={`px-4 py-2 text-sm font-medium rounded-lg transition ${
                              chartPeriod === p
                                ? 'bg-primary-500 text-white'
                                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                            }`}
                          >
                            {p} Days
                          </button>
                        ))}
                      </div>
                    </div>
                    <p className="text-sm text-gray-500 mb-4">
                      Revenue from paid appointments over the last {chartPeriod} days
                    </p>
                    {revenueData?.length > 0 ? (
                      <ResponsiveContainer width="100%" height={300}>
                        <LineChart data={revenueData}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                          <XAxis
                            dataKey="day"
                            stroke="#6b7280"
                            tick={{ fontSize: 12 }}
                          />
                          <YAxis
                            stroke="#6b7280"
                            tick={{ fontSize: 12 }}
                            tickFormatter={(v) => (v >= 1000 ? `${v / 1000}k` : v)}
                          />
                          <Tooltip
                            contentStyle={{
                              backgroundColor: '#fff',
                              border: '1px solid #e5e7eb',
                              borderRadius: '8px',
                            }}
                            formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                            labelFormatter={(label) => `Date: ${label}`}
                          />
                          <Line
                            type="monotone"
                            dataKey="revenue"
                            stroke="#FF6CBF"
                            strokeWidth={2}
                            dot={{ fill: '#FF6CBF', r: 4 }}
                          />
                        </LineChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="h-[300px] flex items-center justify-center text-gray-500">
                        No revenue data for this period
                      </div>
                    )}
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                    {/* Top Services */}
                    <div className="bg-white rounded-lg shadow p-6">
                      <div className="flex items-center justify-between mb-4">
                        <h2 className="text-xl font-semibold text-gray-800">Top Services</h2>
                        <Link
                          href="/services"
                          className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                        >
                          View All
                        </Link>
                      </div>
                      {topServices?.length > 0 ? (
                        <div className="space-y-4">
                          {topServices.map((service, index) => (
                            <div
                              key={index}
                              className="flex items-center justify-between py-3 border-b last:border-0"
                            >
                              <div>
                                <p className="font-medium text-gray-800">{service.name}</p>
                                <p className="text-sm text-gray-500">{service.bookings} bookings</p>
                              </div>
                              <p className="font-semibold text-primary-600">
                                {formatCurrency(service.revenue)}
                              </p>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <p className="text-gray-500 py-8 text-center">No service data yet</p>
                      )}
                    </div>

                    {/* Staff Performance */}
                    <div className="bg-white rounded-lg shadow p-6">
                      <div className="flex items-center justify-between mb-4">
                        <h2 className="text-xl font-semibold text-gray-800">Staff Performance</h2>
                        <Link
                          href="/experts"
                          className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                        >
                          View All
                        </Link>
                      </div>
                      {staffPerformance?.length > 0 ? (
                        <div className="grid grid-cols-2 gap-4">
                          {staffPerformance.map((staff, index) => (
                            <div
                              key={staff.id || index}
                              className="p-4 bg-gray-50 rounded-lg text-center"
                            >
                              <div className="w-12 h-12 rounded-full bg-primary-500 flex items-center justify-center text-white font-bold text-lg mx-auto mb-2">
                                {staff.initials || '?'}
                              </div>
                              <p className="font-medium text-gray-800 text-sm truncate" title={staff.name}>
                                {staff.name}
                              </p>
                              <p className="text-gray-500 text-xs truncate" title={staff.specialty}>
                                {staff.specialty}
                              </p>
                              <p className="text-primary-600 text-sm font-semibold mt-1">
                                {staff.appointments} apts
                              </p>
                              {staff.revenue > 0 && (
                                <p className="text-xs text-gray-600">{formatCurrency(staff.revenue)}</p>
                              )}
                            </div>
                          ))}
                        </div>
                      ) : (
                        <p className="text-gray-500 py-8 text-center">No staff data yet</p>
                      )}
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
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">
                              Customer
                            </th>
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">
                              Service
                            </th>
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">
                              Date & Time
                            </th>
                            <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">
                              Status
                            </th>
                          </tr>
                        </thead>
                        <tbody>
                          {recentAppointments?.length > 0 ? (
                            recentAppointments.map((apt) => (
                              <tr key={apt.id} className="border-b border-gray-100 hover:bg-gray-50">
                                <td className="py-3 px-4">
                                  <div>
                                    <p className="font-medium text-gray-800">
                                      {apt.customer_name || 'N/A'}
                                    </p>
                                    {apt.customer_email && (
                                      <p className="text-xs text-gray-500">{apt.customer_email}</p>
                                    )}
                                  </div>
                                </td>
                                <td className="py-3 px-4 text-sm text-gray-600">
                                  {apt.service_name || 'N/A'}
                                  {apt.offer_title && (
                                    <span className="ml-1 px-1.5 py-0.5 text-xs rounded bg-pink-100 text-pink-700">
                                      🎁
                                    </span>
                                  )}
                                </td>
                                <td className="py-3 px-4 text-sm text-gray-600">
                                  {apt.appointment_date
                                    ? new Date(apt.appointment_date).toLocaleDateString()
                                    : '—'}{' '}
                                  {apt.appointment_time
                                    ? String(apt.appointment_time).slice(0, 5)
                                    : ''}
                                </td>
                                <td className="py-3 px-4">
                                  <span
                                    className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
                                      apt.status || 'reserved'
                                    )}`}
                                  >
                                    {apt.status || 'Pending'}
                                  </span>
                                </td>
                              </tr>
                            ))
                          ) : (
                            <tr>
                              <td colSpan={4} className="py-8 text-center text-gray-500">
                                No appointments yet
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </>
              )}
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}

function StatCard({
  title,
  value,
  subtitle,
  href,
}: {
  title: string;
  value: string | number;
  subtitle?: string;
  href?: string;
}) {
  const content = (
    <>
      <p className="text-sm text-gray-600 mb-1">{title}</p>
      <p className="text-2xl font-bold text-gray-800">{value}</p>
      {subtitle && <p className="text-xs text-gray-500 mt-1">{subtitle}</p>}
    </>
  );

  return (
    <div className="bg-white rounded-lg shadow p-6 hover:shadow-md transition">
      {href ? (
        <Link href={href} className="block">
          {content}
          <p className="text-primary-600 text-xs font-medium mt-2">View details →</p>
        </Link>
      ) : (
        content
      )}
    </div>
  );
}
