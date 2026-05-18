#!/bin/bash
# Script cài đặt và chạy training FLUX LoRA trên Runpod RTX 4090
# Sử dụng: bash scripts/train_lora.sh <tên_nhân_vật>
# Ví dụ:   bash scripts/train_lora.sh anna

CHARACTER=${1:-"character"}
echo "🧠 Bắt đầu training LoRA cho nhân vật: $CHARACTER"

WORKSPACE="/workspace"
TOOLKIT_DIR="$WORKSPACE/ai-toolkit"
OUTPUT_DIR="/workspace/runpod-slim/ComfyUI/models/loras"

# 1. Clone ai-toolkit nếu chưa có
if [ ! -d "$TOOLKIT_DIR" ]; then
    echo "📦 Cloning ai-toolkit..."
    cd $WORKSPACE
    git clone https://github.com/ostris/ai-toolkit.git
    cd ai-toolkit
    pip install -r requirements.txt
else
    echo "✅ ai-toolkit đã tồn tại."
    cd $TOOLKIT_DIR
fi

# 2. Kiểm tra dataset
DATASET_DIR="$WORKSPACE/datasets/$CHARACTER"
if [ ! -d "$DATASET_DIR" ]; then
    echo "❌ Không tìm thấy dataset tại: $DATASET_DIR"
    echo "💡 Hãy upload 20-40 ảnh mặt nhân vật vào thư mục: $DATASET_DIR"
    echo "   Tên file ảnh phải đặt theo format: $CHARACTER (1).jpg, $CHARACTER (2).jpg ..."
    exit 1
fi

IMAGE_COUNT=$(ls $DATASET_DIR/*.jpg $DATASET_DIR/*.png $DATASET_DIR/*.jpeg 2>/dev/null | wc -l)
echo "📸 Tìm thấy $IMAGE_COUNT ảnh training"

# 3. Tạo file config training
mkdir -p $OUTPUT_DIR
CONFIG_FILE="$TOOLKIT_DIR/config/train_${CHARACTER}.yml"

cat > $CONFIG_FILE << EOF
job: extension
config:
  name: "${CHARACTER}_flux_lora_v1"
  process:
    - type: 'sd_trainer'
      training_folder: "${OUTPUT_DIR}"
      device: cuda:0
      trigger_word: "${CHARACTER}_person"
      network:
        type: "lora"
        linear: 16
        linear_alpha: 16
      save:
        dtype: float16
        save_every: 250
        max_step_saves_to_keep: 4
      datasets:
        - folder_path: "${DATASET_DIR}"
          caption_ext: "txt"
          caption_dropout_rate: 0.05
          shuffle_tokens: false
          cache_latents_to_disk: true
          resolution: [ 512, 768, 1024 ]
      train:
        batch_size: 1
        steps: 2000
        gradient_accumulation_steps: 1
        train_unet: true
        train_text_encoder: false
        gradient_checkpointing: true
        noise_scheduler: "flowmatch"
        optimizer: "adamw8bit"
        lr: 1e-4
        lr_scheduler: "cosine_with_restarts"
        lr_scheduler_num_cycles: 1
        ema_config:
          use_ema: true
          ema_decay: 0.99
        dtype: bf16
      model:
        name_or_path: "black-forest-labs/FLUX.1-dev"
        is_flux: true
        quantize: true
      sample:
        sampler: "flowmatch"
        sample_every: 250
        width: 1024
        height: 1024
        prompts:
          - "${CHARACTER}_person, portrait, highly detailed, cinematic"
          - "${CHARACTER}_person, full body, dancing, dynamic pose"
        neg: ""
        seed: 42
        walk_seed: true
        guidance_scale: 4
        sample_steps: 20
meta:
  name: "[character_lora] ${CHARACTER}"
  version: '1.0'
EOF

echo "✅ Config đã được tạo tại: $CONFIG_FILE"
echo ""
echo "🚀 Bắt đầu training (khoảng 30-45 phút trên RTX 4090)..."
echo "   - Steps: 2000"
echo "   - Output: $OUTPUT_DIR/${CHARACTER}_flux_lora_v1/"
echo ""

# 4. Chạy training
cd $TOOLKIT_DIR
python run.py $CONFIG_FILE

echo ""
echo "🎉 Training hoàn tất!"
echo "📁 File LoRA lưu tại: $OUTPUT_DIR/${CHARACTER}_flux_lora_v1/"
echo "💡 Copy file .safetensors vào ComfyUI để dùng trong workflow!"
