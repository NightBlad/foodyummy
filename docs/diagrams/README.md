# FoodyYummy - Use Case Documentation

## Tổng quan
Biểu đồ Use Case tổng quát cho ứng dụng FoodyYummy mô tả các chức năng chính của hệ thống từ góc độ người dùng. Biểu đồ tuân thủ chuẩn UML và thể hiện sự tương tác giữa các actor (User và Admin) với các chức năng của hệ thống.

## Actors (Tác nhân)

### 1. User (Người dùng)
- **Mô tả**: Người dùng thông thường của ứng dụng FoodyYummy
- **Vai trò**: Sử dụng ứng dụng để tìm kiếm, xem, tạo và quản lý công thức nấu ăn cá nhân
- **Quyền hạn**: Truy cập các chức năng cơ bản của ứng dụng

### 2. Admin (Quản trị viên)
- **Mô tả**: Người quản lý và điều hành hệ thống FoodyYummy
- **Vai trò**: Quản lý hệ thống, người dùng và nội dung
- **Quyền hạn**: Có tất cả quyền của User plus các quyền quản trị
- **Kế thừa**: Admin kế thừa từ User (Admin --|> User)

## Use Cases cho User

### 1. Account Management (Quản lý tài khoản)

#### Register/Login (Đăng ký/Đăng nhập)
- **Mô tả**: Người dùng tạo tài khoản mới hoặc đăng nhập vào hệ thống
- **Tiền điều kiện**: Không có
- **Hậu điều kiện**: Người dùng được xác thực và có thể truy cập hệ thống
- **Luồng chính**:
  1. Người dùng chọn đăng ký hoặc đăng nhập
  2. Nhập thông tin yêu cầu (email, mật khẩu, họ tên cho đăng ký)
  3. Hệ thống xác thực thông tin
  4. Cấp quyền truy cập cho người dùng

#### Update Profile (Cập nhật thông tin cá nhân)
- **Mô tả**: Người dùng chỉnh sửa thông tin cá nhân
- **Tiền điều kiện**: Đã đăng nhập
- **Hậu điều kiện**: Thông tin cá nhân được cập nhật
- **Mối quan hệ**: Include từ Register/Login

### 2. Search and View Content (Tìm kiếm và xem nội dung)

#### Search Recipes (Tìm kiếm công thức)
- **Mô tả**: Tìm kiếm công thức theo từ khóa, nguyên liệu hoặc danh mục
- **Tiền điều kiện**: Đã đăng nhập
- **Hậu điều kiện**: Hiển thị danh sách công thức phù hợp

#### View Recipe Details (Xem chi tiết công thức)
- **Mô tả**: Xem thông tin chi tiết của một công thức cụ thể
- **Tiền điều kiện**: Đã đăng nhập
- **Hậu điều kiện**: Hiển thị đầy đủ thông tin công thức

#### Filter and Sort (Lọc và sắp xếp)
- **Mô tả**: Áp dụng bộ lọc và sắp xếp kết quả tìm kiếm
- **Tiền điều kiện**: Đang ở trang tìm kiếm
- **Hậu điều kiện**: Kết quả được lọc/sắp xếp theo tiêu chí
- **Mối quan hệ**: Extend từ Search Recipes

### 3. Personal Recipe Management (Quản lý công thức cá nhân)

#### Create Recipe (Tạo công thức mới)
- **Mô tả**: Người dùng tạo công thức nấu ăn mới
- **Tiền điều kiện**: Đã đăng nhập
- **Hậu điều kiện**: Công thức mới được lưu vào hệ thống
- **Mối quan hệ**: Include Search Recipes (để tham khảo công thức khác)

#### Edit Recipe (Chỉnh sửa công thức)
- **Mô tả**: Chỉnh sửa công thức do chính mình tạo
- **Tiền điều kiện**: Đã đăng nhập và là chủ sở hữu công thức
- **Hậu điều kiện**: Công thức được cập nhật
- **Mối quan hệ**: Include View Recipe Details

#### Delete Recipe (Xóa công thức)
- **Mô tả**: Xóa công thức do chính mình tạo
- **Tiền điều kiện**: Đã đăng nhập và là chủ sở hữu công thức
- **Hậu điều kiện**: Công thức bị xóa khỏi hệ thống

### 4. Social Interactions (Tương tác xã hội)

