using System.ComponentModel.DataAnnotations;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.DTOs
{

    public class CreateAppointmentDto
    {
        [Required(ErrorMessage = "PostId is required")]
        public int PostId { get; set; }

        [Required(ErrorMessage = "Title is required")]
        [StringLength(200, ErrorMessage = "Title must not exceed 200 characters")]
        public string Title { get; set; }

        [StringLength(1000, ErrorMessage = "Description must not exceed 1000 characters")]
        public string? Description { get; set; }

        [Required(ErrorMessage = "AppointmentTime is required")]
        public DateTime AppointmentTime { get; set; }

        [Required(ErrorMessage = "ReminderMinutes is required")]
        [Range(0, 1440, ErrorMessage = "ReminderMinutes must be between 0 and 1440 (24 hours)")]
        public int ReminderMinutes { get; set; }
    }

    public class AppointmentDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int PostId { get; set; }
        public string Title { get; set; }
        public string? Description { get; set; }
        public DateTime AppointmentTime { get; set; }
        public int ReminderMinutes { get; set; }
        public bool IsNotified { get; set; }
        public AppointmentStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ReminderTime => AppointmentTime.AddMinutes(-ReminderMinutes);
    }
}

