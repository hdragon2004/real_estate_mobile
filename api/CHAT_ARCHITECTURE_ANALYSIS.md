# 📊 Phân tích Cấu trúc Chat Backend

## 🔍 Tổng quan

Backend hiện tại có **2 hệ thống chat song song**:

1. **Stream Chat (GetStream.io)** - Sử dụng API bên ngoài
2. **Custom Chat** - Code tay hoàn toàn

---

## 1️⃣ Stream Chat (GetStream.io) - API Bên Ngoài

### 📁 Files liên quan:
- `api/Services/ChatService.cs`
- `api/Controllers/ChatController.cs`
- `api/Services/IChatService.cs`
- `api/appsettings.json` (cấu hình StreamChat)

### 🔧 Chức năng:
1. **Generate User Token** (`GenerateUserTokenAsync`)
   - Tạo JWT token cho Stream Chat
   - Token dùng để frontend kết nối với Stream Chat SDK
   - Endpoint: `POST /api/chat/token`

2. **Ensure Users Exist** (`EnsureUsersExistAsync`)
   - Gọi API Stream Chat để tạo/update users
   - Endpoint Stream: `POST https://chat.stream-io-api.com/users`
   - Endpoint backend: `POST /api/chat/ensure-users`

3. **Delete Channel** (`DeleteChannelAsync`)
   - Gọi API Stream Chat để xóa channel
   - Endpoint Stream: `DELETE https://chat.stream-io-api.com/channels/{type}/{id}`
   - Endpoint backend: `DELETE /api/chat/channels/{type}/{id}`

### 🌐 API bên ngoài được sử dụng:
- **Base URL**: `https://chat.stream-io-api.com/`
- **Authentication**: JWT signed với `StreamChat:ApiSecret`
- **Headers**: 
  - `Authorization`: JWT token
  - `stream-auth-type`: "jwt"

### ⚙️ Cấu hình:
```json
"StreamChat": {
  "ApiKey": "tqq4bnyz2bt8",
  "ApiSecret": "94r8e3eput74b7qb6z3qtjrw6smd8xxbcxwwqmsrw6nxnyefjjsndak4rncsfp3h"
}
```

### 📝 Lưu ý:
- Stream Chat là **third-party service** (GetStream.io)
- Cần có tài khoản và API key/secret
- Frontend cần Stream Chat SDK để sử dụng
- **Có vẻ không được sử dụng trong MessageController hiện tại**

---

## 2️⃣ Custom Chat - Code Tay Hoàn Toàn

### 📁 Files liên quan:
- `api/Controllers/MessageController.cs`
- `api/Hubs/MessageHub.cs`
- `api/Models/Message.cs`
- `api/DTOs/MessageDto.cs`
- `api/DTOs/ConversationDto.cs`

### 🔧 Chức năng:

#### A. MessageController.cs (REST API)
1. **Gửi tin nhắn** (`POST /api/messages`)
   - ✅ Lưu message vào database (Entity Framework)
   - ✅ Gửi real-time qua SignalR
   - ✅ Tạo notification cho người nhận
   - ❌ **KHÔNG** sử dụng Stream Chat API

2. **Lấy danh sách conversations** (`GET /api/messages/conversations`)
   - ✅ Query từ database (Entity Framework)
   - ✅ Group by ConversationId
   - ❌ **KHÔNG** sử dụng Stream Chat API

3. **Lấy lịch sử chat** (`GET /api/messages/conversation/{otherUserId}`)
   - ✅ Query từ database (Entity Framework)
   - ✅ Filter theo ConversationId
   - ❌ **KHÔNG** sử dụng Stream Chat API

#### B. MessageHub.cs (SignalR - Real-time)
1. **OnConnectedAsync**
   - ✅ Thêm user vào SignalR group (`user_{userId}`)
   - ✅ Code tay hoàn toàn

2. **OnDisconnectedAsync**
   - ✅ Xóa user khỏi SignalR group
   - ✅ Code tay hoàn toàn

3. **SendMessageToUser**
   - ✅ Gửi tin nhắn qua SignalR groups
   - ✅ Code tay hoàn toàn

