{-# LANGUAGE OverloadedStrings #-}

module Distribution.Hi.Option
    (
      getInitFlags
    , getMode
    ) where

import           Distribution.Hi.Flag      (extractInitFlags)
import           Distribution.Hi.Types
import           Control.Applicative
import           Data.Time.Calendar    (toGregorian)
import           Data.Time.Clock       (getCurrentTime, utctDay)
import           System.Console.GetOpt
import           System.Environment    (getArgs)

-- | Available options.
options :: [OptDescr Arg]
options =
    [ Option ['p'] ["package-name"](ReqArg (Val "packageName") "package-name")  "Name of package"
    , Option ['m'] ["module-name"] (ReqArg (Val "moduleName") "Module.Name")  "Name of Module"
    , Option ['a'] ["author"]      (ReqArg (Val "author") "NAME")  "Name of the project's author"
    , Option ['e'] ["email"]       (ReqArg (Val "email") "EMAIL")  "Email address of the maintainer"
    , Option ['r'] ["repository"]  (ReqArg (Val "repository") "REPOSITORY")  "Template repository(optional)"
    , Option ['v'] ["version"]     (NoArg Version) "show version number"
    , Option []    ["no-configuration-file"] (NoArg NoConfigurationFile) "run without configuration file"
    ]

-- | Returns 'InitFlags'.
getInitFlags :: IO InitFlags
getInitFlags = extractInitFlags <$> (addYear =<< fst <$> parseArgs <$> getArgs)

-- | Returns 'Mode'.
getMode :: IO Mode
getMode = do
    args <- fst <$> parseArgs <$> getArgs
    return $ if any id [True |Version <- args]
               then ShowVersion
               else if any id [True |NoConfigurationFile <- args]
                      then RunWithNoConfigurationFile
                      else Run

parseArgs :: [String] -> ([Arg], [String])
parseArgs argv =
   case getOpt Permute options argv of
      ([],_,errs) -> error $ concat errs ++ usageInfo header options
      (o,n,[]   ) -> (o,n)
      (_,_,errs ) -> error $ concat errs ++ usageInfo header options
  where
    header = "Usage: hi [OPTION...]"

addYear :: [Arg] -> IO [Arg]
addYear args = do
    (y,_,_) <- (toGregorian . utctDay) <$> getCurrentTime
    return $ (Val "year" $ show y):args