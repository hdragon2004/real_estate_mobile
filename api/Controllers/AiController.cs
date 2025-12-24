using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Services;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AiController : BaseController
    {
        private readonly IAiTextService _aiTextService;
        private readonly IAmenityLookupService _amenityLookupService;

        public AiController(IAiTextService aiTextService, IAmenityLookupService amenityLookupService)
        {
            _aiTextService = aiTextService;
            _amenityLookupService = amenityLookupService;
        }

        [HttpPost("generate-listing")]
        [Authorize] // yêu cầu đăng nhập giống axiosPrivate phía FE
        public async Task<IActionResult> GenerateListing([FromBody] AiGenerateListingDto dto, CancellationToken cancellationToken)
        {
            if (dto is null)
            {
                return BadRequestResponse("Dữ liệu không hợp lệ");
            }

            try
            {
                var amenities = await _amenityLookupService.GetNearbyAmenitiesAsync(dto.Address, cancellationToken);
                dto.NearbyAmenities = amenities?.ToList();

                var (title, description) = await _aiTextService.GenerateListingAsync(dto, cancellationToken);
                return Success(new { title, description }, "Tạo listing thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError($"Lỗi dịch vụ AI: {ex.Message}");
            }
        }

        [HttpGet("nearby-amenities")]
        public async Task<IActionResult> GetNearbyAmenities([FromQuery] string? address, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(address))
            {
                return BadRequestResponse("Địa chỉ không được để trống");
            }

            try
            {
                var amenities = await _amenityLookupService.GetNearbyAmenitiesAsync(address, cancellationToken);
                return Success(amenities ?? Array.Empty<AmenityInfo>(), "Lấy danh sách tiện ích thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError($"Lỗi khi tìm kiếm tiện ích: {ex.Message}");
            }
        }
    }
}

