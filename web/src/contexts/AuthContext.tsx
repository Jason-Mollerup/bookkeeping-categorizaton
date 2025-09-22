import React, { createContext, useContext, useEffect, useState } from "react";
import type { User, LoginForm, RegisterForm } from "@/types";
import { apiService } from "@/services/api";
import { websocketService } from "@/services/websocket";

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (credentials: LoginForm) => Promise<void>;
  register: (userData: RegisterForm) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isAuthenticated = !!user;

  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    if (token) {
      apiService
        .getCurrentUser()
        .then((userData: User) => {
          setUser(userData);
          websocketService.connect(userData.id);
        })
        .catch(() => {
          localStorage.removeItem("auth_token");
        })
        .finally(() => {
          setIsLoading(false);
        });
    } else {
      setIsLoading(false);
    }
  }, []);

  const login = async (credentials: LoginForm) => {
    const { user: userData, token } = await apiService.login(credentials);
    localStorage.setItem("auth_token", token);
    setUser(userData);
    websocketService.connect(userData.id);
  };

  const register = async (userData: RegisterForm) => {
    const { user: newUser, token } = await apiService.register(userData);
    localStorage.setItem("auth_token", token);
    setUser(newUser);
    websocketService.connect(newUser.id);
  };

  const logout = () => {
    localStorage.removeItem("auth_token");
    setUser(null);
    websocketService.disconnect();
  };

  const value: AuthContextType = {
    user,
    isLoading,
    isAuthenticated,
    login,
    register,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
