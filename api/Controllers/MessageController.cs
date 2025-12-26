using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Hubs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using RealEstateHubAPI.Utils;
using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Hosting;

namespace RealEstateHubAPI.Controllers
{
    /// <summary>
    /// Controller cho chat messages
    /// Hỗ trợ chat 1-1 với chủ bài đăng, lưu lịch sử chat, và gửi real-time qua SignalR
    /// </summary>
    [ApiController]
    [Route("api/messages")]
    [Authorize] // Yêu cầu authentication
    public class MessageController : BaseController
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<MessageHub> _messageHub;
        private readonly IHubContext<NotificationHub> _notificationHub;
        private readonly ILogger<MessageController> _logger;
        private readonly IWebHostEnvironment _env;

        public MessageController(
            ApplicationDbContext context,
            IHubContext<MessageHub> messageHub,
            IHubContext<NotificationHub> notificationHub,
            ILogger<MessageController> logger,
            IWebHostEnvironment env)
        {
            _context = context;
            _messageHub = messageHub;
            _notificationHub = notificationHub;
            _logger = logger;
            _env = env;
        }

        /// <summary>
        /// Lấy UserId từ JWT claims
        /// </summary>
        private int? GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out int userId))
            {
                return userId;
            }
            return null;
        }

        private string GenerateConversationId(int user1Id, int user2Id)
        {
            var minId = Math.Min(user1Id, user2Id);
            var maxId = Math.Max(user1Id, user2Id);
            return $"{minId}_{maxId}";
        }

        /// <summary>
        /// POST /api/messages
        /// Gửi tin nhắn đến một user (thường là chủ bài đăng)
        /// </summary>
        [HttpPost]
        [ProducesResponseType(typeof(MessageDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> SendMessage([FromBody] CreateMessageDto dto)
        {
            try
            {
                var senderId = GetUserId();
                if (!senderId.HasValue)
                {
                    return UnauthorizedResponse("User not authenticated");
                }

                if (!ModelState.IsValid)
                {
                    return BadRequestResponse("Dữ liệu không hợp lệ");
                }

                // Validate: không được gửi tin nhắn cho chính mình
                if (dto.ReceiverId == senderId.Value)
                {
                    return BadRequestResponse("Cannot send message to yourself");
                }

                // Kiểm tra receiver tồn tại
                var receiver = await _context.Users.FindAsync(dto.ReceiverId);
                if (receiver == null)
                {
                    return BadRequestResponse($"Receiver with ID {dto.ReceiverId} not found");
                }

                // Kiểm tra post tồn tại (nếu có)
                Post? post = null;
                if (dto.PostId.HasValue)
                {
                    post = await _context.Posts
                        .Include(p => p.User)
                        .FirstOrDefaultAsync(p => p.Id == dto.PostId.Value);
                    if (post == null)
                    {
                        return BadRequestResponse($"Post with ID {dto.PostId} not found");
                    }
                }

                // Validate: Phải có Content hoặc ImageUrl (ít nhất một trong hai)
                if (string.IsNullOrWhiteSpace(dto.Content) && string.IsNullOrWhiteSpace(dto.ImageUrl))
                {
                    return BadRequestResponse("Message content or image is required");
                }

                // Tạo ConversationId để định danh cho đoạn chat (chỉ dùng SenderId và ReceiverId)
                var conversationId = GenerateConversationId(senderId.Value, dto.ReceiverId);

                // Lưu tin nhắn vào database
                // Sử dụng DateTimeHelper để đảm bảo timezone đúng (Vietnam GMT+7)
                var message = new Message
                {
                    SenderId = senderId.Value,
                    ReceiverId = dto.ReceiverId,
                    PostId = dto.PostId ?? 0, // Nếu không có PostId, dùng 0
                    ConversationId = conversationId,
                    Content = !string.IsNullOrWhiteSpace(dto.Content) 
                        ? dto.Content 
                        : (dto.ImageUrl != null ? "[Hình ảnh]" : ""),
                    ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl,
                    SentTime = DateTimeHelper.GetVietnamNow()
                };

                _context.Messages.Add(message);
                await _context.SaveChangesAsync();

                // Load sender để lấy thông tin
                var sender = await _context.Users.FindAsync(senderId.Value);

                // Tạo MessageDto để gửi qua SignalR
                var messageDto = new MessageDto
                {
                    Id = message.Id,
                    SenderId = sender!.Id,
                    SenderName = sender.Name ?? "Unknown",
                    SenderAvatarUrl = sender.AvatarUrl ?? "/uploads/avatars/avatar.jpg",
                    ReceiverId = receiver.Id,
                    ReceiverName = receiver.Name ?? "Unknown",
                    ReceiverAvatarUrl = receiver.AvatarUrl ?? "/uploads/avatars/avatar.jpg",
                    PostId = dto.PostId,
                    PostTitle = post?.Title,
                    PostUserName = post?.User?.Name,
                    ConversationId = conversationId,
                    Content = message.Content,
                    ImageUrl = message.ImageUrl,
                    SentTime = message.SentTime
                };

                // Gửi tin nhắn real-time qua SignalR đến người nhận
                await _messageHub.Clients.Group($"user_{dto.ReceiverId}").SendAsync("ReceiveMessage", messageDto);

                // Tạo notification cho người nhận
                var notification = new Notification
                {
                    UserId = receiver.Id,
                    PostId = dto.PostId,
                    MessageId = message.Id, // FK đến Message
                    AppointmentId = null,
                    SavedSearchId = null,
                    Title = "Tin nhắn mới",
                    Message = post != null 
                        ? $"{sender.Name} đã gửi tin nhắn về bài đăng '{post.Title}'"
                        : $"{sender.Name} đã gửi tin nhắn cho bạn",
                    Type = "Message",
                    IsRead = false,
                    CreatedAt = DateTimeHelper.GetVietnamNow() // Sử dụng DateTimeHelper để đảm bảo timezone đúng
                };

                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();

                // Gửi notification real-time qua SignalR
                await _notificationHub.Clients.Group($"user_{receiver.Id}").SendAsync("ReceiveNotification", new
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

                _logger.LogInformation($"Message {message.Id} sent from {senderId.Value} to {dto.ReceiverId}");

                return Success(messageDto, "Gửi tin nhắn thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        /// <summary>
        /// GET /api/messages/conversations
        /// Lấy danh sách các cuộc hội thoại của user hiện tại
        /// </summary>
        [HttpGet("conversations")]
        [ProducesResponseType(typeof(IEnumerable<ConversationDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetConversations()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User not authenticated");
                }

                var conversations = await _context.Messages
                    .Include(m => m.Sender)
                    .Include(m => m.Receiver)
                    .Include(m => m.Post)
                        .ThenInclude(p => p.User)
                    .Where(m => m.SenderId == userId.Value || m.ReceiverId == userId.Value)
                    .GroupBy(m => m.ConversationId)
                    .Select(g => new ConversationDto
                    {
                        PostId = null, // Không còn group theo PostId nữa
                        OtherUserId = g.First().SenderId == userId.Value 
                            ? g.First().ReceiverId 
                            : g.First().SenderId,
                        PostTitle = null, // Có thể có nhiều post trong 1 conversation
                        PostUserName = null,
                        OtherUserName = g.First().SenderId == userId.Value 
                            ? g.First().Receiver.Name 
                            : g.First().Sender.Name,
                        OtherUserAvatarUrl = g.First().SenderId == userId.Value 
                            ? (g.First().Receiver.AvatarUrl ?? "/uploads/avatars/avatar.jpg")
                            : (g.First().Sender.AvatarUrl ?? "/uploads/avatars/avatar.jpg"),
                        LastMessage = new MessageDto
                        {
                            Id = g.OrderByDescending(m => m.SentTime).First().Id,
                            SenderId = g.OrderByDescending(m => m.SentTime).First().SenderId,
                            SenderName = g.OrderByDescending(m => m.SentTime).First().Sender.Name,
                            ReceiverId = g.OrderByDescending(m => m.SentTime).First().ReceiverId,
                            ReceiverName = g.OrderByDescending(m => m.SentTime).First().Receiver.Name,
                            PostId = g.OrderByDescending(m => m.SentTime).First().PostId,
                            PostTitle = g.OrderByDescending(m => m.SentTime).First().Post != null 
                                ? g.OrderByDescending(m => m.SentTime).First().Post.Title 
                                : null,
                            ConversationId = g.Key,
                            Content = g.OrderByDescending(m => m.SentTime).First().Content,
                            ImageUrl = g.OrderByDescending(m => m.SentTime).First().ImageUrl,
                            SentTime = g.OrderByDescending(m => m.SentTime).First().SentTime
                        },
                        MessageCount = g.Count()
                    })
                    .OrderByDescending(c => c.LastMessage.SentTime)
                    .ToListAsync();

                return Success(conversations, "Lấy danh sách cuộc hội thoại thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting conversations");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        /// <summary>
        /// GET /api/messages/conversation/{otherUserId}
        /// Lấy lịch sử chat với một user cụ thể (theo ConversationId, có thể chứa nhiều PostId)
        /// </summary>
        [HttpGet("conversation/{otherUserId}")]
        [ProducesResponseType(typeof(IEnumerable<MessageDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetConversation(int otherUserId)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User not authenticated");
                }

                // Tạo ConversationId từ 2 userId
                var conversationId = GenerateConversationId(userId.Value, otherUserId);

                var messages = await _context.Messages
                    .Include(m => m.Sender)
                    .Include(m => m.Receiver)
                    .Include(m => m.Post)
                        .ThenInclude(p => p.User)
                    .Where(m => m.ConversationId == conversationId)
                    .OrderBy(m => m.SentTime)
                    .Select(m => new MessageDto
                    {
                        Id = m.Id,
                        SenderId = m.SenderId,
                        SenderName = m.Sender.Name ?? "Unknown",
                        SenderAvatarUrl = m.Sender.AvatarUrl ?? "/uploads/avatars/avatar.jpg",
                        ReceiverId = m.ReceiverId,
                        ReceiverName = m.Receiver.Name ?? "Unknown",
                        ReceiverAvatarUrl = m.Receiver.AvatarUrl ?? "/uploads/avatars/avatar.jpg",
                        PostId = m.PostId,
                        PostTitle = m.Post != null ? m.Post.Title : null,
                        PostUserName = m.Post != null && m.Post.User != null ? m.Post.User.Name : null,
                    ConversationId = m.ConversationId,
                    Content = m.Content,
                    ImageUrl = m.ImageUrl,
                    SentTime = m.SentTime
                })
                .ToListAsync();

                return Success(messages, "Lấy lịch sử chat thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting conversation");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        [HttpPost("upload-image")]
        [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> UploadMessageImage([FromForm] IFormFile image)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User not authenticated");
                }

                // Validate file
                if (image == null || image.Length == 0)
                {
                    return BadRequestResponse("Không có file được tải lên");
                }

                // Validate file type (chỉ cho phép image)
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
                var fileExtension = Path.GetExtension(image.FileName).ToLowerInvariant();
                if (!allowedExtensions.Contains(fileExtension))
                {
                    return BadRequestResponse("Chỉ cho phép file hình ảnh (jpg, jpeg, png, gif, webp)");
                }

                // Validate file size (max 5MB)
                const long maxFileSize = 5 * 1024 * 1024; // 5MB
                if (image.Length > maxFileSize)
                {
                    return BadRequestResponse("Kích thước file không được vượt quá 5MB");
                }

                // Tạo thư mục lưu ảnh message nếu chưa có
                var uploadsFolder = Path.Combine(_env.WebRootPath, "uploads", "messages");
                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                // Tạo tên file mới tránh trùng
                var fileName = $"{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                // Lưu file lên server
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(stream);
                }

                // Trả về URL của ảnh
                var imageUrl = $"/uploads/messages/{fileName}";
                _logger.LogInformation($"Message image uploaded: {imageUrl} by user {userId.Value}");

                return Success(imageUrl, "Upload hình ảnh thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading message image");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }
    }
}
