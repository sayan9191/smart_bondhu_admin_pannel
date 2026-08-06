import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';
import type { AuthResponse } from '../api/client';

interface AuthContextValue {
  user: AuthResponse['user'] | null;
  isAuthenticated: boolean;
  login: (response: AuthResponse) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function readStoredUser(): AuthResponse['user'] | null {
  const raw = localStorage.getItem('admin_user');
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AuthResponse['user'];
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthResponse['user'] | null>(() => {
    const token = localStorage.getItem('admin_access_token');
    return token ? readStoredUser() : null;
  });

  const value = useMemo(
    () => ({
      user,
      isAuthenticated: Boolean(user && localStorage.getItem('admin_access_token')),
      login: (response: AuthResponse) => {
        if (response.user.role !== 'admin') {
          throw new Error('Admin access only');
        }
        localStorage.setItem('admin_access_token', response.tokens.access_token);
        localStorage.setItem('admin_user', JSON.stringify(response.user));
        setUser(response.user);
      },
      logout: () => {
        localStorage.removeItem('admin_access_token');
        localStorage.removeItem('admin_user');
        setUser(null);
      },
    }),
    [user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
