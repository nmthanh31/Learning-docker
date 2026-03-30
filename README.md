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


