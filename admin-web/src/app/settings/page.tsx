'use client';

import Link from 'next/link';
import AuthGuard from '@/components/AuthGuard';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';
import PermissionGuard from '@/components/PermissionGuard';

export default function SettingsPage() {
  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto">
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800 mb-8">Settings & RBAC Management</h1>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <Link href="/settings/roles">
                  <div className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition cursor-pointer h-full">
                    <div className="text-4xl mb-4">👥</div>
                    <h3 className="text-xl font-semibold text-gray-800 mb-2">Role Assignment</h3>
                    <p className="text-sm text-gray-600">
                      Assign roles to users by email address. Users will only have access to features based on their assigned role permissions.
                    </p>
                    <div className="mt-4 text-sm text-primary-600 font-medium">
                      Manage User Roles →
                    </div>
                  </div>
                </Link>

                <Link href="/settings/permissions">
                  <div className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition cursor-pointer h-full">
                    <div className="text-4xl mb-4">🔐</div>
                    <h3 className="text-xl font-semibold text-gray-800 mb-2">Permission Matrix</h3>
                    <p className="text-sm text-gray-600">
                      Manage role permissions. Configure what each role can and cannot do in the system using a visual matrix.
                    </p>
                    <div className="mt-4 text-sm text-primary-600 font-medium">
                      Configure Permissions →
                    </div>
                  </div>
                </Link>
              </div>

              <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-blue-900 mb-2">How RBAC Works</h3>
                <ul className="list-disc list-inside space-y-2 text-sm text-blue-800">
                  <li><strong>Step 1:</strong> Configure permissions for each role in the Permission Matrix</li>
                  <li><strong>Step 2:</strong> Assign roles to users by their email address in Role Assignment</li>
                  <li><strong>Step 3:</strong> Users must log out and log back in for changes to take effect</li>
                  <li><strong>Step 4:</strong> Users will only see and access features based on their role's permissions</li>
                  <li><strong>Security:</strong> Backend API also enforces permissions - even if frontend is bypassed, unauthorized actions are blocked</li>
                </ul>
              </div>
            </div>
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
