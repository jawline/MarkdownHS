import System.FSNotify (withManager, watchTree, Event(Modified))
import System.Environment (getArgs)
import Control.Concurrent (threadDelay)
import Control.Monad (forever, when)
import System.Exit (exitWith, ExitCode(ExitFailure))
import System.Process (system)
import System.Directory (setCurrentDirectory)

-- Triggers cabal to recompile on change and then re-run the website builder.
executeParrot input output = do
  system ("cabal run Parrot -- " ++ input ++ " " ++ output)
  return ()

-- Event callback for FSNotify watcher
-- Triggers only when files are Modified
triggerTransform transformer event |
  Modified _ _ _  <- event = do
    transformer
    putStrLn ("[+] Transform because of change to " ++ (show event))
    return ()
  | otherwise = do
    putStrLn ("[+] " ++ (show event) ++ " does not trigger rebuild")
    return ()

-- Repeatedly watches input or ./src/ and runs the transformer whenever files change.
watchJob transformer input output =
  withManager $ \mgr -> do
    putStrLn ("[+] Watching for changes on: " ++ input)
    watchTree mgr input alwaysTrigger triggerTransform'
    watchTree mgr "src" alwaysTrigger triggerTransform'
    forever $ threadDelay 1000000
  where
    alwaysTrigger _ = True
    triggerTransform' = triggerTransform transformer

-- When the watcher is not called with the right number of arguments complain
failArguments = do
  putStrLn "Usage: executable CORE_DIR SOURCE_DIR OUTPUT"
  exitWith (ExitFailure 1)

{-|
 The purpose of this program is to watch for changes in either the project
 source or the target directory and automatically build a copy of the
 website if files in either change. This is primarily a development tool
 to enable rapid prototyping both in changes to the target site but also in
 Parrot itself.
-}
main = do
  programArguments <- getArgs

  -- Exit if we do not have three arguments
  when (length programArguments /= 3) $ failArguments

  -- We take three arguments, the directory of Parrot's core, the directory of the website source
  -- and the output directory to write changes to
  let coreDirectory = programArguments !! 0
  let input = programArguments !! 1
  let output = programArguments !! 2

  -- We change the working directory to the first directory supplied
  _ <- setCurrentDirectory coreDirectory

  let exec = executeParrot input output

  _ <- exec
  watchJob exec input output
  return ()
