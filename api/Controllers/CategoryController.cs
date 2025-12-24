using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Models;
using RealEstateHubAPI.Repositories;

namespace RealEstateHubAPI.Controllers
{
    [Route("api/categories")]
    [ApiController]
    //[Authorize(Roles = "Admin")]
    public class CategoryController : BaseController
    {
        private readonly ICategoryRepository _categoryRepository;
        private readonly ApplicationDbContext _context;

        public CategoryController(ICategoryRepository categoryRepository, ApplicationDbContext context)
        {
            _categoryRepository = categoryRepository;
            _context = context;
        }

        // Lấy danh sách tất cả các danh mục
        [AllowAnonymous]
        [HttpGet]
        public async Task<IActionResult> GetCategories()
        {
            try
            {
                var categories = await _categoryRepository.GetCategoriesAsync();
                return Success(categories, "Lấy danh sách danh mục thành công");
            }
            catch (Exception ex)
            {
                // Handle exception
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }
        [AllowAnonymous]
        // Lấy thông tin danh mục theo ID
        [HttpGet("{id}")]
        public async Task<IActionResult> GetCategoryById(int id)
        {
            try
            {
                var category = await _categoryRepository.GetCategoryByIdAsync(id);
                if (category == null)
                    return NotFoundResponse("Không tìm thấy danh mục");
                return Success(category, "Lấy thông tin danh mục thành công");
            }
            catch (Exception ex)
            {
                // Handle exception
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }
        
        [HttpPost]
        public async Task<IActionResult> AddCategory([FromBody] Category category)
        {
            try
            {
                await _categoryRepository.AddCategoryAsync(category);
                return Created(category, "Thêm danh mục thành công");
            }
            catch (Exception ex)
            {
                // Handle exception
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }
       
       
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] Category category)
        {
            try
            {
                if (id != category.Id)
                    return BadRequestResponse("ID không khớp");
                await _categoryRepository.UpdateCategoryAsync(category);
                return Success(category, "Cập nhật danh mục thành công");
            }
            catch (Exception ex)
            {
                // Handle exception
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }
       
       
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            try
            {
                await _categoryRepository.DeleteCategoryAsync(id);
                return Success<object>(null, "Xóa danh mục thành công");
            }
            catch (Exception ex)
            {
                // Handle exception
                return InternalServerError("Lỗi máy chủ nội bộ");
            }
        }

        // GET: api/categories/all
        [HttpGet("all")]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var categories = await _context.Categories
                    .Where(c => c.IsActive)
                    .ToListAsync();

                return Success(categories, "Lấy danh sách danh mục thành công");
            }
            catch (Exception ex)
            {
                return InternalServerError($"Lỗi máy chủ nội bộ: {ex.Message}");
            }
        }
    }
}
