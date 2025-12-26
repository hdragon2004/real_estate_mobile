using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Models
{
    public class Report
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int PostId { get; set; }
        public ReportType Type { get; set; }
        public string? Other { get; set; }
        public string? Phone { get; set; }
        // Note: Default value sẽ được set trong constructor hoặc khi tạo entity
        // Sử dụng DateTimeHelper.GetVietnamNow() khi tạo mới
        public DateTime CreatedReport { get; set; }
        public bool IsHandled { get; set; }

        public User? User { get; set; }
        public Post? Post { get; set; }
    }


}
