module Applications where

import XMonad.Core (X, spawn)

-- print screen FULL
execPrint :: X ()
execPrint = spawn "scrot -f ~/Documents/Pictures/Screenshots/%F-%H%M%S.png"

-- print screen to clipboard
execXclipPrint :: X ()
execXclipPrint = spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png"

-- print screen to clipboard, display on vimiv (kind of like making a sticky note)
execStickyPrint :: X ()
execStickyPrint = spawn "scrot -s -f -e 'xclip -selection clipboard -t image/png -i \"$f\"; vimiv \"$f\"' /var/tmp/%F-%H%M%S.png"

-- screen lock
execLock :: X ()
execLock =
  spawn
    "i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa"

-- mic loopback 
execMicLoopback :: X ()
execMicLoopback =
  spawn
    "sh -c 'ID=$(pactl list short modules | grep module-loopback | cut -f1 | head -n1); [ -n \"$ID\" ] && pactl unload-module \"$ID\" || pactl load-module module-loopback latency_msec=1'"

-- status win debug
execStatusWindow :: X ()
execStatusWindow =
  spawn "$HOME/.config/xmonad/status-window"
