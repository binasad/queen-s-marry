'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';

// Session key to track if this is a fresh page load (refresh) vs navigation
const SESSION_KEY = 'app_session_active';

interface AuthGuardProps {
  children: React.ReactNode;
  requiredPermission?: string | string[];
  requiredRole?: string | string[];
}

export default function AuthGuard({ 
  children, 
  requiredPermission,
  requiredRole 
}: AuthGuardProps) {
  const { isAuthenticated, user, token, hasPermission, hasRole, logout } = useAuthStore();
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthorized, setIsAuthorized] = useState(false);

  useEffect(() => {
    // Check if this is a page refresh (session was active but page reloaded)
    const checkForRefresh = () => {
      const sessionActive = sessionStorage.getItem(SESSION_KEY);
      const wasNavigationType = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      
      // If session was active AND this is a reload (not initial load or navigation)
      if (sessionActive && wasNavigationType?.type === 'reload') {
        // Clear auth and redirect to login
        console.log('Page refresh detected - logging out for security');
        localStorage.removeItem('token');
        localStorage.removeItem('auth-storage');
        sessionStorage.removeItem(SESSION_KEY);
        logout();
        router.replace('/login');
        setIsLoading(false);
        return true;
      }
      
      // Mark session as active for future refresh detection
      sessionStorage.setItem(SESSION_KEY, 'true');
      return false;
    };

    // Check for refresh first
    if (checkForRefresh()) {
      return;
    }

    // Check authentication status
    const checkAuth = () => {
      // Also check localStorage directly for token (handles hydration issues)
      const storedToken = localStorage.getItem('token');
      const authStorage = localStorage.getItem('auth-storage');
      
      let isLoggedIn = isAuthenticated && !!token;
      
      // If zustand hasn't hydrated yet, check localStorage directly
      if (!isLoggedIn && storedToken && authStorage) {
        try {
          const parsed = JSON.parse(authStorage);
          isLoggedIn = parsed.state?.isAuthenticated && !!parsed.state?.token;
        } catch (e) {
          isLoggedIn = false;
        }
      }

      if (!isLoggedIn) {
        // Save the current URL to redirect back after login
        const currentPath = window.location.pathname;
        if (currentPath !== '/login' && currentPath !== '/set-password') {
          sessionStorage.setItem('redirectAfterLogin', currentPath);
        }
        router.replace('/login');
        setIsLoading(false);
        return;
      }
      
      // Check role if specified
      if (requiredRole && !hasRole(requiredRole)) {
        router.replace('/unauthorized');
        setIsLoading(false);
        return;
      }
      
      // Check permission if specified
      if (requiredPermission && !hasPermission(requiredPermission)) {
        router.replace('/unauthorized');
        setIsLoading(false);
        return;
      }

      setIsAuthorized(true);
      setIsLoading(false);
    };

    checkAuth();
  }, [isAuthenticated, token, user, requiredPermission, requiredRole, router, hasPermission, hasRole]);

  // Show loading spinner while checking auth
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500 mx-auto mb-4"></div>
          <p className="text-gray-500">Loading...</p>
        </div>
      </div>
    );
  }

  // Don't render children if not authorized
  if (!isAuthorized) {
    return null;
  }

  return <>{children}</>;
}
