'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { authAPI } from '@/lib/api';
import toast from 'react-hot-toast';
import Link from 'next/link';

export default function ResetPasswordPage() {
  const params = useParams();
  const token = (params?.token as string) || '';
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  useEffect(() => {
    if (!token) {
      toast.error('Invalid or missing reset link. Please request a new one.');
    }
  }, [token]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirmPassword) {
      toast.error('Passwords do not match');
      return;
    }
    const passwordRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(password)) {
      toast.error('Password must be 8+ characters with uppercase, number, and special character');
      return;
    }

    setIsLoading(true);
    try {
      const res = await authAPI.resetPassword({ token, newPassword: password });
      if (res.data?.success) {
        toast.success('Password reset successfully! Redirecting to login...');
        setTimeout(() => router.push('/login'), 2000);
      } else {
        toast.error(res.data?.message || 'Failed to reset password');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Invalid or expired link. Please request a new reset link.');
    } finally {
      setIsLoading(false);
    }
  };

  if (!token) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-pink-100 to-purple-100">
        <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md text-center">
          <h1 className="text-xl font-bold text-gray-800 mb-4">Invalid Reset Link</h1>
          <p className="text-gray-600 mb-6">Please request a new password reset link from your profile.</p>
          <Link href="/login" className="text-primary-600 font-medium hover:underline">Go to Login</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-pink-100 to-purple-100">
      <div className="max-w-md w-full mx-4">
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-800 mb-2">Reset Your Password</h1>
            <p className="text-gray-600">Enter your new password below</p>
          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <p className="text-sm font-semibold text-blue-800 mb-2">Password requirements:</p>
            <ul className="text-xs text-blue-700 space-y-1">
              <li>• At least 8 characters</li>
              <li>• One uppercase letter</li>
              <li>• One number</li>
              <li>• One special character (@$!%*?&)</li>
            </ul>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">New Password</label>
              <input
                type="password"
                required
                minLength={8}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                placeholder="Enter new password"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Confirm Password</label>
              <input
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                placeholder="Confirm new password"
              />
            </div>
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-primary-500 hover:bg-primary-600 text-white font-semibold py-3 px-4 rounded-lg disabled:opacity-50"
            >
              {isLoading ? 'Resetting...' : 'Reset Password'}
            </button>
          </form>

          <div className="mt-6 text-center text-sm">
            <Link href="/login" className="text-primary-600 hover:underline">Back to Login</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
