import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  roleId?: string;
  permissions?: string[];
  profileImage?: string;
}

interface AuthStore {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (userData: Partial<User>) => void;
  hasPermission: (permission: string | string[]) => boolean;
  hasRole: (role: string | string[]) => boolean;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      
      login: (user, token) => {
        localStorage.setItem('token', token);
        set({ user, token, isAuthenticated: true });
      },
      
      logout: () => {
        localStorage.removeItem('token');
        set({ user: null, token: null, isAuthenticated: false });
      },
      
      updateUser: (userData) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...userData } : null,
        })),
      
      // Check if user has permission(s)
      hasPermission: (permission) => {
        const user = get().user;
        if (!user || !user.permissions) return false;

        const required = Array.isArray(permission) ? permission : [permission];
        return required.every((perm) => user.permissions?.includes(perm));
      },
      
      // Check if user has role(s)
      hasRole: (role) => {
        const user = get().user;
        if (!user) return false;
        
        const allowedRoles = Array.isArray(role) ? role : [role];
        return allowedRoles.includes(user.role);
      },
    }),
    {
      name: 'auth-storage',
    }
  )
);
