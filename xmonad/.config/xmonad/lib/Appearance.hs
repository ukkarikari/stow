module Appearance where

import System.IO (Handle, hPutStrLn)
import XMonad.Core (X)
import XMonad.Hooks.StatusBar.PP
import XMonad.Layout.Decoration
import XMonad.Prompt

-- -------- decorator themes -----------
myTabTheme :: Theme
myTabTheme =
  def
    { fontName = "xft:Terminus:size=8",
      activeColor = "#8a999e",
      inactiveColor = "#545d75",
      activeBorderColor = "#ccd0d2",
      inactiveBorderColor = "#6c758a",
      activeTextColor = "#ffffff",
      inactiveTextColor = "#9699a2",
      decoHeight = 14
    }

myXPConfig :: XPConfig
myXPConfig =
  def
    { font = "xft:Cozette:size=10",
      bgColor = "#545d75",
      fgColor = "#ffffff",
      bgHLight = "#8a999e",
      fgHLight = "#ffffff",
      borderColor = "#6c758a",
      promptBorderWidth = 1,
      height = 18,
      position = CenteredAt 0.4 0.75,
      historySize = 100
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

myDzenCmd = "" -- temp

-- ---------- pretty printer ----------

myPP :: Handle -> PP
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
  return (Just " ")
