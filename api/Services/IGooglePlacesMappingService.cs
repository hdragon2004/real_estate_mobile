using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Services
{
    /// <summary>
    /// Service để map Google Places address components vào Ward
    /// </summary>
    public interface IGooglePlacesMappingService
    {
        /// <summary>
        /// Map Google Places address components vào Ward (City/District/Ward)
        /// Tự động tìm hoặc tạo City/District/Ward nếu chưa tồn tại
        /// </summary>
        /// <param name="cityName">Tên thành phố từ Google Places</param>
        /// <param name="districtName">Tên quận/huyện từ Google Places</param>
        /// <param name="wardName">Tên phường/xã từ Google Places</param>
        /// <param name="longitude">Kinh độ</param>
        /// <param name="latitude">Vĩ độ</param>
        /// <returns>WardId đã được tạo hoặc tìm thấy</returns>
        Task<int> MapToWardIdAsync(string? cityName, string? districtName, string? wardName, float? longitude = null, float? latitude = null);

        /// <summary>
        /// Parse FullAddress thành CityName, DistrictName, WardName
        /// Format thường gặp: "Số nhà Đường, Phường/Xã, Quận/Huyện, Thành phố/Tỉnh"
        /// </summary>
        /// <param name="fullAddress">Địa chỉ đầy đủ</param>
        /// <returns>Tuple chứa (CityName, DistrictName, WardName)</returns>
        (string? cityName, string? districtName, string? wardName) ParseFullAddress(string? fullAddress);
    }
}

