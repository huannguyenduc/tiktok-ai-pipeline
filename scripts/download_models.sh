#!/bin/bash
# Script tự động tải các models (Kiến trúc FLUX + HunyuanVideo)
# CẢNH BÁO: Các model này cực kỳ nặng (hơn 50GB tổng cộng). Cần kiên nhẫn.

echo "⬇️ Đang tải Siêu mô hình FLUX và HunyuanVideo..."

COMFY_MODELS="/workspace/ComfyUI/models"
mkdir -p $COMFY_MODELS/checkpoints
mkdir -p $COMFY_MODELS/unet
mkdir -p $COMFY_MODELS/clip
mkdir -p $COMFY_MODELS/loras
mkdir -p $COMFY_MODELS/insightface

# 1. FLUX.1 [dev] (Sinh ảnh)
echo "Tải FLUX.1 [dev] (Model: unet/diffusion_models) - Nặng ~23GB"
aria2c -x 16 -s 16 -d $COMFY_MODELS/unet -o flux1-dev.safetensors https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors

# Tải Text Encoders (CLIP) cho FLUX
echo "Tải Text Encoders cho FLUX (t5xxl_fp16 & clip_l)..."
aria2c -x 16 -s 16 -d $COMFY_MODELS/clip -o t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors
aria2c -x 16 -s 16 -d $COMFY_MODELS/clip -o clip_l.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors

# 2. HunyuanVideo (Sinh video chuyển động)
echo "Tải HunyuanVideo Model - Nặng ~30GB"
# Tuỳ thuộc vào node bọc HunyuanVideo bạn dùng (Kijai/HunyuanWrapper), model sẽ nằm ở thư mục unet hoặc checkpoints
aria2c -x 16 -s 16 -d $COMFY_MODELS/unet -o hunyuan_video_720_fp8_e4m3fn.safetensors https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_720_fp8_e4m3fn.safetensors

# 3. FaceSwap (ReActor Model - inswapper_128)
echo "Tải FaceSwap Model (inswapper_128) để chốt khuôn mặt..."
aria2c -x 16 -s 16 -d $COMFY_MODELS/insightface -o inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128.onnx

echo "✅ Tải Models hoàn tất! (Sẵn sàng cho FLUX + Hunyuan V2V)"
