using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Services
{
    /// <summary>
    /// Service để map Google Places address components vào Ward
    /// </summary>
    public class GooglePlacesMappingService : IGooglePlacesMappingService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<GooglePlacesMappingService> _logger;

        public GooglePlacesMappingService(ApplicationDbContext context, ILogger<GooglePlacesMappingService> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Map Google Places address components vào Ward
        /// Tự động tìm hoặc tạo City/District/Ward nếu chưa tồn tại
        /// </summary>
        public async Task<int> MapToWardIdAsync(string? cityName, string? districtName, string? wardName, float? longitude = null, float? latitude = null)
        {
            // Lưu original names để log
            var originalCityName = cityName;
            var originalDistrictName = districtName;
            var originalWardName = wardName;

            // Tìm hoặc tạo City trong database
            var city = await FindOrCreateCityAsync(cityName);
            if (city == null)
            {
                _logger.LogWarning($"City not found and could not be created: {cityName}");
                throw new Exception($"Không thể xác định thành phố '{cityName}'. Vui lòng kiểm tra lại địa chỉ.");
            }

            // Tìm hoặc tạo District trong database
            var district = await FindOrCreateDistrictAsync(districtName, city.Id);
            if (district == null)
            {
                _logger.LogWarning($"District not found and could not be created: {districtName} in city {cityName}");
                throw new Exception($"Không thể xác định quận/huyện '{districtName}'. Vui lòng kiểm tra lại địa chỉ.");
            }

            // Tìm hoặc tạo Ward trong database
            var ward = await FindOrCreateWardAsync(wardName, district.Id);
            if (ward == null)
            {
                _logger.LogWarning($"Ward not found and could not be created: {wardName} in district {districtName}");
                throw new Exception($"Không thể xác định phường/xã '{wardName}'. Vui lòng kiểm tra lại địa chỉ.");
            }

            _logger.LogInformation($"Found Ward: City={cityName}, District={districtName}, Ward={wardName}, WardId={ward.Id}");
            return ward.Id;
        }

        /// <summary>
        /// Parse FullAddress thành CityName, DistrictName, WardName
        /// </summary>
        public (string? cityName, string? districtName, string? wardName) ParseFullAddress(string? fullAddress)
        {
            if (string.IsNullOrWhiteSpace(fullAddress))
                return (null, null, null);

            fullAddress = fullAddress.Trim();
            var parts = fullAddress.Split(',')
                .Select(p => p.Trim())
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .ToList();

            if (parts.Count == 0)
                return (null, null, null);

            string? cityName = null;
            string? districtName = null;
            string? wardName = null;

            // Format: "Số nhà Đường, Phường/Xã, Quận/Huyện, Thành phố/Tỉnh"
            if (parts.Count >= 1)
            {
                var lastPart = parts[parts.Count - 1];
                cityName = ExtractCityName(lastPart);
            }

            if (parts.Count >= 2)
            {
                var secondLastPart = parts[parts.Count - 2];
                districtName = ExtractDistrictName(secondLastPart);
            }

            if (parts.Count >= 3)
            {
                var thirdLastPart = parts[parts.Count - 3];
                wardName = ExtractWardName(thirdLastPart);
            }

            if (cityName == null || districtName == null || wardName == null)
            {
                return ParseIntelligently(parts);
            }

            return (cityName, districtName, wardName);
        }

        private (string? cityName, string? districtName, string? wardName) ParseIntelligently(List<string> parts)
        {
            string? cityName = null;
            string? districtName = null;
            string? wardName = null;

            foreach (var part in parts)
            {
                var lowerPart = part.ToLower();

                if (cityName == null && (
                    lowerPart.Contains("thành phố") || 
                    lowerPart.Contains("tp") ||
                    lowerPart.Contains("tỉnh") ||
                    lowerPart.StartsWith("tp.") ||
                    lowerPart.StartsWith("tp ")))
                {
                    cityName = ExtractCityName(part);
                }
                else if (districtName == null && (
                    lowerPart.Contains("quận") ||
                    lowerPart.Contains("huyện") ||
                    lowerPart.StartsWith("q.") ||
                    lowerPart.StartsWith("q ") ||
                    (lowerPart.StartsWith("quận") && !lowerPart.Contains("phường"))))
                {
                    districtName = ExtractDistrictName(part);
                }
                else if (wardName == null && (
                    lowerPart.Contains("phường") ||
                    lowerPart.Contains("xã") ||
                    lowerPart.Contains("thị trấn") ||
                    lowerPart.StartsWith("p.") ||
                    lowerPart.StartsWith("p ") ||
                    lowerPart.StartsWith("tt")))
                {
                    wardName = ExtractWardName(part);
                }
            }

            return (cityName, districtName, wardName);
        }

        private string? NormalizeName(string? name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return null;

            name = name.Trim();
            var prefixes = new[] { "Thành phố", "TP", "Tp", "Tỉnh", "Quận", "Q.", "Q", "Huyện", "Phường", "P.", "P", "Xã", "Thị trấn", "TT" };
            
            foreach (var prefix in prefixes)
            {
                if (name.StartsWith(prefix + " ", StringComparison.OrdinalIgnoreCase))
                {
                    name = name.Substring(prefix.Length + 1).Trim();
                }
                else if (name.StartsWith(prefix, StringComparison.OrdinalIgnoreCase) && name.Length > prefix.Length)
                {
                    name = name.Substring(prefix.Length).Trim();
                }
            }

            return name;
        }

        private async Task<City?> FindOrCreateCityAsync(string? cityName)
        {
            if (string.IsNullOrWhiteSpace(cityName))
                return null;

            // Normalize cả input và database names để so sánh
            var normalizedInput = NormalizeName(cityName);
            
            // Load tất cả cities về client-side để có thể dùng StringComparison
            var allCities = await _context.Cities.ToListAsync();
            
            // Tìm exact match trước (case-insensitive)
            var city = allCities.FirstOrDefault(c => 
                c.Name.Equals(cityName, StringComparison.OrdinalIgnoreCase));
            
            if (city != null)
            {
                _logger.LogInformation($"Found exact match for city: {cityName} -> {city.Name}");
                return city;
            }

            // Tìm với normalized name
            if (!string.IsNullOrWhiteSpace(normalizedInput))
            {
                city = allCities.FirstOrDefault(c => 
                {
                    var normalizedDb = NormalizeName(c.Name);
                    return normalizedDb != null && 
                           (normalizedDb.Equals(normalizedInput, StringComparison.OrdinalIgnoreCase) ||
                            normalizedDb.Contains(normalizedInput, StringComparison.OrdinalIgnoreCase) ||
                            normalizedInput.Contains(normalizedDb, StringComparison.OrdinalIgnoreCase));
                });
                
                if (city != null)
                {
                    _logger.LogInformation($"Found normalized match for city: {cityName} -> {city.Name}");
                    return city;
                }
            }

            // Tìm với Contains (fallback)
            city = allCities.FirstOrDefault(c => 
                c.Name.Contains(cityName, StringComparison.OrdinalIgnoreCase) || 
                cityName.Contains(c.Name, StringComparison.OrdinalIgnoreCase));

            if (city == null)
            {
                // Không tìm thấy, tạo mới City
                var newCity = new City
                {
                    Name = cityName.Trim()
                };
                _context.Cities.Add(newCity);
                await _context.SaveChangesAsync();
                
                _logger.LogInformation($"Created new City: {cityName} (ID: {newCity.Id})");
                return newCity;
            }
            else
            {
                _logger.LogInformation($"Found partial match for city: {cityName} -> {city.Name}");
            }

            return city;
        }

        private async Task<District?> FindOrCreateDistrictAsync(string? districtName, int cityId)
        {
            if (string.IsNullOrWhiteSpace(districtName))
                return null;

            // Normalize cả input và database names để so sánh
            var normalizedInput = NormalizeName(districtName);
            
            // Load tất cả districts của city về client-side để có thể dùng StringComparison
            var allDistricts = await _context.Districts
                .Where(d => d.CityId == cityId)
                .ToListAsync();
            
            // Tìm exact match trước (case-insensitive)
            var district = allDistricts.FirstOrDefault(d => 
                d.Name.Equals(districtName, StringComparison.OrdinalIgnoreCase));
            
            if (district != null)
            {
                _logger.LogInformation($"Found exact match for district: {districtName} -> {district.Name}");
                return district;
            }

            // Tìm với normalized name
            if (!string.IsNullOrWhiteSpace(normalizedInput))
            {
                district = allDistricts.FirstOrDefault(d => 
                {
                    var normalizedDb = NormalizeName(d.Name);
                    return normalizedDb != null && 
                           (normalizedDb.Equals(normalizedInput, StringComparison.OrdinalIgnoreCase) ||
                            normalizedDb.Contains(normalizedInput, StringComparison.OrdinalIgnoreCase) ||
                            normalizedInput.Contains(normalizedDb, StringComparison.OrdinalIgnoreCase));
                });
                
                if (district != null)
                {
                    _logger.LogInformation($"Found normalized match for district: {districtName} -> {district.Name}");
                    return district;
                }
            }

            // Tìm với Contains (fallback)
            district = allDistricts.FirstOrDefault(d => 
                d.Name.Contains(districtName, StringComparison.OrdinalIgnoreCase) || 
                districtName.Contains(d.Name, StringComparison.OrdinalIgnoreCase));

            if (district == null)
            {
                // Không tìm thấy, tạo mới District
                var newDistrict = new District
                {
                    Name = districtName.Trim(),
                    CityId = cityId
                };
                _context.Districts.Add(newDistrict);
                await _context.SaveChangesAsync();
                
                _logger.LogInformation($"Created new District: {districtName} (ID: {newDistrict.Id}) in CityId={cityId}");
                return newDistrict;
            }
            else
            {
                _logger.LogInformation($"Found partial match for district: {districtName} -> {district.Name}");
            }

            return district;
        }

        private async Task<Ward?> FindOrCreateWardAsync(string? wardName, int districtId)
        {
            if (string.IsNullOrWhiteSpace(wardName))
                return null;

            // Normalize cả input và database names để so sánh
            var normalizedInput = NormalizeName(wardName);
            
            // Load tất cả wards của district về client-side để có thể dùng StringComparison
            var allWards = await _context.Wards
                .Where(w => w.DistrictId == districtId)
                .ToListAsync();
            
            // Tìm exact match trước (case-insensitive)
            var ward = allWards.FirstOrDefault(w => 
                w.Name.Equals(wardName, StringComparison.OrdinalIgnoreCase));
            
            if (ward != null)
            {
                _logger.LogInformation($"Found exact match for ward: {wardName} -> {ward.Name}");
                return ward;
            }

            // Tìm với normalized name
            if (!string.IsNullOrWhiteSpace(normalizedInput))
            {
                ward = allWards.FirstOrDefault(w => 
                {
                    var normalizedDb = NormalizeName(w.Name);
                    return normalizedDb != null && 
                           (normalizedDb.Equals(normalizedInput, StringComparison.OrdinalIgnoreCase) ||
                            normalizedDb.Contains(normalizedInput, StringComparison.OrdinalIgnoreCase) ||
                            normalizedInput.Contains(normalizedDb, StringComparison.OrdinalIgnoreCase));
                });
                
                if (ward != null)
                {
                    _logger.LogInformation($"Found normalized match for ward: {wardName} -> {ward.Name}");
                    return ward;
                }
            }

            // Tìm với Contains (fallback)
            ward = allWards.FirstOrDefault(w => 
                w.Name.Contains(wardName, StringComparison.OrdinalIgnoreCase) || 
                wardName.Contains(w.Name, StringComparison.OrdinalIgnoreCase));

            if (ward == null)
            {
                // Không tìm thấy, tạo mới Ward
                var newWard = new Ward
                {
                    Name = wardName.Trim(),
                    DistrictId = districtId
                };
                _context.Wards.Add(newWard);
                await _context.SaveChangesAsync();
                
                _logger.LogInformation($"Created new Ward: {wardName} (ID: {newWard.Id}) in DistrictId={districtId}");
                return newWard;
            }
            else
            {
                _logger.LogInformation($"Found partial match for ward: {wardName} -> {ward.Name}");
            }

            return ward;
        }

        private string? ExtractCityName(string part)
        {
            if (string.IsNullOrWhiteSpace(part))
                return null;

            part = part.Trim();
            var prefixes = new[] { "Thành phố", "TP.", "TP", "Tp.", "Tp", "Tỉnh" };
            foreach (var prefix in prefixes)
            {
                if (part.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    part = part.Substring(prefix.Length).Trim();
                    if (part.StartsWith(".") || part.StartsWith(" "))
                        part = part.Substring(1).Trim();
                    break;
                }
            }

            return string.IsNullOrWhiteSpace(part) ? null : part;
        }

        private string? ExtractDistrictName(string part)
        {
            if (string.IsNullOrWhiteSpace(part))
                return null;

            part = part.Trim();
            var prefixes = new[] { "Quận", "Q.", "Q", "Huyện" };
            foreach (var prefix in prefixes)
            {
                if (part.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    part = part.Substring(prefix.Length).Trim();
                    if (part.StartsWith(".") || part.StartsWith(" "))
                        part = part.Substring(1).Trim();
                    break;
                }
            }

            return string.IsNullOrWhiteSpace(part) ? null : part;
        }

        private string? ExtractWardName(string part)
        {
            if (string.IsNullOrWhiteSpace(part))
                return null;

            part = part.Trim();
            var prefixes = new[] { "Phường", "P.", "P", "Xã", "Thị trấn", "TT" };
            foreach (var prefix in prefixes)
            {
                if (part.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    part = part.Substring(prefix.Length).Trim();
                    if (part.StartsWith(".") || part.StartsWith(" "))
                        part = part.Substring(1).Trim();
                    break;
                }
            }

            return string.IsNullOrWhiteSpace(part) ? null : part;
        }
    }
}

