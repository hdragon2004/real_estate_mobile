using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Services;
using System.Security.Claims;

namespace RealEstateHubAPI.Controllers
{
    /// <summary>
    /// Controller cho SavedSearch (Khu vực tìm kiếm yêu thích)
    /// </summary>
    [ApiController]
    [Route("api/saved-searches")]
    [Authorize] // Tất cả endpoints đều yêu cầu đăng nhập
    public class SavedSearchController : BaseController
    {
        private readonly ISavedSearchService _savedSearchService;
        private readonly ILogger<SavedSearchController> _logger;

        public SavedSearchController(
            ISavedSearchService savedSearchService,
            ILogger<SavedSearchController> logger)
        {
            _savedSearchService = savedSearchService;
            _logger = logger;
        }

        /// <summary>
        /// Lấy UserId từ JWT claims
        /// </summary>
        private int? GetUserId()
        {
            var userId = User
                .Claims
                .Where(c => c.Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier")
                .Select(c => c.Value)
                .FirstOrDefault();
            
            if (int.TryParse(userId, out int id))
            {
                return id;
            }
            return null;
        }

        /// <summary>
        /// POST /api/saved-searches
        /// Tạo SavedSearch mới
        /// </summary>
        [HttpPost]
        [ProducesResponseType(typeof(SavedSearchDto), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> CreateSavedSearch([FromBody] CreateSavedSearchDto dto)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                // Validate MinPrice <= MaxPrice
                if (dto.MinPrice.HasValue && dto.MaxPrice.HasValue && dto.MinPrice.Value > dto.MaxPrice.Value)
                {
                    return BadRequestResponse("MinPrice must be less than or equal to MaxPrice");
                }

                var savedSearch = await _savedSearchService.CreateSavedSearchAsync(userId.Value, dto);
                return Created(savedSearch, "Tạo tìm kiếm đã lưu thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating saved search");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        /// <summary>
        /// GET /api/saved-searches/me
        /// Lấy tất cả SavedSearch của user hiện tại
        /// </summary>
        [HttpGet("me")]
        [ProducesResponseType(typeof(IEnumerable<SavedSearchDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetUserSavedSearches()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var savedSearches = await _savedSearchService.GetUserSavedSearchesAsync(userId.Value);
                return Success(savedSearches, "Lấy danh sách tìm kiếm đã lưu thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user saved searches");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        /// <summary>
        /// DELETE /api/saved-searches/{id}
        /// Xóa SavedSearch (chỉ user sở hữu mới xóa được)
        /// </summary>
        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> DeleteSavedSearch(int id)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var deleted = await _savedSearchService.DeleteSavedSearchAsync(id, userId.Value);
                if (!deleted)
                {
                    return NotFoundResponse("SavedSearch not found or access denied");
                }

                return Success<object>(null, "Xóa tìm kiếm đã lưu thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting saved search");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        /// <summary>
        /// GET /api/saved-searches/{id}/posts
        /// Lấy danh sách posts phù hợp với SavedSearch
        /// </summary>
        [HttpGet("{id}/posts")]
        [ProducesResponseType(typeof(IEnumerable<PostDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetMatchingPosts(int id)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var posts = await _savedSearchService.FindMatchingPostsAsync(id, userId.Value);
                return Success(posts, "Lấy danh sách bài đăng phù hợp thành công");
            }
            catch (KeyNotFoundException ex)
            {
                return NotFoundResponse(ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting matching posts");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }
    }
}

