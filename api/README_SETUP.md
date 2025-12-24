# Hướng dẫn Setup API

## ⚠️ QUAN TRỌNG: Cấu hình môi trường

1. **Sao chép file cấu hình mẫu:**
   ```bash
   cp appsettings.example.json appsettings.json
   cp appsettings.example.json appsettings.Development.json
   ```

2. **Điền thông tin nhạy cảm vào `appsettings.json`:**
   - JWT Key: Tạo một key bảo mật ngẫu nhiên (tối thiểu 32 ký tự)
   - Connection String: Cập nhật tên server và database của bạn
   - Vnpay: Điền TmnCode và HashSecret từ tài khoản Vnpay của bạn
   - MomoAPI: Điền SecretKey và AccessKey từ tài khoản Momo của bạn
   - StreamChat: Điền ApiKey và ApiSecret từ Stream Chat
   - AI: Điền ApiKey từ OpenRouter

3. **Đảm bảo file `appsettings.json` đã được thêm vào `.gitignore`**

## Cài đặt và chạy

```bash
dotnet restore
dotnet ef database update
dotnet run
```

API sẽ chạy tại: `http://localhost:5134`

