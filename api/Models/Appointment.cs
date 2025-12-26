using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Models
{
    public class Appointment
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public int PostId { get; set; }
        [Required]
        [StringLength(200)]
        public string Title { get; set; }
        [StringLength(1000)]
        public string? Description { get; set; }
        [Required]
        public DateTime AppointmentTime { get; set; }
        [Required]
        [Range(0, 1440, ErrorMessage = "ReminderMinutes must be between 0 and 1440 (24 hours)")]
        public int ReminderMinutes { get; set; }
        public bool IsNotified { get; set; } = false;
        public AppointmentStatus Status { get; set; } = AppointmentStatus.PENDING; // Mặc định là PENDING
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
        
        [ForeignKey("PostId")]
        public virtual Post? Post { get; set; }
    }
}

