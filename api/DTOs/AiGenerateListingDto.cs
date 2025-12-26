using System.Collections.Generic;

namespace RealEstateHubAPI.DTOs
{
    public class AiGenerateListingDto
    {
        public string? Category { get; set; }
        public string? TransactionType { get; set; } // "Sale" | "Rent"
        public string? Address { get; set; }
        public decimal? Price { get; set; }
        // PriceUnit đã được bỏ - format tự động dựa trên giá trị Price
        public decimal? AreaSize { get; set; }
        public int? Bedrooms { get; set; }
        public int? Bathrooms { get; set; }
        public int? Floors { get; set; }
        public string? Direction { get; set; }
        public string? Balcony { get; set; }
        public decimal? Frontage { get; set; }
        public decimal? Alley { get; set; }
        public string? Legal { get; set; }
        public string? Tone { get; set; } // "Lịch sự" | "Trẻ trung"
        public string? UserName { get; set; }
        public string? UserPhone { get; set; }
        public List<AmenityInfo>? NearbyAmenities { get; set; }
    }
}

