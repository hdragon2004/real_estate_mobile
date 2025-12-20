using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using Microsoft.AspNetCore.SignalR;
using RealEstateHubAPI.Hubs;
using System.Security.Claims;


namespace RealEstateHubAPI.Controllers
{
    [Route("api/notifications")]
    [ApiController]
    [Authorize] // Yêu cầu authentication
    public class NotificationController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        public NotificationController(ApplicationDbContext context, IHubContext<NotificationHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }
        /// <summary>
        /// GET /api/notifications
        /// Lấy tất cả notifications của user hiện tại
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<Notification>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetNotifications()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("User not authenticated");
            }

            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();
            
            return Ok(notifications);
        }
        [HttpPost]
        public async Task<IActionResult> CreateNotification([FromBody] Notification notification)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetNotifications), new { userId = notification.UserId }, notification);
        }
        /// <summary>
        /// PUT /api/notifications/{id}/mark-read
        /// Đánh dấu notification đã đọc
        /// </summary>
        [HttpPut("{id}/mark-read")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("User not authenticated");
            }

            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) 
            {
                return NotFound("Notification not found");
            }

            // Kiểm tra user chỉ có thể đánh dấu notification của chính mình
            if (notification.UserId != userId)
            {
                return Forbid("Cannot mark other user's notification as read");
            }

            notification.IsRead = true;
            await _context.SaveChangesAsync();
            
            // Gửi SignalR event để client cập nhật UI
            await _hubContext.Clients.Group($"user_{userId}").SendAsync("NotificationRead", id);
            
            return Ok(new { message = "Notification marked as read" });
        }
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNotification(int id)
        {
            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) return NotFound();
            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();
            return Ok();
        }
        
    }
}
