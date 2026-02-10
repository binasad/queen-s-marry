'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { expertsAPI, servicesAPI } from '@/lib/api';
import toast from 'react-hot-toast';

interface Expert {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  specialty?: string;
  bio?: string;
  image_url?: string;
  rating?: number;
  total_reviews?: number;
  is_active?: boolean;
  services?: any[];
}

export default function ExpertsPage() {
  const [experts, setExperts] = useState<Expert[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingExpert, setEditingExpert] = useState<Expert | null>(null);
  const [services, setServices] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    specialty: '',
    bio: '',
    imageUrl: '',
    serviceIds: [] as string[],
  });

  useEffect(() => {
    loadExperts();
    loadServices();
  }, [search]);

  const loadExperts = async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (search) params.search = search;
      const res = await expertsAPI.getAll(params);
      setExperts(res.data.data.experts || []);
    } catch (error: any) {
      console.error('Failed to load experts:', error);
      toast.error(error.response?.data?.message || 'Failed to load experts');
    } finally {
      setLoading(false);
    }
  };

  const loadServices = async () => {
    try {
      const res = await servicesAPI.getAllServices();
      setServices(res.data.data.services || []);
    } catch (error) {
      console.error('Failed to load services:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const data = {
        name: formData.name,
        email: formData.email || null,
        phone: formData.phone || null,
        specialty: formData.specialty || null,
        bio: formData.bio || null,
        imageUrl: formData.imageUrl || null,
        serviceIds: formData.serviceIds,
      };

      if (editingExpert) {
        await expertsAPI.update(editingExpert.id, data);
        toast.success('Expert updated successfully');
      } else {
        await expertsAPI.create(data);
        toast.success('Expert created successfully');
      }

      setShowModal(false);
      setFormData({ name: '', email: '', phone: '', specialty: '', bio: '', imageUrl: '', serviceIds: [] });
      setEditingExpert(null);
      loadExperts();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to save expert');
    }
  };

  const handleEdit = (expert: Expert) => {
    setEditingExpert(expert);
    setFormData({
      name: expert.name,
      email: expert.email || '',
      phone: expert.phone || '',
      specialty: expert.specialty || '',
      bio: expert.bio || '',
      imageUrl: expert.image_url || '',
      serviceIds: expert.services?.map((s: any) => s.id) || [],
    });
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this expert?')) return;
    try {
      await expertsAPI.delete(id);
      toast.success('Expert deleted successfully');
      loadExperts();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete expert');
    }
  };

  const handleToggleActive = async (expert: Expert) => {
    try {
      await expertsAPI.update(expert.id, { isActive: !expert.is_active });
      toast.success(`Expert ${expert.is_active ? 'deactivated' : 'activated'} successfully`);
      loadExperts();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update expert');
    }
  };

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
              <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Experts</h1>
                <div className="flex gap-4">
                  <input
                    type="text"
                    placeholder="Search experts..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                  />
                  <button
                    onClick={() => {
                      setEditingExpert(null);
                      setFormData({ name: '', email: '', phone: '', specialty: '', bio: '', imageUrl: '', serviceIds: [] });
                      setShowModal(true);
                    }}
                    className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                  >
                    + Add Expert
                  </button>
                </div>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <p className="text-gray-500">Loading experts...</p>
                </div>
              ) : experts.length === 0 ? (
                <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                  No experts found
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {experts.map((expert) => (
                    <div key={expert.id} className="bg-white rounded-lg shadow overflow-hidden">
                      {expert.image_url && (
                        <img
                          src={expert.image_url}
                          alt={expert.name}
                          className="w-full h-48 object-cover"
                        />
                      )}
                      <div className="p-6">
                        <div className="flex items-start justify-between mb-2">
                          <h3 className="text-xl font-semibold text-gray-800">{expert.name}</h3>
                          {expert.is_active === false && (
                            <span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded">
                              Inactive
                            </span>
                          )}
                        </div>
                        {expert.specialty && (
                          <p className="text-sm text-primary-600 mb-2">{expert.specialty}</p>
                        )}
                        {expert.rating && (
                          <div className="flex items-center gap-2 mb-2">
                            <span className="text-yellow-500">⭐</span>
                            <span className="text-sm text-gray-600">
                              {expert.rating.toFixed(1)} ({expert.total_reviews || 0} reviews)
                            </span>
                          </div>
                        )}
                        {expert.email && (
                          <p className="text-sm text-gray-600 mb-1">{expert.email}</p>
                        )}
                        {expert.phone && (
                          <p className="text-sm text-gray-600 mb-4">{expert.phone}</p>
                        )}
                        {expert.bio && (
                          <p className="text-sm text-gray-600 mb-4 line-clamp-2">{expert.bio}</p>
                        )}
                        <div className="flex space-x-2">
                          <button
                            onClick={() => handleEdit(expert)}
                            className="flex-1 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition text-sm"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleToggleActive(expert)}
                            className={`flex-1 px-4 py-2 rounded transition text-sm ${
                              expert.is_active
                                ? 'bg-yellow-500 text-white hover:bg-yellow-600'
                                : 'bg-green-500 text-white hover:bg-green-600'
                            }`}
                          >
                            {expert.is_active ? 'Deactivate' : 'Activate'}
                          </button>
                          <button
                            onClick={() => handleDelete(expert.id)}
                            className="flex-1 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition text-sm"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Modal */}
              {showModal && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                  <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
                    <h2 className="text-2xl font-bold mb-4">
                      {editingExpert ? 'Edit Expert' : 'Add New Expert'}
                    </h2>
                    <form onSubmit={handleSubmit} className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Name *
                        </label>
                        <input
                          type="text"
                          required
                          value={formData.name}
                          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Email
                          </label>
                          <input
                            type="email"
                            value={formData.email}
                            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                          />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Phone
                          </label>
                          <input
                            type="tel"
                            value={formData.phone}
                            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                          />
                        </div>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Specialty
                        </label>
                        <input
                          type="text"
                          value={formData.specialty}
                          onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Bio
                        </label>
                        <textarea
                          value={formData.bio}
                          onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
                          rows={4}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Image URL
                        </label>
                        <input
                          type="url"
                          placeholder="https://example.com/image.jpg"
                          value={formData.imageUrl}
                          onChange={(e) => setFormData({ ...formData, imageUrl: e.target.value })}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Services
                        </label>
                        <div className="max-h-40 overflow-y-auto border border-gray-300 rounded-lg p-2">
                          {services.map((service) => (
                            <label key={service.id} className="flex items-center gap-2 p-2 hover:bg-gray-50">
                              <input
                                type="checkbox"
                                checked={formData.serviceIds.includes(service.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setFormData({ ...formData, serviceIds: [...formData.serviceIds, service.id] });
                                  } else {
                                    setFormData({ ...formData, serviceIds: formData.serviceIds.filter(id => id !== service.id) });
                                  }
                                }}
                                className="w-4 h-4 text-primary-500 rounded focus:ring-primary-500"
                              />
                              <span className="text-sm">{service.name}</span>
                            </label>
                          ))}
                        </div>
                      </div>
                      <div className="flex gap-4 pt-4">
                        <button
                          type="submit"
                          className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                        >
                          {editingExpert ? 'Update' : 'Create'} Expert
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setShowModal(false);
                            setEditingExpert(null);
                            setFormData({ name: '', email: '', phone: '', specialty: '', bio: '', imageUrl: '', serviceIds: [] });
                          }}
                          className="flex-1 px-6 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
                        >
                          Cancel
                        </button>
                      </div>
                    </form>
                  </div>
                </div>
              )}
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
