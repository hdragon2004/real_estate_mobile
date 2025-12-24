import axiosPrivate from './axiosPrivate';
import { unwrapResponse } from './responseHelper';

export const chatService = {
    // Lấy token cho Stream Chat
    getUserToken: async (userId, userName, userImage) => {
        try {
            const response = await axiosPrivate.post('/api/chat/token', {
                userId,
                userName,
                userImage
            });
            return unwrapResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || error.message || 'Không thể lấy token');
        }
    },

    // Upsert users in Stream (server-side)
    ensureUsers: async (userIds) => {
        try {
            const response = await axiosPrivate.post('/api/chat/ensure-users', { userIds });
            return unwrapResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || error.message || 'Không thể đảm bảo users');
        }
    },

    // Delete a Stream channel on server
    deleteChannel: async (type, id, hardDelete = true) => {
        try {
            const response = await axiosPrivate.delete(`/api/chat/channels/${encodeURIComponent(type)}/${encodeURIComponent(id)}?hardDelete=${hardDelete}`);
            return unwrapResponse(response);
        } catch (error) {
            const errorData = error.response?.data;
            throw new Error(errorData?.message || error.message || 'Không thể xóa channel');
        }
    },
};
