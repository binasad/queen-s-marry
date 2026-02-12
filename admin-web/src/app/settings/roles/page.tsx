'use client';

import { useState, useEffect } from 'react';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import PermissionGuard from '@/components/PermissionGuard';
import { rolesAPI, usersAPI } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import toast from 'react-hot-toast';
import CreateRoleModal from './create-role-modal';

interface Role {
  id: string;
  name: string;
  is_system_role?: boolean;
  permissions?: string[];
}

interface UserSummary {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role_name?: string;
  created_at?: string;
  last_login?: string;
}

export default function RolesPage() {
  const { user: currentUser } = useAuthStore();
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [usersByRole, setUsersByRole] = useState<Record<string, UserSummary[]>>({});
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [assignForm, setAssignForm] = useState({
    emails: '',
    roleId: '',
  });

  // Handle API errors gracefully - show roles even if API fails
  const handleApiError = (error: any, defaultMessage: string) => {
    console.error('API Error:', error);
    // For admin with hardcoded login, show a helpful message
    if (error.response?.status === 401 || error.response?.status === 403) {
      toast.error('Please ensure you are logged in as admin');
    } else {
      toast.error(error.response?.data?.message || defaultMessage);
    }
  };

  useEffect(() => {
    loadRoles();
  }, []);

  const loadRoles = async () => {
    try {
      setLoading(true);
      const [rolesRes, permsRes, usersRes] = await Promise.all([
        rolesAPI.getRoles(),
        rolesAPI.getPermissions(),
        usersAPI.getAll({ page: 1, limit: 500 }),
      ]);
      
      const allRoles = rolesRes.data.data || [];
      
      // Filter out Owner and User roles
      const filteredRoles = allRoles.filter(
        (role: Role) => role.name !== 'Owner' && role.name !== 'User'
      );
      
      setRoles(filteredRoles);
      setPermissions(permsRes.data.data || []);

      // Group users by role name for display
      const usersData = usersRes.data?.data?.users || [];
      const grouped: Record<string, UserSummary[]> = {};
      usersData.forEach((u: any) => {
        const roleName = u.role_name || 'Unassigned';
        if (!grouped[roleName]) grouped[roleName] = [];
        grouped[roleName].push({
          id: u.id,
          name: u.name,
          email: u.email,
          phone: u.phone,
          role_name: u.role_name,
          created_at: u.created_at,
          last_login: u.last_login,
        });
      });
      setUsersByRole(grouped);
    } catch (error: any) {
      handleApiError(error, 'Failed to load roles');
      // Set default roles if API fails (for demo/offline mode) - aligned with backend roles
      setRoles([
        { id: '1', name: 'Admin', is_system_role: true, permissions: [] },
        { id: '2', name: 'Expert', is_system_role: false, permissions: [] },
        { id: '3', name: 'Manager', is_system_role: false, permissions: [] },
        { id: '4', name: 'Sales', is_system_role: false, permissions: [] },
      ]);
      setPermissions([
        { id: '1', slug: 'users.view', description: 'View users' },
        { id: '2', slug: 'users.manage', description: 'Manage users' },
        { id: '3', slug: 'services.manage', description: 'Manage services' },
      ]);
      setUsersByRole({});
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteUser = async (userId: string, userName: string) => {
    if (!confirm(`Are you sure you want to delete "${userName}"? This cannot be undone.`)) return;
    try {
      await usersAPI.delete(userId);
      toast.success('User deleted successfully');
      loadRoles();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete user');
    }
  };

  const handleAssignRole = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const emails = assignForm.emails
        .split(',')
        .map((email) => email.trim())
        .filter((email) => email.length > 0);

      if (emails.length === 0) {
        toast.error('Please enter at least one email address');
        return;
      }

      if (emails.length === 1) {
        await usersAPI.assignRoleByEmail({
          email: emails[0],
          roleId: assignForm.roleId,
        });
        toast.success(`Role assigned to ${emails[0]}`);
      } else {
        const res = await usersAPI.assignRoleToMultiple({
          emails,
          roleId: assignForm.roleId,
        });
        toast.success(`Role assigned to ${res.data.data.assigned.length} user(s)`);
        if (res.data.data.failed.length > 0) {
          toast.error(`Failed for ${res.data.data.failed.length} user(s)`);
        }
      }

      setShowAssignModal(false);
      setAssignForm({ emails: '', roleId: '' });
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to assign role');
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
                <div>
                  <h1 className="text-2xl md:text-3xl font-bold text-gray-800">Role Assignment</h1>
                  <p className="text-gray-600 mt-2">Assign roles to users by their email address</p>
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowCreateModal(true)}
                    className="px-6 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition"
                  >
                    + Create Role
                  </button>
                  <button
                    onClick={() => setShowAssignModal(true)}
                    className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                  >
                    + Assign Role by Email
                  </button>
                </div>
              </div>

              <div className="bg-white rounded-lg shadow p-6 mb-6">
                <h2 className="text-xl font-semibold mb-4">How It Works</h2>
                <ul className="list-disc list-inside space-y-2 text-gray-700">
                  <li>Enter one or more email addresses (comma-separated)</li>
                  <li>Select a role to assign</li>
                  <li>Users will receive the permissions associated with that role</li>
                  <li>When users log in, they can only access features based on their assigned role permissions</li>
                  <li>All unauthorized actions will be automatically blocked</li>
                </ul>
              </div>

              {loading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <p className="text-gray-500">Loading roles...</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {roles.map((role) => {
                    const assignedUsers = usersByRole[role.name] || [];
                    return (
                      <div key={role.id} className="bg-white rounded-lg shadow p-6 flex flex-col gap-4">
                        <div className="flex items-center justify-between">
                          <div>
                            <h3 className="text-xl font-semibold text-gray-800">{role.name}</h3>
                            <p className="text-xs text-gray-500 mt-1">
                              {assignedUsers.length} user{assignedUsers.length === 1 ? '' : 's'} assigned
                            </p>
                          </div>
                          {role.is_system_role && role.name !== 'Admin' && (
                            <span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded">
                              System
                            </span>
                          )}
                        </div>
                        
                        <div>
                          <p className="text-sm font-medium text-gray-700 mb-2">Permissions:</p>
                          {role.permissions && role.permissions.length > 0 ? (
                            <div className="flex flex-wrap gap-2">
                              {role.permissions.map((perm) => (
                                <span
                                  key={perm}
                                  className="px-2 py-1 text-xs bg-green-100 text-green-800 rounded"
                                >
                                  {perm}
                                </span>
                              ))}
                            </div>
                          ) : (
                            <p className="text-sm text-gray-500">No permissions assigned</p>
                          )}
                        </div>

                        <div>
                          <p className="text-sm font-medium text-gray-700 mb-2">Assigned users:</p>
                          {assignedUsers.length === 0 ? (
                            <p className="text-sm text-gray-500">No users currently have this role.</p>
                          ) : (
                            <div className="max-h-40 overflow-y-auto border border-gray-100 rounded-md divide-y">
                              {assignedUsers.map((user) => (
                                <div
                                  key={user.id}
                                  className="px-2 py-2 text-xs flex items-center justify-between gap-2 group"
                                >
                                  <div className="flex flex-col gap-0.5 min-w-0">
                                    <span className="font-semibold text-gray-800">
                                      {user.name || 'Unnamed'} ({user.email})
                                    </span>
                                    <span className="text-gray-500">
                                      {user.phone ? `📞 ${user.phone}` : 'No phone'}
                                    </span>
                                  </div>
                                  {user.id !== currentUser?.id ? (
                                    <button
                                      type="button"
                                      onClick={() => handleDeleteUser(user.id, user.name || user.email)}
                                      className="shrink-0 px-2 py-1 text-red-600 hover:bg-red-50 rounded text-xs font-medium transition"
                                      title="Delete user"
                                    >
                                      Delete
                                    </button>
                                  ) : (
                                    <span className="shrink-0 text-xs text-gray-400">(You)</span>
                                  )}
                                </div>
                              ))}
                            </div>
                          )}
                        </div>

                        <button
                          onClick={() => {
                            setAssignForm({ ...assignForm, roleId: role.id });
                            setShowAssignModal(true);
                          }}
                          className="w-full px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition text-sm mt-1"
                        >
                          Assign This Role
                        </button>
                      </div>
                    );
                  })}
                </div>
              )}

              {/* Assign Role Modal */}
              {showAssignModal && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                  <div className="bg-white rounded-lg p-6 max-w-2xl w-full mx-4">
                    <h2 className="text-2xl font-bold mb-4">Assign Role by Email</h2>
                    <form onSubmit={handleAssignRole} className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Email Address(es) *
                        </label>
                        <textarea
                          required
                          value={assignForm.emails}
                          onChange={(e) => setAssignForm({ ...assignForm, emails: e.target.value })}
                          placeholder="Enter email addresses (one per line or comma-separated)&#10;Example:&#10;user1@example.com&#10;user2@example.com"
                          rows={6}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        />
                        <p className="text-xs text-gray-500 mt-1">
                          Enter one or more email addresses. Separate multiple emails with commas or new lines.
                        </p>
                      </div>
                      
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Select Role *
                        </label>
                        <select
                          required
                          value={assignForm.roleId}
                          onChange={(e) => setAssignForm({ ...assignForm, roleId: e.target.value })}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500"
                        >
                          <option value="">-- Select a role --</option>
                          {roles
                            .filter((role) => role.name !== 'Owner' && role.name !== 'User')
                            .map((role) => (
                              <option key={role.id} value={role.id}>
                                {role.name}
                              </option>
                            ))}
                        </select>
                      </div>

                      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                        <p className="text-sm text-yellow-800">
                          <strong>Important:</strong> Users will need to log out and log back in for the new role to take effect.
                        </p>
                      </div>

                      <div className="flex gap-4 pt-4">
                        <button
                          type="submit"
                          className="flex-1 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition"
                        >
                          Assign Role
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setShowAssignModal(false);
                            setAssignForm({ emails: '', roleId: '' });
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

              {/* Create Role Modal */}
              <CreateRoleModal
                isOpen={showCreateModal}
                onClose={() => setShowCreateModal(false)}
                onSuccess={loadRoles}
                availablePermissions={permissions}
              />
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
