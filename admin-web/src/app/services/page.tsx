'use client';

import { useState, useEffect, useCallback } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { servicesAPI } from '@/lib/api';
import { wsService } from '@/services/websocket';
import toast from 'react-hot-toast';

interface Service {
  id: string;
  name: string;
  description?: string;
  price: number;
  duration: number;
  image_url?: string;
  category_id?: string;
  category_name?: string;
  is_active?: boolean;
  tags?: string[];
}

export default function ServicesPage() {
  const [showModal, setShowModal] = useState(false);
  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [editingService, setEditingService] = useState<Service | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');

  // Memoize loadServices to avoid recreating on every render
  const loadServices = useCallback(async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (search) params.search = search;
      if (selectedCategory) params.categoryId = selectedCategory;
      const res = await servicesAPI.getAllServices(params);
      // Handle both response formats: { data: { services: [...] } } or { services: [...] }
      const servicesData = res.data?.data?.services || res.data?.services || [];
      setServices(servicesData);
    } catch (error: any) {
      console.error('Failed to load services:', error);
      toast.error(error.response?.data?.message || 'Failed to load services');
      setServices([]);
    } finally {
      setLoading(false);
    }
  }, [search, selectedCategory]);

  // Load services when search or category changes
  useEffect(() => {
    loadServices();
  }, [loadServices]);

  // Load categories and setup WebSocket once on mount
  useEffect(() => {
    loadCategories();

    // Listen for real-time service updates
    wsService.onServiceCreated = (data) => {
      console.log('💇 New service created via WebSocket:', data);
      loadServices(); // Refresh the list
      toast.success('New service created!');
    };

    wsService.onServiceUpdated = (data) => {
      console.log('💇 Service updated via WebSocket:', data);
      loadServices(); // Refresh the list
      toast.success('Service updated!');
    };

    wsService.onServiceDeleted = (data) => {
      console.log('💇 Service deleted via WebSocket:', data);
      loadServices(); // Refresh the list
      toast.success('Service deleted!');
    };

    // Connect WebSocket
    wsService.connect();

    // Cleanup on unmount
    return () => {
      wsService.onServiceCreated = undefined;
      wsService.onServiceUpdated = undefined;
      wsService.onServiceDeleted = undefined;
    };
  }, [loadServices]);

  const loadCategories = async () => {
    try {
      const res = await servicesAPI.getCategories();
      // Handle different response formats
      const cats = res.data?.data?.categories || res.data?.data || res.data || [];
      setCategories(cats);
    } catch (error) {
      console.error('Failed to load categories:', error);
    }
  };

  const [formData, setFormData] = useState({
    categoryId: '',
    name: '',
    description: '',
    price: '',
    duration: '',
    imageUrl: '',
    tags: '',
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  
  // Category form state
  const [categoryFormData, setCategoryFormData] = useState({
    name: '',
    description: '',
    imageUrl: '',
  });
  const [categorySelectedFile, setCategorySelectedFile] = useState<File | null>(null);
  const [categoryImagePreview, setCategoryImagePreview] = useState<string | null>(null);
  const [categoryUploading, setCategoryUploading] = useState(false);

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this service?')) return;
    try {
      await servicesAPI.deleteService(id);
      toast.success('Service deleted successfully');
      // Refresh the services list
      await loadServices();
    } catch (error: any) {
      console.error('Delete service error:', error);
      toast.error(error.response?.data?.message || 'Failed to delete service');
    }
  };

  const handleToggleActive = async (service: Service) => {
    try {
      const newStatus = !service.is_active;
      await servicesAPI.updateService(service.id, { isActive: newStatus });
      toast.success(`Service ${newStatus ? 'activated' : 'deactivated'} successfully`);
      await loadServices();
    } catch (error: any) {
      console.error('Toggle service status error:', error);
      toast.error(error.response?.data?.message || 'Failed to update service status');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const description = formData.description.trim();
      const imageUrl = formData.imageUrl.trim();

      const serviceData = {
        categoryId: formData.categoryId,
        name: formData.name,
        // IMPORTANT: backend validation uses `.optional()` (does NOT treat `null` as optional)
        // so we must send `undefined` instead of `null`/empty string.
        description: description ? description : undefined,
        price: parseFloat(formData.price),
        duration: parseInt(formData.duration),
        imageUrl: imageUrl ? imageUrl : undefined,
        tags: formData.tags ? formData.tags.split(',').map(t => t.trim()).filter(t => t) : [],
      };

      if (editingService) {
        await servicesAPI.updateService(editingService.id, serviceData);
        toast.success('Service updated successfully');
      } else {
        await servicesAPI.createService(serviceData);
        toast.success('Service created successfully');
      }

      setShowModal(false);
      setEditingService(null);
      setFormData({
        categoryId: '',
        name: '',
        description: '',
        price: '',
        duration: '',
        imageUrl: '',
        tags: '',
      });
      // Refresh the services list
      await loadServices();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to save service');
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        toast.error('Please select an image file');
        return;
      }
      // Validate file size (5MB)
      if (file.size > 5 * 1024 * 1024) {
        toast.error('Image size must be less than 5MB');
        return;
      }
      setSelectedFile(file);
      // Create preview
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUploadImage = async () => {
    if (!selectedFile) {
      toast.error('Please select an image file');
      return;
    }

    try {
      setUploading(true);
      const folder = formData.categoryId ? 'services' : 'assets';
      const res = await servicesAPI.uploadImage(selectedFile, folder);
      const imageUrl = res.data?.data?.imageUrl;
      if (imageUrl) {
        setFormData({ ...formData, imageUrl });
        setSelectedFile(null);
        setImagePreview(null);
        toast.success('Image uploaded successfully');
      }
    } catch (error: any) {
      console.error('Upload error:', error);
      toast.error(error.response?.data?.message || 'Failed to upload image');
    } finally {
      setUploading(false);
    }
  };

  const handleCategoryFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        toast.error('Please select an image file');
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        toast.error('Image size must be less than 5MB');
        return;
      }
      setCategorySelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setCategoryImagePreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleCategoryUploadImage = async () => {
    if (!categorySelectedFile) {
      toast.error('Please select an image file');
      return;
    }

    try {
      setCategoryUploading(true);
      const res = await servicesAPI.uploadImage(categorySelectedFile, 'categories');
      const imageUrl = res.data?.data?.imageUrl;
      if (imageUrl) {
        setCategoryFormData({ ...categoryFormData, imageUrl });
        setCategorySelectedFile(null);
        setCategoryImagePreview(null);
        toast.success('Image uploaded successfully');
      }
    } catch (error: any) {
      console.error('Upload error:', error);
      toast.error(error.response?.data?.message || 'Failed to upload image');
    } finally {
      setCategoryUploading(false);
    }
  };

  const handleCategorySubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const description = categoryFormData.description.trim();
      const imageUrl = categoryFormData.imageUrl.trim();

      await servicesAPI.createCategory({
        name: categoryFormData.name,
        description: description || undefined,
        imageUrl: imageUrl || undefined,
      });

      toast.success('Category created successfully');
      setShowCategoryModal(false);
      setCategoryFormData({
        name: '',
        description: '',
        imageUrl: '',
      });
      setCategorySelectedFile(null);
      setCategoryImagePreview(null);
      await loadCategories();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to create category');
    }
  };

  const handleEdit = (service: Service) => {
    setEditingService(service);
    setFormData({
      categoryId: service.category_id || '',
      name: service.name,
      description: service.description || '',
      price: service.price.toString(),
      duration: service.duration.toString(),
      imageUrl: service.image_url || '',
      tags: service.tags ? service.tags.join(', ') : '',
    });
    setSelectedFile(null);
    setImagePreview(service.image_url || null);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingService(null);
    setFormData({
      categoryId: '',
      name: '',
      description: '',
      price: '',
      duration: '',
      imageUrl: '',
      tags: '',
    });
    setSelectedFile(null);
    setImagePreview(null);
  };

  // Group services by category
  const servicesByCategory = services.reduce((acc, service) => {
    const categoryName = service.category_name || 'Uncategorized';
    if (!acc[categoryName]) {
      acc[categoryName] = [];
    }
    acc[categoryName].push(service);
    return acc;
  }, {} as Record<string, Service[]>);

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Services</h1>
              <div className="flex gap-4 flex-wrap">
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                >
                  <option value="">All Categories</option>
                  {categories.map((category) => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </select>
                <input
                  type="text"
                  placeholder="Search services..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                />
                <button
                  onClick={() => setShowCategoryModal(true)}
                  className="px-6 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition"
                >
                  + Add Category
                </button>
                <button
                  onClick={() => {
                    setEditingService(null);
                    setShowModal(true);
                  }}
                  className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                >
                  + Add Service
                </button>
              </div>
            </div>

            {loading ? (
              <div className="bg-white rounded-lg shadow p-8 text-center">
                <p className="text-gray-500">Loading services...</p>
              </div>
            ) : services.length === 0 ? (
              <div className="bg-white rounded-lg shadow p-8 text-center">
                <p className="text-gray-500 mb-4">No services found</p>
                <p className="text-sm text-gray-400 mb-4">
                  {selectedCategory || search ? 'Try adjusting your filters' : 'Create your first service to get started'}
                </p>
                <button
                  onClick={() => {
                    setEditingService(null);
                    setShowModal(true);
                  }}
                  className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                >
                  + Add Service
                </button>
              </div>
            ) : (
              <div className="bg-white rounded-lg shadow overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        {!selectedCategory && (
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Category
                          </th>
                        )}
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Service Name
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Description
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Price
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Duration
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Tags
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {services.map((service) => (
                        <tr key={service.id} className="hover:bg-gray-50 transition">
                          {!selectedCategory && (
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className="text-sm font-medium text-gray-900">
                                {service.category_name || 'Uncategorized'}
                              </span>
                            </td>
                          )}
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-semibold text-gray-900">{service.name}</div>
                          </td>
                          <td className="px-6 py-4">
                            <div className="text-sm text-gray-600 max-w-xs truncate" title={service.description || ''}>
                              {service.description || <span className="text-gray-400">No description</span>}
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="text-sm font-bold text-primary-500">
                              Rs. {service.price.toLocaleString()}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="text-sm text-gray-600">{service.duration} min</span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            {service.is_active === false ? (
                              <span className="px-2 py-1 text-xs font-semibold bg-red-100 text-red-800 rounded-full">
                                Inactive
                              </span>
                            ) : (
                              <span className="px-2 py-1 text-xs font-semibold bg-green-100 text-green-800 rounded-full">
                                Active
                              </span>
                            )}
                          </td>
                          <td className="px-6 py-4">
                            <div className="flex flex-wrap gap-1">
                              {service.tags && service.tags.length > 0 ? (
                                service.tags.slice(0, 2).map((tag, idx) => (
                                  <span
                                    key={idx}
                                    className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded"
                                  >
                                    {tag}
                                  </span>
                                ))
                              ) : (
                                <span className="text-xs text-gray-400">—</span>
                              )}
                              {service.tags && service.tags.length > 2 && (
                                <span className="text-xs text-gray-500">+{service.tags.length - 2}</span>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                            <div className="flex justify-end gap-2">
                              <button
                                onClick={() => handleToggleActive(service)}
                                className={`px-3 py-1 rounded transition text-sm ${
                                  service.is_active === false
                                    ? 'bg-green-500 text-white hover:bg-green-600'
                                    : 'bg-yellow-500 text-white hover:bg-yellow-600'
                                }`}
                                title={service.is_active === false ? 'Activate service' : 'Deactivate service'}
                              >
                                {service.is_active === false ? 'Activate' : 'Deactivate'}
                              </button>
                              <button
                                onClick={() => handleEdit(service)}
                                className="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600 transition text-sm"
                              >
                                Edit
                              </button>
                              <button
                                onClick={() => handleDelete(service.id)}
                                className="px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600 transition text-sm"
                              >
                                Delete
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                {services.length > 0 && (
                  <div className="bg-gray-50 px-6 py-3 border-t border-gray-200">
                    <p className="text-sm text-gray-600">
                      Showing <span className="font-semibold">{services.length}</span> service{services.length !== 1 ? 's' : ''}
                    </p>
                  </div>
                )}
              </div>
            )}

            {/* Add/Edit Service Modal */}
            {showModal && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
                  <h2 className="text-2xl font-bold mb-4">
                    {editingService ? 'Edit Service' : 'Add New Service'}
                  </h2>
                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Category *
                      </label>
                      <select
                        required
                        value={formData.categoryId}
                        onChange={(e) => setFormData({ ...formData, categoryId: e.target.value })}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                      >
                        <option value="">-- Select a category --</option>
                        {categories.map((category) => (
                          <option key={category.id} value={category.id}>
                            {category.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Service Name *
                      </label>
                      <input
                        type="text"
                        required
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        placeholder="e.g., Hair Coloring"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Description
                      </label>
                      <textarea
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                        rows={4}
                        placeholder="Service description..."
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Price (Rs.) *
                        </label>
                        <input
                          type="number"
                          step="0.01"
                          required
                          min="0"
                          value={formData.price}
                          onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                          placeholder="0.00"
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Duration (minutes) *
                        </label>
                        <input
                          type="number"
                          required
                          min="1"
                          value={formData.duration}
                          onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                          placeholder="60"
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Image
                      </label>
                      
                      {/* Image Preview */}
                      {(imagePreview || formData.imageUrl) && (
                        <div className="mb-3">
                          <img
                            src={imagePreview || formData.imageUrl}
                            alt="Preview"
                            className="w-full h-48 object-cover rounded-lg border border-gray-300"
                            onError={(e) => {
                              e.currentTarget.style.display = 'none';
                            }}
                          />
                        </div>
                      )}

                      {/* File Upload */}
                      <div className="space-y-2">
                        <input
                          type="file"
                          accept="image/*"
                          onChange={handleFileChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 text-sm"
                        />
                        {selectedFile && (
                          <button
                            type="button"
                            onClick={handleUploadImage}
                            disabled={uploading}
                            className="w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                          >
                            {uploading ? 'Uploading...' : 'Upload Image to S3'}
                          </button>
                        )}
                        
                        {/* Manual URL Input (fallback) */}
                        <div className="mt-2">
                          <label className="block text-xs text-gray-500 mb-1">
                            Or enter image URL manually:
                          </label>
                          <input
                            type="url"
                            value={formData.imageUrl}
                            onChange={(e) => setFormData({ ...formData, imageUrl: e.target.value })}
                            placeholder="https://example.com/image.jpg"
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 text-sm"
                          />
                        </div>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Tags (comma-separated)
                      </label>
                      <input
                        type="text"
                        value={formData.tags}
                        onChange={(e) => setFormData({ ...formData, tags: e.target.value })}
                        placeholder="e.g., popular, featured, new"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                      />
                      <p className="text-xs text-gray-500 mt-1">
                        Separate multiple tags with commas
                      </p>
                    </div>

                    <div className="flex gap-4 pt-4">
                      <button
                        type="submit"
                        className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                      >
                        {editingService ? 'Update' : 'Create'} Service
                      </button>
                      <button
                        type="button"
                        onClick={handleCloseModal}
                        className="flex-1 px-6 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            )}

            {/* Add Category Modal */}
            {showCategoryModal && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
                  <h2 className="text-2xl font-bold mb-4">Add New Category</h2>
                  <form onSubmit={handleCategorySubmit} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Category Name *
                      </label>
                      <input
                        type="text"
                        required
                        value={categoryFormData.name}
                        onChange={(e) => setCategoryFormData({ ...categoryFormData, name: e.target.value })}
                        placeholder="e.g., Hair Services"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Description
                      </label>
                      <textarea
                        value={categoryFormData.description}
                        onChange={(e) => setCategoryFormData({ ...categoryFormData, description: e.target.value })}
                        rows={3}
                        placeholder="Category description..."
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Category Image
                      </label>
                      
                      {/* Image Preview */}
                      {(categoryImagePreview || categoryFormData.imageUrl) && (
                        <div className="mb-3">
                          <img
                            src={categoryImagePreview || categoryFormData.imageUrl}
                            alt="Preview"
                            className="w-full h-48 object-cover rounded-lg border border-gray-300"
                            onError={(e) => {
                              e.currentTarget.style.display = 'none';
                            }}
                          />
                        </div>
                      )}

                      {/* File Upload */}
                      <div className="space-y-2">
                        <input
                          type="file"
                          accept="image/*"
                          onChange={handleCategoryFileChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 text-sm"
                        />
                        {categorySelectedFile && (
                          <button
                            type="button"
                            onClick={handleCategoryUploadImage}
                            disabled={categoryUploading}
                            className="w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                          >
                            {categoryUploading ? 'Uploading...' : 'Upload Image to S3'}
                          </button>
                        )}
                        
                        {/* Manual URL Input (fallback) */}
                        <div className="mt-2">
                          <label className="block text-xs text-gray-500 mb-1">
                            Or enter image URL manually:
                          </label>
                          <input
                            type="url"
                            value={categoryFormData.imageUrl}
                            onChange={(e) => setCategoryFormData({ ...categoryFormData, imageUrl: e.target.value })}
                            placeholder="https://example.com/image.jpg"
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 text-sm"
                          />
                        </div>
                      </div>
                    </div>

                    <div className="flex gap-4 pt-4">
                      <button
                        type="submit"
                        className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                      >
                        Create Category
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setShowCategoryModal(false);
                          setCategoryFormData({
                            name: '',
                            description: '',
                            imageUrl: '',
                          });
                          setCategorySelectedFile(null);
                          setCategoryImagePreview(null);
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
