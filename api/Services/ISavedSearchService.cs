using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Services
{
    /// <summary>
    /// Service interface cho SavedSearch
    /// </summary>
    public interface ISavedSearchService
    {
        /// <summary>
        /// Tạo SavedSearch mới cho user
        /// </summary>
        Task<SavedSearchDto> CreateSavedSearchAsync(int userId, CreateSavedSearchDto dto);

        /// <summary>
        /// Lấy tất cả SavedSearch của user
        /// </summary>
        Task<IEnumerable<SavedSearchDto>> GetUserSavedSearchesAsync(int userId);

        /// <summary>
        /// Xóa SavedSearch (chỉ user sở hữu mới xóa được)
        /// </summary>
        Task<bool> DeleteSavedSearchAsync(int savedSearchId, int userId);

        /// <summary>
        /// Tìm các Post phù hợp với SavedSearch
        /// Sử dụng Haversine formula để tính khoảng cách
        /// </summary>
        Task<IEnumerable<PostDto>> FindMatchingPostsAsync(int savedSearchId, int userId);

        /// <summary>
        /// Kiểm tra và tạo thông báo cho các bài đăng mới phù hợp với SavedSearch
        /// Được gọi khi có bài đăng mới được tạo hoặc approved
        /// </summary>
        Task CheckAndCreateNotificationsForNewPostAsync(int postId);
    }
}

