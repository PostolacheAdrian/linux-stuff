#!/bin/bash
export KWIN_DRM_DEVICES=/dev/dri/card1
export KWIN_DRM_ALLOW_TEARING=1
application="${1:-steam}"
exec /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/kwin_wayland_wrapper --drm --xwayland --no-lockscreen --no-global-shortcuts -- "$application" 

