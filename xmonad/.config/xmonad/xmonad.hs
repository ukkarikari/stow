
import Data.Ratio
import Data.List (find)
import Data.Typeable
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
import XMonad.Layout.BinaryColumn

import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.DecorationMadness
import XMonad.Layout.Decoration
import XMonad.Layout.SimpleDecoration

import XMonad.Actions.GridSelect
import XMonad.Actions.UpdatePointer
import qualified XMonad.Actions.DynamicWorkspaces as DW
import XMonad.Actions.WithAll
import qualified XMonad.Util.ExtensibleState as XS
import XMonad.Actions.WindowMenu

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
      logHook = refocusLastLogHook <+> myLogHook dzen,
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
  [ 
    "audio",
    "reading"
  ]


myLayouts =
  MT.mkToggle (MT.single LAYOVERWRITE) $
  MT.mkToggle (MT.single MIRROR) $
    onWorkspace "web" webLayouts $
    onWorkspace "remote" remoteLayouts $
    onWorkspace "temp" tempLayouts $ 
    projectLayout -- (dynamic workspace test) currently this fallback will be used for the 'project workspaces'



--  --- this is the default layout for new workspaces (!) ---
projectLayout = boringWindows $
      myFloat
  ||| noBorders Simplest
  ||| twoPaneThing 2 (1/2)
-- ----------------------------------------------------------


webLayouts = boringWindows $
       noBorders (tabbedBottom shrinkText myTabTheme)
   -- ||| twoPaneThing 2 (1/2)

remoteLayouts = boringWindows $
      roledexGapDeco
  ||| noBorders (tabbedBottom shrinkText myTabTheme)
 
tempLayouts = 
  noBorders Simplest


-- =========================================================================
--                                LAYOUTS  
-- =========================================================================

