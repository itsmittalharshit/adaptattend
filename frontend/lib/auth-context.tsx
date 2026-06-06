'use client';
import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';

export interface AuthUser {
  token: string;
  role: 'manager' | 'employee';
  userId: string;
  orgId: string;
  fullName: string;
  guestKey: string;
}

interface AuthContextType {
  user: AuthUser | null;
  loading: boolean;
  setUser: (u: AuthUser | null) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  setUser: () => {},
  logout: () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUserState] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    try {
      const raw = localStorage.getItem('auth_user');
      if (raw) {
        const parsed = JSON.parse(raw) as AuthUser;
        setUserState(parsed);
      }
    } catch {
      localStorage.removeItem('auth_user');
    } finally {
      setLoading(false);
    }
  }, []);

  const setUser = useCallback((u: AuthUser | null) => {
    setUserState(u);
    if (u) {
      localStorage.setItem('auth_user', JSON.stringify(u));
      localStorage.setItem('access_token', u.token);
    } else {
      localStorage.removeItem('auth_user');
      localStorage.removeItem('access_token');
    }
  }, []);

  const logout = useCallback(() => {
    setUser(null);
    router.push('/enter-key');
  }, [setUser, router]);

  return (
    <AuthContext.Provider value={{ user, loading, setUser, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
