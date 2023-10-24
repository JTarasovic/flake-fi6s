{
  description = "Packaging for sfan5/fi6s";

  nixConfig = {
    extra-substituters = [ "https://flake-fi6s.cachix.org" ];
    extra-trusted-public-keys = [ "flake-fi6s.cachix.org-1:HdBpOduB+6yvnIPaXePDL1bMLKVIO9B5p5h8n78WHok=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-root.url = "github:srid/flake-root";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
    flake-checker = {
      url = "github:DeterminateSystems/flake-checker";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

  };

  outputs = inputs@{ flake-parts, flake-utils, flake-root, treefmt-nix, nixpkgs, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        treefmt-nix.flakeModule
        flake-root.flakeModule
      ];
      systems = flake-utils.lib.defaultSystems;

      perSystem = { config, pkgs, ... }:
        let
          stdenv = pkgs.stdenv;
          treefmt-wrapped = config.treefmt.build.wrapper;
          lib = nixpkgs.lib;
        in
        {
          treefmt.config = {
            inherit (config.flake-root) projectRootFile;
            package = pkgs.treefmt;

            programs.nixpkgs-fmt.enable = true;
            programs.deadnix.enable = true;
            programs.shfmt.enable = true;

            settings = {
              global.excludes = [
                "./result/**"
                ".git/**"
              ];
            };
          };

          packages.default = stdenv.mkDerivation {
            pname = "fi6s";
            version = "8d5ddba";
            src = pkgs.fetchgit {
              url = "https://github.com/sfan5/fi6s";
              rev = "8d5ddba";
              #sha256 = lib.fakeSha256;
              sha256 = "sha256-31nf6GDdGIfgu5VVz4Ls9kiyEi1hXZBiDBa7SLR0l/o=";
            };
            buildInputs = with pkgs; [
              libpcap
            ];
            makeFlags = [
              "BUILD_TYPE=release"
              "PREFIX=$(out)"
            ];
            meta = with lib; {
              homepage = "https://github.com/sfan5/fi6s";
              description = "IPv6 network scanner designed to be fast";
            };
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs;[
              nixd
              nixpkgs-fmt
              treefmt-wrapped
            ];
          };

          formatter = treefmt-wrapped;

          # TODO(jdt): run flake checker
          # checks = with pkgs; {
          #   check-flake = runCommand
          #     "check flake"
          #     { }
          #     ''
          #       echo "${builtins.concatStringsSep "," (builtins.attrNames flake-checker)}"
          #       ${flake-checker.packages.${system}.default}
          #       touch "$out"
          #     '';
          # };
        };
      flake = { };
    };
}
