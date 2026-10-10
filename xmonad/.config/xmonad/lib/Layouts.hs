module Layouts where

-- local
import Appearance (myTabTheme)
--
import Data.List (partition)
import XMonad
import XMonad.Actions.MouseResize (mouseResize)
import XMonad.Layout.BinaryColumn
import XMonad.Layout.BoringWindows (boringWindows)
import XMonad.Layout.Decoration
import XMonad.Layout.Gaps
import XMonad.Layout.LayoutBuilder (LayoutB, layoutAll, layoutN, relBox)
import XMonad.Layout.LayoutModifier 
import XMonad.Layout.LimitWindows (limitWindows)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle qualified as MT
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.Reflect (reflectVert)
import XMonad.Layout.ResizableTile
import XMonad.Layout.Roledex
import XMonad.Layout.Simplest
import XMonad.Layout.SimplestFloat (simplestFloat)
import XMonad.Layout.Tabbed (TabbedDecoration, tabbedBottom)
import qualified XMonad.StackSet as W

{-# ANN myDecorate ("HLint: ignore Eta reduce" :: String) #-}


-- float
myFloatString = "NoFrillsDeco SimplestFloat"

myFloat =
  mouseResize $ myDecorate (lockedMagnifierxy 1.05 1.98 simplestFloat)

tabbedSplit3mag = lockedMagnifierxy 1.05 1.98 tabbedSplit3 

tabbedSplit :: LayoutB Full (LayoutB (ModifiedLayout (Decoration TabbedDecoration DefaultShrinker) Simplest) Full ()) () Window
tabbedSplit =
  layoutN 1 (relBox 0 0 0.5 1) (Just $ relBox 0 0 1 1) Full $
    layoutAll (relBox 0.5 0.0 1 1) (tabbedBottom shrinkText myTabTheme)

tabbedSplit3 ::
  LayoutB
    Full
    (LayoutB
      Full
      (LayoutB
        (ModifiedLayout (Decoration TabbedDecoration DefaultShrinker) Simplest)
        Full
        ())
      ())
    ()
    Window
tabbedSplit3 =
  layoutN 1
    (relBox 0 0 0.5 1)
    (Just $ relBox 0 0 1 1)
    Full $
  layoutN 1
    (relBox 0.5 0 1 0.5)
    (Just $ relBox 0.5 0 1 1)
    Full $
  layoutAll
    (relBox 0.5 0.5 1 1)
    (tabbedBottom shrinkText myTabTheme)



-- locking magnifier
data LockedMagnifier a =
  LockedMagnifier
    (Double, Double)  -- (x zoom, y zoom)
    (Maybe Window)    -- locked window
  deriving (Read, Show)


lockedMagnifierxy
  :: Rational
  -> Rational
  -> l a
  -> ModifiedLayout LockedMagnifier l a
lockedMagnifierxy zoomX zoomY =
  ModifiedLayout $
    LockedMagnifier
      (fromRational zoomX, fromRational zoomY)
      Nothing

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

-- convenience version when xy zoom are the same
lockedMagnifier
  :: Rational
  -> l a
  -> ModifiedLayout LockedMagnifier l a
lockedMagnifier zoom =
  lockedMagnifierxy zoom zoom


instance LayoutModifier LockedMagnifier Window where
  redoLayout
    (LockedMagnifier zoom locked)
    screen
    _
    wrs =
      let
        (target, rest) =
          partition (\(w, _) -> Just w == locked) wrs

        target' =
          fmap (\(w, r) -> (w, magnifyRect screen zoom r)) target
      in
        -- target first so magnified window stays above overlapping windows
        pure (target' ++ rest, Nothing)


  handleMess (LockedMagnifier zoom locked) msg
    | Just Toggle <- fromMessage msg =
        case locked of
          Just _ ->
            pure . Just $
              LockedMagnifier zoom Nothing

          Nothing ->
            withWindowSet $ \ws ->
              pure . Just $
                LockedMagnifier zoom (W.peek ws)

    | Just ToggleOff <- fromMessage msg =
        pure . Just $
          LockedMagnifier zoom Nothing

    | Just ToggleOn <- fromMessage msg =
        case locked of
          Just _ ->
            pure Nothing

          Nothing ->
            withWindowSet $ \ws ->
              pure . Just $
                LockedMagnifier zoom (W.peek ws)

    | otherwise =
        pure Nothing


magnifyRect
  :: Rectangle
  -> (Double, Double)
  -> Rectangle
  -> Rectangle
magnifyRect
  (Rectangle sx sy sw sh)
  (zoomX, zoomY)
  (Rectangle x y w h) =
    Rectangle x' y' w' h'
  where
    w' = min sw $ round (fromIntegral w * zoomX)
    h' = min sh $ round (fromIntegral h * zoomY)

    dx =
      (fromIntegral w' - fromIntegral w) `div` 2

    dy =
      (fromIntegral h' - fromIntegral h) `div` 2

    x' =
      max sx $
        min
          (sx + fromIntegral sw - fromIntegral w')
          (x - dx)

    y' =
      max sy $
        min
          (sy + fromIntegral sh - fromIntegral h')
          (y - dy)

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
