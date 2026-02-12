import api from '../api';

export async function fetchDashboardStats(signal?: AbortSignal, period?: string) {
  const config: { signal?: AbortSignal; params?: { period: string } } = {};
  if (signal) config.signal = signal;
  if (period) config.params = { period };
  const res = await api.get('/dashboard/stats', config);
  const body = res.data;
  return body?.data || body;
}

export async function fetchRecentAppointments(signal?: AbortSignal) {
  const res = await api.get('/appointments/recent', { signal });
  const body = res.data;
  return { appointments: body?.appointments || body?.data?.appointments || [] };
}

export async function fetchRecentPayments(signal?: AbortSignal) {
  const res = await api.get('/payments/recent', { signal });
  const body = res.data;
  return { payments: body?.payments || body?.data?.payments || [] };
}
