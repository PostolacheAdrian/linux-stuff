#!/bin/bash

/usr/lib/at-spi-bus-launcher --launch-immediately &
dbus-update-activation-environment --all & 
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 
/usr/lib/polkit-kde-authentication-agent-1 &
/usr/lib/xdg-desktop-portal-hyprland & 
sleep 2
/usr/lib/xdg-desktop-portal &
#exec /usr/lib/xdg-desktop-portal 
hyprctl setcursor Bibata-Original-Ice 24 & 
waybar &  
dunst &
nm-applet & 
blueman-applet & 
hyprpaper &
