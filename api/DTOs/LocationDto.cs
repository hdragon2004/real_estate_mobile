using System.ComponentModel.DataAnnotations;

namespace RealEstateHubAPI.DTOs
{
    public class CreateDistrictDto
    {
        [Required]
        public string Name { get; set; }
        [Required]
        public int CityId { get; set; }
    }

    public class CreateWardDto
    {
        [Required]
        public string Name { get; set; }
        [Required]
        public int DistrictId { get; set; }
    }
}

