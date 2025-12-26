using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Models
{
    /// <summary>
    /// Entity lưu khu vực tìm kiếm yêu thích của user
    /// User có thể lưu nhiều khu vực quan tâm với các tiêu chí khác nhau
    /// </summary>
    public class SavedSearch
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90")]
        public double CenterLatitude { get; set; }
        [Required]
        [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180")]
        public double CenterLongitude { get; set; }
        [Required]
        [Range(0.1, 100.0, ErrorMessage = "Radius must be between 0.1 and 100 km")]
        public double RadiusKm { get; set; }
        [Required]
        public TransactionType TransactionType { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public bool EnableNotification { get; set; } = true;
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}

