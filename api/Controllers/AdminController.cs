using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using RealEstateHubAPI.Hubs;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using RealEstateHubAPI.Repositories;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.seeds;
using RealEstateHubAPI.Services;
using RealEstateHubAPI.Utils;
using Microsoft.Extensions.Logging;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    [Route("api/admin")]
    [Authorize(Roles = "Admin")]
    public class AdminController : BaseController
    {
        private readonly ICategoryRepository _categoryRepository;
        private readonly ApplicationDbContext _context;
        private readonly IUserRepository _userRepository;
        private readonly ILocationRepository _locationRepository;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ISavedSearchService? _savedSearchService;
        private readonly ILogger<AdminController> _logger;
        
        //private readonly IEmailService _emailService;

        public AdminController(
            ApplicationDbContext context, 
            ICategoryRepository categoryRepository, 
            IUserRepository userRepository,
            ILocationRepository locationRepository, 
            IHubContext<NotificationHub> hubContext,
            ISavedSearchService? savedSearchService = null,
            ILogger<AdminController>? logger = null)
        {
            _context = context;
            _categoryRepository = categoryRepository;
            _userRepository = userRepository;
            _locationRepository = locationRepository;
            _hubContext = hubContext;
            _savedSearchService = savedSearchService;
            _logger = logger;
            //_emailService = emailService;
        }

        // Get admin dashboard stats
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats()
        {
            var stats = new
            {
                totalPosts = await _context.Posts.CountAsync(),
                totalUsers = await _context.Users.CountAsync(),
                totalReports = await _context.Reports.CountAsync(),
                pendingApprovals = await _context.Posts.CountAsync(p => p.Status == "Pending")
            };
            return Success(stats, "Lấy thống kê thành công");
        }

        // Get recent posts
        [HttpGet("recent-posts")]
        public async Task<IActionResult> GetRecentPosts()
        {
            var posts = await _context.Posts
                .Include(p => p.User)
                .OrderByDescending(p => p.Created)
                .Take(10)
                .ToListAsync();
            return Success(posts, "Lấy danh sách bài đăng gần đây thành công");
        }

        // Get recent users
        [HttpGet("recent-users")]
        public async Task<IActionResult> GetRecentUsers()
        {
            var users = await _context.Users
                .OrderByDescending(u => u.Create)
                .Take(10)
                .ToListAsync();
            return Success(users, "Lấy danh sách người dùng gần đây thành công");
        }

        // Approve a post
        [HttpPost("posts/{postId}/approve")]
        public async Task<IActionResult> ApprovePost(int postId)
        {
            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == postId);
            if (post == null)
                return NotFoundResponse("Không tìm thấy bài đăng");

            post.IsApproved = true; // Giữ lại để tương thích ngược
            post.Status = "Active"; // Đánh dấu là đã duyệt
            
            // Set expiry date based on user's role
            var roleName = post.User.Role ?? "User";
            var now = DateTimeHelper.GetVietnamNow();
            post.ExpiryDate = roleName switch
            {
                "Pro_1" => now.AddDays(30),
                "Pro_3" => now.AddDays(90),
                "Pro_12" => now.AddDays(365),
                _ => now.AddDays(7)
            };
            
            await _context.SaveChangesAsync();

            
            var notification = new Notification
            {
                UserId = post.User.Id,
                PostId = post.Id,
                AppointmentId = null,
                MessageId = null,
                SavedSearchId = null,
                Title = "Tin đăng đã được duyệt",
                Message = $"Tin đăng '{post.Title}' của bạn đã được admin duyệt thành công.",
                Type = "approved",
                IsRead = false,
                CreatedAt = DateTimeHelper.GetVietnamNow()
            };
            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Gửi notification real-time qua SignalR
            await _hubContext.Clients.User(post.User.Id.ToString()).SendAsync("ReceiveNotification", new
            {
                Id = notification.Id,
                UserId = notification.UserId,
                PostId = notification.PostId,
                SavedSearchId = notification.SavedSearchId,
                AppointmentId = notification.AppointmentId,
                MessageId = notification.MessageId,
                Title = notification.Title,
                Message = notification.Message,
                Type = notification.Type,
                CreatedAt = notification.CreatedAt,
                IsRead = notification.IsRead
            });

            // Kiểm tra và tạo thông báo cho SavedSearch nếu post có tọa độ
            if (post.Latitude != null && post.Longitude != null && _savedSearchService != null)
            {
                try
                {
                    await _savedSearchService.CheckAndCreateNotificationsForNewPostAsync(post.Id);
                }
                catch (Exception ex)
                {
                    _logger?.LogError(ex, $"Error creating SavedSearch notifications for Post {post.Id}");
                    // Không throw exception để không ảnh hưởng đến việc approve post
                }
            }
            
            await _hubContext.Clients.User(post.User.Id.ToString()).SendAsync("ReceiveNotification", notification);

            
            //await _emailService.SendAsync(post.User.Email, notification.Title, notification.Message);

            return Success(post, "Duyệt bài đăng thành công");
        }

        // Get all reports with details
        [HttpGet("reports")]
        public async Task<IActionResult> GetReports()
        {
            var reports = await _context.Reports
                .Include(r => r.Post)
                .Include(r => r.User)
                .OrderByDescending(r => r.CreatedReport)
                .Select(r => new
                {
                    r.Id,
                    r.UserId,
                    r.PostId,
                    Type = r.Type.ToString(),
                    r.Other,
                    r.Phone,
                    r.CreatedReport,
                    r.IsHandled,
                    User = new
                    {
                        r.User.Id,
                        r.User.Name,
                        r.User.Phone
                    },
                    Post = new
                    {
                        r.Post.Id,
                        r.Post.Title
                    }
                })
                .ToListAsync();
            return Success(reports, "Lấy danh sách báo cáo thành công");
        }

        /// <summary>
        /// Từ chối bài viết (soft delete - không xóa khỏi database)
        /// Đánh dấu Status = "Rejected" để user vẫn có thể xem bài viết của mình
        /// </summary>
        [HttpPost("posts/{postId}/reject")]
        public async Task<IActionResult> RejectPost(int postId)
        {
            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == postId);
            if (post == null)
                return NotFoundResponse("Không tìm thấy bài đăng");

            // Soft delete: Đánh dấu bài viết là "Rejected" thay vì xóa khỏi database
            post.Status = "Rejected";
            post.IsApproved = false; // Giữ lại để tương thích ngược
            
            await _context.SaveChangesAsync();
            
            // Tạo thông báo cho user biết bài viết bị từ chối
            var notification = new Notification
            {
                UserId = post.UserId,
                PostId = post.Id,
                AppointmentId = null,
                MessageId = null,
                SavedSearchId = null,
                Title = "Tin đăng bị từ chối",
                Message = $"Tin đăng '{post.Title}' của bạn đã bị từ chối bởi admin.",
                Type = "PostRejected",
                IsRead = false,
                CreatedAt = DateTimeHelper.GetVietnamNow()
            };
            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Gửi notification real-time qua SignalR
            await _hubContext.Clients.User(post.UserId.ToString()).SendAsync("ReceiveNotification", new
            {
                Id = notification.Id,
                UserId = notification.UserId,
                PostId = notification.PostId,
                SavedSearchId = notification.SavedSearchId,
                AppointmentId = notification.AppointmentId,
                MessageId = notification.MessageId,
                Title = notification.Title,
                Message = notification.Message,
                Type = notification.Type,
                CreatedAt = notification.CreatedAt,
                IsRead = notification.IsRead
            });

            return Success(new { message = "Bài viết đã được đánh dấu là từ chối", postId = postId }, "Từ chối bài đăng thành công");
        }

        /// <summary>
        /// Xóa bài viết - ĐÃ BỊ VÔ HIỆU HÓA
        /// Thay vào đó, sử dụng RejectPost để đánh dấu "Rejected"
        /// Không xóa bài viết khỏi database để user vẫn có thể xem
        /// </summary>
        [HttpDelete("posts/{postId}")]
        [Obsolete("Sử dụng RejectPost thay vì DeletePost. Không xóa bài viết khỏi database.")]
        public async Task<IActionResult> DeletePost(int postId)
        {
            // Chuyển sang RejectPost thay vì xóa
            return await RejectPost(postId);
        }

        // Lock/Unlock user account
        [HttpPut("users/{userId}/lock")]
        public async Task<IActionResult> ToggleUserLock(int userId, [FromBody] bool isLocked)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return NotFoundResponse("Không tìm thấy bài đăng");

            user.IsLocked = isLocked;
            await _context.SaveChangesAsync();
            return Ok(user);
        }

        // Get all categories
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories()
        {
            var categories = await _context.Categories.ToListAsync();
            return Success(categories, "Lấy danh sách danh mục thành công");
        }

        [HttpPost("categories")]
        public async Task<IActionResult> AddCategory([FromBody] Category category)
        {
            if (string.IsNullOrEmpty(category.Name))
                return BadRequestResponse("Category name is required");

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
                return Created(category, "Thêm danh mục thành công");
        }

        [HttpPut("categories/{id}")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] Category category)
        {
            if (id != category.Id)
                return BadRequestResponse("ID không khớp");

            var existingCategory = await _context.Categories.FindAsync(id);
            if (existingCategory == null)
                return NotFoundResponse("Không tìm thấy bài đăng");

            existingCategory.Name = category.Name;
            await _context.SaveChangesAsync();
            return Success(existingCategory, "Cập nhật danh mục thành công");
        }

        [HttpDelete("categories/{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
                return NotFoundResponse("Không tìm thấy bài đăng");

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return Success<object>(null, "Xóa danh mục thành công");
        }

        // Update user role
        [HttpPut("users/{userId}/role")]
        public async Task<IActionResult> UpdateUserRole(int userId, [FromBody] UpdateUserRoleDto model)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return NotFoundResponse("Không tìm thấy bài đăng");

            if (!Enum.TryParse(typeof(Role), model.Role, true, out var parsedRole))
            {
                return BadRequestResponse("Invalid role. Role must be one of: Admin, User, Pro_1, Pro_3, Pro_12");
            }

            user.Role = parsedRole.ToString();
            await _context.SaveChangesAsync();
            return Ok(user);
        }

        // Delete user (Admin only)
        [HttpDelete("users/{userId}")]
        public async Task<IActionResult> DeleteUser(int userId)
        {
            try
            {
                Console.WriteLine($"Attempting to delete user with ID: {userId}");
                Console.WriteLine($"User claims: {string.Join(", ", User.Claims.Select(c => $"{c.Type}: {c.Value}"))}");
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                {
                    Console.WriteLine($"User not found with ID: {userId}");
                    return NotFoundResponse($"Không tìm thấy user với ID: {userId}");
                }
                Console.WriteLine($"Found user: {user.Name} (ID: {user.Id})");
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
                Console.WriteLine($"Successfully deleted user with ID: {userId}");
                return Success<object>(null, "Xóa user thành công");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error deleting user: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return InternalServerError($"Lỗi khi xóa user: {ex.Message}");
            }
        }

        // City endpoints
        [AllowAnonymous]
        [HttpGet("cities")]
        public async Task<IActionResult> GetCities()
        {
            try
            {
                var cities = await _locationRepository.GetCitiesAsync();
                return Ok(cities);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }
        [AllowAnonymous]
        [HttpGet("cities/{id}")]
        public async Task<IActionResult> GetCityById(int id)
        {
            try
            {
                var city = await _locationRepository.GetCityByIdAsync(id);
                if (city == null)
                {
                    return NotFoundResponse($"City with ID {id} not found");
                }
                return Ok(city);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpPost("cities")]
        public async Task<IActionResult> CreateCity([FromBody] City city)
        {
            try
            {
                await _locationRepository.AddCityAsync(city);
                return Created(city, "Tạo thành phố thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpPut("cities/{id}")]
        public async Task<IActionResult> UpdateCity(int id, [FromBody] City city)
        {
            try
            {
                if (id != city.Id)
                {
                    return BadRequestResponse("City ID mismatch");
                }
                await _locationRepository.UpdateCityAsync(city);
                return Ok(city);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpDelete("cities/{id}")]
        public async Task<IActionResult> DeleteCity(int id)
        {
            try
            {
                await _locationRepository.DeleteCityAsync(id);
                return Success<object>(null, "Xóa danh mục thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        // District endpoints
        [HttpGet("districts")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDistricts()
        {
            try
            {
                var districts = await _locationRepository.GetDistrictsAsync();
                return Ok(districts);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpGet("districts/{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDistrictById(int id)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(id);
                if (district == null)
                {
                    return NotFoundResponse($"District with ID {id} not found");
                }
                return Ok(district);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpGet("cities/{cityId}/districts")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDistrictsByCity(int cityId)
        {
            try
            {
                var city = await _locationRepository.GetCityByIdAsync(cityId);
                if (city == null)
                {
                    return NotFound($"City with ID {cityId} not found");
                }

                var districts = await _locationRepository.GetDistrictsByCityAsync(cityId);
                return Ok(districts);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpPost("districts")]
        public async Task<IActionResult> CreateDistrict([FromBody] CreateDistrictDto districtDto)
        {
            try
            {
                var city = await _locationRepository.GetCityByIdAsync(districtDto.CityId);
                if (city == null)
                {
                    return NotFound($"City with ID {districtDto.CityId} not found");
                }

                var district = new District
                {
                    Name = districtDto.Name,
                    CityId = districtDto.CityId
                };

                await _locationRepository.AddDistrictAsync(district);
                return Created(district, "Tạo quận/huyện thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpPut("areas/districts/{id}")]
        public async Task<IActionResult> UpdateDistrict(int id, [FromBody] CreateDistrictDto districtDto)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(id);
                if (district == null)
                {
                    return NotFound($"District with ID {id} not found.");
                }
                district.Name = districtDto.Name;
                district.CityId = districtDto.CityId;
                await _locationRepository.UpdateDistrictAsync(district);
                return Ok(district);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }


        [HttpDelete("districts/{id}")]
        public async Task<IActionResult> DeleteDistrict(int id)
        {
            try
            {
                await _locationRepository.DeleteDistrictAsync(id);
                return Success<object>(null, "Xóa danh mục thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        // Ward endpoints
        [HttpGet("wards")]
        [AllowAnonymous]
        public async Task<IActionResult> GetWards()
        {
            try
            {
                var wards = await _locationRepository.GetWardsAsync();
                return Ok(wards);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpGet("wards/{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetWardById(int id)
        {
            try
            {
                var ward = await _locationRepository.GetWardByIdAsync(id);
                if (ward == null)
                {
                    return NotFoundResponse($"Ward with ID {id} not found");
                }
                return Ok(ward);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpGet("districts/{districtId}/wards")]
        [AllowAnonymous]
        public async Task<IActionResult> GetWardsByDistrict(int districtId)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(districtId);
                if (district == null)
                {
                    return NotFound($"District with ID {districtId} not found");
                }

                var wards = await _locationRepository.GetWardsByDistrictAsync(districtId);
                return Ok(wards);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpPost("wards")]
        public async Task<IActionResult> CreateWard([FromBody] CreateWardDto wardDto)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(wardDto.DistrictId);
                if (district == null)
                {
                    return NotFound($"District with ID {wardDto.DistrictId} not found");
                }

                var ward = new Ward
                {
                    Name = wardDto.Name,
                    DistrictId = wardDto.DistrictId
                };

                await _locationRepository.AddWardAsync(ward);
                return Created(ward, "Tạo phường/xã thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpPut("areas/wards/{id}")]
        public async Task<IActionResult> UpdateWard(int id, [FromBody] CreateWardDto wardDto)
        {
            try
            {
                var ward = await _locationRepository.GetWardByIdAsync(id);
                if (ward == null)
                {
                    return NotFound($"Ward with ID {id} not found.");
                }
                ward.Name = wardDto.Name;
                ward.DistrictId = wardDto.DistrictId;
                await _locationRepository.UpdateWardAsync(ward);
                return Ok(ward);
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }


        [HttpDelete("wards/{id}")]
        public async Task<IActionResult> DeleteWard(int id)
        {
            try
            {
                await _locationRepository.DeleteWardAsync(id);
                return Success<object>(null, "Xóa danh mục thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        // Seed data endpoint
        [HttpPost("seed-data")]
        [HttpGet("seed-data")] // Support both GET and POST
        [AllowAnonymous] // Allow anonymous for initial setup, can be changed to [Authorize(Roles = "Admin")] later
        public IActionResult SeedData([FromQuery] bool force = false)
        {
            try
            {
                DataSeeder.SeedData(_context, force);
                return Success(new { 
                    message = "Data seeding completed successfully!", 
                    force = force,
                    note = force ? "Data was force seeded (may have overwritten existing data)" : "Data was seeded only if database was empty"
                }, "Seed data thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError($"Lỗi khi seed data: {ex.Message}");
            }
        }

        // Get all notifications (Admin only)
        [HttpGet("notifications")]
        public async Task<IActionResult> GetAllNotifications()
        {
            try
            {
                var notifications = await _context.Notifications
                    .Include(n => n.User)
                    .Include(n => n.Post)
                    .Include(n => n.Appointment)
                    .Include(n => n.MessageEntity)
                    .OrderByDescending(n => n.CreatedAt)
                    .Select(n => new
                    {
                        n.Id,
                        n.UserId,
                        UserName = n.User != null ? n.User.Name : null,
                        n.PostId,
                        PostTitle = n.Post != null ? n.Post.Title : null,
                        n.SavedSearchId,
                        n.AppointmentId,
                        n.Title,
                        n.Message,
                        n.Type,
                        n.CreatedAt,
                        n.IsRead
                    })
                    .ToListAsync();
                return Success(notifications, "Lấy danh sách thông báo thành công");
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all notifications");
                return InternalServerError($"Lỗi khi lấy thông báo: {ex.Message}");
            }
        }

        // Get all messages/conversations (Admin only)
        [HttpGet("messages")]
        public async Task<IActionResult> GetAllMessages()
        {
            try
            {
                var messages = await _context.Messages
                    .Include(m => m.Sender)
                    .Include(m => m.Receiver)
                    .Include(m => m.Post)
                    .OrderByDescending(m => m.SentTime)
                    .Select(m => new
                    {
                        m.Id,
                        m.SenderId,
                        SenderName = m.Sender != null ? m.Sender.Name : null,
                        m.ReceiverId,
                        ReceiverName = m.Receiver != null ? m.Receiver.Name : null,
                        m.PostId,
                        PostTitle = m.Post != null ? m.Post.Title : null,
                        m.Content,
                        m.SentTime,
                        m.IsRead
                    })
                    .ToListAsync();
                return Success(messages, "Lấy danh sách tin nhắn thành công");
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all messages");
                return InternalServerError($"Lỗi khi lấy tin nhắn: {ex.Message}");
            }
        }

        // Get all saved searches (Admin only)
        [HttpGet("saved-searches")]
        public async Task<IActionResult> GetAllSavedSearches()
        {
            try
            {
                var savedSearches = await _context.SavedSearches
                    .Include(ss => ss.User)
                    .OrderByDescending(ss => ss.CreatedAt)
                    .Select(ss => new
                    {
                        ss.Id,
                        ss.UserId,
                        UserName = ss.User != null ? ss.User.Name : null,
                        ss.CenterLatitude,
                        ss.CenterLongitude,
                        ss.RadiusKm,
                        TransactionType = ss.TransactionType.ToString(),
                        ss.MinPrice,
                        ss.MaxPrice,
                        ss.EnableNotification,
                        ss.IsActive,
                        ss.CreatedAt
                    })
                    .ToListAsync();
                return Success(savedSearches, "Lấy danh sách tìm kiếm đã lưu thành công");
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all saved searches");
                return InternalServerError($"Lỗi khi lấy tìm kiếm đã lưu: {ex.Message}");
            }
        }

        // Get all appointments (Admin only)
        [HttpGet("appointments")]
        public async Task<IActionResult> GetAllAppointments()
        {
            try
            {
                var appointments = await _context.Appointments
                    .Include(a => a.User)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new
                    {
                        a.Id,
                        a.UserId,
                        UserName = a.User != null ? a.User.Name : null,
                        a.Title,
                        a.Description,
                        a.AppointmentTime,
                        a.ReminderMinutes,
                        a.IsNotified,
                        Status = a.Status,
                        a.CreatedAt
                    })
                    .ToListAsync();
                return Success(appointments, "Lấy danh sách lịch hẹn thành công");
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all appointments");
                return InternalServerError($"Lỗi khi lấy lịch hẹn: {ex.Message}");
            }
        }

    }
}