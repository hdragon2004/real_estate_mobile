import axiosClient from './axiosClient';
import { unwrapResponse, unwrapListResponse } from './responseHelper';

export const messageService = {
    // Gửi tin nhắn mới
    sendMessage: async (messageData) => {
        try {
            const response = await axiosClient.post('/api/messages', messageData);
            return unwrapResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            if (errorData?.message) {
                throw new Error(errorData.message);
            } else if (errorData) {
                throw new Error(typeof errorData === 'string' ? errorData : 'Không thể gửi tin nhắn');
            } else {
                throw new Error('Không thể gửi tin nhắn. Vui lòng thử lại sau.');
            }
        }
    },

    // Lấy cuộc hội thoại giữa 2 người dùng về một bài đăng
    getConversation: async (user1Id, user2Id, postId) => {
        try {
            const response = await axiosClient.get(`/api/messages/${user1Id}/${user2Id}/${postId}`);
            return unwrapListResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || error.message || 'Không thể lấy cuộc hội thoại');
        }
    },

    // Lấy tất cả tin nhắn của một người dùng
    getUserMessages: async (userId) => {
        try {
            const response = await axiosClient.get(`/api/messages/user/${userId}`);
            return unwrapListResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || error.message || 'Không thể lấy tin nhắn');
        }
    },

    // Lấy tất cả tin nhắn của một bài đăng
    getPostMessages: async (postId) => {
        try {
            const response = await axiosClient.get(`/api/messages/post/${postId}`);
            return unwrapListResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || error.message || 'Không thể lấy tin nhắn');
        }
    },
    
    deleteConversation: async (user1Id, user2Id, postId) => {
        try {
            const response = await axiosClient.delete(
                `/api/messages/conversation`,
                { params: { user1Id, user2Id, postId } }
            );
            return unwrapResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || 'Xóa hội thoại thất bại');
        }
    },
}; 
