{-# LANGUAGE LambdaCase #-}

module Utilities where

-- local
import Appearance (myXPConfig, gsXPConfig)
-- fix recursion
import Data.Maybe (isNothing)
import Data.Map qualified as M
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
import Text.Printf (printf)

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
    { gs_cellheight = 25,
      gs_cellwidth = 90,
      gs_cellpadding = 5,
      gs_font = "xft:Terminus:size=9",
      gs_colorizer = myWorkspaceColorizer
    }


myWindowColorizer :: Window -> Bool -> X (String, String)
myWindowColorizer w selected = do
  cls <- runQuery className w

  let hue = 6 * stringToRatio cls

      --saturation=0.65, value=0.60
      c = 0.60 * 0.65
      m = 0.60 - c
      sector = floor hue `mod` 6 :: Int
      f = hue - fromIntegral (floor hue :: Int)
      x = c * (if even sector then f else 1 - f)

      (r, g, b) = case sector of
        0 -> (c, x, 0)
        1 -> (x, c, 0)
        2 -> (0, c, x)
        3 -> (0, x, c)
        4 -> (x, 0, c)
        _ -> (c, 0, x)

      rgb a = round ((a + m) * 255) :: Int
      color = printf "#%02x%02x%02x"
        (rgb r) (rgb g) (rgb b)

  pure $
    if selected
      then ("#44aacc", "#000000")
      else (color, "#ffffff")


-- bringSelected theme
myWindowGSConfig :: GSConfig Window
myWindowGSConfig =
  def
    { gs_cellheight = 20,
      gs_cellwidth = 80,
      gs_cellpadding = 5,
      gs_font = "xft:Terminus:size= 9",
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
    let currentWorkspace =
          W.workspace $
            W.current ws

        curWs =
          W.tag currentWorkspace

        layoutName =
          description $
            W.layout currentWorkspace

        screenId =
          W.screen $
            W.current ws

        screenGeometry =
          screenRect $
            W.screenDetail $
              W.current ws

        visibleWs =
          map
            (W.tag . W.workspace)
            (W.visible ws)

        hiddenWs =
          map W.tag (W.hidden ws)

        focused =
          W.peek ws

        floating =
          W.floating ws

        focusedIsFloating =
          maybe False (\w -> M.member w floating) focused

        stackOrder =
          maybe
            []
            W.integrate
            (W.stack currentWorkspace)

        windowCount w =
          maybe
            0
            (length . W.integrate)
            (W.stack w)

        workspaceLines =
          map
            ( \w ->
                "  "
                  ++ W.tag w
                  ++ ": "
                  ++ show (windowCount w)
                  ++ " windows | "
                  ++ description (W.layout w)
            )
            (W.workspaces ws)

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
          [ 
            "---",
            "screen:     " ++ show screenId,
            "geometry:   " ++ show screenGeometry,
            "workspace:  " ++ curWs,
            "layout:     " ++ layoutName,
            "visible:    " ++ show visibleWs,
            "hidden:     " ++ show hiddenWs,
            "floating:   "
              ++ show (M.size floating)
              ++ " | focused="
              ++ show focusedIsFloating,
            "---",
            "stack:",
            ""
          ]
            ++ stackLines
            -- ++ [ "", "workspaces:" ]
            -- ++ workspaceLines
            ++ [ "---" ]

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
