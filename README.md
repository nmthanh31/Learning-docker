# Material Dashboard Shadcn – Material Design from Creative Tim with shadcn/ui components.
#### Preview

 - [Demo](https://themewagon.github.io/material-shadcn/)

#### Download
 - [Download from ThemeWagon](https://themewagon.com/themes/material-shadcn/)

## Getting Started

1. Clone Repository
```
git clone https://github.com/themewagon/material-shadcn.git
```
2. Install Dependencies
```
npm i
```
3. Run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

## Author 
```
Design and code is completely written by Creative Tim and development team. 
```

## 🚀 Hướng dẫn Triển khai (Docker & Nginx)

Dự án này được tối ưu hóa để triển khai dưới dạng một ứng dụng web tĩnh (SPA) được bảo mật và tối ưu hiệu suất thông qua Nginx bên trong Docker.

### 1. Chi tiết Dockerfile (Multi-stage Build)

Dockerfile được chia làm 2 giai đoạn để giảm kích thước image cuối cùng và tăng tính bảo mật.

#### **Giai đoạn 1: Build Stage (`builder`)**
- `FROM node:20-alpine`: Sử dụng Node.js phiên bản 20 trên nền Alpine Linux (siêu nhẹ).
- `npm ci`: Cài đặt các package dựa chính xác trên file `package-lock.json`, đảm bảo môi trường build nhất quán.
- `npm run build`: Biên dịch mã nguồn React/TypeScript thành các file tĩnh (HTML, JS, CSS) trong thư mục `dist/public`.

#### **Giai đoạn 2: Runtime Stage**
- `FROM nginx:1.25-alpine`: Sử dụng máy chủ Nginx phiên bản 1.25 (Alpine).
- **Security Check**: 
    - `rm /etc/nginx/conf.d/default.conf`: Xóa cấu hình mặc định của Nginx để tránh lộ thông tin hoặc xung đột.
    - `chown -R nginx:nginx ...`: Phân quyền cho user `nginx` (không có quyền root) quản lý các thư mục cần thiết.
- **Copy Config**: Copy các file cấu hình Nginx tùy chỉnh từ thư mục `nginx/` vào container.
- **Copy Static Files**: Copy kết quả build từ giai đoạn 1 vào thư mục `/usr/share/nginx/html`.
- `USER nginx`: Chạy container với user quyền thấp để tăng cường bảo mật.

#### **Cơ chế Healthcheck**
Dockerfile bao gồm một lệnh kiểm tra sức khỏe thông minh:
1. Tìm một file `.js` bất kỳ trong assets.
2. Tính toán mã SHA256 của file đó trên ổ đĩa.
3. Dùng `wget` tải chính file đó thông qua localhost.
4. So sánh hai mã SHA. Nếu khớp nghĩa là Nginx đang phục vụ file đúng cách.

---

### 2. Cấu hình Nginx chi tiết

#### **Cấu hình chung (`nginx.conf`)**
- `worker_processes auto`: Tự động điều chỉnh số lượng tiến trình dựa trên số nhân CPU.
- `sendfile on & tcp_nopush on`: Tối ưu hóa việc truyền gửi file tĩnh, giảm tải cho CPU.
- `gzip on`: Nén dữ liệu (text/css/js) trước khi gửi về trình duyệt, giúp tăng tốc độ tải trang đáng kể.
- `open_file_cache`: Lưu bộ nhớ đệm thông tin các file thường dùng để giảm truy xuất ổ đĩa.

#### **Cấu hình ứng dụng (`conf.d/app.conf`)**
- **Rate Limiting**: `limit_req_zone ... rate=10r/s` - Giới hạn mỗi IP chỉ được gửi tối đa 10 yêu cầu/giây để ngăn chặn tấn công Brute-force hoặc DDOS đơn giản.
- **Security Headers**:
    - `X-Frame-Options: SAMEORIGIN`: Chống tấn công Clickjacking.
    - `X-Content-Type-Options: nosniff`: Ngăn trình duyệt tự ý đoán định kiểu file (MIME type sniffing).
- **Method Limit**: Chỉ cho phép `GET` và `HEAD`. Các yêu cầu `POST`, `DELETE`,... sẽ bị từ chối với lỗi 405 (trừ khi bạn mở rộng thêm API).
- **Caching Strategy**:
    - **Hashed Assets (JS/CSS)**: Cache vĩnh viễn (1 năm) vì các file này có hash trong tên, nếu thay đổi thì tên sẽ khác.
    - **index.html**: Không cache (`no-cache`), luôn yêu cầu trình duyệt kiểm tra phiên bản mới nhất từ server.
- **SPA Routing (Quan trọng nhất)**:
    - `try_files $uri $uri/ @spa`: Nginx sẽ tìm file theo đường dẫn. Nếu không thấy, nó sẽ chuyển sang block `@spa`.
    - `location @spa { rewrite ^ /index.html break; }`: Chuyển tất cả các đường dẫn không tồn tại về `index.html`. Điều này rất quan trọng cho React Router để xử lý routing phía client mà không bị lỗi 404 khi tải lại trang.

---

### 3. Luồng hoạt động (Traffic Flow)

1. **Yêu cầu**: Người dùng truy cập `http://your-domain/profile`.
2. **Nginx tiếp nhận**: Kiểm tra IP có vượt mức 10 requests/s không. Tiếp tục kiểm tra nếu là phương thức `GET`.
3. **Tìm kiếm file**: Nginx tìm file `/profile` trong thư mục `/usr/share/nginx/html`.
4. **Xử lý SPA**: Vì không có file vật lý nào tên là `profile`, Nginx rơi vào block `@spa` và trả về nội dung file `index.html`.
5. **Client Rendering**: Trình duyệt nhận `index.html`, tải file JS của React. React Router thấy URL là `/profile` và hiển thị component tương ứng cho người dùng.


