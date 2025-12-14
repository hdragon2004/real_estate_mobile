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
    public class LocationController : ControllerBase
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
                return Ok(cities);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
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
                    return NotFound($"City with ID {id} not found");
                }
                return Ok(city);
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
                return CreatedAtAction(nameof(GetCityById), new { id = city.Id }, city);
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
                    return NotFound($"District with ID {id} not found");
                }
                return Ok(district);
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
                    return NotFound($"City with ID {cityId} not found");
                }

                var districts = await _locationRepository.GetDistrictsByCityAsync(cityId);
                return Ok(districts);
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
                    return NotFound($"City with ID {districtDto.CityId} not found");
                }

                var district = new District
                {
                    Name = districtDto.Name,
                    CityId = districtDto.CityId
                };

                await _locationRepository.AddDistrictAsync(district);
                return CreatedAtAction(nameof(GetDistrictById), new { id = district.Id }, district);
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
                    return NotFound($"Ward with ID {id} not found");
                }
                return Ok(ward);
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
                    return NotFound($"District with ID {districtId} not found");
                }

                var wards = await _locationRepository.GetWardsByDistrictAsync(districtId);
                return Ok(wards);
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
                    return NotFound($"District with ID {wardDto.DistrictId} not found");
                }

                var ward = new Ward
                {
                    Name = wardDto.Name,
                    DistrictId = wardDto.DistrictId
                };

                await _locationRepository.AddWardAsync(ward);
                return CreatedAtAction(nameof(GetWardById), new { id = ward.Id }, ward);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Internal server error");
            }
        }
    }
}

