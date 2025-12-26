using RealEstateHubAPI.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using RealEstateHubAPI.Model;
using RealEstateHubAPI.Utils;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.AspNetCore.Hosting;
using System.IO;
using RealEstateHubAPI.DTOs;

namespace RealEstateHubAPI.Services
{
    public class PaymentProcessingService : IPaymentProcessingService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<PaymentProcessingService> _logger;
        private readonly IMemoryCache _cache;
        private readonly IWebHostEnvironment _webHostEnvironment;
        public PaymentProcessingService(
            ApplicationDbContext context, 
            ILogger<PaymentProcessingService> logger,
            IMemoryCache cache,
            IWebHostEnvironment webHostEnvironment)
        {
            _context = context;
            _logger = logger;
            _cache = cache;
            _webHostEnvironment = webHostEnvironment;
        }

        public async Task<(bool success, int? agentProfileId)> ProcessSuccessfulPayment(string orderInfo)
        {
            try
            {
                _logger.LogInformation($"Processing successful payment with orderInfo: {orderInfo}");

                // Extract userId, plan, previewId, and amount from orderInfo
                var userId = ExtractUserId(orderInfo);
                var plan = ExtractPlan(orderInfo);
                var previewId = ExtractPreviewId(orderInfo);
                var previewIdString = ExtractPreviewIdAsString(orderInfo);
                var amount = ExtractAmount(orderInfo);

                _logger.LogInformation($"Extracted from orderInfo - UserId: {userId}, Plan: {plan}, PreviewId: {previewId}, PreviewIdString: {previewIdString}, Amount: {amount}");

                // Update user role based on purchased plan
                if (userId.HasValue)
                {
                    _logger.LogInformation($"Starting role upgrade for user {userId.Value} with plan {plan}");
                    var success = await UpgradeUserToMembership(userId.Value, plan);
                    if (success)
                    {
                        _logger.LogInformation($"Successfully upgraded user {userId.Value} based on plan {plan}");
                    }
                    else
                    {
                        _logger.LogError($"Failed to upgrade user {userId.Value} with plan {plan}");
                    }
                }
                else
                {
                    _logger.LogError($"Failed to extract userId from orderInfo: {orderInfo}");
                }

                // Create notifications for successful payment
                if (userId.HasValue)
                {
                    _logger.LogInformation($"Starting to create notifications for user {userId.Value}");
                    await CreatePaymentNotifications(userId.Value, plan, null, null);
                }
                else
                {
                    _logger.LogWarning($"Cannot create notifications - userId is null");
                }

                _logger.LogInformation($"Payment processing completed successfully for user {userId}");
                return (true, null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing successful payment: {ex.Message}");
                
                return (false, null);
            }
        }

        

        private int? ExtractUserId(string orderDesc)
        {
            _logger.LogInformation($"Extracting userId from: {orderDesc}");
            
            if (orderDesc.Contains("userId="))
            {
                var userIdMatch = Regex.Match(orderDesc, @"userId=(\d+)");
                _logger.LogInformation($"UserId regex match: {userIdMatch.Success}");
                
                if (userIdMatch.Success && int.TryParse(userIdMatch.Groups[1].Value, out int parsedUserId))
                {
                    _logger.LogInformation($"Successfully extracted userId: {parsedUserId}");
                    return parsedUserId;
                }
                else
                {
                    _logger.LogWarning($"Failed to parse userId from: {userIdMatch.Groups[1].Value}");
                }
            }
            else
            {
                _logger.LogWarning($"orderDesc does not contain 'userId=': {orderDesc}");
            }
            return null;
        }

        private string ExtractPlan(string orderDesc)
        {
            if (orderDesc.Contains("plan="))
            {
                var planMatch = Regex.Match(orderDesc, @"plan=([^;]+)");
                if (planMatch.Success)
                {
                    return planMatch.Groups[1].Value;
                }
            }
            return "";
        }

        private int? ExtractPreviewId(string orderDesc)
        {
            _logger.LogInformation($"Extracting previewId from: {orderDesc}");
            
            if (orderDesc.Contains("previewId="))
            {
                var previewIdMatch = Regex.Match(orderDesc, @"previewId=([^;]+)");
                _logger.LogInformation($"PreviewId regex match: {previewIdMatch.Success}");
                
                if (previewIdMatch.Success)
                {
                    var previewIdStr = previewIdMatch.Groups[1].Value.Trim();
                    _logger.LogInformation($"Extracted previewId string: '{previewIdStr}'");
                    
                    // Try to parse as int first (for numeric IDs)
                    if (int.TryParse(previewIdStr, out int numericId))
                    {
                        _logger.LogInformation($"Successfully parsed numeric previewId: {numericId}");
                        return numericId;
                    }
                    
                    // If it's a GUID string, we'll use it as is
                    _logger.LogInformation($"Using previewId as string: {previewIdStr}");
                    return null; // We'll handle GUID strings differently
                }
                else
                {
                    _logger.LogWarning($"Failed to match previewId regex in: {orderDesc}");
                }
            }
            else
            {
                _logger.LogWarning($"orderDesc does not contain 'previewId=': {orderDesc}");
            }
            return null;
        }

        private string? ExtractPreviewIdAsString(string orderDesc)
        {
            _logger.LogInformation($"Extracting previewId as string from: {orderDesc}");
            
            if (orderDesc.Contains("previewId="))
            {
                var previewIdMatch = Regex.Match(orderDesc, @"previewId=([^;]+)");
                if (previewIdMatch.Success)
                {
                    var previewId = previewIdMatch.Groups[1].Value.Trim();
                    _logger.LogInformation($"Extracted previewId string: '{previewId}'");
                    return previewId;
                }
            }
            return null;
        }

        private string? ExtractAmount(string orderInfo)
        {
            // Amount is the last numeric token; try to find the last number in the string
            var match = Regex.Matches(orderInfo, @"(\d+)");
            if (match.Count > 0)
            {
                return match[^1].Value; // last match
            }
            return null;
        }


        private async Task<bool> UpgradeUserToMembership(int userId, string plan)
        {
            try
            {
                _logger.LogInformation($"Attempting to upgrade user {userId} based on plan: {plan}");
                
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                {
                    _logger.LogWarning($"User with ID {userId} not found");
                    return false;
                }
                
                _logger.LogInformation($"Found user: {user.Id} ({user.Name}) with current role: {user.Role}");

                // Map plan -> role
                var newRole = plan switch
                {
                    "pro_month" => "Pro_1",
                    "pro_quarter" => "Pro_3",
                    "pro_year" => "Pro_12",
                    _ => "Pro_1"
                };

                var oldRole = user.Role;
                user.Role = newRole;

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Successfully upgraded user {user.Id} ({user.Name}) from {oldRole} to {newRole} via plan: {plan}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error upgrading user {userId} by plan {plan}: {ex.Message}");
                return false;
            }
        }


        private string? MoveFileToPermanentLocation(string? temporaryRelativePath, string targetFolder)
        {
            if (string.IsNullOrEmpty(temporaryRelativePath))
            {
                return null;
            }

            try
            {
                // temporaryRelativePath sẽ có dạng "/uploads/temp/avatars/filename.jpg"
                var fileName = Path.GetFileName(temporaryRelativePath);

                // Xây dựng đường dẫn vật lý đầy đủ của file tạm thời
                var tempFilePath = Path.Combine(_webHostEnvironment.WebRootPath, temporaryRelativePath.TrimStart('/'));

                // Xây dựng đường dẫn vật lý đầy đủ của thư mục đích
                var permanentFolderPath = Path.Combine(_webHostEnvironment.WebRootPath, "uploads", targetFolder);

                // Tạo thư mục đích nếu nó chưa tồn tại
                if (!Directory.Exists(permanentFolderPath))
                {
                    Directory.CreateDirectory(permanentFolderPath);
                }

                // Xây dựng đường dẫn vật lý đầy đủ của file đích
                var permanentFilePath = Path.Combine(permanentFolderPath, fileName);

                // Kiểm tra xem file tạm có tồn tại không trước khi di chuyển
                if (System.IO.File.Exists(tempFilePath))
                {
                    // Di chuyển file
                    System.IO.File.Move(tempFilePath, permanentFilePath, true); // true để ghi đè nếu file đã tồn tại

                    // Trả về đường dẫn tương đối mới cho file
                    return $"/uploads/{targetFolder}/{fileName}";
                }
                else
                {
                    _logger.LogWarning($"Temporary file not found: {tempFilePath}");
                    return temporaryRelativePath; // Giữ lại đường dẫn tạm thời nếu không tìm thấy file
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error moving file from {temporaryRelativePath} to {targetFolder}: {ex.Message}");
                return temporaryRelativePath; // Giữ lại đường dẫn cũ nếu có lỗi
            }
        }

        private async Task CreatePaymentNotifications(int userId, string? plan, string? previewId, int? agentProfileId)
        {
            try
            {
                _logger.LogInformation($"Creating payment notifications for user {userId}, plan: {plan}");
                
                // Get user info for notification
                var user = await _context.Users.FindAsync(userId);
                if (user == null) 
                {
                    _logger.LogWarning($"User {userId} not found, cannot create notifications");
                    return;
                }
                
                _logger.LogInformation($"Found user: {user.Id} ({user.Name})");

                var notifications = new List<Notification>();

                // Always create a payment success notification
                notifications.Add(new Notification
                {
                    UserId = userId,
                    PostId = null,
                    AppointmentId = null,
                    MessageId = null,
                    SavedSearchId = null,
                    Title = "Thanh toán thành công! 🎉",
                    Message = $"Giao dịch của bạn đã được xử lý thành công. Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi!",
                    Type = "payment_success",
                    IsRead = false,
                    CreatedAt = DateTimeHelper.GetVietnamNow()
                });
                
                _logger.LogInformation($"Added payment_success notification for user {userId}");

                // Create role/membership upgrade notification
                if (!string.IsNullOrEmpty(plan))
                {
                    _logger.LogInformation($"Creating role upgrade notification for user {userId} with plan {plan}");
                    var planName = GetPlanDisplayName(plan);
                    notifications.Add(new Notification
                    {
                        UserId = userId,
                        PostId = null,
                        AppointmentId = null,
                        MessageId = null,
                        SavedSearchId = null,
                        Title = "Nâng cấp gói thành công! 👑",
                        Message = $"Tài khoản của bạn đã được nâng cấp lên {planName}.",
                        Type = "membership_upgrade",
                        IsRead = false,
                        CreatedAt = DateTimeHelper.GetVietnamNow()
                    });
                    _logger.LogInformation($"Added membership/role upgrade notification for user {userId}");
                }

                // Add all notifications to database
                _context.Notifications.AddRange(notifications);
                var saveResult = await _context.SaveChangesAsync();
                _logger.LogInformation($"Saved {saveResult} notifications to database for user {userId}");

                _logger.LogInformation($"Created {notifications.Count} notifications for user {userId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating payment notifications for user {userId}: {ex.Message}");
            }
        }

        private string GetPlanDisplayName(string? plan)
        {
            return plan switch
            {
                "pro_month" => "Pro 1 Tháng",
                "pro_quarter" => "Pro 3 Tháng", 
                "pro_year" => "Pro 12 Tháng",
                "basic" => "Gói Cơ Bản",
                "premium" => "Gói Cao Cấp",
                _ => "Membership"
            };
        }
    }
}
