'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { reportsAPI } from '@/lib/api';
import toast from 'react-hot-toast';
import Link from 'next/link';

export default function SalesPage() {
  const [loading, setLoading] = useState(true);
  const [today, setToday] = useState({ revenue: 0, count: 0 });
  const [week, setWeek] = useState({ revenue: 0, count: 0 });
  const [month, setMonth] = useState({ revenue: 0, count: 0 });
  const [transactions, setTransactions] = useState<any[]>([]);

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        const res = await reportsAPI.getSalesOverview();
        const data = res.data?.data || res.data;
        setToday(data.today || { revenue: 0, count: 0 });
        setWeek(data.week || { revenue: 0, count: 0 });
        setMonth(data.month || { revenue: 0, count: 0 });
        setTransactions(data.transactions || []);
      } catch (err: any) {
        console.error('Failed to load sales:', err);
        toast.error(err.response?.data?.message || 'Failed to load sales data');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'PKR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(val);
  };

  const formatDate = (d: string) => {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatTime = (t: string) => {
    if (!t) return '';
    return String(t).slice(0, 5);
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
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Sales</h1>
                <p className="text-gray-600">Track revenue and transactions</p>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-500 mx-auto mb-4"></div>
                  <p className="text-gray-500">Loading sales data...</p>
                </div>
              ) : (
                <>
                  {/* Stats */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                    <div className="bg-white rounded-lg shadow p-6">
                      <p className="text-sm text-gray-600 mb-1">Today</p>
                      <p className="text-2xl font-bold text-gray-800">{formatCurrency(today.revenue)}</p>
                      <p className="text-sm text-gray-500 mt-1">{today.count} transactions</p>
                    </div>
                    <div className="bg-white rounded-lg shadow p-6">
                      <p className="text-sm text-gray-600 mb-1">This Week</p>
                      <p className="text-2xl font-bold text-gray-800">{formatCurrency(week.revenue)}</p>
                      <p className="text-sm text-gray-500 mt-1">{week.count} transactions</p>
                    </div>
                    <div className="bg-white rounded-lg shadow p-6">
                      <p className="text-sm text-gray-600 mb-1">This Month</p>
                      <p className="text-2xl font-bold text-gray-800">{formatCurrency(month.revenue)}</p>
                      <p className="text-sm text-gray-500 mt-1">{month.count} transactions</p>
                    </div>
                  </div>

                  {/* Recent Transactions */}
                  <div className="bg-white rounded-lg shadow overflow-hidden">
                    <div className="flex items-center justify-between p-4 border-b border-gray-200">
                      <h2 className="text-lg font-semibold text-gray-800">Recent Transactions</h2>
                      <Link
                        href="/reports"
                        className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                      >
                        View Reports →
                      </Link>
                    </div>
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead>
                          <tr className="bg-gray-50 border-b border-gray-200">
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600 uppercase">Customer</th>
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600 uppercase">Service</th>
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600 uppercase">Expert</th>
                            <th className="text-left py-3 px-4 text-xs font-semibold text-gray-600 uppercase">Date & Time</th>
                            <th className="text-right py-3 px-4 text-xs font-semibold text-gray-600 uppercase">Amount</th>
                          </tr>
                        </thead>
                        <tbody>
                          {transactions.length === 0 ? (
                            <tr>
                              <td colSpan={5} className="py-8 text-center text-gray-500">
                                No transactions yet
                              </td>
                            </tr>
                          ) : (
                            transactions.map((t) => (
                              <tr key={t.id} className="border-b border-gray-100 hover:bg-gray-50">
                                <td className="py-3 px-4 text-sm text-gray-800">{t.customer_name || '—'}</td>
                                <td className="py-3 px-4 text-sm text-gray-600">{t.service_name || '—'}</td>
                                <td className="py-3 px-4 text-sm text-gray-600">{t.expert_name || '—'}</td>
                                <td className="py-3 px-4 text-sm text-gray-600">
                                  {formatDate(t.appointment_date)} {formatTime(t.appointment_time)}
                                </td>
                                <td className="py-3 px-4 text-sm font-semibold text-gray-800 text-right">
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
