module Settings.Packages.Compiler (compilerPackageArgs) where

import Base
import Flavour
import GHC
import Oracles.Config.Flag
import Oracles.Config.Setting
import Predicate
import Settings

compilerPackageArgs :: Args
compilerPackageArgs = package compiler ? do
    stage   <- getStage
    rtsWays <- getRtsWays
    path    <- getBuildPath
    mconcat [ builder Alex ? arg "--latin1"

            , builder GhcCabal ? mconcat
              [ arg $ "--ghc-option=-DSTAGE=" ++ show (fromEnum stage + 1)
              , arg "--disable-library-for-ghci"
              , anyTargetOs ["openbsd"] ? arg "--ld-options=-E"
              , flag GhcUnregisterised ? arg "--ghc-option=-DNO_REGS"
              , notM ghcWithSMP ? arg "--ghc-option=-DNOSMP"
              , notM ghcWithSMP ? arg "--ghc-option=-optc-DNOSMP"
              , (threaded `elem` rtsWays) ?
                notStage0 ? arg "--ghc-option=-optc-DTHREADED_RTS"
              , ghcWithNativeCodeGen ? arg "--flags=ncg"
              , ghcWithInterpreter ?
                notStage0 ? arg "--flags=ghci"
              , ghcWithInterpreter ?
                ghcEnableTablesNextToCode ?
                notM (flag GhcUnregisterised) ?
                notStage0 ? arg "--ghc-option=-DGHCI_TABLES_NEXT_TO_CODE"
              , ghcWithInterpreter ?
                ghciWithDebugger flavour ?
                notStage0 ? arg "--ghc-option=-DDEBUGGER"
              , ghcProfiled flavour ?
                notStage0 ? arg "--ghc-pkg-option=--force" ]

            , builder Haddock ? arg ("--optghc=-I" ++ path) ]
