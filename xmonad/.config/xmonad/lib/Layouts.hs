module Layouts where

-- local
import Appearance (myTabTheme)
--
import XMonad
import XMonad.Actions.MouseResize (mouseResize)
import XMonad.Layout.BinaryColumn
import XMonad.Layout.BoringWindows (boringWindows)
import XMonad.Layout.Decoration
import XMonad.Layout.Gaps
import XMonad.Layout.LayoutBuilder (LayoutB, layoutAll, layoutN, relBox)
import XMonad.Layout.LayoutModifier (ModifiedLayout)
import XMonad.Layout.LimitWindows (limitWindows)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle qualified as MT
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.Reflect (reflectVert)
import XMonad.Layout.ResizableTile
import XMonad.Layout.Roledex
import XMonad.Layout.Simplest
import XMonad.Layout.SimplestFloat (simplestFloat)
import XMonad.Layout.Tabbed (TabbedDecoration, tabbedBottom)

{-# ANN myDecorate ("HLint: ignore Eta reduce" :: String) #-}

-- custom layout definitions

myFloatString = "NoFrillsDeco Magnifier (off) SimplestFloat"

myFloat =
  mouseResize $ myDecorate (magnifierxyOff 0.5 1.0 simplestFloat)

twoPaneThing win_n ratio =
  limitWindows win_n (noBorders (magnifierczOff' 1.3 (ResizableTall 1 (3 / 100) ratio [])))

roledexGapDeco =
  myDecorate
    ( gaps
        [(L, 60), (R, 60), (U, 10), (D, 10)]
        (reflectVert Roledex)
    )

theTape =
  myDecorate
    ( gaps
        [(L, 20), (R, 20), (U, 175), (D, 175)]
        (Mirror (BinaryColumn 0.0 32))
    )

tabbedSplit :: LayoutB Full (LayoutB (ModifiedLayout (Decoration TabbedDecoration DefaultShrinker) Simplest) Full ()) () Window
tabbedSplit =
  layoutN 1 (relBox 0 0 0.5 1) (Just $ relBox 0 0 1 1) Full $
    layoutAll (relBox 0.5 0.0 1 1) (tabbedBottom shrinkText myTabTheme)

-- decoration helper
myDecorate ::
  l Window ->
  ModifiedLayout
    (Decoration NoFrillsDecoration DefaultShrinker)
    l
    Window
myDecorate l =
  -- the l in this decorate function is to fix the 'a0' ambiguity error
  noFrillsDeco shrinkText myTabTheme l

-- global layout overwrite toggle
data LAYOVERWRITE = LAYOVERWRITE deriving (Read, Show, Eq, Typeable)

-- multi toggle that overwrites the current layout with another
instance MT.Transformer LAYOVERWRITE Window where
  transform LAYOVERWRITE x k = k (boringWindows theTape) (const x)
