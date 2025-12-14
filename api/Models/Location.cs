using System.ComponentModel.DataAnnotations.Schema;

namespace RealEstateHubAPI.Model
{
    public class City
    {
        public int Id { get; set; }
        public string Name { get; set; }
    }

    public class District
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int CityId { get; set; }
        public City City { get; set; }
    }

    public class Ward
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int DistrictId { get; set; }
        public District District { get; set; }
    }
}

