'use client';

import React, { useState, useEffect } from 'react';
import {
  DndContext,
  DragEndEvent,
  DragOverEvent,
  DragOverlay,
  DragStartEvent,
  PointerSensor,
  useSensor,
  useSensors,
} from '@dnd-kit/core';
import { updateRolePermissions } from '../lib/api/rbac';
import { AVAILABLE_ROLES, AVAILABLE_PERMISSIONS, INITIAL_RBAC_MATRIX } from '../data/rbacDummyData';
import toast from 'react-hot-toast';

interface DraggedPermission {
  permissionName: string;
  roleId: string;
}

export default function RolePermissionMatrix() {
  const [matrix, setMatrix] = useState<Record<string, string[]>>(INITIAL_RBAC_MATRIX);
  const [isSaving, setIsSaving] = useState(false);
  const [draggedPermission, setDraggedPermission] = useState<DraggedPermission | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  // Initialize matrix from INITIAL_RBAC_MATRIX
  useEffect(() => {
    setMatrix(INITIAL_RBAC_MATRIX);
  }, []);

  const togglePermission = (roleId: string, permissionName: string) => {
    setMatrix((prev) => {
      const rolePermissions = prev[roleId] || [];
      const hasPermission = rolePermissions.includes(permissionName);

      return {
        ...prev,
        [roleId]: hasPermission
          ? rolePermissions.filter((p) => p !== permissionName)
          : [...rolePermissions, permissionName],
      };
    });
  };

  const handleDragStart = (event: DragStartEvent) => {
    const [roleId, permissionName] = event.active.id.toString().split(':');
    setDraggedPermission({ permissionName, roleId });
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (!over || !draggedPermission) {
      setDraggedPermission(null);
      return;
    }

    const [sourceRoleId, permissionName] = active.id.toString().split(':');
    const targetRoleId = over.id.toString();

    // Only allow dropping on role columns (not permission rows)
    if (targetRoleId.startsWith('role-')) {
      const actualTargetRoleId = targetRoleId.replace('role-', '');

      // Don't copy to the same role
      if (actualTargetRoleId !== sourceRoleId) {
        setMatrix((prev) => {
          const targetPermissions = prev[actualTargetRoleId] || [];
          const hasPermission = targetPermissions.includes(permissionName);

          if (!hasPermission) {
            toast.success(`Permission "${permissionName}" copied to ${AVAILABLE_ROLES.find(r => r.id === actualTargetRoleId)?.name}`);
            return {
              ...prev,
              [actualTargetRoleId]: [...targetPermissions, permissionName],
            };
          }
          // Always return the previous state if nothing changes
          return prev;
        });
      }
    }

    setDraggedPermission(null);
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      // 1. Send the current state of checkboxes to the backend
      await updateRolePermissions(matrix);
      
      // 2. Success Feedback
      toast.success('Permissions updated! Users will see changes on next login.');
    } catch (error) {
      // 3. Error Feedback
      toast.error('Failed to save permissions. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  // Group permissions by their group property
  const permissionsByGroup = AVAILABLE_PERMISSIONS.reduce((acc, perm) => {
    if (!acc[perm.group]) {
      acc[perm.group] = [];
    }
    acc[perm.group].push(perm);
    return acc;
  }, {} as Record<string, typeof AVAILABLE_PERMISSIONS>);

  return (
    <DndContext
      sensors={sensors}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >

      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">Role Permission Matrix</h2>
          <div className="flex items-center gap-4">
            <div className="text-sm text-gray-600">
              💡 Drag permissions between role columns to copy them
            </div>
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSaving ? 'Saving...' : 'Save Permissions'}
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full border-collapse">
            <thead>
              <tr className="bg-gray-50">
                <th className="border px-4 py-3 text-left font-semibold text-gray-700 sticky left-0 bg-gray-50 z-10">
                  Permission
                </th>
                {AVAILABLE_ROLES.map((role) => (
                  <th
                    key={role.id}
                    id={`role-${role.id}`}
                    className="border px-4 py-3 text-center font-semibold text-gray-700 min-w-[150px] hover:bg-gray-100 transition-colors"
                  >
                    <div>
                      <div className="font-bold">{role.name}</div>
                      <div className="text-xs text-gray-500 font-normal">{role.description}</div>
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {Object.entries(permissionsByGroup).map(([groupName, permissions]) => (
                <React.Fragment key={groupName}>
                  {/* @ts-ignore */}
                  <tr className="bg-gray-100">
                    <td
                      colSpan={AVAILABLE_ROLES.length + 1}
                      className="border px-4 py-2 font-semibold text-gray-800"
                    >
                      {groupName}
                    </td>
                  </tr>
                  {permissions.map((permission) => (
                    <tr key={permission.id} className="hover:bg-gray-50">
                      <td className="border px-4 py-3 text-sm text-gray-700 sticky left-0 bg-white z-10">
                        {permission.label}
                      </td>
                      {AVAILABLE_ROLES.map((role) => {
                        const hasPermission = matrix[role.id]?.includes(permission.name) || false;
                        return (
                          <td key={role.id} className="border px-4 py-3 text-center">
                            <div
                              id={`${role.id}:${permission.name}`}
                              draggable={hasPermission}
                              onDragStart={(e) => {
                                if (!hasPermission) {
                                  e.preventDefault();
                                  return;
                                }
                              }}
                              className={`inline-block ${hasPermission ? 'cursor-grab active:cursor-grabbing' : 'cursor-not-allowed'}`}
                              title={hasPermission ? `Drag to copy "${permission.label}" to another role` : 'Enable permission first to drag'}
                            >
                              <input
                                type="checkbox"
                                checked={hasPermission}
                                onChange={() => togglePermission(role.id, permission.name)}
                                className="w-5 h-5 text-primary-500 rounded focus:ring-primary-500 cursor-pointer"
                              />
                            </div>
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>

        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <p className="text-sm text-blue-800">
            <strong>Note:</strong> Changes will take effect after users log out and log back in.
          </p>
          <p className="text-sm text-blue-800 mt-2">
            <strong>Tip:</strong> Drag enabled permissions (checked boxes) to other role columns to quickly copy permissions between roles.
          </p>
        </div>
      </div>

      <DragOverlay>
        {draggedPermission ? (
          <div className="bg-blue-100 border border-blue-300 rounded px-3 py-2 shadow-lg">
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={true}
                readOnly
                className="w-4 h-4 text-primary-500 rounded"
              />
              <span className="text-sm font-medium text-blue-800">
                {AVAILABLE_PERMISSIONS.find(p => p.name === draggedPermission.permissionName)?.label}
              </span>
            </div>
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  );
}
