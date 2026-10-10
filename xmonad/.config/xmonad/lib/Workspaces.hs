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
import XMonad.Layout.Magnifier

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
          onWorkspace "temp" tempLayouts $
            onWorkspace "movie" movieLayouts
              projectLayout

--  --- this is the default layout for new workspaces (!) ---
projectLayout =
  boringWindows $
    TL.toggleLayouts
      (
          lockedMagnifierxy 1.05 1.98 tabbedSplit3
--          magnifierxyOff' 1.2 2.5 tabbedSplit3
      ||| noBorders (tabbedBottom shrinkText myTabTheme))
      (
          myFloat ||| noBorders (tabbedBottom shrinkText myTabTheme)
      )

-- ----------------------------------------------------------

webLayouts =
  boringWindows $
    noBorders (tabbedBottom shrinkText myTabTheme)
    ||| myFloat

movieLayouts =
  boringWindows $
    noBorders Simplest

--    ||| twoPaneThing 2 (1/2)


remoteLayouts =
  boringWindows $
    roledexGapDeco
      ||| noBorders (tabbedBottom shrinkText myTabTheme)

-- \||| myFloat

tempLayouts =
  boringWindows $
    myFloat
      ||| noBorders Simplest
        ||| roledexGapDeco
