'use client';

import Link from 'next/link';
import { useAuthStore } from '@/store/authStore';
import { useRouter } from 'next/navigation';

export default function Header() {
  const { user } = useAuthStore();
  const router = useRouter();

  const handleQuickBook = () => {
    router.push('/appointments?action=quick-book');
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const mobileNavItems = [
    { name: 'Dashboard', path: '/dashboard' },
    { name: 'Profile', path: '/profile' },
    { name: 'Appointments', path: '/appointments' },
    { name: 'Services', path: '/services' },
    { name: 'Reports', path: '/reports' },
  ];

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="flex items-center justify-between px-4 sm:px-6 py-3 sm:py-4">
        <div className="flex items-center space-x-3 sm:space-x-4">
          <button
            onClick={handleQuickBook}
            className="px-3 py-2 sm:px-4 sm:py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors font-medium text-sm sm:text-base"
          >
            Quick Book
          </button>
        </div>

        <div className="flex items-center space-x-3 sm:space-x-4">
          <Link
            href="/profile"
            className="flex items-center space-x-2 sm:space-x-3 hover:opacity-90 transition"
          >
            <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-primary-500 flex items-center justify-center text-white font-bold text-xs sm:text-sm overflow-hidden">
              {user?.profileImage ? (
                <img src={user.profileImage} alt="" className="w-full h-full object-cover" />
              ) : (
                user ? getInitials(user.name) : 'A'
              )}
            </div>
            <div className="text-right">
              <p className="text-sm font-semibold text-gray-800 truncate max-w-[120px] sm:max-w-none">
                {user?.name || 'Admin User'}
              </p>
              <p className="text-xs text-gray-500 capitalize">
                {user?.role || 'Owner'}
              </p>
            </div>
          </Link>
        </div>
      </div>

      {/* Mobile top navigation */}
      <nav className="flex md:hidden px-2 pb-3 space-x-2 overflow-x-auto border-t border-gray-100">
        {mobileNavItems.map((item) => (
          <Link
            key={item.path}
            href={item.path}
            className="whitespace-nowrap px-3 py-2 mt-2 text-xs font-medium rounded-full bg-gray-50 text-gray-700 hover:bg-primary-50 hover:text-primary-600 transition-colors"
          >
            {item.name}
          </Link>
        ))}
      </nav>
    </header>
  );
}
