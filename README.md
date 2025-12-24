# 🏠 Real Estate Hub - Ứng dụng Bất động sản

Hệ thống quản lý và tìm kiếm bất động sản đa nền tảng với các tính năng đầy đủ từ đăng tin, tìm kiếm, chat, đặt lịch hẹn đến thanh toán.

## 📋 Mục lục

- [Tổng quan](#tổng-quan)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Tính năng chính](#tính-năng-chính)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Cài đặt và Setup](#cài-đặt-và-setup)
- [Cấu hình Ngrok](#cấu-hình-ngrok)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [API Documentation](#api-documentation)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)

## 🎯 Tổng quan

**Real Estate Hub** là một hệ thống quản lý bất động sản toàn diện, bao gồm:

- **Backend API**: ASP.NET Core Web API (.NET 9.0)
- **Mobile App**: Flutter (Android/iOS)
- **Web Client**: React.js
- **Real-time Chat**: Stream Chat API với webhook integration
- **Real-time Notifications**: SignalR
- **Payment**: VNPay, Momo integration
- **AI Features**: OpenAI integration cho tự động tạo mô tả

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │     │   React Web     │     │   Admin Panel   │
│   (Mobile)      │     │   (Client)       │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   ASP.NET Core Web API   │
                    │      (.NET 9.0)          │
                    └─────────────┬─────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
┌────────▼────────┐    ┌──────────▼──────────┐   ┌────────▼────────┐
│  SQL Server     │    │   Stream Chat API   │   │   SignalR Hub   │
│  (Database)     │    │   (Real-time Chat)  │   │  (Notifications)│
└─────────────────┘    └─────────────────────┘   └─────────────────┘
```

### Chat Architecture

```
Flutter App
    │
    ▼
Stream Chat SDK (realtime messaging)
    │
    ▼
Stream Chat Webhook
    │
    ▼
ASP.NET Core Web API
    │
    ▼
SQL Database (Conversation + Message Metadata)
```

**Nguyên tắc:**
- Stream Chat chỉ dùng cho real-time messaging
- Metadata được lưu trong database riêng
- Backend kiểm soát permissions và lifecycle
- Frontend không truy cập trực tiếp database
- Stream API Secret chỉ tồn tại ở backend

## ✨ Tính năng chính

### 📱 Mobile App (Flutter)

- ✅ **Đăng nhập/Đăng ký** với JWT authentication
- ✅ **Quản lý bài đăng**: Tạo, chỉnh sửa, xóa bài đăng bất động sản
- ✅ **Tìm kiếm nâng cao**: Lọc theo loại, giá, diện tích, vị trí
- ✅ **Bản đồ**: Hiển thị vị trí bất động sản trên bản đồ
- ✅ **Yêu thích**: Lưu bài đăng yêu thích
- ✅ **So sánh**: So sánh nhiều bất động sản
- ✅ **Lịch hẹn**: Tạo và quản lý lịch hẹn xem nhà
  - Tạo lịch hẹn với bài đăng
  - Chủ bài đăng nhận thông báo và có thể chấp nhận/từ chối
  - Nhắc nhở tự động khi đến giờ hẹn (chỉ khi đã được chấp nhận)
- ✅ **Chat real-time**: Nhắn tin với người đăng bài/chủ nhà
  - Text messages
  - Image messages
  - Voice notes (audio)
- ✅ **Thông báo real-time**: Nhận thông báo tức thời qua SignalR
- ✅ **Tìm kiếm đã lưu**: Lưu và nhận thông báo khi có bài đăng mới phù hợp
- ✅ **Hồ sơ người dùng**: Quản lý thông tin cá nhân, avatar, banner
- ✅ **Thanh toán**: Tích hợp VNPay và Momo

### 🌐 Web Client (React)

- ✅ Giao diện web responsive
- ✅ Tất cả tính năng tương tự mobile app
- ✅ Stream Chat integration
- ✅ Admin panel

### 🔧 Backend API (.NET)

- ✅ RESTful API đầy đủ
- ✅ JWT Authentication & Authorization
- ✅ Real-time notifications với SignalR
- ✅ Stream Chat integration với webhook
- ✅ Payment processing (VNPay, Momo)
- ✅ AI integration (OpenAI) cho tự động tạo mô tả
- ✅ File upload (images, audio)
- ✅ Background services (appointment reminders)

## 🛠️ Công nghệ sử dụng

### Backend
- **.NET 9.0** - ASP.NET Core Web API
- **Entity Framework Core 9.0** - ORM
- **SQL Server** - Database
- **SignalR** - Real-time notifications
- **JWT Bearer** - Authentication
- **Stream Chat .NET SDK** - Chat integration
- **OpenAI SDK** - AI features
- **RestSharp** - HTTP client
- **Stripe.net** - Payment processing

### Mobile (Flutter)
- **Flutter 3.10+** - Cross-platform framework
- **Dio** - HTTP client
- **flutter_secure_storage** - Secure token storage
- **signalr_netcore** - SignalR client
- **flutter_map** - Map display (OpenStreetMap)
- **geolocator** - Location services
- **image_picker** - Camera & gallery
- **permission_handler** - Permissions
- **flutter_dotenv** - Environment variables

### Web Client
- **React.js** - Frontend framework
- **Stream Chat React SDK** - Chat integration
- **Axios** - HTTP client

## 📦 Yêu cầu hệ thống

### Backend
- .NET 9.0 SDK
- SQL Server 2019+ hoặc SQL Server Express
- Visual Studio 2022 hoặc VS Code

### Mobile
- Flutter SDK 3.10+
- Android Studio / Xcode
- Android SDK (API 21+)
- iOS 12+ (cho iOS)

### Web Client
- Node.js 18+
- npm hoặc yarn

### Development Tools
- Ngrok (để test trên thiết bị thật/emulator)
- Git

## 🚀 Cài đặt và Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd Do_an_android/Do_an/android_app
```

### 2. Backend Setup

```bash
cd api

# Cấu hình connection string trong appsettings.json
# Hoặc appsettings.Development.json

# Chạy migrations
dotnet ef database update

# Seed dữ liệu (tùy chọn)
dotnet run --seed

# Chạy backend
dotnet run
```

Backend sẽ chạy tại: `http://0.0.0.0:5134` (có thể truy cập từ mọi IP)

### 3. Flutter App Setup

```bash
cd android_app

# Cài đặt dependencies
flutter pub get

# Tạo file .env từ template
copy ENV_TEMPLATE.txt .env

# Cấu hình .env (xem phần Cấu hình Ngrok)
# Chỉnh sửa NGROK_DOMAIN và các biến khác

# Chạy app
flutter run
```

### 4. Web Client Setup

```bash
cd client

# Cài đặt dependencies
npm install

# Chạy development server
npm run dev
```

## 🔧 Cấu hình Ngrok

Để chạy app trên cả **máy ảo** và **điện thoại thật** mà không cần đổi IP:

### Quick Start (5 phút)

1. **Cài đặt Ngrok**
   ```bash
   # Tải từ: https://ngrok.com/download
   # Hoặc: brew install ngrok/ngrok/ngrok
   ```

2. **Đăng ký và lấy Authtoken**
   - Truy cập: https://dashboard.ngrok.com/signup
   - Lấy authtoken: https://dashboard.ngrok.com/get-started/your-authtoken

3. **Cấu hình Ngrok**
   ```bash
   ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
   ```

4. **Chạy Backend**
   ```bash
   cd api
   dotnet run
   ```

5. **Chạy Ngrok** (terminal mới)
   ```bash
   ngrok http 5134
   ```
   Copy domain từ output (ví dụ: `abc123.ngrok-free.dev`)

6. **Cấu hình Flutter App**
   - Mở file `android_app/.env`
   - Cập nhật:
     ```env
     CONNECTION_MODE=ngrok
     NGROK_DOMAIN=abc123.ngrok-free.dev
     NGROK_PROTOCOL=https
     ```

7. **Build và chạy**
   ```bash
   cd android_app
   flutter run          # Máy ảo
   # hoặc
   flutter build apk    # Điện thoại thật
   ```

**Kết quả:** App hoạt động trên cả máy ảo và điện thoại thật với một cấu hình! 🎉

### Workflow Hàng ngày

1. Chạy backend: `cd api && dotnet run`
2. Chạy ngrok: `ngrok http 5134` (terminal mới)
3. Cập nhật `.env` nếu domain ngrok thay đổi
4. Chạy Flutter app: `cd android_app && flutter run`

**Lưu ý:** Với ngrok free plan, domain sẽ thay đổi mỗi khi restart. Chỉ cần cập nhật `NGROK_DOMAIN` trong `.env`.

## 📁 Cấu trúc dự án

```
Do_an_android/
├── api/                          # Backend API (.NET)
│   ├── Controllers/              # API Controllers
│   │   ├── AuthController.cs
│   │   ├── PostController.cs
│   │   ├── ChatController.cs
│   │   ├── AppointmentController.cs
│   │   └── ...
│   ├── Models/                   # Entity models
│   │   ├── User.cs
│   │   ├── Post.cs
│   │   ├── Appointment.cs
│   │   └── ...
│   ├── Services/                 # Business logic
│   │   ├── IAppointmentService.cs
│   │   ├── StreamChatService.cs
│   │   └── ...
│   ├── DTOs/                     # Data Transfer Objects
│   ├── Hubs/                     # SignalR Hubs
│   │   ├── NotificationHub.cs
│   │   └── MessageHub.cs
│   ├── Migrations/               # EF Core migrations
│   └── Program.cs               # Startup configuration
│
├── android_app/                  # Flutter Mobile App
│   ├── lib/
│   │   ├── config/              # App configuration
│   │   │   └── app_config.dart
│   │   ├── core/                # Core functionality
│   │   │   ├── models/          # Data models
│   │   │   ├── repositories/    # API repositories
│   │   │   ├── services/        # Services (SignalR, Auth)
│   │   │   └── network/         # HTTP client
│   │   └── presentation/        # UI layer
│   │       ├── screens/        # App screens
│   │       └── widgets/        # Reusable widgets
│   ├── assets/                  # Images, fonts
│   ├── ENV_TEMPLATE.txt         # Environment template
│   └── pubspec.yaml            # Dependencies
│
└── client/                      # React Web Client
    ├── src/
    │   ├── pages/              # Page components
    │   ├── components/         # Reusable components
    │   └── api/                # API clients
    └── package.json
```

## 📚 API Documentation

Sau khi chạy backend, truy cập Swagger UI:
```
http://localhost:5134/swagger
```

### Các Endpoints chính

#### Authentication
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/refresh` - Refresh token

#### Posts
- `GET /api/posts` - Lấy danh sách bài đăng
- `GET /api/posts/{id}` - Chi tiết bài đăng
- `POST /api/posts` - Tạo bài đăng mới
- `PUT /api/posts/{id}` - Cập nhật bài đăng
- `DELETE /api/posts/{id}` - Xóa bài đăng

#### Appointments
- `POST /api/appointments` - Tạo lịch hẹn
- `GET /api/appointments/pending` - Lấy lịch hẹn chờ xác nhận
- `POST /api/appointments/{id}/confirm` - Chấp nhận lịch hẹn
- `POST /api/appointments/{id}/reject` - Từ chối lịch hẹn

#### Chat (Stream Chat)
- `POST /api/chat/token` - Lấy Stream Chat token
- `POST /api/chat/channel` - Tạo/lấy channel
- `POST /api/chat/ensure-users` - Đảm bảo users tồn tại trong Stream
- `DELETE /api/chat/channels/{type}/{id}` - Xóa channel

#### Notifications
- `GET /api/notifications` - Lấy danh sách thông báo
- `PUT /api/notifications/{id}/read` - Đánh dấu đã đọc

#### SignalR Hubs
- `/notificationHub` - Real-time notifications
- `/messageHub` - Real-time messages (legacy, đã thay bằng Stream Chat)

## 🔄 Development Workflow

### 1. Khởi động Development Environment

```bash
# Terminal 1: Backend
cd api
dotnet run

# Terminal 2: Ngrok (nếu dùng ngrok)
ngrok http 5134

# Terminal 3: Flutter App
cd android_app
flutter run

# Terminal 4: Web Client (nếu cần)
cd client
npm run dev
```

### 2. Database Migrations

```bash
cd api

# Tạo migration mới
dotnet ef migrations add MigrationName

# Áp dụng migration
dotnet ef database update

# Xem migrations đã áp dụng
dotnet ef migrations list
```

### 3. Testing

```bash
# Flutter tests
cd android_app
flutter test

# Backend tests (nếu có)
cd api
dotnet test
```

## 🐛 Troubleshooting

### Backend không chạy được

**Lỗi:** Connection string không đúng
```bash
# Kiểm tra appsettings.json hoặc appsettings.Development.json
# Đảm bảo connection string đúng với SQL Server của bạn
```

**Lỗi:** Port đã được sử dụng
```bash
# Đổi port trong Properties/launchSettings.json
# hoặc kill process đang dùng port 5134
```

### Flutter App không kết nối được Backend

**Lỗi:** Connection refused
- Kiểm tra backend có đang chạy không
- Kiểm tra `NGROK_DOMAIN` trong `.env` có đúng không
- Kiểm tra ngrok có đang chạy không (truy cập http://127.0.0.1:4040)

**Lỗi:** Build failed
```bash
# Clean và rebuild
cd android_app
flutter clean
flutter pub get
flutter run
```

### SignalR không kết nối được

- Kiểm tra backend có bind với `0.0.0.0:5134` không
- Kiểm tra CORS có cho phép ngrok domain không
- Kiểm tra token có hợp lệ không

### Stream Chat không hoạt động

- Kiểm tra Stream API Key và Secret trong `appsettings.json`
- Kiểm tra webhook URL trong Stream dashboard
- Kiểm tra webhook signature validation

## 📝 Environment Variables

### Backend (`appsettings.json`)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=...;Database=...;..."
  },
  "JwtSettings": {
    "SecretKey": "...",
    "Issuer": "...",
    "Audience": "..."
  },
  "StreamChat": {
    "ApiKey": "...",
    "ApiSecret": "..."
  },
  "OpenAI": {
    "ApiKey": "..."
  }
}
```

### Flutter (`android_app/.env`)

Xem file `android_app/ENV_TEMPLATE.txt` để biết các biến môi trường cần thiết.

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📄 License

[Thêm license của bạn ở đây]

## 👥 Authors

[Thêm tên tác giả ở đây]

## 🙏 Acknowledgments

- Stream Chat cho chat infrastructure
- OpenAI cho AI features
- Flutter team cho framework tuyệt vời
- .NET team cho backend framework

---

**Made with ❤️ by Real Estate Hub Team**
