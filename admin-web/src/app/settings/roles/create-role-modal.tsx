'use client';

import { useState } from 'react';
import { rolesAPI } from '@/lib/api';
import toast from 'react-hot-toast';

interface CreateRoleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  availablePermissions: Array<{ id: string; slug: string; description?: string }>;
}

export default function CreateRoleModal({
  isOpen,
  onClose,
  onSuccess,
  availablePermissions,
}: CreateRoleModalProps) {
  const [formData, setFormData] = useState({
    name: '',
    selectedPermissions: [] as string[],
  });
  const [isCreating, setIsCreating] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      toast.error('Role name is required');
      return;
    }

    setIsCreating(true);
    try {
      await rolesAPI.createRole({
        name: formData.name,
        permissions: formData.selectedPermissions,
      });
      toast.success('Role created successfully');
      setFormData({ name: '', selectedPermissions: [] });
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to create role');
    } finally {
      setIsCreating(false);
    }
  };

  const togglePermission = (permissionSlug: string) => {
    setFormData((prev) => ({
      ...prev,
      selectedPermissions: prev.selectedPermissions.includes(permissionSlug)
        ? prev.selectedPermissions.filter((p) => p !== permissionSlug)
        : [...prev.selectedPermissions, permissionSlug],
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4">Create New Role</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Role Name *
            </label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              placeholder="e.g., Manager, Sales"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Select Permissions
            </label>
            <div className="max-h-60 overflow-y-auto border border-gray-300 rounded-lg p-2">
              {availablePermissions.map((perm) => (
                <label
                  key={perm.id}
                  className="flex items-center gap-2 p-2 hover:bg-gray-50 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={formData.selectedPermissions.includes(perm.slug)}
                    onChange={() => togglePermission(perm.slug)}
                    className="w-4 h-4 text-primary-500 rounded focus:ring-primary-500"
                  />
                  <div className="flex-1">
                    <span className="text-sm font-medium">{perm.slug}</span>
                    {perm.description && (
                      <p className="text-xs text-gray-500">{perm.description}</p>
                    )}
                  </div>
                </label>
              ))}
            </div>
          </div>

          <div className="flex gap-4 pt-4">
            <button
              type="submit"
              disabled={isCreating}
              className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition disabled:opacity-50"
            >
              {isCreating ? 'Creating...' : 'Create Role'}
            </button>
            <button
              type="button"
              onClick={() => {
                setFormData({ name: '', selectedPermissions: [] });
                onClose();
              }}
              className="flex-1 px-6 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
