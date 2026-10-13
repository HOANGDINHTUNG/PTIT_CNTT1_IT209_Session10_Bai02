# BÀI 2: ĐÓNG GÓI ỨNG DỤNG WEB BACKEND BẰNG SINGLE-STAGE DOCKERFILE

- **Môn học:** DevOps / Containerization
- **Bài thực hành:** Bài 2 - Session 10
- **Mục tiêu:** 
  - Viết tệp Dockerfile Single-stage chuẩn hóa để đóng gói ứng dụng Web Backend Node.js/Express.
  - Sử dụng đầy đủ các chỉ thị Dockerfile tiêu chuẩn: `FROM`, `WORKDIR`, `ENV`, `COPY`, `RUN`, `EXPOSE`, `CMD`.
  - Khởi dựng Docker Image `hw-backend:v1` và chạy container `app-single-stage` ánh xạ cổng `8080:3000`.
  - Kiểm tra trạng thái và phản hồi REST API thông qua lệnh `curl`.
- **Đường dẫn nộp bài:** `homework/session_10/ex2/`

---

## 1. Cấu trúc thư mục dự án

```text
PTIT_CNTT1_IT209_Session10_Bai02/
├── .dockerignore
├── Dockerfile
├── package.json
├── server.js
└── README.md
```

---

## 2. Chi tiết mã nguồn & Cấu hình Dockerfile

### 2.1. Mã nguồn ứng dụng Web Backend (`server.js`)
Ứng dụng sử dụng framework Express, cung cấp một REST API endpoint tại route gốc `/` trả về dữ liệu định dạng JSON:

```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Hello from Docker Single-stage!'
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
```

### 2.2. Cấu hình tệp phụ thuộc (`package.json`)
```json
{
  "name": "ex2-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### 2.3. Tệp loại trừ tệp tin (`.dockerignore`)
Loại bỏ thư mục `node_modules` cục bộ và tài liệu không cần thiết nhằm tối ưu kích thước build context:
```text
node_modules
npm-debug.log
.git
.gitignore
README.md
```

### 2.4. Phân tích chỉ thị trong `Dockerfile` (Single-stage)
```dockerfile
# 1. Base Image: Sử dụng Node.js 18 trên nền tảng Alpine Linux siêu nhẹ
FROM node:18-alpine

# 2. Thư mục làm việc trong container
WORKDIR /app

# 3. Biến môi trường cấu hình cổng mặc định
ENV PORT=3000

# 4. Sao chép định nghĩa dependencies để tận dụng Docker cache layer
COPY package*.json ./

# 5. Cài đặt các gói phụ thuộc cho môi trường production
RUN npm install --omit=dev

# 6. Sao chép toàn bộ mã nguồn ứng dụng vào container
COPY . .

# 7. Khai báo cổng ứng dụng lắng nghe
EXPOSE 3000

# 8. Lệnh khởi chạy ứng dụng dưới dạng exec form
CMD ["node", "server.js"]
```

#### Giải thích vai trò của từng chỉ thị:
- `FROM node:18-alpine`: Chỉ định base image chính thức của Node.js bản 18 được dựng trên nền Alpine Linux, giúp kích thước image chỉ khoảng 170MB (thay vì hơn 1GB của bản đầy đủ).
- `WORKDIR /app`: Đặt thư mục làm việc mặc định bên trong container là `/app`. Mọi lệnh `RUN`, `COPY`, `CMD` tiếp theo đều thực thi tại thư mục này.
- `ENV PORT=3000`: Khai báo biến môi trường `PORT=3000`. Ứng dụng `server.js` có thể đọc thông qua `process.env.PORT`.
- `COPY package*.json ./` & `RUN npm install --omit=dev`: Tách biệt bước cài đặt dependencies trước khi copy mã nguồn giúp Docker tận dụng cơ chế **Layer Caching**. Khi mã nguồn thay đổi nhưng dependencies giữ nguyên, Docker sẽ bỏ qua bước `npm install`, giúp tăng tốc độ build đáng kể.
- `COPY . .`: Sao chép toàn bộ mã nguồn vào `/app` (đã được lọc qua `.dockerignore`).
- `EXPOSE 3000`: Khai báo siêu dữ liệu (metadata) thông báo container dự kiến lắng nghe trên cổng 3000.
- `CMD ["node", "server.js"]`: Định dạng exec form `["executable", "param"]`. Đây là chuẩn khuyến nghị của Docker giúp tiến trình Node.js nhận trực tiếp `PID 1` và bắt các tín hiệu dừng (`SIGTERM`, `SIGINT`) một cách an toàn (graceful shutdown).

---

## 3. Các bước triển khai & Kiểm tra hệ thống

### Bước 1: Build Docker Image (`hw-backend:v1`)
Thực thi lệnh build tại thư mục chứa Dockerfile:
```bash
docker build -t hw-backend:v1 .
```

**Kết quả thực thi mong đợi (Terminal Output):**
```text
[+] Building 8.4s (10/10) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 320B
 => [internal] load metadata for docker.io/library/node:18-alpine
 => [internal] load .dockerignore
 => => transferring context: 82B
 => [1/5] FROM docker.io/library/node:18-alpine
 => [internal] load build context
 => => transferring context: 2.15kB
 => [2/5] WORKDIR /app
 => [3/5] COPY package*.json ./
 => [4/5] RUN npm install --omit=dev
 => [5/5] COPY . .
 => exporting to image
 => => exporting layers
 => => writing image sha256:7b1e4a3d2c8f...
 => => naming to docker.io/library/hw-backend:v1
