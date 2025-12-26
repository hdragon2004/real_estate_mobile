using System.ComponentModel.DataAnnotations;

namespace RealEstateHubAPI.DTOs
{
    public class MessageDto
    {
        public int Id { get; set; }
        public int SenderId { get; set; }
        public string SenderName { get; set; }
        public string SenderAvatarUrl { get; set; } 
        public int ReceiverId { get; set; }
        public string ReceiverName { get; set; }
        public string ReceiverAvatarUrl { get; set; }
        public int? PostId { get; set; }
        public string? PostTitle { get; set; }
        public int? PostUserId { get; set; }
        public string? PostUserName { get; set; }
        public string? ConversationId { get; set; }
        public string Content { get; set; }
        public string? ImageUrl { get; set; } // URL của hình ảnh (nếu tin nhắn là hình ảnh)
        public DateTime SentTime { get; set; }
        public bool IsRead { get; set; } = false;
    }

    public class CreateMessageDto
    {
        [Required(ErrorMessage = "ReceiverId is required")]
        public int ReceiverId { get; set; }
        
        public int? PostId { get; set; } // Optional - có thể chat không liên quan đến post
        
        [StringLength(1000, ErrorMessage = "Message content cannot exceed 1000 characters")]
        public string? Content { get; set; } // Optional - có thể rỗng nếu có ImageUrl
        
        public string? ImageUrl { get; set; } // Optional - URL của hình ảnh (nếu tin nhắn là hình ảnh)
    }

    public class TypingIndicatorDto
    {
        public int UserId { get; set; }
        public int OtherUserId { get; set; }
        public int PostId { get; set; }
        public bool IsTyping { get; set; }
    }

    public class MarkAsReadDto
    {
        public int UserId { get; set; }
        public int OtherUserId { get; set; }
        public int PostId { get; set; }
        public int MessageId { get; set; }
    }

    public class ConversationDto
    {
        public int? PostId { get; set; }
        public int OtherUserId { get; set; }
        public string? PostTitle { get; set; }
        public string? PostUserName { get; set; }
        public string OtherUserName { get; set; }
        public string OtherUserAvatarUrl { get; set; }
        public MessageDto LastMessage { get; set; }
        public int MessageCount { get; set; }
        public int UnreadCount { get; set; }
    }
}
