using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace RealEstateHubAPI.Hubs
{
    /// <summary>
    /// SignalR Hub cho real-time notifications
    /// Hỗ trợ JWT authentication để xác định user đang kết nối
    /// </summary>
    [Authorize] // Yêu cầu authentication (JWT token)
    public class NotificationHub : Hub
    {
        private readonly ILogger<NotificationHub> _logger;

        public NotificationHub(ILogger<NotificationHub> logger)
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
        /// Khi client kết nối, thêm user vào group theo UserId để có thể nhận notifications
        /// </summary>
        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            if (!string.IsNullOrEmpty(userId))
            {
                // Thêm user vào group riêng của họ để có thể nhận notifications
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation($"User {userId} connected to NotificationHub with connection {Context.ConnectionId}");
            }
            else
            {
                _logger.LogWarning($"User connected to NotificationHub but UserId not found in claims");
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
                _logger.LogInformation($"User {userId} disconnected from NotificationHub");
            }

            if (exception != null)
            {
                _logger.LogError(exception, $"User {userId} disconnected with error");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Đánh dấu notification đã đọc
        /// Client gọi: connection.invoke("MarkNotificationAsRead", notificationId)
        /// </summary>
        public async Task MarkNotificationAsRead(int notificationId)
        {
            var userId = GetUserId();
            if (string.IsNullOrEmpty(userId))
            {
                await Clients.Caller.SendAsync("Error", "User not authenticated");
                return;
            }

            _logger.LogInformation($"User {userId} marked notification {notificationId} as read");
            await Clients.Caller.SendAsync("NotificationRead", notificationId);
        }
    }
}

