# AI Character Consistency Pipeline (TikTok Video)

Hệ thống tự động hóa tạo video TikTok với khả năng **giữ chuẩn khuôn mặt và dáng người 1:1**, được xây dựng dựa trên hệ sinh thái ComfyUI, AnimateDiff, ControlNet đa tầng và FaceSwap. Hệ thống được tối ưu để chạy trên máy chủ Runpod (RTX 4090) hoặc chạy test local trên Apple Silicon (Macbook M).

---

## 🌟 Tổng quan Kiến trúc

Để đạt được sự nhất quán tuyệt đối cho nhân vật ảo (Virtual Influencer/Character), hệ thống sử dụng quy trình **Video-to-Video (Vid2Vid)** với 3 trụ cột:
1.  **Multi-ControlNet (DWPose + Depth):** Bắt chính xác 100% xương khớp và hình khối từ video nhảy gốc. Nhân vật AI sẽ chuyển động không sai một milimet.
2.  **AnimateDiff (SD 1.5):** Engine sinh video mạnh mẽ và ổn định nhất, thay thế trang phục, phông nền dựa trên Text Prompt.
3.  **ReActor FaceSwap / LoRA:** Khóa chặt khuôn mặt nhân vật để đảm bảo không bị biến dạng khi chuyển động nhanh.

---

## 🚀 1. Hướng dẫn Cài đặt Môi trường

