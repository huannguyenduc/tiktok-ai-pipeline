#!/bin/bash
# Script tự động tải các models cần thiết cho ComfyUI (SD 1.5 Vid2Vid)
# Khuyên dùng aria2c để tải nhanh hơn wget

echo "⬇️ Đang tải Models cho ComfyUI..."

COMFY_MODELS="/workspace/ComfyUI/models"
# Tạo các thư mục nếu chưa có
mkdir -p $COMFY_MODELS/checkpoints
mkdir -p $COMFY_MODELS/controlnet
mkdir -p $COMFY_MODELS/loras
mkdir -p /workspace/ComfyUI/custom_nodes/ComfyUI-AnimateDiff-Evolved/models

# 1. Base Model (DreamShaper 8 - SD 1.5 rất tốt cho AnimateDiff)
echo "Tải Base Checkpoint (DreamShaper 8)..."
aria2c -x 16 -s 16 -d $COMFY_MODELS/checkpoints -o dreamshaper_8.safetensors https://civitai.com/api/download/models/128713

# 2. AnimateDiff Motion Module (v3)
echo "Tải AnimateDiff v3 Motion Module..."
aria2c -x 16 -s 16 -d /workspace/ComfyUI/custom_nodes/ComfyUI-AnimateDiff-Evolved/models -o v3_sd15_mm.ckpt https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_mm.ckpt

# 3. ControlNet Models (OpenPose & Depth)
echo "Tải ControlNet Models (v1.1)..."
aria2c -x 16 -s 16 -d $COMFY_MODELS/controlnet -o control_v11p_sd15_openpose.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth
aria2c -x 16 -s 16 -d $COMFY_MODELS/controlnet -o control_v11f1p_sd15_depth.pth https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth

# 4. FaceSwap (ReActor Model - inswapper_128)
echo "Tải FaceSwap Model (inswapper_128)..."
mkdir -p $COMFY_MODELS/insightface
aria2c -x 16 -s 16 -d $COMFY_MODELS/insightface -o inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128.onnx

echo "✅ Tải Models hoàn tất!"
