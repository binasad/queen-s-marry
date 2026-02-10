'use client';

import { useAuthStore } from '@/store/authStore';

interface PermissionGuardProps {
  children: React.ReactNode;
  permission: string | string[];
  fallback?: React.ReactNode;
}

export default function PermissionGuard({ 
  children, 
  permission, 
  fallback = null 
}: PermissionGuardProps) {
  const hasPermission = useAuthStore((state) => state.hasPermission);
  
  if (!hasPermission(permission)) {
    return <>{fallback}</>;
  }
  
  return <>{children}</>;
}
