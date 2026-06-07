
import Data.Ratio
import System.IO (hPutStrLn)
import XMonad
import XMonad.Actions.GridSelect
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WindowBringer
import XMonad.Actions.FloatSnap
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.InsertPosition
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Hooks.RefocusLast
import XMonad.Hooks.Place
import XMonad.Layout.Accordion
import XMonad.Layout.CircleEx
import XMonad.Layout.Gaps
import XMonad.Layout.IfMax
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiDishes
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace 
-- import XMonad.Layout.Renamed
import qualified XMonad.Layout.Renamed as Renamed
import XMonad.Layout.ResizableThreeColumns
import XMonad.Layout.ResizableTile
import XMonad.Layout.StackTile
import XMonad.Layout.Tabbed
import XMonad.Layout.SimpleFloat
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.SimplestFloat
import XMonad.Layout.DecorationMadness
import XMonad.Layout.Decoration
import XMonad.Layout.SimpleDecoration
import XMonad.Layout.HintedGrid
import XMonad.Layout.IM
import XMonad.Layout.WindowArranger
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation
import XMonad.Layout.Simplest
import XMonad.Layout.FocusTracking
import XMonad.Layout.LimitWindows
import XMonad.Layout.BoringWindows
import XMonad.Layout.Roledex
import XMonad.Layout.TwoPanePersistent
import XMonad.Layout.AutoMaster
import XMonad.Layout.Reflect
import XMonad.Layout.CenteredMaster
import XMonad.Layout.Column
import XMonad.Actions.PerLayoutKeys
import XMonad.Layout.Spacing
import qualified XMonad.Layout.BoringWindows as BW
import XMonad.Actions.MouseResize
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig

import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import XMonad.Prompt
import XMonad.Prompt.Input
import XMonad.Prompt.Shell
import XMonad.Prompt.Pass
import XMonad.Prompt.Workspace
import Config.GridSelect

-- ++++++++++ MAIN +++++++++++
main :: IO ()
main = do
  spawn "xrdb -merge $HOME/.Xresources"
  dzen <- spawnPipe myDzenCmd
  xmonad
    . docks
    . ewmh
    $ myConfig dzen

-- ========= PRETTY PRINTER and DZEN  =========
-- [main] -> [myConfig] -> [logHook] -> [myPP] -> [dzen2 process]
-- ============================================

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
      ppExtras = [myCommand, myVolume, mySpace]
    }

-- just another space
mySpace :: X (Maybe String)
mySpace = do
  return (Just (" "))

-- command segment
myCommand :: X (Maybe String)
myCommand = do
  result <- runProcessWithInput "date" [] ""
  return (Just (init result))

-- volume indicator
myVolume :: X (Maybe String)
myVolume = do
  out <- runProcessWithInput "wpctl" ["get-volume", "@DEFAULT_AUDIO_SINK@"] ""
  let status =
        if "[MUTED]" `elem` words out
          then "☏"
          else "☎"
  return (Just status)

-- ========== WORKSPACES =======
myWorkspaces :: [WorkspaceId]
myWorkspaces =
  [ "code",
    "web",
    "code_alt",
    "rdp",
    "aux",
    "write"
  ]

--  ========= LAYOUTS =========
myLayouts =
  onWorkspace "code" codeLayouts $
  onWorkspace "code_alt" codeAltLayouts $
  onWorkspace "web" webLayouts $
  onWorkspace "aux" auxLayouts $
  onWorkspace "rdp" rdpLayouts $
  onWorkspace "write" writeLayouts $ 
  defaultLayout

