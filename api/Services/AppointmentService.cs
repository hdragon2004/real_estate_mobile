using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Services
{
    public class AppointmentService : IAppointmentService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AppointmentService> _logger;

        public AppointmentService(
            ApplicationDbContext context,
            ILogger<AppointmentService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<AppointmentDto> CreateAppointmentAsync(int userId, CreateAppointmentDto dto)
        {
            // Validate: AppointmentTime phải trong tương lai
            if (dto.AppointmentTime <= DateTime.UtcNow)
            {
                throw new ArgumentException("AppointmentTime must be in the future");
            }

            var appointment = new Appointment
            {
                UserId = userId,
                Title = dto.Title,
                Description = dto.Description,
                AppointmentTime = dto.AppointmentTime,
                ReminderMinutes = dto.ReminderMinutes,
                IsNotified = false,
                IsCanceled = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.Appointments.Add(appointment);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Created Appointment {appointment.Id} for User {userId}, AppointmentTime: {appointment.AppointmentTime}");

            return MapToDto(appointment);
        }

        public async Task<IEnumerable<AppointmentDto>> GetUserAppointmentsAsync(int userId)
        {
            var appointments = await _context.Appointments
                .Where(a => a.UserId == userId && !a.IsCanceled)
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

            appointment.IsCanceled = true;
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Canceled Appointment {appointmentId} for User {userId}");

            return true;
        }

        public async Task<IEnumerable<Appointment>> GetDueAppointmentsAsync()
        {
            var now = DateTime.UtcNow;

            var dueAppointments = await _context.Appointments
                .Where(a => !a.IsNotified &&
                           !a.IsCanceled &&
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
                Title = appointment.Title,
                Description = appointment.Description,
                AppointmentTime = appointment.AppointmentTime,
                ReminderMinutes = appointment.ReminderMinutes,
                IsNotified = appointment.IsNotified,
                IsCanceled = appointment.IsCanceled,
                CreatedAt = appointment.CreatedAt
            };
        }
    }
}

