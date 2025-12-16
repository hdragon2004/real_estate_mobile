using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Services
{

    public interface IAppointmentService
    {

        Task<AppointmentDto> CreateAppointmentAsync(int userId, CreateAppointmentDto dto);

        Task<IEnumerable<AppointmentDto>> GetUserAppointmentsAsync(int userId);

        Task<IEnumerable<AppointmentDto>> GetPendingAppointmentsForPostOwnerAsync(int postOwnerId);

        Task<IEnumerable<AppointmentDto>> GetAllAppointmentsForPostOwnerAsync(int postOwnerId);

        Task<bool> CancelAppointmentAsync(int appointmentId, int userId);

        Task<bool> ConfirmAppointmentAsync(int appointmentId, int postOwnerId);

        Task<bool> RejectAppointmentAsync(int appointmentId, int postOwnerId);

        Task<IEnumerable<Appointment>> GetDueAppointmentsAsync();
    }
}

