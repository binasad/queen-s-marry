import api from '../api';

export async function fetchDashboardStats(signal?: AbortSignal) {
  const res = await api.get('/dashboard/stats', { signal });
  return res.data;
}

export async function fetchRecentAppointments(signal?: AbortSignal) {
  const res = await api.get('/appointments/recent', { signal });
  return res.data;
}

export async function fetchRecentPayments(signal?: AbortSignal) {
  const res = await api.get('/payments/recent', { signal });
  return res.data;
}