codeLayouts =
  boringWindows (magnifiercz' 1.3 (TwoPanePersistent Nothing (3/100) (9/16)) ) 
  ||| boringWindows circleSelector
  ||| boringWindows (noBorders Simplest)

codeAltLayouts =
  boringWindows (magnifiercz' 1.3 (TwoPanePersistent Nothing (3/100) (9/16)) ) 
  ||| myFloat
  ||| boringWindows ( noBorders Simplest )

webLayouts =
  -- boringWindows ( magnifierczOff' 1.3 ( TwoPanePersistent Nothing (3/100) (9/16) ) ) 
  boringAuto ( limitWindows 2  ( noBorders (magnifiercz' 1.3 (ResizableTall 1 (3 / 100) (9 / 16) [])) ) )
  ||| boringWindows columnSelector
  -- ||| boringWindows ( noBorders Simplest )

auxLayouts =
  boringWindows (spacingWithEdge 10 (Grid False))
  -- boringWindows $ noFrillsDeco shrinkText myTabTheme ( spacingWithEdge 10 meinKreis )
  -- ||| myFloat
       
rdpLayouts =
      myFloat
  ||| noBorders (tabbedBottom shrinkText myTabTheme)

writeLayouts =
  boringWindows (magnifiercz' 1.3 (TwoPanePersistent Nothing (3/100) (9/16)) ) 
  ||| noBorders Simplest

defaultLayout =
  noBorders Simplest
  ||| simpleFloat' shrinkText myTabTheme


--  --------- definitions ---------

myFloat =
  Renamed.renamed [Renamed.CutWordsLeft 10, Renamed.Replace "My Float"] $
    boringAuto ( mouseResize $ noFrillsDeco shrinkText myTabTheme (magnifierczOff' 1.3 simplestFloat) )

-- ------ weird old circle layout
meinKreis =
    gaps
      [(L, 140), (R, 200), (U, 20), (D, 20)]
        circleEx
          { cMasterRatio = 8 % 8,
            cStackRatio = 4 % 8,
            cMultiplier = 5 % 7,
            cDelta = -2.2 * pi / 4,
            cNMaster = 0
          }

-- ------ circleFloat with my decorator
circleFloatResizable =
  circleDefaultResizable shrinkText myTabTheme

-- ------ weird sort of window order selector to pair with two pane
columnSelector = 
  noFrillsDeco shrinkText myTabTheme
    ( magnifierxyOff' 3.5 1   
      ( spacingWithEdge 2 ( gaps [(L, 20), (R, 20), (U, 20), (D, 20)]
        ( Mirror (autoMaster 1 (5/100)  
               (Mirror $ Column 1.8) )))))


-- ------ same window order selector thing but for cirlce
circleSelector = 
  noFrillsDeco shrinkText myTabTheme
    ( magnifierxyOff' 2 3 
      ( spacingWithEdge 5 ( gaps [(L, 20), (R, 20), (U, 20), (D, 20)]
        ( Mirror ( autoMaster 1 (5/100)
          meinKreis )))))

-- ------- master window + roledex experiment
-- roledexSelector =
--        noFrillsDeco shrinkText myTabTheme
--          ( spacingWithEdge 5 ( gaps [(L, 20), (R, 20), (U, 20), (D, 20)]
--            ( Mirror (autoMaster 1 (1/100)  $
--                   magnifierxyOff 1.4 1.5 (reflectVert Roledex)  ))))


--  ------ weird ifMax abomination
-- ( IfMax 2 (noBorders (magnifiercz' 1.3 (ResizableTall 1 (3 / 100) (3 / 5) []))) $
--     IfMax 3 (maximizeVertical (MultiDishes 2 3 (1 / 8))) $
--       maxMagnifierOff ( Grid False )
-- )


--  ----- when i made TwoPane with BoringWindows because i didnt know TwoPane existed
-- boringAuto ( limitWindows 2  ( noBorders (magnifiercz' 1.3 (ResizableTall 1 (3 / 100) (9 / 16) [])) ) )
-- ------ this one is the same but looks cooler after you switch to floating
-- boringAuto ( limitWindows 3  ( noBorders (magnifiercz' 1.3 (ResizableTall 1 (3 / 100) (9 / 16) [])) ) )
 
  
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

-- ========= interesting renaming window utility =======
renameFocusedPrompt :: XPConfig -> X ()
renameFocusedPrompt conf =
    inputPrompt conf "Rename window" ?+ \title ->
        withFocused $ \w ->
            safeSpawn "wmctrl"
                ["-i", "-r", show w, "-T", title]

-- ========= STARTUP HOOK =========
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

--  ========= MANAGE HOOK =========
myManageHook :: ManageHook
myManageHook =
  composeAll
    [ isDialog --> doFloat <+> doF W.shiftMaster,
      className =? "Peek" --> doFloat,
      className =? "Xmessage" --> doCenterFloat,
      className =? "dzen2" --> doIgnore, -- ignore border
      title =? "wpp" --> doIgnore -- ignore wallpaper
    ]
    <+> insertPosition Below Newer

--  ========= KEYBINDS =========
myKeybs =
  windowKeybs
    ++ utilityKeybs
    ++ miscKeybs

-- ------------------------------
windowKeybs =
  [
    -- overwrite with boring windows
      ("M-k", BW.focusUp)
    , ("M-j", BW.focusDown)
    , ("M-m", BW.focusMaster)
    -- increase/decrease slave size
    , ("M-z", sendMessage MirrorShrink)
    , ("M-a", sendMessage MirrorExpand)
    -- mafnifier key
    , ("M-=", sendMessage Toggle)
    , ("M-S-=", sendMessage MagnifyMore)
    , ("M--", sendMessage MagnifyLess)
    -- toggle doc
    , ("M-S-m", sendMessage ToggleStruts)
    -- ("M-g", withFocused $ snapShrink D Nothing >> snapShrink R Nothing
    --
    -- move floating windo
    , ("M-S-h", sendMessage (MoveLeft 45))
    , ("M-S-l", sendMessage (MoveRight 45))
    , ("M-S-k", bindByLayout [ ("My Float", sendMessage (MoveUp 45)), ("", windows W.swapUp) ] )
    , ("M-S-j", bindByLayout [ ("My Float", sendMessage (MoveDown 45)), ("", windows W.swapDown) ])
    -- increase/decreasing floating window
    , ("M-C-h", sendMessage (DecreaseLeft 45))
    , ("M-C-l", sendMessage (IncreaseRight 45))
    , ("M-C-k", sendMessage (IncreaseDown 45))
    , ("M-C-j", sendMessage (DecreaseUp 45))
    , ("M-S-g", sendMessage $ SetGeometry (Rectangle 300 100 800 600))
    -- move windows (previously overwritten by the move floating window keybs)
    -- , ("M-S-<Up>", windows W.swapUp)
    -- , ("M-S-<Down>", windows W.swapDown)
  ]

utilityKeybs =
  [ -- screenshot tools
      ("<Print>", spawn "scrot -f ~/Documents/Pictures/Screenshots/%F-%H%M%S.png")
    , ("S-<Print>", spawn "scrot -s -e 'xclip -selection clipboard -t image/png -i $f' -f /var/tmp/%F-%H%M%S.png")
      -- screen lock
    , ("<XF86ScreenSaver>", spawn "i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa")
    , ("M-S-C-s", spawn "i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa")
      -- audio
    , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%-")
    , ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%+")
    , ("<XF86AudioMute>", spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
      -- shell prompts
    , ("M-S-p", passPrompt myXPConfig)
    , ("M-p", shellPrompt myXPConfig)
      -- rename winodw
    , ("M-S-r", renameFocusedPrompt myXPConfig)
  ]

miscKeybs =
  [ 
  -- workspaceSelector
    ("M-<Tab>", myWorkspaceSelector myGSConfig)
  , ("M-S-<Tab>", bringSelected def)
  -- toggle mic feedback
  , ("M-S-m", spawn "sh -c 'ID=$(pactl list short modules | grep module-loopback | cut -f1 | head -n1); [ -n \"$ID\" ] && pactl unload-module \"$ID\" || pactl load-module module-loopback latency_msec=1'")
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

moveAndFollow ws =
  windows (W.shift ws)


-- ++++++++++ CONFIGURATION +++++++++
myConfig dzen =
  def
    { modMask = mod4Mask, -- rebind alt to win
      layoutHook = myLayouts,
      manageHook = myManageHook <+> manageDocks <+> placeHook simpleSmart <+> manageHook def,
      startupHook = myStartupHook,
      logHook = do
        refocusLastLogHook
        updatePointer (0.5, 0.5) (0, 0)
        dynamicLogWithPP (myPP dzen),
      handleEventHook =
        refocusLastWhen (pure True)
        <> handleEventHook def,
      workspaces = myWorkspaces,
      focusFollowsMouse = False,
      terminal = "urxvt",
      normalBorderColor = "#888888",
      focusedBorderColor = "#ffffff"
    }
    `removeKeysP` myRemovedKeys
    `additionalKeysP` myKeybs
