#!/bin/bash
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export  EGL_PLATFORM=wayland
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
export VDPAU_DRIVER=nvidia
export NVD_BACKEND=direct
export GSK_RENDERER=ngl
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export WLR_NO_HARDWARE_CURSORS=1
export SDL_VIDEODRIVER=wayland
#NVD_GPU=0
#DRI_PRIME=1
#:/usr/share/glvnd/egl_vendor.d/50_mesa.json
#__GL_GSYNC_ALLOWED=1
#__GL_VRR_ALLOWED=1
#__GL_SYNC_TO_VBLANK=0
#__VK_LAYER_NV_optimus=NVIDIA_only
#__NV_PRIME_RENDER_OFFLOAD=1
