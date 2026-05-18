#!/usr/bin/env bash
# --------------------------------------------------------------
# One‑click setup for the TikTok‑AI pipeline on Runpod
# --------------------------------------------------------------
# This script will:
#   1️⃣ Create a Python virtual‑env inside ComfyUI
#   2️⃣ Install all required Python packages (ComfyUI, custom nodes, manager)
#   3️⃣ Create placeholder model files so ComfyUI can load the workflow
#   4️⃣ Copy the workflow JSON to the exact location ComfyUI expects
#   5️⃣ Launch ComfyUI inside a tmux session (named 'comfyui')
# --------------------------------------------------------------

set -euo pipefail

# -------------------- Paths --------------------
BASE_DIR="/workspace/runpod-slim/tiktok-ai-pipeline"
COMFY_DIR="/workspace/runpod-slim/ComfyUI"
SCRIPT_DIR="${BASE_DIR}/scripts"
WORKFLOW_SRC="${BASE_DIR}/workflows/full_pipeline_workflow.json"
WORKFLOW_DST="${COMFY_DIR}/user/default/workflows"

# -------------------- Helper --------------------
log() { echo -e "\n\033[1;34m[setup] $*\033[0m"; }
err() { echo -e "\n\033[1;31m[ERROR] $*\033[0m" >&2; exit 1; }

# -------------------- Ensure directories --------------------
log "Ensuring workflow destination exists..."
mkdir -p "${WORKFLOW_DST}"

log "Ensuring placeholder model directories exist..."
mkdir -p "${COMFY_DIR}/models/{loras,flux,clip,vae,hyvid}"

# -------------------- Create placeholder model files --------------------
log "Creating placeholder model files (empty files, just to satisfy ComfyUI)..."
touch "${COMFY_DIR}/models/flux/flux1-dev-fp8.safetensors"
touch "${COMFY_DIR}/models/clip/t5xxl_fp16.safetensors"
touch "${COMFY_DIR}/models/clip/clip_l.safetensors"
touch "${COMFY_DIR}/models/vae/ae.safetensors"
touch "${COMFY_DIR}/models/hyvid/hunyuan_video_720_fp8_e4m3fn.safetensors"
touch "${COMFY_DIR}/models/hyvid/hunyuan_video_vae_bf16.safetensors"
touch "${COMFY_DIR}/models/hyvid/img2vid.safetensors"
touch "${COMFY_DIR}/models/loras/anna_flux_v1.safetensors"

# -------------------- Copy workflow --------------------
log "Copying workflow JSON to ComfyUI folder..."
cp "${WORKFLOW_SRC}" "${WORKFLOW_DST}/full_pipeline_workflow.json"
log "Workflow copied to: ${WORKFLOW_DST}/full_pipeline_workflow.json"

# -------------------- Python venv --------------------
log "Setting up Python virtual environment..."
if [ ! -d "${COMFY_DIR}/venv" ]; then
    python3 -m venv "${COMFY_DIR}/venv"
    log "Virtual env created."
fi
source "${COMFY_DIR}/venv/bin/activate"

log "Upgrading pip and installing core requirements..."
pip install -U pip setuptools
pip install -r "${COMFY_DIR}/requirements.txt"

log "Installing ComfyUI‑Manager (required for custom nodes)..."
pip install -U --pre comfyui-manager

# -------------------- Install extra custom‑node requirements --------------------
log "Checking and installing custom nodes requirements..."
if [ -d "${COMFY_DIR}/custom_nodes" ]; then
    for req in "${COMFY_DIR}/custom_nodes"/*/requirements.txt; do
        if [ -f "$req" ]; then
            log "Installing requirements for: $(basename $(dirname "$req"))"
            pip install -r "$req"
        fi
    done
fi

# -------------------- Start ComfyUI in tmux --------------------
TMUX_NAME="comfyui"
log "Starting ComfyUI in tmux session '${TMUX_NAME}'..."
# Kill previous session if exists
tmux kill-session -t "${TMUX_NAME}" 2>/dev/null || true
# Create new detached session and run ComfyUI
tmux new-session -d -s "${TMUX_NAME}" "python ${COMFY_DIR}/main.py"

log "✅ Setup completed!"
log "ComfyUI is running in tmux session '${TMUX_NAME}'."
log "Open your browser to http://<pod‑ip>:8188 to view the UI."
log "To stop ComfyUI later: tmux kill-session -t ${TMUX_NAME}"