#### Rate Recipe (Đánh giá công thức)
- **Mô tả**: Cho điểm và đánh giá công thức của người khác
- **Tiền điều kiện**: Đã đăng nhập và xem chi tiết công thức
- **Hậu điều kiện**: Đánh giá được lưu
- **Mối quan hệ**: Extend từ View Recipe Details

#### Comment on Recipe (Bình luận công thức)
- **Mô tả**: Viết bình luận cho công thức
- **Tiền điều kiện**: Đã đăng nhập và xem chi tiết công thức
- **Hậu điều kiện**: Bình luận được hiển thị
- **Mối quan hệ**: Extend từ View Recipe Details

#### Favorite Recipe (Yêu thích công thức)
- **Mô tả**: Thêm công thức vào danh sách yêu thích
- **Tiền điều kiện**: Đã đăng nhập
- **Hậu điều kiện**: Công thức được thêm vào danh sách yêu thích

## Use Cases cho Admin

### 1. System Management (Quản lý hệ thống)

#### System Configuration (Cấu hình hệ thống)
- **Mô tả**: Điều chỉnh các thiết lập và cấu hình của hệ thống
- **Tiền điều kiện**: Đã đăng nhập với quyền admin
- **Hậu điều kiện**: Hệ thống được cấu hình theo yêu cầu

#### View Statistics (Xem thống kê)
- **Mô tả**: Xem các báo cáo và thống kê về hoạt động của hệ thống
- **Tiền điều kiện**: Đã đăng nhập với quyền admin
- **Hậu điều kiện**: Hiển thị các báo cáo thống kê

### 2. User Management (Quản lý người dùng)

#### Manage User Accounts (Quản lý tài khoản người dùng)
- **Mô tả**: Xem, chỉnh sửa, khóa/mở khóa tài khoản người dùng
- **Tiền điều kiện**: Đã đăng nhập với quyền admin
- **Hậu điều kiện**: Tài khoản người dùng được quản lý theo yêu cầu

#### Manage Permissions (Quản lý phân quyền)
- **Mô tả**: Cấp hoặc thu hồi quyền của người dùng
- **Tiền điều kiện**: Đã đăng nhập với quyền admin
- **Hậu điều kiện**: Quyền hạn người dùng được cập nhật

### 3. Content Management (Quản lý nội dung)

#### Review Recipes (Kiểm duyệt công thức)
- **Mô tả**: Xem xét và phê duyệt/từ chối công thức do người dùng tạo
- **Tiền điều kiện**: Đã đăng nhập với quyền admin
- **Hậu điều kiện**: Công thức được phê duyệt hoặc từ chối

#### Manage Categories (Quản lý danh mục)
- **Mô tả**: Tạo, chỉnh sửa, xóa các danh mục công thức
- **Tiền điều kiện**: Đã đăng nhập với quyền admin
- **Hậu điều kiện**: Danh mục được quản lý theo yêu cầu

## Mối quan hệ trong Use Case Diagram

### Include Relationships
- **Register/Login** include **Update Profile**: Sau khi đăng ký/đăng nhập, người dùng có thể cập nhật thông tin
- **Create Recipe** include **Search Recipes**: Khi tạo công thức mới, có thể tham khảo công thức khác
- **Edit Recipe** include **View Recipe Details**: Để chỉnh sửa cần xem chi tiết công thức trước

### Extend Relationships
- **Filter and Sort** extend **Search Recipes**: Chức năng mở rộng cho tìm kiếm
- **Comment on Recipe** extend **View Recipe Details**: Bình luận là chức năng mở rộng khi xem chi tiết
- **Rate Recipe** extend **View Recipe Details**: Đánh giá là chức năng mở rộng khi xem chi tiết

### Inheritance
- **Admin** inherits from **User**: Admin có tất cả quyền của User plus quyền quản trị

## Đặc điểm của Use Case Diagram này

1. **Tuân thủ chuẩn UML**: Sử dụng đúng ký hiệu và cấu trúc UML
2. **Mức độ tổng quát**: Các Use Case ở mức high-level, không quá chi tiết
3. **Phân tách rõ ràng**: Có sự phân biệt rõ ràng giữa User và Admin
4. **Mối quan hệ phù hợp**: Sử dụng include, extend và inheritance hợp lý
5. **Bao quát đầy đủ**: Bao gồm tất cả chức năng chính của ứng dụng FoodyYummy