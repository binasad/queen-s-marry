'use client';

import React, { useState, useEffect, useMemo } from 'react';
import {
  DndContext,
  DragEndEvent,
  DragOverlay,
  DragStartEvent,
  PointerSensor,
  useSensor,
  useSensors,
  useDraggable,
  useDroppable,
  closestCenter,
} from '@dnd-kit/core';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import { rolesAPI } from '@/lib/api';
import toast from 'react-hot-toast';

interface Role {
  id: string;
  name: string;
  is_system_role?: boolean;
  permissions?: string[];
}

interface Permission {
  id: string;
  slug: string;
  description?: string;
}

interface DraggedPermission {
  permissionSlug: string;
  roleId: string;
}

// Permission group icons mapping
const getGroupIcon = (groupName: string) => {
  const icons: Record<string, string> = {
    users: '👥',
    roles: '🔐',
    services: '✂️',
    appointments: '📅',
    offers: '🎁',
    courses: '📚',
    experts: '⭐',
    gallery: '🖼️',
    support: '💬',
    dashboard: '📊',
    reports: '📈',
    auth: '🔑',
    categories: '📁',
    notifications: '🔔',
  };
  return icons[groupName.toLowerCase()] || '📋';
};

// Role color mapping
const getRoleColor = (roleName: string) => {
  const colors: Record<string, { bg: string; border: string; text: string; badge: string }> = {
    Admin: { bg: 'bg-purple-50', border: 'border-purple-300', text: 'text-purple-700', badge: 'bg-purple-100 text-purple-800' },
    Expert: { bg: 'bg-blue-50', border: 'border-blue-300', text: 'text-blue-700', badge: 'bg-blue-100 text-blue-800' },
    Manager: { bg: 'bg-green-50', border: 'border-green-300', text: 'text-green-700', badge: 'bg-green-100 text-green-800' },
    Sales: { bg: 'bg-orange-50', border: 'border-orange-300', text: 'text-orange-700', badge: 'bg-orange-100 text-orange-800' },
  };
  return colors[roleName] || { bg: 'bg-gray-50', border: 'border-gray-300', text: 'text-gray-700', badge: 'bg-gray-100 text-gray-800' };
};

