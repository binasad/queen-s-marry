'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { authAPI } from '@/lib/api';
import { servicesAPI } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import toast from 'react-hot-toast';

export default function ProfilePage() {
  const { user, updateUser } = useAuthStore();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [sendingResetLink, setSendingResetLink] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    address: '',
    profileImageUrl: '',
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      setLoading(true);
      const res = await authAPI.getProfile();
      const data = res.data?.data || res.data;
      const u = data?.user || data;
      setProfile(u);
      const imageUrl = u?.profile_image_url || '';
      setFormData({
        name: u?.name || '',
        phone: u?.phone || '',
        address: u?.address || '',
        profileImageUrl: imageUrl,
      });
      setImagePreview(imageUrl || null);
      // Sync profile image to auth store so Header shows it
      if (imageUrl) updateUser({ profileImage: imageUrl });
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to load profile');
    } finally {
      setLoading(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => setImagePreview(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSaving(true);
      let profileImageUrl = formData.profileImageUrl;
      if (selectedFile) {
        const uploadRes = await servicesAPI.uploadImage(selectedFile, 'profiles');
        const url = uploadRes.data?.data?.imageUrl || uploadRes.data?.imageUrl || uploadRes.data?.url;
        if (url) profileImageUrl = url;
      }
      await authAPI.updateProfile({
        name: formData.name,
        phone: formData.phone || undefined,
        address: formData.address || undefined,
        profileImageUrl: profileImageUrl || undefined,
      });
      updateUser({
        name: formData.name,
        profileImage: profileImageUrl,
      });
      toast.success('Profile updated successfully');
      setSelectedFile(null);
      loadProfile();
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  const handleSendResetLink = async () => {
    const email = profile?.email || user?.email;
    if (!email) {
      toast.error('No email found');
      return;
    }
    try {
      setSendingResetLink(true);
      await authAPI.forgotPassword({ email, client: 'admin' });
      toast.success('Password reset link sent to your email. Check your inbox.');
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to send reset link');
    } finally {
      setSendingResetLink(false);
    }
  };

  const getInitials = (name: string) =>
    name?.split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2) || '?';

  const roleName = profile?.role?.name || user?.role || 'User';

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-2xl mx-auto">
              <h1 className="text-2xl font-bold text-gray-800 mb-6">My Profile</h1>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-12 text-center">
                  <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-500 mx-auto" />
                </div>
              ) : (
                <>
                  {/* Profile card with role */}
                  <div className="bg-white rounded-lg shadow p-6 mb-6">
                    <div className="flex items-center gap-6 mb-6">
                      <div className="relative">
                        <div className="w-24 h-24 rounded-full overflow-hidden bg-primary-100 flex items-center justify-center">
                          {imagePreview ? (
                            <img
                              src={imagePreview}
                              alt="Profile"
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <span className="text-3xl font-bold text-primary-600">
                              {getInitials(formData.name || user?.name || '')}
                            </span>
                          )}
                        </div>
                        <label className="absolute bottom-0 right-0 bg-primary-500 text-white rounded-full p-1.5 cursor-pointer hover:bg-primary-600">
                          <input
                            type="file"
                            accept="image/*"
                            className="hidden"
                            onChange={handleFileChange}
                          />
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                          </svg>
                        </label>
                      </div>
                      <div>
                        <h2 className="text-xl font-bold text-gray-800">{formData.name || profile?.name}</h2>
                        <p className="text-gray-600">{profile?.email}</p>
                        <span className="inline-block mt-2 px-3 py-1 text-sm font-medium rounded-full bg-primary-100 text-primary-800">
                          {roleName}
                        </span>
                      </div>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                        <input
                          type="text"
                          value={formData.name}
                          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input
                          type="email"
                          value={profile?.email || ''}
                          disabled
                          className="w-full px-4 py-2 border border-gray-200 rounded-lg bg-gray-50 text-gray-500"
                        />
                        <p className="text-xs text-gray-500 mt-1">Email cannot be changed</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                        <input
                          type="tel"
                          value={formData.phone}
                          onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
                        <textarea
                          value={formData.address}
                          onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                          rows={2}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <button
                        type="submit"
                        disabled={saving}
                        className="w-full px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 disabled:opacity-50"
                      >
                        {saving ? 'Saving...' : 'Save Profile'}
                      </button>
                    </form>
                  </div>

                  {/* Change password via email link */}
                  <div className="bg-white rounded-lg shadow p-6">
                    <h3 className="text-lg font-semibold text-gray-800 mb-4">Change Password</h3>
                    <p className="text-sm text-gray-600 mb-4">
                      Click the button below to receive a password reset link at <strong>{profile?.email}</strong>. The link will expire in 1 hour.
                    </p>
                    <button
                      type="button"
                      onClick={handleSendResetLink}
                      disabled={sendingResetLink}
                      className="w-full px-4 py-2 bg-gray-800 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50"
                    >
                      {sendingResetLink ? 'Sending...' : 'Send password reset link to my email'}
                    </button>
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
