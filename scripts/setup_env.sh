#!/bin/bash
# Script khởi tạo môi trường trên Runpod (Ubuntu/Linux)

echo "🚀 Bắt đầu cài đặt ComfyUI và các Custom Nodes..."

# 1. Cài đặt các thư viện hệ thống cần thiết
if command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi
$SUDO apt-get update && $SUDO apt-get install -y git wget aria2 python3.10-venv ffmpeg libgl1

# Tự động tìm đường dẫn ComfyUI gốc (nếu dùng template runpod-slim thì nó nằm ở đây)
if [ -d "/workspace/runpod-slim/ComfyUI" ]; then
    COMFY_DIR="/workspace/runpod-slim/ComfyUI"
    echo "Phát hiện ComfyUI đã cài sẵn tại: $COMFY_DIR"
else
    COMFY_DIR="/workspace/ComfyUI"
    # 2. Clone ComfyUI nếu chưa có
    if [ ! -d "$COMFY_DIR" ]; then
        echo "Cloning ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git $COMFY_DIR
    else
        echo "ComfyUI đã tồn tại."
    fi
fi

# 3. Chuyển vào thư mục custom_nodes
cd $COMFY_DIR/custom_nodes

# Clone các Custom Nodes bắt buộc cho Vid2Vid và FaceSwap
echo "Cloning Custom Nodes..."
# ComfyUI Manager (quản lý node)
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# AnimateDiff (Engine Video)
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git
# HunyuanVideo Wrapper (Bắt buộc cho Hunyuan V2V)
git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper.git
# Advanced ControlNet (Cho DWPose, Depth)
git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git
# Video Helper (Load/Lưu Video)
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
# ReActor (Face Swap)
git clone https://github.com/Gourieff/comfyui-reactor-node.git
# DWPose Node
git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git

# 4. Cài đặt Requirements cho các nodes
echo "Cài đặt Python requirements..."
cd $COMFY_DIR
pip install -r requirements.txt
pip install opencv-python onnxruntime-gpu insightface

echo "✅ Cài đặt môi trường hoàn tất! Bước tiếp theo: Chạy scripts/download_models.sh"
