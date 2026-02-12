'use client';

import { useState, useEffect, useCallback } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { offersAPI, servicesAPI, coursesAPI } from '@/lib/api';
import { wsService } from '@/services/websocket';
import toast from 'react-hot-toast';

interface Offer {
  id: string;
  title: string;
  description?: string;
  discount_percentage?: number;
  discount_amount?: number;
  image_url?: string;
  start_date: string;
  end_date: string;
  is_active?: boolean;
  service_id?: string;
  course_id?: string;
  created_at?: string;
  updated_at?: string;
}

export default function OffersPage() {
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingOffer, setEditingOffer] = useState<Offer | null>(null);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive' | 'expired'>('all');
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    discountPercentage: '',
    discountAmount: '',
    imageUrl: '',
    startDate: '',
    endDate: '',
    isActive: true,
    serviceId: '',
    courseId: '',
  });
  const [services, setServices] = useState<{ id: string; name: string }[]>([]);
  const [courses, setCourses] = useState<{ id: string; title: string }[]>([]);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  // Memoize loadOffers to avoid recreating on every render
  const loadOffers = useCallback(async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (search) params.search = search;
      if (filter !== 'all') params.status = filter;
      const res = await offersAPI.getAll(params);
      const offersData = res.data?.data?.offers || res.data?.offers || [];
      setOffers(offersData);
    } catch (error: any) {
      console.error('Failed to load offers:', error);
      toast.error(error.response?.data?.message || 'Failed to load offers');
      setOffers([]);
    } finally {
      setLoading(false);
    }
  }, [search, filter]);

  // Load offers when search or filter changes
  useEffect(() => {
    loadOffers();
  }, [loadOffers]);

  // Load services and courses for offer linking
  const loadServicesAndCourses = useCallback(async () => {
    try {
      const [servicesRes, coursesRes] = await Promise.all([
        servicesAPI.getAllServices({ limit: 500 }),
        coursesAPI.getAll({ limit: 500 }),
      ]);
      const svcList = servicesRes.data?.data?.services || servicesRes.data?.services || [];
      const crsList = coursesRes.data?.data?.courses || coursesRes.data?.courses || coursesRes.data || [];
      setServices(svcList.map((s: any) => ({ id: s.id, name: s.name || s.title || s.id })));
      setCourses(Array.isArray(crsList) ? crsList.map((c: any) => ({ id: c.id, title: c.title || c.name || c.id })) : []);
    } catch (e) {
      console.error('Failed to load services/courses:', e);
    }
  }, []);

  useEffect(() => {
    if (showModal) loadServicesAndCourses();
  }, [showModal, loadServicesAndCourses]);

  // Setup WebSocket for real-time updates
  useEffect(() => {
    // Listen for real-time offer updates
    wsService.onOfferCreated = (data) => {
      console.log('🏷️ New offer created via WebSocket:', data);
      loadOffers();
      toast.success('New offer created!');
    };

    wsService.onOfferUpdated = (data) => {
      console.log('🏷️ Offer updated via WebSocket:', data);
      loadOffers();
      toast.success('Offer updated!');
    };

    wsService.onOfferDeleted = (data) => {
      console.log('🏷️ Offer deleted via WebSocket:', data);
      loadOffers();
      toast.success('Offer deleted!');
    };

    wsService.onOffersUpdated = (data) => {
      console.log('🏷️ Offers updated via WebSocket:', data);
      loadOffers();
    };

    // Connect WebSocket
    wsService.connect();

    // Cleanup on unmount
    return () => {
      wsService.onOfferCreated = undefined;
      wsService.onOfferUpdated = undefined;
      wsService.onOfferDeleted = undefined;
      wsService.onOffersUpdated = undefined;
    };
  }, [loadOffers]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const uploadImage = async (): Promise<string | null> => {
    if (!selectedFile) return formData.imageUrl || null;
    
    try {
      setUploading(true);
      const res = await servicesAPI.uploadImage(selectedFile, 'offers');
      // Backend returns: { success: true, data: { imageUrl: '...' } }
      const uploadedUrl = res.data?.data?.imageUrl || res.data?.imageUrl || res.data?.data?.url || res.data?.url || null;
      console.log('Image upload response:', res.data);
      console.log('Uploaded URL:', uploadedUrl);
      if (!uploadedUrl) {
        toast.error('Image uploaded but URL not received');
      }
      return uploadedUrl;
    } catch (error: any) {
      console.error('Failed to upload image:', error);
      toast.error(error.response?.data?.message || 'Failed to upload image');
      return null;
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim()) {
      toast.error('Title is required');
      return;
    }
    
    if (!formData.startDate || !formData.endDate) {
      toast.error('Start and end dates are required');
      return;
    }
    
    if (new Date(formData.endDate) < new Date(formData.startDate)) {
      toast.error('End date must be after start date');
      return;
    }

    try {
      let imageUrl = formData.imageUrl;
      if (selectedFile) {
        const uploadedUrl = await uploadImage();
        if (uploadedUrl) imageUrl = uploadedUrl;
      }

      const data: any = {
        title: formData.title,
        description: formData.description || undefined,
        startDate: formData.startDate,
        endDate: formData.endDate,
        isActive: formData.isActive,
        serviceId: formData.serviceId || undefined,
        courseId: formData.courseId || undefined,
      };

      // Only include one type of discount
      if (formData.discountPercentage) {
        data.discountPercentage = parseFloat(formData.discountPercentage);
      } else if (formData.discountAmount) {
        data.discountAmount = parseFloat(formData.discountAmount);
      }

      if (imageUrl) {
        data.imageUrl = imageUrl;
      }

      if (editingOffer) {
        await offersAPI.update(editingOffer.id, data);
        toast.success('Offer updated successfully');
      } else {
        await offersAPI.create(data);
        toast.success('Offer created successfully');
      }

      closeModal();
      loadOffers();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to save offer');
    }
  };

  const handleEdit = (offer: Offer) => {
    setEditingOffer(offer);
    setFormData({
      title: offer.title,
      description: offer.description || '',
      discountPercentage: offer.discount_percentage?.toString() || '',
      discountAmount: offer.discount_amount?.toString() || '',
      imageUrl: offer.image_url || '',
      startDate: offer.start_date ? offer.start_date.split('T')[0] : '',
      endDate: offer.end_date ? offer.end_date.split('T')[0] : '',
      isActive: offer.is_active !== false,
      serviceId: offer.service_id || '',
      courseId: offer.course_id || '',
    });
    setImagePreview(offer.image_url || null);
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this offer?')) return;
    try {
      await offersAPI.delete(id);
      toast.success('Offer deleted successfully');
      loadOffers();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete offer');
    }
  };

  const handleToggleActive = async (offer: Offer) => {
    try {
      await offersAPI.update(offer.id, { isActive: !offer.is_active });
      toast.success(`Offer ${offer.is_active ? 'deactivated' : 'activated'} successfully`);
      loadOffers();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update offer');
    }
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingOffer(null);
    setFormData({
      title: '',
      description: '',
      discountPercentage: '',
      discountAmount: '',
      imageUrl: '',
      startDate: '',
      endDate: '',
      isActive: true,
      serviceId: '',
      courseId: '',
    });
    setSelectedFile(null);
    setImagePreview(null);
  };

  const getOfferStatus = (offer: Offer) => {
    const now = new Date();
    const startDate = new Date(offer.start_date);
    const endDate = new Date(offer.end_date);

    if (!offer.is_active) {
      return { label: 'Inactive', color: 'bg-gray-100 text-gray-800' };
    }
    if (now < startDate) {
      return { label: 'Upcoming', color: 'bg-blue-100 text-blue-800' };
    }
    if (now > endDate) {
      return { label: 'Expired', color: 'bg-red-100 text-red-800' };
    }
    return { label: 'Active', color: 'bg-green-100 text-green-800' };
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatDiscount = (offer: Offer) => {
    if (offer.discount_percentage) {
      return `${offer.discount_percentage}% OFF`;
    }
    if (offer.discount_amount) {
      return `₹${offer.discount_amount} OFF`;
    }
    return 'Special Offer';
  };

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
              {/* Header */}
              <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Offers & Promotions</h1>
                <div className="flex flex-wrap gap-4">
                  <input
                    type="text"
                    placeholder="Search offers..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  />
                  <select
                    value={filter}
                    onChange={(e) => setFilter(e.target.value as any)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                  >
                    <option value="all">All Offers</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="expired">Expired</option>
                  </select>
                  <button
                    onClick={() => {
                      closeModal();
                      setShowModal(true);
                    }}
                    className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition whitespace-nowrap"
                  >
                    + Add Offer
                  </button>
                </div>
              </div>

              {/* Content */}
              {loading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500 mx-auto mb-4"></div>
                  <p className="text-gray-500">Loading offers...</p>
                </div>
              ) : offers.length === 0 ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <div className="text-6xl mb-4">🏷️</div>
                  <p className="text-gray-500 mb-4">No offers found</p>
                  <button
                    onClick={() => {
                      closeModal();
                      setShowModal(true);
                    }}
                    className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                  >
                    Create your first offer
                  </button>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {offers.map((offer) => {
                    const status = getOfferStatus(offer);
                    return (
                      <div key={offer.id} className="bg-white rounded-lg shadow overflow-hidden hover:shadow-lg transition-shadow">
                        {/* Offer Image */}
                        <div className="relative h-48 bg-gradient-to-br from-primary-400 to-primary-600">
                          {offer.image_url ? (
                            <img
                              src={offer.image_url}
                              alt={offer.title}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="flex items-center justify-center h-full">
                              <span className="text-6xl">🎁</span>
                            </div>
                          )}
                          {/* Discount Badge */}
                          <div className="absolute top-3 right-3 px-3 py-1 bg-red-500 text-white text-sm font-bold rounded-full shadow">
                            {formatDiscount(offer)}
                          </div>
                          {/* Status Badge */}
                          <div className={`absolute top-3 left-3 px-2 py-1 text-xs font-medium rounded-full ${status.color}`}>
                            {status.label}
                          </div>
                        </div>

                        {/* Offer Details */}
                        <div className="p-4">
                          <h3 className="text-lg font-semibold text-gray-800 mb-2 line-clamp-1">
                            {offer.title}
                          </h3>
                          <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                            {offer.description || 'No description provided'}
                          </p>
                          
                          {/* Dates */}
                          <div className="flex items-center text-sm text-gray-500 mb-4">
                            <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <span>{formatDate(offer.start_date)} - {formatDate(offer.end_date)}</span>
                          </div>

                          {/* Actions */}
                          <div className="flex items-center justify-between pt-3 border-t border-gray-100">
                            <button
                              onClick={() => handleToggleActive(offer)}
                              className={`px-3 py-1 text-sm rounded-lg transition ${
                                offer.is_active
                                  ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                  : 'bg-green-100 text-green-700 hover:bg-green-200'
                              }`}
                            >
                              {offer.is_active ? 'Deactivate' : 'Activate'}
                            </button>
                            <div className="flex gap-2">
                              <button
                                onClick={() => handleEdit(offer)}
                                className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition"
                                title="Edit"
                              >
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                </svg>
                              </button>
                              <button
                                onClick={() => handleDelete(offer.id)}
                                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                                title="Delete"
                              >
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                </svg>
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </main>
        </div>
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-800">
                  {editingOffer ? 'Edit Offer' : 'Create New Offer'}
                </h2>
                <button
                  onClick={closeModal}
                  className="p-2 hover:bg-gray-100 rounded-lg transition"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Title */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Title <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    placeholder="e.g., Summer Sale - 20% Off"
                    required
                  />
                </div>

                {/* Description */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <textarea
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    placeholder="Describe your offer..."
                    rows={3}
                  />
                </div>

                {/* Discount */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Discount Percentage
                    </label>
                    <div className="relative">
                      <input
                        type="number"
                        value={formData.discountPercentage}
                        onChange={(e) => setFormData({ ...formData, discountPercentage: e.target.value, discountAmount: '' })}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                        placeholder="e.g., 20"
                        min="0"
                        max="100"
                        step="0.01"
                      />
                      <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500">%</span>
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Or Fixed Amount
                    </label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">₹</span>
                      <input
                        type="number"
                        value={formData.discountAmount}
                        onChange={(e) => setFormData({ ...formData, discountAmount: e.target.value, discountPercentage: '' })}
                        className="w-full pl-8 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                        placeholder="e.g., 500"
                        min="0"
                        step="0.01"
                      />
                    </div>
                  </div>
                </div>

                {/* Dates */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Start Date <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="date"
                      value={formData.startDate}
                      onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      End Date <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="date"
                      value={formData.endDate}
                      onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      required
                    />
                  </div>
                </div>

                {/* Image Upload */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Offer Image
                  </label>
                  <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-lg hover:border-primary-400 transition">
                    <div className="space-y-1 text-center">
                      {imagePreview ? (
                        <div className="relative">
                          <img
                            src={imagePreview}
                            alt="Preview"
                            className="mx-auto h-32 w-auto rounded-lg object-cover"
                          />
                          <button
                            type="button"
                            onClick={() => {
                              setSelectedFile(null);
                              setImagePreview(null);
                              setFormData({ ...formData, imageUrl: '' });
                            }}
                            className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                      ) : (
                        <>
                          <svg className="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                            <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
                          </svg>
                          <div className="flex text-sm text-gray-600">
                            <label className="relative cursor-pointer bg-white rounded-md font-medium text-primary-600 hover:text-primary-500">
                              <span>Upload a file</span>
                              <input
                                type="file"
                                accept="image/*"
                                onChange={handleFileChange}
                                className="sr-only"
                              />
                            </label>
                            <p className="pl-1">or drag and drop</p>
                          </div>
                          <p className="text-xs text-gray-500">PNG, JPG up to 5MB</p>
                        </>
                      )}
                    </div>
                  </div>
                </div>

                {/* Link to Service or Course - tap takes user to specific screen */}
                <div className="space-y-3">
                  <label className="block text-sm font-medium text-gray-700">
                    Link to (optional)
                  </label>
                  <p className="text-xs text-gray-500">When user taps this offer in the app, they will be taken to the linked service or course.</p>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Service</label>
                      <select
                        value={formData.serviceId}
                        onChange={(e) => setFormData({ ...formData, serviceId: e.target.value, courseId: e.target.value ? '' : formData.courseId })}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      >
                        <option value="">— None —</option>
                        {services.map((s) => (
                          <option key={s.id} value={s.id}>{s.name}</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Course</label>
                      <select
                        value={formData.courseId}
                        onChange={(e) => setFormData({ ...formData, courseId: e.target.value, serviceId: e.target.value ? '' : formData.serviceId })}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                      >
                        <option value="">— None —</option>
                        {courses.map((c) => (
                          <option key={c.id} value={c.id}>{c.title}</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>

                {/* Active Toggle */}
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="isActive"
                    checked={formData.isActive}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <label htmlFor="isActive" className="ml-2 text-sm text-gray-700">
                    Active (visible to customers)
                  </label>
                </div>

                {/* Submit Buttons */}
                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={closeModal}
                    className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={uploading}
                    className="flex-1 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {uploading ? 'Uploading...' : editingOffer ? 'Update Offer' : 'Create Offer'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </AuthGuard>
  );
}
