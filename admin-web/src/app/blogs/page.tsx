'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { blogsAPI, servicesAPI } from '@/lib/api';
import toast from 'react-hot-toast';

interface Blog {
  id: string;
  title: string;
  content: string;
  image_url?: string;
  is_active?: boolean;
  display_order?: number;
  created_at?: string;
  updated_at?: string;
}

export default function BlogsPage() {
  const [blogs, setBlogs] = useState<Blog[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingBlog, setEditingBlog] = useState<Blog | null>(null);
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    imageUrl: '',
    isActive: true,
    displayOrder: 0,
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  const loadBlogs = async () => {
    try {
      setLoading(true);
      const res = await blogsAPI.getAllAdmin({});
      setBlogs(res.data?.data?.blogs || []);
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to load blogs');
      setBlogs([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBlogs();
  }, []);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => setImagePreview(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const uploadImage = async (): Promise<string | null> => {
    if (!selectedFile) return formData.imageUrl || null;
    try {
      setUploading(true);
      const res = await servicesAPI.uploadImage(selectedFile, 'blogs');
      const url = res.data?.data?.imageUrl || res.data?.imageUrl || res.data?.data?.url || res.data?.url || null;
      if (!url) toast.error('Image uploaded but URL not received');
      return url;
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to upload image');
      return null;
    } finally {
      setUploading(false);
    }
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingBlog(null);
    setFormData({ title: '', content: '', imageUrl: '', isActive: true, displayOrder: 0 });
    setSelectedFile(null);
    setImagePreview(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.title.trim()) {
      toast.error('Title is required');
      return;
    }
    if (!formData.content.trim()) {
      toast.error('Content is required');
      return;
    }

    try {
      setSaving(true);
      let imageUrl = formData.imageUrl;
      if (selectedFile) {
        const uploadedUrl = await uploadImage();
        if (uploadedUrl) imageUrl = uploadedUrl;
      }

      const data = {
        title: formData.title.trim(),
        content: formData.content.trim(),
        imageUrl: imageUrl || undefined,
        isActive: formData.isActive,
        displayOrder: formData.displayOrder,
      };

      if (editingBlog) {
        await blogsAPI.update(editingBlog.id, data);
        toast.success('Blog updated successfully');
      } else {
        await blogsAPI.create(data);
        toast.success('Blog created successfully');
      }
      closeModal();
      loadBlogs();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to save blog');
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (blog: Blog) => {
    setEditingBlog(blog);
    setFormData({
      title: blog.title,
      content: blog.content,
      imageUrl: blog.image_url || '',
      isActive: blog.is_active !== false,
      displayOrder: blog.display_order || 0,
    });
    setImagePreview(blog.image_url || null);
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this blog?')) return;
    try {
      await blogsAPI.delete(id);
      toast.success('Blog deleted successfully');
      loadBlogs();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete blog');
    }
  };

  const handleToggleActive = async (blog: Blog) => {
    try {
      await blogsAPI.update(blog.id, { isActive: !blog.is_active });
      toast.success(`Blog ${blog.is_active ? 'hidden' : 'published'} successfully`);
      loadBlogs();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update blog');
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
                <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Blogs</h1>
                <button
                  onClick={() => { setEditingBlog(null); setFormData({ title: '', content: '', imageUrl: '', isActive: true, displayOrder: 0 }); setImagePreview(null); setShowModal(true); }}
                  className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition font-medium"
                >
                  Add Blog
                </button>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-12 text-center">
                  <p className="text-gray-500">Loading blogs...</p>
                </div>
              ) : blogs.length === 0 ? (
                <div className="bg-white rounded-lg shadow p-12 text-center text-gray-500">
                  No blogs yet. Click &quot;Add Blog&quot; to create one.
                </div>
              ) : (
                <div className="grid gap-4">
                  {blogs.map((blog) => (
                    <div
                      key={blog.id}
                      className="bg-white rounded-lg shadow p-6 flex flex-col md:flex-row gap-4"
                    >
                      {blog.image_url && (
                        <img
                          src={blog.image_url}
                          alt={blog.title}
                          className="w-full md:w-48 h-32 object-cover rounded-lg"
                        />
                      )}
                      <div className="flex-1">
                        <h3 className="font-bold text-lg text-gray-800">{blog.title}</h3>
                        <p className="text-gray-600 text-sm mt-1 line-clamp-2">{blog.content}</p>
                        <p className="text-xs text-gray-400 mt-2">
                          {blog.created_at ? new Date(blog.created_at).toLocaleDateString() : ''}
                          {blog.is_active === false && (
                            <span className="ml-2 px-2 py-0.5 bg-red-100 text-red-700 rounded">Hidden</span>
                          )}
                        </p>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleToggleActive(blog)}
                          className={`px-4 py-2 rounded-lg text-sm font-medium ${blog.is_active === false ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}
                        >
                          {blog.is_active === false ? 'Publish' : 'Hide'}
                        </button>
                        <button onClick={() => handleEdit(blog)} className="px-4 py-2 bg-blue-100 text-blue-700 rounded-lg text-sm font-medium hover:bg-blue-200">
                          Edit
                        </button>
                        <button onClick={() => handleDelete(blog.id)} className="px-4 py-2 bg-red-100 text-red-700 rounded-lg text-sm font-medium hover:bg-red-200">
                          Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </main>
        </div>
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold p-6 border-b">{editingBlog ? 'Edit Blog' : 'Add Blog'}</h2>
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Title *</label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Content *</label>
                <textarea
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  rows={6}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Image (optional)</label>
                <input type="file" accept="image/*" onChange={handleFileChange} className="w-full text-sm" />
                {imagePreview && (
                  <img src={imagePreview} alt="Preview" className="mt-2 h-32 object-cover rounded-lg" />
                )}
              </div>
              <div className="flex items-center gap-4">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={formData.isActive}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  />
                  <span className="text-sm">Published (visible on app)</span>
                </label>
              </div>
              <div className="flex gap-4 pt-4">
                <button
                  type="submit"
                  disabled={saving || uploading}
                  className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 disabled:opacity-50"
                >
                  {saving || uploading ? 'Saving...' : (editingBlog ? 'Update' : 'Create')}
                </button>
                <button type="button" onClick={closeModal} className="flex-1 px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300">
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AuthGuard>
  );
}
