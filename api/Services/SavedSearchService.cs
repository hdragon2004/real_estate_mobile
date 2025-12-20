using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Services
{
    /// <summary>
    /// Service implementation cho SavedSearch
    /// Xử lý logic nghiệp vụ cho khu vực tìm kiếm yêu thích
    /// </summary>
    public class SavedSearchService : ISavedSearchService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<SavedSearchService> _logger;

        public SavedSearchService(
            ApplicationDbContext context,
            ILogger<SavedSearchService> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Tạo SavedSearch mới cho user
        /// </summary>
        public async Task<SavedSearchDto> CreateSavedSearchAsync(int userId, CreateSavedSearchDto dto)
        {
            // Validate MinPrice <= MaxPrice
            if (dto.MinPrice.HasValue && dto.MaxPrice.HasValue && dto.MinPrice.Value > dto.MaxPrice.Value)
            {
                throw new ArgumentException("MinPrice must be less than or equal to MaxPrice");
            }

            var savedSearch = new SavedSearch
            {
                UserId = userId,
                CenterLatitude = dto.CenterLatitude,
                CenterLongitude = dto.CenterLongitude,
                RadiusKm = dto.RadiusKm,
                TransactionType = dto.TransactionType,
                MinPrice = dto.MinPrice,
                MaxPrice = dto.MaxPrice,
                EnableNotification = dto.EnableNotification,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.SavedSearches.Add(savedSearch);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Created SavedSearch {savedSearch.Id} for User {userId}");

            return MapToDto(savedSearch);
        }

        /// <summary>
        /// Lấy tất cả SavedSearch của user (chỉ active)
        /// </summary>
        public async Task<IEnumerable<SavedSearchDto>> GetUserSavedSearchesAsync(int userId)
        {
            var savedSearches = await _context.SavedSearches
                .Where(ss => ss.UserId == userId && ss.IsActive)
                .OrderByDescending(ss => ss.CreatedAt)
                .ToListAsync();

            return savedSearches.Select(MapToDto);
        }

        /// <summary>
        /// Xóa SavedSearch (chỉ user sở hữu mới xóa được)
        /// </summary>
        public async Task<bool> DeleteSavedSearchAsync(int savedSearchId, int userId)
        {
            var savedSearch = await _context.SavedSearches
                .FirstOrDefaultAsync(ss => ss.Id == savedSearchId && ss.UserId == userId);

            if (savedSearch == null)
            {
                return false;
            }

            // Soft delete: set IsActive = false thay vì xóa thật
            savedSearch.IsActive = false;
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Deleted SavedSearch {savedSearchId} for User {userId}");

            return true;
        }

        /// <summary>
        /// Tìm các Post phù hợp với SavedSearch
        /// Sử dụng Haversine formula để tính khoảng cách
        /// </summary>
        public async Task<IEnumerable<PostDto>> FindMatchingPostsAsync(int savedSearchId, int userId)
        {
            // Lấy SavedSearch và kiểm tra quyền sở hữu
            var savedSearch = await _context.SavedSearches
                .FirstOrDefaultAsync(ss => ss.Id == savedSearchId && ss.UserId == userId && ss.IsActive);

            if (savedSearch == null)
            {
                throw new KeyNotFoundException("SavedSearch not found or access denied");
            }

            // Lấy tất cả posts đã approved và còn hạn, có tọa độ
            var allPosts = await _context.Posts
                .Include(p => p.Category)
                .Include(p => p.User)
                .Include(p => p.Images)
                .Where(p => p.Status == "Active" &&
                    (p.ExpiryDate == null || p.ExpiryDate > DateTime.Now) &&
                    p.Latitude != null &&
                    p.Longitude != null &&
                    p.TransactionType == savedSearch.TransactionType)
                .ToListAsync();

            // Filter theo khoảng giá nếu có
            if (savedSearch.MinPrice.HasValue)
            {
                allPosts = allPosts.Where(p => p.Price >= savedSearch.MinPrice.Value).ToList();
            }

            if (savedSearch.MaxPrice.HasValue)
            {
                allPosts = allPosts.Where(p => p.Price <= savedSearch.MaxPrice.Value).ToList();
            }

            // Tính khoảng cách và filter posts trong radius
            var matchingPosts = allPosts
                .Where(p => CalculateDistance(
                    savedSearch.CenterLatitude,
                    savedSearch.CenterLongitude,
                    p.Latitude.Value,
                    p.Longitude.Value) <= savedSearch.RadiusKm)
                .OrderBy(p => CalculateDistance(
                    savedSearch.CenterLatitude,
                    savedSearch.CenterLongitude,
                    p.Latitude.Value,
                    p.Longitude.Value))
                .ToList();

            // Map sang DTO
            return matchingPosts.Select(p => MapPostToDto(p));
        }

        /// <summary>
        /// Kiểm tra và tạo thông báo cho các bài đăng mới phù hợp với SavedSearch
        /// Được gọi khi có bài đăng mới được tạo hoặc approved
        /// </summary>
        public async Task CheckAndCreateNotificationsForNewPostAsync(int postId)
        {
            var post = await _context.Posts
                .Include(p => p.Category)
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null || post.Status != "Active" || 
                post.Latitude == null || post.Longitude == null)
            {
                return; // Post không hợp lệ hoặc chưa có tọa độ
            }

            // Tìm tất cả SavedSearch active có EnableNotification = true
            // và phù hợp với TransactionType của post
            var matchingSavedSearches = await _context.SavedSearches
                .Where(ss => ss.IsActive &&
                    ss.EnableNotification &&
                    ss.TransactionType == post.TransactionType)
                .ToListAsync();

            foreach (var savedSearch in matchingSavedSearches)
            {
                // Kiểm tra khoảng giá
                if (savedSearch.MinPrice.HasValue && post.Price < savedSearch.MinPrice.Value)
                    continue;

                if (savedSearch.MaxPrice.HasValue && post.Price > savedSearch.MaxPrice.Value)
                    continue;

                // Tính khoảng cách
                var distance = CalculateDistance(
                    savedSearch.CenterLatitude,
                    savedSearch.CenterLongitude,
                    post.Latitude.Value,
                    post.Longitude.Value);

                // Nếu post nằm trong bán kính
                if (distance <= savedSearch.RadiusKm)
                {
                    // Kiểm tra xem đã có thông báo cho SavedSearch này và Post này chưa
                    var existingNotification = await _context.Notifications
                        .FirstOrDefaultAsync(n => n.SavedSearchId == savedSearch.Id && 
                                                   n.PostId == postId &&
                                                   n.Type == "SavedSearch");

                    if (existingNotification == null)
                    {
                        // Tạo thông báo mới (sử dụng Notification chung, phân loại bằng Type = NotificationType.SavedSearch)
                        var notification = new Notification
                        {
                            UserId = savedSearch.UserId,
                            PostId = postId,
                            SavedSearchId = savedSearch.Id, // Lưu SavedSearchId để biết SavedSearch nào trigger và tránh duplicate
                            Title = "Bài đăng mới trong khu vực quan tâm",
                            Message = $"Có bài đăng mới phù hợp với khu vực tìm kiếm của bạn: {post.Title}",
                            Type = "SavedSearch",
                            CreatedAt = DateTime.UtcNow,
                            IsRead = false
                        };

                        _context.Notifications.Add(notification);

                        _logger.LogInformation(
                            $"Created SavedSearch notification for SavedSearch {savedSearch.Id}, Post {postId}, User {savedSearch.UserId}");
                        
                        // Gửi notification real-time qua SignalR (nếu có hub context)
                        // Note: Background service cần inject IHubContext qua IServiceProvider
                        // Được xử lý trong PostController hoặc AdminController khi approve post
                    }
                }
            }

            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Tính khoảng cách giữa 2 điểm trên Trái Đất bằng Haversine formula
        /// Trả về khoảng cách tính bằng km
        /// </summary>
        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371; // Bán kính Trái Đất (km)

            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            var distance = R * c;

            return distance;
        }

        /// <summary>
        /// Chuyển đổi độ sang radian
        /// </summary>
        private double ToRadians(double degrees)
        {
            return degrees * (Math.PI / 180);
        }

        /// <summary>
        /// Map SavedSearch entity sang DTO
        /// </summary>
        private SavedSearchDto MapToDto(SavedSearch savedSearch)
        {
            return new SavedSearchDto
            {
                Id = savedSearch.Id,
                UserId = savedSearch.UserId,
                CenterLatitude = savedSearch.CenterLatitude,
                CenterLongitude = savedSearch.CenterLongitude,
                RadiusKm = savedSearch.RadiusKm,
                TransactionType = savedSearch.TransactionType,
                MinPrice = savedSearch.MinPrice,
                MaxPrice = savedSearch.MaxPrice,
                EnableNotification = savedSearch.EnableNotification,
                IsActive = savedSearch.IsActive,
                CreatedAt = savedSearch.CreatedAt
            };
        }

        /// <summary>
        /// Map Post entity sang PostDto
        /// </summary>
        private PostDto MapPostToDto(Post post)
        {
            return new PostDto
            {
                Id = post.Id,
                Title = post.Title,
                Description = post.Description,
                Price = post.Price,
                PriceUnit = post.PriceUnit,
                TransactionType = post.TransactionType,
                Status = post.Status,
                Created = post.Created,
                Area_Size = post.Area_Size,
                Street_Name = post.Street_Name,
                ImageURL = post.ImageURL,
                UserId = post.UserId,
                CategoryId = post.CategoryId,
                IsApproved = post.IsApproved,
                ExpiryDate = post.ExpiryDate,
                SoPhongNgu = post.SoPhongNgu,
                SoPhongTam = post.SoPhongTam,
                SoTang = post.SoTang,
                HuongNha = post.HuongNha,
                HuongBanCong = post.HuongBanCong,
                MatTien = post.MatTien,
                DuongVao = post.DuongVao,
                PhapLy = post.PhapLy,
                FullAddress = post.FullAddress,
                Longitude = post.Longitude,
                Latitude = post.Latitude,
                PlaceId = post.PlaceId,
                CityName = post.CityName,
                DistrictName = post.DistrictName,
                WardName = post.WardName,
                CategoryName = post.Category?.Name ?? "N/A",
                UserName = post.User?.Name ?? "N/A",
                ImageUrls = post.Images?.ToList() ?? new List<PostImage>(),
                TimeAgo = FormatTimeAgo(post.Created)
            };
        }

        /// <summary>
        /// Format thời gian thành "time ago" string
        /// </summary>
        private string FormatTimeAgo(DateTime dateTime)
        {
            var timeSpan = DateTime.Now - dateTime;

            if (timeSpan.TotalMinutes < 1)
                return "Vừa xong";
            if (timeSpan.TotalMinutes < 60)
                return $"{(int)timeSpan.TotalMinutes} phút trước";
            if (timeSpan.TotalHours < 24)
                return $"{(int)timeSpan.TotalHours} giờ trước";
            if (timeSpan.TotalDays < 30)
                return $"{(int)timeSpan.TotalDays} ngày trước";
            if (timeSpan.TotalDays < 365)
                return $"{(int)(timeSpan.TotalDays / 30)} tháng trước";
            return $"{(int)(timeSpan.TotalDays / 365)} năm trước";
        }
    }
}

