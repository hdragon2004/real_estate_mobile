using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using RealEstateHubAPI.DTOs;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Repositories;

namespace RealEstateHubAPI.Controllers
{
    [Route("api/locations")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class LocationController : BaseController
    {
        private readonly ILocationRepository _locationRepository;
        private readonly ApplicationDbContext _context;
        public LocationController(ILocationRepository locationRepository, ApplicationDbContext context)
        {
            _locationRepository = locationRepository;
            _context = context;
        }

        // City endpoints
        [AllowAnonymous]
        [HttpGet("cities")]
        public async Task<IActionResult> GetCities()
        {
            try
            {
                var cities = await _locationRepository.GetCitiesAsync();
                return Success(cities, "Lấy danh sách thành phố thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }
        [AllowAnonymous]
        [HttpGet("cities/{id}")]
        public async Task<IActionResult> GetCityById(int id)
        {
            try
            {
                var city = await _locationRepository.GetCityByIdAsync(id);
                if (city == null)
                {
                    return NotFoundResponse($"Không tìm thấy thành phố với ID {id}");
                }
                return Success(city, "Lấy thông tin thành phố thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("cities")]
        public async Task<IActionResult> CreateCity([FromBody] City city)
        {
            try
            {
                await _locationRepository.AddCityAsync(city);
                return Created(city, "Tạo thành phố thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        // District endpoints
        [AllowAnonymous]
        [HttpGet("districts")]
        public async Task<IActionResult> GetDistricts()
        {
            try
            {
                var districts = await _locationRepository.GetDistrictsAsync();
                return Ok(districts);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }
        [AllowAnonymous]
        [HttpGet("districts/{id}")]
        public async Task<IActionResult> GetDistrictById(int id)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(id);
                if (district == null)
                {
                    return NotFoundResponse($"Không tìm thấy quận/huyện với ID {id}");
                }
                return Success(district, "Lấy thông tin quận/huyện thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }
        [AllowAnonymous]
        [HttpGet("cities/{cityId}/districts")]
        public async Task<IActionResult> GetDistrictsByCity(int cityId)
        {
            try
            {
                var city = await _locationRepository.GetCityByIdAsync(cityId);
                if (city == null)
                {
                    return NotFoundResponse($"Không tìm thấy thành phố với ID {cityId}");
                }

                var districts = await _locationRepository.GetDistrictsByCityAsync(cityId);
                return Success(districts, "Lấy danh sách quận/huyện thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("districts")]
        public async Task<IActionResult> CreateDistrict([FromBody] CreateDistrictDto districtDto)
        {
            try
            {
                var city = await _locationRepository.GetCityByIdAsync(districtDto.CityId);
                if (city == null)
                {
                    return NotFoundResponse($"Không tìm thấy thành phố với ID {districtDto.CityId}");
                }

                var district = new District
                {
                    Name = districtDto.Name,
                    CityId = districtDto.CityId
                };

                await _locationRepository.AddDistrictAsync(district);
                return Created(district, "Tạo quận/huyện thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        // Ward endpoints
        [AllowAnonymous]
        [HttpGet("wards")]
        public async Task<IActionResult> GetWards()
        {
            try
            {
                var wards = await _locationRepository.GetWardsAsync();
                return Ok(wards);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }
        [AllowAnonymous]
        [HttpGet("wards/{id}")]
        public async Task<IActionResult> GetWardById(int id)
        {
            try
            {
                var ward = await _locationRepository.GetWardByIdAsync(id);
                if (ward == null)
                {
                    return NotFoundResponse($"Không tìm thấy phường/xã với ID {id}");
                }
                return Success(ward, "Lấy thông tin phường/xã thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }
        [AllowAnonymous]
        [HttpGet("districts/{districtId}/wards")]
        public async Task<IActionResult> GetWardsByDistrict(int districtId)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(districtId);
                if (district == null)
                {
                    return NotFoundResponse($"Không tìm thấy quận/huyện với ID {districtId}");
                }

                var wards = await _locationRepository.GetWardsByDistrictAsync(districtId);
                return Success(wards, "Lấy danh sách phường/xã thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("wards")]
        public async Task<IActionResult> CreateWard([FromBody] CreateWardDto wardDto)
        {
            try
            {
                var district = await _locationRepository.GetDistrictByIdAsync(wardDto.DistrictId);
                if (district == null)
                {
                    return NotFoundResponse($"Không tìm thấy quận/huyện với ID {wardDto.DistrictId}");
                }

                var ward = new Ward
                {
                    Name = wardDto.Name,
                    DistrictId = wardDto.DistrictId
                };

                await _locationRepository.AddWardAsync(ward);
                return Created(ward, "Tạo phường/xã thành công");
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }
    }
}

