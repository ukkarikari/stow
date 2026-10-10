import Appearance
import Applications
import Hooks
import Keybinds
import Layouts
import Utilities
import Workspaces
-- XMonad
import XMonad
import XMonad.Core
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (docks, manageDocks)
import XMonad.Hooks.Place (placeHook, simpleSmart)
import XMonad.Hooks.RefocusLast (refocusLastLogHook)
import XMonad.Main (xmonad)
import XMonad.Util.EZConfig (additionalKeysP, removeKeysP)
import XMonad.Util.Run (spawnPipe)

main :: IO ()
main = 
  xmonad
    . docks
    . ewmh
    $ myConfig 

myConfig =
  def
    { modMask = mod4Mask, -- rebind alt to win
      layoutHook = myLayouts,
      manageHook = myManageHook <+> manageDocks <+> placeHook simpleSmart <+> manageHook def,
      startupHook = myStartupHook,
      logHook = myLogHook,
      handleEventHook = myHandleEventHook,
      workspaces = myWorkspaces,
      focusFollowsMouse = False,
      terminal = "urxvt",
      normalBorderColor = "#888888", -- gray
      focusedBorderColor = "#ffffff" -- white
    }
    `removeKeysP` myRemovedKeys
    `additionalKeysP` myKeybs
