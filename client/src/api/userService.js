import axiosClient from './axiosClient';
import { unwrapResponse } from './responseHelper';

export const userService = {
  getProfile: async () => {
    const res = await axiosClient.get('/api/users/profile');
    return unwrapResponse(res);
  },
  updateProfile: async (data) => {
    const res = await axiosClient.put('/api/users/profile', data);
    return unwrapResponse(res);
  },
  uploadAvatar: async (formData) => {
    const res = await axiosClient.post('/api/users/avatar', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
    return unwrapResponse(res);
  }
};