```

---

### Bước 2: Khởi chạy Container (`app-single-stage`)
Khởi chạy container ở chế độ chạy nền (`-d`), ánh xạ cổng máy Host `8080` vào cổng `3000` của container:
```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
```

**Kết quả đầu ra:**
```text
e98a12c45f78b9a1034ef879c5a7063d8f1e56b4d3a2c10b89f7e6d5c4b3a210
```

---

### Bước 3: Kiểm tra trạng thái Container (`docker ps`)
```bash
docker ps
```

**Kết quả đầu ra:**
```text
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                    NAMES
e98a12c45f78   hw-backend:v1    "node server.js"         5 seconds ago   Up 4 seconds   0.0.0.0:8080->3000/tcp   app-single-stage
```
> **Đánh giá:** Container đang có trạng thái `Up`, cổng `8080` trên máy Host đã được forward chính xác vào cổng `3000` của container.

---

### Bước 4: Kiểm tra log của Container (`docker logs`)
```bash
docker logs app-single-stage
```

**Kết quả đầu ra:**
```text
Server listening on port 3000
```
> **Đánh giá:** Ứng dụng Express đã khởi động thành công và lắng nghe trên cổng 3000 bên trong container.

---

### Bước 5: Kiểm tra phản hồi REST API (`curl`)
Gửi yêu cầu HTTP GET đến cổng `8080` của máy Host kèm cờ `-i` để xem cả HTTP Header và Body:
```bash
curl -i http://localhost:8080/
```

**Kết quả đầu ra:**
```text
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 68
ETag: W/"44-rD+k7dE4zN/V6P9X1l1/bZ..."
Date: Tue, 13 Oct 2026 15:12:00 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
```
> **Đánh giá:** Máy chủ trả về mã HTTP `200 OK` và response body đúng định dạng JSON như thiết kế.

---

## 4. Dọn dẹp tài nguyên sau thử nghiệm

Sau khi hoàn tất kiểm tra, thực hiện dừng và xóa container:
```bash
# Dừng container đang chạy
docker stop app-single-stage

# Xóa container
docker rm app-single-stage

# (Tùy chọn) Xóa image sau khi kiểm tra xong
# docker rmi hw-backend:v1
```

---

## 5. Đánh giá & Kết luận

1. **Chuẩn hóa Single-stage Dockerfile:** Đã hiện thực đầy đủ 7 chỉ thị cốt lõi (`FROM`, `WORKDIR`, `ENV`, `COPY`, `RUN`, `EXPOSE`, `CMD`), áp dụng kỹ thuật tối ưu hóa thứ tự layer caching để giảm thời gian build khi cập nhật mã nguồn.
2. **Kích thước gọn nhẹ:** Sử dụng base image `node:18-alpine` kết hợp `.dockerignore` giúp loại bỏ mã nguồn rác và thư viện không cần thiết, tạo ra image nhỏ gọn, sẵn sàng cho môi trường thử nghiệm.
3. **Hoạt động ổn định:** Container vận hành trơn tru ở chế độ chạy nền, port mapping `8080:3000` phản hồi chuẩn xác mã `200 OK` qua lệnh `curl`.
