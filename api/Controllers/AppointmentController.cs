using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Services;
using RealEstateHubAPI.Utils;
using System.Security.Claims;

namespace RealEstateHubAPI.Controllers
{

    [ApiController]
    [Route("api/appointments")]
    [Authorize] // Tất cả endpoints đều yêu cầu đăng nhập
    public class AppointmentController : BaseController
    {
        private readonly IAppointmentService _appointmentService;
        private readonly ILogger<AppointmentController> _logger;

        public AppointmentController(
            IAppointmentService appointmentService,
            ILogger<AppointmentController> logger)
        {
            _appointmentService = appointmentService;
            _logger = logger;
        }

        private int? GetUserId()
        {
            var userId = User
                .Claims
                .Where(c => c.Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier")
                .Select(c => c.Value)
                .FirstOrDefault();
            
            if (int.TryParse(userId, out int id))
            {
                return id;
            }
            return null;
        }

        [HttpPost]
        [ProducesResponseType(typeof(AppointmentDto), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> CreateAppointment([FromBody] CreateAppointmentDto dto)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                // Validate: AppointmentTime phải trong tương lai
                // Frontend gửi local time, cần so sánh với local time hiện tại (Vietnam time)
                if (dto.AppointmentTime <= DateTimeHelper.GetVietnamNow())
                {
                    return BadRequestResponse("AppointmentTime must be in the future");
                }

                var appointment = await _appointmentService.CreateAppointmentAsync(userId.Value, dto);
                return Created(appointment, "Tạo lịch hẹn thành công");
            }
            catch (ArgumentException ex)
            {
                return BadRequestResponse(ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating appointment");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        [HttpGet("me")]
        [ProducesResponseType(typeof(IEnumerable<AppointmentDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetUserAppointments()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var appointments = await _appointmentService.GetUserAppointmentsAsync(userId.Value);
                return Success(appointments, "Lấy danh sách lịch hẹn thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user appointments");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }
        [HttpPut("{id}/cancel")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> CancelAppointment(int id)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var canceled = await _appointmentService.CancelAppointmentAsync(id, userId.Value);
                if (!canceled)
                {
                    return NotFoundResponse("Appointment not found or access denied");
                }

                return Success<object>(null, "Hủy lịch hẹn thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error canceling appointment");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        [HttpGet("pending")]
        [ProducesResponseType(typeof(IEnumerable<AppointmentDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetPendingAppointments()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var appointments = await _appointmentService.GetPendingAppointmentsForPostOwnerAsync(userId.Value);
                return Success(appointments, "Lấy danh sách lịch hẹn chờ xác nhận thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting pending appointments");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        [HttpGet("for-my-posts")]
        [ProducesResponseType(typeof(IEnumerable<AppointmentDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetAllAppointmentsForMyPosts()
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var appointments = await _appointmentService.GetAllAppointmentsForPostOwnerAsync(userId.Value);
                return Success(appointments, "Lấy danh sách lịch hẹn cho bài đăng của tôi thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting appointments for my posts");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        [HttpPut("{id}/confirm")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> ConfirmAppointment(int id)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var confirmed = await _appointmentService.ConfirmAppointmentAsync(id, userId.Value);
                if (!confirmed)
                {
                    return NotFoundResponse("Appointment not found or access denied");
                }

                return Success<object>(null, "Xác nhận lịch hẹn thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error confirming appointment");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }

        [HttpPut("{id}/reject")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> RejectAppointment(int id)
        {
            try
            {
                var userId = GetUserId();
                if (!userId.HasValue)
                {
                    return UnauthorizedResponse("User ID not found in token");
                }

                var rejected = await _appointmentService.RejectAppointmentAsync(id, userId.Value);
                if (!rejected)
                {
                    return NotFoundResponse("Appointment not found or access denied");
                }

                return Success<object>(null, "Từ chối lịch hẹn thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting appointment");
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }
    }
}

