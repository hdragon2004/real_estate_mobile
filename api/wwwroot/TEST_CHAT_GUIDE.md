# 📋 Hướng dẫn Test Chat với test-chat.html

## 🚀 Cách chạy Test Chat Client

### Bước 1: Khởi động Backend API
1. Mở terminal trong thư mục `api`
2. Chạy lệnh:
   ```bash
   dotnet run
   ```
3. Đảm bảo backend đang chạy (thường là `http://localhost:5134` hoặc port khác)

### Bước 2: Mở file test-chat.html
1. Mở file `api/wwwroot/test-chat.html` trong trình duyệt
   - Cách 1: Double-click vào file `test-chat.html`
   - Cách 2: Mở trình duyệt và nhập URL: `http://localhost:5134/test-chat.html` (nếu backend đang chạy)
   - Cách 3: Kéo thả file vào trình duyệt

### Bước 3: Đăng nhập
1. **Base URL**: Nhập URL của backend API
   - Mặc định: `http://localhost:5134`
   - Nếu backend chạy port khác, thay đổi cho phù hợp

2. **Email**: Nhập email của user (từ seed data hoặc user đã tạo)
   - Ví dụ: `user1@example.com`
   - Hoặc: `user2@example.com`
   - Hoặc: `user3@example.com`
   - Hoặc: `admin@realestate.com`

3. **Mật khẩu**: Nhập mật khẩu
   - Mặc định từ seed: `user123` (cho user1, user2, user3)
   - Hoặc: `admin123` (cho admin)

4. Click nút **"🔐 Đăng nhập"**

### Bước 4: Kết nối SignalR
- Sau khi đăng nhập thành công, SignalR sẽ tự động kết nối
- Hoặc click nút **"🔌 Kết nối SignalR"** nếu chưa kết nối
- Kiểm tra trạng thái: **"✅ Đã kết nối SignalR"** (màu xanh)

### Bước 5: Test Chat

#### 5.1. Xem danh sách cuộc trò chuyện
- Danh sách cuộc trò chuyện sẽ hiển thị ở panel bên trái
- Nếu chưa có, bạn cần tạo conversation bằng cách gửi tin nhắn đầu tiên

#### 5.2. Tạo cuộc trò chuyện mới
- Để test chat giữa 2 users, bạn cần:
  1. Mở 2 tab trình duyệt (hoặc 2 cửa sổ)
  2. Đăng nhập với 2 user khác nhau:
     - Tab 1: `user1@example.com` / `user123`
     - Tab 2: `user2@example.com` / `user123`
  3. Ở tab 1, chọn conversation với user2 (hoặc gửi tin nhắn đầu tiên)
  4. Gửi tin nhắn từ tab 1
  5. Tin nhắn sẽ hiển thị real-time ở tab 2

#### 5.3. Gửi tin nhắn
1. Chọn một cuộc trò chuyện từ danh sách bên trái
2. Nhập tin nhắn vào ô input
3. Click **"📤 Gửi"** hoặc nhấn **Enter**
4. Tin nhắn sẽ hiển thị ngay lập tức (real-time)

#### 5.4. Nhận tin nhắn real-time
- Khi user khác gửi tin nhắn, tin nhắn sẽ tự động xuất hiện trong chat
- Không cần refresh trang

### Bước 6: Xem Log
- Phần **"📋 Log"** ở cuối trang sẽ hiển thị:
  - Thông tin kết nối
  - Tin nhắn gửi/nhận
  - Lỗi (nếu có)
  - Các sự kiện SignalR

## 🔍 Kiểm tra và Debug

### Kiểm tra kết nối SignalR
- Xem trạng thái: **"✅ Đã kết nối SignalR"** (màu xanh)
- Nếu **"❌ Chưa kết nối SignalR"** (màu đỏ):
  1. Kiểm tra backend có đang chạy không
  2. Kiểm tra Base URL có đúng không
  3. Kiểm tra JWT token có hợp lệ không
  4. Click **"🔌 Kết nối SignalR"** lại

### Kiểm tra CORS
- Nếu gặp lỗi CORS, đảm bảo backend đã cấu hình CORS đúng
- Kiểm tra file `Program.cs` có `app.UseCors("AllowAll")` trong development

### Kiểm tra Authentication
- Đảm bảo đã đăng nhập thành công
- JWT token sẽ được tự động lưu và sử dụng cho SignalR

## 📝 Lưu ý

1. **Backend phải đang chạy**: File HTML này cần backend API để hoạt động
2. **Cần 2 users để test chat**: Chat là 1-1, cần 2 users khác nhau
3. **SignalR WebSocket**: Đảm bảo firewall không chặn WebSocket connections
4. **HTTPS vs HTTP**: 
   - Development: Dùng HTTP (`http://localhost:5134`)
   - Production: Có thể cần HTTPS

## 🎯 Test Scenarios

### Scenario 1: Chat giữa 2 users
1. Tab 1: Login với `user1@example.com`
2. Tab 2: Login với `user2@example.com`
3. Tab 1: Gửi tin nhắn "Hello" đến user2
4. Tab 2: Nhận tin nhắn "Hello" real-time
5. Tab 2: Gửi tin nhắn "Hi" đến user1
6. Tab 1: Nhận tin nhắn "Hi" real-time

### Scenario 2: Multiple conversations
1. User1 chat với User2
2. User1 chat với User3
3. Kiểm tra danh sách conversations có 2 items
4. Chuyển đổi giữa các conversations

### Scenario 3: Reconnect
1. Kết nối SignalR
2. Gửi/nhận tin nhắn
3. Click **"🔴 Ngắt kết nối"**
4. Click **"🔌 Kết nối SignalR"** lại
5. Kiểm tra tin nhắn vẫn còn và có thể tiếp tục chat

## 🐛 Troubleshooting

### Lỗi: "Failed to connect to SignalR"
- Kiểm tra backend có đang chạy không
- Kiểm tra Base URL có đúng không
- Kiểm tra port có đúng không
- Kiểm tra firewall/antivirus có chặn WebSocket không

### Lỗi: "401 Unauthorized"
- Kiểm tra đã đăng nhập chưa
- Kiểm tra JWT token có hợp lệ không
- Thử đăng nhập lại

### Lỗi: "CORS policy"
- Kiểm tra backend CORS configuration
- Đảm bảo `app.UseCors("AllowAll")` trong development

### Tin nhắn không hiển thị real-time
- Kiểm tra SignalR đã kết nối chưa
- Kiểm tra console log có lỗi không
- Thử refresh trang và kết nối lại

## 📚 API Endpoints được sử dụng

- `POST /api/auth/login` - Đăng nhập
- `GET /api/messages/conversations` - Lấy danh sách conversations
- `GET /api/messages/conversation/{otherUserId}?postId={postId}` - Lấy tin nhắn
- `POST /api/messages` - Gửi tin nhắn
- SignalR Hub: `/messageHub` - Real-time messaging

## ✅ Checklist Test

- [ ] Backend đang chạy
- [ ] Mở file test-chat.html trong browser
- [ ] Đăng nhập thành công
- [ ] SignalR kết nối thành công
- [ ] Xem được danh sách conversations (nếu có)
- [ ] Gửi tin nhắn thành công
- [ ] Nhận tin nhắn real-time
- [ ] Chat giữa 2 users hoạt động
- [ ] Log hiển thị đầy đủ thông tin

