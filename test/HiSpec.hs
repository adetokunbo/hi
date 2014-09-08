{-# LANGUAGE OverloadedStrings #-}

module HiSpec ( spec ) where

import           Hi                    (process)
import           Hi.Types

import           Control.Monad
import           Data.ByteString.Char8 (pack, unpack)
import           Data.Maybe            (fromJust, isJust)
import           Test.Hspec

options :: Option
options = Option { initializeGitRepository = True
                  , packageName = "testapp"
                  , moduleName = "System.Awesome.Library"
                  , author     = "Fujimura Daisuke"
                  , email      = "me@fujimuradaisuke.com"
                  , repository = "file://somewhere"
                  }

lookupContent :: FilePath -> Files -> Maybe String
lookupContent _  [] = Nothing
lookupContent fp (f:fs) = if getFilePath f == fp
                           then Just $ stringifyContents f
                           else lookupContent fp fs

stringifyContents :: File -> String
stringifyContents = unpack . getFileContents

spec :: Spec
spec =
    describe "Hi.process" $ do
      context "Option `packageName` was given and it's in the template" $
        it "should be replaced with the value" $
          let files = process options [TemplateFile "dummy.template" "Foo $packageName bar, \n"] in
          (fromJust $ lookupContent "dummy" files) `shouldContain` packageName options

      context "Option `moduleName` was given and it's in the template" $
        it "should be replaced with the value" $
          let files = process options [TemplateFile "dummy.template" "Foo $moduleName bar, \n"] in
          (fromJust $ lookupContent "dummy" files) `shouldContain` moduleName options

      context "Option `author` was given and it's in the template" $
        it "should be replaced with the value" $
          let files = process options [TemplateFile "dummy.template" "Foo $author bar, \n"] in
          (fromJust $ lookupContent "dummy" files) `shouldContain` author options

      context "Option `email` was given and it's in the template" $
        it "should be replaced with the value" $
          let files = process options [TemplateFile "dummy.template" "Foo $email bar, \n"] in
          (fromJust $ lookupContent "dummy" files) `shouldContain` (email options)

      context "`ModuleName` was given and `moduleName` is in the file path" $
        it "should be replaced with given value, replacing period with path separator" $
          let files = process (options { moduleName = "Bar"}) [TemplateFile "foo/ModuleName/File.hs.template" "module Foo\n"] in
          lookupContent "foo/Bar/File.hs" files `shouldSatisfy` isJust

      describe "file without .template" $ do
        it "should be copied without substitution" $
          let files = process (options {moduleName = "Bar"}) [RegularFile "ModuleName/Foofile" "foo: $bar\n"] in
          lookupContent "Bar/Foofile" files `shouldBe` Just "foo: $bar\n"