// Draggable Permission Name Component
function DraggablePermissionName({
  permission,
  searchQuery,
}: {
  permission: Permission;
  searchQuery?: string;
}) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `permission-${permission.slug}`,
    data: {
      permissionSlug: permission.slug,
      permissionId: permission.id,
    },
  });

  const style = transform
    ? {
        transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
      }
    : undefined;

  // Highlight search matches
  const highlightText = (text: string, query: string) => {
    if (!query) return text;
    const parts = text.split(new RegExp(`(${query})`, 'gi'));
    return parts.map((part, i) =>
      part.toLowerCase() === query.toLowerCase() ? (
        <mark key={i} className="bg-yellow-200 px-1 rounded">
          {part}
        </mark>
      ) : (
        part
      )
    );
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all cursor-grab active:cursor-grabbing shadow-sm ${
        isDragging
          ? 'opacity-50 scale-95 bg-blue-100 border-2 border-blue-400 shadow-lg'
          : 'bg-gradient-to-r from-blue-50 to-indigo-50 border-2 border-blue-200 hover:from-blue-100 hover:to-indigo-100 hover:border-blue-300 hover:shadow-md'
      }`}
      title={`Drag "${permission.slug}" to a role column to add, or to trash to remove from all roles`}
    >
      <div className="flex-shrink-0 w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center">
        <svg
          className="w-5 h-5 text-blue-600"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M4 8h16M4 16h16"
          />
        </svg>
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-semibold text-gray-900 text-sm">
          {searchQuery ? highlightText(permission.slug, searchQuery) : permission.slug}
        </div>
        {permission.description && (
          <div className="text-xs text-gray-500 mt-1 line-clamp-1">{permission.description}</div>
        )}
      </div>
    </div>
  );
}

// Draggable Permission Cell Component
function DraggablePermissionCell({
  roleId,
  permissionSlug,
  hasPermission,
  onToggle,
  roleName,
}: {
  roleId: string;
  permissionSlug: string;
  hasPermission: boolean;
  onToggle: () => void;
  roleName: string;
}) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `role:${roleId}:${permissionSlug}`,
    disabled: !hasPermission,
    data: {
      roleId,
      permissionSlug,
      source: 'role',
    },
  });

  const style = transform
    ? {
        transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
      }
    : undefined;

  const roleColor = getRoleColor(roleName);

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`flex items-center justify-center min-h-[60px] transition-all ${
        isDragging ? 'opacity-50 scale-95' : ''
      }`}
    >
      {hasPermission ? (
        <div
          {...listeners}
          {...attributes}
          className={`flex items-center gap-2 px-3 py-2 rounded-lg ${roleColor.bg} border-2 ${roleColor.border} hover:shadow-md cursor-grab active:cursor-grabbing transition-all`}
          title={`Drag to trash to remove "${permissionSlug}" from ${roleName}`}
        >
          <input
            type="checkbox"
            checked={hasPermission}
            onChange={onToggle}
            className={`w-5 h-5 ${roleColor.text} rounded focus:ring-2 focus:ring-offset-1 cursor-pointer flex-shrink-0`}
            onClick={(e) => e.stopPropagation()}
          />
          <svg
            className={`w-4 h-4 ${roleColor.text} flex-shrink-0`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 8h16M4 16h16"
            />
          </svg>
        </div>
      ) : (
        <label className="cursor-pointer">
          <input
            type="checkbox"
            checked={hasPermission}
            onChange={onToggle}
            className="w-5 h-5 text-gray-400 rounded focus:ring-2 focus:ring-primary-500 cursor-pointer transition-all hover:scale-110"
          />
        </label>
      )}
    </div>
  );
}

// Droppable Role Column Component
function DroppableRoleColumn({
  roleId,
  roleName,
  isSystemRole,
  permissionCount,
  totalPermissions,
  onSelectAll,
  onDeselectAll,
}: {
  roleId: string;
  roleName: string;
  isSystemRole?: boolean;
  permissionCount: number;
  totalPermissions: number;
  onSelectAll: () => void;
  onDeselectAll: () => void;
}) {
  const { isOver, setNodeRef } = useDroppable({
    id: `role-${roleId}`,
  });

  const roleColor = getRoleColor(roleName);
  const percentage = totalPermissions > 0 ? Math.round((permissionCount / totalPermissions) * 100) : 0;

  return (
    <th
      ref={setNodeRef}
      className={`border-2 px-4 py-4 text-center font-semibold min-w-[200px] transition-all duration-200 ${
        isOver
          ? `${roleColor.bg} ${roleColor.border} ring-4 ring-opacity-50 shadow-xl scale-105`
          : `${roleColor.bg} ${roleColor.border} hover:shadow-lg`
      }`}
    >
      <div className="relative">
        <div className={`font-bold text-lg ${roleColor.text} mb-2`}>{roleName}</div>
        {isSystemRole && (
          <div className="text-xs text-blue-600 font-normal mb-2 px-2 py-1 bg-blue-100 rounded-full inline-block">
            System Role
          </div>
        )}
        <div className={`text-xs ${roleColor.badge} px-2 py-1 rounded-full inline-block mb-2`}>
          {permissionCount} / {totalPermissions} ({percentage}%)
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2 mb-2">
          <div
            className={`h-2 rounded-full transition-all ${roleColor.bg.replace('50', '400')}`}
            style={{ width: `${percentage}%` }}
          />
        </div>
        <div className="flex gap-1 justify-center mt-2">
          <button
            onClick={onSelectAll}
            className="text-xs px-2 py-1 bg-white border border-gray-300 rounded hover:bg-gray-50 transition"
            title="Select all permissions"
          >
            All
          </button>
          <button
            onClick={onDeselectAll}
            className="text-xs px-2 py-1 bg-white border border-gray-300 rounded hover:bg-gray-50 transition"
            title="Deselect all permissions"
          >
            None
          </button>
        </div>
        {isOver && (
          <div className={`absolute inset-0 flex items-center justify-center ${roleColor.bg} bg-opacity-95 rounded-lg z-20`}>
            <div className="text-center">
              <svg
                className="w-10 h-10 mx-auto mb-2 text-green-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M5 13l4 4L19 7"
                />
              </svg>
              <div className="text-sm font-bold text-green-800">Drop to Add</div>
            </div>
          </div>
        )}
      </div>
    </th>
  );
}

// Droppable Trash Column Component
function DroppableTrashColumn() {
  const { isOver, setNodeRef } = useDroppable({
    id: 'trash',
  });

  return (
    <th
      ref={setNodeRef}
      className={`border-2 px-4 py-4 text-center font-semibold text-gray-700 min-w-[150px] transition-all duration-200 ${
        isOver
          ? 'bg-red-200 border-red-500 ring-4 ring-red-300 shadow-xl scale-105'
          : 'bg-gray-50 hover:bg-gray-100 border-gray-300'
      }`}
    >
      <div className="relative">
        <div className="font-bold text-lg text-red-600 mb-2">🗑️ Trash</div>
        <div className="text-xs text-gray-500">Remove from all</div>
        {isOver && (
          <div className="absolute inset-0 flex items-center justify-center bg-red-300 bg-opacity-90 rounded-lg z-20">
            <div className="text-center">
              <svg
                className="w-10 h-10 mx-auto mb-2 text-red-700"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
              <div className="text-sm font-bold text-red-800">Drop to Remove</div>
            </div>
          </div>
        )}
      </div>
    </th>
  );
}

// Droppable Trash Cell Component
function DroppableTrashCell() {
  const { isOver, setNodeRef } = useDroppable({
    id: 'trash',
  });

  return (
    <td
      ref={setNodeRef}
      className={`border-2 border-gray-200 px-2 py-3 text-center align-middle transition-all duration-200 ${
        isOver
          ? 'bg-red-100 border-red-400 ring-2 ring-red-300'
          : 'bg-gray-50'
      }`}
    >
      <div className="flex items-center justify-center min-h-[60px]">
        {isOver ? (
          <div className="text-red-600 font-semibold text-sm">Drop to Remove</div>
        ) : (
          <span className="text-lg text-gray-400">🗑️</span>
        )}
      </div>
    </td>
  );
}

export default function PermissionsPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [matrix, setMatrix] = useState<Record<string, string[]>>({});
  const [draggedPermission, setDraggedPermission] = useState<DraggedPermission | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  useEffect(() => {
    loadData();
  }, []);

  // Update matrix when roles are loaded
  useEffect(() => {
    if (roles.length > 0 && Object.keys(matrix).length === 0) {
      const initialMatrix: Record<string, string[]> = {};
      roles
        .filter((role: Role) => ['Admin', 'Expert', 'Manager', 'Sales'].includes(role.name))
        .forEach((role: Role) => {
          initialMatrix[role.id] = Array.isArray(role.permissions) ? role.permissions : [];
        });
      setMatrix(initialMatrix);
      // Expand all groups by default
      const allGroups = new Set(
        permissions.map((p) => p.slug.split('.')[0] || 'other')
      );
      setExpandedGroups(allGroups);
    }
  }, [roles, permissions]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [rolesRes, permsRes] = await Promise.all([
        rolesAPI.getRoles(),
        rolesAPI.getPermissions(),
      ]);
      
      const loadedRoles = rolesRes.data.data || [];
      const loadedPermissions = permsRes.data.data || [];
      
      const allowedRoleNames = ['Admin', 'Expert', 'Manager', 'Sales'];
      const filteredRoles = loadedRoles.filter(
        (role: Role) => allowedRoleNames.includes(role.name)
      );
      
      setRoles(filteredRoles);
      setPermissions(loadedPermissions);
      
      const initialMatrix: Record<string, string[]> = {};
      filteredRoles.forEach((role: Role) => {
        if (Array.isArray(role.permissions)) {
          initialMatrix[role.id] = role.permissions;
        } else {
          initialMatrix[role.id] = [];
        }
      });
      setMatrix(initialMatrix);
      
      // Expand all groups by default
      const allGroups = new Set<string>(
        loadedPermissions.map((p: Permission) => String(p.slug.split('.')[0] || 'other'))
      );
      setExpandedGroups(allGroups);
    } catch (error: any) {
      console.error('Failed to load data:', error);
      const errorMessage = error.response?.data?.message || 'Failed to load roles and permissions';
      toast.error(errorMessage);
      
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
        { id: '4', slug: 'roles.view', description: 'View roles' },
        { id: '5', slug: 'roles.manage', description: 'Manage roles' },
      ]);
      setMatrix({
        '1': ['users.view', 'users.manage', 'services.manage', 'roles.view', 'roles.manage'],
        '2': ['users.view', 'services.manage'],
        '3': ['users.view', 'services.manage'],
        '4': ['users.view'],
      });
    } finally {
      setLoading(false);
    }
  };

  const togglePermission = (roleId: string, permissionSlug: string) => {
    setMatrix((prev) => {
      const rolePermissions = prev[roleId] || [];
      const hasPermission = rolePermissions.includes(permissionSlug);

      return {
        ...prev,
        [roleId]: hasPermission
          ? rolePermissions.filter((p) => p !== permissionSlug)
          : [...rolePermissions, permissionSlug],
      };
    });
  };

  const handleSelectAllForRole = (roleId: string) => {
    setMatrix((prev) => ({
      ...prev,
      [roleId]: permissions.map((p) => p.slug),
    }));
    toast.success('All permissions selected');
  };

  const handleDeselectAllForRole = (roleId: string) => {
    setMatrix((prev) => ({
      ...prev,
      [roleId]: [],
    }));
    toast.success('All permissions deselected');
  };

  const toggleGroup = (groupName: string) => {
    setExpandedGroups((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(groupName)) {
        newSet.delete(groupName);
      } else {
        newSet.add(groupName);
      }
      return newSet;
    });
  };

  const handleDragStart = (event: DragStartEvent) => {
    const activeId = event.active.id.toString();
    const data = event.active.data.current;
    
    if (activeId.startsWith('permission-')) {
      const permissionSlug = data?.permissionSlug || activeId.replace('permission-', '');
      setDraggedPermission({ 
        permissionSlug,
        roleId: '',
      });
    } else if (activeId.startsWith('role:')) {
      const parts = activeId.split(':');
      const roleId = parts[1];
      const permissionSlug = parts[2] || data?.permissionSlug;
      setDraggedPermission({
        permissionSlug,
        roleId,
      });
    }
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (!over) {
      setDraggedPermission(null);
      return;
    }

    const activeId = active.id.toString();
    const overId = over.id.toString();
    const activeData = active.data.current;
    
    const isFromPermissionList = activeId.startsWith('permission-');
    const isFromRoleCell = activeId.startsWith('role:');
    
    let permissionSlug: string;
    let sourceRoleId: string | null = null;
    
    if (isFromPermissionList) {
      permissionSlug = activeData?.permissionSlug || activeId.replace('permission-', '');
    } else if (isFromRoleCell) {
      const parts = activeId.split(':');
      sourceRoleId = parts[1];
      permissionSlug = parts[2] || activeData?.permissionSlug || '';
    } else {
      setDraggedPermission(null);
      return;
    }

    if (overId === 'trash') {
      if (isFromRoleCell && sourceRoleId) {
        setMatrix((prev) => {
          const rolePermissions = prev[sourceRoleId!] || [];
          if (rolePermissions.includes(permissionSlug)) {
            const roleName = roles.find(r => r.id === sourceRoleId)?.name;
            toast.success(`Permission "${permissionSlug}" removed from ${roleName}`);
            return {
              ...prev,
              [sourceRoleId!]: rolePermissions.filter((p) => p !== permissionSlug),
            };
          }
          return prev;
        });
      } else {
        setMatrix((prev) => {
          const newMatrix = { ...prev };
          let removedCount = 0;
          
          Object.keys(newMatrix).forEach((roleId) => {
            if (newMatrix[roleId].includes(permissionSlug)) {
              newMatrix[roleId] = newMatrix[roleId].filter((p) => p !== permissionSlug);
              removedCount++;
            }
          });

          if (removedCount > 0) {
            toast.success(`Permission "${permissionSlug}" removed from ${removedCount} role(s)`);
          } else {
            toast(`Permission "${permissionSlug}" was not assigned to any role`, {
              icon: 'ℹ️',
            });
          }
          
          return newMatrix;
        });
      }
    } else if (overId.startsWith('role-') && isFromPermissionList) {
      const targetRoleId = overId.replace('role-', '');
      
      setMatrix((prev) => {
        const targetPermissions = prev[targetRoleId] || [];
        const hasPermission = targetPermissions.includes(permissionSlug);

        if (!hasPermission) {
          const roleName = roles.find(r => r.id === targetRoleId)?.name;
          toast.success(`Permission "${permissionSlug}" added to ${roleName}`);
          return {
            ...prev,
            [targetRoleId]: [...targetPermissions, permissionSlug],
          };
        } else {
          const roleName = roles.find(r => r.id === targetRoleId)?.name;
          toast(`Permission "${permissionSlug}" already exists in ${roleName}`, {
            icon: 'ℹ️',
          });
        }
        return prev;
      });
    }

    setDraggedPermission(null);
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const updatePromises = Object.entries(matrix).map(async ([roleId, permissionSlugs]) => {
        try {
          await rolesAPI.updateRolePermissions(roleId, permissionSlugs);
          return { roleId, success: true };
        } catch (error: any) {
          console.error(`Failed to update role ${roleId}:`, error);
          return { roleId, success: false, error: error.response?.data?.message || 'Update failed' };
        }
      });
      
      const results = await Promise.all(updatePromises);
      const failed = results.filter(r => !r.success);
      
      if (failed.length > 0) {
        toast.error(`Failed to update ${failed.length} role(s). Check console for details.`);
        console.error('Failed updates:', failed);
      } else {
        toast.success('Permissions updated successfully! Users will see changes on next login.');
      }
      
      await loadData();
    } catch (error: any) {
      console.error('Failed to save permissions:', error);
      toast.error(error.response?.data?.message || 'Failed to save permissions. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  // Group permissions by prefix and filter by search
  const groupedPermissions = useMemo(() => {
    const filtered = permissions.filter((perm) =>
      perm.slug.toLowerCase().includes(searchQuery.toLowerCase()) ||
      perm.description?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const grouped = filtered.reduce((acc, perm) => {
      const group = perm.slug.split('.')[0] || 'other';
      if (!acc[group]) {
        acc[group] = [];
      }
      acc[group].push(perm);
      return acc;
    }, {} as Record<string, Permission[]>);

    return grouped;
  }, [permissions, searchQuery]);

  // Calculate permission counts for each role
  const rolePermissionCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    roles.forEach((role) => {
      counts[role.id] = matrix[role.id]?.length || 0;
    });
    return counts;
  }, [roles, matrix]);

  const filteredRoles = roles.filter((role) => ['Admin', 'Expert', 'Manager', 'Sales'].includes(role.name))
    .sort((a, b) => {
      const order = ['Admin', 'Expert', 'Manager', 'Sales'];
      return order.indexOf(a.name) - order.indexOf(b.name);
    });

  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-[95vw] mx-auto">
              {/* Header Section */}
              <div className="mb-6">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-4">
                  <div>
                    <h1 className="text-3xl md:text-4xl font-bold text-gray-800 mb-2">
                      Permission Matrix
                    </h1>
                    <p className="text-gray-600">
                      Configure what each role can and cannot do. Drag permissions or use checkboxes.
                    </p>
                  </div>
                  <button
                    onClick={handleSave}
                    disabled={isSaving}
                    className="px-6 py-3 bg-gradient-to-r from-primary-500 to-primary-600 text-white rounded-xl hover:from-primary-600 hover:to-primary-700 transition-all shadow-lg hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed font-semibold"
                  >
                    {isSaving ? (
                      <span className="flex items-center gap-2">
                        <svg className="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                        </svg>
                        Saving...
                      </span>
                    ) : (
                      '💾 Save Permissions'
                    )}
                  </button>
                </div>

                {/* Search Bar */}
                <div className="relative">
                  <input
                    type="text"
                    placeholder="🔍 Search permissions by name or description..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full px-4 py-3 pl-12 border-2 border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all"
                  />
                  <svg
                    className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  {searchQuery && (
                    <button
                      onClick={() => setSearchQuery('')}
                      className="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    >
                      ✕
                    </button>
                  )}
                </div>
              </div>

              {loading ? (
                <div className="bg-white rounded-xl shadow-lg p-12 text-center">
                  <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500 mb-4"></div>
                  <p className="text-gray-500 text-lg">Loading permissions...</p>
                </div>
              ) : roles.length === 0 || permissions.length === 0 ? (
                <div className="bg-white rounded-xl shadow-lg p-12 text-center">
                  <p className="text-gray-500 mb-4 text-lg">
                    {roles.length === 0 ? 'No roles found.' : 'No permissions found.'}
                  </p>
                  <p className="text-sm text-gray-400">
                    Please ensure the backend API is running and you have the necessary permissions.
                  </p>
                </div>
              ) : (
                <DndContext
                  sensors={sensors}
                  collisionDetection={closestCenter}
                  onDragStart={handleDragStart}
                  onDragEnd={handleDragEnd}
                >
                  <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                    <div className="overflow-x-auto">
                      <table className="min-w-full border-collapse">
                        <thead>
                          <tr className="bg-gradient-to-r from-gray-50 to-gray-100">
                            <th className="border-2 px-4 py-4 text-left font-bold text-gray-700 sticky left-0 bg-gradient-to-r from-gray-50 to-gray-100 z-20 min-w-[320px] shadow-lg">
                              <div className="flex items-center gap-2">
                                <span>Permission</span>
                                <span className="text-xs font-normal text-gray-500">
                                  ({Object.values(groupedPermissions).flat().length} total)
                                </span>
                              </div>
                            </th>
                            {filteredRoles.map((role) => (
                              <DroppableRoleColumn
                                key={role.id}
                                roleId={role.id}
                                roleName={role.name}
                                isSystemRole={role.is_system_role}
                                permissionCount={rolePermissionCounts[role.id] || 0}
                                totalPermissions={permissions.length}
                                onSelectAll={() => handleSelectAllForRole(role.id)}
                                onDeselectAll={() => handleDeselectAllForRole(role.id)}
                              />
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {Object.entries(groupedPermissions).length === 0 ? (
                            <tr>
                              <td
                                colSpan={filteredRoles.length + 1}
                                className="border px-4 py-12 text-center text-gray-500"
                              >
                                <div className="text-lg">🔍</div>
                                <div className="mt-2">No permissions found matching "{searchQuery}"</div>
                              </td>
                            </tr>
                          ) : (
                            Object.entries(groupedPermissions)
                              .sort(([a], [b]) => a.localeCompare(b))
                              .map(([groupName, groupPerms]) => {
                                const isExpanded = expandedGroups.has(groupName);
                                const icon = getGroupIcon(groupName);
                                
                                return (
                                  <React.Fragment key={groupName}>
                                    <tr className="bg-gray-100 hover:bg-gray-200 transition-colors cursor-pointer">
                                      <td
                                        colSpan={filteredRoles.length + 1}
                                        className="border-2 px-4 py-3 font-bold text-gray-800 sticky left-0 bg-gray-100 z-10"
                                        onClick={() => toggleGroup(groupName)}
                                      >
                                        <div className="flex items-center justify-between">
                                          <div className="flex items-center gap-3">
                                            <span className="text-xl">{icon}</span>
                                            <span className="text-lg">
                                              {groupName.charAt(0).toUpperCase() + groupName.slice(1)} Permissions
                                            </span>
                                            <span className="text-sm font-normal text-gray-600">
                                              ({groupPerms.length})
                                            </span>
                                          </div>
                                          <svg
                                            className={`w-5 h-5 text-gray-600 transition-transform ${
                                              isExpanded ? 'rotate-180' : ''
                                            }`}
                                            fill="none"
                                            stroke="currentColor"
                                            viewBox="0 0 24 24"
                                          >
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                                          </svg>
                                        </div>
                                      </td>
                                    </tr>
                                    {isExpanded &&
                                      groupPerms.map((permission) => (
                                        <tr key={permission.id} className="hover:bg-gray-50 transition-colors">
                                          <td className="border-2 px-4 py-3 text-sm text-gray-700 sticky left-0 bg-white z-10">
                                            <DraggablePermissionName permission={permission} searchQuery={searchQuery} />
                                          </td>
                                          {filteredRoles.map((role) => {
                                            const hasPermission = matrix[role.id]?.includes(permission.slug) || false;
                                            return (
                                              <td
                                                key={role.id}
                                                className="border-2 border-gray-200 px-2 py-3 text-center align-middle"
                                              >
                                                <DraggablePermissionCell
                                                  roleId={role.id}
                                                  permissionSlug={permission.slug}
                                                  hasPermission={hasPermission}
                                                  onToggle={() => togglePermission(role.id, permission.slug)}
                                                  roleName={role.name}
                                                />
                                              </td>
                                            );
                                          })}
                                        </tr>
                                      ))}
                                  </React.Fragment>
                                );
                              })
                          )}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  <DragOverlay>
                    {draggedPermission ? (
                      <div
                        className={`bg-gradient-to-r text-white border-4 rounded-xl px-6 py-4 shadow-2xl transform rotate-2 scale-110 ${
                          draggedPermission.roleId
                            ? 'from-red-500 to-red-600 border-red-400'
                            : 'from-blue-500 to-blue-600 border-blue-400'
                        }`}
                      >
                        <div className="flex items-center gap-4">
                          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8h16M4 16h16" />
                          </svg>
                          <div>
                            <div className="font-bold text-base">{draggedPermission.permissionSlug}</div>
                            <div
                              className={`text-xs mt-1 flex items-center gap-1 ${
                                draggedPermission.roleId ? 'text-red-100' : 'text-blue-100'
                              }`}
                            >
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                              </svg>
                              {draggedPermission.roleId
                                ? 'Drop on trash to remove from this role'
                                : 'Drop on role to add or trash to remove from all'}
                            </div>
                          </div>
                        </div>
                      </div>
                    ) : null}
                  </DragOverlay>
                </DndContext>
              )}

              {/* Info Box */}
              <div className="mt-6 p-6 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl border-2 border-blue-200">
                <div className="flex items-start gap-3">
                  <div className="text-2xl">💡</div>
                  <div className="flex-1">
                    <p className="text-sm text-blue-900 font-semibold mb-2">
                      <strong>Quick Tips:</strong>
                    </p>
                    <ul className="text-sm text-blue-800 space-y-1 list-disc list-inside">
                      <li>Drag permission cards to role columns to add permissions</li>
                      <li>Click checkboxes to toggle individual permissions</li>
                      <li>Use "All" / "None" buttons in role headers for bulk actions</li>
                      <li>Drag green permission cells to Trash to remove from that role</li>
                      <li>Search to quickly find specific permissions</li>
                      <li>Click group headers to expand/collapse permission categories</li>
                    </ul>
                    <p className="text-xs text-blue-700 mt-3 font-medium">
                      ⚠️ Changes take effect after users log out and log back in.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
