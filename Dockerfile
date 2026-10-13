# Base Image nhẹ sử dụng Alpine Linux với Node.js 18
FROM node:18-alpine

# Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# Thiết lập biến môi trường PORT mặc định
ENV PORT=3000

# Sao chép định nghĩa dependencies để tận dụng Docker cache layer
COPY package*.json ./

# Cài đặt các dependencies cần thiết
RUN npm install --omit=dev

# Sao chép toàn bộ mã nguồn vào thư mục làm việc
COPY . .

# Khai báo port lắng nghe của ứng dụng
EXPOSE 3000

# Lệnh khởi chạy ứng dụng (dạng exec form)
CMD ["node", "server.js"]
