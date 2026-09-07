module Keybinds where

-- local
import Appearance (myXPConfig)
import Applications
import Layouts
import Utilities
--

import XMonad.Actions.DynamicWorkspaces qualified as DW
import XMonad.Actions.GridSelect (bringSelected)
import XMonad.Actions.PerLayoutKeys (bindByLayout)
import XMonad.Actions.PerWorkspaceKeys (bindOn)
import XMonad.Actions.WindowMenu (windowMenu)
import XMonad.Actions.WithAll (killAll)
import XMonad.Core (X, spawn)
import XMonad.Layout.BoringWindows qualified as BW
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle qualified as MT
import XMonad.Layout.MultiToggle.Instances (StdTransformers (MIRROR))
import XMonad.Layout.ResizableTile
import XMonad.Layout.ToggleLayouts qualified as TL
import XMonad.Layout.WindowArranger
import XMonad.Operations (sendMessage, windows)
import XMonad.Prompt.Pass (passPrompt)
import XMonad.Prompt.Shell (shellPrompt)
import XMonad.Prompt.Workspace (workspacePrompt)
import XMonad.StackSet qualified as W

myKeybs =
  windowKeybinds
    ++ utilityKeybinds
    ++ tempKeybinds

-- Keybinds :: [(String, X ())]
windowKeybinds =
  [ -- overwrite with boring windows
    ("M-k", BW.focusUp),
    ("M-j", BW.focusDown),
    ("M-m", BW.focusMaster),
    ("M-b", BW.markBoring),
    ("M-S-b", BW.clearBoring),
    -- increase/decrease slave size
    ("M-z", sendMessage MirrorShrink),
    ("M-a", sendMessage MirrorExpand),
    -- magnifier keys
    ("M-=", sendMessage Toggle),
    ("M-S-=", sendMessage MagnifyMore),
    ("M--", sendMessage MagnifyLess),
    -- mirror
    ("M-S-m", sendMessage $ MT.Toggle MIRROR),
    -- layout overwrite
    ("M-S-o", sendMessage $ MT.Toggle LAYOVERWRITE),
    --     --  floating windows  --

    -- movmt
    ("M-S-h", sendMessage (MoveLeft 45)),
    ("M-S-l", sendMessage (MoveRight 45)),
    ( "M-S-k",
      bindByLayout
        [ (myFloatString, sendMessage (MoveUp 45)),
          ("", windows W.swapUp)
        ]
    ),
    ( "M-S-j",
      bindByLayout
        [ (myFloatString, sendMessage (MoveDown 45)),
          ("", windows W.swapDown)
        ]
    ),
    -- resize
    ("M-C-h", sendMessage (DecreaseLeft 35)),
    ("M-C-l", sendMessage (IncreaseRight 35)),
    ("M-C-k", sendMessage (DecreaseUp 35)),
    ("M-C-j", sendMessage (IncreaseDown 35)),
    -- , ("M-S-g", sendMessage $ SetGeometry (Rectangle 200 100 500 300))
    ("M-S-g", cycleGeometry)
  ]

utilityKeybinds =
  [ -- shell prompts
    ("M-S-p", passPrompt myXPConfig),
    ("M-p", shellPrompt myXPConfig),
    -- rename winodw
    ("C-S-r", renameFocusedPrompt myXPConfig),
    -- workspaceSelector
    ("M-<Tab>", myWorkspaceSelector myWorkspaceGSConfig),
    ("M-S-<Tab>", bringSelected myWindowGSConfig),
    ("M-C-<Space>", windowMenu),
    -- change keyboard layout
    ("C-<Space>", keyboardLayoutPrompt),
    -- toggle layouts
    ("M-S-f", sendMessage TL.ToggleLayout),
    -- (dynamic workspaces test) prompt to create new workspace
    ("C-M-n", workspacePrompt myXPConfig gotoWorkspace),
    -- (dynamic workspaces test) kill all workspace processes and remove workspace
    ( "C-M-<Backspace>",
      do
        killAll
        DW.removeWorkspace
    ),
    -- screenshot
    ("<Print>", execPrint),
    ("S-<Print>", execXclipPrint),
    -- screen lock
    ("<XF86ScreenSaver>", execLock),
    ("M-S-C-s", execLock),
    -- audio
    ("<XF86AudioLowerVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%-"),
    ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%+"),
    ("<XF86AudioMute>", spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  ]

tempKeybinds =
  [ -- spawn windows on aux
    ( "M-<F2>",
      bindOn
        [ ( "aux",
            do
              spawn "urxvt -e sh -c 'btop; bash'"
              spawn "sleep 0.5; snow"
              spawn "sleep 1; xload"
          )
        ]
    ),
    -- toggle mic feedback
    ("M-C-m", execMicLoopback),
    -- debug window test
    ( "M-C-d",
      spawn "urxvt -name xmonad-debug -e watch -n 0.2 'cat /tmp/xmonad-debug'" -- test
    )
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