### Triển khai trên Máy chủ Runpod (RTX 4090) - Khuyên dùng
1. Thuê máy RTX 4090 trên [Runpod.io](https://www.runpod.io/). Chọn Template `RunPod PyTorch` hoặc `Ubuntu`.
2. Cấp **Network Volume (150GB+)** và mount vào `/workspace` để lưu Models vĩnh viễn (không bị mất khi xoá Pod).
3. Mở Terminal của Runpod và chạy:

```bash
# Clone repository
git clone git@github.com-huanpro:huannguyenduc/tiktok-ai-pipeline.git
cd tiktok-ai-pipeline

# 1. Chạy script cài đặt hệ thống & Custom Nodes cho ComfyUI
bash scripts/setup_env.sh

# 2. Chạy script tải AI Models (Vài chục GB, mất 15-30 phút tuỳ mạng Runpod)
bash scripts/download_models.sh
```

### Triển khai Local trên macOS (Apple Silicon M1/M2/M3/M4)
Dùng để test logic, nối node và sinh ảnh tĩnh hoặc video độ phân giải thấp nhằm tiết kiệm chi phí thuê server.
```bash
# Clone repository
git clone git@github.com-huanpro:huannguyenduc/tiktok-ai-pipeline.git
cd tiktok-ai-pipeline

# Cấp quyền chạy cho các script
chmod +x scripts/*.sh

# Chạy script cài đặt dành riêng cho Mac (Sử dụng MPS)
bash scripts/setup_mac.sh

# Khởi động ComfyUI trên Mac
cd ComfyUI
source venv/bin/activate
python main.py --force-fp16
```

---

## 🧠 2. Đóng gói Nhân vật (Training AI LoRA)

Để hệ thống thực sự "hiểu" và "nhớ" khuôn mặt nhân vật ảo của bạn (ví dụ nhân vật tên là "Anna"), bạn cần huấn luyện một mô hình **LoRA** (Low-Rank Adaptation). 

### Bước 1: Chuẩn bị Dataset (Dữ liệu)
1. Cắt từ video/ảnh gốc ra khoảng **20 - 30 bức ảnh** của khuôn mặt nhân vật.
2. Yêu cầu: Đa dạng góc độ (thẳng, nghiêng, cúi), đa dạng biểu cảm (cười, buồn), rõ nét, và có độ phân giải từ `512x512` trở lên.
3. Crop hình vuông tập trung vào phần đầu và ngực. Đặt tất cả vào một thư mục, ví dụ: `dataset/anna_images/`.

### Bước 2: Huấn luyện với Kohya_ss
Công cụ chuẩn ngành để train LoRA là [Kohya_ss](https://github.com/bmaltais/kohya_ss). Bạn có thể chạy Kohya_ss trực tiếp trên Runpod.
1. Cài đặt Kohya_ss theo hướng dẫn trên Github của họ.
2. Mở giao diện Kohya_ss, vào tab **LoRA**.
3. **Source Model:** Chọn `runwayml/stable-diffusion-v1-5` (nếu bạn định làm video bằng AnimateDiff v1.5).
4. **Folders:** 
   - Image folder: Trỏ tới thư mục dataset.
   - Output folder: Chọn nơi lưu model đầu ra.
5. **Training Parameters:** 
   - Batch size: `1` hoặc `2`.
   - Epochs: `10`
   - Learning rate: `1e-4`
   - Network Rank (Dimension): `32`
6. Nhấn **Train model**. Quá trình trên RTX 4090 sẽ mất khoảng 15-30 phút.
7. Kết quả thu được là một file `.safetensors` (ví dụ `anna_character_v1.safetensors` nặng khoảng 36MB - 144MB).

### Bước 3: Đưa nhân vật vào Hệ thống
- Sao chép file `anna_character_v1.safetensors` vào thư mục: 
  `/workspace/ComfyUI/models/loras/`
- Giờ đây, nhân vật của bạn đã được "đóng gói" thành công.

---

## 🎬 3. Hướng dẫn Gọi Nhân vật & Tạo Video

Khi nhân vật đã được nạp vào hệ thống, bạn sử dụng **ComfyUI** để ra lệnh tạo video nhảy.

### Cấu hình Workflow ComfyUI (Vid2Vid)
1. Mở giao diện web ComfyUI.
2. Kéo thả các Node cơ bản cho quy trình:
   - **Load Video:** Nhập video gốc của một người đang nhảy Tiktok.
   - **DWPose ControlNet:** Trích xuất xương khớp từ video trên.
   - **Depth ControlNet:** Trích xuất chiều sâu.
   - **Load Checkpoint:** Chọn model `dreamshaper_8.safetensors`.
   - **Load LoRA:** Trỏ đến file `anna_character_v1.safetensors` của bạn.
   - **AnimateDiff Loader:** Tải model `v3_sd15_mm.ckpt`.
3. **Thêm FaceSwap (ReActor):** Để nét mặt giống ảnh thật 100% (bù đắp những góc nghiêng AI vẽ chưa hoàn hảo), cho đường video đầu ra đi qua Node **ReActor Fast Face Swap** và cung cấp 1 tấm ảnh chân dung sắc nét của Anna làm tham chiếu.

### Kích hoạt bằng Text Prompt (Gọi nhân vật)
Trong ô Text Prompt (CLIP Text Encode), bạn gọi nhân vật bằng cú pháp:
> **Positive Prompt:** `<lora:anna_character_v1:1.0>, (anna_woman:1.2), 1girl, highly detailed face, wearing school uniform, dancing in a futuristic neon city, masterpiece, best quality, 8k`
> 
> **Negative Prompt:** `ugly, deformed, disfigured, poor details, bad anatomy`

*Lưu ý: Chữ `anna_woman` là trigger word (từ khoá) bạn đã dùng khi đặt tên thư mục ảnh lúc train Kohya.*

Nhấn **Queue Prompt** và đợi vài phút. Kết quả trả về là một video nhân vật Anna nhảy khớp 100% với dáng của video gốc, nhưng trong bộ đồ và bối cảnh hoàn toàn mới!

---

## 🤖 4. Tự động hóa Pipeline qua API (Python)

Khi bạn đã tạo được chuỗi Workflow ưng ý trên ComfyUI, bạn không cần mở giao diện Web để kéo thả nữa. Mọi thứ có thể được lập trình tự động hóa.

### Bước 1: Xuất file JSON
1. Mở ComfyUI Web, vào biểu tượng ⚙️ (Settings) -> Bật **Enable Dev mode Options**.
2. Một nút mới tên là **Save (API Format)** sẽ xuất hiện. Nhấn vào đó để tải file `workflow_api.json`.
3. Lưu file này vào thư mục `workflows/` trong project của bạn.

### Bước 2: Chạy Script Python
Mình đã chuẩn bị sẵn file `api_agent.py` để bạn gọi trực tiếp ComfyUI. Bạn có thể nhúng nó vào một con Bot Telegram hoặc AI CLI.

```bash
# Đảm bảo bạn đã cài thư viện
pip install -r requirements.txt

# Chạy tạo video tự động
python api_agent.py
```
Trong file `api_agent.py`, bạn có thể can thiệp bằng code để thay đổi đoạn Text Prompt tự động (ví dụ dùng GPT-4 tạo ra ngẫu nhiên áo quần cho nhân vật mỗi ngày) và thay đổi đường dẫn video input. Video sẽ được kết xuất thẳng ra thư mục `output/`.

---

## 🛠 Lời khuyên cho Production
* **Bảo toàn dữ liệu:** Luôn cấu hình Volume trên Runpod và trỏ thư mục `/models` vào Volume. Chi phí Volume rất rẻ, bạn có thể xóa hẳn Pod để ngừng tính tiền GPU mà vẫn giữ lại mọi model và cấu hình cho lần chạy sau.
* **Upscale:** Video đầu ra của AnimateDiff thường có độ phân giải thấp (khoảng `512x768`). Hãy tải file `.mp4` vào CapCut trên điện thoại, áp dụng bộ lọc Làm nét (Sharpen) hoặc dùng các công cụ AI Upscale (Topaz Video AI) trước khi đăng TikTok.
