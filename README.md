# AI Character Consistency Pipeline (TikTok Video) - SOTA Edition

Hệ thống tự động hóa tạo video TikTok với khả năng **giữ chuẩn khuôn mặt và dáng người 1:1**, sử dụng kiến trúc tối tân nhất (State of the Art) hiện nay: **FLUX (Sinh ảnh tĩnh)** kết hợp **HunyuanVideo (Sinh video chuyển động)** trên máy chủ Runpod (RTX 4090).

---

## 🌟 Kiến trúc Hệ thống (FLUX + Hunyuan V2V)

Để video đạt chất lượng điện ảnh, chuyển động vật lý mượt mà nhưng vẫn giữ lại 100% dáng nhảy của video gốc, quy trình chuẩn sẽ diễn ra theo Flow sau:

```text
Video nhân vật (Gốc)
    ↓
Extract Frames (Trích xuất khung hình)
    ↓
Dataset Cleanup (Làm sạch dữ liệu)
    ↓
Train FLUX LoRA (Tạo "bộ não" nhớ khuôn mặt nhân vật chuẩn xác nhất)
    ↓
Generate Image (Dùng FLUX sinh ảnh tĩnh tĩnh đầu tiên cực nét)
    ↓
Hunyuan Video-to-Video (Ép Hunyuan bắt chước 100% dáng từ video gốc)
    ↓
ReActor FaceSwap (Khóa nét mặt ở mọi khung hình để không bị móp méo)
    ↓
CapCut Edit ➔ TikTok
```

---

## 🚀 1. Hướng dẫn Cài đặt Môi trường (Runpod RTX 4090)

Kiến trúc này yêu cầu rất nhiều VRAM (24GB của RTX 4090 là bắt buộc). Bạn hãy thuê pod có **Network Volume (Tối thiểu 200GB)**.

Mở Terminal của Runpod và chạy:
```bash
# 1. Clone repository
git clone git@github.com-huanpro:huannguyenduc/tiktok-ai-pipeline.git
cd tiktok-ai-pipeline

# 2. Cài đặt hệ thống & Custom Nodes cho ComfyUI (Bao gồm node HunyuanVideo)
bash scripts/setup_env.sh

# 3. Tải các siêu mô hình FLUX và HunyuanVideo (Rất nặng, tốn thời gian)
bash scripts/download_models.sh
```

---

## 🧠 2. Đóng gói Nhân vật (Training FLUX LoRA)

FLUX hiện tại là vô địch về khả năng học khuôn mặt người.
1. Dùng video nhảy của bạn, cắt ra khoảng **20-30 bức ảnh** cận mặt sắc nét.
2. Dùng công cụ [Kohya_ss](https://github.com/bmaltais/kohya_ss) trên Runpod.
3. Thiết lập Training cho **FLUX**:
   - Source Model: `black-forest-labs/FLUX.1-dev`
   - Image folder: Trỏ tới thư mục chứa 30 ảnh của bạn.
   - Batch size: 1, Epochs: 15, Network Rank: 16
4. Bấm Train. Sau khoảng 30-45 phút trên RTX 4090, bạn sẽ thu được file LoRA (ví dụ: `anna_flux_v1.safetensors`).
5. Copy file đó vào thư mục `/workspace/ComfyUI/models/loras/`.

---

## 🎬 3. Hướng dẫn Xây dựng Workflow ComfyUI

Workflow của bạn sẽ được chia làm 2 giai đoạn nối tiếp nhau:

### Giai đoạn 1: Sinh ảnh gốc bằng FLUX
- **Node Load Checkpoint:** Chọn model `FLUX.1-dev`.
- **Node Load LoRA:** Chọn file `anna_flux_v1.safetensors`.
- **Text Prompt:** Gọi nhân vật (VD: `photo of anna_woman, wearing cyberpunk jacket, neon background`).
- **Kết quả:** Một bức ảnh tĩnh đẹp hoàn hảo về nhân vật.

### Giai đoạn 2: Bơm hồn bằng Hunyuan Video-to-Video (V2V)
- Lấy bức ảnh tĩnh ở trên làm điểm bắt đầu (First Frame).
- Dùng node **Load Video** tải video Tiktok nhảy gốc của bạn vào.
- Dùng **HunyuanVideo ControlNet / Pose Control** để phân tích bộ xương từ video gốc.
- Đẩy toàn bộ dữ liệu vào node **HunyuanVideo Sampler**. AI sẽ biến bức ảnh tĩnh thành video dựa trên khung xương của video gốc.

### Giai đoạn 3: Chốt hạ Khuôn mặt (ReActor)
- Dù FLUX và Hunyuan rất xịn, khi nhân vật nhảy nhanh, mặt vẫn có rủi ro bị mờ/biến dạng.
- Nối đầu ra của video Hunyuan vào node **ReActor (FaceSwap)**.
- Đưa 1 bức ảnh chân dung rõ nét nhất của Anna vào. ReActor sẽ dán lại mặt Anna lên từng khung hình của video ➔ Khớp 1:1 tuyệt đối!

---

## 🤖 4. Tự động hóa Pipeline qua API (Python)

Khi bạn thiết kế xong Workflow trên ComfyUI, hãy xuất ra file JSON (bật `Dev mode Options` -> `Save API format`).

Lưu file đó vào `workflows/vid2vid_flux_hunyuan.json`. Sau đó chạy Script Python để tự động hóa việc kết xuất (phù hợp cho các dự án Agent):

```bash
# Đảm bảo bạn đã cài thư viện
pip install -r requirements.txt

# Chạy tạo video tự động (Thay đổi prompt trực tiếp trong file code)
python api_agent.py
```
Video xuất ra sẽ được lưu tại thư mục `output/`. Mang video này qua CapCut chèn nhạc và bạn đã sẵn sàng viral trên TikTok!
