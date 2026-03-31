#!/bin/bash
export LIBVA_DRIVER_NAME=nvidia
#export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export EGL_PLATFORM=wayland
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json 
export VDPAU_DRIVER=nvidia
export NVD_BACKEND=direct
export GSK_RENDERER=ngl
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
#export WLR_NO_HARDWARE_CURSORS=1
export SDL_VIDEODRIVER=wayland
#NVD_GPU=0
#DRI_PRIME=1
#:/usr/share/glvnd/egl_vendor.d/50_mesa.json
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
#__GL_SYNC_TO_VBLANK=0
#export __VK_LAYER_NV_optimus=NVIDIA_only
#export __NV_PRIME_RENDER_OFFLOAD=1
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE_SIZE=12000000000
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
#export KWIN_DRM_DEVICES=/dev/dri/card1
