'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { authAPI } from '@/lib/api';
import toast from 'react-hot-toast';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const { isAuthenticated, login } = useAuthStore();

  // Redirect if already logged in
  useEffect(() => {
    if (isAuthenticated) {
      router.push('/dashboard');
    }
  }, [isAuthenticated, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Regular login flow
      const loginResponse = await authAPI.login({ email, password });
      
      console.log('Login response:', loginResponse);
      
      if (!loginResponse.data || !loginResponse.data.success) {
        const errorMessage = loginResponse.data?.message || loginResponse.data?.error || 'Login failed';
        throw new Error(errorMessage);
      }
      
      const { data } = loginResponse.data;
      const userData = data.user;
      
      // Get access token (could be accessToken or token)
      const accessToken = data.accessToken || data.token;
      
      if (!accessToken) {
        console.error('No token in response:', data);
        throw new Error('No access token received from server');
      }
      
      if (!userData) {
        console.error('No user data in response:', data);
        throw new Error('No user data received from server');
      }
      
      // Store token
      localStorage.setItem('token', accessToken);
      
      // Extract role and permissions
      const roleName = userData.role?.name || 'User';
      const roleId = userData.role?.id || userData.role_id || null;
      const permissions = userData.role?.permissions || [];
      
      console.log('Logging in user:', {
        id: userData.id,
        name: userData.name,
        email: userData.email,
        role: roleName,
        roleId,
        permissions
      });
      
      // Login with full user data including permissions
      login({
        id: userData.id,
        name: userData.name,
        email: userData.email,
        role: roleName,
        roleId: roleId,
        permissions: permissions,
        profileImage: userData.profileImage || userData.profile_image_url,
      }, accessToken);
      
      toast.success('Login successful!');
      
      // Redirect to saved path or dashboard
      const redirectPath = sessionStorage.getItem('redirectAfterLogin') || '/dashboard';
      sessionStorage.removeItem('redirectAfterLogin');
      router.push(redirectPath);
    } catch (error: any) {
      console.error('Login error:', error);
      const errorMessage = error.response?.data?.message || error.message || 'Login failed. Please check your credentials.';
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-pink-100 to-purple-100">
      <div className="max-w-md w-full mx-4">
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          {/* Logo/Header */}
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-800 mb-2">BeautyHub</h1>
            <p className="text-gray-500 text-sm mb-1">Marry-Queen Salon</p>
            <p className="text-gray-600">Sign in to manage your salon</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                Email Address
              </label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="Enter your email"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <input
                id="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="••••••••"
              />
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-primary-500 hover:bg-primary-600 text-white font-semibold py-3 px-4 rounded-lg transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          {/* Footer */}
          <div className="mt-6 text-center text-sm text-gray-600">
            <p>© 2026 Salon App. All rights reserved.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
