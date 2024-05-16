{-#LANGUAGE OverloadedStrings #-}

module Main where

import qualified Text.MMark as MM
import qualified Control.Foldl as L
import qualified Turtle as TS
import qualified Turtle.Shell as TS.Shell
import qualified Turtle.Prelude as TS.Prelude
import qualified Options.Applicative as A
import qualified Data.Text as T
import qualified Data.Text.IO as T.IO
import qualified Text.Megaparsec   as M
import qualified Text.Megaparsec.Char as MC
import qualified System.FilePath.Posix as FP
import qualified System.IO as IO
import qualified Control.Applicative.Combinators as C
import Data.Void ( Void )
import Data.Text (Text)
import Data.Data (Data)
import Data.Typeable (Typeable)

parser :: A.Parser FilePath
parser = A.argument A.str (A.metavar "FOLDER")

data Node = Node {
    nodeID :: String,
    nodeLabel :: String,
    nodeSize :: Double,
    nodeType :: String
    } deriving (Show, Data, Typeable)


data Edge = Edge {
    edgeSource :: String,
    edgeTarget :: String,
    edgeLabel :: String,
    edgeWeight :: Double
    } deriving (Show, Data, Typeable)

isMarkdown :: FilePath -> Bool
isMarkdown fp = ".md" == snd (FP.splitExtension fp)

extractNode :: FilePath -> Node
extractNode fp = Node{
    nodeID=pathWithoutExtension,
    nodeLabel=filename,
    nodeSize=1.0,
    nodeType=folder
    }
    where
      (pathWithoutExtension, ext) = FP.splitExtension fp
      (folder, filename) = FP.splitFileName pathWithoutExtension

documentParser :: M.Parsec Void String [String]
documentParser = do
    r <- C.many (M.try (M.skipManyTill (M.noneOf ['[']) singleLinkParser))
    _ <- C.many M.anySingle
    _ <- M.eof
    return r

singleLinkParser :: M.Parsec Void String String
singleLinkParser = do
    _ <- M.chunk "[["
    link <- C.many (M.noneOf [']'])
    _ <- M.chunk "]]"
    return link

getLinks :: FilePath -> String -> Either (M.ParseErrorBundle String Void) [String]
getLinks = M.runParser documentParser

myfoldM :: L.FoldM IO String [(Node, [Edge])]
myfoldM = L.FoldM step init extract
    where
        step accumulator filename = do
            print ("working on" <> filename)
            let node = extractNode filename
            input <- IO.readFile filename
            case getLinks filename input of
                Left bundle -> do
                    putStrLn (M.errorBundlePretty bundle)
                    return accumulator
                Right r -> do
                    let edges = (\x -> Edge{
                        edgeSource=nodeID node,
                        edgeTarget=x,
                        edgeLabel="relates",
                        edgeWeight=1.0}) <$> r
                    return $ (node, edges) : accumulator
        init = return []
        extract = return

-- write list of Haskell Nodes to a file in CSV format with field names
-- as the first line. Uses String and not Text.
writeNodeList :: FilePath -> [Node] -> IO ()
writeNodeList filename records = do
    let header = "ID,Label,Size,Type"
        recordToString (Node nodeID nodeLabel nodeSize nodeType) =
            nodeID ++ "," ++ nodeLabel ++ "," ++ show nodeSize ++ "," ++ nodeType
        recordsAsString = unlines $ header : (recordToString <$> records)
    IO.writeFile filename recordsAsString

-- write list of Haskell Edges to a file in CSV format with field names
-- as the first line. Uses String and not Text.
writeEdgeList :: FilePath -> [Edge] -> IO ()
writeEdgeList filename records = do
    let header = "Source,Target,Label,Weight"
        recordToString (Edge edgeSource edgeTarget edgeLabel edgeWeight) =
            edgeSource ++ "," ++ edgeTarget ++ "," ++ edgeLabel ++ "," ++ show edgeWeight
        recordsAsString = unlines $ header : (recordToString <$> records)
    IO.writeFile filename recordsAsString

main :: IO()
main = do
    basefolder :: FilePath <- A.execParser (A.info (parser A.<**> A.helper) mempty)
    let files :: TS.Shell String = TS.mfilter isMarkdown $ TS.Prelude.lstree basefolder
    parsedLinks :: [(Node, [Edge])] <- TS.foldIO files myfoldM
    let nodes = fst <$> parsedLinks
        edges = mconcat $ snd <$> parsedLinks
    writeNodeList "nodes.csv" nodes
    writeEdgeList "edges.csv" edges
    print "done"
