using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Services
{

    public interface IAppointmentService
    {

        Task<AppointmentDto> CreateAppointmentAsync(int userId, CreateAppointmentDto dto);

        Task<IEnumerable<AppointmentDto>> GetUserAppointmentsAsync(int userId);

        Task<bool> CancelAppointmentAsync(int appointmentId, int userId);

        Task<IEnumerable<Appointment>> GetDueAppointmentsAsync();
    }
}

