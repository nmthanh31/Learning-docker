# Giải thích chi tiết từng dòng cấu hình Docker và Nginx

Dưới đây là phần giải nghĩa từng dòng một (line-by-line) cho các file cấu hình được sử dụng trong dự án.

## 1. File `nginx/nginx.conf`
Đây là file cấu hình gốc của Nginx.

```nginx
worker_processes auto;
# Tự động xác định và cấp phát số lượng worker process bằng với số luồng (cores) của CPU.

events {
    worker_connections 1024;
    # Mỗi worker process ở trên có thể xử lý tối đa 1024 kết nối (clients/requests) cùng một lúc.
}

http {
    include       mime.types;
    # Nạp danh sách các kiểu định dạng file (ví dụ: .html là text/html, .css là text/css).
    
    default_type  application/octet-stream;
    # Nếu Nginx không nhận diện được loại file, nó sẽ gán kiểu mặc định này (thường trình duyệt sẽ tải file về thay vì hiển thị).

    sendfile on;
    # Bật tính năng truyền file tĩnh tối ưu. Cho phép hệ điều hành (Kernel) gửi thẳng data từ ổ cứng ra card mạng, bỏ qua bộ nhớ của ứng dụng Nginx.
    
    tcp_nopush on;
    # (Đi kèm với sendfile). Nginx sẽ gộp các gói tin nhỏ lại thành gói lớn rồi mới gửi đi một lần, giúp tối ưu băng thông và giảm nghẽn mạng.

    server_tokens off;
    # Ẩn số liệu về phiên bản Nginx trong HTTP Header trả về (ví dụ không hiện "Server: nginx/1.29"), tránh bị hacker dò các lỗ hổng theo version.

    # Gzip
    gzip on;
    # Bật tính năng nén file trước khi gửi cho client, giúp giảm dung lượng băng thông mạng.
    
    gzip_vary on;
    # Thêm header `Vary: Accept-Encoding`. Giúp các proxy server trung gian biết rằng file này có thể được trả về ở dạng nén hoặc không nén.
    
    gzip_proxied any;
    # Cho phép Nginx phản hồi file nén dữ liệu qua mọi Proxy.
    
    gzip_comp_level 5;
    # Mức độ nén từ 1 đến 9. Mức 5 là mức tối ưu nhất (cân bằng giữa việc tiết kiệm CPU của server và tỷ lệ nén).
    
    gzip_types
        text/plain text/css application/json application/javascript application/xml+rss image/svg+xml;
    # Chỉ định đích danh các loại file có thể đem đi nén. Ví dụ: JS, CSS, JSON. Ở đây Cố tình không nén ảnh PNG/JPG vì bản chất chúng đã được file gốc nén.

    # File cache
    open_file_cache max=1000 inactive=30s;
    # Lưu vào RAM (cache) của Server thông tin của tối đa 1000 file descriptors. Dọn rác khỏi cache nếu file không được hệ thống gọi trong 30 giây rưỡi.
    
    open_file_cache_valid 60s;
    # Cứ sau 60 giây nginX sẽ lôi ra check lại xem các file này nội dung có còn đúng không hay bị gỡ rồi.
    
    open_file_cache_min_uses 2;
    # Số lần "cần xem" đủ để Nginx thấy quan trọng nên đưa lên Cache RAM (ở đây file bị truy vấn ít nhất 2 lần).
    
    etag on;
    # Bật header ETag, giúp trình duyệt nhận biết file tĩnh đã thay đổi cấu trúc chưa.

    # Disable directory listing
    autoindex off;
    # Không hiện rải rác danh sách từng file như một thư mục ftp trên máy tính, gây lộ thư mục của Source tĩnh.

    include /etc/nginx/conf.d/*.conf;
    # Include các file .conf ảo vào hệ tổng.
}
```

## 2. File `nginx/conf.d/app.conf`
Cấu hình giao tiếp HTTP cụ thể của ứng dụng.

