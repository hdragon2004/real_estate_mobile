using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using RealEstateHubAPI.Services;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Models;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Model;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using RealEstateHubAPI.Extensions;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ChatController : ControllerBase
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
                    return BadRequest("Empty users");
                await _chatService.EnsureUsersExistAsync(request.UserIds);
                return Ok(new { Success = true });
            }
            catch (Exception ex)
            {
                return BadRequest($"Failed to ensure users: {ex.Message}");
            }
        }
        [HttpPost("token")]
        public async Task<IActionResult> GetUserToken([FromBody] ChatTokenRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(request.UserId);
                if (user == null)
                    return NotFound("User not found");

                var token = await _chatService.GenerateUserTokenAsync(
                    request.UserId,
                    request.UserName ?? user.Name,
                    request.UserImage ?? user.AvatarUrl
                );

                return Ok(new ChatTokenResponse
                {
                    Token = token,
                    ApiKey = _configuration["StreamChat:ApiKey"]
                             ?? Environment.GetEnvironmentVariable("STREAM_CHAT_API_KEY")
                             ?? string.Empty
                });
            }
            catch (Exception ex)
            {
                return BadRequest($"Failed to generate token: {ex.Message}");
            }
        }

        [HttpDelete("channels/{type}/{id}")]
        public async Task<IActionResult> DeleteChannel([FromRoute] string type, [FromRoute] string id, [FromQuery] bool hardDelete = true)
        {
            try
            {
                await _chatService.DeleteChannelAsync(type, id, hardDelete);
                return Ok(new { Success = true });
            }
            catch (Exception ex)
            {
                return BadRequest($"Failed to delete channel: {ex.Message}");
            }
        }

        /// <summary>
        /// GET /api/chat/channels/mobile
        /// Lấy danh sách channels cho mobile với pagination và metadata
        /// </summary>
        [HttpGet("channels/mobile")]
        [ProducesResponseType(typeof(MobileChannelsResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMobileChannels([FromQuery] int page = 1, [FromQuery] int limit = 20)
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (!int.TryParse(userIdClaim, out int userId))
                    return Unauthorized("User not authenticated");

                // Validate pagination parameters
                if (page < 1) page = 1;
                if (limit < 1) limit = 20;
                if (limit > 100) limit = 100; // Max limit

                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                    return NotFound("User not found");

                // Get user's Stream Chat token và API key
                var apiKey = _configuration["StreamChat:ApiKey"]
                             ?? Environment.GetEnvironmentVariable("STREAM_CHAT_API_KEY")
                             ?? string.Empty;
                var apiSecret = _configuration["StreamChat:ApiSecret"]
                                ?? Environment.GetEnvironmentVariable("STREAM_CHAT_API_SECRET");
                
                if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(apiSecret))
                    return StatusCode(500, "Stream Chat not configured");

                // Generate server token để query channels
                var serverToken = GenerateServerToken(apiSecret);

                using var http = new HttpClient { BaseAddress = new Uri("https://chat.stream-io-api.com/") };
                http.DefaultRequestHeaders.Remove("Authorization");
                http.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", serverToken);
                http.DefaultRequestHeaders.Remove("stream-auth-type");
                http.DefaultRequestHeaders.TryAddWithoutValidation("stream-auth-type", "jwt");

                // Query channels với pagination
                var offset = (page - 1) * limit;
                var queryParams = $"?api_key={apiKey}&user_id={userId}&limit={limit}&offset={offset}";
                
                var resp = await http.GetAsync($"channels/messaging{queryParams}");
                if (!resp.IsSuccessStatusCode)
                {
                    var errorText = await resp.Content.ReadAsStringAsync();
                    return StatusCode((int)resp.StatusCode, $"Failed to query channels: {errorText}");
                }

                var content = await resp.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(content);
                var channels = doc.RootElement.GetProperty("channels");

                var channelList = new List<MobileChannelDto>();
                foreach (var channel in channels.EnumerateArray())
                {
                    var channelData = channel.GetProperty("channel");

                    JsonElement lastMessage = default;
                    var hasLastMessage = channel.TryGetProperty("messages", out var messages) &&
                                         messages.GetArrayLength() > 0;
                    if (hasLastMessage)
                    {
                        lastMessage = messages[0];
                    }

                    var members = channel.TryGetProperty("members", out var membersArray) ? 
                                   membersArray.EnumerateArray().ToList() : new List<JsonElement>();

                    // Tìm partner info
                    var partner = members.FirstOrDefault(m =>
                        m.GetProperty("user_id").GetString() != userId.ToString());
                    string? partnerName = null;
                    string? partnerAvatar = null;
                    if (partner.ValueKind != JsonValueKind.Undefined && partner.TryGetProperty("user", out var partnerUser))
                    {
                        partnerName = partnerUser.GetStringOrNull("name");
                        partnerAvatar = partnerUser.GetStringOrNull("image");
                    }

                    var channelDto = new MobileChannelDto
                    {
                        Id = channelData.GetProperty("id").GetString(),
                        Type = channelData.GetProperty("type").GetString(),
                        Name = channelData.GetStringOrNull("name"),
                        Image = channelData.GetStringOrNull("image"),
                        LastMessage = hasLastMessage ? new MessageSummaryDto
                        {
                            Text = lastMessage.GetStringOrNull("text"),
                            UserId = lastMessage.TryGetProperty("user", out var userMsg) ? 
                                    userMsg.GetStringOrNull("id") : null,
                            CreatedAt = lastMessage.GetDateTime("created_at")
                        } : null,
                        UnreadCount = channel.GetInt32OrDefault("unread_count"),
                        MemberCount = members.Count,
                        PartnerName = partnerName,
                        PartnerAvatar = partnerAvatar,
                        UpdatedAt = channelData.GetDateTime("updated_at"),
                        CreatedAt = channelData.GetDateTime("created_at")
                    };

                    channelList.Add(channelDto);
                }

                var response = new MobileChannelsResponse
                {
                    Channels = channelList,
                    Page = page,
                    Limit = limit,
                    Total = channelList.Count, // Stream không trả về total, dùng count
                    HasMore = channelList.Count == limit // Giả định có thêm nếu đầy đủ limit
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "Internal server error", message = ex.Message });
            }
        }

        /// <summary>
        /// GET /api/chat/unread-count
        /// Lấy tổng số tin nhắn chưa đọc của user
        /// </summary>
        [HttpGet("unread-count")]
        [ProducesResponseType(typeof(UnreadCountResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetUnreadCount()
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (!int.TryParse(userIdClaim, out int userId))
                    return Unauthorized("User not authenticated");

                var apiKey = _configuration["StreamChat:ApiKey"]
                             ?? Environment.GetEnvironmentVariable("STREAM_CHAT_API_KEY")
                             ?? string.Empty;
                var apiSecret = _configuration["StreamChat:ApiSecret"]
                                ?? Environment.GetEnvironmentVariable("STREAM_CHAT_API_SECRET");
                
                if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(apiSecret))
                    return StatusCode(500, "Stream Chat not configured");

                // Generate server token
                var serverToken = GenerateServerToken(apiSecret);

                using var http = new HttpClient { BaseAddress = new Uri("https://chat.stream-io-api.com/") };
                http.DefaultRequestHeaders.Remove("Authorization");
                http.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", serverToken);
                http.DefaultRequestHeaders.Remove("stream-auth-type");
                http.DefaultRequestHeaders.TryAddWithoutValidation("stream-auth-type", "jwt");

                // Get unread count cho user
                var resp = await http.GetAsync($"users/{userId}/unread_count?api_key={apiKey}");
                if (!resp.IsSuccessStatusCode)
                {
                    var errorText = await resp.Content.ReadAsStringAsync();
                    return StatusCode((int)resp.StatusCode, $"Failed to get unread count: {errorText}");
                }

                var content = await resp.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(content);
                var unreadCount = doc.RootElement.GetProperty("unread_count").GetInt32();

                return Ok(new UnreadCountResponse { UnreadCount = unreadCount });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "Internal server error", message = ex.Message });
            }
        }

        /// <summary>
        /// Utility method để generate server token cho Stream Chat admin operations
        /// </summary>
        private string GenerateServerToken(string apiSecret)
        {
            var securityKey = new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(apiSecret));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
            var serverToken = new JwtSecurityToken(signingCredentials: credentials);
            return new JwtSecurityTokenHandler().WriteToken(serverToken);
        }
    }

    /// <summary>
    /// Response cho mobile channels query
    /// </summary>
    public class MobileChannelsResponse
    {
        public List<MobileChannelDto> Channels { get; set; } = new();
        public int Page { get; set; }
        public int Limit { get; set; }
        public int Total { get; set; }
        public bool HasMore { get; set; }
    }

    /// <summary>
    /// Mobile channel data transfer object
    /// </summary>
    public class MobileChannelDto
    {
        public string Id { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string? Name { get; set; }
        public string? Image { get; set; }
        public MessageSummaryDto? LastMessage { get; set; }
        public int UnreadCount { get; set; }
        public int MemberCount { get; set; }
        public string? PartnerName { get; set; }
        public string? PartnerAvatar { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    /// <summary>
    /// Message summary cho mobile
    /// </summary>
    public class MessageSummaryDto
    {
        public string? Text { get; set; }
        public string? UserId { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    /// <summary>
    /// Unread count response
    /// </summary>
    public class UnreadCountResponse
    {
        public int UnreadCount { get; set; }
    }
}
