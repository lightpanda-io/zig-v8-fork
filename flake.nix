{
  description = "a fork of the V8 Javascript Engine, built with Zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # This build pipeline is very unhappy without an FHS-compliant env.
        fhs = pkgs.buildFHSEnv {
          name = "fhs-shell";
          targetPkgs =
            pkgs: with pkgs; [
              nix-prefetch-scripts

              python3
              ty
            ];
        };
      in
      {
        devShells.default = fhs.env;
        packages = import ./nix/package.nix { inherit pkgs; };
      }
    );
}
