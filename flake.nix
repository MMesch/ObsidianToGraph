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
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          (pkgs.haskellPackages.ghcWithPackages (p: [p.turtle] ))
          pkgs.haskellPackages.haskell-language-server
          pkgs.haskellPackages.hls-splice-plugin
          pkgs.haskellPackages.hls-eval-plugin
          pkgs.haskellPackages.ormolu
        ];
      };
    });
}
