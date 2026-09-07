{-# LANGUAGE LambdaCase #-}

module Utilities where

-- local
import Appearance (myXPConfig)
-- fix recursion
import Data.Maybe (isNothing)
-- XMonad
import XMonad
import XMonad.Actions.DynamicWorkspaces qualified as DW
import XMonad.Actions.GridSelect
import XMonad.Core (ExtensionClass, WorkspaceId, X, initialValue)
import XMonad.Layout.WindowArranger (WindowArrangerMsg (SetGeometry))
import XMonad.Prompt (XPConfig)
import XMonad.Prompt.Input (inputPrompt, (?+))
import XMonad.StackSet qualified as W
import XMonad.Util.ExtensibleState qualified as XS
import XMonad.Util.NamedWindows (getName)
import XMonad.Util.Run (safeSpawn)

-- --------- interesting renaming window utility (useful for urxvt) ---------
renameFocusedPrompt :: XPConfig -> X ()
renameFocusedPrompt conf =
  inputPrompt conf "Rename window" ?+ \title ->
    withFocused $ \w ->
      safeSpawn
        "wmctrl"
        ["-i", "-r", show w, "-T", title]

-- (dynamic workspaces test)
-- goes to workspace if it exists, creates a new one if it doesnt (maybe integrate inside gridSelect)
gotoWorkspace :: WorkspaceId -> X ()
gotoWorkspace ws = do
  exists <-
    gets $
      any ((== ws) . W.tag) . W.workspaces . windowset

  if exists
    then windows (W.greedyView ws)
    else do
      DW.addHiddenWorkspace ws
      windows (W.greedyView ws)
      initializeWorkspace ws

-- init for starting workspace specific applications
initializeWorkspace :: WorkspaceId -> X ()
initializeWorkspace "mail" =
  spawn "betterbird"
initializeWorkspace _ =
  pure ()

-- grid select for layouts
myWorkspaceSelector :: GSConfig (WorkspaceId, Bool) -> X ()
myWorkspaceSelector conf = do
  ws <- gets (W.workspaces . windowset)

  let entries =
        [ (W.tag w, (W.tag w, isNothing (W.stack w)))
          | w <- ws
        ]

  gridselect conf entries
    >>= flip whenJust (\(name, _) -> windows (W.greedyView name))

-- workspace gridselect colorizer
myWorkspaceColorizer :: (WorkspaceId, Bool) -> Bool -> X (String, String)
myWorkspaceColorizer (_, empty) active =
  return $
    case (active, empty) of
      (True, _) -> ("#ffffff", "#000000") -- selected
      (False, True) -> ("#222222", "#666666") -- empty workspace
      (False, False) -> ("#222222", "#ffffff") -- non-empty workspace

-- workspace gridselect theme
myWorkspaceGSConfig :: GSConfig (WorkspaceId, Bool)
myWorkspaceGSConfig =
  def
    { gs_cellheight = 50,
      gs_cellwidth = 180,
      gs_cellpadding = 10,
      gs_font = "xft:Terminus:size=11",
      gs_colorizer = myWorkspaceColorizer
    }

-- window gridselect colorizer
myWindowColorizer :: Window -> Bool -> X (String, String)
myWindowColorizer =
  colorRangeFromClassName
    (0x22, 0x22, 0x22)
    (0x66, 0x66, 0x66)
    (0x44, 0xAA, 0xCC)
    (0xBB, 0xBB, 0xBB)
    (0x00, 0x00, 0x00)

-- bringSelected theme
myWindowGSConfig :: GSConfig Window
myWindowGSConfig =
  def
    { gs_cellheight = 50,
      gs_cellwidth = 200,
      gs_cellpadding = 10,
      gs_font = "xft:Terminus:size=11",
      gs_colorizer = myWindowColorizer
    }

-- keyboard layout toggle prompt
keyboardLayoutPrompt :: X ()
keyboardLayoutPrompt =
  inputPrompt myXPConfig "keyboard layout (us/br)"
    ?+ \case
      "us" ->
        spawn "setxkbmap -layout us"
      "br" ->
        spawn "setxkbmap -layout br -variant thinkpad"
      _ -> return ()

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
          maybe
            []
            W.integrate
            ( W.stack $
                W.workspace $
                  W.current ws
            )
        focused = W.peek ws

    names <- mapM getName stackOrder

    let stackLines =
          zipWith
            ( \w name ->
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
          [ "workspace: " ++ curWs,
            "layout:    " ++ layoutName,
            "",
            "stack:"
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
small = centeredRect 0.3 0.45

vertical = centeredRect 0.35 0.95

large = centeredRect 0.65 0.85

minimized = centeredRect 0.35 0.023

-- presets for floating window sizes
presets :: [Rectangle -> Rectangle]
presets =
  [ large,
    vertical,
    small,
    minimized
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
