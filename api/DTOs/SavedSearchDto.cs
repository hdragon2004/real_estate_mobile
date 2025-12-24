using System.ComponentModel.DataAnnotations;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.DTOs
{
    /// <summary>
    /// DTO để tạo SavedSearch mới
    /// </summary>
    public class CreateSavedSearchDto
    {
        [Required(ErrorMessage = "CenterLatitude is required")]
        [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90")]
        public double CenterLatitude { get; set; }

        [Required(ErrorMessage = "CenterLongitude is required")]
        [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180")]
        public double CenterLongitude { get; set; }

        [Required(ErrorMessage = "RadiusKm is required")]
        [Range(0.1, 100.0, ErrorMessage = "Radius must be between 0.1 and 100 km")]
        public double RadiusKm { get; set; }

        [Required(ErrorMessage = "TransactionType is required")]
        public TransactionType TransactionType { get; set; }

        public decimal? MinPrice { get; set; }

        public decimal? MaxPrice { get; set; }

        public bool EnableNotification { get; set; } = true;

        /// <summary>
        /// Validate: MinPrice <= MaxPrice nếu cả hai đều có giá trị
        /// </summary>
        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (MinPrice.HasValue && MaxPrice.HasValue && MinPrice.Value > MaxPrice.Value)
            {
                yield return new ValidationResult(
                    "MinPrice must be less than or equal to MaxPrice",
                    new[] { nameof(MinPrice), nameof(MaxPrice) });
            }
        }
    }

    /// <summary>
    /// DTO để trả về SavedSearch
    /// </summary>
    public class SavedSearchDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public double CenterLatitude { get; set; }
        public double CenterLongitude { get; set; }
        public double RadiusKm { get; set; }
        public TransactionType TransactionType { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public bool EnableNotification { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