{-# ANN myDecorate ("HLint: ignore Eta reduce" :: String) #-}

-- custom layout definitions

myFloat = 
  mouseResize $ maxMagnifierOff (myDecorate simplestFloat)

twoPaneThing win_n ratio = 
  limitWindows win_n ( noBorders (magnifierczOff' 1.3 (ResizableTall 1 (3 / 100) ratio [])) ) 
 
roledexGapDeco =
  myDecorate 
   ( gaps [(L, 60), (R, 60), (U, 10), (D, 10)]
       (reflectVert Roledex)
   )

theTape =
  myDecorate
   ( gaps [(L, 20), (R, 20), (U, 175), (D, 175)]
        (Mirror (BinaryColumn 0.0 32))
   )

  
-- decoration helper
myDecorate l = -- the l in this decorate function is to fix the 'a0' ambiguity error
  noFrillsDeco shrinkText myTabTheme l

-- global layout overwrite toggle
data LAYOVERWRITE = LAYOVERWRITE deriving (Read, Show, Eq, Typeable)

-- multi toggle that overwrites the current layout with another
instance MT.Transformer LAYOVERWRITE Window where
    transform LAYOVERWRITE x k = k (boringWindows $ theTape ) (\_ -> x)



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


-- (dynamic workspaces test)
-- goes to workspace if it exists, creates a new one if it doesnt (maybe integrate inside gridSelect)
gotoWorkspace :: WorkspaceId -> X ()
gotoWorkspace ws = do
  exists <- gets $
      any ((==ws) . W.tag) . W.workspaces . windowset

  if exists
      then windows (W.greedyView ws)
      else do
          DW.addHiddenWorkspace ws
          windows (W.greedyView ws)
          initializeWorkspace ws

-- init for starting workspace specific applications
initializeWorkspace :: WorkspaceId -> X()
initializeWorkspace "mail" =
  spawn "betterbird"

initializeWorkspace _ =
  pure ()


-- grid select for layouts
myWorkspaceSelector :: GSConfig (WorkspaceId, Bool) -> X ()
myWorkspaceSelector conf = do
  ws <- gets (W.workspaces . windowset)

  let entries =
        [ (W.tag w, (W.tag w, isNothing w))
        | w <- ws
        ]
      isNothing w = W.stack w == Nothing

  gridselect conf entries
    >>= flip whenJust (\(name, _) -> windows (W.greedyView name))


-- workspace gridselect colorizer
myWorkspaceColorizer :: (WorkspaceId, Bool) -> Bool -> X (String, String)
myWorkspaceColorizer (_, empty) active =
  return $
    case (active, empty) of
      (True, _)      -> ("#ffffff", "#000000")  -- selected
      (False, True)  -> ("#222222", "#666666")  -- empty workspace
      (False, False) -> ("#222222", "#ffffff")  -- non-empty workspace


-- workspace gridselect theme
myWorkspaceGSConfig :: GSConfig (WorkspaceId, Bool)
myWorkspaceGSConfig = def
  { gs_cellheight   = 50
  , gs_cellwidth    = 180
  , gs_cellpadding  = 10
  , gs_font         = "xft:Terminus:size=11"
  , gs_colorizer    = myWorkspaceColorizer
  }


-- window gridselect colorizer
myWindowColorizer :: Window -> Bool -> X (String, String)
myWindowColorizer =
  colorRangeFromClassName
    (0x22,0x22,0x22)
    (0x66,0x66,0x66)
    (0x44,0xAA,0xCC)
    (0xBB,0xBB,0xBB)
    (0x00,0x00,0x00)


-- bringSelected theme
myWindowGSConfig :: GSConfig Window
myWindowGSConfig = def
  { gs_cellheight   = 50
  , gs_cellwidth    = 200
  , gs_cellpadding  = 10
  , gs_font         = "xft:Terminus:size=11"
  , gs_colorizer    = myWindowColorizer
  }


-- keyboard layout toggle prompt
keyboardLayoutPrompt :: X ()
keyboardLayoutPrompt =
  inputPrompt myXPConfig "keyboard layout (us/br)"
    ?+ \choice ->
      case choice of
        "us" ->
          spawn "setxkbmap -layout us"

        "br" ->
          spawn "setxkbmap -layout br -variant thinkpad"

        _ ->
          return ()


-- debug utility (WIP)
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


-- ---- FLOAT WEIRD THINGS ---

-- state for float
newtype FloatPreset = FloatPreset Int
    deriving (Read, Show)

instance ExtensionClass FloatPreset where
    initialValue = FloatPreset 0

-- data types
newtype GeometryPreset = GeometryPreset Int
    deriving (Read, Show)

instance ExtensionClass GeometryPreset where
    initialValue = GeometryPreset 0

-- kind of emulation of RationalRect
centeredRect :: Rational -> Rational -> Rectangle -> Rectangle
centeredRect wf hf (Rectangle sx sy sw sh) =
    let sw' = fromIntegral sw :: Rational
        sh' = fromIntegral sh :: Rational

        w = floor (sw' * wf)
        h = floor (sh' * hf)

        x = fromIntegral sx + (fromIntegral sw - w) `div` 2
        y = fromIntegral sy + (fromIntegral sh - h) `div` 2
    in Rectangle
        (fromIntegral x)
        (fromIntegral y)
        (fromIntegral w)
        (fromIntegral h)

-- presets
small  = centeredRect 0.5 0.45
vertical = centeredRect 0.45 0.85
large  = centeredRect 0.80 0.75

-- presets for floating window sizes
presets :: [Rectangle->Rectangle]
presets =
    [ small
    , vertical
    , large
    ]

-- cycle thru geoms cos im not using the xm floating layer
cycleGeometry :: X ()
cycleGeometry = do
    GeometryPreset i <- XS.get

    ws <- gets windowset
    let screen =
            screenRect
          . W.screenDetail
          . W.current
          $ ws

    sendMessage $ SetGeometry ((presets !! i) screen)

    XS.put $ GeometryPreset ((i + 1) `mod` length presets)


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
    [
    -- lock xss cmd
    "xss-lock 'i3lock -c 00000022 --verif-font=Unifont --wrong-font=Unifont --ring-color ffffff20 --inside-color 00000000 --line-color 00000000 --keyhl-color ffffffaa'"

    , "pkill picom ; picom --backend glx --fading --fade-delta 2 --config $HOME/.config/picom/picom-config"

      --    TODO edit the wpp src and change this botch
      -- , "$HOME/.local/bin/wppsnow"
      -- , "sleep 2 ; xdotool search --name \"wpp\" windowlower windowsize 1440 900 windowmove 0 0"

    , "xrdb -merge $HOME/.Xresources"
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
    -- layout overwrite
    , ("M-S-o", sendMessage $ MT.Toggle LAYOVERWRITE)


    --     --  floating windows  --

    -- movmt
    , ("M-S-h", sendMessage (MoveLeft 45))
    , ("M-S-l", sendMessage (MoveRight 45))
    , ("M-S-k", bindByLayout [ ("Magnifier (off) NoFrillsDeco SimplestFloat", sendMessage (MoveUp 45)),
                               ("", windows W.swapUp) ] )
    , ("M-S-j", bindByLayout [ ("Magnifier (off) NoFrillsDeco SimplestFloat", sendMessage (MoveDown 45)),
                               ("", windows W.swapDown) ])
    -- resize
    , ("M-C-h", sendMessage (DecreaseLeft 45))
    , ("M-C-l", sendMessage (IncreaseRight 45))
    , ("M-C-k", sendMessage (DecreaseUp 45))
    , ("M-C-j", sendMessage (IncreaseDown 45))
    -- , ("M-S-g", sendMessage $ SetGeometry (Rectangle 200 100 500 300))
   , ("M-S-g", cycleGeometry)
  ]


utilityKeybinds =
  [
      -- shell prompts
      ("M-S-p", passPrompt myXPConfig)
    , ("M-p", shellPrompt myXPConfig)

      -- rename winodw
    , ("C-S-r", renameFocusedPrompt myXPConfig) 

    -- workspaceSelector
    , ("M-<Tab>", myWorkspaceSelector myWorkspaceGSConfig)
    , ("M-S-<Tab>", bringSelected myWindowGSConfig)
    , ("M-C-<Space>", windowMenu)

    -- change layout
    , ("C-<Space>", keyboardLayoutPrompt)

    -- (dynamic workspaces test) prompt to create new workspace
    , ("C-M-n", workspacePrompt myXPConfig gotoWorkspace)

    -- (dynamic workspaces test) kill all workspace processes and remove workspace
    , ("C-M-<Backspace>", do 
                              killAll
                              DW.removeWorkspace
    )

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
    ("M-<F2>", bindOn [("aux", do
                          spawn "urxvt -e sh -c 'btop; bash'"
                          spawn "sleep 0.5; snow"
                          spawn "sleep 1; xload")
                    ])

  -- toggle mic feedback
  , ("M-C-m", execMicLoopback)

  -- debug window test
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
