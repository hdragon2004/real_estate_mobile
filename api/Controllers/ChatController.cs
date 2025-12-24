using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using RealEstateHubAPI.Services;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Models;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ChatController : BaseController
    {
        private readonly IChatService _chatService;
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public ChatController(IChatService chatService, ApplicationDbContext context, IConfiguration configuration)
        {
            _chatService = chatService;
            _context = context;
            _configuration = configuration;
        }

        [HttpPost("ensure-users")]
        public async Task<IActionResult> EnsureUsers([FromBody] EnsureUsersRequest request)
        {
            try
            {
                if (request?.UserIds == null || request.UserIds.Count == 0)
                    return BadRequestResponse("Empty users");
                await _chatService.EnsureUsersExistAsync(request.UserIds);
                return Success(new { Success = true }, "Đảm bảo users tồn tại thành công");
            }
            catch (Exception ex)
            {
                return BadRequestResponse($"Failed to ensure users: {ex.Message}");
            }
        }
        [HttpPost("token")]
        public async Task<IActionResult> GetUserToken([FromBody] ChatTokenRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(request.UserId);
                if (user == null)
                    return NotFoundResponse("User not found");

                var token = await _chatService.GenerateUserTokenAsync(
                    request.UserId,
                    request.UserName ?? user.Name,
                    request.UserImage ?? user.AvatarUrl
                );

                return Success(new ChatTokenResponse
                {
                    Token = token,
                    ApiKey = _configuration["StreamChat:ApiKey"] ?? string.Empty
                }, "Tạo token thành công");
            }
            catch (Exception ex)
            {
                return BadRequestResponse($"Failed to generate token: {ex.Message}");
            }
        }

        [HttpDelete("channels/{type}/{id}")]
        public async Task<IActionResult> DeleteChannel([FromRoute] string type, [FromRoute] string id, [FromQuery] bool hardDelete = true)
        {
            try
            {
                await _chatService.DeleteChannelAsync(type, id, hardDelete);
                return Success<object>(null, "Xóa channel thành công");
            }
            catch (Exception ex)
            {
                return BadRequestResponse($"Failed to delete channel: {ex.Message}");
            }
        }

        
    }
}
