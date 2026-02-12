'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import toast from 'react-hot-toast';

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { logout, hasPermission } = useAuthStore();

  const handleLogout = () => {
    logout();
    toast.success('Logged out successfully');
    router.push('/login');
  };

  const menuItems = [
    { name: 'Dashboard', path: '/dashboard', icon: '📊', permission: 'dashboard.view' },
    { name: 'Appointments', path: '/appointments', icon: '📅', permission: 'appointments.view' },
    { name: 'Services', path: '/services', icon: '💇', permission: 'services.manage' },
    { name: 'Offers', path: '/offers', icon: '🎁', permission: 'offers.manage' },
    { name: 'Customers', path: '/customers', icon: '👥', permission: 'users.view' },
    { name: 'Courses', path: '/courses', icon: '📚', permission: 'courses.manage' },
    { name: 'Experts', path: '/experts', icon: '⭐', permission: 'experts.manage' },
    { name: 'Sales', path: '/sales', icon: '💰', permission: 'dashboard.view' },
    { name: 'Blogs', path: '/blogs', icon: '📝', permission: 'offers.manage' },
    { name: 'Support', path: '/support', icon: '💬', permission: 'support.view' },
    { name: 'Reports', path: '/reports', icon: '📈', permission: 'dashboard.view' },
    { name: 'Settings', path: '/settings', icon: '⚙️', permission: 'roles.view' },
  ];

  return (
    <aside className="hidden md:flex md:w-64 bg-white shadow-lg md:h-screen flex-col">
      <div className="p-6 border-b">
        <h2 className="text-2xl font-bold text-primary-500">BeautyHub</h2>
        <p className="text-xs text-gray-500 mt-1">Marry-Queen Salon</p>
      </div>

      <nav className="flex-1 mt-6 overflow-y-auto">
        {menuItems.map((item) => {
          // Hide menu items if user doesn't have permission
          if (item.permission && !hasPermission(item.permission)) {
            return null;
          }
          
          return (
            <Link
              key={item.path}
              href={item.path}
              className={`flex items-center px-6 py-3 text-gray-700 hover:bg-primary-50 hover:text-primary-600 transition ${
                pathname === item.path ? 'bg-primary-50 text-primary-600 border-r-4 border-primary-500' : ''
              }`}
            >
              <span className="text-xl mr-3">{item.icon}</span>
              <span className="font-medium">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="p-6 border-t">
        <button
          onClick={handleLogout}
          className="w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition font-medium"
        >
          Logout
        </button>
      </div>
    </aside>
  );
}
