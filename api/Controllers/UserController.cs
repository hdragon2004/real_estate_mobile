using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using RealEstateHubAPI.Repositories;
using System.Security.Claims;

namespace RealEstateHubAPI.Controllers
{
    [Route("api/users")]
    [ApiController]
    
    public class UserController : BaseController
    {
        private readonly IUserRepository _userRepository;
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public UserController(IUserRepository userRepository, ApplicationDbContext context, IWebHostEnvironment env)
        {
            _userRepository = userRepository;
            _context = context;
            _env = env;
          
        }

        

        [AllowAnonymous]
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            try
            {
                var users = await _userRepository.GetUsersAsync();
                return Success(users, "Lấy danh sách người dùng thành công");
            }
            catch (Exception ex)
            {
                // Handle exception
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(int id)
        {
            var user = await _userRepository.GetUserByIdAsync(id);
            if (user == null) return NotFoundResponse("Không tìm thấy người dùng");
            
            // Trả về avatar mặc định nếu user không có avatar
            if (string.IsNullOrEmpty(user.AvatarUrl))
            {
                user.AvatarUrl = "/uploads/avatars/avatar.jpg";
            }
            
            return Success(user, "Lấy thông tin người dùng thành công");
        }

        [AllowAnonymous] 
        [HttpPost]
        public async Task<IActionResult> AddUser([FromBody] User user)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return Created(user, "Thêm người dùng thành công");
        }

        

        
        
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return UnauthorizedResponse("Chưa đăng nhập");
            var userId = int.Parse(userIdClaim);
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFoundResponse("Không tìm thấy người dùng");
            
            // Trả về avatar mặc định nếu user không có avatar
            if (string.IsNullOrEmpty(user.AvatarUrl))
            {
                user.AvatarUrl = "/uploads/avatars/avatar.jpg";
            }
            
            return Success(user, "Lấy thông tin profile thành công");
        }


        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] User updateUser)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return UnauthorizedResponse("Chưa đăng nhập");
            var userId = int.Parse(userIdClaim);

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFoundResponse("Không tìm thấy người dùng");

            // Cập nhật các trường được phép
            user.Name = updateUser.Name;
            user.Email = updateUser.Email;
            user.Phone = updateUser.Phone;
            user.AvatarUrl = updateUser.AvatarUrl;

            await _context.SaveChangesAsync();
            return Success(user, "Cập nhật profile thành công");
        }


        [HttpPost("avatar")]
        public async Task<IActionResult> UploadAvatar([FromForm] IFormFile avatar)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return UnauthorizedResponse("Chưa đăng nhập");
            var userId = int.Parse(userIdClaim);

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFoundResponse("Không tìm thấy người dùng");

            // Validate file
            if (avatar == null || avatar.Length == 0)
                return BadRequestResponse("Không có file được tải lên");

            // Đường dẫn lưu file upload
            var uploads = Path.Combine(_env.WebRootPath, "uploads", "avatars");
            if (!Directory.Exists(uploads))
                Directory.CreateDirectory(uploads);

            // Xóa avatar cũ nếu có (tránh tích tụ file rác)
            if (!string.IsNullOrEmpty(user.AvatarUrl) && user.AvatarUrl.StartsWith("/uploads/avatars/"))
            {
                var oldAvatarPath = Path.Combine(_env.WebRootPath, user.AvatarUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
                if (System.IO.File.Exists(oldAvatarPath))
                {
                    try
                    {
                        System.IO.File.Delete(oldAvatarPath);
                    }
                    catch (Exception ex)
                    {
                        // Log lỗi nhưng không chặn việc upload avatar mới
                        // Có thể log vào logger nếu cần
                    }
                }
            }

            // Tạo tên file mới tránh trùng
            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(avatar.FileName)}";
            var filePath = Path.Combine(uploads, fileName);

            // Lưu file lên server
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await avatar.CopyToAsync(stream);
            }

            // Cập nhật URL avatar cho user
            user.AvatarUrl = $"/uploads/avatars/{fileName}";
            await _context.SaveChangesAsync();

            return Success(new { avatarUrl = user.AvatarUrl }, "Tải lên avatar thành công");
        }


    }
}
