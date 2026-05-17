# AI Character Consistency Pipeline (TikTok Video)

Hệ thống tự động hóa tạo video TikTok giữ chuẩn khuôn mặt và dáng người 1:1, sử dụng ComfyUI, AnimateDiff, ControlNet và FaceSwap trên máy chủ Runpod (RTX 4090).

## 🚀 Hướng dẫn Triển khai trên Runpod

### 1. Khởi tạo Pod
1. Thuê máy RTX 4090 trên Runpod.io.
2. Chọn Template `RunPod PyTorch` hoặc Ubuntu cơ bản.
3. Cấp Network Volume (150GB+) để lưu Model.

### 2. Cài đặt Môi trường
Mở Terminal của Runpod và chạy:
```bash
# Clone repo này
git clone git@github.com-huanpro:huannguyenduc/tiktok-ai-pipeline.git
cd tiktok-ai-pipeline

# Chạy script cài đặt ComfyUI & Custom Nodes
bash scripts/setup_env.sh

# Chạy script tải AI Models (Vài chục GB, mất 15-30 phút)
bash scripts/download_models.sh
```

### 3. Tự động hóa tạo Video (API Agent)
Sau khi thiết kế luồng (workflow) trên ComfyUI UI và xuất ra JSON (lưu vào thư mục `workflows/`), bạn có thể gọi API:

```bash
# Cài đặt thư viện Python
pip install -r requirements.txt

# Bật ComfyUI (Nếu chưa chạy)
# python /workspace/ComfyUI/main.py --listen

# Chạy bot để tạo video tự động
python api_agent.py
```
Video sau khi xử lý sẽ được lưu ở thư mục `output/`.
