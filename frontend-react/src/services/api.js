const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ;

async function get(endpoint) {
  const res = await fetch(`${API_BASE_URL}${endpoint}`);
  if (!res.ok) throw new Error(`API error: ${res.status}`);
  return res.json();
}

async function post(endpoint, body) {
  const res = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.message || data.errors?.[0]?.msg || `API error: ${res.status}`);
  }
  return data;
}

export async function getCategories() {
  const res = await get('/categories');
  return res.data?.categories || res.data || [];
}

export async function getServices(categoryId) {
  const params = new URLSearchParams({ isActive: 'true', limit: '200' });
  if (categoryId) params.set('categoryId', categoryId);
  const res = await get(`/services?${params}`);
  return res.data?.services || res.data || [];
}

export async function getCourses() {
  const res = await get('/courses?isActive=true');
  return res.data?.courses || res.data || [];
}

export async function getOffers() {
  const res = await get('/offers?isActive=true');
  return res.data?.offers || res.data || [];
}

export async function getExperts() {
  const res = await get('/experts');
  return res.data?.experts || res.data || [];
}

export async function createAppointment(data) {
  return post('/appointments', data);
}

export async function applyCourse(courseId, data) {
  return post(`/courses/${courseId}/apply`, data);
}
