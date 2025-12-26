using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using RealEstateHubAPI.Model;
using System.ComponentModel.DataAnnotations;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.DTOs
{
    public class PostDto
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        // PriceUnit đã được bỏ - format tự động dựa trên giá trị Price
        public TransactionType TransactionType { get; set; }
        public string Status { get; set; }
        public DateTime Created { get; set; }
        public float Area_Size { get; set; }
        public string Street_Name { get; set; }
        
        public int UserId { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } 
        public string? CityName { get; set; }     
        public string? DistrictName { get; set; }  
        public string? WardName { get; set; }      
        public string UserName { get; set; } 
        public bool IsApproved { get; set; }
        public DateTime? ExpiryDate { get; set; }

        public int? SoPhongNgu { get; set; }
        public int? SoPhongTam { get; set; }
        public int? SoTang { get; set; }
        public string? HuongNha { get; set; }
        public string? HuongBanCong { get; set; }
        public float? MatTien { get; set; }
        public float? DuongVao { get; set; }
        public string? PhapLy { get; set; }

        public List<PostImage> ImageUrls { get; set; }
        
        // ImageURL: URL của ảnh chính
        public string? ImageURL { get; set; }

        // Google Maps integration fields
        public string? FullAddress { get; set; }  // Địa chỉ đầy đủ (để hiển thị)
        public float? Longitude { get; set; }
        public float? Latitude { get; set; }
        public string? PlaceId { get; set; }

        public string TimeAgo { get; set; }

    }
    public class CreatePostDto
    {
        [Required]
        public string Title { get; set; }
        [Required]
        public string Description { get; set; }
        [Required]
        public decimal Price { get; set; }
        
        // PriceUnit đã được bỏ - format tự động dựa trên giá trị Price
        [Required]
        public TransactionType TransactionType  { get; set; }
        [Required]
        public string Street_Name { get; set; }
        [Required]
        public float Area_Size { get; set; }
        public int? SoPhongNgu { get; set; } 
        public int? SoPhongTam { get; set; } 
        public int? SoTang { get; set; } 
        public string? HuongNha { get; set; } 
        public string? HuongBanCong { get; set; }
        public float? MatTien { get; set; } 
        public float? DuongVao { get; set; } 
        public string? PhapLy { get; set; } 

        [Required]
        public int CategoryId { get; set; }
        
        public int UserId { get; set; }

        [Required]
        public IFormFile[] Images { get; set; }

        // ImageURL: URL của ảnh chính (sẽ được set sau khi upload ảnh đầu tiên, hoặc có thể chỉ định)
        public string? ImageURL { get; set; }

        // Google Maps integration fields (optional - nếu có thì sẽ tự động map vào WardId)
        public string? FullAddress { get; set; }  // Địa chỉ đầy đủ từ Google Maps
        public float? Longitude { get; set; }     // Tọa độ kinh độ từ Google Maps
        public float? Latitude { get; set; }      // Tọa độ vĩ độ từ Google Maps
        public string? PlaceId { get; set; }      // Google Place ID
        
        // Address components từ provinces.open-api.vn (bắt buộc)
        [Required]
        public string CityName { get; set; }     // Tên thành phố từ provinces.open-api.vn
        [Required]
        public string DistrictName { get; set; } // Tên quận/huyện từ provinces.open-api.vn
        [Required]
        public string WardName { get; set; }      // Tên phường/xã từ provinces.open-api.vn
        
    }
    public class UpdatePostDto
    {
        [Required]
        public int Id { get; set; }
        [Required]
        public string Title { get; set; }
        [Required]
        public string Description { get; set; }
        [Required]
        public decimal Price { get; set; }

        // PriceUnit đã được bỏ - format tự động dựa trên giá trị Price
        [Required]
        public TransactionType TransactionType { get; set; }
        public string? Status { get; set; }
        [Required]
        public string Street_Name { get; set; }
        [Required]
        public float Area_Size { get; set; }
        public int? SoPhongNgu { get; set; } 
        public int? SoPhongTam { get; set; } 
        public int? SoTang { get; set; }
        public string? HuongNha { get; set; } 
        public string? HuongBanCong { get; set; } 
        public float? MatTien { get; set; } 
        public float? DuongVao { get; set; } 
        public string? PhapLy { get; set; } 

        [Required]
        public int CategoryId { get; set; }
        
        public int UserId { get; set; }

        public IFormFile[]? Images { get; set; } 

        // ImageURL: URL của ảnh chính (nếu cập nhật ảnh chính)
        public string? ImageURL { get; set; }
        
        // Google Maps integration fields (optional)
        public string? FullAddress { get; set; }
        public float? Longitude { get; set; }
        public float? Latitude { get; set; }
        public string? PlaceId { get; set; }
        
        // Address components từ provinces.open-api.vn
        public string? CityName { get; set; }     // Tên thành phố từ provinces.open-api.vn
        public string? DistrictName { get; set; }  // Tên quận/huyện từ provinces.open-api.vn
        public string? WardName { get; set; }      // Tên phường/xã từ provinces.open-api.vn
       
    }

    /// <summary>
    /// DTO cho tìm kiếm posts theo bán kính trên bản đồ
    /// Sử dụng POST thay vì GET vì:
    /// 1. Request body chứa tọa độ và bán kính (phức tạp hơn query string)
    /// 2. POST cho phép gửi dữ liệu lớn hơn và bảo mật hơn
    /// 3. Tính toán Haversine được thực hiện trên backend để:
    ///    - Giảm tải cho client
    ///    - Đảm bảo tính nhất quán của công thức tính toán
    ///    - Có thể cache và optimize query trên database
    /// </summary>
    public class SearchByRadiusDto
    {
        [Required(ErrorMessage = "CenterLat is required")]
        [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90")]
        [System.Text.Json.Serialization.JsonPropertyName("centerLat")]
        public double CenterLat { get; set; }      // Vĩ độ của điểm trung tâm

        [Required(ErrorMessage = "CenterLng is required")]
        [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180")]
        [System.Text.Json.Serialization.JsonPropertyName("centerLng")]
        public double CenterLng { get; set; }      // Kinh độ của điểm trung tâm

        [Required(ErrorMessage = "RadiusInKm is required")]
        [Range(0.1, 100, ErrorMessage = "Radius must be between 0.1 and 100 km")]
        [System.Text.Json.Serialization.JsonPropertyName("radiusInKm")]
        public double RadiusInKm { get; set; }     // Bán kính tìm kiếm (km)
    }
}
