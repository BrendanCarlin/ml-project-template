# setup/setup_ml_env.sh

#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./setup/setup_ml_env.sh <project_name>"
  exit 1
fi

ENV_NAME=$1

if [[ ! "$ENV_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "❌ Invalid project name. Use only letters, numbers, underscores, and hyphens."
  exit 1
fi

PROJECT_DIR="$(pwd)/$ENV_NAME"

if conda info --envs | grep -q "^$ENV_NAME\\s"; then
  read -p "⚠️ Conda environment '$ENV_NAME' already exists. Reuse it? (y/n): " yn
  case $yn in
    [Yy]*)
      echo "🔄 Reusing existing environment '$ENV_NAME'..."
      ;;
    *)
      read -p "🔁 Enter a new environment name: " NEW_ENV_NAME
      ENV_NAME="$NEW_ENV_NAME"
      PROJECT_DIR="$(pwd)/$ENV_NAME"
      echo "📛 Using new environment name: '$ENV_NAME'"
      ;;
  esac
fi

if [ -d "$PROJECT_DIR" ]; then
  read -p "⚠️ Project folder '$PROJECT_DIR' already exists. Delete and recreate it? (y/n): " yn
  case $yn in
    [Yy]*)
      echo "🧹 Removing existing project folder..."
      rm -rf "$PROJECT_DIR"
      ;;
    *)
      echo "❌ Aborting setup. Please choose a different project name."
      exit 1
      ;;
  esac
fi

mkdir -p "$PROJECT_DIR/notebooks" "$PROJECT_DIR/data" "$PROJECT_DIR/.vscode"
echo "📁 Created project folder: $PROJECT_DIR"

cleanup_on_fail() {
  echo "💥 An error occurred. Cleaning up..."
  [ -d "$PROJECT_DIR" ] && rm -rf "$PROJECT_DIR"
  conda env remove -y -n "$ENV_NAME" 2>/dev/null || true
  jupyter kernelspec uninstall -y "$ENV_NAME" 2>/dev/null || true
}
trap cleanup_on_fail ERR

if ! conda info --envs | grep -q "^$ENV_NAME\\s"; then
  conda create -y -n "$ENV_NAME" python=3.10
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
pip install tensorflow numpy pandas scikit-learn matplotlib jupyterlab

python -m ipykernel install --user --name="$ENV_NAME" --display-name "$ENV_NAME"

# Determine script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/../validation/gpu_check.py" "$PROJECT_DIR/gpu_check.py"

# Create starter notebook
STARTER_NOTEBOOK="$PROJECT_DIR/notebooks/starter.ipynb"
if [ ! -f "$STARTER_NOTEBOOK" ]; then
  cat << EOF > "$STARTER_NOTEBOOK"
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Welcome to your new ML project 👋\\n",
    "This is your starter notebook. Happy experimenting!"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import numpy as np\\n",
    "import pandas as pd\\n",
    "import matplotlib.pyplot as plt"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "$ENV_NAME",
   "language": "python",
   "name": "$ENV_NAME"
  },
  "language_info": {
   "name": "python"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 2
}
EOF
  echo "📓 Created starter notebook: $STARTER_NOTEBOOK"
fi

# Create VS Code settings
cat << EOF > "$PROJECT_DIR/.vscode/settings.json"
{
  "python.defaultInterpreterPath": "$PYTHON_PATH",
  "jupyter.jupyterServerType": "local",
  "jupyter.kernelFilter": {
    "name": "$ENV_NAME"
  }
}
EOF

# Run validation
echo "🔍 Running GPU validation..."
python "$PROJECT_DIR/gpu_check.py"

# Launch VS Code
if command -v code >/dev/null 2>&1; then
  echo "🚀 Launching VS Code in $PROJECT_DIR..."
  code "$PROJECT_DIR"
else
  echo "⚠️ VS Code 'code' CLI not found. Skipping launch."
fi

echo "✅ Project '$ENV_NAME' successfully set up and GPU-ready."
