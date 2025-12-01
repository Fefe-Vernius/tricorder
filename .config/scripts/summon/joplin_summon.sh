#!/bin/bash

#Find Joplin's connection ID for tray
joplin_conn=$(busctl --user list | grep joplin | awk '{print $1}' | head -2 | tail -1)
#Find window ID, in case it is open
joplin_window_id=$(niri msg -j windows | jq -r '.[] | select(.app_id == "@joplin/app-desktop") | .id' | head -n1)

if [[ -z "$joplin_conn" ]]; then
    #if it is not running, start it
    /home/fefe/.progs/joplin/Joplin-3.4.12.AppImage
else
    #if running, check for open window first, else open from tray
    if [ -n "$joplin_window_id" ]; then
        #switch focus to Joplin's window
        niri msg action focus-window --id "$joplin_window_id"
    else
        #emulate a left-click on Joplin's tray icon
        gdbus call --session \
          --dest "$joplin_conn" \
          --object-path /StatusNotifierItem \
          --method org.kde.StatusNotifierItem.Activate 0 0
    fi
fi
