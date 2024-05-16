{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = 
    {
      self,
      nixpkgs,
      flake-utils
    }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      haskellEnv = pkgs.haskellPackages.ghcWithPackages (p: [p.turtle p.megaparsec]);
      obsidianToGraph = pkgs.stdenv.mkDerivation {
          name = "obsidianToGraph";
          src = ./.;
          buildInputs = [haskellEnv];
          buildPhase = ''
            ghc to_graph.hs
            mkdir -p $out/bin
            cp to_graph $out/bin/obsidianToGraph
          '';
        };
    in
    {
      packages.obsidianToGraph = obsidianToGraph;
      packages.default = obsidianToGraph;
      packages.apps.default = obsidianToGraph;
      devShells.default = pkgs.mkShell {
        packages = [
          haskellEnv
          pkgs.haskellPackages.haskell-language-server
          pkgs.haskellPackages.hls-splice-plugin
          pkgs.haskellPackages.hls-eval-plugin
          pkgs.haskellPackages.ormolu
        ];
      };
    });
}