```nginx
server {
    listen 80;
    # Nginx mở port 80 để lắng nghe HTTP Request ở client.
    
    server_name localhost;
    # Domain mặc định quy ước cấu hình này là dùng cho server localhost.

    root /usr/share/nginx/html;
    # Đường dẫn thư mục vật lý chứa file static của web ở stage production này.
    
    index index.html;
    # Nạp file đầu nếu user tìm theo directory path.

    # ===== SECURITY =====
    add_header X-Content-Type-Options "nosniff" always;
    # Ngăn trình duyệt cố gắng "tự động đoán" định dạng mime type, ngăn chặn mã độc nhúng vào payload khác.
    
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    # Chỉ gửi thông tin Header Referer khi link qua domain cross-origin là giao thức mã hóa HTTPS.
    
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
    # Khóa sạch quyền xin Permission truy cập Camera/ Mic từ Browser (rất chuẩn chỉ ở project này).

    # ===== BLOCK SOURCE MAP =====
    location ~* \.map$ {
        deny all;
    }
    # Response từ chối toàn phần đối với URL xin xin resource .map của JS.

    # Method limit
    if ($request_method !~ ^(GET|HEAD)$ ) {
        return 405;
    }
    # Vì Frontend là tĩnh tệp tin, nếu API calls request Method là DELETE hoặc POST (Method sửa database backend), Nginx trả thẳng mã Lỗi 405 (không có quyền Method Allowed).

    # ===== HASHED ASSETS (IMMUTABLE) =====
    location ~* -[a-zA-Z0-9]+\.(js|css)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
        try_files $uri =404;
    }
    # Build của react có thư mục static như: main-a1b2c3.js. Lúc này yêu cầu browser nhớ tên cache vĩnh viễn là 1 năm (max config file), cho browser không cần hit load asset băm này.
    
    # ===== NON-HASHED JS/CSS =====
    location ~* \.(js|css)$ {
        add_header Cache-Control "public, max-age=300, must-revalidate";
        try_files $uri =404;
    }
    # Các file .css/ JS thường, config nhẹ 5 phút thôi (băt trình duyệt validate thay đổi sau 5').

    # ===== IMAGES =====
    location ~* \.(png|jpg|jpeg|gif|svg|ico)$ {
        add_header Cache-Control "public, max-age=300, must-revalidate";
        try_files $uri =404;
    }
    # Cache cho image 5 phút.

    # ===== INDEX.HTML =====
    location = /index.html {
        add_header Cache-Control "no-cache, must-revalidate";
    }
    # index.html là cửa ngõ gọi ra file react script (main hash JS trên). Nginx bắt ko được Cache index này để có bản index mới nhất có Link JS mới nhất.

    # ===== REAL 404 FILE =====
    location ~* \.(txt|log)$ {
        try_files $uri =404;
    }
    # Đối với txt/log tìm ko thấy trên thư mục Nginx thì 404 file thực luôn.

    # ===== SPA ROUTING =====
    location / {
        try_files $uri $uri/ @spa;
    }
    # Khi user vào \login, Nginx không thể trả file \login, do đó ngầm routing về @spa .

    # ===== SPA FALLBACK =====
    location @spa {
        add_header Cache-Control "no-cache, must-revalidate";
        rewrite ^ /index.html break;
    }
    # Đây là block ảo, mọi request không tồn tại tự được gõ đè lại về trang gốc `index.html`. Browser SPA (VD: browser-router react-dom) sẽ làm nốt công việc routing nội tại React.
}
```

## 3. File `Dockerfile`
File dùng thuật toán biên dịch vùng (Multi-Stage Build).

```dockerfile
# ===== BUILD STAGE =====
FROM node:20-alpine AS builder
# [Giai Đoạn 1] Lấy Node JS bản 20 lõi Alpine cực tối giản làm server Build. Đặt tên bí danh stage này là `builder`.

WORKDIR /app
# Directory ở máy ảo là /app

COPY package*.json ./
# Lưu cache package json version file cho stage này bằng cách Copy 1 mình chúng vào trước.
RUN npm ci
# Dùng "CI Clean Install", nhanh và chuẩn xác hơn npm i cho DevOps pipeline do đọc lock file chính xác.

COPY . .
# Sau khi cài NodeJS Modules thì chép source gốc của ta vào container này.
ENV GENERATE_SOURCEMAP=false
# Inject biến này cho Build tool (như Vite react vite config), tắt build generate ra map debug nhằm tăng độ nhỏ của folder và bảo mật.

RUN npm run build
# Script run package build của project thành file static, tự lưu folder `/app/dist/public`

# ===== RUNTIME STAGE =====
FROM nginx:1.29-alpine-slim
# [Giai Đoạn 2] Lấy lại 1 OS Nginx mới khác độc lập với cái image builder nodejs trên là `nginx:1.29-alpine-slim`. 

RUN rm /etc/nginx/conf.d/default.conf
# File nginX luôn thừa 1 cấu hình mặc định, cần xóa.

RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /usr/share/nginx/html
# Cắt bỏ quyền sở hữu phân cấp root ở service Nginx này, chia quyền quản trị toàn bộ cache nginx, file log nginx vào chủ sở hữu là người dùng tên nginx

COPY nginx/nginx.conf /etc/nginx/nginx.conf
# Copy file cài Nginx.conf của ta vào.
COPY nginx/conf.d /etc/nginx/conf.d
# Copy các File server name ảo (app.conf).

COPY --from=builder /app/dist/public /usr/share/nginx/html
# Hút toàn bộ khối rễ folder đã compile ở giai đoạn 1 (tức block alias `builder`) chép thành HTML chạy web Nginx.

USER nginx
# Set user của Container sau này là "nginx", thay vì là ROOT. Nhằm chống Hack container nếu Hacker exploit command chạy bash.

HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD sh -c '\
    FILE=$(find /usr/share/nginx/html/assets -type f -name "*.js" | head -n 1); \
    [ -f "$FILE" ] || exit 1; \
    NAME=$(basename "$FILE"); \
    DISK_SHA=$(sha256sum "$FILE" | cut -d" " -f1); \
    LIVE_SHA=$(wget -qO- http://127.0.0.1/assets/$NAME | sha256sum | cut -d" " -f1); \
    [ -n "$LIVE_SHA" ] || exit 1; \
    [ "$DISK_SHA" = "$LIVE_SHA" ] || exit 1; \
    exit 0; \
  '
# [Heath-check cho DevOps Orchestrators Docker Swarm / K8S]: Cứ mỗi 10 Giây tìm 1 file random JS build ra lưu trong đĩa. Tính toán SHA256 mã băm. Call Local network port HTTP 127.0.0.1/ lấy nguyên nội dung về và băm tiếp. Chừng nào hai mã đều hợp lệ là ứng dụng Nginx khỏe. (10s làm 1 lần, Fail đợi thử gọi thêm với 3 retries qua 5 giây timeout loop). Fail trả docker status Unhealthy Exit 1, thành công là Exit 0.

EXPOSE 80
# Container port network mở cửa port 80 giao thức http.
```
