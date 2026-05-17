#!/bin/bash
# Script khởi tạo môi trường trên Runpod (Ubuntu/Linux)

echo "🚀 Bắt đầu cài đặt ComfyUI và các Custom Nodes..."

# 1. Cài đặt các thư viện hệ thống cần thiết
sudo apt-get update && sudo apt-get install -y git wget aria2 python3.10-venv ffmpeg libgl1

# 2. Clone ComfyUI nếu chưa có
if [ ! -d "/workspace/ComfyUI" ]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
else
    echo "ComfyUI đã tồn tại."
fi

# 3. Chuyển vào thư mục custom_nodes
cd /workspace/ComfyUI/custom_nodes

# Clone các Custom Nodes bắt buộc cho Vid2Vid và FaceSwap
echo "Cloning Custom Nodes..."
# ComfyUI Manager (quản lý node)
git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# AnimateDiff (Engine Video)
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git
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
cd /workspace/ComfyUI
pip install -r requirements.txt
pip install opencv-python onnxruntime-gpu insightface

echo "✅ Cài đặt môi trường hoàn tất! Bước tiếp theo: Chạy scripts/download_models.sh"
