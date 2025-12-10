## Mục Tiêu
- Duy trì brand và phong cách hiện có (màu, typography, bố cục).
- Nâng chất lượng UI/UX: nhất quán component, visual hierarchy, accessibility, responsive, hiệu suất.

## Cơ Sở Thiết Kế Hiện Có
- Màu: dùng `AppColors` (accent xanh ngọc, surface/background, text/secondary) — `lib/core/theme/app_colors.dart`.
- Typography: dùng Inter qua `AppTextStyles` và `AppTheme.textTheme` — `lib/core/theme/app_text_styles.dart`, `lib/core/theme/app_theme.dart`.
- Bóng/đổ: `AppShadows` cho card/button/sheet — `lib/core/theme/app_shadows.dart`.
- Component nền tảng: `AppButton`, `PropertyCard`, pill/chip, thẻ thông tin — đảm bảo kế thừa theme.

## Lộ Trình Thực Hiện
1) Phân Tích & Xác Định Cải Tiến
- Rà soát các màn chính: `home`, `search`, `post_details`, `notification`, `profile`.
- Kiểm tra sự nhất quán về spacing (8/12/16/20), bo góc (12/14/16), palette, font weight.
- Lập danh sách lệch chuẩn (nút lẫn lộn kiểu, shadow không thống nhất, text tone chưa đúng…).

2) Thiết Kế Thành Phần Theo Style Guide
- Chuẩn hóa design tokens: màu, typography, spacing, radius, shadow (tận dụng `AppColors`, `AppTextStyles`, `AppShadows`).
- Chuẩn hóa component core:
  - Buttons: dùng `AppButton` cho CTA chính/phụ; trạng thái hover/focus/disabled đồng bộ.
  - Pills/Chips/Badges: dùng chip theme, icon size 16–20, label `labelMedium`.
  - Cards: thống nhất surface, radius 16, `AppShadows.card`, nội dung có hệ thứ bậc rõ.
  - Info rows: mẫu key–value cho phần “Chi tiết”.
- Áp dụng visual hierarchy: tiêu đề h4/h5, giá `priceLarge`, mô tả `bodyMedium` màu `textSecondary`.

3) Triển Khai Theo Module
- Post Details: đã refactor theo layout tham khảo (hero ảnh, giá nổi bật, hàng tính năng, block “Chi tiết” với modal “Xem thêm”). Tiếp tục tinh chỉnh features và chia nhóm thông tin.
- Search Results & Home:
  - Thống nhất `PropertyCard` (badge trạng thái, badge giá, hàng tính năng).
  - Thêm thanh lọc/sắp xếp consistent với chip theme.
- Notifications & Profile:
  - Đồng bộ spacing, radius, tone văn bản, icon theme.
- Widgets chung:
  - Chuẩn hoá `AppButton`, pill, info row, empty state, loading.

4) Accessibility
- Tương phản màu đáp ứng WCAG AA (kiểm tra accent trên nền trắng và textSecondary trên surface).
- Tăng tap target >= 44px, `Semantics` cho icon-only buttons (yêu thích, chia sẻ).
- Focus states rõ ràng cho web/desktop; hỗ trợ `MouseRegion` + `Focus`.

5) Responsive
- Dùng grid/Wrap responsive cho quick stats, chặn tràn nhãn dài; kiểm soát breakpoints nhỏ (<360), chuẩn (360–600), lớn (>600).
- Ảnh: `CachedNetworkImage` với `fit: cover`, placeholder shimmer.

6) Hiệu Suất
- Tránh overdraw: surface/variant đúng chỗ; reuse widgets; lazy lists (`ListView.builder`).
- Tối ưu ảnh: chiều cao hợp lý, cache.
- Giữ animations nhẹ (Hero, indicator) — không gây jank.

7) Tích Hợp MCP Figma
- Nhận `fileKey` và (tuỳ chọn) `nodeId` của file Figma.
- Bước thực hiện:
  - Đồng bộ tokens Figma → `AppColors`, `AppTextStyles` (đối chiếu tên biến, không đổi brand).
  - Xuất icon/vector cần thiết (SVG/PNG) vào `assets/` và cập nhật `pubspec.yaml`.
  - Lấy layout tham khảo các section (card/detail/features) để tinh chỉnh spacing và ratio.

## Kiểm Thử
- Phân tích/lint: `flutter analyze` không lỗi.
- Responsive thực tế: chạy trên `Android`, `Windows`, `Chrome` với resize theo breakpoint.
- Cross-browser desktop/web: kiểm tra hover/focus, modal, scrolling.
- Trải nghiệm người dùng: kịch bản xem chi tiết, tìm kiếm, yêu thích, liên hệ (email/phone).

## Bàn Giao & Đo Lường
- Pull request theo module; screenshot trước/sau.
- Checklist accessibility/consistency.
- Hiệu suất: đo thời gian render trang và tỉ lệ lỗi ảnh.

## Yêu Cầu/Đầu Vào Cần Bạn Xác Nhận
- Cung cấp Figma `fileKey` (và `nodeId` nếu muốn chỉ định màn) để đồng bộ tokens và xuất icon.
- Cho biết màn ưu tiên (ví dụ: Home, Search, Details, Notifications) để triển khai trước.

## Kế Hoạch Triển Khai (Từng Bước)
1) Chuẩn hoá tokens và button/pill/card.
2) Hoàn thiện Post Details theo tham khảo, tinh chỉnh Features/Details.
3) Áp dụng cho Home/Search Results.
4) Đồng bộ Notifications/Profile.
5) Kiểm thử responsive + accessibility; rà lint; chụp ảnh so sánh.

Xác nhận kế hoạch trên và gửi `fileKey` Figma để tôi bắt đầu.