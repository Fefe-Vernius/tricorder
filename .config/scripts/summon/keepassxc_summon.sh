#!/bin/bash

#Find the window ID for Vivaldi Flatpak and focus it
window_id=$(niri msg -j windows | jq -r '.[] | select(.app_id == "org.keepassxc.KeePassXC") | .id' | head -n1)

if [ -n "$window_id" ]; then
    niri msg action focus-window --id "$window_id"
else
    flatpak run org.keepassxc.KeePassXC
fi
