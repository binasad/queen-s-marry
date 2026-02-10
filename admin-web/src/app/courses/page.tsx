'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { coursesAPI } from '@/lib/api';
import { wsService } from '@/services/websocket';
import toast from 'react-hot-toast';

interface Course {
  id: string;
  title: string;
  description?: string;
  duration?: string;
  price?: number;
  image_url?: string;
  is_active?: boolean;
  created_at?: string;
}

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingCourse, setEditingCourse] = useState<Course | null>(null);
  const [search, setSearch] = useState('');
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    duration: '',
    price: '',
    imageUrl: '',
  });

  useEffect(() => {
    loadCourses();
    setupWebSocket();
  }, [search]);

  const setupWebSocket = () => {
    // Listen for real-time course updates
    wsService.onCourseCreated = (data) => {
      console.log('📚 New course created via WebSocket:', data);
      loadCourses(); // Refresh the list
      toast.success('New course created!');
    };

    wsService.onCourseUpdated = (data) => {
      console.log('📚 Course updated via WebSocket:', data);
      loadCourses(); // Refresh the list
      toast.success('Course updated!');
    };

    wsService.onCourseDeleted = (data) => {
      console.log('📚 Course deleted via WebSocket:', data);
      loadCourses(); // Refresh the list
      toast.success('Course deleted!');
    };

    // Connect WebSocket
    wsService.connect();
  };

  const loadCourses = async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (search) params.search = search;
      const res = await coursesAPI.getAll(params);
      setCourses(res.data.data.courses || []);
    } catch (error: any) {
      console.error('Failed to load courses:', error);
      toast.error(error.response?.data?.message || 'Failed to load courses');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const data = {
        title: formData.title,
        description: formData.description || null,
        duration: formData.duration || null,
        price: formData.price ? parseFloat(formData.price) : null,
        imageUrl: formData.imageUrl || null,
      };

      if (editingCourse) {
        await coursesAPI.update(editingCourse.id, data);
        toast.success('Course updated successfully');
      } else {
        await coursesAPI.create(data);
        toast.success('Course created successfully');
      }

      setShowModal(false);
      setFormData({ title: '', description: '', duration: '', price: '', imageUrl: '' });
      setEditingCourse(null);
      loadCourses();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to save course');
    }
  };

  const handleEdit = (course: Course) => {
    setEditingCourse(course);
    setFormData({
      title: course.title,
      description: course.description || '',
      duration: course.duration || '',
      price: course.price?.toString() || '',
      imageUrl: course.image_url || '',
    });
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this course?')) return;
    try {
      await coursesAPI.delete(id);
      toast.success('Course deleted successfully');
      loadCourses();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete course');
    }
  };

  const handleToggleActive = async (course: Course) => {
    try {
      await coursesAPI.update(course.id, { isActive: !course.is_active });
      toast.success(`Course ${course.is_active ? 'deactivated' : 'activated'} successfully`);
      loadCourses();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update course');
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
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Courses</h1>
                <div className="flex gap-4">
                  <input
                    type="text"
                    placeholder="Search courses..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                  />
                  <button
                    onClick={() => {
                      setEditingCourse(null);
                      setFormData({ title: '', description: '', duration: '', price: '', imageUrl: '' });
                      setShowModal(true);
                    }}
                    className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                  >
                    + Add Course
                  </button>
                </div>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <p className="text-gray-500">Loading courses...</p>
                </div>
              ) : courses.length === 0 ? (
                <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
                  No courses found
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {courses.map((course) => (
                    <div key={course.id} className="bg-white rounded-lg shadow overflow-hidden">
                      {course.image_url && (
                        <img
                          src={course.image_url}
                          alt={course.title}
                          className="w-full h-48 object-cover"
                        />
                      )}
                      <div className="p-6">
                        <div className="flex items-start justify-between mb-2">
                          <h3 className="text-xl font-semibold text-gray-800">{course.title}</h3>
                          {course.is_active === false && (
                            <span className="px-2 py-1 text-xs bg-red-100 text-red-800 rounded">
                              Inactive
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                          {course.description || 'No description'}
                        </p>
                        <div className="flex justify-between items-center mb-4">
                          {course.price && (
                            <span className="text-2xl font-bold text-primary-500">
                              Rs. {course.price.toLocaleString()}
                            </span>
                          )}
                          {course.duration && (
                            <span className="text-sm text-gray-500">{course.duration}</span>
                          )}
                        </div>
                        <div className="flex space-x-2">
                          <button
                            onClick={() => handleEdit(course)}
                            className="flex-1 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition text-sm"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleToggleActive(course)}
                            className={`flex-1 px-4 py-2 rounded transition text-sm ${
                              course.is_active
                                ? 'bg-yellow-500 text-white hover:bg-yellow-600'
                                : 'bg-green-500 text-white hover:bg-green-600'
                            }`}
                          >
                            {course.is_active ? 'Deactivate' : 'Activate'}
                          </button>
                          <button
                            onClick={() => handleDelete(course.id)}
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
                      {editingCourse ? 'Edit Course' : 'Add New Course'}
                    </h2>
                    <form onSubmit={handleSubmit} className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Title *
                        </label>
                        <input
                          type="text"
                          required
                          value={formData.title}
                          onChange={(e) => setFormData({ ...formData, title: e.target.value })}
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
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Duration
                          </label>
                          <input
                            type="text"
                            placeholder="e.g., 3 months"
                            value={formData.duration}
                            onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                          />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Price
                          </label>
                          <input
                            type="number"
                            step="0.01"
                            placeholder="0.00"
                            value={formData.price}
                            onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                          />
                        </div>
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
                      <div className="flex gap-4 pt-4">
                        <button
                          type="submit"
                          className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                        >
                          {editingCourse ? 'Update' : 'Create'} Course
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setShowModal(false);
                            setEditingCourse(null);
                            setFormData({ title: '', description: '', duration: '', price: '', imageUrl: '' });
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
