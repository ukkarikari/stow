
import Data.Ratio
import System.IO (hPutStrLn)
import System.IO (Handle)

import XMonad

import XMonad.Layout.Accordion
import XMonad.Layout.CircleEx
import XMonad.Layout.Gaps
import XMonad.Layout.IfMax
import XMonad.Layout.Magnifier
import XMonad.Layout.PerWorkspace 
import qualified XMonad.Layout.Renamed as Renamed
import XMonad.Layout.ResizableTile
import XMonad.Layout.StackTile
import XMonad.Layout.Tabbed
import XMonad.Layout.SimpleFloat
import XMonad.Layout.SimplestFloat

import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.DecorationMadness
import XMonad.Layout.Decoration
import XMonad.Layout.SimpleDecoration

import XMonad.Actions.GridSelect
import XMonad.Actions.UpdatePointer

import XMonad.Layout.Column
import XMonad.Layout.HintedGrid
import XMonad.Layout.IM
import XMonad.Layout.WindowArranger
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation
import XMonad.Layout.Simplest
import XMonad.Layout.FocusTracking
import XMonad.Layout.LimitWindows
import XMonad.Layout.Roledex
import XMonad.Layout.TwoPanePersistent
import XMonad.Layout.AutoMaster
import XMonad.Layout.Reflect
import XMonad.Layout.CenteredMaster
import XMonad.Layout.Spiral

import XMonad.Actions.PerLayoutKeys
import XMonad.Actions.PerWorkspaceKeys

import XMonad.Layout.BoringWindows
import XMonad.Layout.PerScreen
import XMonad.Layout.NoBorders
import qualified XMonad.Layout.MultiToggle as MT
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.Spacing
import qualified XMonad.Layout.BoringWindows as BW
import XMonad.Actions.MouseResize
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig

import XMonad.Util.NamedWindows (getName)
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import XMonad.Prompt
import XMonad.Prompt.Input
import XMonad.Prompt.Shell
import XMonad.Prompt.Pass
import XMonad.Prompt.Workspace

import Config.GridSelect

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Hooks.RefocusLast
import XMonad.Hooks.Place


--     ---- index ----
-- 
-- main
-- workspaces
-- layouts
-- appearance
-- utilites
-- hooks
-- applications
-- keybindings
-- 
--     ----------------


-- =========================================================================
--                                 MAIN                                   
-- =========================================================================
main :: IO ()
main = do
  dzen <- spawnPipe myDzenCmd
  xmonad
    . docks
    . ewmh
    $ myConfig dzen


myConfig dzen =
  def
    { modMask = mod4Mask, -- rebind alt to win
      layoutHook = myLayouts,
      manageHook = myManageHook <+> manageDocks <+> placeHook simpleSmart <+> manageHook def,
      startupHook = myStartupHook,
      logHook = myLogHook dzen,
      handleEventHook = myHandleEventHook,
      workspaces = myWorkspaces,
      focusFollowsMouse = False,
      terminal = "urxvt",
      normalBorderColor = "#888888",
      focusedBorderColor = "#ffffff"
    }
    `removeKeysP` myRemovedKeys
    `additionalKeysP` myKeybs


-- =========================================================================
--                             WORKSPACE-LAYOUTS                         
-- =========================================================================
myWorkspaces :: [WorkspaceId]
myWorkspaces =
  [ "code",
    "web",
    "code_alt",
    "rdp",
    "aux",
    "research",
    "media"
  ]

myLayouts =
  MT.mkToggle (MT.single MIRROR) $
    onWorkspace "code" codeLayouts $
    onWorkspace "code_alt" codeAltLayouts $
    onWorkspace "web" webLayouts $
    onWorkspace "aux" auxLayouts $
    onWorkspace "research" researchLayouts $ 
    onWorkspace "media" mediaLayouts 
    defaultLayout

codeLayouts = boringWindows $
      twoPaneThing 2 (9/16)
  ||| noBorders Simplest

codeAltLayouts = boringWindows $
      twoPaneThing 2 (9/16)
  ||| noBorders Simplest

webLayouts = boringWindows $
       twoPaneThing 2 (1/2)
   ||| noBorders (tabbedBottom shrinkText myTabTheme)

auxLayouts = boringWindows $
      spiral (9/10) 
  ||| myDecorate simplestFloat
       
researchLayouts = boringWindows $
      twoPaneThing 3 (1/2)
  ||| noBorders Simplest

mediaLayouts = boringWindows $
  roledexGapDeco
  ||| noBorders Simplest
  
defaultLayout = boringWindows $
  noBorders Simplest
  ||| myDecorate simplestFloat


-- =========================================================================
--                                LAYOUTS  
-- =========================================================================

