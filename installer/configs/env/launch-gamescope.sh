#!/bin/bash
export HYPRCURSOR_THEME=Bibata-Original-Ice
export CURSOR_THEME=Bibata-Original-Ice
export XCURSOR_SIZE=24
export XDG_SESSION_TYPE=wayland
export MOZ_DBUS_REMOTE=1
export MOZ_ENABLE_WAYLAND=1
export MOZ_DISABLE_RDD_SANDBOX=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=gtk3
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_WAYLAND_DISBALE_WINDOWDECORATION=1
export QT_SCALE_FACTOR=1
export GDK_BACKEND=wayland,x11
export GDK_SCALE_FACTOR=1
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export GBM_BACKEND=nvidia-drm
export __NV_PRIME_RENDER_OFFLOAD=1
export __VK_LAYER_NV_optimus=NVIDIA_only
#export WLR_NO_HARDWARE_CURSORS=1
export ENABLE_GAMESCOPE_WSI=1
export WLR_RENDERER=vulkan
sudo setcap 'cap_sys_nice=eip' /usr/bin/gamescope
sudo sysctl vm.swappiness=20
sudo sysctl vm.max_map_count=2147483642
getcap /usr/bin/gamescope
exec gamescope -e -W 1920 -H 1080 -w 1920 -h 1080 -r 240 -f -s 1 --adaptive-sync --force-grab-cursor  --steam -- steam -gamepadui -pipewire-dmabuf


