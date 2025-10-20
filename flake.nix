{
  description = "a fork of the V8 Javascript Engine, built with Zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    zigPkgs.url = "github:mitchellh/zig-overlay";
    zigPkgs.inputs.nixpkgs.follows = "nixpkgs";

    zlsPkg.url = "github:zigtools/zls/0.15.0";
    zlsPkg.inputs.zig-overlay.follows = "zigPkgs";
    zlsPkg.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      zigPkgs,
      zlsPkg,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          (final: prev: {
            zigpkgs = zigPkgs.packages.${prev.system};
            zls = zlsPkg.packages.${prev.system}.default;
          })
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # This build pipeline is very unhappy without an FHS-compliant env.
        fhs = pkgs.buildFHSEnv {
          name = "fhs-shell";
          targetPkgs =
            pkgs: with pkgs; [
              nix-prefetch-scripts
              zigpkgs."0.15.2"
              zls

              gn
              ninja
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
