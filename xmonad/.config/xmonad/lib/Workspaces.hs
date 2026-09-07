module Workspaces where

-- local
import Appearance (myTabTheme)
import Layouts
--
import XMonad.Core (WorkspaceId)
import XMonad.Layout ((|||))
import XMonad.Layout.BoringWindows (boringWindows)
import XMonad.Layout.Decoration (shrinkText)
import XMonad.Layout.MultiToggle qualified as MT
import XMonad.Layout.MultiToggle.Instances (StdTransformers (MIRROR))
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Simplest
import XMonad.Layout.Tabbed (tabbedBottom)
import XMonad.Layout.ToggleLayouts qualified as TL

myWorkspaces :: [WorkspaceId]
myWorkspaces =
  [ "audio",
    "network"
  ]

-- (dynamic workspace test) currently this fallback will be used for the 'project workspaces'
myLayouts =
  MT.mkToggle (MT.single LAYOVERWRITE) $
    MT.mkToggle (MT.single MIRROR) $
      onWorkspace "web" webLayouts $
        onWorkspace "remote" remoteLayouts $
          onWorkspace "temp" tempLayouts projectLayout

--  --- this is the default layout for new workspaces (!) ---
projectLayout =
  boringWindows $
    TL.toggleLayouts
      ( noBorders Simplest
          ||| tabbedSplit
      )
      (myFloat ||| noBorders Simplest)

-- ----------------------------------------------------------

webLayouts =
  boringWindows $
    noBorders (tabbedBottom shrinkText myTabTheme)

-- \||| twoPaneThing 2 (1/2)

remoteLayouts =
  boringWindows $
    roledexGapDeco
      ||| noBorders (tabbedBottom shrinkText myTabTheme)

-- \||| myFloat

tempLayouts =
  boringWindows $
    myFloat
      ||| noBorders Simplest
