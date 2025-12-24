import axiosClient from './axiosClient';
import { unwrapResponse, unwrapListResponse } from './responseHelper';

export const postService = {
  getPostsByUser: async (userId) => {
    const res = await axiosClient.get(`/api/posts/user/${userId}`);
    return unwrapListResponse(res);
  },
  getPostById: async (postId) => {
    const res = await axiosClient.get(`/api/posts/${postId}`);
    return unwrapResponse(res);
  }
};