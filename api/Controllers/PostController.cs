using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.Extensions.Caching.Memory;
using System.Text.Json;
using RealEstateHubAPI.Services;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    [Route("api/posts")]
    
    public class PostController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;
        private readonly ILogger<PostController> _logger;
        private readonly IMemoryCache _cache;
        private readonly IGooglePlacesMappingService _googlePlacesMappingService;
        private readonly ISavedSearchService? _savedSearchService;

        public PostController(
            ApplicationDbContext context, 
            IWebHostEnvironment env, 
            ILogger<PostController> logger, 
            IMemoryCache cache,
            IGooglePlacesMappingService googlePlacesMappingService,
            ISavedSearchService? savedSearchService = null)
        {
            _context = context;
            _env = env;
            _logger = logger;
            _cache = cache;
            _googlePlacesMappingService = googlePlacesMappingService;
            _savedSearchService = savedSearchService;
        }
        
        private List<string> GetUserRoles() {
            return User
                .Claims
                .Where(c => c.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role")
                .Select(c => c.Value)
                .ToList();
        }
        
        private int? GetUserId()
        {
            var userId = User
                .Claims
                .Where(c => c.Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier")
                .Select(c => c.Value)
                .FirstOrDefault();
            int id;
            if (int.TryParse(userId, out id))
            {
                return id;
            }
            else {
                return null;
            }
        }

        /// <summary>
        /// Set avatar mặc định cho user nếu user không có avatar
        /// </summary>
        private void SetDefaultAvatarIfNeeded(User? user)
        {
            if (user != null && string.IsNullOrEmpty(user.AvatarUrl))
            {
                user.AvatarUrl = "/uploads/avatars/avatar.jpg";
            }
        }

        [AllowAnonymous]
        [HttpGet]
        public async Task<IActionResult> GetPosts(
            [FromQuery] bool? isApproved,
            [FromQuery] string? transactionType,
            [FromQuery] string? categoryType)
        {
                var posts = _context.Posts
                .Include(p => p.User)
                .Include(p => p.Category)
                .Include(p => p.Images)
                .AsQueryable();

            // Filter by approval status - ưu tiên dùng Status, nhưng vẫn hỗ trợ isApproved để tương thích ngược
            if (isApproved.HasValue)
            {
                if (isApproved.Value)
                {
                    var oneDayAgo = DateTime.Now.AddDays(-1);
                    posts = posts.Where(p => p.Status == "Active" && (p.ExpiryDate == null || p.ExpiryDate > oneDayAgo));
                }
                else
                {
                    posts = posts.Where(p => p.Status == "Pending" || p.Status == "Rejected");
                }
            }
            else
            {
                // Mặc định chỉ hiển thị bài viết đã duyệt (Active) và chưa hết hạn
                posts = posts.Where(p => p.Status == "Active" &&
                    (p.ExpiryDate == null || p.ExpiryDate > DateTime.Now));
            }

            // Filter by transaction type
            if (!string.IsNullOrEmpty(transactionType))
            {
                if (Enum.TryParse<TransactionType>(transactionType, true, out var transactionTypeEnum))
                {
                    posts = posts.Where(p => p.TransactionType == transactionTypeEnum);
                }
            }

            // Filter by category type
            if (!string.IsNullOrEmpty(categoryType))
            {
                posts = posts.Where(p => p.Category.Name.ToLower().Contains(categoryType.ToLower()));
            }

            var postsList = await posts.ToListAsync();
            
            // Set avatar mặc định cho user trong mỗi post sau khi filter
            foreach (var post in postsList)
            {
                SetDefaultAvatarIfNeeded(post.User);
            }

            return Ok(postsList);
        }
        
        /// <summary>
        /// Tìm kiếm posts trong bán kính từ một điểm trên bản đồ
        /// 
        /// Sử dụng POST thay vì GET vì:
        /// - Request body chứa tọa độ và bán kính (phức tạp hơn query string)
        /// - POST cho phép gửi dữ liệu lớn hơn và bảo mật hơn
        /// 
        /// Tính toán Haversine được thực hiện trên backend để:
        /// - Giảm tải cho client (không cần tính toán phức tạp trên mobile)
        /// - Đảm bảo tính nhất quán của công thức tính toán
        /// - Có thể cache và optimize query trên database
        /// - FREE solution, không cần Google Maps API
        /// 
        /// Route: POST /api/posts/map-radius-search
        /// </summary>
        [AllowAnonymous]
        [HttpPost("map-radius-search")]
        [ProducesResponseType(typeof(IEnumerable<PostDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<IEnumerable<PostDto>>> SearchByRadius(
            [FromBody] SearchByRadiusDto dto)
        {
            try
            {
                _logger.LogInformation($"[MapRadiusSearch] Called with CenterLat={dto.CenterLat}, CenterLng={dto.CenterLng}, RadiusInKm={dto.RadiusInKm}");
                
                // Validate input
                if (dto.RadiusInKm <= 0)
                {
                    _logger.LogWarning($"[MapRadiusSearch] Invalid radius: {dto.RadiusInKm}");
                    return BadRequest(new { error = "Radius must be greater than 0" });
                }

                // Lấy tất cả posts đã approved và còn hạn
                var allPosts = await _context.Posts
                    .Include(p => p.Category)
                    .Include(p => p.User)
                    .Include(p => p.Images)
                    .Where(p => p.Status == "Active" &&
                        (p.ExpiryDate == null || p.ExpiryDate > DateTime.Now) &&
                        p.Latitude != null &&
                        p.Longitude != null)
                    .ToListAsync();

                // Tính khoảng cách và filter posts trong radius
                var postsInRadius = allPosts
                    .Where(p => CalculateDistance(
                        dto.CenterLat,
                        dto.CenterLng,
                        p.Latitude.Value,
                        p.Longitude.Value) <= dto.RadiusInKm)
                    .OrderBy(p => CalculateDistance(
                        dto.CenterLat,
                        dto.CenterLng,
                        p.Latitude.Value,
                        p.Longitude.Value))
                    .ToList();

                // Set avatar mặc định cho user trong mỗi post và map sang DTO
                var postDtos = postsInRadius.Select(p =>
                {
                    SetDefaultAvatarIfNeeded(p.User);
                    return new PostDto
                    {
                        Id = p.Id,
                        Title = p.Title,
                        Description = p.Description,
                        Price = p.Price,
                        PriceUnit = p.PriceUnit,
                        TransactionType = p.TransactionType,
                        Status = p.Status,
                        Created = p.Created,
                        Area_Size = p.Area_Size,
                        Street_Name = p.Street_Name,
                        ImageURL = p.ImageURL,
                        UserId = p.UserId,
                        CategoryId = p.CategoryId,
                        IsApproved = p.IsApproved,
                        ExpiryDate = p.ExpiryDate,
                        SoPhongNgu = p.SoPhongNgu,
                        SoPhongTam = p.SoPhongTam,
                        SoTang = p.SoTang,
                        HuongNha = p.HuongNha,
                        HuongBanCong = p.HuongBanCong,
                        MatTien = p.MatTien,
                        DuongVao = p.DuongVao,
                        PhapLy = p.PhapLy,
                        FullAddress = p.FullAddress,
                        Longitude = p.Longitude,
                        Latitude = p.Latitude,
                        PlaceId = p.PlaceId,
                        CityName = p.CityName,
                        DistrictName = p.DistrictName,
                        WardName = p.WardName,
                        CategoryName = p.Category?.Name ?? "N/A",
                        UserName = p.User?.Name ?? "N/A",
                        ImageUrls = p.Images.ToList(),
                        TimeAgo = FormatTimeAgo(p.Created)
                    };
                }).ToList();

                _logger.LogInformation($"[MapRadiusSearch] Found {postDtos.Count} posts within {dto.RadiusInKm}km radius");
                
                // Trả về empty list nếu không có kết quả (HTTP 200 với empty array)
                return Ok(postDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[MapRadiusSearch] Error searching posts by radius");
                return StatusCode(500, new { error = "Internal server error", message = ex.Message });
            }
        }
        
        // GET: api/posts/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            try
            {
                var post = await _context.Posts
                    .Include(p => p.Category)
                    .Include(p => p.User)
                    .Include(p => p.Images)
                    .FirstOrDefaultAsync(p => p.Id == id);

                if (post == null)
                    return NotFound();

                // Set avatar mặc định cho user nếu cần
                SetDefaultAvatarIfNeeded(post.User);

                return Ok(post);
            }
            catch (Exception ex)
            {
                // Log lỗi chi tiết hơn trong môi trường phát triển
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // POST: api/posts
        [HttpPost]
        public async Task<IActionResult> Create([FromForm] CreatePostDto dto, int role)
        {
            // Validate required fields trước
            if (string.IsNullOrEmpty(dto.Title) || string.IsNullOrEmpty(dto.Description) || 
                dto.Price <= 0 || dto.Area_Size <= 0 || string.IsNullOrEmpty(dto.Street_Name) || 
                dto.CategoryId <= 0 || dto.UserId <= 0)
            {
                return BadRequest("All required fields must be filled with valid values");
            }

            // Verify User exists và kiểm tra IsLocked
            var user = await _context.Users.FindAsync(dto.UserId);
            if (user == null)
            {
                return BadRequest($"User with ID {dto.UserId} not found");
            }

            // Kiểm tra user có bị khóa không
            if (user.IsLocked)
            {
                return BadRequest("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên để được hỗ trợ.");
            }

            // Kiểm tra nếu có token, userId từ token phải khớp với dto.UserId
            var currentUserId = GetUserId();
            if (currentUserId.HasValue && currentUserId.Value != dto.UserId)
            {
                return BadRequest("Bạn chỉ có thể tạo post cho chính tài khoản của mình.");
            }

            // Enforce posting limits based on user's current role
            var roleName = user.Role ?? "User";
            int limit;
            int windowDays;
            switch (roleName)
            {
                case "Pro_1":
                    limit = 100; windowDays = 30; break;
                case "Pro_3":
                    limit = 300; windowDays = 90; break;
                case "Pro_12":
                    limit = 1200; windowDays = 365; break;
                default:
                    limit = 5; windowDays = 7; break;
            }

            var cutoff = DateTime.Now.AddDays(-windowDays);
            var countInWindow = _context.Posts
                .Where(p => p.UserId == dto.UserId && p.Created >= cutoff)
                .Count();

            if (countInWindow >= limit)
            {
                return BadRequest($"Bạn đã đạt giới hạn {limit} bài viết trong {windowDays} ngày. Nâng cấp gói Pro để đăng nhiều hơn (Pro_1: 100/30 ngày, Pro_3: 300/90 ngày, Pro_12: 1200/365 ngày). Vào trang Membership để nâng cấp.");
            }

            try
            {
                // Log received data (không serialize IFormFile vì không thể serialize)
                _logger.LogInformation($"Received CreatePostDto - Title: {dto.Title}, Images count: {dto.Images?.Length ?? 0}");
                if (dto.Images != null && dto.Images.Length > 0)
                {
                    for (int i = 0; i < dto.Images.Length; i++)
                    {
                        _logger.LogInformation($"Image {i}: FileName={dto.Images[i].FileName}, Length={dto.Images[i].Length}, ContentType={dto.Images[i].ContentType}");
                    }
                }

                // Validate Address: phải có CityName, DistrictName, WardName (từ provinces.open-api.vn)
                if (string.IsNullOrEmpty(dto.CityName) || 
                    string.IsNullOrEmpty(dto.DistrictName) || 
                    string.IsNullOrEmpty(dto.WardName))
                {
                    return BadRequest("CityName, DistrictName, and WardName are required (from provinces.open-api.vn)");
                }

                // Nếu có FullAddress nhưng chưa có CityName/DistrictName/WardName, tự động parse
                if (!string.IsNullOrEmpty(dto.FullAddress) && 
                    (string.IsNullOrEmpty(dto.CityName) || string.IsNullOrEmpty(dto.DistrictName) || string.IsNullOrEmpty(dto.WardName)))
                {
                    var (cityName, districtName, wardName) = _googlePlacesMappingService.ParseFullAddress(dto.FullAddress);
                    
                    if (!string.IsNullOrEmpty(cityName))
                        dto.CityName = dto.CityName ?? cityName;
                    if (!string.IsNullOrEmpty(districtName))
                        dto.DistrictName = dto.DistrictName ?? districtName;
                    if (!string.IsNullOrEmpty(wardName))
                        dto.WardName = dto.WardName ?? wardName;

                    _logger.LogInformation($"Parsed FullAddress '{dto.FullAddress}' -> City: {dto.CityName}, District: {dto.DistrictName}, Ward: {dto.WardName}");
                }

                // Parse TransactionType from string to enum
                if (!Enum.TryParse<TransactionType>(dto.TransactionType.ToString(), true, out var transactionType))
                {
                    return BadRequest($"Invalid TransactionType: {dto.TransactionType}. Must be either 'Sale' or 'Rent'");
                }

                // Verify Category exists
                var category = await _context.Categories.FindAsync(dto.CategoryId);
                if (category == null)
                {
                    return BadRequest($"Category with ID {dto.CategoryId} not found");
                }

                // Tính toán thời gian hết hạn dựa trên role (user đã được verify ở trên)
                DateTime? expiryDate = null;
                var roleNameForExpiry = user.Role ?? "User";
                expiryDate = roleNameForExpiry switch
                {
                    "Pro_1" => DateTime.Now.AddDays(30),
                    "Pro_3" => DateTime.Now.AddDays(90),
                    "Pro_12" => DateTime.Now.AddDays(365),
                    _ => DateTime.Now.AddDays(7)
                };

                var post = new Post
                {
                    Title = dto.Title,
                    Description = dto.Description,
                    Price = dto.Price,
                    TransactionType = transactionType,
                    PriceUnit = dto.PriceUnit,
                    Status = "Pending", // Luôn là "Pending" khi tạo mới, chỉ admin mới có thể thay đổi
                    Street_Name = dto.Street_Name,
                    Area_Size = dto.Area_Size,
                    Created = DateTime.Now,
                    CategoryId = dto.CategoryId,
                    UserId = GetUserId() ?? dto.UserId,
                    IsApproved = false, // Giữ lại để tương thích ngược, nhưng ưu tiên dùng Status
                    ExpiryDate = expiryDate,
                    Images = new List<PostImage>(),
                    SoPhongNgu = dto.SoPhongNgu,
                    SoPhongTam = dto.SoPhongTam,
                    SoTang = dto.SoTang,
                    HuongNha = dto.HuongNha,
                    HuongBanCong = dto.HuongBanCong,
                    MatTien = dto.MatTien,
                    DuongVao = dto.DuongVao,
                    PhapLy = dto.PhapLy,
                    // Google Maps integration fields
                    FullAddress = dto.FullAddress,
                    Longitude = dto.Longitude,
                    Latitude = dto.Latitude,
                    PlaceId = dto.PlaceId,
                    // Address components để tìm kiếm/filter
                    CityName = dto.CityName,
                    DistrictName = dto.DistrictName,
                    WardName = dto.WardName
                };

                // Log post object before saving
                _logger.LogInformation($"Created Post object: {System.Text.Json.JsonSerializer.Serialize(post)}");

                if (dto.Images != null && dto.Images.Any())
                {
                    // Lưu tất cả ảnh vào thư mục uploads/posts (không phân biệt ảnh chính hay ảnh phụ)
                    var uploadsPath = Path.Combine(_env.WebRootPath, "uploads", "posts");
                    if (!Directory.Exists(uploadsPath))
                    {
                        Directory.CreateDirectory(uploadsPath);
                    }

                    string? firstImageUrl = null; // Lưu URL của ảnh đầu tiên (ảnh chính)

                    // Lưu tất cả ảnh vào thư mục posts
                    for (int i = 0; i < dto.Images.Length; i++)
                    {
                        var image = dto.Images[i];
                        var fileName = $"{Guid.NewGuid()}_{image.FileName}";
                        var filePath = Path.Combine(uploadsPath, fileName);

                        try
                        {
                            using (var stream = new FileStream(filePath, FileMode.Create))
                            {
                                await image.CopyToAsync(stream);
                            }
                            _logger.LogInformation($"Saved image {i + 1}/{dto.Images.Length}: {fileName} ({image.Length} bytes)");

                            var imageUrl = $"/uploads/posts/{fileName}";
                            var postImage = new PostImage 
                            { 
                                Url = imageUrl,
                                PostId = 0 // Sẽ được set tự động khi Post được save
                            };
                            post.Images.Add(postImage);

                            // Lưu URL của ảnh đầu tiên làm ảnh chính
                            if (i == 0)
                            {
                                firstImageUrl = imageUrl;
                                _logger.LogInformation($"First image URL saved: {firstImageUrl}");
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, $"Error saving image {i + 1}: {image.FileName}");
                            throw;
                        }
                    }

                    // Set ImageURL: ưu tiên dto.ImageURL nếu có, nếu không thì dùng ảnh đầu tiên
                    if (!string.IsNullOrEmpty(dto.ImageURL))
                    {
                        // Kiểm tra xem ImageURL có trong danh sách ảnh đã upload không
                        var imageExists = post.Images.Any(img => img.Url == dto.ImageURL);
                        if (imageExists)
                        {
                            post.ImageURL = dto.ImageURL;
                            _logger.LogInformation($"Set ImageURL from DTO: {dto.ImageURL}");
                        }
                        else
                        {
                            // Nếu ImageURL không khớp với ảnh nào, dùng ảnh đầu tiên
                            post.ImageURL = firstImageUrl ?? post.Images.First().Url;
                            _logger.LogWarning($"ImageURL from DTO ({dto.ImageURL}) not found in uploaded images, using first image: {post.ImageURL}");
                        }
                    }
                    else if (!string.IsNullOrEmpty(firstImageUrl))
                    {
                        // Nếu không có ImageURL trong DTO, dùng ảnh đầu tiên
                        post.ImageURL = firstImageUrl;
                        _logger.LogInformation($"Set ImageURL to first image: {firstImageUrl}");
                    }
                    else if (post.Images.Any())
                    {
                        post.ImageURL = post.Images.First().Url;
                        _logger.LogInformation($"Set ImageURL (fallback) to: {post.ImageURL}");
                    }
                }
                else
                {
                    _logger.LogWarning("No images provided in CreatePostDto");
                }

                // Đảm bảo ImageURL được set nếu có ảnh
                if (post.Images != null && post.Images.Any() && string.IsNullOrEmpty(post.ImageURL))
                {
                    post.ImageURL = post.Images.First().Url;
                    _logger.LogWarning($"ImageURL was null but Images exist, setting to first image: {post.ImageURL}");
                }

                // Log trước khi save để kiểm tra ImageURL
                _logger.LogInformation($"Post before save - ImageURL: {post.ImageURL ?? "NULL"}, Images count: {post.Images?.Count ?? 0}");
                if (post.Images != null && post.Images.Any())
                {
                    _logger.LogInformation($"First image URL: {post.Images.First().Url}");
                }

                _context.Posts.Add(post);
                
                try
                {
                    await _context.SaveChangesAsync();
                    
                    // Reload post từ database để kiểm tra ImageURL đã được lưu chưa
                    await _context.Entry(post).ReloadAsync();
                    _logger.LogInformation($"Post saved successfully - Id: {post.Id}, ImageURL: {post.ImageURL ?? "NULL"}");

                    // Nếu post được approve ngay (IsApproved = true), kiểm tra và tạo thông báo cho SavedSearch
                    if (post.IsApproved && _savedSearchService != null && post.Latitude != null && post.Longitude != null)
                    {
                        try
                        {
                            await _savedSearchService.CheckAndCreateNotificationsForNewPostAsync(post.Id);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, $"Error creating SavedSearch notifications for Post {post.Id}");
                            // Không throw exception để không ảnh hưởng đến việc tạo post
                        }
                    }
                    
                    if (string.IsNullOrEmpty(post.ImageURL))
                    {
                        _logger.LogError($"ERROR: ImageURL is still NULL after save! PostId: {post.Id}, Images count: {post.Images?.Count ?? 0}");
                    }
                }
                catch (DbUpdateException ex)
                {
                    _logger.LogError($"Database update error: {ex.Message}");
                    _logger.LogError($"Inner exception: {ex.InnerException?.Message}");
                    return StatusCode(500, $"Database error: {ex.InnerException?.Message ?? ex.Message}");
                }

                // Xóa tin nháp khi đăng tin thành công
                var userId = GetUserId();
                if (userId.HasValue)
                {
                    var draftKey = $"post_draft_{userId}";
                    _cache.Remove(draftKey);
                    _logger.LogInformation($"Đã xóa tin nháp cho user {userId} sau khi đăng tin thành công");
                }

                return CreatedAtAction(nameof(GetById), new { id = post.Id }, post);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error in Create post: {ex.Message}");
                _logger.LogError($"Stack trace: {ex.StackTrace}");
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // PUT: api/posts/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromForm] UpdatePostDto updateDto)
        {
            if (id != updateDto.Id)
                return BadRequest("ID không khớp.");

            var post = await _context.Posts
                .Include(p => p.Images) 
                .FirstOrDefaultAsync(p => p.Id == id);

            if (post == null)
                return NotFound("Bài đăng không tìm thấy.");

            // Nếu có FullAddress nhưng chưa có CityName/DistrictName/WardName, tự động parse
            if (!string.IsNullOrEmpty(updateDto.FullAddress) && 
                (string.IsNullOrEmpty(updateDto.CityName) || string.IsNullOrEmpty(updateDto.DistrictName) || string.IsNullOrEmpty(updateDto.WardName)))
            {
                var (cityName, districtName, wardName) = _googlePlacesMappingService.ParseFullAddress(updateDto.FullAddress);
                
                if (!string.IsNullOrEmpty(cityName))
                    updateDto.CityName = updateDto.CityName ?? cityName;
                if (!string.IsNullOrEmpty(districtName))
                    updateDto.DistrictName = updateDto.DistrictName ?? districtName;
                if (!string.IsNullOrEmpty(wardName))
                    updateDto.WardName = updateDto.WardName ?? wardName;

                _logger.LogInformation($"Parsed FullAddress '{updateDto.FullAddress}' -> City: {updateDto.CityName}, District: {updateDto.DistrictName}, Ward: {updateDto.WardName}");
            }

            // Validate Address: nếu có thay đổi thì phải có đầy đủ CityName, DistrictName, WardName
            if ((!string.IsNullOrEmpty(updateDto.CityName) || !string.IsNullOrEmpty(updateDto.DistrictName) || !string.IsNullOrEmpty(updateDto.WardName)) &&
                (string.IsNullOrEmpty(updateDto.CityName) || string.IsNullOrEmpty(updateDto.DistrictName) || string.IsNullOrEmpty(updateDto.WardName)))
            {
                return BadRequest("If updating address, CityName, DistrictName, and WardName are all required (from provinces.open-api.vn)");
            }
           
            post.Title = updateDto.Title;
            post.Description = updateDto.Description;
            post.Price = updateDto.Price;
            post.PriceUnit = updateDto.PriceUnit;
            post.TransactionType = updateDto.TransactionType;
            post.Status = updateDto.Status; 
            post.Street_Name = updateDto.Street_Name;
            post.Area_Size = updateDto.Area_Size;
            post.CategoryId = updateDto.CategoryId;
            post.SoPhongNgu = updateDto.SoPhongNgu;
            post.SoPhongTam = updateDto.SoPhongTam;
            post.SoTang = updateDto.SoTang;
            post.HuongNha = updateDto.HuongNha;
            post.HuongBanCong = updateDto.HuongBanCong;
            post.MatTien = updateDto.MatTien;
            post.DuongVao = updateDto.DuongVao;
            post.PhapLy = updateDto.PhapLy;
            // Google Maps integration fields
            post.FullAddress = updateDto.FullAddress ?? post.FullAddress;
            post.Longitude = updateDto.Longitude ?? post.Longitude;
            post.Latitude = updateDto.Latitude ?? post.Latitude;
            post.PlaceId = updateDto.PlaceId ?? post.PlaceId;
            // Address components để tìm kiếm/filter
            post.CityName = updateDto.CityName ?? post.CityName;
            post.DistrictName = updateDto.DistrictName ?? post.DistrictName;
            post.WardName = updateDto.WardName ?? post.WardName;
            

            // Handle new images
            if (updateDto.Images != null && updateDto.Images.Any())
            {
                // Lưu tất cả ảnh vào thư mục uploads/posts (không phân biệt ảnh chính hay ảnh phụ)
                var uploadsPath = Path.Combine(_env.WebRootPath, "uploads", "posts");
                if (!Directory.Exists(uploadsPath))
                {
                    Directory.CreateDirectory(uploadsPath);
                }

                string? firstImageUrl = null;

                // Lưu tất cả ảnh vào thư mục posts
                for (int i = 0; i < updateDto.Images.Length; i++)
                {
                    var image = updateDto.Images[i];
                    var fileName = $"{Guid.NewGuid()}_{image.FileName}";
                    var filePath = Path.Combine(uploadsPath, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await image.CopyToAsync(stream);
                    }

                    var imageUrl = $"/uploads/posts/{fileName}";
                    post.Images.Add(new PostImage { Url = imageUrl });

                    if (i == 0)
                    {
                        firstImageUrl = imageUrl;
                    }
                }

                // Set ImageURL: ưu tiên updateDto.ImageURL nếu có, nếu không thì dùng ảnh đầu tiên
                if (!string.IsNullOrEmpty(updateDto.ImageURL))
                {
                    // Kiểm tra xem ImageURL có trong danh sách ảnh đã upload không
                    var imageExists = post.Images.Any(img => img.Url == updateDto.ImageURL);
                    if (imageExists)
                    {
                        post.ImageURL = updateDto.ImageURL;
                        _logger.LogInformation($"Updated ImageURL from DTO: {updateDto.ImageURL}");
                    }
                    else
                    {
                        // Nếu ImageURL không khớp với ảnh nào, dùng ảnh đầu tiên
                        post.ImageURL = firstImageUrl ?? post.Images.First().Url;
                        _logger.LogWarning($"ImageURL from DTO ({updateDto.ImageURL}) not found in uploaded images, using first image: {post.ImageURL}");
                    }
                }
                else if (!string.IsNullOrEmpty(firstImageUrl))
                {
                    // Nếu không có ImageURL trong DTO, dùng ảnh đầu tiên
                    post.ImageURL = firstImageUrl;
                    _logger.LogInformation($"Updated ImageURL to first image: {firstImageUrl}");
                }
                else if (post.Images.Any())
                {
                    post.ImageURL = post.Images.First().Url;
                    _logger.LogInformation($"Updated ImageURL (fallback) to: {post.ImageURL}");
                }
            }
            else if (!string.IsNullOrEmpty(updateDto.ImageURL))
            {
                // Nếu không có ảnh mới nhưng có ImageURL trong DTO, cập nhật ImageURL
                // Kiểm tra xem ImageURL có trong danh sách ảnh hiện tại không
                var imageExists = post.Images?.Any(img => img.Url == updateDto.ImageURL) ?? false;
                if (imageExists)
                {
                    post.ImageURL = updateDto.ImageURL;
                    _logger.LogInformation($"Updated ImageURL from DTO (no new images): {updateDto.ImageURL}");
                }
                else
                {
                    _logger.LogWarning($"ImageURL from DTO ({updateDto.ImageURL}) not found in existing images");
                }
            }


            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/posts/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var post = await _context.Posts
                .Include(p => p.Images)
                .FirstOrDefaultAsync(p => p.Id == id);
            if (post == null)
                return NotFound();

            _context.PostImages.RemoveRange(post.Images);
            _context.Posts.Remove(post);

            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<Post>>> SearchPosts(
            [FromQuery] int? categoryId,
            [FromQuery] string? status, // Changed to nullable - not required
            [FromQuery] decimal? minPrice,
            [FromQuery] decimal? maxPrice,
            [FromQuery] decimal? minArea,
            [FromQuery] decimal? maxArea,
            [FromQuery] int? cityId,
            [FromQuery] int? districtId,
            [FromQuery] int? wardId,
            [FromQuery] string? cityName, // Added for location filtering
            [FromQuery] string? districtName, // Added for location filtering
            [FromQuery] string? wardName, // Added for location filtering
            [FromQuery] string? q) // Changed to nullable - not required
        {
            try
            {
                var query = _context.Posts
                    .Include(p => p.Category)
                    .Include(p => p.User)
                    .AsQueryable();

                // Apply filters
                if (categoryId.HasValue)
                    query = query.Where(p => p.CategoryId == categoryId);

                if (!string.IsNullOrEmpty(status))
                    query = query.Where(p => p.Status == status);

                if (minPrice.HasValue)
                    query = query.Where(p => p.Price >= minPrice);

                if (maxPrice.HasValue)
                    query = query.Where(p => p.Price <= maxPrice);

                if (minArea.HasValue)
                    query = query.Where(p => p.Area_Size >= (float)minArea);

                if (maxArea.HasValue)
                    query = query.Where(p => p.Area_Size <= (float)maxArea);

                // Filter by location using cityName, districtName, wardName query parameters
                if (!string.IsNullOrEmpty(cityName))
                    query = query.Where(p => p.CityName != null && p.CityName.Contains(cityName));
                
                if (!string.IsNullOrEmpty(districtName))
                    query = query.Where(p => p.DistrictName != null && p.DistrictName.Contains(districtName));
                
                if (!string.IsNullOrEmpty(wardName))
                    query = query.Where(p => p.WardName != null && p.WardName.Contains(wardName));

                // Search query (q) - optional, search in title, description, and address fields
                if (!string.IsNullOrEmpty(q))
                {
                    var searchQuery = q.ToLower();
                    query = query.Where(p =>
                        (p.Title != null && p.Title.ToLower().Contains(searchQuery)) ||
                        (p.Description != null && p.Description.ToLower().Contains(searchQuery)) ||
                        (p.Street_Name != null && p.Street_Name.ToLower().Contains(searchQuery)) ||
                        (p.CityName != null && p.CityName.ToLower().Contains(searchQuery)) ||
                        (p.DistrictName != null && p.DistrictName.ToLower().Contains(searchQuery)) ||
                        (p.WardName != null && p.WardName.ToLower().Contains(searchQuery))
                    );
                }

                // Only return Active posts (approved posts) for public search
                query = query.Where(p => p.Status == "Active" && (p.ExpiryDate == null || p.ExpiryDate > DateTime.Now.AddDays(-1)));

                var posts = await query.ToListAsync();
                
                // Set avatar mặc định cho user trong mỗi post
                foreach (var post in posts)
                {
                    SetDefaultAvatarIfNeeded(post.User);
                }
                
                return Ok(posts);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        /// <summary>
        /// Tính khoảng cách giữa 2 điểm trên Trái Đất bằng Haversine formula
        /// Trả về khoảng cách tính bằng km
        /// 
        /// Haversine formula:
        /// a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
        /// c = 2 ⋅ atan2( √a, √(1−a) )
        /// d = R ⋅ c
        /// 
        /// Trong đó:
        /// - φ là vĩ độ (latitude)
        /// - λ là kinh độ (longitude)
        /// - R là bán kính Trái Đất (≈ 6371 km)
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

        private double ToRadians(double degrees)
        {
            return degrees * (Math.PI / 180);
        }

        /// <summary>
        /// Format thời gian thành "time ago" string (ví dụ: "2 giờ trước", "3 ngày trước")
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

        /// <summary>
        /// Lấy bài viết của user
        /// - Nếu user xem bài viết của chính mình: trả về tất cả (đã duyệt, đợi duyệt, bị từ chối)
        /// - Nếu user xem bài viết của user khác: chỉ trả về các bài đã duyệt (Active)
        /// </summary>
        [HttpGet("user/{userId}")]
        [Authorize]
        public async Task<IActionResult> GetPostsByUser(int userId)
        {
            var currentUserId = GetUserId();
            if (!currentUserId.HasValue)
            {
                return Forbid("Bạn chỉ có thể xem bài viết của chính mình");
            }

            var isOwnPosts = currentUserId.Value == userId;

            var query = _context.Posts
                .Include(p => p.Images)
                .Include(p => p.Category)
                .Include(p => p.User)
                .Where(p => p.UserId == userId);

            // Nếu không phải bài viết của chính mình, chỉ hiển thị các bài đã duyệt (Active)
            if (!isOwnPosts)
            {
                var oneDayAgo = DateTime.Now.AddDays(-1);
                query = query.Where(p => p.Status == "Active" && (p.ExpiryDate == null || p.ExpiryDate > oneDayAgo));
            }

            var posts = await query
                .OrderByDescending(p => p.Created)
                .ToListAsync();
              
            // Set avatar mặc định cho user trong mỗi post
            foreach (var post in posts)
            {
                SetDefaultAvatarIfNeeded(post.User);
            }
              
            return Ok(posts);
        }

        
        
        // Lưu tin nháp vào session
        [Authorize]
        [HttpPost("draft/save")]
        public async Task<IActionResult> SaveDraft([FromBody] SaveDraftDto dto)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return Unauthorized("Không tìm thấy thông tin người dùng.");
                }

                var draftKey = $"post_draft_{userId}";
                var draftData = new DraftPostData
                {
                    UserId = userId.Value,
                    FormData = dto.FormData,
                    CurrentStep = dto.CurrentStep,
                    CreatedAt = DateTime.Now,
                    LastModified = DateTime.Now
                };

                var cacheEntryOptions = new MemoryCacheEntryOptions()
                    .SetSlidingExpiration(TimeSpan.FromDays(7)); // Tin nháp tồn tại 7 ngày

                _cache.Set(draftKey, draftData, cacheEntryOptions);

                _logger.LogInformation($"Đã lưu tin nháp cho user {userId}");

                return Ok(new { 
                    message = "Đã lưu tin nháp thành công",
                    draftId = draftKey,
                    lastModified = draftData.LastModified
                });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi khi lưu tin nháp: {ex.Message}");
                return StatusCode(500, "Lỗi khi lưu tin nháp");
            }
        }

        // Lấy tin nháp từ session
        [Authorize]
        [HttpGet("draft")]
        public async Task<IActionResult> GetDraft()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return Unauthorized("Không tìm thấy thông tin người dùng.");
                }

                var draftKey = $"post_draft_{userId}";
                if (_cache.TryGetValue(draftKey, out DraftPostData draftData))
                {
                    return Ok(new
                    {
                        hasDraft = true,
                        formData = draftData.FormData,
                        currentStep = draftData.CurrentStep,
                        createdAt = draftData.CreatedAt,
                        lastModified = draftData.LastModified
                    });
                }

                return Ok(new { hasDraft = false });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi khi lấy tin nháp: {ex.Message}");
                return StatusCode(500, "Lỗi khi lấy tin nháp");
            }
        }

        // Xóa tin nháp
        [Authorize]
        [HttpDelete("draft")]
        public async Task<IActionResult> DeleteDraft()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return Unauthorized("Không tìm thấy thông tin người dùng.");
                }

                var draftKey = $"post_draft_{userId}";
                _cache.Remove(draftKey);

                _logger.LogInformation($"Đã xóa tin nháp cho user {userId}");

                return Ok(new { message = "Đã xóa tin nháp thành công" });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi khi xóa tin nháp: {ex.Message}");
                return StatusCode(500, "Lỗi khi xóa tin nháp");
            }
        }

        // Cập nhật tin nháp
        [Authorize]
        [HttpPut("draft")]
        public async Task<IActionResult> UpdateDraft([FromBody] SaveDraftDto dto)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return Unauthorized("Không tìm thấy thông tin người dùng.");
                }

                var draftKey = $"post_draft_{userId}";
                if (_cache.TryGetValue(draftKey, out DraftPostData existingDraft))
                {
                    existingDraft.FormData = dto.FormData;
                    existingDraft.CurrentStep = dto.CurrentStep;
                    existingDraft.LastModified = DateTime.Now;

                    var cacheEntryOptions = new MemoryCacheEntryOptions()
                        .SetSlidingExpiration(TimeSpan.FromDays(7));

                    _cache.Set(draftKey, existingDraft, cacheEntryOptions);

                    _logger.LogInformation($"Đã cập nhật tin nháp cho user {userId}");

                    return Ok(new { 
                        message = "Đã cập nhật tin nháp thành công",
                        lastModified = existingDraft.LastModified
                    });
                }

                return NotFound("Không tìm thấy tin nháp để cập nhật");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi khi cập nhật tin nháp: {ex.Message}");
                return StatusCode(500, "Lỗi khi cập nhật tin nháp");
            }
        }
        



    }

    
}