{-# ANN myDecorate ("HLint: ignore Eta reduce" :: String) #-}

-- helpers
myDecorate l = -- the l in this decorate function is to fix the 'a0' ambiguity error
  noFrillsDeco shrinkText myTabTheme l

-- my layout definitions
twoPaneThing win_n ratio = 
  limitWindows win_n ( noBorders (magnifierczOff' 1.3 (ResizableTall 1 (3 / 100) ratio [])) ) 
 
roledexGapDeco =
  myDecorate 
   ( gaps [(L, 30), (R, 30), (U, 10), (D, 10)]
       (reflectVert Roledex)
   )


-- =========================================================================
--                                APPEARANCE  
-- =========================================================================

-- -------- decorator themes -----------
myTabTheme :: Theme
myTabTheme = def
  { fontName            = "xft:Terminus:size=8"
  , activeColor         = "#8a999e"
  , inactiveColor       = "#545d75"
  , activeBorderColor   = "#ccd0d2"
  , inactiveBorderColor = "#6c758a"
  , activeTextColor     = "#ffffff"
  , inactiveTextColor   = "#9699a2"
  , decoHeight          = 14
  }

myXPConfig :: XPConfig
myXPConfig = def
  { font                = "xft:Cozette:size=10"
  , bgColor             = "#545d75"
  , fgColor             = "#ffffff"
  , bgHLight            = "#8a999e"
  , fgHLight            = "#ffffff"
  , borderColor         = "#6c758a"
  , promptBorderWidth   = 1
  , height              = 18
  , position            = CenteredAt 0.4 0.75 
  , historySize         = 100
  }

-- ----------------- PRETTY PRINTER and DZEN --------------------
-- [main] -> [myConfig] -> [logHook] -> [myPP] -> [dzen2 process]
-- --------------------------------------------------------------

-- ---------- dzen command ----------
myDzenCmd :: String
-- myDzenCmd =
--   "dzen2"
--     ++ " -dock"
--     ++ " -ta r"
--     ++ " -fn Cozette:bold:size=10"
--     ++ " -bg #000000"
--     ++ " -fg #ffffff"

myDzenCmd = "" --temp 

-- ---------- pretty printer ----------
myPP h =
  def
    { ppOutput = hPutStrLn h,
      ppOrder = \(ws : l : t : ex) -> [l, t, ws] ++ ex,
      ppCurrent = dzenColor "#000000" "#f9f9f9" . wrap " " " ",
      ppHidden = wrap " " " ",
      ppSep = " ",
      ppExtras = [mySpace]
    }

-- just another space
mySpace :: X (Maybe String)
mySpace = do
  return (Just (" "))


-- =========================================================================
--                                UTILITIES
-- =========================================================================

-- --------- interesting renaming window utility (useful for urxvt) ---------
renameFocusedPrompt :: XPConfig -> X ()
renameFocusedPrompt conf =
    inputPrompt conf "Rename window" ?+ \title ->
        withFocused $ \w ->
            safeSpawn "wmctrl"
                ["-i", "-r", show w, "-T", title]

-- debug utility
myDebugLog :: X ()
myDebugLog =
  withWindowSet $ \ws -> do
    let curWs =
          W.currentTag ws

        layoutName =
          description $
            W.layout $
              W.workspace $
                W.current ws

        stackOrder =
          maybe []
                W.integrate
                ( W.stack
                $ W.workspace
                $ W.current ws
                )
        focused = W.peek ws

    names <- mapM getName stackOrder

    
    let stackLines =
          zipWith
            (\w name ->
                (if Just w == focused then "* " else "  ")
                ++ show name
                ++ " ("
                ++ show w
                ++ ")"
            )
            stackOrder
            names

    io $
      writeFile "/tmp/xmonad-debug" $
        unlines $
          [ "workspace: " ++ curWs
          , "layout:    " ++ layoutName
          , ""
          , "stack:"
          ]
          ++ stackLines


-- =========================================================================
--                                    HOOKS
-- =========================================================================

moveAndFollow ws =
  windows (W.shift ws)

-- ------- startup hook -------
myStartupHook = do
  spawnOnce "redshift -r -l manual"
  mapM_
    spawnOnce
    [ -- lock xss cmd
    "xss-lock 'i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa'",
    "pkill picom ; picom --backend glx --fading --fade-delta 2 --config $HOME/.config/picom/picom-config"
      --    TODO edit the wpp src and change this botch
      -- , "$HOME/.local/bin/wppsnow"
      -- , "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0"
    ]


--  -------  manage hook ------
myManageHook :: ManageHook
myManageHook =
  composeAll
    [ isDialog --> doFloat <+> doF W.shiftMaster,
      className =? "Peek" --> doFloat,
      className =? "Xmessage" --> doCenterFloat,
      className =? "dzen2" --> doIgnore, -- ignore border
      title =? "watch"
        --> doRectFloat (W.RationalRect 0.6 0.0 0.4 0.3),
      title =? "wpp" --> doIgnore -- ignore wallpaper
    ]
    <+> insertPosition Below Newer


-- -------  log hook  ---------
myLogHook dzen = do
    refocusLastLogHook
    updatePointer (0.5, 0.5) (0, 0)
    myDebugLog 
    dynamicLogWithPP (myPP dzen)


-- -----  handle event hook -----
myHandleEventHook =
    refocusLastWhen (pure True)
    <> handleEventHook def



-- =====================================================================
--                             APPLICATIONS                            
-- =====================================================================

execPrint = spawn "scrot -f ~/Documents/Pictures/Screenshots/%F-%H%M%S.png"
execXclipPrint = spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png"

execLock = spawn
  "i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa"

execMicLoopback = spawn
  "sh -c 'ID=$(pactl list short modules | grep module-loopback | cut -f1 | head -n1); [ -n \"$ID\" ] && pactl unload-module \"$ID\" || pactl load-module module-loopback latency_msec=1'"

-- =====================================================================
--                                KEYBINDS                            
-- =====================================================================

myKeybs =
  windowKeybindss
    ++ utilityKeybinds
    ++ tempKeybinds

windowKeybindss =
  [
    -- overwrite with boring windows
      ("M-k", BW.focusUp)
    , ("M-j", BW.focusDown)
    , ("M-m", BW.focusMaster)
    , ("M-b", BW.markBoring)
    , ("M-S-b", BW.clearBoring)

    -- increase/decrease slave size
    , ("M-z", sendMessage MirrorShrink)
    , ("M-a", sendMessage MirrorExpand)

    -- magnifier keys
    , ("M-=", sendMessage Toggle)
    , ("M-S-=", sendMessage MagnifyMore)
    , ("M--", sendMessage MagnifyLess)

    -- mirror
    , ("M-S-m", sendMessage $ MT.Toggle MIRROR)

    --     --  floating windows  --

    -- movmt
    , ("M-S-h", sendMessage (MoveLeft 45))
    , ("M-S-l", sendMessage (MoveRight 45))
    , ("M-S-k", bindByLayout [ ("NoFrillsDeco SimplestFloat", sendMessage (MoveUp 45)),
                               ("", windows W.swapUp) ] )
    , ("M-S-j", bindByLayout [ ("NoFrillsDeco SimplestFloat", sendMessage (MoveDown 45)),
                               ("", windows W.swapDown) ])
    -- resize
    , ("M-C-h", sendMessage (DecreaseLeft 45))
    , ("M-C-l", sendMessage (IncreaseRight 45))
    , ("M-C-k", sendMessage (IncreaseDown 45))
    , ("M-C-j", sendMessage (DecreaseUp 45))
    , ("M-S-g", sendMessage $ SetGeometry (Rectangle 200 100 500 300))
  ]


utilityKeybinds =
  [
      -- shell prompts
      ("M-S-p", passPrompt myXPConfig)
    , ("M-p", shellPrompt myXPConfig)
      -- rename winodw
    , ("C-S-r", renameFocusedPrompt myXPConfig) 
    -- workspaceSelector
    , ("M-<Tab>", myWorkspaceSelector myGSConfig)
    , ("M-S-<Tab>", bringSelected def)
    -- screenshot
    , ("<Print>", execPrint)
    , ("S-<Print>", execXclipPrint)
      -- screen lock
    , ("<XF86ScreenSaver>", execLock)
    , ("M-S-C-s", execLock)
      -- audio
    , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%-")
    , ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%+")
    , ("<XF86AudioMute>",        spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  ]

tempKeybinds =
  [ 
    -- spawn windows on aux
    ("<F2>", bindOn [("aux", do
                          spawn "urxvt -e sh -c 'btop; bash'"
                          spawn "sleep 0.5; snow"
                          spawn "sleep 1; xload")
                    ])

  -- toggle mic feedback
  , ("M-C-m", execMicLoopback)

  -- test
  , ("M-C-d",
    spawn "urxvt -name xmonad-debug -e watch -n 0.2 'cat /tmp/xmonad-debug'") -- test
  ]


myRemovedKeys =
  [ "M-S-q", -- disable default exit
    "M-p", -- disable default dmenu
    "M-1",
    "M-2",
    "M-3",
    "M-7",
    "M-8",
    "M-4",
    "M-S-4",
    "M-5",
    "M-S-5",
    "M-6",
    "M-S-6",
    "M-9",
    "M-S-9"
  ]
