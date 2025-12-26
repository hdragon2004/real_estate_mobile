using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Models;

namespace RealEstateHubAPI.Model
{
    public class Post
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        
        public decimal Price { get; set; }
        
        // PriceUnit đã được bỏ - format tự động dựa trên giá trị Price
        // Sử dụng CurrencyFormatter.FormatCurrency(Price) để hiển thị
       
        public TransactionType TransactionType { get; set; }
        public string Status { get; set; } = "Pending"; 
        // Note: Default value sẽ được set trong constructor hoặc khi tạo entity
        // Sử dụng DateTimeHelper.GetVietnamNow() khi tạo mới
        public DateTime Created { get; set; }
        public float Area_Size { get; set; }
        public string Street_Name { get; set; }
        public string? ImageURL { get; set; } 
        public int UserId { get; set; }
        public int CategoryId { get; set; }
        public bool IsApproved { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public virtual User? User { get; set; }
        public virtual Category? Category { get; set; }

        public List<PostImage>? Images { get; set; }        
        public List<Message>? Messages { get; set; }

        public int? SoPhongNgu { get; set; } 
        public int? SoPhongTam { get; set; } 
        public int? SoTang { get; set; } 
        public string? HuongNha { get; set; } 
        public string? HuongBanCong { get; set; } 
        public float? MatTien { get; set; } 
        public float? DuongVao { get; set; } 
        public string? PhapLy { get; set; } 

        // Google Maps integration fields
        public string? FullAddress { get; set; }  // Địa chỉ đầy đủ từ Google Maps (để hiển thị)
        public float? Longitude { get; set; }     // Tọa độ kinh độ từ Google Maps
        public float? Latitude { get; set; }      // Tọa độ vĩ độ từ Google Maps
        public string? PlaceId { get; set; }      // Google Place ID (optional)
        
        // Address components để tìm kiếm/filter
        public string? CityName { get; set; }     // Tên thành phố (để tìm kiếm)
        public string? DistrictName { get; set; } // Tên quận/huyện (để tìm kiếm)
        public string? WardName { get; set; }     // Tên phường/xã (để tìm kiếm)

    }
}
