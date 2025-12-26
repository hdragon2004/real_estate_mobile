using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using RealEstateHubAPI.Utils;
using System.Security.Claims;

namespace RealEstateHubAPI.Hubs
{
    /// <summary>
    /// SignalR Hub cho chat 1-1 giữa users (messages)
    /// Hỗ trợ JWT authentication để xác định user đang kết nối
    /// </summary>
    [Authorize] // Yêu cầu authentication (JWT token)
    public class MessageHub : Hub
    {
        private readonly ILogger<MessageHub> _logger;

        public MessageHub(ILogger<MessageHub> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Lấy UserId từ JWT claims trong Context.User
        /// </summary>
        private string? GetUserId()
        {
            return Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        }

        /// <summary>
        /// Khi client kết nối, thêm user vào group theo UserId để có thể nhận tin nhắn
        /// </summary>
        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            if (!string.IsNullOrEmpty(userId))
            {
                // Thêm user vào group riêng của họ để có thể nhận tin nhắn
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation($"User {userId} connected to MessageHub with connection {Context.ConnectionId}");
            }
            else
            {
                _logger.LogWarning($"User connected to MessageHub but UserId not found in claims");
            }

            await base.OnConnectedAsync();
        }

        /// <summary>
        /// Khi client ngắt kết nối, xóa user khỏi group
        /// </summary>
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = GetUserId();
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation($"User {userId} disconnected from MessageHub");
            }

            if (exception != null)
            {
                _logger.LogError(exception, $"User {userId} disconnected with error");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Gửi tin nhắn đến một user cụ thể
        /// Client gọi: connection.invoke("SendMessageToUser", toUserId, message)
        /// </summary>
        /// <param name="toUserId">UserId của người nhận</param>
        /// <param name="message">Nội dung tin nhắn</param>
        /// <param name="postId">ID của bài đăng liên quan (optional)</param>
        public async Task SendMessageToUser(string toUserId, string message, int? postId = null)
        {
            var fromUserId = GetUserId();
            if (string.IsNullOrEmpty(fromUserId))
            {
                await Clients.Caller.SendAsync("Error", "User not authenticated");
                return;
            }

            if (string.IsNullOrEmpty(toUserId))
            {
                await Clients.Caller.SendAsync("Error", "Receiver ID is required");
                return;
            }

            if (string.IsNullOrWhiteSpace(message))
            {
                await Clients.Caller.SendAsync("Error", "Message content is required");
                return;
            }

            try
            {
                // Gửi tin nhắn đến group của người nhận
                // Client sẽ nhận qua event "ReceiveMessage"
                await Clients.Group($"user_{toUserId}").SendAsync("ReceiveMessage", new
                {
                    FromUserId = fromUserId,
                    ToUserId = toUserId,
                    Message = message,
                    PostId = postId,
                    SentTime = DateTimeHelper.GetVietnamNow()
                });

                // Xác nhận cho người gửi rằng tin nhắn đã được gửi
                await Clients.Caller.SendAsync("MessageSent", new
                {
                    ToUserId = toUserId,
                    Message = message,
                    SentTime = DateTimeHelper.GetVietnamNow()
                });

                _logger.LogInformation($"Message sent from {fromUserId} to {toUserId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending message from {fromUserId} to {toUserId}");
                await Clients.Caller.SendAsync("Error", "Failed to send message");
            }
        }

        /// <summary>
        /// Đánh dấu tin nhắn đã đọc (optional - có thể dùng để hiển thị "đã đọc")
        /// </summary>
        public async Task MarkMessageAsRead(int messageId)
        {
            var userId = GetUserId();
            if (string.IsNullOrEmpty(userId))
            {
                await Clients.Caller.SendAsync("Error", "User not authenticated");
                return;
            }

            // Có thể thêm logic để update database ở đây
            _logger.LogInformation($"User {userId} marked message {messageId} as read");
            await Clients.Caller.SendAsync("MessageRead", messageId);
        }
    }
}

