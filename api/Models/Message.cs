using RealEstateHubAPI.Model;

namespace RealEstateHubAPI.Model
{
    public class Message
    {
        public int Id { get; set; }

        public int SenderId { get; set; }
        public User Sender { get; set; }

        public int ReceiverId { get; set; }
        public User Receiver { get; set; }

        public int PostId { get; set; }
        public Post Post { get; set; }

        public string ConversationId { get; set; }

        public string Content { get; set; }

        public string? ImageUrl { get; set; } 
        
        // Note: Default value sẽ được set trong constructor hoặc khi tạo entity
        // Sử dụng DateTimeHelper.GetVietnamNow() khi tạo mới
        public DateTime SentTime { get; set; }
        
        public bool IsRead { get; set; } = false;
        
        
    }
}

