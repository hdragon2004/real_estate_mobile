namespace RealEstateHubAPI.DTOs
{
    /// <summary>
    /// Standardized API response format
    /// </summary>
    /// <typeparam name="T">Type of data in the response</typeparam>
    public class ApiResponse<T>
    {
        public int Status { get; set; }
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; }

        public ApiResponse()
        {
        }

        public ApiResponse(int status, string message, T? data = default)
        {
            Status = status;
            Message = message;
            Data = data;
        }
    }

    public class ApiResponse
    {
        public int Status { get; set; }
        public string Message { get; set; } = string.Empty;
        public object? Data { get; set; }

        public ApiResponse()
        {
        }

        public ApiResponse(int status, string message, object? data = null)
        {
            Status = status;
            Message = message;
            Data = data;
        }
    }
}

