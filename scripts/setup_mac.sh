#!/bin/bash
# Script khởi tạo ComfyUI trên Macbook (Apple Silicon - M1/M2/M3/M4)

echo "🍎 Bắt đầu cài đặt ComfyUI cho macOS (Apple Silicon)..."

# 1. Chuyển vào thư mục gốc của dự án
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)

# 2. Cài đặt các thư viện hệ thống cần thiết (nếu có Homebrew)
if command -v brew >/dev/null 2>&1; then
    echo "Cài đặt aria2, ffmpeg qua Homebrew..."
    brew install wget aria2 ffmpeg
else
    echo "⚠️ Không tìm thấy Homebrew, vui lòng cài đặt thủ công."
fi

# 3. Clone ComfyUI nếu chưa có
if [ ! -d "ComfyUI" ]; then
    echo "Đang tải mã nguồn ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
else
    echo "Thư mục ComfyUI đã tồn tại."
fi

# 4. Tạo môi trường ảo (Virtual Environment)
cd ComfyUI
if [ ! -d "venv" ]; then
    echo "Tạo môi trường Python ảo (venv)..."
    python3 -m venv venv
fi

# Kích hoạt môi trường ảo
source venv/bin/activate

# 5. Cài đặt PyTorch và các thư viện cần thiết cho MPS (Mac)
echo "Cài đặt PyTorch và requirements cho Apple Silicon..."
pip install --upgrade pip
# Cài bản pytorch chuẩn hỗ trợ MPS
pip install torch torchvision torchaudio
pip install -r requirements.txt

# 6. Clone các Custom Nodes cơ bản
echo "Tải các Custom Nodes..."
cd custom_nodes
[ ! -d "ComfyUI-Manager" ] && git clone https://github.com/ltdrdata/ComfyUI-Manager.git
[ ! -d "ComfyUI-AnimateDiff-Evolved" ] && git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git
[ ! -d "ComfyUI-Advanced-ControlNet" ] && git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git
[ ! -d "ComfyUI-VideoHelperSuite" ] && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git

# 7. Cài requirements cho custom nodes
cd ..
echo "Cài đặt thư viện cho Custom Nodes..."
# (Tuỳ chọn cài thêm opencv, onnxruntime cho Mac)
pip install opencv-python insightface onnxruntime

echo ""
echo "✅ Cài đặt Local trên Mac hoàn tất!"
echo "👉 Để chạy ComfyUI, hãy gõ các lệnh sau:"
echo "cd $PROJECT_DIR/ComfyUI"
echo "source venv/bin/activate"
echo "python main.py --force-fp16"
