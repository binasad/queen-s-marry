'use client';

import { useState, useEffect, useCallback } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { reportsAPI } from '@/lib/api';
import toast from 'react-hot-toast';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

const STATUS_COLORS: Record<string, string> = {
  completed: '#22c55e',
  confirmed: '#3b82f6',
  reserved: '#f59e0b',
  cancelled: '#ef4444',
  pending: '#6b7280',
};

export default function ReportsPage() {
  const [loading, setLoading] = useState(true);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [revenueData, setRevenueData] = useState<any[]>([]);
  const [summary, setSummary] = useState<any>(null);
  const [topServices, setTopServices] = useState<any[]>([]);
  const [appointmentsByStatus, setAppointmentsByStatus] = useState<any[]>([]);
  const [transactions, setTransactions] = useState<any[]>([]);

  const setDefaultDates = () => {
    const end = new Date();
    const start = new Date();
    start.setDate(start.getDate() - 30);
    setEndDate(end.toISOString().split('T')[0]);
    setStartDate(start.toISOString().split('T')[0]);
  };

  const loadReports = useCallback(async (signal?: AbortSignal) => {
    if (!startDate || !endDate) return;
    try {
      setLoading(true);
      const res = await reportsAPI.getReports(
        { startDate, endDate },
        signal ? { signal } : undefined
      );
      const data = res.data?.data || res.data;
      setRevenueData(data.revenueData || []);
      setSummary(data.summary || {});
      setTopServices(data.topServices || []);
      setAppointmentsByStatus(data.appointmentsByStatus || []);
    } catch (err: any) {
      if (err.name !== 'AbortError' && err.name !== 'CanceledError') {
        console.error('Failed to load reports:', err);
        toast.error(err.response?.data?.message || 'Failed to load reports');
      }
    } finally {
      setLoading(false);
    }
  }, [startDate, endDate]);

  const loadTransactions = useCallback(async () => {
    if (!startDate || !endDate) return;
    try {
      const res = await reportsAPI.getTransactions({
        startDate,
        endDate,
        limit: 200,
      });
      const data = res.data?.data || res.data;
      setTransactions(data.transactions || []);
    } catch (err: any) {
      console.error('Failed to load transactions:', err);
    }
  }, [startDate, endDate]);

  useEffect(() => {
    setDefaultDates();
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    if (startDate && endDate) {
      loadReports(controller.signal);
      loadTransactions();
    }
    return () => controller.abort();
  }, [startDate, endDate, loadReports, loadTransactions]);

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'PKR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(val);
  };

  const exportToCSV = () => {
    if (transactions.length === 0) {
      toast.error('No transactions to export');
      return;
    }
    const headers = ['Date', 'Customer', 'Service', 'Expert', 'Amount', 'Status'];
    const rows = transactions.map((t) => [
      t.appointment_date,
      t.customer_name || '',
      t.service_name || '',
      t.expert_name || '',
      t.total_price || 0,
      t.payment_status || '',
    ]);
    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `sales-report-${startDate}-to-${endDate}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
    toast.success('Report exported');
  };

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
              <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-6">
                <div>
                  <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Reports</h1>
                  <p className="text-gray-600">Analytics and revenue insights</p>
                </div>
                <div className="flex flex-wrap items-center gap-4">
                  <div className="flex items-center gap-2">
                    <label className="text-sm text-gray-600">From</label>
                    <input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                  <div className="flex items-center gap-2">
                    <label className="text-sm text-gray-600">To</label>
                    <input
                      type="date"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                      className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                  <button
                    onClick={exportToCSV}
                    className="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                  >
                    Export CSV
                  </button>
                </div>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-500 mx-auto mb-4"></div>
                  <p className="text-gray-500">Loading reports...</p>
                </div>
              ) : (
                <>
                  {/* Summary Cards */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                    <div className="bg-white rounded-lg shadow p-4">
                      <p className="text-sm text-gray-600">Total Revenue</p>
                      <p className="text-xl font-bold text-gray-800">
                        {formatCurrency(summary?.totalRevenue || 0)}
                      </p>
                    </div>
                    <div className="bg-white rounded-lg shadow p-4">
                      <p className="text-sm text-gray-600">Total Appointments</p>
                      <p className="text-xl font-bold text-gray-800">
                        {summary?.totalAppointments ?? 0}
                      </p>
                    </div>
                    <div className="bg-white rounded-lg shadow p-4">
                      <p className="text-sm text-gray-600">Paid</p>
                      <p className="text-xl font-bold text-green-600">
                        {summary?.paidCount ?? 0}
                      </p>
                    </div>
                    <div className="bg-white rounded-lg shadow p-4">
                      <p className="text-sm text-gray-600">Cancelled</p>
                      <p className="text-xl font-bold text-red-600">
                        {summary?.cancelledCount ?? 0}
                      </p>
                    </div>
                  </div>

                  {/* Revenue Chart */}
                  <div className="bg-white rounded-lg shadow p-6 mb-6">
                    <h2 className="text-lg font-semibold text-gray-800 mb-4">Revenue Over Time</h2>
                    <ResponsiveContainer width="100%" height={300}>
                      <LineChart data={revenueData}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                        <XAxis dataKey="day" stroke="#6b7280" />
                        <YAxis stroke="#6b7280" />
                        <Tooltip
                          contentStyle={{
                            backgroundColor: '#fff',
                            border: '1px solid #e5e7eb',
                            borderRadius: '8px',
                          }}
                          formatter={(value: number) => [formatCurrency(value), 'Revenue']}
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
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                    {/* Top Services */}
                    <div className="bg-white rounded-lg shadow p-6">
                      <h2 className="text-lg font-semibold text-gray-800 mb-4">Top Services by Revenue</h2>
                      {topServices.length === 0 ? (
                        <p className="text-gray-500 text-sm">No data for this period</p>
                      ) : (
                        <div className="space-y-3">
                          {topServices.map((s, i) => (
                            <div
                              key={i}
                              className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0"
                            >
                              <div>
                                <p className="font-medium text-gray-800">{s.name}</p>
                                <p className="text-xs text-gray-500">{s.bookings} bookings</p>
                              </div>
                              <p className="font-semibold text-primary-600">
                                {formatCurrency(s.revenue)}
                              </p>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* Appointments by Status */}
                    <div className="bg-white rounded-lg shadow p-6">
                      <h2 className="text-lg font-semibold text-gray-800 mb-4">Appointments by Status</h2>
                      {appointmentsByStatus.length === 0 ? (
                        <p className="text-gray-500 text-sm">No data for this period</p>
                      ) : (
                        <ResponsiveContainer width="100%" height={200}>
                          <PieChart>
                            <Pie
                              data={appointmentsByStatus.map((s) => ({
                                name: s.status,
                                value: s.count,
                              }))}
                              cx="50%"
                              cy="50%"
                              innerRadius={50}
                              outerRadius={80}
                              paddingAngle={2}
                              dataKey="value"
                              label={({ name, value }) => `${name}: ${value}`}
                            >
                              {appointmentsByStatus.map((_, i) => (
                                <Cell
                                  key={i}
                                  fill={
                                    STATUS_COLORS[
                                      String(appointmentsByStatus[i].status).toLowerCase()
                                    ] || '#94a3b8'
                                  }
                                />
                              ))}
                            </Pie>
                            <Tooltip />
                          </PieChart>
                        </ResponsiveContainer>
                      )}
                    </div>
                  </div>

                  {/* Transactions Table */}
                  <div className="bg-white rounded-lg shadow overflow-hidden">
                    <h2 className="text-lg font-semibold text-gray-800 p-4 border-b">
                      Paid Transactions ({transactions.length})
                    </h2>
                    <div className="overflow-x-auto max-h-96 overflow-y-auto">
                      <table className="w-full">
                        <thead className="bg-gray-50 sticky top-0">
                          <tr>
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600">
                              Date
                            </th>
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600">
                              Customer
                            </th>
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600">
                              Service
                            </th>
                            <th className="text-right py-3 px-4 text-xs font-semibold text-gray-600">
                              Amount
                            </th>
                          </tr>
                        </thead>
                        <tbody>
                          {transactions.length === 0 ? (
                            <tr>
                              <td colSpan={4} className="py-8 text-center text-gray-500">
                                No transactions in this period
                              </td>
                            </tr>
                          ) : (
                            transactions.map((t) => (
                              <tr key={t.id} className="border-b border-gray-100 hover:bg-gray-50">
                                <td className="py-2 px-4 text-sm text-gray-600">
                                  {new Date(t.appointment_date).toLocaleDateString()}
                                </td>
                                <td className="py-2 px-4 text-sm text-gray-800">
                                  {t.customer_name || '—'}
                                </td>
                                <td className="py-2 px-4 text-sm text-gray-600">
                                  {t.service_name || '—'}
                                </td>
                                <td className="py-2 px-4 text-sm font-medium text-right">
                                  {formatCurrency(parseFloat(t.total_price || 0))}
                                </td>
                              </tr>
                            ))
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
