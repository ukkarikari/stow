module Hooks where

-- local
import Appearance (myPP)
import Utilities (myDebugLog)
--
import XMonad.Actions.UpdatePointer (updatePointer)
import XMonad.Core (ManageHook, WorkspaceId, X, handleEventHook)
import XMonad.Hooks.InsertPosition (Focus (Newer), Position (Below), insertPosition)
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.RefocusLast (refocusLastWhen)
import XMonad.Hooks.StatusBar.PP (def, dynamicLogWithPP)
import XMonad.ManageHook
import XMonad.Operations (windows)
import XMonad.StackSet qualified as W
--
import XMonad.Util.SpawnOnce (spawnOnce)

moveAndFollow :: WorkspaceId -> X ()
moveAndFollow ws =
  windows (W.shift ws)

-- ------- startup hook -------
myStartupHook = do
  spawnOnce "redshift -r -l manual"
  mapM_
    spawnOnce
    [ -- lock xss cmd
      "xss-lock 'i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa'",
      "pkill picom ; picom --backend glx --fading --fade-delta 2 --config $HOME/.config/picom/picom-config",
      --    TODO edit the wpp src and change this botch
      -- , "$HOME/.local/bin/wppsnow"
      -- , "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0"

      "xrdb -merge $HOME/.Xresources"
    ]

--  -------  manage hook ------
myManageHook :: ManageHook
myManageHook =
  composeAll
    [ isDialog --> doFloat <+> doF W.shiftMaster,
      className =? "Peek" --> doFloat,
      className =? "Xmessage" --> doCenterFloat,
      className =? "dzen2" --> doIgnore, -- ignore border
      title
        =? "watch"
        --> doRectFloat (W.RationalRect 0.6 0.0 0.4 0.3),
      title =? "wpp" --> doIgnore -- ignore wallpaper
    ]
    <+> insertPosition Below Newer

-- -------  log hook  ---------
myLogHook dzen = do
  updatePointer (0.5, 0.5) (0, 0)
  myDebugLog
  dynamicLogWithPP (myPP dzen)

-- -----  handle event hook -----
myHandleEventHook =
  refocusLastWhen (pure True)
    <> handleEventHook def
