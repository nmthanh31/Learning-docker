# Cẩm nang Docker và Giải thích Cấu hình Dự án

## 1. Kiến thức cơ bản về Docker

### 1.1. Các Khái Niệm Cốt Lõi
- **Image**: Một gói (package) nén đóng băng chứa mã nguồn, thư viện, biến môi trường và file cấu hình cần thiết để chạy một ứng dụng. Có thể coi nó giống như một file `.iso` cài đặt hệ điều hành nhưng thu nhỏ nhẹ lại.
- **Container**: Là một phiên bản (instance) đang chạy thực tế của một Image. Một Image có thể khởi tạo ra hàng ngàn Container độc lập giống hệt nhau mà không bị trùng lặp môi trường.
- **Dockerfile**: File kịch bản chứa các bước lệnh (instruction) để Docker Engine tự động "quét" qua và build (xây dựng) ra một Image mới.
- **Docker Compose**: Là công cụ giúp định nghĩa và khởi chạy hệ thống nhiều container cùng lúc (multi-container) thông qua file cấu hình `docker-compose.yml`. Thay vì gõ vài chục lệnh terminal dài dòng cho mỗi container rời rạc, tính năng này giúp tự động hóa toàn bộ một cụm mạng.

### 1.2. Các Lệnh (Command Line) Cơ Bản Nhất
Dưới đây là các lệnh Docker CLI (Command Line Interface) thường dùng hàng ngày nhất:

**Quản lý Image:**
- `docker build -t <tên-image>:<tag> .`: Xây dựng một image từ thư mục hiện tại (cần có Dockerfile ở thư mục đang đứng `.` ). *Ví dụ: `docker build -t my-app:1.0 .`*
- `docker images` hoặc `docker image ls`: Liệt kê các image đang lưu sẵn trên máy tính của bạn.
- `docker rmi <id-hoặc-tên-image>`: Xóa một image không còn dùng (remove image).

**Quản lý Container:**
- `docker run -d -p 8080:80 --name my-web my-app:1.0`: Tạo và chạy một container từ image `my-app:1.0`.
  - `-d`: Chạy ngầm phía sau (detach).
  - `-p 8080:80`: Map port (Gắn Cổng mạng 80 của container trỏ ra cổng 8080 của máy tính thực).
  - `--name`: Đặt tên riêng cho dễ quản lý.
- `docker ps`: Liệt kê các container **đang chạy**. Thêm cờ `-a` (`docker ps -a`) để xem cả những container đã bị tắt.
- `docker stop <tên-container>`: Dừng (tắt máy) container đang chạy.
- `docker start <tên-container>`: Chạy lại container đã bị stop từ trước.
- `docker rm <tên-container>`: Xóa hẳn một container vĩnh viễn (lưu ý: nó phải đang trong trạng thái stop mới được xóa, trừ khi dùng cờ `-f` ép buộc lệnh xóa thẳng tay).
- `docker logs <tên-container>`: Xem lại log (lịch sử màn hình console terminal) báo lỗi print ra của ứng dụng ẩn bên trong container.
- `docker exec -it <tên-container> sh`: Mở cánh cửa "chui thẳng" vào bên trong hệ điều hành của container để soi file và gõ dòng lệnh bash script. (Nếu OS là Ubuntu cài bản full có thể gõ `bash` thay vì `sh`).

### 1.3. Cú Pháp Thường Gặp Khi Viết Dockerfile
Khi phải định nghĩa hoặc đọc hiểu Dockerfile, đây là các từ khóa cốt cán:
- `FROM`: Kế thừa môi trường từ 1 image nền có sẵn (ví dụ lấy OS ubuntu hay môi trường dev nodejs). Phải nằm trên cùng.
- `WORKDIR`: Khai báo thư mục làm việc hiện thời khi nhảy vào vùng chứa (tương tự vòng lệnh `cd`). 
- `COPY`: Copy file/thư mục từ máy tính của bạn (hay máy Runner) đẩy sang bên trong lõi hệ điều hành của container.
- `RUN`: Chỉ đạo phần mềm thực thi các câu lệnh (xảy ra ở lúc diễn ra thời điểm **Build Image**). Ví dụ: `RUN npm install` hoặc `RUN apt-get update`.
- `CMD / ENTRYPOINT`: Câu lệnh đinh chỉ gốc để khởi động ứng dụng TẠI LÚC CHẠY CONTAINER (**Runtime**). (VD: `CMD ["npm", "start"]` hay `CMD ["nginx", "-g", "daemon off;"]`).
- `EXPOSE`: Giống như một cái biển báo cho con người là "ứng dụng của container định mở port 80 nhé", chứ bản thân lệnh này nó không tự map port ra máy chủ (phải dùng `-p` tự gõ). Này đóng vai làm documentation mô tả port nội bộ.
- `ENV`: Khai báo siêu biến môi trường.

### 1.4. Cách Viết `docker-compose.yml` Cơ Bản
File `docker-compose.yml` viết bằng chuẩn ngôn ngữ YAML (Lưu ý: Ngôn ngữ này bắt lỗi căn lề phân tầng bằng dấu Space, tuyệt đối không xài phím Tab). 
*Ví dụ để chạy Frontend Nginx kết nối cùng một Backend API qua Compose:*

```yaml
version: '3.8' # Phiên bản cú pháp compose quy ước

services:
  # Container số 1: Web Frontend UI
  frontend:
    build: . # Tự đọc file Dockerfile ở ngay folder hiện tại và build lấy Image sống
    ports:
      - "80:80" # Map HTTP ra máy tính
    restart: always # Luật tự động hồi sinh: lỡ container sập do crash, tự động boot khởi động lại nó.
    depends_on:
      - backend # Logic tuần tự: frontend sẽ chỉ bắt đầu khởi chạy nếu cái container `backend` bên dưới đã được launch gọi dậy thành công.

  # Container số 2: Backend Logic
  backend:
    image: my-backend-api:latest # Thay vì chạy Dockerfile, ta xài luôn gói image đã nấu nướng sẵn trên mạng tải về.
    environment:                 # Nhồi biến môi trường vào container
      - DB_HOST=database-mysql
      - DB_PASSWORD=my_secret_vault
    ports:
      - "8080:8080"
```

**Các lệnh thường hay đi kèm với Docker Compose:**
- `docker-compose up -d`: Thần chú tối thượng, tự động "phép thuật" mọi thứ (build tự động nếu chưa có, lập mạng LAN network ảo, gom nhóm lại, đổ config port, và kích hoạt Start sạch cả cụm lên ngầm). `-d` là chế độ chạy ẩn màn hình console.
- `docker-compose down`: Xóa sổ giải tán đám đông - tắt máy tắt server, dọn dẹp sạch sẽ trả lại vùng network, biến mất xóa container.
- `docker-compose logs -f`: Theo dõi console logs của toàn bộ cụm đó trộn chung lại (giữ màn terminal trực tiếp).

---

## 2. Giải thích chi tiết cấu hình Docker và Nginx (Project hiện tại)

Dưới đây là phần giải nghĩa từng dòng một (line-by-line) cho các file cấu hình được sử dụng trong dự án.

### 2.1. File `nginx/nginx.conf`
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

### 2.2. File `nginx/conf.d/app.conf`
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
    # Response từ từ chối toàn phần đối với URL xin xin resource .map của JS.

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

### 2.3. File `Dockerfile`
File dùng Multi-Stage Build.

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
