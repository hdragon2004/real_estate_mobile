import React, { createContext, useState, useEffect, useContext } from 'react';
import axiosClient from '../api/axiosClient';
import axiosPrivate from '../api/axiosPrivate';
import { unwrapResponse } from '../api/responseHelper';
import { toast } from 'react-hot-toast';

// Tạo và export AuthContext
export const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Kiểm tra token trong localStorage khi component mount
    const token = localStorage.getItem('token');
    if (token) {
      fetchUserProfile();
    } else {
      setLoading(false);
    }
  }, []);

  const fetchUserProfile = async () => {
    try {
      const response = await axiosPrivate.get('/api/users/profile');
      const userData = unwrapResponse(response);
      setUser(userData);
    } catch (error) {
      console.error('Error fetching user profile:', error);
      localStorage.removeItem('token');
    } finally {
      setLoading(false);
    }
  };

  const login = async (email, password) => {
    try {
      const response = await axiosClient.post("/api/auth/login", {
        email,
        password,
      });

      // API trả về format: { status, message, data: { user, token } }
      const responseData = response.data;
      
      // Kiểm tra nếu có data và token trong data
      if (responseData.data && responseData.data.token) {
        const token = responseData.data.token;
        const user = responseData.data.user;
        
        localStorage.setItem("token", token);
        setUser(user);
        
        // Hiển thị thông báo thành công
        showNotification(responseData.message || "Đăng nhập thành công", "success");
        
        return { success: true };
      }
      
      // Nếu không có token trong data, trả về lỗi
      const errorMessage = responseData?.message || "Không nhận được token từ server";
      return { success: false, error: errorMessage };
    } catch (error) {
      console.error("Login error:", error);
      const errorMessage = error.response?.data?.message || 
                          error.response?.data || 
                          "Đăng nhập thất bại"; 
      return { success: false, error: errorMessage };
    }
  };

  const register = async (userData) => {
    try {
      console.log('Register data being sent:', userData);
      const response = await axiosPrivate.post('/api/auth/register', userData);
      console.log('Register response:', response.data);
      
      // API trả về format: { status, message, data: { user, token } }
      const responseData = response.data;
      
      // Kiểm tra nếu có data và token trong data
      if (responseData.data && responseData.data.token) {
        const token = responseData.data.token;
        const user = responseData.data.user;
        
        localStorage.setItem('token', token);
        if (user) {
          setUser(user);
        }
        
        // Hiển thị thông báo thành công
        showNotification(responseData.message || "Đăng ký thành công", "success");
        
        return { success: true };
      } else {
        return {
          success: false,
          error: responseData?.message || 'Không nhận được token từ server'
        };
      }
    } catch (error) {
      console.error('Register error:', error.response?.data);
      const errorMessage = error.response?.data?.message || 
                          error.response?.data || 
                          'Đăng ký thất bại';
      return {
        success: false,
        error: errorMessage
      };
    }
  };

  const logout = () => {
    console.log('Logging out...');
    localStorage.removeItem('token');
    setUser(null);
  };

  const updateProfile = async (userData) => {
    try {
      console.log('Updating profile...');
      const response = await axiosPrivate.put('/api/users/profile', userData);
      const updatedUser = unwrapResponse(response);
      console.log('Profile update response:', updatedUser);
      setUser(updatedUser);
      return { success: true };
    } catch (error) {
      console.error('Profile update error:', error);
      const errorData = error.response?.data;
      return {
        success: false,
        error: errorData?.message || 'Cập nhật thông tin thất bại'
      };
    }
  };

  

  const showNotification = (message, type = 'error') => {
    const baseOptions = {
      duration: 5000,
      position: 'top-right',
      style: {
        padding: '10px',
        borderRadius: '8px',
        fontSize: '14px',
        
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }
    };

    if (type === 'error') {
      toast.error(message, {
        ...baseOptions,
        style: {
          ...baseOptions.style,
          background: '#fee',
          color: '#c00',
        }
      });
    } else if (type === 'warning') {
      toast(message, {
        ...baseOptions,
        icon: '⚠️',
        style: {
          ...baseOptions.style,
          background: '#fff3cd',
          color: '#856404',
        }
      });
    } else {
      toast.success(message, {
        ...baseOptions,
        style: {
          ...baseOptions.style,
          background: '#e8f5e9',
          color: '#2e7d32',
        }
      });
    }
  };

  const value = {
    user,
    loading,
    login,
    register,
    logout,
    updateProfile,
    refreshUser: fetchUserProfile,
    showNotification
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
