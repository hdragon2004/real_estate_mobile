using System.ComponentModel.DataAnnotations.Schema;
using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Models
{
    public class Notification
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? PostId { get; set; } 

        public int? SavedSearchId { get; set; }
        public int? AppointmentId { get; set; } // Link to Appointment
        
        public string Title { get; set; }
        public string Message { get; set; }
        
        /// <summary>
        /// Loại thông báo (string):
        /// - "approved": Bài đăng được admin duyệt
        /// - "SavedSearch": Bài đăng mới trong khu vực quan tâm (có SavedSearchId)
        /// - "Message": Tin nhắn mới
        /// - "Favorite": Bài đăng được thêm vào yêu thích
        /// - "PostPending": Bài đăng đang chờ duyệt
        /// - "PostApproved": Bài đăng đã được duyệt (tương tự "approved")
        /// - "Welcome": Thông báo chào mừng user mới
        /// - "Reminder": Nhắc lịch hẹn (Appointment reminder)
        /// </summary>
        public string Type { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsRead { get; set; } = false;

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
        
        [ForeignKey("PostId")]
        public virtual Post? Post { get; set; }
        
        [ForeignKey("SavedSearchId")]
        public virtual SavedSearch? SavedSearch { get; set; }

        [ForeignKey("AppointmentId")]
        public virtual Appointment? Appointment { get; set; }
        
        public int? SenderId { get; internal set; }
    }
}
