#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./setup/destroy_ml_env.sh <project_name>"
  exit 1
fi

ENV_NAME=$1
PROJECT_DIR="$(pwd)/$ENV_NAME"

if [ -d "$PROJECT_DIR" ]; then
  echo "🗑️ Deleting project folder: $PROJECT_DIR"
  rm -rf "$PROJECT_DIR"
else
  echo "⚠️ Project folder not found."
fi

if conda info --envs | grep -q "^$ENV_NAME\s"; then
  echo "🧨 Removing conda environment: $ENV_NAME"
  conda remove -y --name "$ENV_NAME" --all
else
  echo "⚠️ Conda environment '$ENV_NAME' not found."
fi

if jupyter kernelspec list | grep -q "$ENV_NAME"; then
  echo "🧹 Unregistering Jupyter kernel: $ENV_NAME"
  jupyter kernelspec uninstall -y "$ENV_NAME"
else
  echo "⚠️ No Jupyter kernel registered for '$ENV_NAME'"
fi

echo "✅ Cleanup complete."
