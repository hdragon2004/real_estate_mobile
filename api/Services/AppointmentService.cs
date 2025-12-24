using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Hubs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Services
{
    public class AppointmentService : IAppointmentService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AppointmentService> _logger;
        private readonly IHubContext<NotificationHub>? _notificationHub;

        public AppointmentService(
            ApplicationDbContext context,
            ILogger<AppointmentService> logger,
            IHubContext<NotificationHub>? notificationHub = null)
        {
            _context = context;
            _logger = logger;
            _notificationHub = notificationHub;
        }

        public async Task<AppointmentDto> CreateAppointmentAsync(int userId, CreateAppointmentDto dto)
        {
            // Validate: AppointmentTime phải trong tương lai
            // Frontend gửi local time, cần so sánh với local time hiện tại
            var now = DateTime.Now; // Local time để so sánh với local time từ frontend
            if (dto.AppointmentTime <= now)
            {
                throw new ArgumentException("AppointmentTime must be in the future");
            }

            // Validate: PostId phải tồn tại
            var postExists = await _context.Posts.AnyAsync(p => p.Id == dto.PostId);
            if (!postExists)
            {
                throw new ArgumentException($"Post with Id {dto.PostId} does not exist");
            }

            // Lấy thông tin post để lấy UserId của chủ bài post
            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == dto.PostId);

            if (post == null)
            {
                throw new ArgumentException($"Post with Id {dto.PostId} does not exist");
            }

            var appointment = new Appointment
            {
                UserId = userId,
                PostId = dto.PostId,
                Title = dto.Title,
                Description = dto.Description,
                AppointmentTime = dto.AppointmentTime,
                ReminderMinutes = dto.ReminderMinutes,
                IsNotified = false,
                Status = AppointmentStatus.PENDING, // Mặc định là PENDING khi tạo mới
                CreatedAt = DateTime.UtcNow
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Created Appointment {appointment.Id} for User {userId}, AppointmentTime: {appointment.AppointmentTime}");

            // Gửi thông báo cho chủ bài post (post.UserId) để chấp nhận lịch hẹn
            var postOwnerId = post.UserId;
            var notification = new Notification
            {
                UserId = postOwnerId, // Gửi cho chủ bài post
                PostId = dto.PostId,
                AppointmentId = appointment.Id,
                SavedSearchId = null,
                MessageId = null,
                SenderId = userId, // User tạo appointment (để có thể nhắn tin)
                Title = "Yêu cầu lịch hẹn mới",
                Message = $"Bạn có yêu cầu lịch hẹn '{dto.Title}' vào lúc {dto.AppointmentTime:dd/MM/yyyy HH:mm}. Vui lòng chấp nhận hoặc từ chối.",
                Type = "AppointmentRequest",
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Gửi notification real-time qua SignalR
            if (_notificationHub != null)
            {
                await _notificationHub.Clients.Group($"user_{postOwnerId}").SendAsync("ReceiveNotification", new
                {
                    Id = notification.Id,
                    UserId = notification.UserId,
                    PostId = notification.PostId,
                    SavedSearchId = notification.SavedSearchId,
                    AppointmentId = notification.AppointmentId,
                    MessageId = notification.MessageId,
                    SenderId = notification.SenderId, // User tạo appointment
                    Title = notification.Title,
                    Message = notification.Message,
                    Type = notification.Type,
                    CreatedAt = notification.CreatedAt,
                    IsRead = notification.IsRead
                });
            }

            return MapToDto(appointment);
        }

        public async Task<IEnumerable<AppointmentDto>> GetUserAppointmentsAsync(int userId)
        {
            // Trả về TẤT CẢ appointments của user, bao gồm cả những cái bị hủy/từ chối
            // để có thể hiển thị trong tab "Bị từ chối"
            var appointments = await _context.Appointments
                .Where(a => a.UserId == userId)
                .OrderBy(a => a.AppointmentTime)
                .ToListAsync();

            return appointments.Select(MapToDto);
        }

        public async Task<IEnumerable<AppointmentDto>> GetPendingAppointmentsForPostOwnerAsync(int postOwnerId)
        {
            // Lấy các appointments chưa được chấp nhận (PENDING) cho các bài post của user này
            var appointments = await _context.Appointments
                .Include(a => a.Post)
                .Where(a => a.Post != null && 
                           a.Post.UserId == postOwnerId && 
                           a.Status == AppointmentStatus.PENDING)
                .OrderBy(a => a.CreatedAt)
                .ToListAsync();

            return appointments.Select(MapToDto);
        }

        public async Task<IEnumerable<AppointmentDto>> GetAllAppointmentsForPostOwnerAsync(int postOwnerId)
        {
            // Lấy TẤT CẢ appointments (PENDING, ACCEPTED, REJECTED) cho các bài post của user này
            var appointments = await _context.Appointments
                .Include(a => a.Post)
                .Where(a => a.Post != null && 
                           a.Post.UserId == postOwnerId)
                .OrderBy(a => a.AppointmentTime)
                .ToListAsync();

            return appointments.Select(MapToDto);
        }

        public async Task<bool> CancelAppointmentAsync(int appointmentId, int userId)
        {
            var appointment = await _context.Appointments
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.UserId == userId);

            if (appointment == null)
            {
                return false;
            }

            appointment.Status = AppointmentStatus.REJECTED;
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Canceled Appointment {appointmentId} for User {userId}");

            return true;
        }

        public async Task<bool> ConfirmAppointmentAsync(int appointmentId, int postOwnerId)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Post)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && 
                                         a.Post != null && 
                                         a.Post.UserId == postOwnerId &&
                                         a.Status == AppointmentStatus.PENDING);

            if (appointment == null)
            {
                return false;
            }

            appointment.Status = AppointmentStatus.ACCEPTED;
            await _context.SaveChangesAsync();

            // Gửi thông báo cho user đã tạo appointment (appointment.UserId) rằng lịch hẹn đã được chấp nhận
            var notification = new Notification
            {
                UserId = appointment.UserId,
                PostId = appointment.PostId,
                AppointmentId = appointment.Id,
                SavedSearchId = null,
                MessageId = null,
                Title = "Lịch hẹn đã được chấp nhận",
                Message = $"Lịch hẹn '{appointment.Title}' vào lúc {appointment.AppointmentTime:dd/MM/yyyy HH:mm} đã được chấp nhận.",
                Type = "AppointmentConfirmed",
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Gửi notification real-time qua SignalR
            if (_notificationHub != null)
            {
                await _notificationHub.Clients.Group($"user_{appointment.UserId}").SendAsync("ReceiveNotification", new
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
            }

            _logger.LogInformation($"Confirmed Appointment {appointmentId} by PostOwner {postOwnerId}");

            return true;
        }

        public async Task<bool> RejectAppointmentAsync(int appointmentId, int postOwnerId)
        {
            var appointment = await _context.Appointments
                .Include(a => a.Post)
                .Include(a => a.User)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && 
                                         a.Post != null && 
                                         a.Post.UserId == postOwnerId &&
                                         a.Status == AppointmentStatus.PENDING);

            if (appointment == null)
            {
                return false;
            }

            appointment.Status = AppointmentStatus.REJECTED;
            await _context.SaveChangesAsync();

            // Gửi thông báo cho user đã tạo appointment (appointment.UserId) rằng lịch hẹn đã bị từ chối
            var notification = new Notification
            {
                UserId = appointment.UserId,
                PostId = appointment.PostId,
                AppointmentId = appointment.Id,
                SavedSearchId = null,
                MessageId = null,
                Title = "Lịch hẹn đã bị từ chối",
                Message = $"Lịch hẹn '{appointment.Title}' vào lúc {appointment.AppointmentTime:dd/MM/yyyy HH:mm} đã bị từ chối.",
                Type = "AppointmentRejected",
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            // Gửi notification real-time qua SignalR
            if (_notificationHub != null)
            {
                await _notificationHub.Clients.Group($"user_{appointment.UserId}").SendAsync("ReceiveNotification", new
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
            }

            _logger.LogInformation($"Rejected Appointment {appointmentId} by PostOwner {postOwnerId}");

            return true;
        }

        public async Task<IEnumerable<Appointment>> GetDueAppointmentsAsync()
        {
            var now = DateTime.UtcNow;

            // Chỉ gửi reminder cho appointments đã được chấp nhận (ACCEPTED)
            var dueAppointments = await _context.Appointments
                .Where(a => !a.IsNotified &&
                           a.Status == AppointmentStatus.ACCEPTED && // CHỈ gửi reminder khi đã được chấp nhận
                           a.AppointmentTime.AddMinutes(-a.ReminderMinutes) <= now)
                .ToListAsync();

            return dueAppointments;
        }

        private AppointmentDto MapToDto(Appointment appointment)
        {
            return new AppointmentDto
            {
                Id = appointment.Id,
                UserId = appointment.UserId,
                PostId = appointment.PostId,
                Title = appointment.Title,
                Description = appointment.Description,
                AppointmentTime = appointment.AppointmentTime,
                ReminderMinutes = appointment.ReminderMinutes,
                IsNotified = appointment.IsNotified,
                Status = appointment.Status,
                CreatedAt = appointment.CreatedAt
            };
        }
    }
}

