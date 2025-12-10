## Mục tiêu
- Nâng cấp màn hình hồ sơ cá nhân theo mẫu (ảnh 1) nhưng giữ phong cách dự án hiện tại (ảnh 2).
- Bao gồm: thông tin cơ bản, ảnh đại diện, các trường chi tiết, nút chỉnh sửa/cập nhật; hiệu ứng mượt, responsive, và nhất quán với hệ thống thiết kế.

## Bối cảnh mã hiện tại
- Màn hình hiện tại: `lib/presentation/screens/user/profile_screen.dart` hiển thị avatar, tên, email, thống kê và menu ListTile. Logic tải dữ liệu: `_loadProfileData` với `UserRepository`, `PostRepository`, `FavoriteRepository`.
- Điểm cần cải thiện: bố cục một cột, khoảng cách/typography chưa theo token, thiếu hiệu ứng/hover và dark mode; menu đơn điệu; không có phần "Giới thiệu" và danh sách bài đăng như tham chiếu.

## Quy trình MCP Figma
1. Thiết lập file Figma cho Profile (yêu cầu `fileKey`/`nodeId`).
2. Tạo Component Library chuyên cho Profile với variants (Light/Dark, Mobile/Tablet/Web).
3. Chuẩn hóa tokens (màu, typographic scale, radius, shadow) để khớp `AppColors`, `AppTextStyles`, `AppShadows`.
4. Xuất icon/illustration cần thiết qua cầu MCP, lưu vào `assets/icons/profile/`.
5. Tạo prototype tương tác (hover, transition, bottom sheet chỉnh sửa).

## Thư viện component Profile
- ProfileHeader: avatar (hero), tên, email, badge/role, nút "Chỉnh sửa"; hỗ trợ thay avatar.
- StatPillGrid: lưới thống kê (Yêu thích/Lịch hẹn/Bài đăng) với chip viền và hiệu ứng hover (web/desktop).
- ProfileAbout: khối "Giới thiệu" có nút "Đọc thêm" dạng modal bottom sheet.
- ProfileListings: danh sách bài đăng của người dùng (sử dụng `PropertyCard` đã chuẩn hóa).
- ProfileMenuSection: nhóm menu (Yêu thích, Lịch hẹn, Quản lý bài đăng, Thông báo, Cài đặt) với icon + mũi tên, phân nhóm bằng divider mềm.
- EditCTA: cụm nút `AppButton` (Chỉnh sửa/Cập nhật), variants outlined/solid.
- AvatarPicker: thành phần chọn/cập nhật ảnh, re-usable cho `edit_profile_screen.dart`.

## Bố cục màn hình
- CustomScrollView với `SliverAppBar` tiêu đề "Hồ sơ" và actions (Cài đặt).
- Sliver list: ProfileHeader → StatPillGrid → ProfileAbout → ProfileListings (tối đa 3 item + link Xem tất cả) → ProfileMenuSection → EditCTA.
- Khoảng cách 20/16, radius 16, shadow `AppShadows.card` đồng nhất.

## Hiệu ứng & Transition
- Hero cho avatar, AnimatedSwitcher cho thống kê, InkWell ripple + hover (web/desktop) trên pill/menu, modal bottom sheet với `RoundedRectangleBorder(top: 20)`, subtle elevation transitions.

## Responsive & Dark mode
- LayoutBuilder xác định cột của StatPillGrid: 2/3/4 theo `maxWidth`.
- Typography dùng `AppTextStyles`; màu dùng `AppColors` và `Theme.of(context).colorScheme` để auto dark.
- Touch target ≥48px, Semantics/tooltip cho icon-only.

## Tích hợp dữ liệu
- Tái sử dụng `_loadProfileData` và repo sẵn có, giữ `RefreshIndicator`.
- Thêm `About` từ trường profile (nếu chưa có, fallback hiển thị gợi ý điền thông tin).
- Listings lấy từ `PostRepository.getPostsByUser` và hiển thị bằng `PropertyCard`.

## Các bước triển khai mã
1. Tạo thư mục `lib/presentation/widgets/profile/` và thêm các widget: `profile_header.dart`, `stat_pill_grid.dart`, `profile_about.dart`, `profile_menu_section.dart`, `profile_listings.dart`, `edit_cta.dart`, `avatar_picker.dart`.
2. Refactor `lib/presentation/screens/user/profile_screen.dart` để dùng các widget mới, đổi sang `CustomScrollView + SliverAppBar`.
3. Cập nhật `edit_profile_screen.dart` để dùng `AvatarPicker` và `AppButton` thống nhất.
4. Thêm bottom sheet cho “Giới thiệu” và dialog xác nhận khi cập nhật thông tin.
5. Kết nối Figma: đồng bộ tokens, xuất icon/avatar placeholder qua MCP.
6. Viết test UI cơ bản cho layout/responsive (golden/baseline snapshot nếu có hạ tầng) và chạy `flutter analyze`.

## Deliverables
- Bộ component Profile re-usable + màn hình Profile nâng cấp.
- Prototype Figma tương tác (Light/Dark, Mobile/Web).
- Tài sản icon được xuất sang `assets/icons/profile/`.

## Đánh giá & xác minh
- So sánh thẩm mỹ với ảnh 1: bố cục rõ ràng, khoảng cách/typography nhất quán.
- Dễ dùng: hành động chỉnh sửa hiển thị nổi bật, menu truy cập nhanh.
- Mở rộng: component-based, hỗ trợ variants.
- Consistency: dùng AppTokens đã chuẩn hoá.

## Yêu cầu xác nhận
- Cung cấp `fileKey`/`nodeId` Figma để đồng bộ tự động. Nếu chưa có, tôi sẽ tiến hành phần mã với tokens hiện tại và tạo file Figma mới, sau đó gửi link để duyệt.