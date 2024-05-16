# Obsidian To Graph

This script extracts nodes and edges from a folder in an Obsidian vault and
saves them as `nodes.csv` and `edges.csv`. It uses the full path (without
extension) as node `ID`, and also writes a `Type` column which contains the
full folder name (that is with all subfolders).

You can run it with `nix run github:mmesch/ObsidianToGraph -- FOLDER` where
`FOLDER` is the folder in your vault that you want to convert.

**CAREFUL** you need to convert all links in your Obsidian vault to "absolute"
first. You can do that with the
[link converter plugin](https://github.com/ozntel/obsidian-link-converter) after
selecting "absolute" links under settings.

Gephi is sometimes a pain to run. If `nix run nixpkgs#gephi` doesn't really
work because of OpenGL issues, you can download the latest gephi package from
their website, extract it and run the executable with:

`NIXPKGS_ALLOW_UNFREE=1 nix run nixpkgs#steam-run --impure -- ./gephi`

Afterwards you go on "open" in the main menu, select the `nodes.csv` file
first, click through the dialogs making sure "Append to Existing Workspace" is
selected. Afterwards you do the same with `edges.csv` and that's it.