4. **MarkMessageAsRead**
   - ✅ Đánh dấu tin nhắn đã đọc
   - ✅ Code tay hoàn toàn

### 🗄️ Database:
- **Model**: `Message` (trong `api/Models/Message.cs`)
- **Fields**:
  - `Id`, `SenderId`, `ReceiverId`, `PostId`
  - `ConversationId` (string: `"{minId}_{maxId}"`)
  - `Content`, `SentTime`, `IsRead`
- **Relations**: 
  - `Sender` → `User`
  - `Receiver` → `User`
  - `Post` → `Post`

### 🔄 Real-time Communication:
- **Technology**: **SignalR** (Microsoft)
- **Hub**: `/messageHub`
- **Events**:
  - `ReceiveMessage`: Nhận tin nhắn mới
  - `MessageSent`: Xác nhận tin nhắn đã gửi
  - `MessageRead`: Đánh dấu đã đọc
  - `Error`: Lỗi

### 🔐 Authentication:
- **JWT Bearer Token** (từ backend auth system)
- SignalR nhận token qua:
  - Query string: `?access_token={token}`
  - Hoặc header: `Authorization: Bearer {token}`

---

## 📊 So sánh 2 Hệ thống

| Tiêu chí | Stream Chat (API) | Custom Chat (Code tay) |
|----------|-------------------|------------------------|
| **Lưu trữ messages** | Stream Chat cloud | Database riêng (SQL Server) |
| **Real-time** | Stream Chat SDK | SignalR (Microsoft) |
| **Chi phí** | Có phí (sau free tier) | Miễn phí (self-hosted) |
| **Tùy biến** | Hạn chế | Hoàn toàn tự do |
| **Phụ thuộc** | Phụ thuộc GetStream.io | Không phụ thuộc |
| **Đang sử dụng** | ❌ Có vẻ không | ✅ Đang sử dụng |

---

## 🎯 Kết luận

### Hệ thống đang hoạt động:
✅ **Custom Chat (Code tay)** - Đang được sử dụng trong:
- `MessageController` - Gửi/nhận messages
- `MessageHub` - Real-time messaging
- Database - Lưu trữ messages

### Hệ thống có sẵn nhưng không dùng:
❌ **Stream Chat (API)** - Có code nhưng không được sử dụng trong:
- `MessageController` - Không gọi Stream Chat API
- `MessageHub` - Không sử dụng Stream Chat

### Khuyến nghị:
1. **Nếu muốn tiếp tục dùng Custom Chat:**
   - Có thể xóa code Stream Chat để giảm phức tạp
   - Hoặc giữ lại để dùng sau này

2. **Nếu muốn chuyển sang Stream Chat:**
   - Cần refactor `MessageController` để gọi Stream Chat API
   - Frontend cần dùng Stream Chat SDK
   - Cần migrate data từ database sang Stream Chat

3. **Nếu muốn dùng cả 2:**
   - Có thể tạo 2 endpoints riêng:
     - `/api/messages` - Custom chat
     - `/api/stream-chat` - Stream Chat

---

## 📝 Files liên quan

### Stream Chat:
- `api/Services/ChatService.cs`
- `api/Controllers/ChatController.cs`
- `api/Services/IChatService.cs`

### Custom Chat:
- `api/Controllers/MessageController.cs`
- `api/Hubs/MessageHub.cs`
- `api/Models/Message.cs`
- `api/DTOs/MessageDto.cs`
- `api/DTOs/ConversationDto.cs`
- `api/DTOs/CreateMessageDto.cs`

---

## 🔍 Code Evidence

### Custom Chat - Code tay:
```csharp
// MessageController.cs - Lưu vào database
var message = new Message { ... };
_context.Messages.Add(message);
await _context.SaveChangesAsync();

// Gửi qua SignalR
await _messageHub.Clients.Group($"user_{receiverId}").SendAsync("ReceiveMessage", messageDto);
```

### Stream Chat - API bên ngoài:
```csharp
// ChatService.cs - Gọi API Stream Chat
using var http = new HttpClient { BaseAddress = new Uri("https://chat.stream-io-api.com/") };
var resp = await http.PostAsync($"users?api_key={apiKey}", content);
```

