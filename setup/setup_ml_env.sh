#!/bin/bash
set -e  # Exit immediately on error

# 1. Get env name / project name from argument
if [ -z "$1" ]; then
  echo "Usage: ./setup_gpu_env.sh <project_name>"
  exit 1
fi

ENV_NAME=$1

# 2. Validate env name
if [[ ! "$ENV_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "❌ Invalid project name. Only letters, numbers, underscores, and hyphens are allowed."
  exit 1
fi

PROJECT_DIR="$(pwd)/$ENV_NAME"

# 3. Check if environment already exists
if conda info --envs | grep -q "^$ENV_NAME\s"; then
  echo "❌ Conda environment '$ENV_NAME' already exists. Choose a different name or delete the existing one."
  exit 1
fi

# 4. Create project folder structure
if [ -d "$PROJECT_DIR" ]; then
  echo "⚠️  Project folder '$PROJECT_DIR' already exists. Skipping folder creation."
else
  mkdir -p "$PROJECT_DIR/notebooks" "$PROJECT_DIR/data"
  echo "📁 Created project folder: $PROJECT_DIR"
fi

# 5. Trap failure and clean up
cleanup_on_fail() {
  echo "💥 An error occurred. Cleaning up..."
  [ -d "$PROJECT_DIR" ] && rm -rf "$PROJECT_DIR"
  conda env remove -y -n "$ENV_NAME" 2>/dev/null || true
  jupyter kernelspec uninstall -y "$ENV_NAME" 2>/dev/null || true
}
trap cleanup_on_fail ERR

# 6. Create conda environment
conda create -y -n "$ENV_NAME" python=3.10

# 7. Activate conda in this shell
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

# 8. Install PyTorch with CUDA
conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia

# 9. Install TensorFlow and tools
pip install tensorflow numpy pandas scikit-learn matplotlib jupyterlab

# 10. Register Jupyter kernel
python -m ipykernel install --user --name="$ENV_NAME" --display-name "$ENV_NAME"

# 11. Write gpu_check.py
GPU_CHECK="$PROJECT_DIR/gpu_check.py"
if [ ! -f "$GPU_CHECK" ]; then
  cat << EOF > "$GPU_CHECK"
import torch
import tensorflow as tf
print("=== PyTorch ===")
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Device:", torch.cuda.get_device_name(0))
print("\\n=== TensorFlow ===")
gpus = tf.config.list_physical_devices('GPU')
print("Detected GPUs:", gpus)
EOF
  echo "✅ Created gpu_check.py"
fi

# 12. Run validation
echo "🔍 Running GPU validation..."
python "$GPU_CHECK"

# 13. Launch VS Code
if command -v code >/dev/null 2>&1; then
  echo "🚀 Launching VS Code in $PROJECT_DIR..."
  code "$PROJECT_DIR"
else
  echo "⚠️ 'code' command not found. Skipping VS Code launch."
fi

echo "✅ Project '$ENV_NAME' successfully set up and GPU-ready."
