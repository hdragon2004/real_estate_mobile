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
using Microsoft.Extensions.Logging;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    [Route("api/admin")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
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
            return Ok(stats);
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
            return Ok(posts);
        }

        // Get recent users
        [HttpGet("recent-users")]
        public async Task<IActionResult> GetRecentUsers()
        {
            var users = await _context.Users
                .OrderByDescending(u => u.Create)
                .Take(10)
                .ToListAsync();
            return Ok(users);
        }

        // Approve a post
        [HttpPost("posts/{postId}/approve")]
        public async Task<IActionResult> ApprovePost(int postId)
        {
            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == postId);
            if (post == null)
                return NotFound();

            post.IsApproved = true; // Giữ lại để tương thích ngược
            post.Status = "Active"; // Đánh dấu là đã duyệt
            
            // Set expiry date based on user's role
            var roleName = post.User.Role ?? "User";
            post.ExpiryDate = roleName switch
            {
                "Pro_1" => DateTime.Now.AddDays(30),
                "Pro_3" => DateTime.Now.AddDays(90),
                "Pro_12" => DateTime.Now.AddDays(365),
                _ => DateTime.Now.AddDays(7)
            };
            
            await _context.SaveChangesAsync();

            
            var notification = new Notification
            {
                UserId = post.User.Id,
                PostId = post.Id,
                Title = "Tin đăng đã được duyệt",
                Message = $"Tin đăng '{post.Title}' của bạn đã được admin duyệt thành công.",
                Type = "approved",
                IsRead = false,
                CreatedAt = DateTime.Now
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

            return Ok(post);
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
            return Ok(reports);
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
                return NotFound();

            // Soft delete: Đánh dấu bài viết là "Rejected" thay vì xóa khỏi database
            post.Status = "Rejected";
            post.IsApproved = false; // Giữ lại để tương thích ngược
            
            await _context.SaveChangesAsync();
            
            // Tạo thông báo cho user biết bài viết bị từ chối
            var notification = new Notification
            {
                UserId = post.UserId,
                PostId = post.Id,
                Title = "Tin đăng bị từ chối",
                Message = $"Tin đăng '{post.Title}' của bạn đã bị từ chối bởi admin.",
                Type = "PostRejected",
                IsRead = false,
                CreatedAt = DateTime.Now
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
                Title = notification.Title,
                Message = notification.Message,
                Type = notification.Type,
                CreatedAt = notification.CreatedAt,
                IsRead = notification.IsRead
            });

            return Ok(new { message = "Bài viết đã được đánh dấu là từ chối", postId = postId });
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
                return NotFound();

            user.IsLocked = isLocked;
            await _context.SaveChangesAsync();
            return Ok(user);
        }

        // Get all categories
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories()
        {
            var categories = await _context.Categories.ToListAsync();
            return Ok(categories);
        }

        [HttpPost("categories")]
        public async Task<IActionResult> AddCategory([FromBody] Category category)
        {
            if (string.IsNullOrEmpty(category.Name))
                return BadRequest("Category name is required");

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCategories), new { id = category.Id }, category);
        }

        [HttpPut("categories/{id}")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] Category category)
        {
            if (id != category.Id)
                return BadRequest();

            var existingCategory = await _context.Categories.FindAsync(id);
            if (existingCategory == null)
                return NotFound();

            existingCategory.Name = category.Name;
            await _context.SaveChangesAsync();
            return Ok(existingCategory);
        }

        [HttpDelete("categories/{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
                return NotFound();

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return Ok();
        }

        // Update user role
        [HttpPut("users/{userId}/role")]
        public async Task<IActionResult> UpdateUserRole(int userId, [FromBody] UpdateUserRoleDto model)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return NotFound();

            if (!Enum.TryParse(typeof(Role), model.Role, true, out var parsedRole))
            {
                return BadRequest("Invalid role. Role must be one of: Admin, User, Pro_1, Pro_3, Pro_12");
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
                    return NotFound($"Không tìm thấy user với ID: {userId}");
                }
                Console.WriteLine($"Found user: {user.Name} (ID: {user.Id})");
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
                Console.WriteLine($"Successfully deleted user with ID: {userId}");
                return Ok(new { message = "Xóa user thành công" });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error deleting user: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return StatusCode(500, new { message = "Lỗi khi xóa user", error = ex.Message });
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
                return StatusCode(500, "Internal server error");
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
                    return NotFound($"City with ID {id} not found");
                }
                return Ok(city);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("cities")]
        public async Task<IActionResult> CreateCity([FromBody] City city)
        {
            try
            {
                await _locationRepository.AddCityAsync(city);
                return CreatedAtAction(nameof(GetCityById), new { id = city.Id }, city);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPut("cities/{id}")]
        public async Task<IActionResult> UpdateCity(int id, [FromBody] City city)
        {
            try
            {
                if (id != city.Id)
                {
                    return BadRequest("City ID mismatch.");
                }
                await _locationRepository.UpdateCityAsync(city);
                return Ok(city);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpDelete("cities/{id}")]
        public async Task<IActionResult> DeleteCity(int id)
        {
            try
            {
                await _locationRepository.DeleteCityAsync(id);
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return StatusCode(500, "Internal server error");
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
                    return NotFound($"District with ID {id} not found");
                }
                return Ok(district);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return StatusCode(500, "Internal server error");
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
                return CreatedAtAction(nameof(GetDistrictById), new { id = district.Id }, district);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return StatusCode(500, "Internal server error");
            }
        }


        [HttpDelete("districts/{id}")]
        public async Task<IActionResult> DeleteDistrict(int id)
        {
            try
            {
                await _locationRepository.DeleteDistrictAsync(id);
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return StatusCode(500, "Internal server error");
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
                    return NotFound($"Ward with ID {id} not found");
                }
                return Ok(ward);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return StatusCode(500, "Internal server error");
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
                return CreatedAtAction(nameof(GetWardById), new { id = ward.Id }, ward);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return StatusCode(500, "Internal server error");
            }
        }


        [HttpDelete("wards/{id}")]
        public async Task<IActionResult> DeleteWard(int id)
        {
            try
            {
                await _locationRepository.DeleteWardAsync(id);
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                return Ok(new { 
                    message = "Data seeding completed successfully!", 
                    force = force,
                    note = force ? "Data was force seeded (may have overwritten existing data)" : "Data was seeded only if database was empty"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error seeding data", error = ex.Message });
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
                    .Include(n => n.SavedSearch)
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
                return Ok(notifications);
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all notifications");
                return StatusCode(500, new { message = "Error getting notifications", error = ex.Message });
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
                return Ok(messages);
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all messages");
                return StatusCode(500, new { message = "Error getting messages", error = ex.Message });
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
                return Ok(savedSearches);
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all saved searches");
                return StatusCode(500, new { message = "Error getting saved searches", error = ex.Message });
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
                        a.IsCanceled,
                        a.CreatedAt
                    })
                    .ToListAsync();
                return Ok(appointments);
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error getting all appointments");
                return StatusCode(500, new { message = "Error getting appointments", error = ex.Message });
            }
        }

    }
}