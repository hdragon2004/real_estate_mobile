using Microsoft.AspNetCore.Mvc;
using RealEstateHubAPI.DTOs;

namespace RealEstateHubAPI.Controllers
{
    [ApiController]
    public abstract class BaseController : ControllerBase
    {
        protected IActionResult Success<T>(T? data, string message = "Successfully")
        {
            var response = new ApiResponse<T>
            {
                Status = 200,
                Message = message,
                Data = data
            };
            return StatusCode(200, response);
        }

        protected IActionResult Created<T>(T? data, string message = "Created successfully")
        {
            var response = new ApiResponse<T>
            {
                Status = 201,
                Message = message,
                Data = data
            };
            return StatusCode(201, response);
        }

        protected IActionResult Accepted<T>(T? data, string message = "Accepted")
        {
            var response = new ApiResponse<T>
            {
                Status = 202,
                Message = message,
                Data = data
            };
            return StatusCode(202, response);
        }

        protected IActionResult BadRequestResponse(string message = "Bad request")
        {
            var response = new ApiResponse
            {
                Status = 400,
                Message = message,
                Data = null
            };
            return StatusCode(400, response);
        }

        protected IActionResult UnauthorizedResponse(string message = "Unauthorized")
        {
            var response = new ApiResponse
            {
                Status = 401,
                Message = message,
                Data = null
            };
            return StatusCode(401, response);
        }

        protected IActionResult ForbiddenResponse(string message = "Forbidden")
        {
            var response = new ApiResponse
            {
                Status = 403,
                Message = message,
                Data = null
            };
            return StatusCode(403, response);
        }

        protected IActionResult NotFoundResponse(string message = "Not found")
        {
            var response = new ApiResponse
            {
                Status = 404,
                Message = message,
                Data = null
            };
            return StatusCode(404, response);
        }

        protected IActionResult InternalServerError(string message = "Internal server error")
        {
            var response = new ApiResponse
            {
                Status = 500,
                Message = message,
                Data = null
            };
            return StatusCode(500, response);
        }

        protected IActionResult CustomResponse<T>(int statusCode, string message, T? data = default)
        {
            var response = new ApiResponse<T>
            {
                Status = statusCode,
                Message = message,
                Data = data
            };
            return StatusCode(statusCode, response);
        }

        protected IActionResult CustomResponse(int statusCode, string message, object? data = null)
        {
            var response = new ApiResponse
            {
                Status = statusCode,
                Message = message,
                Data = data
            };
            return StatusCode(statusCode, response);
        }

        // Overloads for ActionResult<T> return types
        protected ActionResult<T> SuccessActionResult<T>(T? data, string message = "Successfully")
        {
            var response = new ApiResponse<T>
            {
                Status = 200,
                Message = message,
                Data = data
            };
            return StatusCode(200, response);
        }

        protected ActionResult<T> CreatedActionResult<T>(T? data, string message = "Created successfully")
        {
            var response = new ApiResponse<T>
            {
                Status = 201,
                Message = message,
                Data = data
            };
            return StatusCode(201, response);
        }

        protected ActionResult<T> BadRequestActionResult<T>(string message = "Bad request")
        {
            var response = new ApiResponse
            {
                Status = 400,
                Message = message,
                Data = null
            };
            return StatusCode(400, response);
        }

        protected ActionResult<T> InternalServerErrorActionResult<T>(string message = "Internal server error")
        {
            var response = new ApiResponse
            {
                Status = 500,
                Message = message,
                Data = null
            };
            return StatusCode(500, response);
        }
    }
}

