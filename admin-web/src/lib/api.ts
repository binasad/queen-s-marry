import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || (process.env.NEXT_PUBLIC_BACKEND_URL ? `${process.env.NEXT_PUBLIC_BACKEND_URL}/api/v1` : 'http://44.215.209.41:5000/api/v1');

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login if unauthorized
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;

// Auth API
export const authAPI = {
  login: (credentials: { email: string; password: string }) =>
    api.post('/auth/login', credentials),
  
  getProfile: () => api.get('/profile'),
  
  updateProfile: (data: any) => api.put('/profile', data),
  
  changePassword: (data: { currentPassword: string; newPassword: string }) =>
    api.post('/auth/change-password', data),
  
  verifySetupToken: (token: string) =>
    api.get(`/auth/setup-password/${encodeURIComponent(token)}`),
  
  setPassword: (data: { token: string; password: string }) =>
    api.post('/auth/set-password', data),
};

// Services API
export const servicesAPI = {
  getCategories: () => api.get('/categories'),
  
  createCategory: (data: { name: string; description?: string; imageUrl?: string; icon?: string; displayOrder?: number }) =>
    api.post('/categories', data),
  
  getAllServices: (params?: any) => api.get('/services', { params }),
  
  getServiceById: (id: string) => api.get(`/services/${id}`),
  
  createService: (data: any) => api.post('/services', data),
  
  updateService: (id: string, data: any) => api.put(`/services/${id}`, data),
  
  deleteService: (id: string) => api.delete(`/services/${id}`),
  
  getExperts: (params?: any) => api.get('/experts', { params }),

  uploadImage: (file: File, folder?: string) => {
    const formData = new FormData();
    formData.append('image', file);
    if (folder) {
      formData.append('folder', folder);
    }
    return api.post('/upload-image', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
};

// Appointments API
export const appointmentsAPI = {
  getAll: (params?: any) => api.get('/appointments', { params }),
  
  updateStatus: (id: string, data: { status: string; cancelReason?: string }) =>
    api.put(`/appointments/${id}/status`, data),
  
  markAsPaid: (id: string, data: { paymentMethod: string }) =>
    api.put(`/appointments/${id}/pay`, data),
  
  delete: (id: string) => api.delete(`/appointments/${id}`),
  
  getDashboardStats: () => api.get('/dashboard/stats'),
};

// Users/Customers API
export const usersAPI = {
  getAll: (params?: any) => api.get('/users', { params }),
  
  getById: (id: string) => api.get(`/users/${id}`),
  
  delete: (id: string) => api.delete(`/users/${id}`),
  
  assignRoleByEmail: (data: { email: string; roleId: string }) =>
    api.post('/users/assign-role', data),
  
  assignRoleToMultiple: (data: { emails: string[]; roleId: string }) =>
    api.post('/users/assign-role-multiple', data),
};

// Courses API
export const coursesAPI = {
  getAll: (params?: any) => api.get('/courses', { params }),
  
  getById: (id: string) => api.get(`/courses/${id}`),
  
  getApplications: () => api.get('/courses/admin/applications'),
  
  create: (data: any) => api.post('/courses', data),
  
  update: (id: string, data: any) => api.put(`/courses/${id}`, data),
  
  delete: (id: string) => api.delete(`/courses/${id}`),
};

// Experts API
export const expertsAPI = {
  getAll: (params?: any) => api.get('/experts', { params }),
  
  getById: (id: string) => api.get(`/experts/${id}`),
  
  create: (data: any) => api.post('/experts', data),
  
  update: (id: string, data: any) => api.put(`/experts/${id}`, data),
  
  delete: (id: string) => api.delete(`/experts/${id}`),
};

// Blogs API
export const blogsAPI = {
  getAll: (params?: any) => api.get('/blogs', { params }),
  getAllAdmin: (params?: any) => api.get('/blogs/admin', { params }),
  getById: (id: string) => api.get(`/blogs/${id}`),
  create: (data: any) => api.post('/blogs', data),
  update: (id: string, data: any) => api.put(`/blogs/${id}`, data),
  delete: (id: string) => api.delete(`/blogs/${id}`),
};

// Support/Tickets API
export const supportAPI = {
  getAll: (params?: any) => api.get('/support/tickets', { params }),
  
  getById: (id: string) => api.get(`/support/tickets/${id}`),
  
  create: (data: any) => api.post('/support/tickets', data),
  
  update: (id: string, data: any) => api.put(`/support/tickets/${id}`, data),
  
  delete: (id: string) => api.delete(`/support/tickets/${id}`),
};

// Roles API
export const rolesAPI = {
  getPermissions: () => api.get('/permissions'),
  
  getRoles: () => api.get('/roles'),
  
  createRole: (data: { name: string; permissions: string[] }) =>
    api.post('/roles', data),
  
  updateRolePermissions: (roleId: string, permissions: string[]) =>
    api.put(`/roles/${roleId}/permissions`, { permissions }),
};

// Reports & Sales API
export const reportsAPI = {
  getSalesOverview: () => api.get('/reports/sales'),
  getReports: (params?: { startDate?: string; endDate?: string }, config?: any) =>
    api.get('/reports/data', { params, ...config }),
  getTransactions: (params?: { startDate?: string; endDate?: string; page?: number; limit?: number }) =>
    api.get('/reports/transactions', { params }),
};

// Offers API
export const offersAPI = {
  getAll: (params?: any) => api.get('/offers/admin', { params }),
  
  getById: (id: string) => api.get(`/offers/${id}`),
  
  create: (data: any) => api.post('/offers', data),
  
  update: (id: string, data: any) => api.put(`/offers/${id}`, data),
  
  delete: (id: string) => api.delete(`/offers/${id}`),
};
