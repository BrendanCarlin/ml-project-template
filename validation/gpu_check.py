# gpu_check.py
import torch
import tensorflow as tf

print("=== PyTorch ===")
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Device:", torch.cuda.get_device_name(0))

print("\n=== TensorFlow ===")
gpus = tf.config.list_physical_devices('GPU')
print("Detected GPUs:", gpus)
